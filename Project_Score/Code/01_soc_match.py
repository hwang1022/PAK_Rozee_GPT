"""
01_soc_match.py
Match Rozee.pk job titles to O*NET SOC codes using Claude Haiku,
then look up O*NET tasks for each matched occupation.

Strategy: Use a lightweight system prompt (Claude knows O*NET codes from
training) then validate returned codes against the labelset. This keeps
prompt bytes low to stay within the 20M bytes/hour rate limit.

Inputs:
  data/jobs_export.csv         -- jid, title (+ other cols from Stata export)
  [LABELSET_PATH]              -- full_labelset.tsv (Eloundou labels + O*NET tasks)

Outputs (column names must match prep_data_20yr.do exactly):
  data/pipeline/jobsdesc_extract.csv       -- job_id, jid, num_tasks
  data/pipeline/tmain_match_tasks.csv      -- jid, job_id, title, onet_task_id,
                                              onet_task_text, onet_soc_code, occupation_title
  data/pipeline/jobsdesc_onetsoc_tmain.csv -- jid, job_id, onet_soc_code

Cache:
  data/pipeline/soc_cache.json  -- title -> {soc_code, occupation_title}
                                   Survives interruptions; re-run skips cached titles.
"""


import asyncio
import hashlib
import json
import logging
import os
import random
import sys
import time
from pathlib import Path

import anthropic
import pandas as pd
from tqdm import tqdm

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
BASE = Path(__file__).parent.parent
PROJECT_ROOT  = BASE.parent
JOBS_CSV      = BASE / "data" / "jobs_export.csv"
LABELSET_TSV  = PROJECT_ROOT / "Reference Code" / "GPTs-are-GPTs-main" / "data" / "full_labelset.tsv"

PIPELINE_DIR  = BASE / "data" / "pipeline"
PIPELINE_DIR.mkdir(parents=True, exist_ok=True)

CACHE_FILE    = PIPELINE_DIR / "soc_cache.json"
OUT_EXTRACT   = PIPELINE_DIR / "jobsdesc_extract.csv"
OUT_TASKS     = PIPELINE_DIR / "tmain_match_tasks.csv"
OUT_SOC       = PIPELINE_DIR / "jobsdesc_onetsoc_tmain.csv"
LOG_FILE      = BASE / "output" / "logs" / "soc_match.log"
LOG_FILE.parent.mkdir(parents=True, exist_ok=True)

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE, mode="w"),
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
MODEL         = "claude-haiku-4-5-20251001"
BATCH_SIZE    = 15          # stable compromise between speed and truncation risk
MAX_TASKS     = 15          # max O*NET tasks per job (matches prep_data.do)
CONCURRENCY   = 1           # fully sequential to avoid burst 429s
MAX_RETRIES   = 6
RETRY_DELAY   = 5           # seconds between retries
WINDOW_DELAY  = 0.0         # no inter-window pause; rely on sequential requests + backoff
SAVE_EVERY    = 50          # save cache every N completed windows
MAX_OUTPUT_TOKENS = 1000    # enough room for full JSON response on 10-title batches

# Lightweight system prompt (~500 bytes instead of ~44KB)
SYSTEM_PROMPT = (
    "You match job titles to O*NET-SOC 2019 codes. For each title, return the "
    "best-fitting 8-character O*NET-SOC code (e.g. '15-1252.00') and the standard "
    "occupation title. Return ONLY a JSON array of objects with keys: "
    '"title" (original, unchanged), "soc_code", "occupation_title". '
    "No explanation, no markdown — raw JSON only."
)

# ---------------------------------------------------------------------------
# Load reference data
# ---------------------------------------------------------------------------

def load_labelset(path):
    """Load full_labelset.tsv."""
    df = pd.read_csv(path, sep="\t")
    df.columns = [c.strip() for c in df.columns]
    rename = {
        "O*NET-SOC Code": "onet_soc_code",
        "Task ID":        "onet_task_id",
        "Task":           "onet_task_text",
        "Title":          "occupation_title",
    }
    df = df.rename(columns={k: v for k, v in rename.items() if k in df.columns})
    df["onet_task_id"] = pd.to_numeric(df["onet_task_id"], errors="coerce").astype("Int64")
    return df


