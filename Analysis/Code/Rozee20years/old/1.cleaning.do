
/*======================================================================*
 |  Project:    Rozee 
 |  Author:     AB
 | 	File: 		Cleaning and Merging Rozee20years Data
 |  Required:	Run 0_master.do before this file
 *======================================================================*/

********************************************
********************************************
**# Converting datasets
********************************************
********************************************

* Helper: convert a folder of CSVs to DTA
cap program drop convert_csv_folder
program define convert_csv_folder, rclass
    syntax , INPATH(string) OUTPATH(string)

    local csvs : dir "`inpath'" files "*.csv"
    foreach f of local csvs {
        local base = subinstr("`f'", ".csv", "", .)
        di as txt "-> Importing `inpath'/`f'"
        import delimited using "`inpath'/`f'", varnames(1) encoding("UTF-8") clear
        compress
        save "`outpath'/`base'.dta", replace
    }
end

* Convert main inputs
convert_csv_folder, inpath("$in")  outpath("$out")
convert_csv_folder, inpath("$in2") outpath("$out2")

di as result "All done. DTA files saved to:"
di as result "$out"
di as result "$out2"

********************************************
********************************************
**# Merging and compressing datasets
********************************************
********************************************

*----------------------------------------------
* Applications
* input: 	$out/applications x.dta
* output: 	$merged/applications.dta
*----------------------------------------------

* Start with file 1
use "$out/applications 1.dta", clear

* Append files 2..19
forvalues i = 2/19 {
    local f "$out/applications `i'.dta"
    di as txt "Appending `f'"
    capture noisily append using "`f'"
    if _rc {
        di as err "mismatch on `f' — retrying with force"
        capture noisily append using "`f'", force
    }
}

compress
save "$merged/applications.dta", replace
di as result "Saved master: $merged/applications.dta"

*---------------------------------------
* Users
* input: 	$out/users x.dta
* output: 	$merged/users.dta
*---------------------------------------

* Start with file 1
use "$out/users 1.dta", clear

* Append file 2
local f "$out/users 2.dta"
di as txt "Appending `f'"
capture noisily append using "`f'"
if _rc {
    di as err "mismatch on `f' — retrying with force"
    capture noisily append using "`f'", force
}

compress
save "$merged/users.dta", replace
di as result "Saved master: $merged/users.dta"

*---------------------------------------
* User Education
* input: 	$out/userEducation x.dta
* output: 	$merged/users_education.dta
*---------------------------------------

* Start with file 1
use "$out/userEducation 1.dta", clear

* Append files 2..3
forvalues i = 2/3 {
    local f "$out/userEducation `i'.dta"
    di as txt "Appending `f'"
    capture noisily append using "`f'"
    if _rc {
        di as err "mismatch on `f' — retrying with force"
        capture noisily append using "`f'", force
    }
}

compress
save "$merged/users_education.dta", replace

*----------------------------------------
* User Experience 
* input: 	$out/userExperience x.dta
* output: 	$merged/users_experience.dta
*----------------------------------------

* Start with file 1
use "$out/userExperience 1.dta", clear

* Append file 2
local f "$out/userExperience 2.dta"
di as txt "Appending `f'"
capture noisily append using "`f'"
if _rc {
    di as err "mismatch on `f' — retrying with force"
    capture noisily append using "`f'", force
}

compress
save "$merged/users_experience.dta", replace

*---------------------------------------
* Compress non-merged files
* input: 	$out/
* output: 	$merged/
*---------------------------------------

local srcs "apply_job_quick_answers.dta apply_job_quick_questions.dta companyInfo.dta deleted_jobs.dta jobs.dta user_languages.dta user_skills.dta"
local dsts "jobs_answers.dta jobs_questions.dta companies.dta jobs_deleted.dta jobs.dta users_languages.dta users_skills.dta"

local n : word count `srcs'
forvalues i = 1/`n' {
    local src : word `i' of `srcs'
    local dst : word `i' of `dsts'
    use "$out/`src'", clear
    compress
    save "$merged/`dst'", replace
}

