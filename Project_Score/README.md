# RozeeAI 20-Year Analysis

Adaptation of the RozeeAI DiD analysis for the full 20-year Rozee.pk dataset
(`jobs_int.dta`, 749,502 jobs, 2004–2024).

## Known Gaps and Decisions

### ISIC Sector (skipped)
The `job_isic_sec` variable in the ADB analysis lives on `companies_adb_clean.dta`
and was constructed externally by ADB using an ISIC crosswalk not available here.
The 20-year `companies_int.dta` has Rozee's own `industry_str` taxonomy (65 sectors)
but no ISIC mapping.

**Not used** in the main DiD (`analysis_demand.do`) — only in sector breakdown charts
(`descriptives.do`). Skipped for now.

**Options if ISIC is needed later:**
- (a) Map via the 102,403 company_id overlap between ADB and 20-year companies
      (merge `job_isic_sec` from ADB onto 20-year companies by `company_id`)
- (b) Use Rozee's own `industry_str` directly as a sector variable
- (c) Build a new ISIC crosswalk from `industry_str` labels manually

### 35K ADB-only jids
The ADB dataset contains 35,545 job IDs not present in `jobs_int.dta` (~10.5% of
the ADB sample). These were likely included in ADB's supplementary data request.
They are excluded from this 20-year analysis by design.

### Three-level matching (main/less/great) not replicated
The original pipeline produced three CSV files at different matching thresholds.
This rebuild uses a single Claude Haiku pass per unique title. If match quality
is a concern, the Python script can be re-run with modified prompting or a
smaller batch size.

**Validation:** Compare DiD results on the 2020–2022 overlap window to the
original ADB results (`Drafts/v1/Tables/did_postings_gpt.tex`). Expect directional
consistency; exact magnitudes may differ due to broader job coverage and different
salary construction.

### Education encoding
ADB `education_level` (ordinal 0–5) was reconstructed from 20-year `min_education_str`
using this mapping in `03_analysis_demand_20yr.do`:

| Value | Labels |
|---|---|
| 0 | Non-Matriculation |
| 1 | Matriculation/O-Level |
| 2 | Intermediate/A-Level |
| 3 | Bachelors, Diploma, Certification, Short Course |
| 4 | Masters, M-Phill, MBBS, ACCA, CA, Pharm-D, MD, BDS |
| 5 | Doctorate |

### Salary hidden field
`sal_from_num` is missing for ~54% of 20-year jobs, but `sal_from_hide_num`
fills in an additional 315K observations. The analysis combines both:
`salary_from = cond(!missing(sal_from_num), sal_from_num, sal_from_hide_num)`.
This is equivalent to what the ADB cleaning did with `salary_from_clean`.

## Pipeline

```
Step 1  00_export_jobs.do      → data/jobs_export.csv
Step 2  01_soc_match.py        → data/pipeline/tmain_match_tasks.csv + 2 others
Step 3  02_prep_data_20yr.do   → data/extracted_tasks_ai_20yr.dta
                                 data/job_titles_soc_20yr.dta
Step 4  03_analysis_demand_20yr.do → output/tables/ + output/figures/
```

Run with: `bash run.sh`

Skip completed steps: `bash run.sh --skip-export --skip-match` (reruns from Step 3)

The SOC matching step (Step 2) caches results to `data/pipeline/soc_cache.json`
and can be safely interrupted and resumed.

## Output Layout

- `output/logs/` — Stata/Python pipeline logs
- `output/tables/` — regression tables (`did_*_20yr_*.tex`)
- `output/figures/` — event-study figures (`es_*_20yr_*.png`)
- `output/report/` — report source and compiled PDF

## Reference Files (read-only)
- `full_labelset.tsv` — Eloundou et al. (2024) O*NET task + AI exposure labels
- `soc_structure.dta` — SOC hierarchy (reused from ADB run, no rebuild needed)
- `jobs_int.dta` / `companies_int.dta` — 20-year Rozee.pk data
