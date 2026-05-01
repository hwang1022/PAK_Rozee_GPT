# Rozee Project Memory: Analyses Completed So Far

Last reviewed: April 30 2026

Summary created by HW and Codex

## Purpose of This Project

The project uses Rozee.pk labor-market platform data to understand job postings, applicants, firms, applications, salary expectations, RozeeGPT/Rozeena activity, and the relationship between AI exposure and labor-market outcomes in Pakistan.

The work so far has two broad goals:

1. Build reliable cleaned and analysis-ready Rozee datasets from multiple raw extracts.
2. Use those data to study labor-market patterns, especially salary expectations and whether occupations more exposed to generative AI changed differently after the public launch of ChatGPT in November 2022.

## High-Level Map

| Strand | Main Question / Goal | Main Code Locations | Main Data Used | Main Outputs / Findings |
|---|---|---|---|---|
| 1. Core Rozee data description | What is in the Rozee ADB extract, and what are the basic data quality issues? | `Analysis/Code/Descriptives/02 Data Description.do` | ADB Rozee extract: applications, jobs, companies, users, education, experience, language, skill, metadata files | `Analysis/Output/Rozee_description/Rozee_description.pdf` |
| 2. Rozee sanity checks and exploratory descriptives | Do key variables behave sensibly, and what deeper descriptive patterns appear? | `Analysis/Code/Descriptives/03 Data Description_v2_part1.do`; `03 Data Description_v2_part2.do`; `04 Shapefile.do` | ADB Rozee extract plus cross-file merges and Pakistan shapefile/geography data | `Analysis/Output/Rozee_description_v2/Rozee_description_v2.pdf` |
| 3. Salary expectations and application behavior | Are application-level expected salaries meaningful, and how do they relate to shortlisting and job salary ranges? | `Analysis/Code/Descriptives/05 Salary Exp.do` | Application-level expected/current salary data linked to job-posting salary data | `Analysis/Output/Rozee_expsal/Rozee_expsal.pdf` |
| 4. RozeeGPT / Rozeena preparation and exploration | What is in the RozeeGPT/Rozeena extract, how clean is it, and how can it be merged into analysis samples? | `Analysis/Code/RozeeGPT`; `Analysis/Code/Memos/RozeeGPT_*.do` | RozeeGPT/Rozeena users, jobs, companies, applications, applicant profiles, education, experience, skills, and CV/chat data | Cleaned `.dta` files and memo-generation code; no polished compiled report found in `Analysis/Output` |
| 5. AI exposure and labor-market effects | Did high-AI-exposure occupations experience different changes in postings and wages after ChatGPT? | `RozeeAI_exposure/Code and Data/Dofiles`; `RozeeAI_exposure/20yr_analysis/code` | Cleaned Rozee job/company data linked to SOC/O*NET task data and AI-exposure labels | `RozeeAI_exposure/Drafts/Rozee_AI.pdf`; `RozeeAI_exposure/20yr_analysis/output/report/20yr_results_report.pdf` |

## Strand 1: Core Rozee Data Description

### Goal

Document the structure, scale, and basic quality of the ADB Rozee extract. This strand is mostly descriptive and is meant to help readers understand the raw platform data before moving to research analysis.

### Data Used

The main ADB Rozee platform extract, including:

- Applications
- Job postings
- Companies
- Users / candidates
- User education
- User experience
- User languages
- User skills
- Job skills
- Deleted jobs
- Quick questions / answers
- Test-builder questions / answers
- Metadata: countries, cities, areas, skills

### Analyses Done

- Dataset-level sample sizes and identifiers
- Mergeability checks across users, jobs, companies, and applications
- Missingness and variable coverage checks
- Time distributions of applications, jobs, companies, and user creation
- Salary summaries for users, jobs, and applications
- Skill and language distributions
- Basic education, experience, and career-level summaries

### Findings / Outputs

Main report:

- `Analysis/Output/Rozee_description/Rozee_description.pdf`

Main code:

- `Analysis/Code/Descriptives/02 Data Description.do`

Important takeaways from the report include:

- The ADB application data cover a very large number of applications from 2020 to 2025.
- The job data may be incomplete relative to applications, since many application records point to job IDs that do not merge to the job file.
- Metadata files exist for country/city/area/skill IDs, but some metadata fields have quality issues, especially skill-name duplication/encoding and missing city geocoordinates.