********************************************
********************************************
**# Cleaning and destringing variables
********************************************
********************************************

*---------------------------------------
* Users
* input: 	$merged/users.dta
* output: 	$merged/temp/users_temp.dta
*---------------------------------------

*--- Load
use "$merged/users.dta", clear

*--- Clean key string IDs and salaries
foreach v in gender_id maritalstatus industry_id careerlevel_id country_id city_id cursal expsal {
    replace `v' = trim(`v')
    replace `v' = "" if inlist(upper(`v'),"NULL",".","NA","N/A","NONE","MISSING")
}

foreach v in gender_id maritalstatus industry_id careerlevel_id {
    replace `v' = "" if `v'=="0"
}

*--- Numeric copies
destring gender_id       , gen(gender_id_num)       force
destring maritalstatus   , gen(maritalstatus_num)   force
destring industry_id     , gen(industry_id_num)     force
destring careerlevel_id  , gen(careerlevel_id_num)  force
destring country_id      , gen(country_id_num)      force
destring city_id         , gen(city_id_num)         force
destring cursal          , gen(cursal_pkr)          force
destring expsal          , gen(expsal_pkr)          force

*--- DOB to age
gen double 	dobirth_d = daily(dobirth,"YMD")
format 		dobirth_d %td
gen int 	age = floor((d(01jan2025) - dobirth_d)/365.25)
replace 	age = . if missing(dobirth_d) | age<14 | age>90

*--- Experience to years
gen str20 	experience_clean = upper(trim(experience))
replace 	experience_clean = subinstr(experience_clean," YEARS","",.)
replace 	experience_clean = "0" if experience_clean=="FRESH"
destring 	experience_clean, gen(exp_years) force
drop 		experience_clean

*--- Map from meta_info.dta (vars: id, type, name)
* Industry
preserve
    use "$merged/data-dict/meta_info.dta", clear
    keep if type=="Industry"
    keep id name
    rename id   industry_id_num
    rename name industry_str
    tempfile m_ind
    save "`m_ind'"
restore
merge m:1 industry_id_num using "`m_ind'", nogenerate

* MaritalStatus
preserve
    use "$merged/data-dict/meta_info.dta", clear
    keep if type=="MaritalStatus"
    keep id name
    rename id   maritalstatus_num
    rename name maritalstatus_str
    tempfile m_mar
    save "`m_mar'"
restore
merge m:1 maritalstatus_num using "`m_mar'", nogenerate

* Gender
preserve
    use "$merged/data-dict/meta_info.dta", clear
    keep if type=="Gender"
    keep id name
    rename id   gender_id_num
    rename name gender_str
    tempfile m_gen
    save "`m_gen'"
restore
merge m:1 gender_id_num using "`m_gen'", nogenerate

* CareerLevel
preserve
    use "$merged/data-dict/meta_info.dta", clear
    keep if type=="CareerLevel"
    keep id name
    rename id   careerlevel_id_num
    rename name careerlevel_str
    tempfile m_car
    save "`m_car'"
restore
merge m:1 careerlevel_id_num using "`m_car'", nogenerate

*--- Countries: country_id to country_name
preserve
    use "$merged/data-dict/countries.dta", clear
    keep country_id country_name
    rename country_id  country_id_num
    tempfile m_cty
    save "`m_cty'"
restore
merge m:1 country_id_num using "`m_cty'", nogenerate

*--- Cities: city_id to cityy_name
preserve
    use "$merged/data-dict/cities.dta", clear
    keep city_id cityy_name
    rename city_id     city_id_num
    rename cityy_name  city_name
    tempfile m_city
    save "`m_city'"
restore
merge m:1 city_id_num using "`m_city'", nogenerate

*--- Buckets + salary gap
gen byte 	age_bucket = .
replace 	age_bucket = 1 if inrange(age,18,24)
replace 	age_bucket = 2 if inrange(age,25,34)
replace 	age_bucket = 3 if inrange(age,35,44)
replace 	age_bucket = 4 if inrange(age,45,54)
replace 	age_bucket = 5 if age>=55 & age<.

