ssc install tabout, replace

*************************
*** DATA DESCRIPTION ***
*************************
**#Meta Data

import delimited "$input/Rozee/meta_data/countries.csv", clear bindquote(strict)

import delimited "$input/Rozee/meta_data/cities.csv", clear bindquote(strict)
count if city_lat=="NULL"
*54,824

import delimited "$input/Rozee/meta_data/areas.csv", clear bindquote(strict)
count if lat=="NULL"
*10

import delimited "$input/Rozee/meta_data/skills.csv", clear bindquote(strict)

**#Application Data

***************************
****application_adb.csv****
***************************
import delimited "$input/Rozee/application_adb.csv", clear bindquote(strict)

*N
count

*Unique id
distinct cv_log_id

*Other id information
count if test_code=="NULL" | test_code=="" // 21,860,661

preserve
bys jid: egen num=count(jid)
duplicates drop jid, force
est clear 
estpost tabstat num, c(stat) stat(count mean median min max)

esttab using "$tabdes\application_appnum_sum.tex", replace ////
  cells("count(fmt(%8.0fc)) Mean(fmt(%6.1fc)) p50(fmt(%6.0fc))  Min(fmt(%6.0fc)) Max(fmt(%6.0fc))")   nonumber ///
  nomtitle nonote noobs label booktabs       ///
  collabels("N" "Mean" "Median" "Min" "Max")  ///
  title("Summary Statistics of Num. of Applications per Job  (Application)") ///
  posthead("\label{tab:appappnum}")
restore


**Main variables
*apply_date
gen datestr=substr(apply_date, 1, 10)
gen date=date(datestr, "YMD")
format date %td
sort date

gen year=year(date)
gen month=mofd(date)
format month %tm
set scheme plotplainblind

preserve
collapse (count) cv_log_id, by(month)
twoway connected cv_log_id month, xtitle("Month") ytitle("Num of Applications")
graph export "$figdes\month_distribution_application.png", replace as(png) name("Graph")
restore

*emp_status
tab emp_status

*test_Status
tab test_status

*currentSalary,expectedSalary

*Summary statistics
replace currentsalary="" if currentsalary=="NULL"
replace expectedsalary="" if expectedsalary=="NULL"
destring currentsalary expectedsalary, replace

est clear 
estpost tabstat currentsalary expectedsalary, c(stat) stat(count mean median min max)

esttab using "$tabdes\application_sum.tex", replace ////
  cells("count(fmt(%12.0fc)) Mean(fmt(%12.0fc)) p50(fmt(%12.0fc)) Min(fmt(%12.0fc)) Max(fmt(%8.0fc))")   nonumber ///
  nomtitle nonote noobs label booktabs       ///
  collabels("N" "Mean" "Median" "Min" "Max")  ///
  title("Summary Statistics (Application)") ///
  posthead("\label{tab:application}")
  





**#Job Data

***************************
****jobs_adb.csv****
***************************
import delimited "$input/Rozee/jobs_adb.csv", clear bindquote(strict) maxquotedrows(1000)


 *N
count

*Unique id
distinct jid

*Other id information
count if city_id=="NULL"
distinct city_id if city_id!="NULL"
count if country_id=="NULL"
distinct country_id if country_id!="NULL"
count if country_id=="79"
count if area_id=="NULL" | area_id==""
distinct area_id if area_id!="NULL" & area_id!=""

**Main variables

*title, job_type_id, job_shift_id, genderid
distinct title

*req_experience, max_experience
count if max_experience=="NULL" | max_experience==""
tab req_experience

*salary_range_from/to, currency_unit
preserve
replace salary_range_from= salary_range_from_hide if salary_range_from=="NULL"
replace salary_range_to= salary_range_to_hide if salary_range_to=="NULL"
drop salary_range_from_hide salary_range_to_hide
count if salary_range_from=="NULL"
tab currency_unit
replace currency_unit ="PKR" if currency_unit=="Pakistani Rupee"
replace salary_range_from="" if salary_range_from=="NULL"| currency_unit!="PKR"
replace salary_range_to="" if salary_range_to=="NULL"| currency_unit!="PKR"
destring salary_range_from salary_range_to, replace
replace salary_range_to=salary_range_to*0.0035
replace salary_range_from=salary_range_from*0.0035
egen salary_median = rowmean(salary_range_to salary_range_from)
drop if salary_range_to< salary_range_from

