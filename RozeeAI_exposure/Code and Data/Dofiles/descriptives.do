clear all 

cap log close 
set more off 

global path "D:\Dropbox\Rozee AI Project"
global data "${path}/Code and Data/Analysis Data"

global tables "${path}/Drafts/v1/Tables"
global graphs "${path}/Drafts/v1/Figures"


/*==============================================================================
	Set up data: Job postings and AI exposure
 ==============================================================================*/

//Merge job postings with AI exposure data and job titles
use "${data}/Rozee/jobs_adb_clean.dta", clear

rename city_id company_city_id
merge m:1 company_id using "${data}/Rozee/companies_adb_clean.dta", nogen keep(match master)
merge 1:1 jid using "${data}/job_titles_soc.dta", nogen keep(match master)

merge 1:m jid using "${data}/extracted_tasks_ai.dta", nogen keep(match master)

drop created_date
order jid onet_task_id onet_task_text job_created_date
sort jid onet_task_id

//Trim down to main sample years
gen year = year(job_created_date)
drop if year <= 2019 | year > 2025

//AI Exposure variable
cap drop ai_*
gen ai_exposure_human = 0 if human_exposure_agg == "E0"
replace ai_exposure_human = 1 if human_exposure_agg == "E1"
replace ai_exposure_human = 0.5 if human_exposure_agg == "E2"

gen ai_exposure_gpt = 0 if gpt4_exposure == "E0"
replace ai_exposure_gpt = 1 if gpt4_exposure == "E1"
replace ai_exposure_gpt = 0.5 if gpt4_exposure == "E2"

//Checks 
cap drop check_*
gen check_ai = beta == ai_exposure_gpt 
tab check_ai
drop check_ai 

//Aggregate to job-onet-month level
collapse (mean) ai_exposure_gpt ai_exposure_human, by(jid job_created_date job_isic_sec)

save "${data}/jobs_ai_exposure.dta", replace

/*==============================================================================
	AI Exposure of tasks vs percentage of occupations
 ==============================================================================*/
 
use "${data}/jobs_ai_exposure.dta", clear

* Drop rows with missing exposure
drop if missing(ai_exposure_gpt) & missing(ai_exposure_human)

* Convert to percent scale (0–100)
gen ai_exposure_gpt_pct   = ai_exposure_gpt   * 100
gen ai_exposure_human_pct = ai_exposure_human * 100

tempfile cdfdata
tempname mem
postfile `mem' threshold pct_gpt pct_human using `cdfdata', replace

* Get total number of job postings
count
local total = r(N)