label define lageb 1 "18–24" 2 "25–34" 3 "35–44" 4 "45–54" 5 "55+"
label values age_bucket lageb

gen byte 	exp_bucket = .
replace 	exp_bucket = 0 if exp_years==0
replace 	exp_bucket = 1 if inrange(exp_years,1,2)
replace 	exp_bucket = 2 if inrange(exp_years,3,5)
replace 	exp_bucket = 3 if inrange(exp_years,6,9)
replace 	exp_bucket = 4 if exp_years>=10 & exp_years<.

label define lexpb 0 "0 (Fresh)" 1 "1–2" 2 "3–5" 3 "6–9" 4 "10+"
label values exp_bucket lexpb

gen double sal_gap = expsal_pkr - cursal_pkr if !missing(expsal_pkr,cursal_pkr)

*--------- Ordering -------------
ds
local allvars `r(varlist)'

* Created vars
local created ///
    gender_id_num maritalstatus_num industry_id_num careerlevel_id_num ///
    country_id_num city_id_num cursal_pkr expsal_pkr ///
    dobirth_d age exp_years ///
    industry_str maritalstatus_str gender_str careerlevel_str ///
    country_name city_name ///
    age_bucket exp_bucket sal_gap

* Original vars
local origvars : list allvars - created

* Order
cap drop 	_RAW_____________ _CREATED_________
gen 		_RAW_____________ = .
gen 		_CREATED_________ = .

order 		_RAW_____________ `origvars' _CREATED_________ `created'

save "$merged/temp/users_temp.dta", replace

*--------- PKR-at-creation -> 2024 USD (PPP) -------------

use "$merged/temp/users_temp.dta", clear
 
* Convert to Stata datetime (%tc)
cap gen double user_created_dt = clock(created, "YMDhms")
format user_created_dt %tc

* Extract year
cap gen user_created_yr = yofd(dofc(user_created_dt))
tab user_created_yr, m

* PPP lookup (PAK & USA), 2004–2024
cap frame drop ppp
cap frame create ppp
frame change  ppp

* Pull PPP (LCU per international $) for all, then keep PAK/USA
wbopendata, indicator("PA.NUS.PPP") clear
keep countrycode yr2004-yr2024
keep if inlist(countrycode,"PAK","USA")

* wide -> long -> side-by-side
reshape long yr, i(countrycode) j(year)
rename yr ppp_lcu_per_intdol

reshape wide ppp_lcu_per_intdol, i(year) j(countrycode) string
rename ppp_lcu_per_intdolPAK ppp_pak_lcu_per_intdol   // PKR per int$
rename ppp_lcu_per_intdolUSA ppp_usa_usd_per_intdol   // USD per int$

* Align key name with main data
rename year user_created_yr

frame change default

