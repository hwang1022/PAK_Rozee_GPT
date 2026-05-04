/*==============================================================================
   03_analysis_demand_20yr.do
   DiD and Event Study analysis: AI exposure × ChatGPT launch (Nov 2022)
   on occupation-level job postings and wages — 20-year dataset (2004–2024).

   Adapted from analysis_demand.do. Key changes:
     - Loads 20-year versions of datasets
     - Variable renames (job_created_date → created_d, salary fields)
     - Salary constructed from sal_from_num + sal_from_hide_num (hidden field)
     - Education ordinal built from min_education_str
     - Date range: 2004–2024 (vs 2020–2025 in ADB)
     - Event study covers full pre-period (2004–2024)

   Outputs (in output/):
     output/tables/did_postings_20yr_human.tex
     output/tables/did_postings_20yr_gpt.tex
     output/tables/did_wages_20yr_human.tex
     output/tables/did_wages_20yr_gpt.tex
     output/figures/es_postings_20yr_*.png
     output/figures/es_wages_20yr_*.png
 ==============================================================================*/

clear all
set more off
cap log close

global base     "`c(pwd)'"
global data     "${base}/data"
global tables   "${base}/output/tables"
global graphs   "${base}/output/figures"
global int_data "/Users/abrockell/Library/CloudStorage/Dropbox-HarvardUniversity/Alec Brockell/PAK_Rozee_GPT/Data/Analysis/Rozee20years/251008_Intermediate_Rozee20years"

cap mkdir "${base}/output/tables"
cap mkdir "${base}/output/figures"

log using "${base}/output/logs/analysis.log", replace text

di "================================================================"
di "  03_analysis_demand_20yr.do"
di "  Date: $S_DATE"
di "================================================================"


/*==============================================================================
   SECTION 1: Prepare data
 ==============================================================================*/

//Load job-task-AI-exposure data
use "${data}/extracted_tasks_ai_20yr.dta", clear

//Merge job-level source data first (adds company_id and other controls)
cap drop created_d  // safety: drop if somehow present before the merge
merge m:1 jid using "${data}/jobs_export.dta", keep(match master) nogen ///
	keepusing(jid created_d created_yr created_mo ///
	          company_id ///
	          sal_from_num sal_from_hide_num sal_to_num sal_to_hide_num ///
	          min_education_str req_exp_yrs industry_id_num industry_str)

//Merge company info (for city, but not ISIC — see README)
merge m:1 company_id using "${int_data}/companies_int.dta", ///
	keep(match master) nogen keepusing(company_id city_id_num city_name)

//Merge SOC occupation (one occupation row per jid)
merge m:1 jid using "${data}/job_titles_soc_20yr.dta", keep(match master) nogen

//Trim to analysis years (2004–2024)
drop if missing(created_yr)
drop if created_yr < 2004 | created_yr > 2024

di _n "--- Sample after year restriction ---"
count

/*--- Salary ---*/
//Combine main + hidden salary fields, then trim p99
gen salary_from = cond(!missing(sal_from_num) & sal_from_num > 0, ///
                       sal_from_num, sal_from_hide_num)
gen salary_to   = cond(!missing(sal_to_num)   & sal_to_num > 0, ///
                       sal_to_num,   sal_to_hide_num)

gen salary_mid = .
replace salary_mid = (salary_from + salary_to) / 2 ///
	if !missing(salary_from) & !missing(salary_to)
replace salary_mid = salary_from if !missing(salary_from) &  missing(salary_to)
replace salary_mid = salary_to   if  missing(salary_from) & !missing(salary_to)

