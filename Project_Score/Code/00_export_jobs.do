/*==============================================================================
   00_export_jobs.do
   Export jobs_int.dta to CSV for the SOC matching Python pipeline.
   Drops deleted jobs and jobs without titles.
   Output: data/jobs_export.csv
 ==============================================================================*/

clear all
set more off
cap log close

global base     "`c(pwd)'"
global int_data "/Users/abrockell/Library/CloudStorage/Dropbox-HarvardUniversity/Alec Brockell/PAK_Rozee_GPT/Data/Analysis/Rozee20years/251008_Intermediate_Rozee20years"
global out      "${base}"

log using "${out}/output/logs/export_jobs.log", replace text

di "================================================================"
di "  00_export_jobs.do"
di "  Date: $S_DATE"
di "================================================================"

use "${int_data}/jobs_int.dta", clear

di _n "--- Initial obs ---"
count

//Drop deleted jobs
drop if isdeleted == 1

//Drop jobs with no title (only 4 total, confirmed in exploration)
drop if title == "" | missing(title)

di _n "--- After drops ---"
count

//Keep only variables needed by the pipeline and downstream analysis
keep jid title created_d created_yr created_mo company_id ///
     sal_from_num sal_from_hide_num sal_to_num sal_to_hide_num ///
     currency_unit req_exp_yrs min_education_str industry_id_num industry_str

di _n "--- Variable summary before export ---"
describe

//Export to CSV (for Python SOC matching pipeline)
export delimited "${out}/data/jobs_export.csv", replace

//Save .dta (for Stata merge in 03_analysis_demand_20yr.do)
save "${out}/data/jobs_export.dta", replace

di _n "--- Export complete ---"
count
di "Written to: ${out}/data/jobs_export.csv"
di "Written to: ${out}/data/jobs_export.dta"

log close