cap program drop pppconvert
program define pppconvert
    version 18
    syntax varname(numeric) , YEARvar(name) GENerate(name)

    tempvar _lnk
    frlink m:1 `yearvar', frame(ppp) generate(`_lnk')
    frget  ppp_pak_lcu_per_intdol, from(`_lnk')

    frame ppp: quietly summarize ppp_usa_usd_per_intdol if user_created_yr==2024
    scalar PPP_US_2024 = r(mean)

    gen double `generate' = .
    replace   `generate' = (`varlist' / ppp_pak_lcu_per_intdol) * PPP_US_2024 ///
        if inrange(`yearvar',2004,2024)

    label var `generate' "2024 USD (PPP) from `varlist'"
    drop `_lnk' ppp_pak_lcu_per_intdol
end

* Apply to salaries
pppconvert expsal_pkr, yearvar(user_created_yr) generate(expsal_usd_ppp)
pppconvert cursal_pkr, yearvar(user_created_yr) generate(cursal_usd_ppp)


save "$merged/temp/users_temp.dta", replace

* Checks
tabstat cursal_usd_ppp if user_created_yr > 2000, statistics(n me sem p10 q p90)
tabstat expsal_usd_ppp if user_created_yr > 2000, statistics(n me sem p10 q p90)

*--------- Labels for created variables -------------
cap label var gender_id_num        "Gender ID (numeric)"
cap label var maritalstatus_num    "Marital status ID (numeric)"
cap label var industry_id_num      "Industry ID (numeric)"
cap label var careerlevel_id_num   "Career level ID (numeric)"
cap label var country_id_num       "Country ID (numeric)"
cap label var city_id_num          "City ID (numeric)"

cap label var cursal_pkr           "Current salary (PKR)"
cap label var expsal_pkr           "Expected salary (PKR)"
cap label var sal_gap              "Expected – current salary (PKR)"

cap label var dobirth_d            "Date of birth"
cap label var age                  "Age (years; trimmed 14–90)"
cap label var exp_years            "Years of experience"

cap label var industry_str         "Industry (string label)"
cap label var maritalstatus_str    "Marital status (string label)"
cap label var gender_str           "Gender (string label)"
cap label var careerlevel_str      "Career level (string label)"
cap label var country_name         "Country name"
cap label var city_name            "City name"

cap label var age_bucket           "Age bucket"
cap label var exp_bucket           "Experience bucket"

cap label var user_created_dt      "User created datetime (%tc from 'created')"
cap label var user_created_yr      "User created year"

cap label var expsal_usd_ppp       "2024 USD (PPP) from expsal_pkr"
cap label var cursal_usd_ppp       "2024 USD (PPP) from cursal_pkr"

save "$merged/temp/users_temp.dta", replace

*---------------------------------------
* Applications
* input: 	$merged/applications.dta
* output: 	$merged/temp/applications_temp.dta
*---------------------------------------

*--- Load
use "$merged/applications.dta", clear

*--- Clean key string fields (IDs, statuses, salaries, dates)
foreach v in emp_status test_code test_status currentsalary expectedsalary {
    replace `v' = trim(`v')
    replace `v' = "" if inlist(upper(`v'),"NULL",".","NA","N/A","NONE","MISSING")
}

*--- Numeric copies
destring currentsalary   , gen(cursal_pkr_app)  force
destring expectedsalary  , gen(expsal_pkr_app)  force

*--- Application datetime
gen double app_dt = clock(apply_date,"YMDhms")
format app_dt %tc
gen app_d  = dofc(app_dt)
format app_d %td
gen int app_yr = yofd(app_d)
gen byte app_mo = month(app_d)

*--- Salary gap at application
gen double sal_gap_app_pkr = expsal_pkr_app - cursal_pkr_app if !missing(expsal_pkr_app, cursal_pkr_app)

*--------- Ordering -------------
* Created vars
local created ///
    cursal_pkr_app expsal_pkr_app sal_gap_app_pkr ///
    app_dt app_d app_yr app_mo

* Order
cap drop _RAW_____________ _CREATED_________
cap gen _RAW_____________ = .
cap gen _CREATED_________ = .

order _RAW_____________ app_id user_id jid company_id apply_date emp_status test_code test_status currentsalary expectedsalary _CREATED_________ `created'

save "$merged/temp/applications_temp.dta", replace

*--------- PKR-at-application -> 2024 USD (PPP) -------------
use "$merged/temp/applications_temp.dta", clear

* Ensure PPP frame key name matches
frame ppp: cap gen app_yr = user_created_yr

* Apply to salaries
pppconvert expsal_pkr_app, yearvar(apply_yr) generate(expsal_usd_ppp_app)
pppconvert cursal_pkr_app, yearvar(apply_yr) generate(cursal_usd_ppp_app)

* Optional USD gap
gen double sal_gap_app_usd_ppp = expsal_usd_ppp_app - cursal_usd_ppp_app if !missing(expsal_usd_ppp_app, cursal_usd_ppp_app)

*--------- Labels for created variables -------------
cap label var user_id_num            "User ID (numeric)"
cap label var jid_num                "Job ID (numeric)"
cap label var company_id_num         "Company ID (numeric)"

cap label var cursal_pkr_app         "Current salary at application (PKR)"
cap label var expsal_pkr_app         "Expected salary at application (PKR)"
cap label var sal_gap_app_pkr        "Expected − current salary at application (PKR)"

cap label var apply_dt               "Application datetime (%tc)"
cap label var apply_d                "Application date (%td)"
cap label var apply_yr               "Application year"
cap label var apply_mo               "Application month (1–12)"

cap label var expsal_usd_ppp_app     "2024 USD (PPP) from expected salary at application"
cap label var cursal_usd_ppp_app     "2024 USD (PPP) from current salary at application"
cap label var sal_gap_app_usd_ppp    "Expected − current salary at application (2024 USD, PPP)"

save "$merged/temp/applications_temp.dta", replace

*-----------------------------------------
* Companies
* input: 	$merged/companies.dta
* output: 	$merged/temp/companies_temp.dta
*-----------------------------------------

*--- Load
use "$merged/companies.dta", clear

*--- Clean key string fields (IDs, counts, statuses, dates, text)
foreach v in company_name company_detail city_id country_id no_of_employee ///
            operating_since created industry_id ppsp companyowntype ///
            contact_name contact_designation nooffices origincompany ///
            company_status company_address {
    replace `v' = trim(`v')
    replace `v' = "" if inlist(upper(`v'),"NULL",".","NA","N/A","NONE","MISSING")
}