//Trim at p99 (within 2004–2024 window)
sum salary_mid, detail
replace salary_mid = . if salary_mid > `r(p99)'

di _n "--- Salary coverage ---"
count if !missing(salary_mid)

/*--- AI Exposure variables (identical to original analysis_demand.do) ---*/
cap drop aiexp_*

gen aiexp_human_alpha = 0 if human_exposure_agg == "E0"
replace aiexp_human_alpha = 1 if human_exposure_agg == "E1"
replace aiexp_human_alpha = 0 if human_exposure_agg == "E2"

gen aiexp_human_beta = 0 if human_exposure_agg == "E0"
replace aiexp_human_beta = 1 if human_exposure_agg == "E1"
replace aiexp_human_beta = 0.5 if human_exposure_agg == "E2"

gen aiexp_human_gamma = 0 if human_exposure_agg == "E0"
replace aiexp_human_gamma = 1 if human_exposure_agg == "E1"
replace aiexp_human_gamma = 1 if human_exposure_agg == "E2"

gen aiexp_gpt_alpha = 0 if gpt4_exposure == "E0"
replace aiexp_gpt_alpha = 1 if gpt4_exposure == "E1"
replace aiexp_gpt_alpha = 0 if gpt4_exposure == "E2"

gen aiexp_gpt_beta = 0 if gpt4_exposure == "E0"
replace aiexp_gpt_beta = 1 if gpt4_exposure == "E1"
replace aiexp_gpt_beta = 0.5 if gpt4_exposure == "E2"

gen aiexp_gpt_gamma = 0 if gpt4_exposure == "E0"
replace aiexp_gpt_gamma = 1 if gpt4_exposure == "E1"
replace aiexp_gpt_gamma = 1 if gpt4_exposure == "E2"

//Consistency check
cap drop check_ai
gen check_ai = (beta == aiexp_gpt_beta)
tab check_ai
drop check_ai

/*--- Education ordinal (from min_education_str) ---*/
gen education_level = .
replace education_level = 0 if inlist(min_education_str, "Non-Matriculation")
replace education_level = 1 if inlist(min_education_str, "Matriculation/O-Level")
replace education_level = 2 if inlist(min_education_str, "Intermediate/A-Level")
replace education_level = 3 if inlist(min_education_str, "Bachelors", "Diploma", ///
                                      "Certification", "Short Course")
replace education_level = 4 if inlist(min_education_str, "Masters", "M-Phill", ///
                                      "MBBS", "ACCA", "CA", "Pharm-D", "MD", "BDS")
replace education_level = 5 if inlist(min_education_str, "Doctorate")

di _n "--- Education level distribution ---"
tabulate education_level


/*==============================================================================
   SECTION 2: Collapse to job level, then to occupation-month level
 ==============================================================================*/

//Aggregate AI exposure to job level (mean across tasks, as in original)
collapse (mean) aiexp_human_alpha aiexp_human_beta aiexp_human_gamma ///
                aiexp_gpt_alpha aiexp_gpt_beta aiexp_gpt_gamma, ///
         by(jid created_d created_yr max_broad_occupation salary_mid)

encode max_broad_occupation, gen(occupation)
drop if missing(occupation)

gen month = mofd(created_d)
format month %tm

gen post = (month >= tm(2022m11))

di _n "--- Job-level observations ---"
count

/*--- Pre-period AI exposure at occupation level (before ChatGPT launch) ---*/
preserve
keep if post == 0
collapse (mean) aiexp_human_alpha aiexp_human_beta aiexp_human_gamma ///
                aiexp_gpt_alpha aiexp_gpt_beta aiexp_gpt_gamma, by(occupation)

tempfile ai_exposure
save `ai_exposure', replace
restore

/*--- Collapse to occupation-month level ---*/
collapse (count) postings = jid (mean) salary_mid, by(occupation month)