def build_onet_lookup(labelset):
    """Build: soc_code -> {occupation_title, tasks: [(task_id, task_text)...]}"""
    lookup = {}
    for soc, grp in labelset.groupby("onet_soc_code"):
        tasks = (
            grp[["onet_task_id", "onet_task_text"]]
            .drop_duplicates("onet_task_id")
            .sort_values("onet_task_id")
            .head(MAX_TASKS)
        )
        occ_title = grp["occupation_title"].iloc[0]
        lookup[soc] = {
            "occupation_title": occ_title,
            "tasks": list(tasks.itertuples(index=False, name=None)),
        }
    return lookup


def build_valid_soc_set(labelset):
    """Set of valid SOC codes for validation."""
    return set(labelset["onet_soc_code"].unique())


def build_soc_title_map(labelset):
    """soc_code -> canonical occupation_title."""
    return dict(
        labelset[["onet_soc_code", "occupation_title"]]
        .drop_duplicates("onet_soc_code")
        .values
    )

# ---------------------------------------------------------------------------
# Cache helpers
# ---------------------------------------------------------------------------

def load_cache(path):
    if path.exists():
        with open(path) as f:
            return json.load(f)
    return {}


def save_cache(cache, path):
    with open(path, "w") as f:
        json.dump(cache, f)


def validate_api_key():
    """
    Fail fast on malformed API keys copied with smart punctuation or whitespace.
    Anthropic keys should be plain ASCII; otherwise httpx can crash while
    constructing request headers.
    """
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        raise RuntimeError("ANTHROPIC_API_KEY is not set in the environment.")

    try:
        api_key.encode("ascii")
    except UnicodeEncodeError as e:
        raise RuntimeError(
            "ANTHROPIC_API_KEY contains non-ASCII characters. This usually means "
            "the key was copied with smart punctuation (for example an em dash) "
            "or extra hidden formatting. Re-copy the key directly from the "
            "Anthropic console and set it again."
        ) from e

    if api_key != api_key.strip():
        raise RuntimeError(
            "ANTHROPIC_API_KEY contains leading or trailing whitespace. "
            "Re-set it without extra spaces or line breaks."
        )

    fingerprint = hashlib.sha256(api_key.encode("ascii")).hexdigest()[:12]
    log.info(f"Using ANTHROPIC_API_KEY fingerprint: {fingerprint}")


def backoff_seconds(attempt):
    """Exponential backoff with a little jitter to avoid synchronized retries."""
    return RETRY_DELAY * (2 ** attempt) + random.uniform(0.5, 2.0)

# ---------------------------------------------------------------------------
# Claude API call
# ---------------------------------------------------------------------------