*--- Numeric copies (IDs, counts)
destring city_id     , gen(city_id_num)     force
destring country_id  , gen(country_id_num)  force
destring industry_id , gen(industry_id_num) force
destring nooffices   , gen(nooffices_num)   force

*--- Employee band parsing (no_of_employee)
gen str40 emp_s = upper(trim(no_of_employee))
replace emp_s = subinstr(emp_s, ",", "", .)

gen double emp_min = .
gen double emp_max = .

* range "A-B"
replace emp_min = real(regexs(1)) if regexm(emp_s, "^[ ]*([0-9]+)[ ]*-[ ]*([0-9]+)[ ]*$")
replace emp_max = real(regexs(2)) if regexm(emp_s, "^[ ]*([0-9]+)[ ]*-[ ]*([0-9]+)[ ]*$")

* trailing plus "N+"
replace emp_min = real(regexs(1)) if missing(emp_min) & regexm(emp_s, "^[ ]*([0-9]+)[ ]*\+$")
replace emp_max = .                if regexm(emp_s, "^[ ]*([0-9]+)[ ]*\+$")

* single number "N"
replace emp_min = real(regexs(1)) if missing(emp_min) & regexm(emp_s, "^[ ]*([0-9]+)[ ]*$")
replace emp_max = emp_min         if missing(emp_max) & !missing(emp_min) & regexm(emp_s, "^[ ]*([0-9]+)[ ]*$")

* midpoint (when both present)
gen double emp_mid = (emp_min + emp_max)/2 if emp_min<. & emp_max<.

* convenient labeled bucket
gen byte emp_bucket = .
replace emp_bucket = 1 if emp_min>=1    & (emp_max<=10   | emp_max==.)
replace emp_bucket = 2 if emp_min>=11   & emp_max<=50
replace emp_bucket = 3 if emp_min>=51   & emp_max<=100
replace emp_bucket = 4 if emp_min>=101  & emp_max<=500
replace emp_bucket = 5 if emp_min>=501  & emp_max<=1000
replace emp_bucket = 6 if emp_min>=1001 & emp_max<=5000
replace emp_bucket = 7 if emp_min>=5001 & emp_max==.
label define lemp 1 "1–10" 2 "11–50" 3 "51–100" 4 "101–500" 5 "501–1000" 6 "1001–5000" 7 "5000+"
label values emp_bucket lemp
drop emp_s emp_max emp_min emp_mid

*--- Created datetime
gen double created_dt = clock(created,"YMDhms")
format created_dt %tc
gen created_d = dofc(created_dt)
format created_d %td
gen int  created_yr = yofd(created_d)
gen byte created_mo = month(created_d)

*--- Operating-since (extract 4-digit year from strings)
gen int opsince_yr = .
replace opsince_yr = real(regexs(1)) if regexm(operating_since, "([12][0-9]{3})")
replace opsince_yr = . if opsince_yr<1900 | opsince_yr>2025