est clear 
estpost tabstat salary_range_from salary_range_to salary_median, c(stat) stat(count mean median min max)

esttab using "$tabdes\job_salary_sum.tex", replace ////
  cells("count(fmt(%6.0fc)) Mean(fmt(%6.2fc)) p50(fmt(%6.0fc)) Min Max")   nonumber ///
  nomtitle nonote noobs label booktabs       ///
  collabels("N" "Mean" "Median"  "Min" "Max")  ///
  title("Summary Statistics of Salary (Jobs)") ///
  posthead("\label{tab:companysalary}")
restore

*created displaydate applyby deactivateafterapplyby
preserve
gen date=date(applyby, "YMD")
format date %td
sort date

gen year=year(date)
collapse (count) jid, by(year)
twoway connected jid year, xtitle("Year") ytitle("Num of Jobs")
graph export "$figdes\year_distribution_jobs.png", as(png) name("Graph")
restore

*industry_id, department_id
count if industry_id=="NULL" | industry_id==""
distinct industry_id
count if department_id=="NULL" | department_id==""
distinct department_id

*min_education max_education_id
distinct min_education
count if min_education=="NULL"
count if max_education_id=="NULL"
tab max_education_id
tab min_education

tabout min_education using "$tabdes\job_freq4.tex", replace style(tex) oneway c(col cum) f(2 2 2) clab(Percent_% Cum._%) npos(col) nlab(Freq.)

*totalpositions
count if totalpositions=="" | totalpositions=="NULL"

preserve
replace totalpositions="" if totalpositions=="NULL"
replace totalpositions="" if totalpositions=="0" | totalpositions=="111"
replace totalpositions="35" if totalpositions=="35+"
destring totalpositions, replace

est clear 
estpost tabstat totalpositions, c(stat) stat(count mean median sd min max)

esttab using "$tabdes\job_positionnum_sum.tex", replace ////
  cells("count(fmt(%6.0fc)) Mean(fmt(%6.2fc)) p50(fmt(%6.2fc)) SD(fmt(%6.2fc)) Min Max")   nonumber ///
  nomtitle nonote noobs label booktabs       ///
  collabels("N" "Mean" "Median" "SD" "Min" "Max")  ///
  title("Summary Statistics of Position Number (Jobs)") ///
  posthead("\label{tab:company_positionnum}")
restore

*careerlevelid careerlevel
count if careerlevelid=="NULL" | careerlevelid==""
tab careerlevel

*min_age max_age
count if min_age=="NULL" | min_age==""
replace min_age="" if min_age=="NULL"
replace max_age="" if max_age=="NULL"
destring min_age max_age, replace

preserve
egen med_age=rowmean(min_age max_age)
est clear 
estpost tabstat min_age max_age med_age, c(stat) stat(count mean median sd min max)

esttab using "$tabdes\job_age_sum.tex", replace ////
  cells("count(fmt(%6.0fc)) Mean(fmt(%6.2fc)) p50(fmt(%6.2fc)) SD(fmt(%6.2fc)) Min Max")   nonumber ///
  nomtitle nonote noobs label booktabs       ///
  collabels("N" "Mean" "Median" "SD" "Min" "Max")  ///
  title("Summary Statistics of Age Requirements (Jobs)") ///
  posthead("\label{tab:company_age}")
restore

*jobpackage isfeatured istopjob ispremiumjob applyjobquestion
tabout jobpackage isfeatured istopjob ispremiumjob applyjobquestion using "$tabdes\job_freq1.tex", replace style(tex) oneway c(col cum) f(2 2 2) clab(Percent_% Cum._%) npos(col) nlab(Freq.)

* tb_id tb_require
tab tb_id
tab tb_require

*description
count if description=="NULL" | description==""

*filter_gender filter_experience filter_degree filter_age filter_city isdeleted
count if isdeleted=="N" & deletedon!="NULL" & deletedon!="0000-00-00 00:00:00"
count if isdeleted=="Y" & (deletedon=="NULL" | deletedon=="0000-00-00 00:00:00")
tabout filter_gender filter_experience filter_degree filter_age filter_city isdeleted using "$tabdes\job_freq2.tex", replace style(tex) oneway c(col cum) f(2 2 2) clab(Percent_% Cum._%) npos(col) nlab(Freq.)


