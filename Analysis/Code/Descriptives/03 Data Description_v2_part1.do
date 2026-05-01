clear all

**#Job Dataset

***************************
**#****Sanity Check****
***************************

**# 1. Are low-experience jobs consistently paid less?

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
drop if salary_range_to< salary_range_from

collapse (mean) salary=salary_median (count) num=jid, by(req_experience)
drop if num<100

*sort
gen order=substr(req_experience, 1, 2)
replace order="0" if order=="Fr"
replace order="0.5" if order=="Le"
replace order="" if order=="NU"
destring order, replace
sort order
drop order
gen order=_n


local labels ""


levelsof order, local(req_nums)
foreach n of local req_nums {

    local experience = req_experience[`n']

    local labels `"`labels' `n' "`experience'""'
}


label define my_labels `labels'


label values order my_labels
	   
	   
twoway (bar num order, yaxis(2) barwidth(0.5) color(dkgreen) ylabel(0(20000)100000, axis(2))) ///
       (connected salary order, yaxis(1) color(black) ylabel(0(100)1200, axis(1)) lw(0.5)),  ///
       xtitle("Required Experience") legend(pos(11) ring(0) col(1) label(1 "Number") label(2 "Salary(Dollar)")) ///
       xlabel(1(1)16, valuelabel angle(90) labsize(1.8)) ///
       ytitle("Mean Salary(Dollar)", axis(1)) ytitle("Number of Jobs", axis(2))
	
graph export "$figdesv2\job_check_1_1.png", replace as(png) name("Graph")



**# 2. Does the "careerlevel" label align with the actual required experience field?

import delimited "$input/Rozee/jobs_adb.csv", clear bindquote(strict) maxquotedrows(1000)

preserve
keep if careerlevel=="Entry Level"
collapse (count) num=jid, by(req_experience)
drop if num<5
gen order=substr(req_experience, 1, 2)
replace order="0" if order=="Fr"
replace order="0.5" if order=="Le"
replace order="" if order=="NU" |order=="No"
destring order, replace
sort order
drop if order==.
drop order
gen order=_n

local labels ""


levelsof order, local(req_nums)
foreach n of local req_nums {

    local experience = req_experience[`n']

    local labels `"`labels' `n' "`experience'""'
}


label define my_labels `labels'


label values order my_labels

twoway bar num order, barwidth(0.5) color(dkgreen)  ///
        ///
       xtitle("Required Experience") ///
       xlabel(1(1)15, valuelabel angle(45) labsize(1.8)) ///
       ytitle("Number of Jobs") title("Entry Level (N=100,104)", size(4)) name(g1, replace)
	   
restore





preserve
keep if careerlevel=="Intern/Student"
collapse (count) num=jid, by(req_experience)
drop if num<5
gen order=substr(req_experience, 1, 2)
replace order="0" if order=="Fr"
replace order="0.5" if order=="Le"
replace order="" if order=="NU" |order=="No"
destring order, replace
sort order
drop if order==.
drop order
gen order=_n

local labels ""


levelsof order, local(req_nums)
foreach n of local req_nums {

    local experience = req_experience[`n']

    local labels `"`labels' `n' "`experience'""'
}

label define my_labels `labels'


label values order my_labels

twoway bar num order, barwidth(0.5) color(dkgreen)  ///
        ///
       xtitle("Required Experience") ///
       xlabel(1(1)11, valuelabel angle(45) labsize(1.8)) ///
       ytitle("Number of Jobs") title("Intern/Student (N=13,040)", size(4)) name(g2, replace)
	   
restore


preserve
keep if careerlevel=="Experienced Professional"
collapse (count) num=jid, by(req_experience)
drop if num<31
gen order=substr(req_experience, 1, 2)
replace order="0" if order=="Fr"
replace order="0.5" if order=="Le"
replace order="" if order=="NU" |order=="No"
destring order, replace
sort order
drop if order==.
drop order
gen order=_n

local labels ""


levelsof order, local(req_nums)
foreach n of local req_nums {

    local experience = req_experience[`n']

    local labels `"`labels' `n' "`experience'""'
}


label define my_labels `labels'


label values order my_labels

twoway bar num order, barwidth(0.5) color(dkgreen)  ///
        ///
       xtitle("Required Experience") ///
       xlabel(1(1)17, valuelabel angle(45) labsize(1.8)) ///
       ytitle("Number of Jobs") title("Experienced Professional (N=211,572)", size(4)) name(g3, replace)
	   
restore


preserve
keep if careerlevel=="Department Head"
collapse (count) num=jid, by(req_experience)
drop if num<15
gen order=substr(req_experience, 1, 2)
replace order="0" if order=="Fr"
replace order="0.5" if order=="Le"
replace order="" if order=="NU" |order=="No"
destring order, replace
sort order
drop if order==.
drop order
gen order=_n

local labels ""

levelsof order, local(req_nums)
foreach n of local req_nums {

    local experience = req_experience[`n']

    local labels `"`labels' `n' "`experience'""'
}


label define my_labels `labels'


label values order my_labels

twoway bar num order, barwidth(0.5) color(dkgreen)  ///
        ///
       xtitle("Required Experience") ///
       xlabel(1(1)16, valuelabel angle(45) labsize(1.8)) ///
       ytitle("Number of Jobs") title("Department Head (N=4,686)", size(4)) name(g4, replace)
	   
restore

graph combine g2 g1 g3 g4
graph export "$figdesv2\job_check_2_1.png", replace as(png) name("Graph")


**# 3. Are salary levels aligned with career level tags?
import delimited "$input/Rozee/jobs_adb.csv", clear bindquote(strict) maxquotedrows(1000)
keep if careerlevel=="Department Head" | careerlevel=="Experienced Professional" | careerlevel=="Intern/Student" | careerlevel=="Entry Level"

replace salary_range_from= salary_range_from_hide if salary_range_from=="NULL"
replace salary_range_to= salary_range_to_hide if salary_range_to=="NULL"
drop salary_range_from_hide salary_range_to_hide
tab currency_unit
replace currency_unit ="PKR" if currency_unit=="Pakistani Rupee"
replace salary_range_from="" if salary_range_from=="NULL"| currency_unit!="PKR"
replace salary_range_to="" if salary_range_to=="NULL"| currency_unit!="PKR"
drop if currency_unit=="SR"
destring salary_range_from salary_range_to, replace
replace salary_range_to=salary_range_to*0.0035
replace salary_range_from=salary_range_from*0.0035
egen salary_median = rowmean(salary_range_to salary_range_from)
drop if salary_range_to< salary_range_from

gen order=1 if careerlevel=="Intern/Student"
replace order=2 if careerlevel=="Entry Level"
replace order=3 if careerlevel=="Experienced Professional"
replace order=4 if careerlevel=="Department Head"
sort order

graph box salary_median, over(careerlevel, sort(order)) noout ytitle("Salary(Dollar)") ylabel(0(200)1600) note("")
graph export "$figdesv2\job_check_3_1.png", replace as(png) name("Graph")


**# 4. Are the values in the req_experience and max_experience fields clean and interpretable? 

import delimited "$input/Rozee/jobs_adb.csv", clear bindquote(strict) maxquotedrows(1000)
tabout req_experience using "$tabdesv2\job_check_4_1.tex", replace style(tex) oneway c(col cum) f(2 2 2) clab(Percent_% Cum._%) npos(col) nlab(Freq.)
tabout max_experience using "$tabdesv2\job_check_4_2.tex", replace style(tex) oneway c(col cum) f(2 2 2) clab(Percent_% Cum._%) npos(col) nlab(Freq.)

**# 5. Similar to the experience requirement, is there a similar relationship between the education requirement and salary as well as career level?

**# 6. Is there a similar relationship between the age requirement and salary / career level?
import delimited "$input/Rozee/jobs_adb.csv", clear bindquote(strict) maxquotedrows(1000)
replace min_age="" if min_age=="NULL"
replace max_age="" if max_age=="NULL"
destring min_age max_age, replace
egen med_age=rowmean(min_age max_age)
drop if min_age>max_age &min_age!=.

replace salary_range_from= salary_range_from_hide if salary_range_from=="NULL"
replace salary_range_to= salary_range_to_hide if salary_range_to=="NULL"
drop salary_range_from_hide salary_range_to_hide
tab currency_unit
replace currency_unit ="PKR" if currency_unit=="Pakistani Rupee"
replace salary_range_from="" if salary_range_from=="NULL"| currency_unit!="PKR"
replace salary_range_to="" if salary_range_to=="NULL"| currency_unit!="PKR"
drop if currency_unit=="SR"
destring salary_range_from salary_range_to, replace
replace salary_range_to=salary_range_to*0.0035
replace salary_range_from=salary_range_from*0.0035
egen salary_median = rowmean(salary_range_to salary_range_from)
drop if salary_range_to< salary_range_from & salary_range_from!=.

binscatterhist salary_median med_age, hist(salary_median med_age) coefficient(0.0001) p xtitle("Age Requirement") ytitle("Salary(Dollar)")

graph export "$figdesv2\job_check_6_1.png", replace as(png) name("Graph")

import delimited "$input/Rozee/jobs_adb.csv", clear bindquote(strict) maxquotedrows(1000)
keep if careerlevel=="Department Head" | careerlevel=="Experienced Professional" | careerlevel=="Intern/Student" | careerlevel=="Entry Level"

gen order=1 if careerlevel=="Intern/Student"
replace order=2 if careerlevel=="Entry Level"
replace order=3 if careerlevel=="Experienced Professional"
replace order=4 if careerlevel=="Experienced Professional"
sort order

replace min_age="" if min_age=="NULL"
replace max_age="" if max_age=="NULL"
destring min_age max_age, replace
egen med_age=rowmean(min_age max_age)
drop if min_age>max_age &min_age!=.

graph box med_age, over(careerlevel, sort(order)) noout ytitle("Age Requirement")  note("")
graph export "$figdesv2\job_check_6_2.png", replace as(png) name("Graph")

**# 7.Are there significant differences in job salaries across different industries



**# 8. What is the distribution of the application duration for job postings?

*plot1
import delimited "$input/Rozee/jobs_adb.csv", clear bindquote(strict) maxquotedrows(1000)

gen date_ddl=date(applyby, "YMD")
format date_ddl %td

gen datestr=substr(displaydate, 1, 10)
gen date_dis=date(datestr, "YMD")
format date_dis %td
gen year=year(date_dis)

drop if year<2020

gen duration=date_ddl-date_dis
drop if duration<0

drop if duration>100

hist duration, by(year) color(dkgreen) xtitle("Application Duration") xlabel(0(10)100) note("")
graph export "$figdesv2\job_check_8_1.png", replace as(png) name("Graph")

*plot2
import delimited "$input/Rozee/jobs_adb.csv", clear bindquote(strict) maxquotedrows(1000)


replace totalpositions="" if totalpositions=="NULL"
replace totalpositions="" if totalpositions=="0" | totalpositions=="111"
replace totalpositions="35" if totalpositions=="35+"
destring totalpositions, replace


gen date_ddl=date(applyby, "YMD")
format date_ddl %td

gen datestr=substr(displaydate, 1, 10)
gen date_dis=date(datestr, "YMD")
format date_dis %td


gen duration=date_ddl-date_dis
drop if duration<0

binscatterhist totalpositions duration, hist(totalpositions duration) coefficient(0.0001) p xtitle("Application Durations") ytitle("Total Positions")

graph export "$figdesv2\job_check_8_2.png", replace as(png) name("Graph")

*plot3
import delimited "$input/Rozee/application_adb.csv", clear bindquote(strict)
collapse (count) num=cv_log_id, by(jid)
save "$input/Rozee/appication_temp.dta", replace

import delimited "$input/Rozee/jobs_adb.csv", clear bindquote(strict) maxquotedrows(1000)
gen date_ddl=date(applyby, "YMD")
format date_ddl %td

gen datestr=substr(displaydate, 1, 10)
gen date_dis=date(datestr, "YMD")
format date_dis %td


gen duration=date_ddl-date_dis
drop if duration<0

merge 1:1 jid using "$input/Rozee/appication_temp.dta"
drop if _merge==2

binscatterhist num duration, hist(num duration) coefficient(0.0001) p xtitle("Application Duration") ytitle("Num of Application Received")
graph export "$figdesv2\job_check_8_3.png", replace as(png) name("Graph")


**Plot4

replace totalpositions="" if totalpositions=="NULL"
replace totalpositions="" if totalpositions=="0" | totalpositions=="111"
replace totalpositions="35" if totalpositions=="35+"
destring totalpositions, replace


binscatterhist num totalpositions, hist(num totalpositions) coefficient(0.0001) p xtitle("Total Positions") ytitle("Num of Application Received")


graph export "$figdesv2\job_check_8_4.png", replace as(png) name("Graph")

**# 9. Is there a basic correlation between the number of total positions and the size of the companies posting those jobs?

import delimited "$input/Rozee/companies_adb.csv", clear bindquote(strict) maxquotedrows(100)
keep company_id no_of_employee nooffices
 save "$input/Rozee/companies_temp.dta", replace

import delimited "$input/Rozee/jobs_adb.csv", clear bindquote(strict) maxquotedrows(1000)
merge m:1 company_id using "$input/Rozee/companies_temp.dta"
drop if _merge==2
drop _merge

replace totalpositions="" if totalpositions=="NULL"
replace totalpositions="" if totalpositions=="0" | totalpositions=="111"
replace totalpositions="35" if totalpositions=="35+"
destring totalpositions, replace


bys company_id: egen totalpos=sum(totalpositions)
duplicates drop company_id, force

keep company_id totalpos no_of_employee nooffices

replace nooffices="" if nooffices=="1234" | nooffices=="1\'" | nooffices=="2000" |nooffices=="NULL"
replace nooffices="20" if nooffices=="20+"
destring nooffices, replace

binscatterhist totalpos nooffices, hist(totalpos nooffices) coefficient(0.0001) p xtitle("Num of Office") ytitle("Total Recruited Positions") ylabel(0(40)200) xlabel(0(3)21)

graph export "$figdesv2\job_check_9_1.png", replace as(png) name("Graph")


collapse (mean) totalpos=totalpos (count) num=company_id, by(no_of_employee)
drop if num<10
drop if no_of_employee=="" | no_of_employee=="NULL"
drop if no_of_employee=="101-300"
gen order=1 if no_of_employee=="1-10"
replace order=2 if no_of_employee=="11-50"
replace order=3 if no_of_employee=="51-100"
replace order=4 if no_of_employee=="101-200"
replace order=5 if no_of_employee=="201-300"
replace order=6 if no_of_employee=="301-600"
replace order=7 if no_of_employee=="601-1000"
replace order=8 if no_of_employee=="1001-1500"
replace order=9 if no_of_employee=="1501-2000"
replace order=10 if no_of_employee=="2001-2500"
replace order=11 if no_of_employee=="2501-3000"
replace order=12 if no_of_employee=="3001-3500"
replace order=13 if no_of_employee=="3501-4000"
replace order=14 if no_of_employee=="4001-4500"
replace order=15 if no_of_employee=="4501-5000"
replace order=16 if no_of_employee=="More than 5000"
sort order

local labels ""


levelsof order, local(req_nums)
foreach n of local req_nums {

    local experience = no_of_employee[`n']

    local labels `"`labels' `n' "`experience'""'
}


label define my_labels `labels'


label values order my_labels

twoway (bar num order, yaxis(2) barwidth(0.5) color(dkgreen) ylabel(0(5000)40000, axis(2))) ///
       (connected totalpos order, yaxis(1) color(black) ylabel(0(50)150, axis(1)) lw(0.5)),  ///
       xtitle("Number of Employee") legend(pos(11) ring(0) col(1) label(1 "Number") label(2 "Total Positions")) ///
       xlabel(1(1)16, valuelabel angle(45) labsize(2)) ///
       ytitle("Total Recruited Positions", axis(1)) ytitle("Number of Companies", axis(2))
	   
graph export "$figdesv2\job_check_9_2.png", replace as(png) name("Graph")

**# 10. Are the jobpackage, isfeatured, istopjob, and ispremiumjob variables generally consistent with Salary and Career Level?

**# 11. Are the current salary and expected salary of candidates in the application generally consistent with the salary listed in the job posting?

import delimited "$input/Rozee/jobs_adb.csv", clear bindquote(strict) maxquotedrows(1000)
replace salary_range_from= salary_range_from_hide if salary_range_from=="NULL"
replace salary_range_to= salary_range_to_hide if salary_range_to=="NULL"
drop salary_range_from_hide salary_range_to_hide
tab currency_unit
replace currency_unit ="PKR" if currency_unit=="Pakistani Rupee"
replace salary_range_from="" if salary_range_from=="NULL"| currency_unit!="PKR"
replace salary_range_to="" if salary_range_to=="NULL"| currency_unit!="PKR"
drop if currency_unit=="SR"
destring salary_range_from salary_range_to, replace
replace salary_range_to=salary_range_to*0.0035
replace salary_range_from=salary_range_from*0.0035
egen salary_median = rowmean(salary_range_to salary_range_from)
drop if salary_range_to< salary_range_from & salary_range_from!=.

keep jid salary_median
save "$input/Rozee/jobs_temp.dta", replace



import delimited "$input/Rozee/application_adb.csv", clear bindquote(strict)
keep jid currentsalary expectedsalary
replace currentsalary="" if currentsalary=="NULL"
replace expectedsalary="" if expectedsalary=="NULL"

merge m:1 jid using "$input/Rozee/jobs_temp.dta"
drop if _merge==2
drop _merge

binscatterhist salary_median expectedsalary, hist(salary_median expectedsalary) coefficient(0.0001) p xtitle("Expected Salary") ytitle("Job Salary(Dollar)") name(p1, replace)
binscatterhist salary_median currentsalary, hist(salary_median currentsalary) coefficient(0.0001) p xtitle("Current Salary") ytitle("Job Salary(Dollar)") name(p2, replace)

graph combine p1 p2
graph export "$figdesv2\job_check_11_1.png", replace as(png) name("Graph")


***************************
**#****More Exploratory****
***************************
**# 1. Are job types distributed differently across cities or regions?
import delimited "$input/Rozee/jobs_adb.csv", clear bindquote(strict) maxquotedrows(1000)
keep if country_id=="79"
split city_id, parse(,)
reshape long city_id, i(jid) j(city)
drop if city_id==""

destring city_id, force replace

merge m:1 city_id using "$input/Rozee/meta_data/cities.dta"

drop if _merge==2
drop _merge

save "$input/Rozee/jobs_temp.dta", replace

use "$input/Rozee/jobs_temp.dta", clear
gen datestr=substr(displaydate, 1, 10)
gen date_dis=date(datestr, "YMD")
format date_dis %td
gen year=year(date_dis)

drop if year<2020

keep if careerlevel=="Department Head" | careerlevel=="Experienced Professional" | careerlevel=="Intern/Student" | careerlevel=="Entry Level"

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

gen highlevel=1 if careerlevel=="Department Head" | careerlevel=="Experienced Professional"
gen lowlevel=1 if careerlevel=="Intern/Student" | careerlevel=="Entry Level"

collapse (count) jobnum=jid (sum) highlevel=highlevel lowlevel=lowlevel (mean) salary=salary_median, by(city_id cityy_name)

rename cityy_name ADM2_EN

drop if ADM2_EN==""
merge 1:1 ADM2_EN using "$input/shapefile_pk/pak_admbnda_adm2_wfp_20220909.dta"

drop if _merge==1

spmap jobnum using "pak_admbnda_adm2_wfp_20220909_shp.dta" , id(_ID)  clnumber(8) fcolor(Reds2)   legstyle(1) legend(position(5) size(*1.2)) title("Space Distribution of Job Number") 

graph export "$figdesv2\job_explore_1_1.png", replace as(png) name("Graph")

spmap highlevel using "pak_admbnda_adm2_wfp_20220909_shp.dta" , id(_ID)  clnumber(12) fcolor(Greens2)   legstyle(1) legend(position(5) size(*1.2)) title("Space Distribution of High-Level Job Number") name(p1, replace)
spmap lowlevel using "pak_admbnda_adm2_wfp_20220909_shp.dta" , id(_ID)  clnumber(12) fcolor(Greens2)   legstyle(1) legend(position(5) size(*1.2)) title("Space Distribution of Low-Level Job Number") name(p2, replace)

graph combine p1 p2, col(1)

graph export "$figdesv2\job_explore_1_2.png", replace as(png) name("Graph")

spmap salary using "pak_admbnda_adm2_wfp_20220909_shp.dta" , id(_ID)  clnumber(12) fcolor(Blues2)   legstyle(1) legend(position(5) size(*1.2)) title("Space Distribution of Job Salary")

graph export "$figdesv2\job_explore_1_3.png", replace as(png) name("Graph")


use "$input/Rozee/jobs_temp.dta", clear
gen datestr=substr(displaydate, 1, 10)
gen date_dis=date(datestr, "YMD")
format date_dis %td
gen year=year(date_dis)

drop if year<2020

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

collapse (mean) salary=salary_median, by(city_id cityy_name year)

gen year_str="20" if year==2020 |year==2021
replace year_str="22"  if year==2022 |year==2023
replace year_str="24"   if year==2024 | year==2025

collapse (mean) salary, by(city_id cityy_name year_str)

reshape wide salary, i(city_id) j(year_str) string

rename cityy_name ADM2_EN

drop if ADM2_EN==""
duplicates drop ADM2_EN, force
merge 1:1 ADM2_EN using "$input/shapefile_pk/pak_admbnda_adm2_wfp_20220909.dta"

drop if _merge==1

spmap salary20 using "pak_admbnda_adm2_wfp_20220909_shp.dta" , id(_ID)  clnumber(12) fcolor(Blues2)   legstyle(1) legend(position(5) size(*1.2)) title("Space Distribution of Job Salary(20-21)") name(p1, replace)
spmap salary22 using "pak_admbnda_adm2_wfp_20220909_shp.dta" , id(_ID)  clnumber(12) fcolor(Blues2)   legstyle(1) legend(position(5) size(*1.2)) title("Space Distribution of Job Salary(22-23)") name(p2, replace)
spmap salary24 using "pak_admbnda_adm2_wfp_20220909_shp.dta" , id(_ID)  clnumber(12) fcolor(Blues2)   legstyle(1) legend(position(5) size(*1.2)) title("Space Distribution of Job Salary(24-25)") name(p3, replace)

graph display p1
graph export "$figdesv2\job_explore_1_4.png", replace as(png) name("p1")
graph display p2
graph export "$figdesv2\job_explore_1_5.png", replace as(png) name("p2")
graph display p3
graph export "$figdesv2\job_explore_1_6.png", replace as(png) name("p3")

**# 2. A job's salary is typically a range. How is the size of this range distributed
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

gen salary_range=salary_range_to - salary_range_from
gen salary_range_relative = salary_range/salary_median

gen datestr=substr(displaydate, 1, 10)
gen date_dis=date(datestr, "YMD")
format date_dis %td
gen year=year(date_dis)

drop if year<2020

drop if salary_range>2000

hist salary_range, xtitle("Salary Range (USD)") xlabel(0(1000)8000) name(p1, replace)
hist salary_range_relative, by(year) xtitle("Relative Salary Range (Range/Mean)") name(p2, replace)

graph combine p1 p2
graph export "$figdesv2\job_explore_2_1.png", replace as(png) name("Graph")

replace totalpositions="" if totalpositions=="NULL"
replace totalpositions="" if totalpositions=="0" | totalpositions=="111"
replace totalpositions="35" if totalpositions=="35+"
destring totalpositions, replace

binscatterhist salary_range_relative totalpositions, hist(salary_range_relative totalpositions) coefficient(0.0001) p xtitle("Total Positions") ytitle("Relative Salary Range (Range/Mean)") name(p1, replace)

replace req_experience="NULL" if max_experience=="NULL"
gen min_exp=substr(req_experience, 1, 2)
gen max_exp=substr(max_experience, 1, 2)
replace min_exp="0" if min_exp=="Fr"
replace min_exp="0" if min_exp=="Le"
replace min_exp="" if min_exp=="NU"
replace min_exp="0" if min_exp=="No"
replace max_exp="0" if max_exp=="Fr"
replace max_exp="0" if max_exp=="Le"
replace max_exp="" if max_exp=="NU"
replace max_exp="0" if max_exp=="No"
destring min_exp max_exp, replace force

drop if min_exp>max_exp & min_exp!=.

gen exp_range=max_exp - min_exp

binscatterhist salary_range_relative exp_range, hist(salary_range_relative exp_range) coefficient(0.0001) p xtitle("Experience Requirement Range") ytitle("Relative Salary Range (Range/Mean)") name(p2, replace)

graph combine p1 p2
graph export "$figdesv2\job_explore_2_2.png", replace as(png) name("Graph")



import delimited "$input/Rozee/companies_adb.csv", clear bindquote(strict) maxquotedrows(100)
rename created created_company
keep company_id no_of_employee nooffices companyowntype created_company
 save "$input/Rozee/companies_temp.dta", replace

import delimited "$input/Rozee/jobs_adb.csv", clear bindquote(strict) maxquotedrows(1000)

merge m:1 company_id using "$input/Rozee/companies_temp.dta"
drop if _merge==2
drop _merge

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

gen salary_range=salary_range_to - salary_range_from
gen salary_range_relative = salary_range/salary_median

preserve
replace nooffices="" if nooffices=="1234" | nooffices=="1\'" | nooffices=="2000" |nooffices=="NULL"
replace nooffices="20" if nooffices=="20+"
destring nooffices, replace

binscatterhist salary_range_relative nooffices, hist(salary_range_relative nooffices) coefficient(0.0001) p xtitle("Number of Offices") ytitle("Relative Salary Range (Range/Mean)") 
graph export "$figdesv2\job_explore_2_3.png", replace as(png) name("Graph")
restore

preserve

drop if companyowntype=="NULL"

graph box salary_range_relative, over(companyowntype) noout ytitle("Relative Salary Range (Range/Mean)")  note("")
graph export "$figdesv2\job_explore_2_4.png", replace as(png) name("Graph")

restore

preserve

gen datestr=substr(displaydate, 1, 10)
gen date_dis=date(datestr, "YMD")
format date_dis %td
gen month_job=mofd(date_dis)

replace datestr=substr(created_company, 1, 10)
replace date_dis=date(datestr, "YMD")
format date_dis %td
gen month_company=mofd(date_dis)

gen month_gap=month_job-month_company
drop if month_gap<0

binscatterhist salary_range_relative month_gap, hist(salary_range_relative month_gap) coefficient(0.0001) xlabel(0(40)200)p xtitle("Months after Company Entry") ytitle("Relative Salary Range (Range/Mean)") 

graph export "$figdesv2\job_explore_2_5.png", replace as(png) name("Graph")

restore

**# 3. What are the trends for career level and salary for jobs in different industries? 

**# 4. For the job posting, what does the application timing usually look like?
import delimited "$input/Rozee/application_adb.csv", clear bindquote(strict)
keep cv_log_id jid apply_date

gen datestr=substr(apply_date, 1, 10)

gen date_dis=date(datestr, "YMD")
rename date_dis date_apply

drop apply_date datestr
save "$input/Rozee/application_time.dta", replace

import delimited "$input/Rozee/jobs_adb.csv", clear bindquote(strict) maxquotedrows(1000)

replace salary_range_from= salary_range_from_hide if salary_range_from=="NULL"
replace salary_range_to= salary_range_to_hide if salary_range_to=="NULL"
drop salary_range_from_hide salary_range_to_hide
tab currency_unit
replace currency_unit ="PKR" if currency_unit=="Pakistani Rupee"
replace salary_range_from="" if salary_range_from=="NULL"| currency_unit!="PKR"
replace salary_range_to="" if salary_range_to=="NULL"| currency_unit!="PKR"
drop if currency_unit=="SR"
destring salary_range_from salary_range_to, replace
replace salary_range_to=salary_range_to*0.0035
replace salary_range_from=salary_range_from*0.0035
egen salary_median = rowmean(salary_range_to salary_range_from)
drop if salary_range_to< salary_range_from & salary_range_from!=.



merge m:1 company_id using "$input/Rozee/companies_temp.dta"
drop if _merge==2

keep jid created displaydate applyby deactivateafterapplyby company_id totalpositions careerlevel min_age max_age salary_median no_of_employee companyowntype nooffices

keep if careerlevel=="Department Head" | careerlevel=="Experienced Professional" | careerlevel=="Intern/Student" | careerlevel=="Entry Level"


gen highlevel=1 if careerlevel=="Department Head" | careerlevel=="Experienced Professional"
replace highlevel=0 if careerlevel=="Intern/Student" | careerlevel=="Entry Level"
drop careerlevel

merge 1:m jid using "$input/Rozee/application_time.dta"

drop if _merge==2
drop _merge

gen datestr=substr(displaydate, 1, 10)
gen date_dis=date(datestr, "YMD")
rename date_dis date_jobdisplay
drop datestr

gen dayafterjob=date_apply-date_jobdisplay
drop if dayafterjob<0


collapse (count) num_job=cv_log_id, by(jid highlevel dayafterjob)

preserve
collapse (mean) num_job, by(dayafterjob)
keep if dayafterjob<30

twoway connected num_job dayafterjob, xtitle("Days after Job Creation") ytitle("Mean Number of Application Received")

graph export "$figdesv2\job_explore_4_1.png", replace as(png) name("Graph")
restore

preserve
keep if highlevel==1
collapse (mean) num_job, by(dayafterjob)
keep if dayafterjob<30

twoway connected num_job dayafterjob, xtitle("Days after Job Creation") ytitle("Mean Number of Application Received") title("High-Level Jobs") name(p1, replace)
restore

preserve
keep if highlevel==0
collapse (mean) num_job, by(dayafterjob)
keep if dayafterjob<30

twoway connected num_job dayafterjob, xtitle("Days after Job Creation") ytitle("Mean Number of Application Received") title("Low-Level Jobs") name(p2, replace)
restore

graph combine p1 p2

graph export "$figdesv2\job_explore_4_2.png", replace as(png) name("Graph")


**# 5. What's the difference between jobs with quick questions and those without?
import delimited "$input/Rozee/jobs_adb.csv", clear bindquote(strict) maxquotedrows(1000)

keep if careerlevel=="Department Head" | careerlevel=="Experienced Professional" | careerlevel=="Intern/Student" | careerlevel=="Entry Level"

collapse (count) num=jid, by(applyjobquestion careerlevel )

gen order=1 if careerlevel=="Intern/Student"
replace order=2 if careerlevel=="Entry Level"
replace order=3 if careerlevel=="Experienced Professional"
replace order=4 if careerlevel=="Department Head"
sort order

graph pie num, over(careerlevel) by(applyjobquestion) sort(order)

graph export "$figdesv2\job_explore_5_1.png", replace as(png) name("Graph")



import delimited "$input/Rozee/jobs_adb.csv", clear bindquote(strict) maxquotedrows(1000)

replace salary_range_from= salary_range_from_hide if salary_range_from=="NULL"
replace salary_range_to= salary_range_to_hide if salary_range_to=="NULL"
drop salary_range_from_hide salary_range_to_hide
tab currency_unit
replace currency_unit ="PKR" if currency_unit=="Pakistani Rupee"
replace salary_range_from="" if salary_range_from=="NULL"| currency_unit!="PKR"
replace salary_range_to="" if salary_range_to=="NULL"| currency_unit!="PKR"
drop if currency_unit=="SR"
destring salary_range_from salary_range_to, replace
replace salary_range_to=salary_range_to*0.0035
replace salary_range_from=salary_range_from*0.0035
egen salary_median = rowmean(salary_range_to salary_range_from)
drop if salary_range_to< salary_range_from & salary_range_from!=.

graph box salary_median, over(applyjobquestion) noout ytitle("Job Salary") note("")


graph export "$figdesv2\job_explore_5_2.png", replace as(png) name("Graph")

merge 1:1 jid using "$input/Rozee/appication_temp.dta"
drop if _merge==2

graph box num, over(applyjobquestion) noout ytitle("Number of Application Received") note("")
graph export "$figdesv2\job_explore_5_3.png", replace as(png) name("Graph")

drop _merge
merge m:1 company_id using "$input/Rozee/companies_temp.dta"
drop if _merge==2


preserve
drop if companyowntype=="NULL"

collapse (count) num=jid, by(applyjobquestion companyowntype )

graph pie num, over(companyowntype) by(applyjobquestion)
graph export "$figdesv2\job_explore_5_4.png", replace as(png) name("Graph")
restore

collapse (count) num=jid, by(applyjobquestion no_of_employee)
drop if no_of_employee=="" | no_of_employee=="NULL"

gen order=1 if no_of_employee=="1-10"
replace order=2 if no_of_employee=="11-50"
replace order=3 if no_of_employee=="51-100"
replace order=4 if no_of_employee=="101-200"
replace order=5 if no_of_employee=="201-300"
replace order=6 if no_of_employee=="301-600"
replace order=7 if no_of_employee=="601-1000"
replace order=8 if no_of_employee=="1001-1500"
replace order=9 if no_of_employee=="1501-2000"
replace order=10 if no_of_employee=="2001-2500"
replace order=11 if no_of_employee=="2501-3000"
replace order=12 if no_of_employee=="3001-3500"
replace order=13 if no_of_employee=="3501-4000"
replace order=14 if no_of_employee=="4001-4500"
replace order=15 if no_of_employee=="4501-5000"
replace order=16 if no_of_employee=="More than 5000"

drop if order==.

gen group=floor((order-0.5)/4)

gen employee="1-200" if group==0
replace employee="201-1500" if group==1
replace employee="1501-3500" if group==2
replace employee="More than 3500" if group==3

graph pie num, over(no_of_employee) by(applyjobquestion) sort(order) legend(size(*0.5) col(2))
graph export "$figdesv2\job_explore_5_5.png", replace as(png) name("Graph")

**# 6. Do higher-level jobs require more skills? Does skill count or importance correlate with pay?
import delimited "$input/Rozee/jobs_skills_adb.csv", clear bindquote(strict)

bys jid: egen skill_num=count(skill_id)
bys jid: egen skill_im=sum(skill_importance)
gen skill_noim=skill_num-skill_im
keep jid skill_noim skill_num skill_im
duplicates drop jid, force

save "$input/Rozee/jobs_skills_temp.dta", replace

import delimited "$input/Rozee/jobs_adb.csv", clear bindquote(strict) maxquotedrows(1000)
keep if careerlevel=="Department Head" | careerlevel=="Experienced Professional" | careerlevel=="Intern/Student" | careerlevel=="Entry Level"

gen order=1 if careerlevel=="Intern/Student"
replace order=2 if careerlevel=="Entry Level"
replace order=3 if careerlevel=="Experienced Professional"
replace order=4 if careerlevel=="Department Head"
sort order

merge 1:1 jid using "$input/Rozee/jobs_skills_temp.dta"
drop if _merge==2
drop _merge

graph box skill_num, over(careerlevel, sort(order)) noout ytitle("Num of Skills") note("")

graph export "$figdesv2\job_explore_6_1.png", replace as(png) name("Graph")

replace salary_range_from= salary_range_from_hide if salary_range_from=="NULL"
replace salary_range_to= salary_range_to_hide if salary_range_to=="NULL"
drop salary_range_from_hide salary_range_to_hide
tab currency_unit
replace currency_unit ="PKR" if currency_unit=="Pakistani Rupee"
replace salary_range_from="" if salary_range_from=="NULL"| currency_unit!="PKR"
replace salary_range_to="" if salary_range_to=="NULL"| currency_unit!="PKR"
drop if currency_unit=="SR"
destring salary_range_from salary_range_to, replace
replace salary_range_to=salary_range_to*0.0035
replace salary_range_from=salary_range_from*0.0035
egen salary_median = rowmean(salary_range_to salary_range_from)
drop if salary_range_to< salary_range_from & salary_range_from!=.

binscatterhist skill_num salary_median, hist(skill_num salary_median) coefficient(0.0001) p xtitle("Job Salary(Dollar)") ytitle("Num of Skills") name(p1, replace)
binscatterhist skill_im salary_median, hist(skill_im salary_median) coefficient(0.0001) p xtitle("Job Salary(Dollar)") ytitle("Num of Important Skills") name(p2, replace)

graph combine p1 p2

graph export "$figdesv2\job_explore_6_2.png", replace as(png) name("Graph")

gen datestr=substr(displaydate, 1, 10)
gen date_dis=date(datestr, "YMD")
format date_dis %td
gen year=year(date_dis)

drop if year<2020

hist skill_num, by(year) color(dkgreen) xlabel(0(5)30) xtitle("Number of Skills") note("") name(p1, replace)
hist skill_noim, by(year) color(dkgreen) xlabel(0(5)30) xtitle("Number of Non-Important Skills") note("") name(p2, replace)

graph combine p1 p2, rows(1)
graph export "$figdesv2\job_explore_6_3.png", replace as(png) name("Graph")

gen im_pctg=skill_noim/skill_num

binscatterhist skill_noim salary_median, coefficient(0.0001) p xtitle("Job Salary(Dollar)") ytitle("Num of Non Important Skills") name(p1, replace)
binscatterhist im_pctg salary_median,  coefficient(0.0001) p xtitle("Job Salary(Dollar)") ytitle("Pctg of Non Important Skills") name(p2, replace)

graph combine p1 p2, rows(1)
graph export "$figdesv2\job_explore_6_4.png", replace as(png) name("Graph")


import delimited "$input/Rozee/jobs_adb.csv", clear bindquote(strict) maxquotedrows(1000)
merge 1:1 jid using "$input/Rozee/jobs_skills_temp.dta"
drop if _merge==2
drop _merge

merge 1:1 jid using "$input/Rozee/appication_temp.dta"
drop if _merge==2
drop _merge

gen noim_pctg=skill_noim/skill_num

binscatterhist num skill_num, coefficient(0.0001) p xtitle("Num of Skills") ytitle("Num of Application Received") name(p1, replace)

binscatterhist num skill_num, control(skill_im) coefficient(0.0001) p xtitle("Num of Skills") ytitle("Num of Application Received") note("Control the number of important skills") name(p2, replace)

graph combine p1 p2
graph export "$figdesv2\job_explore_6_5.png", replace as(png) name("Graph")

binscatterhist num skill_noim, control(skill_num) coefficient(0.0001) p xtitle("Num of Unimportant Skills") ytitle("Num of Application Received") note("Control the number of skills") name(p3, replace)
graph export "$figdesv2\job_explore_6_6.png", replace as(png) name("p3")

