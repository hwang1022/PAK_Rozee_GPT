clear all

**#User Dataset

***************************
**#****Sanity Check****
***************************

**# 1. Is a candidate's reported age or birth year consistent with their declared work experience?

import delimited "$input/Rozee/users_adb.csv", clear varnames(1) bindquote(strict)

gen datestr=substr(last_modified, 1, 10)
gen date_dis=date(datestr, "YMD")
format date_dis %td
gen year_last=year(date_dis)
drop datestr date_dis

gen date_dis=date(dobirth, "YMD")
gen year_birth =year(date_dis)
drop date_dis

gen age=year_last - year_birth

keep if age<100 & age>0

hist age, note("age= date of last modified - date of birth(input by user).")
graph export "$figdesv2\user_check_1_1.png", replace as(png) name("Graph")

drop if experience =="NULL" | experience =="Intern" | experience ==""

replace experience ="1 Year" if experience =="1"
replace experience ="Fresh" if experience =="0"
replace experience ="Less than 1 Year" if experience =="Less than a year"
replace experience = "More than 35 Years" if experience =="36 Years" | experience =="37 Years" |experience =="38 Years" |experience =="39 Years" |experience =="40 Years" |experience =="41 Years" |experience =="42 Years" |experience =="43 Years" |experience =="44 Years" |experience =="45 Years" 


collapse (mean) age (count) num=year_last, by(experience)

drop if num <10

gen order=substr(experience, 1, 2)
replace order="0" if order=="Fr"
replace order="0.5" if order=="Le"
replace order="38" if order=="Mo"
destring order, replace
sort order

drop order
gen order=_n

local labels ""