## Strand 2: Rozee Sanity Checks and Exploratory Descriptives

### Goal

Go beyond basic documentation and check whether key economic variables are internally coherent. This strand asks whether the variables behave in ways that make sense before using them in downstream analysis.

### Data Used

Mostly the same ADB Rozee extract as Strand 1, but with more active linking across:

- Job postings
- Applications
- Companies
- Users
- Job skills
- User skills
- User experience
- User education
- Geography/shapefile data

### Analyses Done

Job-side checks:

- Salary versus required experience
- Career level versus required experience
- Salary versus career level
- Cleanliness of minimum and maximum experience fields
- Salary/career level versus age requirements
- Application duration and number of applications received
- Total positions versus company size
- Applicant current/expected salary versus job salary
- Geographic distribution of jobs, high-level jobs, low-level jobs, and salary
- Salary range size and its relationship to job/company characteristics
- Application timing after job creation
- Quick-question usage by job/company attributes
- Skill counts and skill importance versus salary, career level, and applications received

User/application checks:

- Age distribution and age versus work experience
- User salary/current salary versus career level
- Salary gap and team-management experience
- Salary gap by gender, age, experience, skill count, geography, and time
- Application volume by user, gender, and year
- Breadth of industries in a user's application history
- Salary expectation gap over application order

### Findings / Outputs

Main report:

- `Analysis/Output/Rozee_description_v2/Rozee_description_v2.pdf`

Main code:

- `Analysis/Code/Descriptives/03 Data Description_v2_part1.do`
- `Analysis/Code/Descriptives/03 Data Description_v2_part2.do`
- `Analysis/Code/Descriptives/04 Shapefile.do`

Important takeaways from the report include:

- Required experience, career level, age requirements, and salary generally move in expected directions.
- The `req_experience` field is messier than `max_experience`, though most problematic formats cover relatively few jobs.
- Application duration, quick-question usage, skill counts, salary ranges, and company size all received exploratory treatment, but these are descriptive rather than causal analyses.

## Strand 3: Salary Expectations and Application Behavior

### Goal

Study whether application-level expected salary is meaningful and how it relates to applicant behavior and employer outcomes.

This strand focuses on the fact that every Rozee application records a user-reported expected salary and current salary, which creates a dynamic application-level salary-expectation panel.

### Data Used

Mainly:

- Rozee ADB application data, especially expected salary, current salary, application date, applicant ID, job ID, and employer status/shortlisting information
- Rozee ADB job data, especially posted salary ranges and whether salary is visible/hidden

### Analyses Done

- Quality check: how much expected salary varies within user over 1 month, 1 quarter, 1 year, and the full 4.5-year window
- Distribution of expected salary within a user's own historical salary-expectation range
- Regression of shortlisting on log expected salary, with combinations of user fixed effects and job fixed effects
- Comparison of self-reported expected salary to posted job salary ranges
- Evolution of expected salary and salary expectation gaps as users submit more applications
- Initial setup for job-search-cycle analysis, though not all listed cycle outputs appear in the compiled report

### Findings / Outputs

Main report:

- `Analysis/Output/Rozee_expsal/Rozee_expsal.pdf`

Main code:

- `Analysis/Code/Descriptives/05 Salary Exp.do`

Important findings in the report:

- Many users vary expected salary across applications, suggesting the variable has usable signal rather than being entirely stale/defaulted.
- In the shortlisting sample, about 10% of applications are shortlisted.
- Regression results show that, after controlling for both user and job fixed effects, higher log expected salary is associated with a lower probability of shortlisting. The coefficient is statistically significant but small.
- For visible salary postings, many applicants report expected salaries inside the posted salary range, with notable mass near the lower bound.
- The report notes a puzzling pattern: even when salary is hidden, expected salaries appear highly consistent with the true salary range, and this needs clarification from Rozee.
- Over application order, expected salary tends to rise, while the salary expectation gap/confidence measure tends to fall.

## Strand 4: RozeeGPT / Rozeena Preparation and Exploration

### Goal

Clean, document, and explore the RozeeGPT/Rozeena data so it can be used in later analysis. This strand is currently more data-audit/sample-construction work than a finalized research analysis.

### Data Used

RozeeGPT/Rozeena extract files, including:

