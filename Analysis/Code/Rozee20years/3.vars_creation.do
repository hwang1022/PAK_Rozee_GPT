
/*======================================================================*
 |  Project:    Rozee 
 |  Author:     AB
 |  File:       Creating variables for cleaned Rozee20years data
 |  Required:   Run 1.creation.do and 2.cleaning.do before this file
 *======================================================================*/
 
************************************************
************************************************
**# USERS
************************************************
************************************************

*--- Load ----------------------------------------------------

	use "$proc/users_proc.dta", clear

*--- DOB to age ----------------------------------------------------

	gen double 	dobirth_d = daily(dobirth,"YMD")
	format 		dobirth_d %td
	gen int 	age = floor((d(01jan2025) - dobirth_d)/365.25)
	replace 	age = . if missing(dobirth_d) | age<14 | age>90

*--- Exact years of experience -------------------------------------------------

	gen double exp_exact = .
	replace exp_exact = real(ustrregexs(1)) if ///
		ustrregexm(experience, "^\s*([0-9]+)\s*$")

*--- Dictionary map from meta_info.dta (vars: id, type, name) ------------------

	* Industry
	preserve
		use "$dict/meta_info.dta", clear
		keep if type=="Industry"
		keep id name
		rename id   industry_id_num
		rename name industry_str
		tempfile m_ind
		save "`m_ind'"
	restore
	merge m:1 industry_id_num using "`m_ind'", keep(1 3) nogen

	* MaritalStatus
	preserve
		use "$dict/meta_info.dta", clear
		keep if type=="MaritalStatus"
		keep id name
		rename id   maritalstatus_num
		rename name maritalstatus_str
		tempfile m_mar
		save "`m_mar'"
	restore
	merge m:1 maritalstatus_num using "`m_mar'", keep(1 3) nogen

	* Gender
	preserve
		use "$dict/meta_info.dta", clear
		keep if type=="Gender"
		keep id name
		rename id   gender_id_num
		rename name gender_str
		tempfile m_gen
		save "`m_gen'"
	restore
	merge m:1 gender_id_num using "`m_gen'", keep(1 3) nogen

	* CareerLevel
	preserve
		use "$dict/meta_info.dta", clear
		keep if type=="CareerLevel"
		keep id name
		rename id   careerlevel_id_num
		rename name careerlevel_str
		tempfile m_car
		save "`m_car'"
	restore
	merge m:1 careerlevel_id_num using "`m_car'", keep(1 3) nogen

*--- Countries: country_id to country_name ------------------------------------

	preserve
		use "$dict/countries.dta", clear
		keep country_id country_name
		rename country_id  country_id_num
		tempfile m_cty
		save "`m_cty'"
	restore
	merge m:1 country_id_num using "`m_cty'", keep(1 3) nogen

*--- Cities: city_id to cityy_name ------------------------------------------

	preserve
		use "$dict/cities.dta", clear
		keep city_id cityy_name
		rename city_id     city_id_num
		rename cityy_name  city_name
		tempfile m_city
		save "`m_city'"
	restore
	merge m:1 city_id_num using "`m_city'", keep(1 3) nogen

*--- Buckets + salary gap ----------------------------------------------------

	gen byte 	age_bucket = .
	replace 	age_bucket = 1 if inrange(age,18,24)
	replace 	age_bucket = 2 if inrange(age,25,34)
	replace 	age_bucket = 3 if inrange(age,35,44)
	replace 	age_bucket = 4 if inrange(age,45,54)
	replace 	age_bucket = 5 if age>=55 & age<.

	label define lageb 1 "18–24" 2 "25–34" 3 "35–44" 4 "45–54" 5 "55+"
	label values age_bucket lageb

	gen byte 	exp_bucket = .
	replace 	exp_bucket = 0 if exp_exact==0
	replace 	exp_bucket = 1 if inrange(exp_exact,1,2)
	replace 	exp_bucket = 2 if inrange(exp_exact,3,5)
	replace 	exp_bucket = 3 if inrange(exp_exact,6,9)
	replace 	exp_bucket = 4 if exp_exact>=10 & exp_exact<.

	label define lexpb 0 "0 (Fresh)" 1 "1–2" 2 "3–5" 3 "6–9" 4 "10+"
	label values exp_bucket lexpb

	gen double 	sal_gap = expsal_pkr - cursal_pkr if !missing(expsal_pkr,cursal_pkr)

	* Convert to Stata datetime (%tc)
	gen double 	user_created_dt = clock(created, "YMDhms")
	format 		user_created_dt %tc

	* Extract year
	gen 		user_created_yr = yofd(dofc(user_created_dt))
	tab 		user_created_yr, m

