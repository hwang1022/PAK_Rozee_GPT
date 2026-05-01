clear all

cap log close 
set more off 

global path "D:\Dropbox\Rozee AI Project"
global data "${path}/Code and Data/Analysis Data"

global tables "${path}/Drafts/v1/Tables"
global graphs "${path}/Drafts/v1/Figures"


/*==============================================================================
	Job Counts and Wages
 ==============================================================================*/


/*==============================================================================
	Prepare data
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

//Define wages 
gen salary_mid = .
replace salary_mid = (salary_from_clean + salary_to_clean)/2 if !missing(salary_from_clean, salary_to_clean)
replace salary_mid = salary_from_clean if missing(salary_to_clean) & !missing(salary_from_clean)
replace salary_mid = salary_to_clean if missing(salary_from_clean) & !missing(salary_to_clean)

sum salary_mid, detail
replace salary_mid = . if salary_mid > `r(p99)'

//AI Exposure variable
cap drop ai_*

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

//Checks 
cap drop check_*
gen check_ai = beta == aiexp_gpt_beta
tab check_ai
drop check_ai 


//Get job level data 
collapse (mean) aiexp_human_alpha aiexp_human_beta aiexp_human_gamma ///
		aiexp_gpt_alpha aiexp_gpt_beta aiexp_gpt_gamma, ///
		by(jid job_created_date max_broad_occupation salary_mid)

encode max_broad_occupation, gen(occupation)
drop if missing(occupation)

gen month = mofd(job_created_date)
format month %tm

gen post = (month >= tm(2022m11))

//Get AI exposure at occupation level (before ChatGPT launch)
preserve 	
keep if post == 0 
collapse (mean) aiexp_human_alpha aiexp_human_beta aiexp_human_gamma ///
		aiexp_gpt_alpha aiexp_gpt_beta aiexp_gpt_gamma, by(occupation)

tempfile ai_exposure 
save `ai_exposure', replace
restore 

//Get posting per month per occupation 
collapse (count) postings = jid (mean) salary_mid, by(occupation month)

merge m:1 occupation using `ai_exposure', nogen keep(match master)

gen log_postings = log(postings)
gen log_wages = log(salary_mid)
gen post = (month >= tm(2022m11))

reshape long aiexp_human_ aiexp_gpt_, i(occupation month) j(measure_type) string
rename aiexp_human_ aiexp_human 
rename aiexp_gpt_ aiexp_gpt

/*==============================================================================
	DiD 
 ==============================================================================*/

* Postings
eststo didpostings_hum_alpha: reghdfe log_postings c.aiexp_human##i.post if measure_type == "alpha", absorb(occupation month)
eststo didpostings_hum_beta: reghdfe log_postings c.aiexp_human##i.post if measure_type == "beta", absorb(occupation month)
eststo didpostings_hum_gamma: reghdfe log_postings c.aiexp_human##i.post if measure_type == "gamma", absorb(occupation month)

eststo didpostings_gpt_alpha: reghdfe log_postings c.aiexp_gpt##i.post if measure_type == "alpha", absorb(occupation month)
eststo didpostings_gpt_beta: reghdfe log_postings c.aiexp_gpt##i.post if measure_type == "beta", absorb(occupation month)
eststo didpostings_gpt_gamma: reghdfe log_postings c.aiexp_gpt##i.post if measure_type == "gamma", absorb(occupation month)	