* age as of 2025
gen int company_age = 2025 - opsince_yr if opsince_yr<.

*--- Dictionary joins (industry, countries, cities)
* Industry
preserve
    use "$merged/data-dict/meta_info.dta", clear
    keep if type=="Industry"
    keep id name
    rename id   industry_id_num
    rename name industry_str
    tempfile m_ind
    save "`m_ind'"
restore
merge m:1 industry_id_num using "`m_ind'", nogenerate

* Countries
preserve
    use "$merged/data-dict/countries.dta", clear
    keep country_id country_name
    rename country_id country_id_num
    tempfile m_cty
    save "`m_cty'"
restore
merge m:1 country_id_num using "`m_cty'", nogenerate

* Cities
preserve
    use "$merged/data-dict/cities.dta", clear
    keep city_id cityy_name
    rename city_id    city_id_num
    rename cityy_name city_name
    tempfile m_city
    save "`m_city'"
restore
merge m:1 city_id_num using "`m_city'", nogenerate

*--------- Ordering -------------
ds
local allvars `r(varlist)'

* Created vars
local created ///
    city_id_num country_id_num industry_id_num nooffices_num ///
    emp_bucket ///
    created_dt created_d created_yr created_mo ///
    opsince_yr company_age ///
    industry_str country_name city_name

* Original vars
local origvars : list allvars - created

* Order
cap drop _RAW_____________ _CREATED_________
gen _RAW_____________ = .
gen _CREATED_________ = .

order _RAW_____________ `origvars' _CREATED_________ `created'

*--------- Labels for created variables -------------
cap label var city_id_num          "City ID (numeric)"
cap label var country_id_num       "Country ID (numeric)"
cap label var industry_id_num      "Industry ID (numeric)"
cap label var nooffices_num        "Number of offices (numeric)"

cap label var emp_bucket           "Number of employees (buckets)"

cap label var created_dt           "Record created datetime (%tc)"
cap label var created_d            "Record created date (%td)"
cap label var created_yr           "Record created year"
cap label var created_mo           "Record created month (1–12)"

cap label var opsince_yr           "Operating since (year)"
cap label var company_age	       "Company age in 2025 (years)"

cap label var industry_str         "Industry (string label)"
cap label var country_name         "Country name"
cap label var city_name            "City name"

compress
save "$merged/temp/companies_temp.dta", replace

*---------------------------------------
* Jobs
* input: 	$merged/jobs.dta
* output: 	$merged/temp/jobs_temp.dta
*---------------------------------------

*--- Load
use "$merged/jobs.dta", clear

*--- Clean strings
foreach v in title job_type_id job_shift_id genderid city_id area_id country_id ///
            req_experience max_experience salary_range_from salary_range_to ///
            salary_range_from_hide salary_range_to_hide currency_unit ///
            created displaydate applyby deactivateafterapplyby ///
            industry_id department_id min_education max_education_id ///
            careerlevelid jobpackage isfeatured istopjob ispremiumjob ///
            applyjobquestion tb_id tb_require description ///
            filter_gender filter_experience filter_degree filter_age filter_city {
    replace `v' = trim(`v')
    replace `v' = "" if inlist(upper(`v'),"NULL",".","NA","N/A","NONE","MISSING")
}

*--- Numeric copies (IDs and counts; jid and company_id already numeric)
destring job_type_id        , gen(job_type_id_num)        force
destring job_shift_id       , gen(job_shift_id_num)       force
destring genderid           , gen(genderid_num)           force
destring city_id            , gen(city_id_num)            force
destring area_id            , gen(area_id_num)            force
destring country_id         , gen(country_id_num)         force
destring industry_id        , gen(industry_id_num)        force
destring department_id      , gen(department_id_num)      force
destring min_education      , gen(min_education_num)      force
destring max_education_id   , gen(max_education_id_num)   force
destring careerlevelid      , gen(careerlevelid_num)      force
destring tb_id              , gen(tb_id_num)              force
destring totalpositions     , replace                      force