levelsof order, local(req_nums)
foreach n of local req_nums {

    local experience = experience[`n']

    local labels `"`labels' `n' "`experience'""'
}


label define my_labels `labels'


label values order my_labels


twoway (bar num order, yaxis(2) barwidth(0.5) color(dkgreen) ylabel(0(200000)1000000, axis(2))) ///
       (connected age order, yaxis(1) color(black) ylabel(0(10)60, axis(1)) lw(0.5)),  ///
       xtitle("User's Experience") legend(pos(13) ring(0) col(1) label(1 "Number") label(2 "Age")) ///
       xlabel(1(1)38, valuelabel angle(45) labsize(1.8)) ///
       ytitle("Mean Age", axis(1)) ytitle("Number of Users", axis(2)) note("Keeping sample of 0<age<100")

graph export "$figdesv2\user_check_1_2.png", replace as(png) name("Graph")

**# 2. Are the user's expected salary and current salary generally consistent with their career level?

import delimited "$input/Rozee/users_adb.csv", clear varnames(1) bindquote(strict)

gen careerlevel="Intern/Student" if careerlevel_id=="685"
replace careerlevel="Experienced Professional" if careerlevel_id=="693"
replace careerlevel="Department Head" if careerlevel_id=="698"
replace careerlevel="Entry Level" if careerlevel_id=="868"

drop if careerlevel==""

replace cursal="" if cursal=="NULL"
replace expsal="" if expsal=="NULL"
destring cursal expsal, replace

gen order=1 if careerlevel=="Intern/Student"
replace order=2 if careerlevel=="Entry Level"
replace order=3 if careerlevel=="Experienced Professional"
replace order=4 if careerlevel=="Department Head"
sort order

graph box cursal, over(careerlevel, sort(order)) noout ytitle("Current Salary")  note("Current Salary Input By User") name(p1, replace)

graph export "$figdesv2\user_check_2_1.png", replace as(png) name("p1")

graph box expsal, over(careerlevel, sort(order)) noout ytitle("Expected Salary")  note("Expected Salary Input By User") 
graph export "$figdesv2\user_check_2_2.png", replace as(png) name("Graph")


**# 3. Do users with team management experience earn higher salaries?

import delimited "$input/Rozee/userExperience_adb.csv", clear varnames(1) bindquote(strict)

gen manageteam=1 if manage_team!="no"
replace manageteam=0 if manageteam==.

collapse (sum) manageteam, by(user_id)
gen manageteam_dummy = (manageteam>0)
gen manageteam_str="With Team Management Exp" if manageteam_dummy==1
replace manageteam_str = "Without Team Management Exp" if manageteam_dummy==0

save "$input/Rozee/userExperience_temp.dta", replace


import delimited "$input/Rozee/users_adb.csv", clear varnames(1) bindquote(strict)
merge 1:1 user_id using "$input/Rozee/userExperience_temp.dta"
drop if _merge==2
drop _merge

drop if manageteam_str==""

replace cursal="" if cursal=="NULL"
replace expsal="" if expsal=="NULL"
destring cursal expsal, replace

graph box cursal, over(manageteam_str) noout ytitle("Current Salary")  note("Current Salary Input By User")
graph export "$figdesv2\user_check_3_1.png", replace as(png) name("Graph")
graph box expsal, over(manageteam_str) noout ytitle("Expected Salary")  note("Expected Salary Input By User") 
graph export "$figdesv2\user_check_3_2.png", replace as(png) name("Graph")

gen careerlevel="Intern/Student" if careerlevel_id=="685"
replace careerlevel="Experienced Professional" if careerlevel_id=="693"
replace careerlevel="Department Head" if careerlevel_id=="698"
replace careerlevel="Entry Level" if careerlevel_id=="868"

drop if careerlevel==""

collapse (count) num=cursal, by(manageteam_str careerlevel )

gen order=1 if careerlevel=="Intern/Student"
replace order=2 if careerlevel=="Entry Level"
replace order=3 if careerlevel=="Experienced Professional"
replace order=4 if careerlevel=="Department Head"
sort order

graph pie num, over(careerlevel) by(manageteam_str) sort(order)
graph export "$figdesv2\user_check_3_3.png", replace as(png) name("Graph")


***************************
**#****More Exploratory****
***************************
**# 1. What factors correlate with the difference between a candidate's current salary and their expected salary on their profile?


import delimited "$input/Rozee/users_adb.csv", clear varnames(1) bindquote(strict)

replace cursal="" if cursal=="NULL"
replace expsal="" if expsal=="NULL"
destring cursal expsal, replace

gen gap = expsal-cursal
gen gap_relative = gap/cursal

drop if gap_relative>10 & gap_relative!=.

*gender
preserve
keep if gender_id =="443" | gender_id =="445"

graph box gap_relative, over(gender_id) noout ytitle("Relative Salary Expectation Gap")  note("Not sure which gender id is male or female") 
graph export "$figdesv2\user_explore_1_1.png", replace as(png) name("Graph")


graph box gap, over(gender_id) noout ytitle("Salary Expectation Gap")  note("Not sure which gender id is male or female") 
graph export "$figdesv2\user_explore_1_2.png", replace as(png) name("Graph")

graph box expsal, over(gender_id) noout ytitle("Expected Salary")  note("Not sure which gender id is male or female")
graph export "$figdesv2\user_explore_1_3.png", replace as(png) name("Graph")
restore

*Age/working experience

//age
preserve
gen datestr=substr(last_modified, 1, 10)
gen date_dis=date(datestr, "YMD")
format date_dis %td
gen year_last=year(date_dis)
drop datestr date_dis

gen date_dis=date(dobirth, "YMD")
gen year_birth =year(date_dis)
drop date_dis

gen age=year_last - year_birth



keep if age<100 & age>0

gen age_str = "Younger than 22" if age<23
replace age_str = "23-26" if age>22 & age<27
replace age_str = "26-30" if age>26 & age<31
replace age_str = "30-50" if age>30 & age<51
replace age_str = "Older than 50" if age>50



graph box gap_relative, over(age_str, sort(age)) noout ytitle("Relative Salary Expectation Gap")  note("X axis: age range") 
graph export "$figdesv2\user_explore_1_4.png", replace as(png) name("Graph")


graph box gap, over(age_str, sort(age)) noout ytitle("Salary Expectation Gap")  note("X axis: age range") 
graph export "$figdesv2\user_explore_1_5.png", replace as(png) name("Graph")

graph box expsal, over(age_str, sort(age)) noout ytitle("Expected Salary")  note("X axis: age range")
graph export "$figdesv2\user_explore_1_6.png", replace as(png) name("Graph")

restore

//working experience
preserve

drop if experience =="NULL" | experience =="Intern" | experience ==""

replace experience ="1 Year" if experience =="1"
replace experience ="Fresh" if experience =="0"
replace experience ="Less than 1 Year" if experience =="Less than a year"
replace experience = "More than 35 Years" if experience =="36 Years" | experience =="37 Years" |experience =="38 Years" |experience =="39 Years" |experience =="40 Years" |experience =="41 Years" |experience =="42 Years" |experience =="43 Years" |experience =="44 Years" |experience =="45 Years" 

collapse (mean) cursal expsal gap gap_relative (count) num=gap, by(experience)

drop if num <20

gen order=substr(experience, 1, 2)
replace order="0" if order=="Fr"
replace order="0.5" if order=="Le"
replace order="38" if order=="Mo"
destring order, replace
sort order

gen exp = "Less than 1 Year" if order <2
replace exp = "2-10 Years" if order>1 & order<11
replace exp = "11-20 Years" if order>10 & order<21
replace exp = "21-30 Years" if order>20 & order<31
replace exp = "More than 30 Years" if order >30


drop order
gen order=_n

local labels ""


levelsof order, local(req_nums)
foreach n of local req_nums {

    local experience = experience[`n']

    local labels `"`labels' `n' "`experience'""'
}


label define my_labels `labels'


label values order my_labels

twoway (bar expsal order, barwidth(0.5) color(dkgreen)) , xtitle("User's Experience") xtitle("User's Experience") ytitle("Expected Salary") xlabel(1(1)38, valuelabel angle(45) labsize(1.8))  note("")



graph export "$figdesv2\user_explore_1_7.png", replace as(png) name("Graph")


twoway (bar gap_relative order, barwidth(0.5) color(dkgreen)) , xtitle("User's Experience") ytitle("Relative Salary Expectation Gap") xlabel(1(1)38, valuelabel angle(45) labsize(1.8))  note("")

graph export "$figdesv2\user_explore_1_8.png", replace as(png) name("Graph")
restore

*Profile attractiveness:skill/duration
preserve
import delimited "$input/Rozee/users_skills_adb.csv", clear varnames(1) bindquote(strict)

gen skill3=1 if level=="3"
gen skill2=1 if level=="2"
gen skill1=1 if level=="1"
gen skillnull=1 if level=="NULL"

collapse (count) skill_num=skill_id (sum) skill3 skill2 skill1 skillnull, by(user_id)

save "$input/Rozee/users_skills_temp.dta", replace
restore

preserve
merge 1:1 user_id using "$input/Rozee/users_skills_temp.dta"
drop _merge

gen ifnoskill=(skill_num==.)


graph box gap_relative, over(ifnoskill) noout ytitle("Relative Salary Expectation Gap") note("X axis: 1= No skill input")

graph export "$figdesv2\user_explore_1_9.png", replace as(png) name("Graph")

drop if skill_num>20
binscatterhist gap_relative skill_num, hist(skill_num)  line(qfit) xtitle("Skill Number") ytitle("Relative Salary Expectation Gap")

graph export "$figdesv2\user_explore_1_10.png", replace as(png) name("Graph")

gen skilllow=skill2+skill1

binscatterhist gap_relative skilllow, coefficient(0.001) p xtitle("Num of non proficient Skills" ) ytitle("Relative Salary Expectation Gap")

graph export "$figdesv2\user_explore_1_11.png", replace as(png) name("Graph")

binscatterhist gap_relative skill3, coefficient(0.001) p xtitle("Num of proficient Skills" ) ytitle("Relative Salary Expectation Gap")

graph export "$figdesv2\user_explore_1_12.png", replace as(png) name("Graph")
restore

preserve
import delimited "$input/Rozee/userExperience_adb.csv", clear varnames(1) bindquote(strict)

gen start=substr(jobstart, 1, 4)
replace start="" if start=="NULL"
destring start, replace force
replace start=. if start<1980 | start>2025

drop if jobend=="Present"
drop if jobend=="present"
drop if start==.

drop start

gen start=substr(jobstart, 1, 7)
gen end=substr(jobend, 1, 7)

gen start_month=monthly(start, "YM")
gen end_month=monthly(end, "YM")

drop if start_month>end_month

gen duration=end_month-start_month
replace duration=. if duration>1200

collapse (mean) duration, by(user_id)

save "$input/Rozee/userExperience_temp.dta", replace
restore

preserve
merge 1:1 user_id using "$input/Rozee/userExperience_temp.dta"
drop if _merge==2

gen ifnoexp=(_merge==1)


graph box gap_relative, over(ifnoexp) noout ytitle("Relative Salary Expectation Gap") note("X axis: 1= No Experience input")

graph export "$figdesv2\user_explore_1_13.png", replace as(png) name("Graph")

binscatterhist gap_relative duration, hist(duration) line(connect) xtitle("Mean Num of Months of Past Experience" ) ytitle("Relative Salary Expectation Gap")

graph export "$figdesv2\user_explore_1_14.png", replace as(png) name("Graph")
restore

**Macro: cohort/region
preserve

gen datestr=substr(last_modified, 1, 10)
gen date_dis=date(datestr, "YMD")
format date_dis %td
gen year_last=year(date_dis)
drop datestr date_dis

keep if year_last>2015

graph box gap_relative, over(year_last) noout ytitle("Relative Salary Expectation Gap")  note("X axis: Year of Last Modified") 
graph export "$figdesv2\user_explore_1_18.png", replace as(png) name("Graph")

keep if gender_id =="443" | gender_id =="445"
graph box gap_relative, over(gender_id) over(year_last) noout ytitle("Relative Salary Expectation Gap")  note("X axis: Year of Last Modified") 
graph export "$figdesv2\user_explore_1_15.png", replace as(png) name("Graph")
restore

preserve
keep if country_id=="79"
destring city_id, force replace

merge m:1 city_id using "$input/Rozee/meta_data/cities.dta"
drop if _merge==2
drop _merge

collapse (count) usernum = city_id (mean) gap_relative, by(cityy_name)
rename cityy_name ADM2_EN

drop if ADM2_EN==""

merge 1:1 ADM2_EN using "$input/shapefile_pk/pak_admbnda_adm2_wfp_20220909.dta"

drop if _merge==1

spmap usernum using "$input/shapefile_pk/pak_admbnda_adm2_wfp_20220909_shp.dta" , id(_ID)  clnumber(8) fcolor(Reds2)   legstyle(1) legend(position(5) size(*1.2)) title("Space Distribution of User Number") 

graph export "$figdesv2\user_explore_1_16.png", replace as(png) name("Graph")

spmap gap_relative using "$input/shapefile_pk/pak_admbnda_adm2_wfp_20220909_shp.dta" , id(_ID)  clnumber(8) fcolor(Greens2)   legstyle(1) legend(position(5) size(*1.2)) title("Space Distribution of Relative Salary Expectation Gap ") 

graph export "$figdesv2\user_explore_1_17.png", replace as(png) name("Graph")
restore

**# 2. Provide a basic description of the user's job-seeking process.

*number of application
import delimited "$input/Rozee/application_adb.csv", clear bindquote(strict)

gen datestr=substr(apply_date, 1, 10)
gen date_apply=date(datestr, "YMD")
gen year_apply=year(date_apply)
drop datestr

**add***

merge m:1 user_id using "$input/Rozee/users_temp.dta"
drop if _merge==2
drop _merge

*************

collapse (count) num_application=cv_log_id, by(user_id gender_id year_apply)
graph box num_application, over(year_apply) noout ytitle("Mean Number of Application per User")  note("") 

graph export "$figdesv2\user_explore_2_1.png", replace as(png) name("Graph")

keep if gender_id=="443" | gender_id=="445"
graph box num_application, over(gender_id)  over(year_apply) noout ytitle("Mean Number of Application per User")  note("") 

graph export "$figdesv2\user_explore_2_7.png", replace as(png) name("Graph")
*broad & narrow
import delimited "$input/Rozee/jobs_adb.csv", clear bindquote(strict) maxquotedrows(1000)

replace salary_range_from= salary_range_from_hide if salary_range_from=="NULL"
replace salary_range_to= salary_range_to_hide if salary_range_to=="NULL"
drop salary_range_from_hide salary_range_to_hide
tab currency_unit
replace currency_unit ="PKR" if currency_unit=="Pakistani Rupee"
replace salary_range_from="" if salary_range_from=="NULL"| currency_unit!="PKR"
replace salary_range_to="" if salary_range_to=="NULL"| currency_unit!="PKR"
destring salary_range_from salary_range_to, replace
replace salary_range_to=salary_range_to*0.0035
replace salary_range_from=salary_range_from*0.0035
egen salary_median = rowmean(salary_range_to salary_range_from)
drop if salary_range_to< salary_range_from & salary_range_from!=.

keep jid industry_id totalpositions careerlevel min_age max_age salary_median city_id country_id

rename industry_id industry_id_job
rename city_id city_id_job
rename country_id country_id_job

save "$input/Rozee/jobs_temp.dta", replace


import delimited "$input/Rozee/users_adb.csv", clear varnames(1) bindquote(strict)
keep user_id gender_id dobirth last_modified industry_id city_id country_id
save "$input/Rozee/users_temp.dta", replace

import delimited "$input/Rozee/application_adb.csv", clear bindquote(strict)

keep cv_log_id user_id jid company_id apply_date currentsalary expectedsalary

merge m:1 user_id using "$input/Rozee/users_temp.dta"
drop if _merge==2
drop _merge

merge m:1 jid using "$input/Rozee/jobs_temp.dta"
drop if _merge==2
drop _merge

sort user_id industry_id_job
egen tag= tag(user_id industry_id_job)

collapse (sum) num_industry=tag, by(user_id gender_id dobirth)


hist num_industry, xtitle("Number of Industries across User's all Applications")
graph export "$figdesv2\user_explore_2_2.png", replace as(png) name("Graph")

keep if gender_id=="443" | gender_id =="445"
graph bar (mean) num_industry (median) num_industry, over(gender_id)  ytitle("Number of Industries across User's all Applications")  note("") 

graph export "$figdesv2\user_explore_2_3.png", replace as(png) name("Graph")

gen date_dis=date(dobirth, "YMD")
gen year_birth =year(date_dis)
drop date_dis

drop if year_birth<1960 | year_birth>2006

graph bar num_industry, over(year_birth, label(angle(45) labsize(1.8))) ytitle("Number of Industries across User's all Applications") note("Xaxis: Year of Birth")

graph export "$figdesv2\user_explore_2_4.png", replace as(png) name("Graph")

*expected gap
import delimited "$input/Rozee/application_adb.csv", clear bindquote(strict)

keep cv_log_id user_id jid company_id apply_date currentsalary expectedsalary

merge m:1 user_id using "$input/Rozee/users_temp.dta"
drop if _merge==2
drop _merge

merge m:1 jid using "$input/Rozee/jobs_temp.dta"
drop if _merge==2
drop _merge


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
bys user_id date_apply: gen rank_application=_n

preserve
collapse (count) num=cv_log_id (mean) gap gap_relative, by(rank_application)
drop if rank_application>40

twoway (bar num rank_application, yaxis(2) barwidth(0.5) color(dkgreen) ylabel(0(3000000)15000000, axis(2))) ///
       (connected gap rank_application, yaxis(1) color(black) ylabel(7500(500)10000,axis(1)) lw(0.5)),  ///
       xtitle("Order of Application") legend(pos(12) ring(0) col(1) label(1 "Number") label(2 "Gap")) ///
       xlabel(1(1)40, valuelabel angle(45) labsize(1.8)) ///
       ytitle("Salary Expectation Gap", axis(1)) ytitle("Number of Applications", axis(2))

graph export "$figdesv2\user_explore_2_5.png", replace as(png) name("Graph")


twoway (bar num rank_application, yaxis(2) barwidth(0.5) color(dkgreen) ylabel(0(3000000)15000000, axis(2))) ///
       (connected gap_relative rank_application, yaxis(1) color(black) ylabel(,axis(1)) lw(0.5)),  ///
       xtitle("Order of Application") legend(pos(12) ring(0) col(1) label(1 "Number") label(2 "Gap")) ///
       xlabel(1(1)40, valuelabel angle(45) labsize(1.8)) ///
       ytitle("Relative Salary Expectation Gap", axis(1)) ytitle("Number of Applications", axis(2))
	   
graph export "$figdesv2\user_explore_2_6.png", replace as(png) name("Graph")
