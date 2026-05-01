clear all
clear matrix 
clear mata 
set more off

***************************
**#****Quality Check****
***************************

**# 1. What is the variation in expected salary reported by a single user across job applications?

import delimited "$input/Rozee/application_adb.csv", clear bindquote(strict)

set scheme plotplainblind

replace currentsalary="" if currentsalary=="NULL"
replace expectedsalary="" if expectedsalary=="NULL"
destring currentsalary expectedsalary, replace

gen datestr=substr(apply_date, 1, 10)
gen date=date(datestr, "YMD")
format date %td
sort date

gen year=year(date)
gen month=mofd(date)
gen quarter = qofd(date)
format month %tm
format quarter %tq
drop datestr

drop test_code test_status



*drop user with less than 10 application
bys user_id: egen sum= count(cv_log_id)
drop if sum<11


**4.5 Years
preserve
bysort user_id: egen sd_by_user = sd(expectedsalary)
egen tag_user = tag(user_id)
count if tag_user==1
count if tag_user==1 & sd_by_user>0 & sd_by_user!=.
count if tag_user==1 & sd_by_user==0
count if tag_user==1 & sd_by_user==.

keep if sd_by_user>0 & sd_by_user!=.
restore

**1year
preserve
bysort user_id year: egen sd_by_useryear = sd(expectedsalary)
egen tag_year = tag(user_id year)
count if tag_year==1
count if tag_year==1 & sd_by_useryear>0 & sd_by_useryear!=.
count if tag_year==1 & sd_by_useryear==0
count if tag_year==1 & sd_by_useryear==.

keep if sd_by_useryear>0 & sd_by_useryear!=.
distinct user_id
restore


**1quarter
preserve
bysort user_id quarter: egen sd_by_userquarter = sd(expectedsalary)
egen tag_quarter = tag(user_id quarter)
count if tag_quarter==1
count if tag_quarter==1 & sd_by_userquarter>0 & sd_by_userquarter!=.
count if tag_quarter==1 & sd_by_userquarter==0
count if tag_quarter==1 & sd_by_userquarter==.

keep if sd_by_userquarter>0 & sd_by_userquarter!=.
distinct user_id
restore


**1month
preserve
bysort user_id month: egen sd_by_usermonth = sd(expectedsalary)
egen tag_month = tag(user_id month)
count if tag_month==1
count if tag_month==1 & sd_by_usermonth>0 & sd_by_usermonth!=.
count if tag_month==1 & sd_by_usermonth==0
count if tag_month==1 & sd_by_usermonth==.

keep if  sd_by_usermonth>0 & sd_by_usermonth!=.
distinct user_id
restore


*Distribution of Expected salary

preserve

bysort user_id: egen sd_by_user = sd(expectedsalary)

keep if sd_by_user>0 & sd_by_user!=.

bys user_id: egen max_exp= max(expectedsalary)
bys user_id: egen min_exp= min(expectedsalary)



gen distribution = (expectedsalary-min_exp)/(max_exp-min_exp)

hist distribution, xtitle("Relative Position of Expected Salary within Individual's Range") name(g1, replace)


gen dis = "Between" if distribution<1 & distribution>0
replace dis= "Max or Min" if distribution ==1 | distribution ==0

gen tag=1

graph pie tag, over(dis) title("Relative Position of Expected Salary within Individual's Range") name(g2, replace)

graph combine g1 g2

graph export "$figexp\quality_1_2.png", replace as(png) name("Graph")

restore


***************************
**#****Further Analysis****
***************************

**# 1. In each application, what is the relationship between the self-reported expected salary and the probability of being shortlisted?

import delimited "$input/Rozee/application_adb.csv", clear bindquote(strict)

gen interview=( emp_status=="shortlisted" | emp_status=="interviewed")

bys jid: egen sum_int=sum(interview)
replace interview=. if sum_int==0
drop sum_int

replace currentsalary="" if currentsalary=="NULL"
replace expectedsalary="" if expectedsalary=="NULL"
destring currentsalary expectedsalary, replace
drop test_code test_status apply_date

rename interview shortlisted
tabout shortlisted using "$tabexp\ana_1_1.tex", replace style(tex) oneway c(col cum) f(2 2 2) clab(Percent_% Cum._%) npos(col) nlab(Freq.)



winsor2 expectedsalary, replace cuts(0.5 99.5) trim

gen lnexpsal = log(expectedsalary)

reghdfe shortlisted lnexpsal, noabsorb
est store model1
outreg2 model1 using "$tabexp\ana_1_2.tex", replace addtext(User FE, No, Job FE, No) nocons

reghdfe shortlisted lnexpsal, absorb(user_id)
est store model2
outreg2 model2 using "$tabexp\ana_1_2.tex", append addtext(User FE, Yes, Job FE, No) nocons

reghdfe shortlisted lnexpsal, absorb(jid)
est store model3
outreg2 model3 using "$tabexp\ana_1_2.tex", append addtext(User FE, No, Job FE, Yes) nocons

reghdfe shortlisted lnexpsal, absorb(user_id jid)
est store model4
outreg2 model4 using "$tabexp\ana_1_2.tex", append addtext(User FE, Yes, Job FE, Yes) nocons





**# 2. Does the self-reported expected salary align with the salary range listed in the job posting? What is the distribution?



import delimited "$input/Rozee/jobs_adb.csv", clear bindquote(strict) maxquotedrows(1000)
keep jid salary_range_from salary_range_to salary_range_from_hide salary_range_to_hide
destring salary_range_from salary_range_to salary_range_from_hide salary_range_to_hide, replace force