*--- PKR to USD PPP conversion ----------------------------------

	frame create ppp
	frame change  ppp

	wbopendata, indicator("PA.NUS.PPP") clear
	keep countrycode yr2004-yr2024
	keep if inlist(countrycode,"PAK","USA")

	reshape long yr, i(countrycode) j(year)
	rename yr ppp_lcu_per_intdol

	reshape wide ppp_lcu_per_intdol, i(year) j(countrycode) string
	rename ppp_lcu_per_intdolPAK ppp_pak_lcu_per_intdol   // PKR per int$
	rename ppp_lcu_per_intdolUSA ppp_usa_usd_per_intdol   // USD per int$

	rename year user_created_yr
	frame change default

	* Apply to salaries
	pppconvert expsal_pkr, yearvar(user_created_yr) generate(expsal_usd_ppp)
	pppconvert cursal_pkr, yearvar(user_created_yr) generate(cursal_usd_ppp)

	* Checks
	tabstat cursal_usd_ppp if user_created_yr > 2000, statistics(n me sem p10 q p90)
	tabstat expsal_usd_ppp if user_created_yr > 2000, statistics(n me sem p10 q p90)

	
*--- Languages -------------------------------------------------------------

	local K 20

	preserve
		use "$proc/users_languages_proc.dta", clear
		keep user_id lang_id lang_level
		drop if missing(user_id) | missing(lang_id)

		// if same language repeats for a user, keep the highest level
		bysort user_id lang_id: egen _maxlvl = max(lang_level)
		keep if lang_level == _maxlvl
		bysort user_id lang_id (lang_level): keep if _n == _N
		drop _maxlvl

		// rank languages per user: highest level first, then by lang_id
		gsort user_id -lang_level lang_id
		by user_id: gen byte lang_rank = _n

		// keep only top K and reshape wide
		keep if lang_rank <= `K'
		reshape wide lang_id lang_level, i(user_id) j(lang_rank)

		// rename to lang1_id/lang1_level ... lang20_id/lang20_level
		forvalues i = 1/`K' {
			capture rename lang_id`i'    lang`i'_id
			capture rename lang_level`i' lang`i'_level
		}

		tempfile m_langwide
		save "`m_langwide'"
	restore

	merge m:1 user_id using "`m_langwide'", keep(1 3) nogen

	// compute language count after reshape (non-missing ID slots)
	local J = `K'-1
	local langvars
	forvalues i = 1/`J' {
		local langvars `langvars' lang`i'_id
	}
	egen lang_count = rownonmiss(`langvars')

	// labels
	forvalues i = 1/`J' {
		label var lang`i'_id     "Language `i' ID (numeric)"
		label var lang`i'_level  "Language `i' proficiency level (numeric)"
	}
	
	// keep top 5 languages for id and level
	forvalues i = 6/19{
		drop lang`i'_id
		drop lang`i'_level
	}

*--- Skills: counts by level (0–3) and merge ---------------------------------

	preserve
		use "$proc/users_skills_proc.dta", clear
		keep user_id skill_level_num
		drop if missing(user_id) | missing(skill_level_num)
		keep if inrange(skill_level_num,0,3)

		* counts per user × level
		contract user_id skill_level_num
		rename _freq n

		reshape wide n, i(user_id) j(skill_level_num)

		* ensure all four level columns exist; fill missing with 0
		foreach L of numlist 0/3 {
			capture confirm variable n`L'
			if _rc gen n`L' = 0
		}

		* rename for clarity
		rename n0 skill_lvl0_n
		rename n1 skill_lvl1_n
		rename n2 skill_lvl2_n
		rename n3 skill_lvl3_n

		tempfile m_skillcounts
		save "`m_skillcounts'"
	restore

	merge m:1 user_id using "`m_skillcounts'", keep(1 3) nogen