*--- Salary fields (PKR)
destring salary_range_from       , gen(sal_from_pkr)        force
destring salary_range_to         , gen(sal_to_pkr)          force
destring salary_range_from_hide  , gen(sal_from_hide_pkr)   force
destring salary_range_to_hide    , gen(sal_to_hide_pkr)     force

*--- Datetimes and date parts
gen double created_dt  = clock(created,"YMDhms")
format created_dt %tc
gen created_d   = dofc(created_dt)
format created_d %td
gen int  created_yr = yofd(created_d)
gen byte created_mo = month(created_d)

gen double display_dt = clock(displaydate,"YMDhms")
format display_dt %tc
gen display_d  = dofc(display_dt)
format display_d %td

gen double applyby_dt  = clock(applyby,"YMDhms")
format applyby_dt %tc
gen applyby_d   = dofc(applyby_dt)
format applyby_d %td

*--- Deactivate-after-applyby flag
gen byte deact_applyby = (upper(deactivateafterapplyby)=="Y")

*--- Experience years
gen str30 _req = lower(trim(req_experience))
gen str30 _max = lower(trim(max_experience))

gen double req_exp_yrs = .
replace req_exp_yrs = 0    if inlist(_req,"fresh","less than 1 year")
replace req_exp_yrs = real(regexs(1)) if regexm(_req,"^([0-9]+)")
replace req_exp_yrs = .    if _req=="not required"

gen double max_exp_yrs = .
replace max_exp_yrs = 0    if inlist(_max,"fresh","less than 1 year")
replace max_exp_yrs = real(regexs(1)) if regexm(_max,"^([0-9]+)")
replace max_exp_yrs = .    if _max=="not required"

drop _req _max

*--- Age
destring min_age , gen(min_age_num) force
destring max_age , gen(max_age_num) force

*--- Flags (Y/N → 1/0)
gen byte is_featured           = (upper(isfeatured)=="Y")
gen byte is_topjob             = (upper(istopjob)=="Y")
gen byte is_premiumjob         = (upper(ispremiumjob)=="Y")
gen byte has_applyby_questions = (upper(applyjobquestion)=="Y")

gen byte filter_gender_flag     = (upper(filter_gender)=="Y")
gen byte filter_experience_flag = (upper(filter_experience)=="Y")
gen byte filter_degree_flag     = (upper(filter_degree)=="Y")
gen byte filter_age_flag        = (upper(filter_age)=="Y")
gen byte filter_city_flag       = (upper(filter_city)=="Y")

*--- Currency
cap drop currency_str
gen str15 currency_str = upper(trim(currency_unit))
replace currency_str = subinstr(currency_str,"  "," ",.)   // collapse doubles

* Map variants and numeric codes
replace currency_str = "PKR" if inlist(currency_str,"PAKISTANI RUPEE","PKR","2855")
replace currency_str = "USD" if inlist(currency_str,"USD","447")

*--- Dictionary joins (industry, gender, career level; plus country/city)
* Industry
preserve
    use "$merged/data-dict/meta_info.dta", clear
    keep if type=="Industry"
    keep id name
    rename id   industry_id_num
    rename name industry_str
    tempfile m_ind
    save "`m_ind'"
restore
merge m:1 industry_id_num using "`m_ind'", nogenerate

* Gender
preserve
    use "$merged/data-dict/meta_info.dta", clear
    keep if type=="Gender"
    keep id name
    rename id   genderid_num
    rename name gender_str
    tempfile m_gen
    save "`m_gen'"
restore
merge m:1 genderid_num using "`m_gen'", nogenerate

* CareerLevel
preserve
    use "$merged/data-dict/meta_info.dta", clear
    keep if type=="CareerLevel"
    keep id name
    rename id   careerlevelid_num
    rename name careerlevel_str
    tempfile m_car
    save "`m_car'"
restore
merge m:1 careerlevelid_num using "`m_car'", nogenerate

* Countries
preserve
    use "$merged/data-dict/countries.dta", clear
    keep country_id country_name
    rename country_id country_id_num
    tempfile m_cty
    save "`m_cty'"
restore
merge m:1 country_id_num using "`m_cty'", nogenerate