async def match_batch(client, titles, semaphore, valid_socs, soc_title_map):
    """
    Ask Claude to match a batch of job titles to SOC codes.
    Validates returned codes against the known O*NET set.
    """
    titles_json = json.dumps(titles, ensure_ascii=False)
    user_msg = f"Match each job title to the best O*NET-SOC occupation:\n{titles_json}"
    last_failure_kind = None
    last_text_preview = None

    for attempt in range(MAX_RETRIES):
        response = None
        async with semaphore:
            try:
                response = await client.messages.create(
                    model=MODEL,
                    max_tokens=MAX_OUTPUT_TOKENS,
                    messages=[{"role": "user", "content": user_msg}],
                    system=SYSTEM_PROMPT,
                )
                text = response.content[0].text.strip()
                # Strip markdown code blocks if present
                if text.startswith("```"):
                    text = text.split("```")[1]
                    if text.startswith("json"):
                        text = text[4:]
                results = json.loads(text)

                if not isinstance(results, list) or len(results) != len(titles):
                    last_failure_kind = "length"
                    last_text_preview = text[:500]
                    log.warning(f"Length mismatch: sent {len(titles)}, got "
                                f"{len(results) if isinstance(results, list) else 'non-list'}. Retrying.")
                    if attempt < MAX_RETRIES - 1:
                        await asyncio.sleep(backoff_seconds(attempt))
                    continue

                # Validate SOC codes — use canonical title from our labelset
                for r in results:
                    code = r.get("soc_code", "")
                    if code in valid_socs:
                        r["occupation_title"] = soc_title_map.get(code, r.get("occupation_title", ""))
                    else:
                        # Try common format fixes
                        fixed = code.replace(" ", "").strip()
                        if fixed in valid_socs:
                            r["soc_code"] = fixed
                            r["occupation_title"] = soc_title_map.get(fixed, r.get("occupation_title", ""))
                        else:
                            r["soc_code"] = None  # will be skipped

                return results

            except (json.JSONDecodeError, KeyError, IndexError) as e:
                last_failure_kind = "parse"
                last_text_preview = text[:500] if "text" in locals() else None
                stop_reason = getattr(response, "stop_reason", "unknown") if "response" in locals() else "no_response"
                log.warning(
                    f"Parse error on attempt {attempt+1}: {e} "
                    f"(stop_reason={stop_reason}, batch_size={len(titles)})"
                )
            except anthropic.RateLimitError:
                last_failure_kind = "rate_limit"
                wait = backoff_seconds(attempt + 1)
                log.warning(f"Rate limit hit (attempt {attempt+1}). Waiting {wait}s...")
                await asyncio.sleep(wait)
            except anthropic.APIError as e:
                last_failure_kind = "api_error"
                log.warning(f"API error on attempt {attempt+1}: {e}")
                await asyncio.sleep(backoff_seconds(attempt))

        if attempt < MAX_RETRIES - 1:
            await asyncio.sleep(backoff_seconds(attempt))

    if last_failure_kind in {"parse", "length"} and len(titles) > 1:
        mid = len(titles) // 2
        left = titles[:mid]
        right = titles[mid:]
        log.warning(
            f"Falling back to smaller sub-batches after repeated {last_failure_kind} failure "
            f"(batch_size={len(titles)}, left={len(left)}, right={len(right)})."
        )
        if last_text_preview:
            log.warning(f"Last malformed response preview: {last_text_preview!r}")

        left_results = await match_batch(client, left, semaphore, valid_socs, soc_title_map)
        right_results = await match_batch(client, right, semaphore, valid_socs, soc_title_map)
        return left_results + right_results

    log.error(
        f"All retries failed for batch starting with: {titles[0]!r} "
        f"(failure_kind={last_failure_kind}, batch_size={len(titles)})"
    )
    return [{"title": t, "soc_code": None, "occupation_title": None} for t in titles]

# ---------------------------------------------------------------------------
# Main async pipeline
# ---------------------------------------------------------------------------

async def run_matching(unique_titles, cache, valid_socs, soc_title_map):
    """Process all uncached titles through Claude in controlled windows."""
    uncached = [t for t in unique_titles if t not in cache]
    log.info(f"Titles to match: {len(uncached)} (cached: {len(unique_titles) - len(uncached)})")

    if not uncached:
        return cache

    client = anthropic.AsyncAnthropic(max_retries=0)
    semaphore = asyncio.Semaphore(CONCURRENCY)

    # Split into batches
    batches = [uncached[i:i+BATCH_SIZE] for i in range(0, len(uncached), BATCH_SIZE)]
    log.info(f"Batches: {len(batches)} x up to {BATCH_SIZE} titles each")
    log.info(f"System prompt size: {len(SYSTEM_PROMPT)} bytes (lightweight mode)")

    completed = 0
    valid_matches = 0
    invalid_matches = 0

    with tqdm(total=len(batches), desc="Matching batches") as pbar:
        for win_start in range(0, len(batches), CONCURRENCY):
            window = batches[win_start : win_start + CONCURRENCY]
            tasks = [
                match_batch(client, batch, semaphore, valid_socs, soc_title_map)
                for batch in window
            ]
            results_list = await asyncio.gather(*tasks)

            for results in results_list:
                for r in results:
                    if r.get("soc_code"):
                        cache[r["title"]] = {
                            "soc_code": r["soc_code"],
                            "occupation_title": r["occupation_title"],
                        }
                        valid_matches += 1
                    else:
                        invalid_matches += 1
                completed += 1
                pbar.update(1)

            if completed % SAVE_EVERY < CONCURRENCY:
                save_cache(cache, CACHE_FILE)
                rate = valid_matches / max(valid_matches + invalid_matches, 1) * 100
                log.info(f"Cache saved: {len(cache)} entries "
                         f"(valid: {valid_matches}, invalid: {invalid_matches}, "
                         f"hit rate: {rate:.1f}%)")

            await asyncio.sleep(WINDOW_DELAY)

    save_cache(cache, CACHE_FILE)
    rate = valid_matches / max(valid_matches + invalid_matches, 1) * 100
    log.info(f"Matching complete. Cache: {len(cache)}, "
             f"valid: {valid_matches}, invalid: {invalid_matches}, "
             f"hit rate: {rate:.1f}%")
    return cache