***************************
****deleted_jobs_adb.csv****
***************************

import delimited "$input/Rozee/deleted_jobs_adb.csv", clear bindquote(strict)

count


***************************
****jobs_skills_adb.csv****
***************************
import delimited "$input/Rozee/jobs_skills_adb.csv", clear bindquote(strict)

*N, uniqueID
distinct jid skill_id, j

**Main variables
*skill_id,skill_importance
tab skill_importance
bys jid: egen num=count(jid)

preserve
duplicates drop jid, force

hist num, xtitle("Num. of Skill Attched to Jobs")
graph export "$figdes\hist_skillnum_job.png", replace as(png) name("Graph")

est clear 
estpost tabstat num, c(stat) stat(count mean median sd min max)

esttab using "$tabdes\job_skillnum_sum.tex", replace ////
  cells("count(fmt(%8.0fc)) Mean(fmt(%6.2fc)) p50(fmt(%6.0fc)) SD(fmt(%6.2fc)) Min Max")   nonumber ///
  nomtitle nonote noobs label booktabs       ///
  collabels("N" "Mean" "Median" "SD" "Min" "Max")  ///
  title("Summary Statistics of Num. of Skill Attched to Jobs  (Jobs)") ///
  posthead("\label{tab:jobskillnum}")
 restore
 
 
preserve
bys skill_id: egen skillnum=count(skill_id)
duplicates drop skill_id, force
restore

bys jid: egen skillmean=mean(skill_importance)
duplicates drop jid, force

hist skillmean, xtitle("Mean of Skill Importance for Each Job")
graph export "$figdes\hist_skillmean_job.png", replace as(png) name("Graph")
est clear 
estpost tabstat skillmean, c(stat) stat(count mean median min max)

esttab using "$tabdes\job_skillmean_sum.tex", replace ////
  cells("count(fmt(%8.0fc)) Mean(fmt(%6.2fc)) p50(fmt(%6.0fc))  Min Max")   nonumber ///
  nomtitle nonote noobs label booktabs       ///
  collabels("N" "Mean" "Median" "Min" "Max")  ///
  title("Summary Statistics of Mean of Skill Importance  (Jobs)") ///
  posthead("\label{tab:jobskillmean}")
  
  
  
  
  



*****************************************
****apply_job_qucik_questions_adb.csv****
*****************************************
import delimited "$input/Rozee/apply_job_qucik_questions_adb.csv", clear bindquote(strict)
 
 *N
count

*Unique id
distinct questionid


  
 ***************************************
****apply_job_quick_answers_adb.csv****
***************************************
 import delimited "$input/Rozee/apply_job_qucik_answers_adb.csv", clear bindquote(strict) maxquotedrows(100)
 drop if jobquestionid==0
*N
count

*Unique id
distinct  userid jid jobquestionid, j
/*        Observations
      total   distinct
    4879795    4871696
*/


*****************************************
****test\_builder\_questions\_adb.csv****
*****************************************
import delimited "$input/Rozee/test_builder_questions_adb.csv", clear bindquote(strict) maxquotedrows(100)


*N, unique ID
distinct tb_id q_id,j


*****************************************
****test\_builder\_answers\_adb.csv****
*****************************************
import delimited "$input/Rozee/test_builder_answers_adb.csv", clear bindquote(strict) maxquotedrows(100)


*N, unique ID
distinct tb_id test_code q_id,j
distinct test_code q_id,j
/*        Observations
      total   distinct
   34345509   3.23e+07
*/






**#Company Data

***************************
****companies_adb.csv****
***************************
import delimited "$input/Rozee/companies_adb.csv", clear bindquote(strict) maxquotedrows(100)

 *N
count

*Unique id
distinct company_id

*Other id information
count if city_id=="NULL"
distinct city_id if city_id!="NULL"
count if country_id=="NULL"
distinct country_id if country_id!="NULL"
count if country_id=="79"

**Main variables

* company_detail
count if company_detail=="." | company_detail=="NULL" | company_detail=="," |company_detail==", ," |company_detail=="..."

*no_of_employee
tabulate no_of_employee

*operating_since
count if operating_since=="-" | operating_since=="NULL" | operating_since==""

*created
gen datestr=substr(created, 1, 10)
gen date=date(datestr, "YMD")
format date %td
sort date