*--------- Order and labels ----------------------------------------------------

	ds
	local allvars `r(varlist)'
	local created ///
		gender_id_num maritalstatus_num industry_id_num careerlevel_id_num ///
		country_id_num city_id_num cursal_pkr expsal_pkr ///
		dobirth_d age exp_exact ///
		industry_str maritalstatus_str gender_str careerlevel_str ///
		country_name city_name ///
		lang1_id lang1_level ///
		lang2_id lang2_level ///
		lang3_id lang3_level ///
		lang4_id lang4_level ///
		lang5_id lang5_level ///
		lang_count ///
		skill_lvl0_n skill_lvl1_n skill_lvl2_n skill_lvl3_n ///
		age_bucket exp_bucket sal_gap ///
		user_created_dt user_created_yr expsal_usd_ppp cursal_usd_ppp

	local origvars : list allvars - created

	gen  	_ORIGINAL_____________ = .
	gen 	_CREATED_________ = .
	order 	_ORIGINAL_____________ `origvars' _CREATED_________ `created'

	label var gender_id_num        "Gender ID (numeric)"
	label var maritalstatus_num    "Marital status ID (numeric)"
	label var industry_id_num      "Industry ID (numeric)"
	label var careerlevel_id_num   "Career level ID (numeric)"
	label var country_id_num       "Country ID (numeric)"
	label var city_id_num          "City ID (numeric)"
	label var lang_count 		   "Number of languages listed (count)"
	label var cursal_pkr           "Current salary (PKR)"
	label var expsal_pkr           "Expected salary (PKR)"
	label var sal_gap              "Expected – current salary (PKR)"
	label var dobirth_d            "Date of birth"
	label var age                  "Age (years; trimmed 14–90)"
	label var exp_exact 		   "Exact years of experience (numeric)"
	label var industry_str         "Industry (string label)"
	label var maritalstatus_str    "Marital status (string label)"
	label var gender_str           "Gender (string label)"
	label var careerlevel_str      "Career level (string label)"
	label var country_name         "Country name"
	label var city_name            "City name"
	label var age_bucket           "Age bucket"
	label var exp_bucket           "Experience bucket"
	label var user_created_dt      "User created datetime (%tc from 'created')"
	label var user_created_yr      "User created year"
	label var expsal_usd_ppp       "2024 USD (PPP) from expsal_pkr"
	label var cursal_usd_ppp       "2024 USD (PPP) from cursal_pkr"
	label var skill_lvl0_n 		   "Count of skills at level 0"
	label var skill_lvl1_n		   "Count of skills at level 1"
	label var skill_lvl2_n 		   "Count of skills at level 2"
	label var skill_lvl3_n		   "Count of skills at level 3"


*--------- Compress and save ---------------------------------------------------

	compress
	save "$int/users_int.dta", replace
	
	
************************************************
************************************************
**# USERS EDUCATION
************************************************
************************************************

*--- Load ----------------------------------------------------

	use "$proc/users_education_proc.dta", clear

*--- Graduation year helpers ---------------------------------

	* Datetimes
    gen double createdon_dt = clock(createdon, "YMDhms")
    format %tc createdon_dt
	
    gen int    createdon_d  = dofc(createdon_dt)
    format %td createdon_d
	
    gen int    createdon_yr = year(createdon_d)

	* Normalize graduation year and make buckets
	gen byte grad_year_bucket = .
	replace grad_year_bucket = floor((eduyear_num - 1900)/10) + 1 if inrange(eduyear_num, 1900, 2040)

	* Labels
	label define lgy , replace
	local start = 1900
	local stop  = 2040
	local i = 1
	forvalues y = `start'(10)`stop' {
		local y2 = `y' + 9
		if `y2' > `stop' local y2 = `stop'
		label define lgy `i' "`y'–`y2'", add
		local ++i
	}
	label values grad_year_bucket lgy

*--- Common grade scales ---------------------------------------------------

	gen byte grade_is_gpa4 = (edugradeoutof_num==4)
	gen byte grade_is_gpa5 = (edugradeoutof_num==5)
	gen byte grade_is_pct  = (edugradeoutof_num==100)

*--- Dictionary joins --------------------------------------------------

	* DegreeType
	preserve
		use "$dict/meta_info.dta", clear
		keep if inlist(type,"degreeType","DegreeLevel")
		keep id name
		rename id   degreetypeid_num
		rename name degreetype_str
		tempfile m_degtype
		save "`m_degtype'"
	restore
	merge m:1 degreetypeid_num using "`m_degtype'", keep(1 3) nogen

	* HighestDegree
	preserve
		use "$dict/meta_info.dta", clear
		keep if inlist(type,"degreeType","DegreeLevel")
		keep id name
		rename id   highestdegreeid_num
		rename name highestdegree_str
		tempfile m_highdeg
		save "`m_highdeg'"
	restore
	merge m:1 highestdegreeid_num using "`m_highdeg'", keep(1 3) nogen

	preserve
		use "$dict/countries.dta", clear
		keep country_id country_name
		rename country_id educountryid_num
		tempfile m_cty
		save "`m_cty'"
	restore
	merge m:1 educountryid_num using "`m_cty'", keep(1 3) nogen

	preserve
		use "$dict/cities.dta", clear
		keep city_id cityy_name
		rename city_id    educityid_num
		rename cityy_name edu_city_name
		tempfile m_city
		save "`m_city'"
	restore
	merge m:1 educityid_num using "`m_city'", keep(1 3) nogen