esttab didpostings_hum_alpha didpostings_hum_beta didpostings_hum_gamma ///
	using "${tables}/did_postings_human.tex", replace ///
	collabels(none) alignment(c) stats(N, fmt(%6.0fc)) ///
	cell(b(fmt(%5.3f) star) se(fmt(%5.3f) par)) label ///
	starlevels(* 0.10 ** 0.05 *** 0.01) nobaselevels ///
	mtitles("$\alpha$" "$\beta$" "$\gamma$") ///
	title("Impact of public-use ChatGPT on job counts (Human rating) \label{tab:did_postings_human}")  drop(1.post aiexp_human) ///
	coeflabels(1.post#c.aiexp_human "Post-2022 x AI Exposure (Human)") ///
	substitute("\_" "_" {l} {p{0.7\linewidth}} [htbp] [h]) tex ///
	addnote(* p $<$ 0.1; ** p $<$ 0.05; *** p $<$ 0.01. Standard errors in parenthesis. ///
	 Dependent variable is Log of monthly job postings by occupation. Includes occupation and month fixed effects.)

esttab didpostings_gpt_alpha didpostings_gpt_beta didpostings_gpt_gamma ///
	using "${tables}/did_postings_gpt.tex", replace ///
	collabels(none) alignment(c) stats(N, fmt(%6.0fc)) ///
	cell(b(fmt(%5.3f) star) se(fmt(%5.3f) par)) label ///
	starlevels(* 0.10 ** 0.05 *** 0.01) nobaselevels ///
 mtitles("$\alpha$" "$\beta$" "$\gamma$") ///
	title("Impact of public-use ChatGPT on job counts (GPT rating) \label{tab:did_postings_gpt}") drop(1.post aiexp_gpt) ///
	coeflabels(1.post#c.aiexp_gpt "Post-2022 x AI Exposure (GPT)") ///
	substitute("\_" "_" {l} {p{0.7\linewidth}} [htbp] [h]) tex ///
	addnote(* p $<$ 0.1; ** p $<$ 0.05; *** p $<$ 0.01. Standard errors in parenthesis. ///
	 Dependent variable is Log of monthly job postings by occupation. Includes occupation and month fixed effects.)


* Wages
eststo didwage_hum_alpha: reghdfe log_wages c.aiexp_human##i.post if measure_type == "alpha", absorb(occupation month)
eststo didwage_hum_beta: reghdfe log_wages c.aiexp_human##i.post if measure_type == "beta", absorb(occupation month)
eststo didwage_hum_gamma: reghdfe log_wages c.aiexp_human##i.post if measure_type == "gamma", absorb(occupation month)

eststo didwage_gpt_alpha: reghdfe log_wages c.aiexp_gpt##i.post if measure_type == "alpha", absorb(occupation month)
eststo didwage_gpt_beta: reghdfe log_wages c.aiexp_gpt##i.post if measure_type == "beta", absorb(occupation month)
eststo didwage_gpt_gamma: reghdfe log_wages c.aiexp_gpt##i.post if measure_type == "gamma", absorb(occupation month)

esttab didwage_hum_alpha didwage_hum_beta didwage_hum_gamma ///
	using "${tables}/did_wages_human.tex", replace ///
	collabels(none) alignment(c) stats(N, fmt(%6.0fc)) ///
	cell(b(fmt(%5.3f) star) se(fmt(%5.3f) par)) label ///
	starlevels(* 0.10 ** 0.05 *** 0.01) nobaselevels ///
 mtitles("$\alpha$" "$\beta$" "$\gamma$") ///
	title("Impact of public-use ChatGPT on wages (Human rating) \label{tab:did_wages_human}")  drop(1.post aiexp_human) ///
	coeflabels(1.post#c.aiexp_human "Post-2022 x AI Exposure (Human)") ///
	substitute("\_" "_" {l} {p{0.7\linewidth}} [htbp] [h]) tex ///
	addnote(* p $<$ 0.1; ** p $<$ 0.05; *** p $<$ 0.01. Standard errors in parenthesis. ///
	 Dependent variable is Log of wages by occupation. Includes occupation and month fixed effects.)

esttab didwage_gpt_alpha didwage_gpt_beta didwage_gpt_gamma ///
	using "${tables}/did_wages_gpt.tex", replace ///
	collabels(none) alignment(c) stats(N, fmt(%6.0fc)) ///
	cell(b(fmt(%5.3f) star) se(fmt(%5.3f) par)) label ///
	starlevels(* 0.10 ** 0.05 *** 0.01) nobaselevels ///
 mtitles("$\alpha$" "$\beta$" "$\gamma$") ///
	title("Impact of public-use ChatGPT on wages (GPT rating) \label{tab:did_wages_gpt}") drop(1.post aiexp_gpt) ///
	coeflabels(1.post#c.aiexp_gpt "Post-2022 x AI Exposure (GPT)") ///
	substitute("\_" "_" {l} {p{0.7\linewidth}} [htbp] [h]) tex ///
	addnote(* p $<$ 0.1; ** p $<$ 0.05; *** p $<$ 0.01. Standard errors in parenthesis. ///
	 Dependent variable is Log of wages by occupation. Includes occupation and month fixed effects.)


/*==============================================================================
	Event Study 
 ==============================================================================*/

* Relative month to ChatGPT launch (Nov 2022)
gen relm = month - tm(2022m11)

* Create dummy for each relative month (omit –1 as baseline)
cap drop relm_*
forval i = -34/-1 {
	local j = `i' * -1
	gen relm_pre_`j' = relm == `i'
}

forval i = 0/29 {
	gen relm_post_`i' = relm == `i'
}

//Create variable names
local months
forval m = 34(-1)2 {
    local months `months' 1.relm_pre_`m'#c.aiexp_human
}

forval m = 0/29 {
	local months `months' 1.relm_post_`m'#c.aiexp_human
}

disp "`months'"

eststo event_postings: reghdfe log_postings `months' if measure_type == "beta", ///
	absorb(occupation month) level(80)

eststo event_wages: reghdfe log_wages `months' if measure_type == "beta", ///
	absorb(occupation month) level(80)


//Plot Event Study for Postings
local monthplot
forval m = 24(-1)2 {
    local monthplot `monthplot' 1.relm_pre_`m'#c.aiexp_human 
}

forval m = 0/24 {
	local monthplot `monthplot' 1.relm_post_`m'#c.aiexp_human
}

disp "`monthplot'"

coefplot event_postings, ///
    keep(`monthplot') vertical ///
    yline(0, lcolor(red)) ///
	xlabel(1 "-24" 2 " " 3 "-22" 4 " " 5 "-20" 6 " " 7 "-18" 8 " " ///
	9 "-16" 10 " " 11 "-14" 12 " " 13 "-12" 14 " " 15 "-10" 16 " " ///
	17 "-8" 18 " " 19 "-6" 20 " " 21 "-4" 22 " " 23 "-2" 24 "0" ///
	25 " " 26 "2" 27 " " 28 "4" 29 " " 30 "6" 31 " " 32 "8" 33 " " ///
	34 "10" 35 " " 36 "12" 37 " " 38 "14" 39 " " 40 "16" 41 " " ///
	42 "18" 43 " " 44 "20" 45 " " 46 "22" 47 " " 48 "24", labsize(small)) ///
    xline(24, lcolor(red)) ///
    ytitle("Effect on log(Postings)") ///
    note("Month –1 omitted as base; 95% CI") ///
    msymbol(circle) mcolor(blue) ///
    ciopts(recast(rcap) lcolor(blue%30))
*graph export "${graphs}/es_postings.png", replace

//Plot Event Study for Wages
coefplot event_wages, ///
    keep(`monthplot') vertical ///
    yline(0, lcolor(red)) ///
	xlabel(1 "-24" 2 " " 3 "-22" 4 " " 5 "-20" 6 " " 7 "-18" 8 " " ///
	9 "-16" 10 " " 11 "-14" 12 " " 13 "-12" 14 " " 15 "-10" 16 " " ///
	17 "-8" 18 " " 19 "-6" 20 " " 21 "-4" 22 " " 23 "-2" 24 "0" ///
	25 " " 26 "2" 27 " " 28 "4" 29 " " 30 "6" 31 " " 32 "8" 33 " " ///
	34 "10" 35 " " 36 "12" 37 " " 38 "14" 39 " " 40 "16" 41 " " ///
	42 "18" 43 " " 44 "20" 45 " " 46 "22" 47 " " 48 "24", labsize(small)) ///
    xline(24, lcolor(red)) ///
    ytitle("Effect on log(Wages)") ///
    note("Month –1 omitted as base; 95% CI") ///
    msymbol(circle) mcolor(blue) ///
    ciopts(recast(rcap) lcolor(blue%30))
graph export "${graphs}/es_wages.png", replace