gen year=year(date)
set scheme plotplainblind

preserve
collapse (count) company_id, by(year)
twoway connected company_id year,   xtitle("Year") ytitle("Num of Companies")
graph export "$figdes\year_distribution_copanies_entry.png", as(png) name("Graph")
restore

* industry_id
distinct  industry_id

*ppsp
count if ppsp=="-" | ppsp=="NULL" | ppsp=="" | missing(ppsp)

*companyOwnType
count if companyowntype=="-" | companyowntype=="NULL" | companyowntype=="" |missing(companyowntype)
tab companyowntype if companyowntype!="-" & companyowntype!="NULL" & companyowntype!="" & !missing(companyowntype)
replace companyowntype="Public" if companyowntype=="Public\'"
replace companyowntype="" if companyowntype=="NULL"

*contact_name / contact_designation
count if contact_name=="-" | contact_name=="NULL" | contact_name=="" | missing(contact_name)
count if contact_designation=="-" | contact_designation=="NULL" | contact_designation=="" | missing(contact_designation)

*noOffices
count if nooffices=="-" | nooffices=="NULL" | nooffices=="" 
replace nooffices="" if nooffices=="1234" | nooffices=="1\'" | nooffices=="2000" |nooffices=="NULL"
replace nooffices="20" if nooffices=="20+"
destring nooffices, replace

est clear 
estpost tabstat nooffices, c(stat) stat(count mean median sd min max)

esttab using "$tabdes\company_sum.tex", replace ////
  cells("count(fmt(%6.0fc)) Mean(fmt(%6.2fc)) p50(fmt(%6.0fc))  Min Max")   nonumber ///
  nomtitle nonote noobs label booktabs       ///
  collabels("N" "Mean" "Median" "Min" "Max")  ///
  title("Summary Statistics (Company)") ///
  posthead("\label{tab:company}")
  
hist nooffices, xtitle("Num. of Offices (Company)")
graph export "$figdes\hist_officenum_company.png", replace as(png) name("Graph")


*originCompany
count if origincompany=="-" | origincompany=="NULL" | origincompany=="" | missing(origincompany)

*company_status
tab company_status if company_status!="NULL" & company_status!="" &!missing(company_status)
replace company_status="" if company_status=="NULL"

tabout companyowntype company_status using "$tabdes\company_freq1.tex", append style(tex) oneway c(col cum) f(2 2 2) clab(Percent_% Cum._%) npos(col) nlab(Freq.)


*company_address
count if company_address=="NULL" | missing(company_address)


















**#User (Candidate) Data

***************************
****users_adb.csv****
***************************
import delimited "$input/Rozee/users_adb.csv", clear varnames(1) bindquote(strict)

*N, uniqueID


*Other id information
count if city_id=="NULL"
distinct city_id if city_id!="NULL"
count if country_id=="NULL"
distinct country_id if country_id!="NULL"
count if country_id=="79"
count if area_id=="NULL" | area_id==""
distinct area_id if area_id!="NULL" & area_id!=""
count if nationality_id=="NULL"
distinct nationality_id if nationality_id!="NULL"
count if nationality_id=="79"

**Main variables

*gender_id maritalstatus dobirth profile_access
preserve
gen date_birth=date(dobirth, "YMD")
gen year_birth=year(date_birth)
replace year_birth=. if year_birth>2020 |year_birth<1920
hist year_birth, xtitle("Year of Birth")
graph export "$figdes\year_hist_userbirth.png", as(png) name("Graph")
restore

replace gender_id="NULL" if gender_id=="0"
replace maritalstatus="NULL" if maritalstatus=="RegCon"
replace maritalstatus="683" if maritalstatus=="683\'"

tabout gender_id maritalstatus profile_access using "$tabdes\user_freq1.tex", replace style(tex) oneway c(col cum) f(2 2 2) clab(Percent_% Cum._%) npos(col) nlab(Freq.)

*cursal expsal
count if cursal=="NULL"
count if expsal=="NULL"
replace cursal="" if cursal=="NULL"
replace expsal="" if expsal=="NULL"
destring cursal expsal, replace

est clear 
estpost tabstat cursal expsal, c(stat) stat(count mean median sd min max)