*--- Order & labels -----------------------------------------------------------

	ds
	local allvars `r(varlist)'

	local created ///
		degreetypeid_num highestdegreeid_num educountryid_num educityid_num ///
		eduyear_num edugradeoutof_num ///
		grad_year_bucket ///
		grade_is_gpa4 grade_is_gpa5 grade_is_pct ///
		degreetype_str highestdegree_str ///
		country_name edu_city_name ///
		createdon_dt createdon_d createdon_yr

	local origvars : list allvars - created

	gen   _ORIGINAL_____________ = .
	gen   _CREATED_________      = .
	order _ORIGINAL_____________ `origvars' _CREATED_________ `created'

	* Labels for created variables
	label var createdon_dt        "Education record created datetime (%tc)"
	label var createdon_d         "Education record created date (%td)"
	label var createdon_yr        "Education record created year"
	label var grad_year_bucket    "Graduation year bucket (10-year, 1900–2040)"
	label var grade_is_gpa4       "Out of 4.0 GPA scale"
	label var grade_is_gpa5       "Out of 5.0 GPA scale"
	label var grade_is_pct        "Out of 100 (percentage)"
	label var degreetype_str      "Degree type (string label)"
	label var highestdegree_str   "Highest degree (string label)"
	label var country_name        "Education country name"
	label var edu_city_name       "Education city name"
	label var degreetypeid_num     "Degree type ID (numeric)"
	label var highestdegreeid_num  "Highest degree ID (numeric)"
	label var educountryid_num     "Education country ID (numeric)"
	label var educityid_num        "Education city ID (numeric)"
	label var eduyear_num          "Graduation/education year (numeric)"
	label var edugradeoutof_num    "Grade out of (numeric)"


*--- Compress and save ---------------------------------------------------------------------

	compress
	save "$int/users_education_int.dta", replace

	
************************************************
************************************************
**# USERS EXPERIENCE
************************************************
************************************************

*--- Load ----------------------------------------------------

	use "$proc/users_experience_proc.dta", clear

*--- Datetime --------------------------------------------

	gen double createdon_dt = clock(createdon, "YMDhms")
	format %tc createdon_dt
	gen int    createdon_d  = dofc(createdon_dt)
	format %td createdon_d
	gen int    createdon_yr = year(createdon_d)

	gen int    jobstart_m = monthly(jobstart, "YM")
	gen int    jobend_m   = .
	replace     jobend_m  = monthly(jobend, "YM") if !ustrregexm(lower(jobend), "^\s*present\s*$")
	format %tm jobstart_m jobend_m
	
	gen byte jobstart_mon = month(dofm(jobstart_m)) if !missing(jobstart_m)
	gen byte jobend_mon   = month(dofm(jobend_m))   if !missing(jobend_m)

	gen int    jobstart_yr = yofd(dofm(jobstart_m))
	gen int    jobend_yr   = yofd(dofm(jobend_m))

*--- Manage team buckets -------------------------------------

	gen byte  manage_team_ind = .
	replace   manage_team_ind = 0 if manage_team=="no" | manage_team==""
	replace   manage_team_ind = 1 if manage_team!="no" & manage_team!=""
	label define lmt 0 "No" 1 "Yes"
	label values manage_team_ind lmt

	gen double team_size = .
	replace team_size = real(ustrregexs(1)) if ustrregexm(manage_team, "^\s*([0-9]+)\s*$")
	replace team_size = real(ustrregexs(1)) if ustrregexm(manage_team, "^\s*([0-9]+)\+\s*$")

	gen byte team_size_bucket = .
	replace team_size_bucket = 1 if inrange(team_size, 1, 5)
	replace team_size_bucket = 2 if inrange(team_size, 6,10)
	replace team_size_bucket = 3 if inrange(team_size,11,20)
	replace team_size_bucket = 4 if inrange(team_size,21,35)
	replace team_size_bucket = 5 if team_size>=36 & team_size<.
	label define lts 1 "1–5" 2 "6–10" 3 "11–20" 4 "21–35" 5 "36+"
	label values team_size_bucket lts

*--- Dictionary joins (country/city names) -------------------

	preserve
		use "$dict/cities.dta", clear
		keep city_id cityy_name
		rename city_id empcityid_num
		bysort empcityid_num (cityy_name): keep if _n==1
		tempfile m_city
		save "`m_city'"
	restore

	preserve
		use "$dict/countries.dta", clear
		keep country_id country_name
		rename country_id empcountryid_num
		bysort empcountryid_num (country_name): keep if _n==1
		tempfile m_cty
		save "`m_cty'"
	restore

	merge m:1 empcityid_num     using "`m_city'", keep(1 3) nogen
	merge m:1 empcountryid_num  using "`m_cty'",  

	rename cityy_name city_name