* Cities
preserve
    use "$merged/data-dict/cities.dta", clear
    keep city_id cityy_name
    rename city_id    city_id_num
    rename cityy_name city_name
    tempfile m_city
    save "`m_city'"
restore
merge m:1 city_id_num using "`m_city'", nogenerate

*--------- Ordering -------------
ds
local allvars `r(varlist)'

* Created vars
local created ///
    job_type_id_num job_shift_id_num genderid_num city_id_num area_id_num country_id_num ///
    industry_id_num department_id_num min_education_num max_education_id_num careerlevelid_num tb_id_num ///
    sal_from_pkr sal_to_pkr sal_from_hide_pkr sal_to_hide_pkr ///
    created_dt created_d created_yr created_mo display_dt display_d applyby_dt applyby_d ///
    deact_applyby req_exp_yrs max_exp_yrs min_age_num max_age_num ///
    is_featured is_topjob is_premiumjob has_applyby_questions ///
    filter_gender_flag filter_experience_flag filter_degree_flag filter_age_flag filter_city_flag ///
    currency_str industry_str gender_str careerlevel_str country_name city_name

* Original vars
local origvars : list allvars - created

* Order
cap drop _RAW_____________ _CREATED_________
gen _RAW_____________ = .
gen _CREATED_________ = .

order _RAW_____________ `origvars' _CREATED_________ `created'

*--------- Labels -------------
cap label var job_type_id_num          "Job type ID (numeric)"
cap label var job_shift_id_num         "Job shift ID (numeric)"
cap label var genderid_num             "Target gender ID (numeric)"
cap label var city_id_num              "City ID (numeric)"
cap label var area_id_num              "Area ID (numeric)"
cap label var country_id_num           "Country ID (numeric)"
cap label var industry_id_num          "Industry ID (numeric)"
cap label var department_id_num        "Department ID (numeric)"
cap label var min_education_num        "Min education ID (numeric)"
cap label var max_education_id_num     "Max education ID (numeric)"
cap label var careerlevelid_num        "Career level ID (numeric)"
cap label var tb_id_num                "TB ID (numeric)"

cap label var sal_from_pkr             "Salary range from (PKR)"
cap label var sal_to_pkr               "Salary range to (PKR)"
cap label var sal_from_hide_pkr        "Salary range from (hidden, PKR)"
cap label var sal_to_hide_pkr          "Salary range to (hidden, PKR)"

cap label var created_dt               "Job created datetime (%tc)"
cap label var created_d                "Job created date (%td)"
cap label var created_yr               "Job created year"
cap label var created_mo               "Job created month (1–12)"
cap label var display_dt               "Display datetime (%tc)"
cap label var display_d                "Display date (%td)"
cap label var applyby_dt               "Apply-by datetime (%tc)"
cap label var applyby_d                "Apply-by date (%td)"

cap label var deact_applyby            "Deactivate after apply-by (1/0)"

cap label var req_exp_yrs              "Required experience (years)"
cap label var max_exp_yrs              "Maximum experience (years)"
cap label var min_age_num              "Minimum age (years)"
cap label var max_age_num              "Maximum age (years)"

cap label var is_featured              "Featured job (1/0)"
cap label var is_topjob                "Top job (1/0)"
cap label var is_premiumjob            "Premium job (1/0)"
cap label var has_applyby_questions    "Requires apply-by questions (1/0)"

cap label var filter_gender_flag       "Filter gender active (1/0)"
cap label var filter_experience_flag   "Filter experience active (1/0)"
cap label var filter_degree_flag       "Filter degree active (1/0)"
cap label var filter_age_flag          "Filter age active (1/0)"
cap label var filter_city_flag         "Filter city active (1/0)"

cap label var currency_str             "Currency (normalized)"
cap label var industry_str             "Industry (string label)"
cap label var gender_str               "Target gender (string label)"
cap label var careerlevel_str          "Career level (string label)"
cap label var country_name             "Country name"
cap label var city_name                "City name"

compress
save "$merged/temp/jobs_temp.dta", replace

use "$merged/temp/jobs_temp.dta", clear