esttab using "$tabdes\user_salary_sum.tex", replace ////
  cells("count(fmt(%6.0fc)) Mean(fmt(%6.2fc)) p50(fmt(%6.0fc)) SD(fmt(%6.0fc)) Min Max")   nonumber ///
  nomtitle nonote noobs label booktabs       ///
  collabels("N" "Mean" "Median" "SD" "Min" "Max")  ///
  title("Summary Statistics of Current and Expected Salary  (Users)") ///
  posthead("\label{tab:usersalary}")


*created last_modified
gen datestr=substr(created, 1, 10)
gen date=date(datestr, "YMD")
format date %td
sort date

gen year=year(date)
set scheme plotplainblind

preserve
collapse (count) date, by(year)
format date %9.0g
drop if year==1970
twoway connected date year, xtitle("Year") ytitle("Num of User Profile Creation")
graph export "$figdes\year_distribution_user_creation.png", replace as(png) name("Graph")
restore

*experience
bys experience: egen num=count(experience)
replace experience="NULL" if num<11
replace experience="NULL" if experience=="LESS" | experience=="Less"

tabout experience using "$tabdes\user_freq2.tex", replace style(tex) oneway c(col cum) f(2 2 2) clab(Percent_% Cum._%) npos(col) nlab(Freq.)



*industry_id department_id

count if industry_id=="NULL" | industry_id==""
distinct industry_id
count if department_id=="NULL" | department_id==""
distinct department_id

**careerlevel_id

tabout careerlevel_id using "$tabdes\user_freq3.tex", replace style(tex) oneway c(col cum) f(2 2 2) clab(Percent_% Cum._%) npos(col) nlab(Freq.)


***************************
****user_languages_adb.csv**
***************************
import delimited "$input/Rozee/user_languages_adb.csv", clear varnames(1) bindquote(strict)

*N, uniqueID
distinct user_id lang_id, j
duplicates tag user_id lang_id, gen(tag)
sort user_id lang_id lang_level
bys user_id: drop if tag==1&lang_level<lang_level[_n+1]
duplicates drop user_id lang_id, force
drop tag


**Main variables
*lang_id
tabout lang_id using "$tabdes\user_freq4.tex", replace style(tex) oneway c(col cum) f(2 2 2) clab(Percent_% Cum._%) npos(col) nlab(Freq.)

bys user_id: egen num=count(user_id)

preserve
duplicates drop user_id, force
est clear 
estpost tabstat num, c(stat) stat(count mean median sd min max)

esttab using "$tabdes\user_langnum_sum.tex", replace ////
  cells("count(fmt(%6.0fc)) Mean(fmt(%6.2fc)) p50(fmt(%6.0fc)) SD(fmt(%6.2fc)) Min Max")   nonumber ///
  nomtitle nonote noobs label booktabs       ///
  collabels("N" "Mean" "Median" "SD" "Min" "Max")  ///
  title("Summary Statistics of Num. of Users' Languanges  (User)") ///
  posthead("\label{tab:userlangnum}")
 restore
 
 *lang_level
 tabout lang_level using "$tabdes\user_freq5.tex", replace style(tex) oneway c(col cum) f(2 2 2) clab(Percent_% Cum._%) npos(col) nlab(Freq.)
 
 bys user_id: egen lanmean=mean(lang_level)
duplicates drop user_id, force

hist lanmean, xtitle("Mean of Languange Proficiency for Each User")
graph export "$figdes\hist_lanmean_user.png", replace as(png) name("Graph")





***************************
****users_skills_adb.csv***
***************************
import delimited "$input/Rozee/users_skills_adb.csv", clear varnames(1) bindquote(strict)


*N, uniqueID
distinct user_id skill_id, j

**Main variables
*skill_id
bys user_id: egen num=count(user_id)

preserve
duplicates drop user_id, force
est clear 
estpost tabstat num, c(stat) stat(count mean median sd min max)

esttab using "$tabdes\user_skillnum_sum.tex", replace ////
  cells("count(fmt(%6.0fc)) Mean(fmt(%6.2fc)) p50(fmt(%6.0fc)) SD(fmt(%6.2fc)) Min Max")   nonumber ///
  nomtitle nonote noobs label booktabs       ///
  collabels("N" "Mean" "Median" "SD" "Min" "Max")  ///
  title("Summary Statistics of Num. of Users' Skills  (User)") ///
  posthead("\label{tab:userskillnum}")
 restore
 
 
 preserve
 bys skill_id: egen skillnum=count(skill_id)
 duplicates drop skill_id, force
 sort skillnum
 
 
 
 
 
 
 
 
 *level
 tabout level using "$tabdes\user_freq6.tex", replace style(tex) oneway c(col cum) f(2 2 2) clab(Percent_% Cum._%) npos(col) nlab(Freq.)
 
 replace level="" if level=="NULL"
 destring level, replace
 bys user_id: egen skillmean=mean(level)