*--- Order & labels ------------------------------------------

	ds
	local allvars `r(varlist)'

	local created ///
		jobcompanyid_num empcityid_num empcountryid_num ///
		createdon_dt createdon_d createdon_yr ///
		jobstart_m jobend_m jobstart_mon jobend_mon jobstart_yr jobend_yr ///
		manage_team_ind team_size team_size_bucket ///
		country_name city_name

	local origvars : list allvars - created

	gen   _ORIGINAL_____________ = .
	gen   _CREATED_________      = .
	order _ORIGINAL_____________ `origvars' _CREATED_________ `created'

	label var createdon_dt        "Experience record created datetime (%tc)"
	label var createdon_d         "Experience record created date (%td)"
	label var createdon_yr        "Experience record created year"
	label var jobstart_m          "Job start (%tm)"
	label var jobend_m            "Job end (%tm)"
	label var jobstart_mon 		  "Job start month (1–12)"
	label var jobend_mon   		  "Job end month (1–12)"
	label var jobstart_yr         "Job start year"
	label var jobend_yr           "Job end year"
	label var manage_team_ind     "Manages a team (flag)"
	label var team_size           "Team size (parsed)"
	label var team_size_bucket    "Team size bucket"
	label var country_name        "Employment country name"
	label var city_name       	  "Employment city name"
	label var jobcompanyid_num    "Employer/company ID (numeric)"
	label var empcityid_num       "Employment city ID (numeric)"
	label var empcountryid_num    "Employment country ID (numeric)"

*--- Compress and save ---------------------------------------

	compress
	save "$int/users_experience_int.dta", replace
	
	
************************************************
************************************************
**# COMPANIES
************************************************
************************************************

*--- Load ----------------------------------------------------

	use "$proc/companies_proc.dta", clear

*--- Number of employees ----------------------------------------------------

	gen str40 emp_s = upper(trim(no_of_employee))

	gen double emp_min = .
	gen double emp_max = .

	* Keep only clean ranges A-B
	replace emp_min = real(regexs(1)) if regexm(emp_s, "^\s*([0-9]+)\s*-\s*([0-9]+)\s*$")
	replace emp_max = real(regexs(2)) if regexm(emp_s, "^\s*([0-9]+)\s*-\s*([0-9]+)\s*$")

	* Drop reversed ranges; keep only proper A-B ranges
	replace emp_min = . if emp_min>emp_max
	replace emp_max = . if missing(emp_min)

	* Include single values N (set min=max=N)
	replace emp_min = real(regexs(1)) if missing(emp_min) & regexm(emp_s, "^\s*([0-9]+)\s*$")
	replace emp_max = emp_min         if missing(emp_max) & regexm(emp_s, "^\s*([0-9]+)\s*$")

	* Keep only the open-ended "MORE THAN 5000" as its own bucket
	gen byte emp_bucket = .
	replace emp_bucket = 7 if emp_s == "MORE THAN 5000"

	* Buckets
	replace emp_bucket = 1 if inrange(emp_max,   1,   10) & !missing(emp_min) & emp_bucket==.
	replace emp_bucket = 2 if inrange(emp_max,  11,   50) & !missing(emp_min) & emp_bucket==.  
	replace emp_bucket = 3 if inrange(emp_max,  51,  100) & !missing(emp_min) & emp_bucket==.
	replace emp_bucket = 4 if inrange(emp_max, 101,  500) & !missing(emp_min) & emp_bucket==.   
	replace emp_bucket = 5 if inrange(emp_max, 501, 1000) & !missing(emp_min) & emp_bucket==.   
	replace emp_bucket = 6 if inrange(emp_max,1001, 5000) & !missing(emp_min) & emp_bucket==.   

	label define lemp 1 "1–10" 2 "11–50" 3 "51–100" 4 "101–500" 5 "501–1000" 6 "1001–5000" 7 "5001+"
	label values emp_bucket lemp

	tab emp_bucket

*--- Created time + opsince ----------------------------------------------------

	gen double created_dt = clock(created, "YMDhms")
	format      created_dt %tc

	gen        created_d  = dofc(created_dt)
	format     created_d  %td

	gen int    created_yr = yofd(created_d)
	gen byte   created_mo = month(created_d)

	gen int    opsince_yr = .
	replace     opsince_yr = real(regexs(1)) if regexm(operating_since, "([12][0-9]{3})")
	replace     opsince_yr = .               if opsince_yr<1900 | opsince_yr>2025

	gen int    company_age = 2025 - opsince_yr if opsince_yr<.