- Users
- Companies
- Jobs
- Applications
- Applicant personal information
- Applicant education
- Applicant experience
- User skills
- Job skills
- Application skills
- Country metadata
- CV/chat data, including chat sessions and cleaned chat responses where available

### Analyses / Processing Done

Pipeline code in `Analysis/Code/RozeeGPT`:

- Converts raw CSVs to Stata `.dta`
- Cleans users, companies, jobs, applications, applicant personal info, education, and experience
- Creates variables such as:
  - Dates and years
  - User age
  - PPP-adjusted current salary
  - Job created/updated/published/apply-by dates
  - Hide-salary and manage-employees indicators
  - Required experience min/max fields
  - Maximum budget
  - Job skill counts
  - Application scores and skill counts

Memo/exploration code in `Analysis/Code/Memos`:

- Missingness tables for users, companies, jobs, applications, applicant personal info, education, and experience
- User descriptives: age, country, skill counts, creation year, salary
- Company descriptives: creation timing and missingness
- Job descriptives: budget, required experience, subordinates, job skill counts, creation/update/publish/apply-by timing
- Application descriptives: scores, test/video/coding/overall score fields, employer status, skills
- Applicant-profile reshaping: education and experience histories are reshaped wide for merging
- Merged application dataset construction combining jobs, users, companies, applications, applicant education, applicant experience, and personal info
- Core sample construction and Rozeena/chat overlap checks

### Findings / Outputs

Main code:

- `Analysis/Code/RozeeGPT/0.master_gpt.do`
- `Analysis/Code/RozeeGPT/1.creation_gpt.do`
- `Analysis/Code/RozeeGPT/2.cleaning_gpt.do`
- `Analysis/Code/RozeeGPT/3.vars_creation_gpt.do`
- `Analysis/Code/Memos/RozeeGPT_dive0.do`
- `Analysis/Code/Memos/RozeeGPT_dive1.do`
- `Analysis/Code/Memos/RozeeGPT_memo.do`

Main output status:

- Cleaned and variable-created `.dta` outputs are produced under the `Data/Cleaned/RozeeGPT` and `Data/Analysis/RozeeGPT` paths referenced by the scripts.
- Memo scripts write tables/figures to `Tex/Aux/RozeeGPT_memo/inputs` and temporary merged data to `Data/temp`, according to the code.
- No polished compiled RozeeGPT/Rozeena report was found in `Analysis/Output` during this review.

Important caveat:

- This strand should be treated as in-progress exploratory infrastructure. It is not yet a completed empirical analysis with a single final report.

## Strand 5: AI Exposure and Labor-Market Effects

### Goal

Ask whether occupations with higher generative-AI exposure experienced different labor-market changes after the public launch of ChatGPT in November 2022.

The high-level research question is:

> Did public access to ChatGPT change labor demand and posted wages in Pakistan, especially for occupations whose tasks are more exposed to generative AI?

### Data Used

Two related data systems are used.

ADB-window analysis:

- Cleaned Rozee ADB job and company data
- SOC/O*NET job-title and occupation mappings
- Extracted O*NET task rows for Rozee jobs
- Eloundou / GPTs-are-GPTs task-level AI exposure labels
- SOC hierarchy / broad occupation structure

20-year extension:

- Full 20-year Rozee job data
- Full 20-year Rozee company data
- Exported job data from `jobs_int.dta`
- SOC/O*NET task labels from `full_labelset.tsv`
- Claude Haiku title-to-SOC matching output
- Constructed task-level and occupation-level AI-exposure files

### Analyses Done

Data preparation:

- Merge Rozee job postings with company data, SOC occupation data, and task-level AI-exposure data
- Convert task-level exposure labels into job-level measures
- Aggregate job-level exposure to occupation-level exposure using pre-ChatGPT postings
- Construct occupation-month panels
- Define posted wage as salary midpoint, trimming extreme salary values

Exposure measures:

- `alpha`: share of tasks labelled directly exposed to LLMs
- `beta`: direct exposure plus half weight on complementary/software-assisted exposure
- `gamma`: direct plus complementary/software-assisted exposure fully counted
- Each measure is computed using both human ratings and GPT ratings

Descriptive analysis:

- AI exposure distribution across job postings
- AI exposure by sector
- AI exposure by posted salary
- AI exposure by education requirement
- AI exposure by experience requirement
- AI exposure by number of tasks extracted