merge m:1 occupation using `ai_exposure', nogen keep(match master)

gen log_postings = log(postings)
gen log_wages    = log(salary_mid)
gen post         = (month >= tm(2022m11))
gen year         = yofd(dofm(month))

di _n "--- Occupation-month panel ---"
count
sum postings log_postings salary_mid log_wages, detail

//Reshape to long on measure_type (alpha/beta/gamma)
reshape long aiexp_human_ aiexp_gpt_, i(occupation month) j(measure_type) string
rename aiexp_human_ aiexp_human
rename aiexp_gpt_   aiexp_gpt

di _n "--- Long panel ---"
count


/*==============================================================================
   SECTION 3: DiD Regressions
 ==============================================================================*/

//--- Postings: Human ---
eststo didpostings_hum_alpha: reghdfe log_postings c.aiexp_human##i.post ///
    if measure_type == "alpha", absorb(occupation month)
eststo didpostings_hum_beta:  reghdfe log_postings c.aiexp_human##i.post ///
    if measure_type == "beta",  absorb(occupation month)
eststo didpostings_hum_gamma: reghdfe log_postings c.aiexp_human##i.post ///
    if measure_type == "gamma", absorb(occupation month)

//--- Postings: GPT ---
eststo didpostings_gpt_alpha: reghdfe log_postings c.aiexp_gpt##i.post ///
    if measure_type == "alpha", absorb(occupation month)
eststo didpostings_gpt_beta:  reghdfe log_postings c.aiexp_gpt##i.post ///
    if measure_type == "beta",  absorb(occupation month)
eststo didpostings_gpt_gamma: reghdfe log_postings c.aiexp_gpt##i.post ///
    if measure_type == "gamma", absorb(occupation month)

//--- Wages: Human ---
eststo didwage_hum_alpha: reghdfe log_wages c.aiexp_human##i.post ///
    if measure_type == "alpha", absorb(occupation month)
eststo didwage_hum_beta:  reghdfe log_wages c.aiexp_human##i.post ///
    if measure_type == "beta",  absorb(occupation month)
eststo didwage_hum_gamma: reghdfe log_wages c.aiexp_human##i.post ///
    if measure_type == "gamma", absorb(occupation month)

//--- Wages: GPT ---
eststo didwage_gpt_alpha: reghdfe log_wages c.aiexp_gpt##i.post ///
    if measure_type == "alpha", absorb(occupation month)
eststo didwage_gpt_beta:  reghdfe log_wages c.aiexp_gpt##i.post ///
    if measure_type == "beta",  absorb(occupation month)
eststo didwage_gpt_gamma: reghdfe log_wages c.aiexp_gpt##i.post ///
    if measure_type == "gamma", absorb(occupation month)


/*--- Export tables ---*/
esttab didpostings_hum_alpha didpostings_hum_beta didpostings_hum_gamma ///
	using "${tables}/did_postings_20yr_human.tex", replace ///
	collabels(none) alignment(c) stats(N, fmt(%6.0fc)) ///
	cell(b(fmt(%5.3f) star) se(fmt(%5.3f) par)) label ///
	starlevels(* 0.10 ** 0.05 *** 0.01) nobaselevels ///
	mtitles("$\alpha$" "$\beta$" "$\gamma$") ///
	title("Impact of ChatGPT on job counts (Human rating, 20-year) \label{tab:did_postings_20yr_human}") ///
	drop(1.post aiexp_human) ///
	coeflabels(1.post#c.aiexp_human "Post-2022 x AI Exposure (Human)") ///
	substitute("\_" "_" {l} {p{0.7\linewidth}} [htbp] [h]) tex ///
	addnote("* p < 0.1; ** p < 0.05; *** p < 0.01. Standard errors in parentheses. Dependent variable is log of monthly job postings by occupation. Occupation and month fixed effects.")

esttab didpostings_gpt_alpha didpostings_gpt_beta didpostings_gpt_gamma ///
	using "${tables}/did_postings_20yr_gpt.tex", replace ///
	collabels(none) alignment(c) stats(N, fmt(%6.0fc)) ///
	cell(b(fmt(%5.3f) star) se(fmt(%5.3f) par)) label ///
	starlevels(* 0.10 ** 0.05 *** 0.01) nobaselevels ///
	mtitles("$\alpha$" "$\beta$" "$\gamma$") ///
	title("Impact of ChatGPT on job counts (GPT-4 rating, 20-year) \label{tab:did_postings_20yr_gpt}") ///
	drop(1.post aiexp_gpt) ///
	coeflabels(1.post#c.aiexp_gpt "Post-2022 x AI Exposure (GPT)") ///
	substitute("\_" "_" {l} {p{0.7\linewidth}} [htbp] [h]) tex ///
	addnote("* p < 0.1; ** p < 0.05; *** p < 0.01. Standard errors in parentheses. Dependent variable is log of monthly job postings by occupation. Occupation and month fixed effects.")

esttab didwage_hum_alpha didwage_hum_beta didwage_hum_gamma ///
	using "${tables}/did_wages_20yr_human.tex", replace ///
	collabels(none) alignment(c) stats(N, fmt(%6.0fc)) ///
	cell(b(fmt(%5.3f) star) se(fmt(%5.3f) par)) label ///
	starlevels(* 0.10 ** 0.05 *** 0.01) nobaselevels ///
	mtitles("$\alpha$" "$\beta$" "$\gamma$") ///
	title("Impact of ChatGPT on wages (Human rating, 20-year) \label{tab:did_wages_20yr_human}") ///
	drop(1.post aiexp_human) ///
	coeflabels(1.post#c.aiexp_human "Post-2022 x AI Exposure (Human)") ///
	substitute("\_" "_" {l} {p{0.7\linewidth}} [htbp] [h]) tex ///
	addnote("* p < 0.1; ** p < 0.05; *** p < 0.01. Standard errors in parentheses. Dependent variable is log of wages by occupation. Occupation and month fixed effects.")

esttab didwage_gpt_alpha didwage_gpt_beta didwage_gpt_gamma ///
	using "${tables}/did_wages_20yr_gpt.tex", replace ///
	collabels(none) alignment(c) stats(N, fmt(%6.0fc)) ///
	cell(b(fmt(%5.3f) star) se(fmt(%5.3f) par)) label ///
	starlevels(* 0.10 ** 0.05 *** 0.01) nobaselevels ///
	mtitles("$\alpha$" "$\beta$" "$\gamma$") ///
	title("Impact of ChatGPT on wages (GPT-4 rating, 20-year) \label{tab:did_wages_20yr_gpt}") ///
	drop(1.post aiexp_gpt) ///
	coeflabels(1.post#c.aiexp_gpt "Post-2022 x AI Exposure (GPT)") ///
	substitute("\_" "_" {l} {p{0.7\linewidth}} [htbp] [h]) tex ///
	addnote("* p < 0.1; ** p < 0.05; *** p < 0.01. Standard errors in parentheses. Dependent variable is log of wages by occupation. Occupation and month fixed effects.")


/*==============================================================================
   SECTION 4: Event Study
   Full pre-period from 2004m1 (month –226 relative to Nov 2022)
   Plots show ±36 months for comparability with ADB event study
 ==============================================================================*/

//Relative month to ChatGPT launch (Nov 2022)
gen relm = month - tm(2022m11)

//Pre-period dummies (omit –1 as baseline)
sum relm
local min_relm = r(min)   // e.g., –226 for 2004m1
local max_relm = r(max)   // e.g., +25 for 2024m12

cap drop relm_*
forval i = `=abs(`min_relm')'(-1)2 {
    gen relm_pre_`i' = (relm == -`i')
}
forval i = 0/`max_relm' {
    gen relm_post_`i' = (relm == `i')
}