*--- Dictionary joins ----------------------------------------------------

	preserve
		use "$dict/meta_info.dta", clear
		keep if type=="Industry"
		keep id name
		rename id   industry_id_num
		rename name industry_str
		tempfile m_ind
		save "`m_ind'"
	restore
	merge m:1 industry_id_num using "`m_ind'", keep(1 3) nogen

	preserve
		use "$dict/countries.dta", clear
		keep country_id country_name
		rename country_id country_id_num
		tempfile m_cty
		save "`m_cty'"
	restore
	merge m:1 country_id_num using "`m_cty'", keep(1 3) nogen

	preserve
		use "$dict/cities.dta", clear
		keep  city_id cityy_name
		rename city_id    city_id_num
		rename cityy_name city_name
		tempfile m_city
		save "`m_city'"
	restore
	merge m:1 city_id_num using "`m_city'", keep(1 3) nogen


*--------- Order and labels ----------------------------------------------------

	ds
	local allvars `r(varlist)'
	local created ///
		city_id_num country_id_num industry_id_num nooffices_num ///
		emp_bucket created_dt created_d created_yr created_mo ///
		emp_s emp_max emp_min company_type_str ///
		opsince_yr company_age industry_str country_name city_name

	local origvars : list allvars - created

	gen      	_ORIGINAL_____________ = .
	gen      	_CREATED_________ = .

	order    	_ORIGINAL_____________ `origvars' _CREATED_________ `created'

	label var city_id_num              "City ID (numeric)"
	label var country_id_num           "Country ID (numeric)"
	label var industry_id_num          "Industry ID (numeric)"
	label var nooffices_num            "Number of offices (numeric)"
	label var emp_s					   "Number of employees"	
	label var emp_bucket               "Number of employees (buckets)"
	label var emp_min				   "Minimum number of employees"
	label var emp_max 				   "Maximum number of employees"
	label var created_dt               "Record created datetime (%tc)"
	label var created_d                "Record created date (%td)"
	label var created_yr               "Record created year"
	label var created_mo               "Record created month (1–12)"
	label var opsince_yr               "Operating since (year)"
	label var company_age              "Company age in 2025 (years)"
	label var industry_str             "Industry (string label)"
	label var company_type_str 		   "Company ownership type"
	label var country_name             "Country name"
	label var city_name                "City name"


*--------- Compress and save ---------------------------------------------------

	compress
	save "$int/companies_int.dta", replace


************************************************
************************************************
**# JOBS
************************************************
************************************************

*--- Load ----------------------------------------------------

	use "$proc/jobs_proc.dta", clear


*--- Datetimes ----------------------------------------------------

	gen double 		created_dt = clock(created, "YMDhms") if !missing(created)
	format %tc 		created_dt

	gen int  		created_d  = dofc(created_dt)
	format %td 		created_d
	gen int  		created_yr = year(created_d)
	gen byte 		created_mo = month(created_d)

	gen int 		applyby_d  = date(applyby, "YMD") if !missing(applyby)
	format %td 		applyby_d
	gen int 		applyby_yr = year(applyby_d)
	gen byte 		applyby_mo = month(applyby_d)

*--- Experience ----------------------------------------------------

	gen str30 _req = lower(trim(req_experience))
	gen str30 _max = lower(trim(max_experience))

	gen double 	req_exp_yrs = .
	replace     req_exp_yrs = 0                    if inlist(_req, "fresh", "less than 1 year")
	replace     req_exp_yrs = real(regexs(1))      if regexm(_req, "^([0-9]+)")
	replace     req_exp_yrs = .                    if _req=="not required"

	gen double 	max_exp_yrs = .
	replace     max_exp_yrs = 0                    if inlist(_max, "fresh", "less than 1 year")
	replace     max_exp_yrs = real(regexs(1))      if regexm(_max, "^([0-9]+)")
	replace     max_exp_yrs = .                    if _max=="not required"

	drop _req _max
	