# ---------------------------------------------------------------------------
# Build output CSVs
# ---------------------------------------------------------------------------

def build_output_csvs(jobs, cache, onet_lookup):
    """Build the three CSV files consumed by prep_data_20yr.do."""
    extract_rows = []
    task_rows    = []
    soc_rows     = []

    unmatched = 0
    for _, row in tqdm(jobs.iterrows(), total=len(jobs), desc="Building output CSVs"):
        jid   = int(row["jid"])
        title = str(row["title"]).strip()

        match = cache.get(title)
        if not match or not match.get("soc_code"):
            unmatched += 1
            continue

        soc_code     = match["soc_code"]
        onet_info    = onet_lookup.get(soc_code)

        if not onet_info:
            unmatched += 1
            continue

        occ_title    = onet_info["occupation_title"]
        task_list    = onet_info["tasks"][:MAX_TASKS]
        n_tasks      = len(task_list)

        extract_rows.append({"job_id": jid, "jid": jid, "num_tasks": n_tasks})
        soc_rows.append({"jid": jid, "job_id": jid, "onet_soc_code": soc_code})

        for task_id, task_text in task_list:
            task_rows.append({
                "jid":              jid,
                "job_id":           jid,
                "title":            title,
                "onet_task_id":     int(task_id) if pd.notna(task_id) else "",
                "onet_task_text":   task_text,
                "onet_soc_code":    soc_code,
                "occupation_title": occ_title,
            })

    log.info(f"Unmatched jobs (no cache or no O*NET lookup): {unmatched}")
    log.info(f"Jobs with output: {len(extract_rows)}")
    log.info(f"Total task rows: {len(task_rows)}")

    pd.DataFrame(extract_rows).to_csv(OUT_EXTRACT, index=False)
    pd.DataFrame(task_rows).to_csv(OUT_TASKS, index=False)
    pd.DataFrame(soc_rows).to_csv(OUT_SOC, index=False)

    log.info(f"Written: {OUT_EXTRACT}")
    log.info(f"Written: {OUT_TASKS}")
    log.info(f"Written: {OUT_SOC}")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

async def main():
    log.info("=== 01_soc_match.py start ===")
    validate_api_key()

    log.info(f"Loading jobs from {JOBS_CSV}")
    jobs = pd.read_csv(JOBS_CSV, usecols=["jid", "title"], dtype={"jid": int, "title": str})
    jobs["title"] = jobs["title"].fillna("").str.strip()
    jobs = jobs[jobs["title"] != ""].copy()
    log.info(f"Jobs loaded: {len(jobs)}")

    log.info(f"Loading labelset from {LABELSET_TSV}")
    labelset = load_labelset(LABELSET_TSV)
    onet_lookup = build_onet_lookup(labelset)
    valid_socs = build_valid_soc_set(labelset)
    soc_title_map = build_soc_title_map(labelset)
    log.info(f"O*NET occupations: {len(valid_socs)}")

    unique_titles = jobs["title"].unique().tolist()
    log.info(f"Unique job titles: {len(unique_titles)}")

    cache = load_cache(CACHE_FILE)
    log.info(f"Cache loaded: {len(cache)} existing entries")

    # Validate existing cache entries against current SOC set
    stale = [t for t, v in cache.items() if v.get("soc_code") not in valid_socs]
    if stale:
        log.info(f"Removing {len(stale)} stale cache entries with invalid SOC codes")
        for t in stale:
            del cache[t]
        save_cache(cache, CACHE_FILE)

    cache = await run_matching(unique_titles, cache, valid_socs, soc_title_map)

    matched = sum(1 for t in unique_titles if t in cache and cache[t].get("soc_code"))
    log.info(f"Match rate on unique titles: {matched}/{len(unique_titles)} "
             f"({100*matched/max(len(unique_titles),1):.1f}%)")

    build_output_csvs(jobs, cache, onet_lookup)
    log.info("=== 01_soc_match.py complete ===")


if __name__ == "__main__":
    asyncio.run(main())
