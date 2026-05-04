/*==============================================================================
   02_prep_data_20yr.do
   Simplified adaptation of the original prep_data.do for the 20-year dataset.

   Key differences from original:
     - Single matching level only (main); no "less" or "great" variants
     - jidmissing branch removed (all 20-year jobs have valid jids)
     - Task text + Eloundou labels read from full_labelset.tsv
       (replaces Task Statements.xlsx + eloundou_onet_tasks.tsv)
     - soc_structure.dta reused from ADB run (already built)
     - Outputs: extracted_tasks_ai_20yr.dta, job_titles_soc_20yr.dta

   Input CSVs (from 01_soc_match.py):
     data/pipeline/jobsdesc_extract.csv
     data/pipeline/tmain_match_tasks.csv
     data/pipeline/jobsdesc_onetsoc_tmain.csv

   Reference files (read-only from Dropbox):
     full_labelset.tsv   -- O*NET tasks + Eloundou exposure labels combined
     soc_structure.dta   -- SOC hierarchy (reused from ADB run)
 ==============================================================================*/

clear all
set more off
cap log close

local full_pwd  "`c(pwd)'"
local lastslash = strrpos("`full_pwd'", "/")

global base     "`full_pwd'"
global project  = substr("`full_pwd'", 1, `lastslash' - 1)
global pipeline "${base}/data/pipeline"
global data_out "${base}/data"
global adb_data "${project}/Code and Data/Analysis Data"
global labelset "${project}/Reference Code/GPTs-are-GPTs-main/data/full_labelset.tsv"

log using "${base}/output/logs/prep_data.log", replace text

di "================================================================"
di "  02_prep_data_20yr.do"
di "  Date: $S_DATE"
di "================================================================"


/*==============================================================================
   SECTION 1: Load main extraction output
 ==============================================================================*/

di _n "--- Loading jobsdesc_extract.csv ---"
import delimited "${pipeline}/jobsdesc_extract.csv", ///
	varnames(1) clear bindquote(strict) maxquotedrows(1000)

keep job_id jid num_tasks
destring jid job_id num_tasks, replace force
drop if jid == .
save "${data_out}/jobids.dta", replace
count
di "  jobids: `r(N)'"


/*==============================================================================
   SECTION 2: Load and clean matched task rows
 ==============================================================================*/

di _n "--- Loading tmain_match_tasks.csv ---"
import delimited "${pipeline}/tmain_match_tasks.csv", ///
	varnames(1) clear bindquote(strict) maxquotedrows(1000)

order jid job_id title onet_task_id onet_task_text onet_soc_code occupation_title
destring jid job_id onet_task_id, replace force

gen filetype = 1
label def filetype 1 "Main"
label val filetype filetype

//Rank within job (order of tasks)
sort jid onet_task_id
bysort jid (onet_task_id): gen rank = _n

//Merge job counts
merge m:1 jid job_id using "${data_out}/jobids.dta", keep(match master)
drop if jid == .
drop _merge

di _n "--- After loading tasks ---"
count
codebook jid

//Cap at 15 tasks per job (matches original pipeline)
drop if rank > 15
bysort jid: egen n_tasks = count(onet_task_id)

di _n "--- After capping at 15 tasks per job ---"
count
sum n_tasks, detail

save "${data_out}/matched_tasks_20yr.dta", replace


/*==============================================================================
   SECTION 3: Merge with full_labelset.tsv (task text + Eloundou labels)
   full_labelset.tsv has: O*NET-SOC Code, Task ID, Task, Task Type, Title,
   human_exposure_agg, gpt4_exposure, gpt4_exposure_alt_rubric, gpt_3_relevant,
   gpt4_automation, alpha, beta, gamma, automation, human_labels
 ==============================================================================*/

di _n "--- Loading full_labelset.tsv ---"
preserve
import delimited "${labelset}", varnames(1) clear

//Normalise column names
rename v1             row_index
rename onetsoccode    onet_soc_code_ref
rename taskid         onet_task_id_ref
rename task           onet_task_text_ref
rename title          occupation_title_ref

//Keep only the fields needed for merging
destring onet_task_id_ref, replace force
drop if missing(onet_task_id_ref)

//Rename for merge
rename onet_task_id_ref onet_task_id

tempfile labelset_data
save `labelset_data', replace
restore

//Merge on onet_task_id (m:1 — multiple jobs may match to same O*NET task)
merge m:1 onet_task_id using `labelset_data', nogen keep(match master)

di _n "--- After Eloundou merge ---"
count
codebook human_exposure_agg gpt4_exposure

//Overwrite task text and SOC code with O*NET canonical versions
//where available (more accurate than what came from Python)
cap replace onet_task_text   = onet_task_text_ref   if !missing(onet_task_text_ref)
cap replace onet_soc_code    = onet_soc_code_ref    if !missing(onet_soc_code_ref)
cap replace occupation_title = occupation_title_ref if !missing(occupation_title_ref)
cap drop onet_task_text_ref onet_soc_code_ref occupation_title_ref row_index

sort jid onet_task_id

//Save the full task-level AI exposure file
save "${data_out}/extracted_tasks_ai_20yr.dta", replace

di _n "--- Saved extracted_tasks_ai_20yr.dta ---"
count


/*==============================================================================
   SECTION 4: Build job_titles_soc_20yr.dta
   (one row per jid: jid, title, job_id, max_broad_occupation)
 ==============================================================================*/

di _n "--- Building job_titles_soc_20yr.dta ---"

//Load SOC assignment from Python output
import delimited "${pipeline}/jobsdesc_onetsoc_tmain.csv", ///
	varnames(1) clear bindquote(strict) maxquotedrows(1000)

destring jid job_id, replace force
drop if jid == .

//Get job titles from matched tasks
preserve
use "${data_out}/extracted_tasks_ai_20yr.dta", clear
keep job_id jid title
duplicates drop
tempfile jobs_title
save `jobs_title', replace
restore

//Merge in titles
merge m:1 job_id using `jobs_title', nogen keep(match master)

//Merge with SOC hierarchy (reuse soc_structure.dta from ADB run)
rename onet_soc_code DetailedOccupation
merge m:1 DetailedOccupation using "${adb_data}/soc_structure.dta", nogen keep(match master)

order jid title major_occupation_title minor_occupation_title broad_occupation_title onet_occupation
gsort + jid

//Modal occupation at each level (where a job has multiple task-SOC entries)
bysort jid: egen max_major_group     = mode(major_occupation_title), minmode
bysort jid: egen max_minor_group     = mode(minor_occupation_title), minmode
bysort jid: egen max_broad_occupation = mode(broad_occupation_title), minmode

keep jid title job_id max_broad_occupation
duplicates drop
drop if jid == .

di _n "--- job_titles_soc_20yr summary ---"
count
codebook jid
tabulate max_broad_occupation, sort

save "${data_out}/job_titles_soc_20yr.dta", replace

di _n "--- Saved job_titles_soc_20yr.dta ---"

//Clean up temp file
cap erase "${data_out}/matched_tasks_20yr.dta"
cap erase "${data_out}/jobids.dta"

di _n "================================================================"
di "  02_prep_data_20yr.do complete"
di "================================================================"

log close