*--- Dictionary joins ----------------------------------------------------

	preserve
		use "$dict/meta_info.dta", clear
		keep if type=="Industry"
		keep id name
		rename id   industry_id_num
		rename name industry_str
		tempfile m_ind
		save "`m_ind'"
	restore
	merge m:1 industry_id_num using "`m_ind'", keep(1 3) nogen

	preserve
		use "$dict/meta_info.dta", clear
		keep if type=="Gender"
		keep id name
		rename id   genderid_num
		rename name gender_str
		tempfile m_gen
		save "`m_gen'"
	restore
	merge m:1 genderid_num using "`m_gen'", keep(1 3) nogen

	preserve
		use "$dict/meta_info.dta", clear
		keep if type=="CareerLevel"
		keep id name
		rename id   careerlevelid_num
		rename name careerlevel_str
		tempfile m_car
		save "`m_car'"
	restore
	merge m:1 careerlevelid_num using "`m_car'", keep(1 3) nogen

	preserve
		use "$dict/countries.dta", clear
		keep country_id country_name
		rename country_id country_id_num
		tempfile m_cty
		save "`m_cty'"
	restore
	merge m:1 country_id_num using "`m_cty'", keep(1 3) nogen
	
	preserve
		use "$dict/meta_info.dta", clear
		keep if type=="DegreeLevel"
		keep id name
		tempfile m_deglev
		save "`m_deglev'"
	restore

	preserve
		use "`m_deglev'", clear
		rename id   min_education_num
		rename name min_education_str
		tempfile m_deglev_min
		save "`m_deglev_min'"
	restore
	merge m:1 min_education_num using "`m_deglev_min'", keep(1 3) keepusing(min_education_str) nogen

	preserve
		use "`m_deglev'", clear
		rename id   max_education_num
		rename name max_education_str
		tempfile m_deglev_max
		save "`m_deglev_max'"
	restore
	merge m:1 max_education_num using "`m_deglev_max'", keep(1 3) keepusing(max_education_str) nogen


	/*preserve
		use "$dict/cities.dta", clear
		keep  city_id cityy_name
		rename cityy_name city_name
		tempfile m_city
		save "`m_city'"
	restore
	merge m:1 city_id using "`m_city'", keep(1 3) nogen*/ // need to decide on "All Cities" in 2.process.do 


*--- Deleted jobs join + flags ----------------------------------------------

	preserve
		use "$merged/jobs_deleted.dta", clear
		keep jid deletedon
		replace deletedon = trim(deletedon)
		replace deletedon = "" if inlist(upper(deletedon),"","NULL",".","NA","N/A","NONE","MISSING")
		duplicates drop jid, force
		tempfile m_del
		save "`m_del'"
	restore

	merge m:1 jid using "`m_del'", keep(1 3) nogen

	gen double deletedon_dt = clock(deletedon, "YMDhms") if deletedon!=""
	gen int    deletedon_d  = dofc(deletedon_dt) if deletedon_dt<.
	gen int    deletedon_yr = year(deletedon_d)  if deletedon_d<.
	gen byte   deletedon_mo = month(deletedon_d) if deletedon_d<.
	gen byte   isdeleted    = (deletedon!="")

	format %tc deletedon_dt
	format %td deletedon_d

	
*--------- Order and labels ----------------------------------------------------

	ds
	local allvars `r(varlist)'

	local created ///
		job_type_id_num job_shift_id_num genderid_num country_id_num totalpositions_num ///
		industry_id_num department_id_num min_education_num max_education_num careerlevelid_num tb_id_num ///
		sal_from_num sal_to_num sal_from_hide_num sal_to_hide_num ///
		created_dt created_d created_yr created_mo ///
		applyby_d applyby_yr applyby_mo ///
		req_exp_yrs max_exp_yrs min_age_num max_age_num ///
		isfeatured istopjob ispremiumjob applyjobquestion_num ///
		deletedon_dt deletedon_d deletedon_yr deletedon_mo isdeleted ///
		filter_gender_num filter_experience_num filter_degree_num filter_age_num filter_city_num ///
		industry_str gender_str careerlevel_str country_name min_education_str max_education_str

	local origvars : list allvars - created

	gen    _ORIGINAL_____________ = .
	gen    _CREATED_________      = .
	order  _ORIGINAL_____________ `origvars' _CREATED_________ `created'

	* Labels for created variables
	label var job_type_id_num          "Job type ID (numeric)"
	label var job_shift_id_num         "Job shift ID (numeric)"
	label var genderid_num             "Target gender ID (numeric)"
	label var country_id_num           "Country ID (numeric)"
	label var industry_id_num          "Industry ID (numeric)"
	label var department_id_num        "Department ID (numeric)"
	label var min_education_num        "Min education ID (numeric)"
	label var max_education_num        "Max education ID (numeric)"
	label var careerlevelid_num        "Career level ID (numeric)"
	label var tb_id_num                "TB ID (numeric)"
	label var totalpositions_num	   "Total positions (numeric)"	
	
	label var sal_from_num             "Salary range from (numeric)"
	label var sal_to_num               "Salary range to (numeric)"
	label var sal_from_hide_num        "Salary range from (hidden, numeric)"
	label var sal_to_hide_num          "Salary range to (hidden, numeric)"

	label var created_dt               "Job created datetime (%tc)"
	label var created_d                "Job created date (%td)"
	label var created_yr               "Job created year"
	label var created_mo               "Job created month (1–12)"

	label var applyby_d                "Apply-by date (%td)"
	label var applyby_yr               "Apply-by year"
	label var applyby_mo               "Apply-by month (1–12)"

	label var req_exp_yrs              "Required experience (years)"
	label var max_exp_yrs              "Maximum experience (years)"
	label var min_age_num              "Minimum age (years)"
	label var max_age_num              "Maximum age (years)"

	label var isfeatured               "Featured job (1/0)"
	label var istopjob                 "Top job (1/0)"
	label var ispremiumjob             "Premium job (1/0)"
	label var applyjobquestion_num     "Requires apply-by questions (1/0)"

	label var deletedon                "Job deleted datetime (original)"
	label var deletedon_dt             "Job deleted datetime (%tc)"
	label var deletedon_d              "Job deleted date (%td)"
	label var deletedon_yr             "Job deleted year"
	label var deletedon_mo             "Job deleted month (1–12)"
	label var isdeleted                "Job is marked deleted (1/0)"

	label var filter_gender_num        "Filter gender active (1/0)"
	label var filter_experience_num    "Filter experience active (1/0)"
	label var filter_degree_num        "Filter degree active (1/0)"
	label var filter_age_num           "Filter age active (1/0)"
	label var filter_city_num          "Filter city active (1/0)"

	label var industry_str             "Industry (string label)"
	label var gender_str               "Target gender (string label)"
	label var careerlevel_str          "Career level (string label)"
	label var min_education_str 	   "Minimum education (string label)"
	label var max_education_str 	   "Maximum education (string label)"
	label var country_name             "Country name (string label)"