gen hide=(salary_range_from_hide!=.| salary_range_to_hide!=.)
replace hide=. if salary_range_from==. & salary_range_to==. & salary_range_from_hide==. &  salary_range_to_hide==.
replace hide =0 if hide==1 & (salary_range_from!=.|salary_range_to!=.)

save "$input/Rozee/jobs_temp.dta", replace


import delimited "$input/Rozee/application_adb.csv", clear bindquote(strict)
merge m:1 jid using "$input/Rozee/jobs_temp.dta"
drop if _merge==2
drop _merge

destring currentsalary expectedsalary, replace force


winsor2 expectedsalary, replace cuts(0.5 99.5) trim
drop if salary_range_from> salary_range_to & salary_range_from!=.
drop if salary_range_from_hide>salary_range_to_hide & salary_range_from_hide!=.
gen expquatile = (expectedsalary-salary_range_from)/(salary_range_to-salary_range_from) if hide==0
replace expquatile = (expectedsalary-salary_range_from_hide)/(salary_range_to_hide-salary_range_from_hide) if hide==1

keep if expquatile>-5 & expquatile<5


hist expquatile if hide==0, xtitle("Relative Position of Expected Salary within Job's Salary Range (Visible)")
graph export "$figexp\ana_2_3.png", replace as(png) name("Graph")

hist expquatile if hide==1, xtitle("Relative Position of Expected Salary within Job's Salary Range (Hidden)")
graph export "$figexp\ana_2_4.png", replace as(png) name("Graph")



**# 3. As a person's number of applications increase, how do their expected salary and salary expectation gap (gap between current and expected salary) change?

import delimited "$input/Rozee/application_adb.csv", clear bindquote(strict)

keep cv_log_id user_id jid company_id apply_date currentsalary expectedsalary

gen datestr=substr(apply_date, 1, 10)
gen date_apply=date(datestr, "YMD")
gen year_apply=year(date_apply)
drop datestr

destring currentsalary expectedsalary, force replace
gen gap = expectedsalary - currentsalary
gen gap_relative = gap/currentsalary

drop if gap_relative>5 & gap_relative!=.
drop if currentsalary > 1000000 & currentsalary !=.

sort user_id date_apply
bys user_id: egen sum= count(cv_log_id)
drop if sum<11

bys user_id: gen rank_application=_n

collapse (count) num=cv_log_id (mean) expectedsalary gap gap_relative, by(rank_application)


drop if rank_application>40

twoway (bar num rank_application, yaxis(2) barwidth(0.5) color(dkgreen) ylabel(0(300000)1500000, axis(2))) ///
       (connected expectedsalary rank_application, yaxis(1) color(black) ),  ///
       xtitle("Order of Application") legend(pos(12) ring(0) col(1) label(1 "Number") label(2 "Expected Salary")) ///
       xlabel(1(1)40, valuelabel angle(45) labsize(1.8)) ///
       ytitle("Expected Salary", axis(1)) ytitle("Number of Applications", axis(2))

graph export "$figexp\ana_3_1.png", replace as(png) name("Graph")

twoway (bar num rank_application, yaxis(2) barwidth(0.5) color(dkgreen) ylabel(0(300000)1500000, axis(2))) ///
       (connected gap_relative rank_application, yaxis(1) color(black) ),  ///
       xtitle("Order of Application") legend(pos(12) ring(0) col(1) label(1 "Number") label(2 "Gap")) ///
       xlabel(1(1)40, valuelabel angle(45) labsize(1.8)) ///
       ytitle("Relative Salary Expectation Gap", axis(1)) ytitle("Number of Applications", axis(2))

graph export "$figexp\ana_3_2.png", replace as(png) name("Graph")

**# 4. How many job-seeking cycles does a person typically have between 2020 and 2025? What changes occur to the expected salary both between and within these different cycles?


import delimited "$input/Rozee/application_adb.csv", clear bindquote(strict)

keep cv_log_id user_id jid company_id apply_date currentsalary expectedsalary

gen datestr=substr(apply_date, 1, 10)
gen date_apply=date(datestr, "YMD")
gen year_apply=year(date_apply)
drop datestr

destring currentsalary expectedsalary, force replace


sort user_id date_apply

by user_id: egen sum= count(cv_log_id)
drop if sum<11

by user_id: gen gap = date_apply - date_apply[_n-1]


by user_id: gen cycle_id = 1
by user_id: replace cycle_id = cycle_id[_n-1] + (gap > 35) if _n > 1

preserve
bys user_id: egen num_cycle=max(cycle_id)
duplicates drop user_id, force

hist num_cycle, xtitle("Number of Job Search Cycles")
graph export "$figexp\ana_4_1.png", replace as(png) name("Graph")
restore

preserve
bys user_id cycle_id: egen mean_expected =  mean(expectedsalary)
collapse (mean) mean_expected, by(cycle_id)
drop if cycle_id>20
twoway connected mean_expected cycle_id, xtitle("Order of Job Search Cycle") ytitle("Mean Expected Salary")
graph export "$figexp\ana_4_2.png", replace as(png) name("Graph")
restore


preserve
bys user_id cycle_id: gen rank_application=_n
collapse (mean) expectedsalary, by(user_id rank_application)
collapse (mean) expectedsalary, by(rank_application)

drop if rank_application>10

twoway connected expectedsalary rank_application, xtitle("Order of Application within Single Job Search Cycle") ytitle("Mean Expected Salary")

graph export "$figexp\ana_4_3.png", replace as(png) name("Graph")
restore