//Build variable list for reghdfe (omit relm_pre_1 = month –1 as baseline)
local months_hum
forval m = `=abs(`min_relm')'(-1)2 {
    local months_hum `months_hum' 1.relm_pre_`m'#c.aiexp_human
}
forval m = 0/`max_relm' {
    local months_hum `months_hum' 1.relm_post_`m'#c.aiexp_human
}

local months_gpt
forval m = `=abs(`min_relm')'(-1)2 {
    local months_gpt `months_gpt' 1.relm_pre_`m'#c.aiexp_gpt
}
forval m = 0/`max_relm' {
    local months_gpt `months_gpt' 1.relm_post_`m'#c.aiexp_gpt
}

eststo event_postings_hum: reghdfe log_postings `months_hum' if measure_type == "beta", ///
    absorb(occupation month) level(80)
eststo event_wages_hum:    reghdfe log_wages    `months_hum' if measure_type == "beta", ///
    absorb(occupation month) level(80)
eststo event_postings_gpt: reghdfe log_postings `months_gpt' if measure_type == "beta", ///
    absorb(occupation month) level(80)
eststo event_wages_gpt:    reghdfe log_wages    `months_gpt' if measure_type == "beta", ///
    absorb(occupation month) level(80)


/*--- Event study plots (±36 months window = 73 coefficients) ---*/
//Build plot variable list for the ±36 window
local monthplot_hum
forval m = 36(-1)2 {
    local monthplot_hum `monthplot_hum' 1.relm_pre_`m'#c.aiexp_human
}
forval m = 0/36 {
    local monthplot_hum `monthplot_hum' 1.relm_post_`m'#c.aiexp_human
}