*--------- Compress and save ---------------------------------------------------

	compress
	save "$int/jobs_int.dta", replace

************************************************
************************************************
**# APPLICATIONS -- RANDOM SUBSAMPLE
************************************************
************************************************

*--- Load ----------------------------------------------------

	use "$proc/applications_sample_proc.dta", clear


*--- Application datetime parts ------------------------------------------------

	gen double   apply_dt  = clock(apply_date, "YMDhms")
	format       apply_dt %tc

	gen       	 apply_d   = dofc(apply_dt)
	format    	 apply_d   %td

	gen int    	 apply_yr  = yofd(apply_d)
	gen byte   	 apply_mo  = month(apply_d)


*--- Salary gap at application -------------------------------------------

	gen double sal_gap_app = expsal_app - cursal_app ///
								 if !missing(expsal_app, cursal_app)

/*--- PKR to USD PPP conversion ----------------------------------

	* PPP lookup (PAK & USA), 2004–2024
	frame create ppp
	frame change  ppp

	wbopendata, indicator("PA.NUS.PPP") clear
	keep countrycode yr2004-yr2024
	keep if inlist(countrycode,"PAK","USA")

	reshape long yr, i(countrycode) j(year)
	rename yr ppp_lcu_per_intdol

	reshape wide ppp_lcu_per_intdol, i(year) j(countrycode) string
	rename ppp_lcu_per_intdolPAK ppp_pak_lcu_per_intdol   // PKR per int$
	rename ppp_lcu_per_intdolUSA ppp_usa_usd_per_intdol   // USD per int$

	rename year apply_yr
	frame change default

	* Apply to salaries
	pppconvert expsal_pkr_app, yearvar(apply_yr) generate(expsal_usd_ppp_app)
	pppconvert cursal_pkr_app, yearvar(apply_yr) generate(cursal_usd_ppp_app)

	gen double sal_gap_app_usd_ppp = expsal_usd_ppp_app - cursal_usd_ppp_app ///
									 if !missing(expsal_usd_ppp_app, cursal_usd_ppp_app)

*/

*--------- Order and labels ----------------------------------------------------

	local created ///
		cursal_app expsal_app sal_gap_app ///
		apply_dt apply_d apply_yr apply_mo ///
		//expsal_usd_ppp_app cursal_usd_ppp_app sal_gap_app_usd_ppp

	ds
	local allvars `r(varlist)'
	local origvars : list allvars - created

	gen      _ORIGINAL_____________ = .
	gen      _CREATED_________ = .

	order    _ORIGINAL_____________ `origvars' _CREATED_________ `created'

	label var cursal_app          		"Current salary at application (numeric)"
	label var expsal_app          		"Expected salary at application (numeric)"
	label var sal_gap_app         		"Expected − current salary at application (numeric)"
	label var apply_dt                	"Application datetime (%tc)"
	label var apply_d                 	"Application date (%td)"
	label var apply_yr                	"Application year"
	label var apply_mo                	"Application month (1–12)"
	*label var expsal_usd_ppp_app      	"2024 USD (PPP) from expected salary at application"
	*label var cursal_usd_ppp_app      	"2024 USD (PPP) from current salary at application"
	*label var sal_gap_app_usd_ppp     	"Expected − current salary at application (2024 USD, PPP)"


*--------- Compress and save ---------------------------------------------------

	compress
	save "$int/applications_sample_int.dta", replace

*/

********************************************
********************************************
**# End of do file
********************************************
********************************************