duplicates drop user_id, force

hist skillmean, xtitle("Mean of Skill Proficiency for Each User")
graph export "$figdes\hist_skillmean_user.png", replace as(png) name("Graph")


***************************
****userEducation_adb.csv****
***************************

import delimited "$input/Rozee/userEducation_adb.csv", clear varnames(1) bindquote(strict)

*N, uniqueID
distinct user_id eduid
distinct educountryid educityid
count if educityid=="NULL"
count if educountryid=="NULL"
count if educountryid=="79"


**Main variables
*edulevel
tab edulevel

*degreeTypeID
distinct degreetypeid
count if degreetypeid=="NULL"
tabout degreetypeid using "$tabdes\user_freq7.tex", replace style(tex) oneway c(col cum) f(2 2 2) clab(Percent_% Cum._%) npos(col) nlab(Freq.)

* degreeMajorID /degreeMajorSub
count if degreemajorid=="NULL"

*highestdegreeid
distinct highestdegreeid
count if highestdegreeid=="NULL"

*eduyear createdon
replace eduyear="" if eduyear=="NULL"| eduyear=="${${" | eduyear=="0000" | eduyear=="-000" |eduyear=="In P"| eduyear=="Sele" | eduyear=="pres"
destring eduyear, replace
replace eduyear=. if eduyear>2035

hist eduyear, xtitle("Education Year")
graph export "$figdes\year_hist_user_education.png", replace as(png) name("Graph")

*edugradetype edugradeval edugradeoutof
count if edugradetype=="NULL" | edugradetype==""
count if edugradeval=="NULL" | edugradeval==""
count if edugradeoutof=="NULL" | edugradeoutof==""
replace edugradetype="" if edugradetype=="NULL"

*schoolname schooltype
count if schoolname=="" | schoolname=="NULL"
count if schooltype=="" | schooltype=="NULL"


tabout edugradetype schooltype using "$tabdes\user_freq8.tex", replace style(tex) oneway c(col cum) f(2 2 2) clab(Percent_% Cum._%) npos(col) nlab(Freq.)


***************************
****userExperience_adb.csv****
***************************
import delimited "$input/Rozee/userExperience_adb.csv", clear varnames(1) bindquote(strict)

*N, uniqueID
distinct user_id expid
distinct empcountryid empcityid
count if empcityid=="NULL"
count if empcountryid=="NULL"
count if empcountryid=="79"



**Main variables
*jobtitle
distinct jobtitle
count if jobtitle=="NULL" |jobtitle==""

*jobstart jobend
count if jobstart=="NULL" |jobstart==""
count if jobend=="NULL" | jobend==""
gen start=substr(jobstart, 1, 4)
replace start="" if start=="NULL"
destring start, replace force
replace start=. if start<1980 | start>2025
hist start, xtitle("Start Year of Job Experience")
graph export "$figdes\year_hist_user_experiencestart.png", replace as(png) name("Graph")

preserve
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
est clear 
estpost tabstat duration, c(stat) stat(count mean median min max)

esttab using "$tabdes\user_jobduration_sum.tex", replace ////
  cells("count(fmt(%8.0fc)) Mean(fmt(%6.2fc)) p50(fmt(%6.0fc)) Min Max")   nonumber ///
  nomtitle nonote noobs label booktabs       ///
  collabels("N" "Mean" "Median" "Min" "Max")  ///
  title("Summary Statistics of Past Job Duration  (User)") ///
  posthead("\label{tab:userjobduration}")
 restore



*manage_team
count if manage_team==""
tabout manage_team using "$tabdes\user_freq9.tex", replace style(tex) oneway c(col cum) f(2 2 2) clab(Percent_% Cum._%) npos(col) nlab(Freq.)


*jobcompanyid jobcompany
count if jobcompanyid=="NULL" | jobcompanyid==""
distinct jobcompanyid