local monthplot_gpt
forval m = 36(-1)2 {
    local monthplot_gpt `monthplot_gpt' 1.relm_pre_`m'#c.aiexp_gpt
}
forval m = 0/36 {
    local monthplot_gpt `monthplot_gpt' 1.relm_post_`m'#c.aiexp_gpt
}

//Build xlabel macro for ±36 window (even months labelled)
local xlabels
local pos = 1
forval m = 36(-1)2 {
    local lbl = -`m'
    if mod(`m', 6) == 0 {
        local xlabels `xlabels' `pos' "`lbl'"
    }
    else {
        local xlabels `xlabels' `pos' " "
    }
    local pos = `pos' + 1
}
forval m = 0/36 {
    if mod(`m', 6) == 0 {
        local xlabels `xlabels' `pos' "`m'"
    }
    else {
        local xlabels `xlabels' `pos' " "
    }
    local pos = `pos' + 1
}
local xline_pos = 36  // position of month 0 (Nov 2022) in the ±36 window

//Plot: Postings (Human rating)
coefplot event_postings_hum, ///
    keep(`monthplot_hum') vertical ///
    yline(0, lcolor(red)) ///
    xlabel(`xlabels', labsize(small)) ///
    xline(`xline_pos', lcolor(red)) ///
    ytitle("Effect on log(Postings)") ///
    note("Month -1 omitted as base; 80% CI shown. Full model covers 2004-2024.") ///
    msymbol(circle) mcolor(blue) ///
    ciopts(recast(rcap) lcolor(blue%30))
graph export "${graphs}/es_postings_20yr_human.png", replace

//Plot: Postings (GPT rating)
coefplot event_postings_gpt, ///
    keep(`monthplot_gpt') vertical ///
    yline(0, lcolor(red)) ///
    xlabel(`xlabels', labsize(small)) ///
    xline(`xline_pos', lcolor(red)) ///
    ytitle("Effect on log(Postings)") ///
    note("Month -1 omitted as base; 80% CI shown. Full model covers 2004-2024.") ///
    msymbol(circle) mcolor(blue) ///
    ciopts(recast(rcap) lcolor(blue%30))
graph export "${graphs}/es_postings_20yr_gpt.png", replace

//Plot: Wages (Human rating)
coefplot event_wages_hum, ///
    keep(`monthplot_hum') vertical ///
    yline(0, lcolor(red)) ///
    xlabel(`xlabels', labsize(small)) ///
    xline(`xline_pos', lcolor(red)) ///
    ytitle("Effect on log(Wages)") ///
    note("Month -1 omitted as base; 80% CI shown. Full model covers 2004-2024.") ///
    msymbol(circle) mcolor(blue) ///
    ciopts(recast(rcap) lcolor(blue%30))
graph export "${graphs}/es_wages_20yr_human.png", replace

//Plot: Wages (GPT rating)
coefplot event_wages_gpt, ///
    keep(`monthplot_gpt') vertical ///
    yline(0, lcolor(red)) ///
    xlabel(`xlabels', labsize(small)) ///
    xline(`xline_pos', lcolor(red)) ///
    ytitle("Effect on log(Wages)") ///
    note("Month -1 omitted as base; 80% CI shown. Full model covers 2004-2024.") ///
    msymbol(circle) mcolor(blue) ///
    ciopts(recast(rcap) lcolor(blue%30))
graph export "${graphs}/es_wages_20yr_gpt.png", replace


di _n "================================================================"
di "  03_analysis_demand_20yr.do complete"
di "================================================================"

log close