Empirical analysis:

- Continuous difference-in-differences at the occupation-month level
- Treatment intensity is occupation-level AI exposure
- Shock/post period begins in November 2022
- Outcomes:
  - log monthly job postings by occupation
  - log posted wages by occupation-month
- Fixed effects:
  - occupation fixed effects
  - month fixed effects
- Event-study specifications interact AI exposure with month-relative-to-ChatGPT indicators to check pre-trends and visualize dynamics

### Findings / Outputs

Original ADB-window report:

- `RozeeAI_exposure/Drafts/Rozee_AI.pdf`

Original ADB-window code:

- `RozeeAI_exposure/Code and Data/Dofiles/prep_data.do`
- `RozeeAI_exposure/Code and Data/Dofiles/descriptives.do`
- `RozeeAI_exposure/Code and Data/Dofiles/analysis_demand.do`

Original ADB-window findings:

- The draft concludes that higher-AI-exposure occupations experienced relative declines in job postings and wages after ChatGPT.
- Key table outputs are in `RozeeAI_exposure/Drafts/v1/Tables`.
- Key figure outputs are in `RozeeAI_exposure/Drafts/v1/Figures`.

20-year extension report:

- `RozeeAI_exposure/20yr_analysis/output/report/20yr_results_report.pdf`

20-year extension code:

- `RozeeAI_exposure/20yr_analysis/code/00_export_jobs.do`
- `RozeeAI_exposure/20yr_analysis/code/01_soc_match.py`
- `RozeeAI_exposure/20yr_analysis/code/02_prep_data_20yr.do`
- `RozeeAI_exposure/20yr_analysis/code/03_analysis_demand_20yr.do`
- `RozeeAI_exposure/20yr_analysis/run.sh`

20-year extension findings:

- The 20-year extension uses 740,657 job postings from 2004-2024.
- The SOC matching pipeline outputs 677,087 jobs with matched SOC/task output and 10,016,893 task rows.
- Postings results differ from the original ADB-window analysis: the 20-year report estimates positive post-ChatGPT posting effects for higher-exposure occupations under the human beta and GPT beta measures.
- Wage results are mostly null, except for a positive GPT-alpha wage estimate.
- The report notes that the 20-year analysis does not use ISIC sector controls because ISIC sector is not available in the 20-year company data.

Important caveats:

- The original ADB-window results and the 20-year extension point in different directions for labor demand.
- The 20-year extension uses a different SOC-matching method: Claude Haiku single-pass title-to-SOC matching rather than the original GPT-4 three-threshold matching pipeline.
- The 20-year extension excludes ADB-only job IDs that are not present in the 20-year data.
- The empirical strategy relies on a parallel-trends assumption: absent ChatGPT, high- and low-AI-exposure occupations would have followed similar trends.

## Other Data Construction Work

### Rozee 20-Year Cleaning Pipeline

Separate from the AI-exposure extension, there is a general 20-year Rozee cleaning and variable-creation pipeline:

- `Analysis/Code/Rozee20years/0.master.do`
- `Analysis/Code/Rozee20years/1.creation.do`
- `Analysis/Code/Rozee20years/2.cleaning.do`
- `Analysis/Code/Rozee20years/3.vars_creation.do`

This pipeline converts raw CSVs, merges split files, cleans users/jobs/companies/applications, and creates intermediate analysis-ready datasets such as users, education, experience, companies, jobs, and application samples.

There is also exploratory memo code:

- `Analysis/Code/Memos/Rozee20years_memo.do`

This memo code appears to generate many tables and figures for users, education, experience, jobs, companies, and applications. During this review, no compiled 20-year memo report was found in `Analysis/Output`.

## Known Folder-Level Caveats

- Some scripts have user-specific root paths and may not run without editing globals.
- `Analysis/Code/Rozee20years/0.master.do` and `Analysis/Code/RozeeGPT/0.master_gpt.do` contain a standalone `x` before the `do` calls; this would likely stop Stata if run as-is.
- Some memo outputs are written outside `Analysis/Output`, especially to `Tex/Aux/...` and `Data/temp`, so a reader should inspect those paths if available.
- The AI-exposure analysis has two versions with different samples and matching procedures; they should not be treated as identical replications.