* Loop over exposure thresholds
forvalues t = 0(1)100 {
    quietly count if ai_exposure_gpt_pct   >= `t'
    local pct_gpt = 100 * r(N) / `total'

    quietly count if ai_exposure_human_pct >= `t'
    local pct_human = 100 * r(N) / `total'

    post `mem' (`t') (`pct_gpt') (`pct_human')
}
postclose `mem'
use `cdfdata', clear

twoway ///
    (line pct_gpt threshold, lcolor(stblue)) ///
    (line pct_human threshold, lcolor(red)), ///
    xtitle("Percent of AI-exposed tasks in job posting") ///
    ytitle("Percent of job postings") ///
    ylabel(0(20)100, grid) xlabel(0(20)100) ///
    legend(order(1 "GPT measure" 2 "Human measure") position(6) row(1)) ///
	note("N = 330184, covering 2020-2025Apr")
graph export "${graphs}/ai_exposure_cdf.png", replace

/*==============================================================================
	AI Exposure by broad Sector
 ==============================================================================*/

use "${data}/jobs_ai_exposure.dta", clear
drop if missing(job_isic_sec)

* Total stats
quietly summarize ai_exposure_human
local total_mean_h = r(mean)
local total_sd_h   = r(sd)
quietly summarize ai_exposure_gpt
local total_mean_g = r(mean)
local total_sd_g   = r(sd)
quietly count
local total_n = r(N)

* Collapse
collapse ///
    (mean) ai_exposure_gpt ai_exposure_human ///
    (sd)   sd_gpt=ai_exposure_gpt sd_human=ai_exposure_human ///
    (count) n=jid, ///
    by(job_isic_sec)

* Convert sector to string using value labels (if any)
decode job_isic_sec, gen(sector)
drop job_isic_sec
rename sector job_isic_sec

* Append total row
tempfile sectorstats
save `sectorstats'

clear
set obs 1
gen job_isic_sec = "Total"
gen ai_exposure_human = `total_mean_h'
gen sd_human          = `total_sd_h'
gen ai_exposure_gpt   = `total_mean_g'
gen sd_gpt            = `total_sd_g'
gen n                 = `total_n'

append using `sectorstats'

gen is_total = (job_isic_sec=="Total")
sort is_total job_isic_sec
drop is_total

order job_isic_sec ai_exposure_human sd_human ai_exposure_gpt sd_gpt n

export excel using "${tables}/ai_exposure_by_sector.xlsx", firstrow(variables) replace



/*==============================================================================
	Wages 
 ==============================================================================*/

use "${data}/jobs_ai_exposure.dta", clear

merge 1:1 jid using "${data}/Rozee/jobs_adb_clean.dta", nogen keep(match master)

gen salary_mid = .
replace salary_mid = (salary_from_clean + salary_to_clean)/2 if !missing(salary_from_clean, salary_to_clean)
replace salary_mid = salary_from_clean if missing(salary_to_clean) & !missing(salary_from_clean)
replace salary_mid = salary_to_clean if missing(salary_from_clean) & !missing(salary_to_clean)

sum salary_mid, detail
replace salary_mid = . if salary_mid > `r(p99)'

* Generate custom bins
gen salary_bin = .
replace salary_bin =  5000  if inrange(salary_mid, 0, 10000)
replace salary_bin = 15000  if inrange(salary_mid,10001,20000)
replace salary_bin = 25000  if inrange(salary_mid,20001,30000)
replace salary_bin = 35000  if inrange(salary_mid,30001,40000)
replace salary_bin = 45000  if inrange(salary_mid,40001,50000)
replace salary_bin = 60000  if inrange(salary_mid,50001,70000)
replace salary_bin = 80000  if inrange(salary_mid,70001,90000)
replace salary_bin =100000  if inrange(salary_mid,90001,110000)
replace salary_bin =130000  if inrange(salary_mid,110001,150000)
replace salary_bin =170000  if salary_mid > 150000 

* Collapse to mean Human exposure per bin
collapse (mean) mean_exposure = ai_exposure_human ///
         (semean) se_exposure = ai_exposure_human ///
         (count) N=jid, by(salary_bin)
      
gen ci_upper_avg = mean_exposure + 1.96 * se_exposure 
gen ci_lower_avg = mean_exposure - 1.96 * se_exposure

* Polynomial (quadratic) fit with 95% CI
twoway (scatter mean_exposure salary_bin) ///
      (line mean_exposure salary_bin, lcolor(black)) ///
      (line ci_upper_avg salary_bin, lpattern(dash) lcolor(gray)) ///
      (line ci_lower_avg salary_bin, lpattern(dash) lcolor(gray)), ///
      legend(order(1 "Mean AI exposure" 2 "Non-parametric fit" 3 "95% CI" 4 "95% CI") pos(6) row(1) size(small)) ///
      xtitle("Mid-point of disclosed wage range (PKR)", size(small)) ///
      ytitle("Mean AI exposure (Human Rating)", size(small)) ///
      ylabel(, labsize(small)) xlabel(, labsize(small)) ///
	note("N = 330184, covering 2020-2025Apr")
graph export "${graphs}/ai_exposure_salary.png", replace


/*==============================================================================
	Experience 
 ==============================================================================*/

use "${data}/jobs_ai_exposure.dta", clear

merge 1:1 jid using "${data}/Rozee/jobs_adb_clean.dta", nogen keep(match master)

fre req_experience_clean
replace req_experience_clean = 8 if req_experience_clean > 8 

label def expband_lbl 8 "10+ years", modify 

* Collapse to mean AI exposure per experience band
collapse (mean) mean_exposure = ai_exposure_human ///
         (semean) se_exposure = ai_exposure_human ///
         (count) N=jid, by(req_experience_clean)

gen ci_upper_avg = mean_exposure + 1.96 * se_exposure
gen ci_lower_avg = mean_exposure - 1.96 * se_exposure

* Polynomial (quadratic) fit with 95% CI
twoway (scatter mean_exposure req_experience_clean) ///
      (line mean_exposure req_experience_clean, lcolor(black)) ///
      (line ci_upper_avg req_experience_clean, lpattern(dash) lcolor(gray)) ///
      (line ci_lower_avg req_experience_clean, lpattern(dash) lcolor(gray)), ///
      legend(order(1 "Mean AI exposure" 2 "Non-parametric fit" 3 "95% CI" 4 "95% CI") pos(6) row(1) size(small)) ///
      xtitle("Required experience (years)", size(small)) ///
      ytitle("Mean AI exposure (Human Rating)", size(small)) ///
      ylabel(, labsize(small)) xlabel(, labsize(small)) ///
	note("N = 330184, covering 2020-2025Apr")
graph export "${graphs}/ai_exposure_experience.png", replace

/*==============================================================================
	Education 
 ==============================================================================*/

use "${data}/jobs_ai_exposure.dta", clear

merge 1:1 jid using "${data}/Rozee/jobs_adb_clean.dta", nogen keep(match master)

* Generate new grouped education variable
cap drop edu_group
gen edu_group = .

replace edu_group = 1 if education_level == 0   // Less than Matriculation
replace edu_group = 2 if education_level == 1   // Matriculation
replace edu_group = 3 if education_level == 2   // Intermediate (A-Level)
replace edu_group = 4 if education_level == 3   // Undergraduate
replace edu_group = 5 if inlist(education_level, 4, 5)   // Postgraduate or Professional/Other

* Label the groups
label define edu_group_lbl ///
    1 "< High School" ///
    2 "High School" ///
    3 "Diploma" ///
    4 "Bachelors Degree" ///
    5 "Postgrad"

label values edu_group edu_group_lbl
label var edu_group "Education group"

* Collapse to mean AI exposure per education group
collapse (mean) mean_exposure = ai_exposure_human ///
         (semean) se_exposure = ai_exposure_human ///
         (count) N=jid, by(edu_group)

gen ci_upper_avg = mean_exposure + 1.96 * se_exposure
gen ci_lower_avg = mean_exposure - 1.96 * se_exposure

* Polynomial (quadratic) fit with 95% CI
twoway (scatter mean_exposure edu_group) ///
      (line mean_exposure edu_group, lcolor(black)) ///
      (line ci_upper_avg edu_group, lpattern(dash) lcolor(gray)) ///
      (line ci_lower_avg edu_group, lpattern(dash) lcolor(gray)), ///
      legend(order(1 "Mean AI exposure" 2 "Non-parametric fit" 3 "95% CI") ///
             pos(6) row(1) size(small)) ///
      ytitle("Mean AI exposure (Human Rating)", size(small)) ///
      xtitle("", size(medsmall)) ///
      ylabel(, labsize(small)) ///
      xlabel(1(1)5, valuelabel labsize(small))  ///
	note("N = 330184, covering 2020-2025Apr")
graph export "${graphs}/ai_exposure_education.png", replace

/*==============================================================================
	Number of tasks and exposure
 ==============================================================================*/

//Get number of tasks per job
use "${data}/extracted_tasks_ai.dta", clear 
keep jid job_id num_tasks n_tasks 
duplicates drop
codebook jid 

tempfile num_tasks
save `num_tasks', replace

//Merge with main data
use "${data}/jobs_ai_exposure.dta", clear

merge 1:1 jid using "${data}/Rozee/jobs_adb_clean.dta", nogen keep(match master)
merge 1:1 jid using `num_tasks', nogen keep(match master)

gen num_task_clean = num_tasks if num_tasks <= 15
replace num_task_clean = 15 if num_tasks > 15

collapse (mean) ai_exposure_human ai_exposure_gpt ///
         (semean) se_human=ai_exposure_human se_gpt=ai_exposure_gpt ///
         (count) N=jid, by(num_task_clean)
gen ci_upper_human = ai_exposure_human + 1.96 * se_human
gen ci_lower_human = ai_exposure_human - 1.96 * se_human

graph twoway (scatter ai_exposure_human num_task_clean) ///
      (line ai_exposure_human num_task_clean, lcolor(black)) ///
      (line ci_upper_human num_task_clean, lpattern(dash) lcolor(gray)) ///
      (line ci_lower_human num_task_clean, lpattern(dash) lcolor(gray)), ///
      legend(order(1 "Mean AI exposure" 2 "Non-parametric fit" 3 "95% CI" 4 "95% CI") pos(6) row(1) size(small)) ///
      xtitle("Number of tasks extracted", size(small)) ///      
        xlabel(0(2.5)15, labsize(small)) ///
        ytitle("Mean AI exposure (Human Rating)", size(small)) ///
        ylabel(, labsize(small)) xlabel(, labsize(small)) ///
	note("N = 330184, covering 2020-2025Apr")

graph export "${graphs}/ai_exposure_num_tasks.png", replace

gen ci_upper_gpt = ai_exposure_gpt + 1.96 * se_gpt
gen ci_lower_gpt = ai_exposure_gpt - 1.96 * se_gpt

graph twoway (scatter ai_exposure_gpt num_task_clean) ///
      (line ai_exposure_gpt num_task_clean, lcolor(black)) ///
        (line ci_upper_gpt num_task_clean, lpattern(dash) lcolor(gray)) ///
        (line ci_lower_gpt num_task_clean, lpattern(dash) lcolor(gray)), ///
      legend(order(1 "Mean AI exposure" 2 "Non-parametric fit" ///
                3 "95% CI" 4 "95% CI") pos(6) row(1) size(small)) ///
        xtitle("Number of tasks extracted", size(small)) ///
        ytitle("Mean AI exposure (GPT Rating)", size(small)) ///
        ylabel(, labsize(small)) xlabel(, labsize(small))  ///
	note("N = 330184, covering 2020-2025Apr")

graph export "${graphs}/ai_exposure_num_tasks_gpt.png", replace
