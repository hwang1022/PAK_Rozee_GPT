
/*============================================================================*
 |  Project:    Rozee 
 |  Author:     AB
 |  File:       Creating variables for cleaned RozeeGPT data
 |  Required:   Run 1.creation_gpt.do and 2.cleaning_gpt.do before this file
 *============================================================================*/
 
************************************************
************************************************
**# USERS
************************************************
************************************************

*--- Load -------------------------------------------------------------------

	use "$cleaned/users_gpt_cleaned.dta", clear

*--- Dates: DOB -> age; created_at / last_login -> %tc, %td, years ----------

	gen int    dob_d      = date(dob, "YMD")
	format     dob_d %td
	label var  dob_d      "Date of birth (%td)"

	gen int    age        = floor((d(01jan2025) - dob_d)/365.25)
	replace     age       = . if missing(dob_d) | age<14 | age>90
	label var  age        "Age (years; trimmed 14–90)"

	gen double created_tc = clock(created_at, "YMDhms")
	gen int    created_d  = dofc(created_tc)
	gen int    created_yr = yofd(created_d)
	format     created_tc %tc
	format     created_d  %td
	label var  created_tc "Created at (%tc)"
	label var  created_d  "Created date (%td)"
	label var  created_yr "Created year"

	gen double lastlogin_tc = clock(last_login, "YMDhms")
	gen int    lastlogin_d  = dofc(lastlogin_tc)
	gen int    lastlogin_yr = yofd(lastlogin_d)
	format     lastlogin_tc %tc
	format     lastlogin_d  %td
	label var  lastlogin_tc "Last login (%tc)"
	label var  lastlogin_d  "Last login date (%td)"
	label var  lastlogin_yr "Last login year"

*--- Country -------------------------------------------------------------

	destring country_id, gen(country_id_num)
	label var  country_id_num "Country ID (numeric)"

	preserve
		use "$dict/countries_ha.dta", clear
		keep countryid countryname
		rename countryid country_id_num
		tempfile m_cty
		save "`m_cty'"
	restore
	
	merge m:1 country_id_num using "`m_cty'", keep(1 3) nogen
	label var countryname "Country name"

*--- Current salary --------------------------------------------------------

	gen strL cursal_pkr = current_salary

	* remove currency text and spaces
	replace cursal_pkr = ustrregexra(cursal_pkr, "(?i)\bPKR\b", "")
	replace cursal_pkr = subinstr(cursal_pkr, " ", "", .)

	* handle K/k shorthand: "30k" or "2.5k" -> "30000" / "2500"
	quietly replace cursal_pkr = string(real(ustrregexs(1))*1000,"%12.0f") ///
		if ustrregexm(cursal_pkr, "^\s*([0-9]+(?:\.[0-9]+)?)\s*[kK]\s*$")

	* set negatives and zeros to missing
	replace cursal_pkr = "" if ustrregexm(cursal_pkr, "^-")
	replace cursal_pkr = "" if inlist(cursal_pkr,"0","00","000","0.0","0.00","0.000")

	* convert to numeric in place
	destring cursal_pkr, replace
	
	* convert to 2024 USD PPP
    frame create ppp
    frame change  ppp

    wbopendata, indicator("PA.NUS.PPP") clear
    keep countrycode yr2004-yr2024
    keep if inlist(countrycode,"PAK","USA")

    reshape long yr, i(countrycode) j(created_yr)
    rename yr ppp_lcu_per_intdol

    reshape wide ppp_lcu_per_intdol, i(created_yr) j(countrycode) string
    rename ppp_lcu_per_intdolPAK ppp_pak_lcu_per_intdol   // PKR per int$
    rename ppp_lcu_per_intdolUSA ppp_usa_usd_per_intdol   // USD per int$

    frame change default

	pppconvert cursal_pkr, yearvar(created_yr) generate(cursal_usd_ppp)
	
*--- Skills: count skills per user ------------------------------------------

	preserve
		use "$created/user_skills_ha.dta", clear   // rows: one skill per user_id
		keep user_id skill_id

		contract user_id skill_id              // unique pairs
		bys user_id: gen skillcount = _N
		keep user_id skillcount
		by user_id: keep if _n==1

		tempfile m_skillcount
		save "`m_skillcount'"
	restore

	merge 1:1 user_id using "`m_skillcount'", keep(1 3) nogen

*--- Order and labels --------------------------------------------------------

	ds
	local allvars `r(varlist)'

	local created ///
		country_id_num countryname ///
		dob_d age skillcount ///
		created_tc created_d created_yr ///
		lastlogin_tc lastlogin_d lastlogin_yr ///
		cursal_pkr cursal_usd_ppp

	local origvars : list allvars - created

	gen   _ORIGINAL_____________ = .
	gen   _CREATED_________      = .
	order _ORIGINAL_____________ `origvars' _CREATED_________ `created'

    label var country_id_num   	"Country ID (numeric)"
    label var countryname     	"Country name"
    label var dob_d            	"Date of birth (%td)"
    label var age              	"Age (years; trimmed 14–90)"
	label var skillcount 	   	"Number of skills listed (count)"
    label var created_tc       	"Created at (%tc)"
    label var created_d        	"Created date (%td)"
    label var created_yr       	"Created year"
    label var lastlogin_tc     	"Last login (%tc)"
    label var lastlogin_d      	"Last login date (%td)"
    label var lastlogin_yr     	"Last login year"
    label var cursal_pkr       	"Current salary (PKR)"
    label var cursal_usd_ppp   	"2024 USD (PPP) from cursal_pkr"

*--- Compress and save ---------------------------------------------------------

	compress
	save "$vars/users_gpt_vars_creation.dta", replace


************************************************
************************************************
**# COMPANIES
************************************************
************************************************

*--- Load ----------------------------------------------------

	use "$cleaned/companies_gpt_cleaned.dta", clear	
	
*--- Created time + opsince ----------------------------------------------------

	gen double 	created_dt = clock(created_at, "YMDhms")
	format      created_dt %tc

	gen        	created_d  = dofc(created_dt)
	format     	created_d  %td

	gen int    	created_yr = yofd(created_d)
	gen byte   	created_mo = month(created_d)

*--------- Order and labels ----------------------------------------------------

	ds
	local allvars `r(varlist)'
	local created ///
		created_dt created_d created_yr created_mo

	local origvars : list allvars - created

	gen      	_ORIGINAL_____________ = .
	gen      	_CREATED_________ = .

	order    	_ORIGINAL_____________ `origvars' _CREATED_________ `created'

	label var created_dt               "Record created datetime (%tc)"
	label var created_d                "Record created date (%td)"
	label var created_yr               "Record created year"
	label var created_mo               "Record created month (1–12)"

*--------- Compress and save ---------------------------------------------------

	compress
	save "$vars/companies_gpt_vars_creation.dta", replace	
	
	
************************************************
************************************************
**# JOBS
************************************************
************************************************

*--- Load ----------------------------------------------------

	use "$cleaned/jobs_gpt_cleaned.dta", clear

*--- Datetimes ----------------------------------------------------

	* Created at
	gen double 		created_dt = clock(created_at, "YMDhms") if !missing(created_at)
	format %tc 		created_dt
	gen int  		created_d  = dofc(created_dt)
	format %td 		created_d
	gen int  		created_yr = year(created_d)
	gen byte 		created_mo = month(created_d)

	* Updated at
	gen double 		updated_dt = clock(updated_at, "YMDhms") if !missing(updated_at)
	format %tc 		updated_dt
	gen int  		updated_d  = dofc(updated_dt)
	format %td 		updated_d
	gen int  		updated_yr = year(updated_d)
	gen byte 		updated_mo = month(updated_d)
	
	* Published at
	gen double  published_dt = clock(published_at, "YMDhms") if !missing(published_at)
	format %tc  published_dt
	gen int     published_d  = dofc(published_dt)
	format %td  published_d
	gen int     published_yr = year(published_d)
	gen byte    published_mo = month(published_d)

	* Apply by
	gen double  apply_by_dt = clock(apply_by, "YMDhms") if !missing(apply_by)
	format %tc  apply_by_dt
	gen int     apply_by_d  = dofc(apply_by_dt)
	format %td  apply_by_d
	gen int     apply_by_yr = year(apply_by_d)
	gen byte    apply_by_mo = month(apply_by_d)

*--- Numeric copies ----------------------------------------------------

	gen 		hide_salary_num = ""
	replace 	hide_salary_num = "1" if hide_salary == "Y"
	replace 	hide_salary_num = "0" if hide_salary == "N"
	destring 	hide_salary_num, replace
	
	gen         manage_employees_num = ""
	replace     manage_employees_num = "1" if manage_employees == "Yes"
	replace     manage_employees_num = "0" if manage_employees == "No"
	destring    manage_employees_num, replace
	
	destring 	subordinates_count, gen(subordinates_num)
	destring 	maximum_budget,		gen(max_budget_num)
	
*--- Required experience ----------------------------------------------------

	gen strL  req_exp_clean = trim(ustrlower(required_experience))

	* Normalize punctuation/spaces
	replace   req_exp_clean = ustrregexra(req_exp_clean, "[,;/]+", " ")
	replace   req_exp_clean = ustrregexra(req_exp_clean, "\s+", " ")

	* Common typos / variants -> canonical
	replace   req_exp_clean = ustrregexra(req_exp_clean, "yrs|yr", "year")
	replace   req_exp_clean = ustrregexra(req_exp_clean, "yearz|eyats", "year")
	replace   req_exp_clean = ustrregexra(req_exp_clean, "years", "year")
	replace   req_exp_clean = ustrregexra(req_exp_clean, "months", "month")
	replace   req_exp_clean = ustrregexra(req_exp_clean, "year's", "year")

	* Words -> numbers (keep word boundaries)
	local wmap "one 1 two 2 three 3 four 4 five 5 six 6 seven 7 eight 8 nine 9 ten 10 eleven 11 twelve 12 fifteen 15 twenty 20"
	forvalues i = 1(2)`: word count `wmap'' {
		local w : word `i' of `wmap'
		local n : word `=`i'+1' of `wmap'
		replace req_exp_clean = ustrregexra(req_exp_clean, "\b`w'\b", "`n'")
	}

	* Canonical phrases -> numeric spans
	replace   req_exp_clean = ustrregexra(req_exp_clean, "\bhalf\s*year\b", "0.5 year")
	replace   req_exp_clean = ustrregexra(req_exp_clean, "\bless than\s*1\s*year\b", "0 to 1 year")
	replace   req_exp_clean = ustrregexra(req_exp_clean, "\bup to\s*([0-9]+(\.[0-9]+)?)\s*year\b",  "0 to \1 year")
	replace   req_exp_clean = ustrregexra(req_exp_clean, "\bfresh to\s*([0-9]+(\.[0-9]+)?)\s*month\b", "0 to \1 month")
	replace   req_exp_clean = ustrregexra(req_exp_clean, "\bfresh to\s*([0-9]+(\.[0-9]+)?)\s*year\b",  "0 to \1 year")

	* "Year…" prefix variants
	replace   req_exp_clean = ustrregexra(req_exp_clean, "\byear\s*([0-9]+(\.[0-9]+)?)\s*(to|-)\s*([0-9]+(\.[0-9]+)?)\b", "\1 to \4 year")
	replace   req_exp_clean = ustrregexra(req_exp_clean, "\byear\s*([0-9]+(\.[0-9]+)?)\b", "\1 year")

	* Misspellings / variants
	replace   req_exp_clean = ustrregexra(req_exp_clean, "\bupto\b", "up to")
	replace   req_exp_clean = ustrregexra(req_exp_clean, "\bfres\b", "fresh")
	replace   req_exp_clean = ustrregexra(req_exp_clean, "\bfresh graduates?\b", "fresh")
	replace   req_exp_clean = ustrregexra(req_exp_clean, "\bfresh year?\b", "fresh")
	replace   req_exp_clean = ustrregexra(req_exp_clean, "\bno experience required?\b", "fresh")
	replace   req_exp_clean = ustrregexra(req_exp_clean, "\bfresh\s+0 to\b", "0 to")  // "fresh 0 to 1 year"
	replace   req_exp_clean = ustrregexra(req_exp_clean, "\bfresh\s*-\s*([0-9]+(\.[0-9]+)?)\s*(year|month)\b", "0 to \1 \3")
	replace   req_exp_clean = ustrregexra(req_exp_clean, "\bfresh\s*or\s*([0-9]+(\.[0-9]+)?)\s*(year|month)\b", "0 to \1 \3")
	replace   req_exp_clean = ustrregexra(req_exp_clean, "\bfresh\s*and\s*up to\s*([0-9]+(\.[0-9]+)?)\s*(year|month)\b", "0 to \1 \3")

	* Stray unit forms
	replace   req_exp_clean = ustrregexra(req_exp_clean, "([0-9]+)\s*y\b", "\1 year")
	replace   req_exp_clean = ustrregexra(req_exp_clean, "([0-9]+)month\b", "\1 month")

	* Curly quotes -> straight single quote
	replace req_exp_clean = ustrregexra(req_exp_clean, ustrunescape("\u2018|\u2019|\u201C|\u201D"), "'")

	* Ranges/numbers missing unit -> add " year"
	replace   req_exp_clean = req_exp_clean + " year" if regexm(req_exp_clean, "^\s*[0-9]+(\.[0-9]+)?\s*(to|-)\s*[0-9]+(\.[0-9]+)?\s*$")
	replace   req_exp_clean = req_exp_clean + " year" if regexm(req_exp_clean, "^\s*[0-9]+(\.[0-9]+)?\s*$")
	replace   req_exp_clean = "0" + req_exp_clean + " year" if regexm(req_exp_clean, "^\s*\.[0-9]+\s*$")

	* Trim trailing filler after normalized spans
	replace   req_exp_clean = ustrregexra(req_exp_clean, "(year)\s+is fine\b", "\1")

	* Non-informative noise -> missing
	replace   req_exp_clean = "" if inlist(req_exp_clean, "a","s","nn","asd","sad")
	replace   req_exp_clean = "" if trim(req_exp_clean)=="year"

	* Final tidy for remaining edge cases
	replace   req_exp_clean = ustrregexra(req_exp_clean, "^\s*[0-9]+\s+(0 to [0-9]+(\.[0-9]+)?\s*(year|month))\s*$", "\1")
	replace   req_exp_clean = ustrregexra(req_exp_clean, "^\s*[0-9]+\s+([0-9]+(\.[0-9]+)?\s*year)\s*$", "\1")
	replace   req_exp_clean = ustrregexra(req_exp_clean, "\byear\s*([0-9]+(\.[0-9]+)?)\s*year\b", "\1 year")
	replace req_exp_clean = "" if !missing(req_exp_clean) & !regexm(req_exp_clean, "[0-9]") & !regexm(req_exp_clean, "\bfresh(\s+year)?\b")

	*--- Targets
	gen double req_exp_min = .
	gen double req_exp_max = .

	*==================================================
	* 1) Explicit "fresh / no experience" -> 0–0
	*==================================================
	
	replace req_exp_min = 0 if regexm(req_exp_clean, "\bfresh\b")
	replace req_exp_max = 0 if req_exp_clean == "fresh"

	*==================================================
	* 2) Month ranges/singles -> fractions
	*==================================================
	
	* fresh - X month  -> 0 – X/12
	replace req_exp_min = 0 if missing(req_exp_min) & ustrregexm(req_exp_clean, "^\s*fresh\s*-\s*([0-9]+)\s*month\s*$")
	replace req_exp_max = real(ustrregexs(1))/12 if missing(req_exp_max) & ustrregexm(req_exp_clean, "^\s*fresh\s*-\s*([0-9]+)\s*month\s*$")
	
	* zero-start month span: "0 to X month" or "0-X month" -> 0 – X/12
	replace req_exp_min = real(ustrregexs(1))/12 if missing(req_exp_min) & ustrregexm(req_exp_clean, "([0-9]+)\s*(to|-)\s*([0-9]+)\s*month\b")
	replace req_exp_max = real(ustrregexs(3))/12 if missing(req_exp_max) & ustrregexm(req_exp_clean, "([0-9]+)\s*(to|-)\s*([0-9]+)\s*month\b")
	replace req_exp_min = 0 if missing(req_exp_min) & ustrregexm(req_exp_clean, "^\s*0\s*(to|-)\s*([0-9]+)\s*month\s*$")
	replace req_exp_max = real(ustrregexs(2))/12 if missing(req_exp_max) & ustrregexm(req_exp_clean, "^\s*0\s*(to|-)\s*([0-9]+)\s*month\s*$")

	* hyphen with only one 'month': "0-6 month"
	replace req_exp_min = real(ustrregexs(1))/12 if missing(req_exp_min) & ustrregexm(req_exp_clean, "([0-9]+)\s*-\s*([0-9]+)\s*month")
	replace req_exp_max = real(ustrregexs(2))/12 if missing(req_exp_max) & ustrregexm(req_exp_clean, "([0-9]+)\s*-\s*([0-9]+)\s*month")

	* month–year: "6 month to 1.5 year" OR "6 month-1 year"
	replace req_exp_min = real(ustrregexs(1))/12 if missing(req_exp_min) & ustrregexm(req_exp_clean, "([0-9]+)\s*month\s*(to|-)\s*([0-9]+(\.[0-9]+)?)\s*year")
	replace req_exp_max = real(ustrregexs(3))    if missing(req_exp_max) & ustrregexm(req_exp_clean, "([0-9]+)\s*month\s*(to|-)\s*([0-9]+(\.[0-9]+)?)\s*year")

	* single month: "6 month" (not part of a range)
	replace req_exp_min = real(ustrregexs(1))/12 if missing(req_exp_min) & ustrregexm(req_exp_clean, "\b([0-9]+)\s*month\b")
	replace req_exp_max = req_exp_min            if missing(req_exp_max) & !missing(req_exp_min) & ustrregexm(req_exp_clean, "\b([0-9]+)\s*month\b")
	
	*==================================================
	* 3) Year patterns (everything with the word "year")
	*    Normalize glued/hyphenated tokens, then extract:
	*    (a) x to y year / x-y year / x year to y year  -> x–y
	*    (b) 'at least x to y+ year'                    -> x–y
	*==================================================
	
	* 3-year -> 3 year
	replace req_exp_clean = ustrregexra(req_exp_clean, "\b([0-9]+(\.[0-9]+)?)\s*-\s*year\b", "\1 year")
	
	* 5year  -> 5 year   ;  4 - 5year -> 4 - 5 year
	replace req_exp_clean = ustrregexra(req_exp_clean, "\b([0-9]+(\.[0-9]+)?)year\b", "\1 year")
	replace req_exp_clean = ustrregexra(req_exp_clean, "([0-9]+(\.[0-9]+)?)\s*-\s*([0-9]+(\.[0-9]+)?)year\b", "\1 - \3 year")
	
	* "x year-y year" -> "x to y year"
	replace req_exp_clean = ustrregexra(req_exp_clean, "([0-9]+(\.[0-9]+)?)\s*year\s*-\s*([0-9]+(\.[0-9]+)?)\s*year\b", "\1 to \3 year")
	
	* --- Extra normalization for mojibake dashes and odd separators ---
	replace req_exp_clean = subinstr(req_exp_clean, "â€'", "-", .)

	* --- Ranges where only the RHS says "year" (e.g., "03 to 05 year", "10-12 year") ---
	replace req_exp_min = real(ustrregexs(1)) ///
		if missing(req_exp_min) & ustrregexm(req_exp_clean, "0*([0-9]+(\.[0-9]+)?)\s*(to|-)\s*0*([0-9]+(\.[0-9]+)?)\s*year\b")
		
	replace req_exp_max = real(ustrregexs(4)) ///
		if missing(req_exp_max) & ustrregexm(req_exp_clean, "0*([0-9]+(\.[0-9]+)?)\s*(to|-)\s*0*([0-9]+(\.[0-9]+)?)\s*year\b")

	* --- Ranges where BOTH sides carry "year" (e.g., "5 year-10 year") ---
	replace req_exp_min = real(ustrregexs(1)) ///
		if missing(req_exp_min) & ustrregexm(req_exp_clean, "([0-9]+(\.[0-9]+)?)\s*year\s*(to|-)\s*([0-9]+(\.[0-9]+)?)\s*year\b")
		
	replace req_exp_max = real(ustrregexs(4)) ///
		if missing(req_exp_max) & ustrregexm(req_exp_clean, "([0-9]+(\.[0-9]+)?)\s*year\s*(to|-)\s*([0-9]+(\.[0-9]+)?)\s*year\b")

	* --- "at least x to y+ year" (present: e.g., "at least 4 to 5+ year") ---
	replace req_exp_min = real(ustrregexs(1)) ///
		if missing(req_exp_min) & ustrregexm(req_exp_clean, "\bat least\s*([0-9]+(\.[0-9]+)?)\s*(to|-)\s*([0-9]+(\.[0-9]+)?)\+?\s*year\b")
		
	replace req_exp_max = real(ustrregexs(4)) ///
		if missing(req_exp_max) & ustrregexm(req_exp_clean, "\bat least\s*([0-9]+(\.[0-9]+)?)\s*(to|-)\s*([0-9]+(\.[0-9]+)?)\+?\s*year\b")

	* --- Bare space-separated range before 'year' (e.g., "10 12 year") ---
	replace req_exp_min = real(ustrregexs(1)) ///
		if missing(req_exp_min) & ustrregexm(req_exp_clean, "\b([0-9]+(\.[0-9]+)?)\s+([0-9]+(\.[0-9]+)?)\s*year\b")
	replace req_exp_max = real(ustrregexs(3)) ///
		if missing(req_exp_max) & ustrregexm(req_exp_clean, "\b([0-9]+(\.[0-9]+)?)\s+([0-9]+(\.[0-9]+)?)\s*year\b")

	* --- Ranges where RHS has a plus: "x to y+ year" or "x - y+ year" ---
	replace req_exp_min = real(ustrregexs(1)) ///
		if missing(req_exp_min) & ustrregexm(req_exp_clean, "\b([0-9]+(\.[0-9]+)?)\s*(to|-)\s*([0-9]+(\.[0-9]+)?)\+\s*year\b")
	replace req_exp_max = real(ustrregexs(4)) ///
		if missing(req_exp_max) & ustrregexm(req_exp_clean, "\b([0-9]+(\.[0-9]+)?)\s*(to|-)\s*([0-9]+(\.[0-9]+)?)\+\s*year\b")

	*==================================================
	* 4) Open-ended lower bounds seen in data
	*    "x+ year" / "x year+" / "at least x year"
	*    "minimum x year" / "x year minimum" / "x year above"
	*    "x year or more" / "over x year"
	*    -> min = x, max = .
	*==================================================
	
	replace req_exp_min = real(regexs(1)) if missing(req_exp_min) & ///
		( regexm(req_exp_clean, "\b([0-9]+(\.[0-9]+)?)\s*\+\s*year\b") ///
		| regexm(req_exp_clean, "\b([0-9]+(\.[0-9]+)?)\s*year\s*\+\b") ///
		| regexm(req_exp_clean, "\bat least\s*([0-9]+(\.[0-9]+)?)\s*year\b") ///
		| regexm(req_exp_clean, "\bminimum\s*([0-9]+(\.[0-9]+)?)\s*year\b") ///
		| regexm(req_exp_clean, "\b([0-9]+(\.[0-9]+)?)\s*year\s*minimum\b") ///
		| regexm(req_exp_clean, "\b([0-9]+(\.[0-9]+)?)\s*year\s*or more\b") ///
		| regexm(req_exp_clean, "\bover\s*([0-9]+(\.[0-9]+)?)\s*year\b") ///
		| regexm(req_exp_clean, "\b([0-9]+(\.[0-9]+)?)\s*year\s*above\b") )
		
	* --- Open-ended lower bounds with 'year'
	replace req_exp_min = real(ustrregexs(1)) if missing(req_exp_min) & ///
		ustrregexm(req_exp_clean, "\b0*([0-9]+(?:\.[0-9]+)?)\s*\+\s*years?\b")

	replace req_exp_min = real(ustrregexs(1)) if missing(req_exp_min) & ///
		ustrregexm(req_exp_clean, "\b0*([0-9]+(?:\.[0-9]+)?)\s*years?\s*\+\b")

	* --- Bare open-ended: 'x+'
	replace req_exp_min = real(ustrregexs(1)) if missing(req_exp_min) & ///
		ustrregexm(req_exp_clean, "^\s*0*([0-9]+(?:\.[0-9]+)?)\s*\+\s*$")

	* --- Life-cycle phrasing: '3 (at least 01 life cycle)' -> 3–3 ---
	replace req_exp_min = real(ustrregexs(1)) if missing(req_exp_min) & ///
		ustrregexm(req_exp_clean, "^\s*0*([0-9]+(?:\.[0-9]+)?)\s*\((?:[^)]*life\s*cycle[^)]*)\)\s*$")

	replace req_exp_max = req_exp_min if missing(req_exp_max) & req_exp_min<. & ///
		ustrregexm(req_exp_clean, "life\s*cycle")
		
	replace req_exp_max = . if req_exp_clean == "1 year+" ///
	| req_exp_clean == "minimum of 10 year of experience in sales of herbal medicines nutraceutical and pharma." ///
	| req_exp_clean == "minimum 10 year of sales experience in fmcg. natural medicine experience would be as advantage."

	*==================================================
	* 5) Single year values seen in data (incl. "3-year")
	*    After normalization above, these reduce to "x year"
	*==================================================
	
	replace req_exp_min = real(regexs(1)) ///
		if missing(req_exp_min) & regexm(req_exp_clean, "\b([0-9]+(\.[0-9]+)?)\s*year\b")
		
	replace req_exp_max = req_exp_min ///
		if missing(req_exp_max) & !missing(req_exp_min) & regexm(req_exp_clean, "\b([0-9]+(\.[0-9]+)?)\s*year\b")
	
	*==================================================
	* 6) Other corrections
	*==================================================
	
	* before: "^\s*(\d+(\.\d+)?)\s*(to|-)\s*(\d+(\.\d+)?)\s*$"
	replace req_exp_min = real(regexs(1)) ///
		if missing(req_exp_min) & ///
		regexm(req_exp_clean, "^\s*([0-9]+(\.[0-9]+)?)\s*(to|-)\s*([0-9]+(\.[0-9]+)?)\b(?!\s*(month|months))")
		
	replace req_exp_max = real(regexs(4)) ///
		if missing(req_exp_max) & ///
		regexm(req_exp_clean, "^\s*([0-9]+(\.[0-9]+)?)\s*(to|-)\s*([0-9]+(\.[0-9]+)?)\b(?!\s*(month|months))")
		
	* turn "0 to 1 3" -> "0 to 1-3 year" (or at least "0 to 1-3")
	replace req_exp_clean = ustrregexra(req_exp_clean, "\b0\s*to\s*1\s+3\b", "0 to 1-3")
	replace req_exp_clean = ustrregexra(req_exp_clean, "\b0\s*to\s*1\s+1\b", "0 to 1-1")
	
	replace req_exp_min = real(ustrregexs(1)) ///
		if missing(req_exp_min) & ustrregexm(req_exp_clean, "\b([0-9]+(\.[0-9]+)?)\s+([0-9]+(\.[0-9]+)?)\s*year\b")
		
	replace req_exp_max = real(ustrregexs(3)) ///
		if missing(req_exp_max) & ustrregexm(req_exp_clean, "\b([0-9]+(\.[0-9]+)?)\s+([0-9]+(\.[0-9]+)?)\s*year\b")
			
	replace req_exp_clean = ustrregexra(req_exp_clean, "\bo([0-9]+)\s*year\b", "\1 year")		
	
	* x to y-z  -> min=x, max=z   (no 'year' token)
	replace req_exp_min = real(regexs(1)) ///
		if missing(req_exp_min) & regexm(req_exp_clean, "^\s*([0-9]+(?:\.[0-9]+)?)\s*to\s*([0-9]+(?:\.[0-9]+)?)\s*-\s*([0-9]+(?:\.[0-9]+)?)\s*$")
	replace req_exp_max = real(regexs(3)) ///
		if missing(req_exp_max) & regexm(req_exp_clean, "^\s*([0-9]+(?:\.[0-9]+)?)\s*to\s*([0-9]+(?:\.[0-9]+)?)\s*-\s*([0-9]+(?:\.[0-9]+)?)\s*$")
		
	* Promote "x to y-z" -> min=x, max=z even if min/max already set earlier
	replace req_exp_max = real(regexs(3)) if ///
		regexm(req_exp_clean, "\b([0-9]+(?:\.[0-9]+)?)\s*to\s*([0-9]+(?:\.[0-9]+)?)\s*-\s*([0-9]+(?:\.[0-9]+)?)\b")
	replace req_exp_min = real(regexs(1)) if ///
		regexm(req_exp_clean, "\b([0-9]+(?:\.[0-9]+)?)\s*to\s*([0-9]+(?:\.[0-9]+)?)\s*-\s*([0-9]+(?:\.[0-9]+)?)\b")
				
	* Extract both sides when RHS has 'year' and LHS is bare number (inverted cases)
	capture drop __l __r
	gen double __l = real(regexs(1)) if regexm(req_exp_clean, "^\s*([0-9]+(?:\.[0-9]+)?)\s*-\s*([0-9]+(?:\.[0-9]+)?)\s*year\b")
	gen double __r = real(regexs(2)) if regexm(req_exp_clean, "^\s*([0-9]+(?:\.[0-9]+)?)\s*-\s*([0-9]+(?:\.[0-9]+)?)\s*year\b")

	replace req_exp_min = cond(__l<=__r, __l, __r) if __l<. & __r<.
	replace req_exp_max = cond(__l<=__r, __r, __l) if __l<. & __r<.

	drop __l __r

	* single numeric-only value -> x–x
	replace req_exp_min = real(req_exp_clean) ///
		if missing(req_exp_min) & regexm(req_exp_clean, "^\s*[0-9]+(\.[0-9]+)?\s*$")
	replace req_exp_max = req_exp_min ///
		if missing(req_exp_max) & !missing(req_exp_min) & regexm(req_exp_clean, "^\s*[0-9]+(\.[0-9]+)?\s*$")

	* Checks
	tab req_exp_clean if missing(req_exp_min) & missing(req_exp_max)
	
*--- Job–skills: counts by importance (0–2) and merge -------------------------

	preserve
		use "$created/jobs_skills_ha.dta", clear
		keep job_id skill_importance
		drop if missing(job_id) | missing(skill_importance)

		* keep only 0/1/2 (your tab shows no 3s)
		keep if inrange(skill_importance, 0, 2)

		* counts per job × importance level
		contract job_id skill_importance
		rename _freq n
		rename job_id jid

		* wide layout: one column per importance level
		reshape wide n, i(jid) j(skill_importance)

		* ensure all three level columns exist; fill with 0 if absent
		foreach L of numlist 0/2 {
			capture confirm variable n`L'
			if _rc gen n`L' = 0
		}

		* clearer names + total
		rename n0 job_skillimp0_n
		rename n1 job_skillimp1_n
		rename n2 job_skillimp2_n

		tempfile m_jobskillcounts
		save "`m_jobskillcounts'"
	restore

	* merge onto current jobs data in memory
	merge m:1 jid using "`m_jobskillcounts'", keep(1 3) nogen

	* jobs with no skills get zeros
	foreach v in job_skillimp0_n job_skillimp1_n job_skillimp2_n {
		replace `v' = 0 if missing(`v')
	}
	
	gen     job_skill_n = job_skillimp0_n + job_skillimp1_n + job_skillimp2_n
	
*--------- Order and labels ----------------------------------------------------

    ds
    local allvars `r(varlist)'

    local created ///
        created_dt  created_d  created_yr  created_mo  ///
        updated_dt  updated_d  updated_yr  updated_mo  ///
        published_dt published_d published_yr published_mo ///
        apply_by_dt apply_by_d apply_by_yr apply_by_mo ///
        hide_salary_num manage_employees_num subordinates_num max_budget_num ///
        req_exp_clean req_exp_min req_exp_max ///
		job_skillimp0_n job_skillimp1_n job_skillimp2_n job_skill_n

    local origvars : list allvars - created

    gen    _ORIGINAL_____________ = .
    gen    _CREATED_________      = .

    order  _ORIGINAL_____________ `origvars' _CREATED_________ `created'

    label var created_dt   				"Record created datetime (%tc)"
    label var created_d    				"Record created date (%td)"
    label var created_yr   				"Record created year"
    label var created_mo   				"Record created month (1–12)"
    label var updated_dt   				"Record updated datetime (%tc)"
    label var updated_d    				"Record updated date (%td)"
    label var updated_yr   				"Record updated year"
    label var updated_mo   				"Record updated month (1–12)"
    label var published_dt 				"Record published datetime (%tc)"
    label var published_d  				"Record published date (%td)"
    label var published_yr 				"Record published year"
    label var published_mo 				"Record published month (1–12)"
    label var apply_by_dt  				"Apply-by datetime (%tc)"
    label var apply_by_d   				"Apply-by date (%td)"
    label var apply_by_yr  				"Apply-by year"
    label var apply_by_mo  				"Apply-by month (1–12)"
    label var hide_salary_num        	"Hide salary? (1=Y, 0=N)"
    label var manage_employees_num   	"Manages employees? (1=Yes, 0=No)"
    label var subordinates_num       	"Subordinates count (numeric)"
    label var max_budget_num         	"Maximum budget (numeric)"
    label var req_exp_clean          	"Required experience (cleaned text)"
    label var req_exp_min            	"Required experience (min years)"
    label var req_exp_max            	"Required experience (max years)"
	label var job_skillimp0_n 			"Skills linked to job (importance = 0)"
	label var job_skillimp1_n 			"Skills linked to job (importance = 1)"
	label var job_skillimp2_n 			"Skills linked to job (importance = 2)"
	label var job_skill_n     			"Skills linked to job (total, importance 0–2)"

*--------- Compress and save ---------------------------------------------------

    compress
    save "$vars/jobs_gpt_vars_creation.dta", replace	
	
	
************************************************
************************************************
**# APPLICATIONS
************************************************
************************************************

*--- Load -------------------------------------------------------------------

	use "$cleaned/applications_gpt_cleaned.dta", clear

*--- Datetimes ----------------------------------------------------

	* Created at
	gen double 		created_dt = clock(created_at, "YMDhms") if !missing(created_at)
	format %tc 		created_dt
	gen int  		created_d  = dofc(created_dt)
	format %td 		created_d
	gen int  		created_yr = year(created_d)
	gen byte 		created_mo = month(created_d)	
	
*--- Numeric copies ----------------------------------------------------

	destring overall_score, 			gen(overall_score_num)
	destring coding_test_score, 		gen(coding_test_score_num)
	destring video_interview_score, 	gen(video_interview_score_num)
	destring test_score, 				gen(test_score_num)

*--- Skills: count skills per application -------------------------------------

	preserve
		use "$created/application_skills_ha.dta", clear   // rows: one skill per application_id
		keep application_id skill_id

		contract application_id skill_id              // unique pairs
		bys application_id: gen skillcount = _N
		keep application_id skillcount
		by application_id: keep if _n==1

		tempfile m_skillcount
		save "`m_skillcount'"
	restore

	merge 1:1 application_id using "`m_skillcount'", keep(1 3) nogen	
	
*--------- Order and labels ----------------------------------------------------

ds
local allvars `r(varlist)'

* vars created in this do-file (numeric copies + datetimes + aggregates)
local created ///
    created_dt  created_d  created_yr  created_mo ///
    test_score_num video_interview_score_num coding_test_score_num overall_score_num ///
    skillcount

local origvars : list allvars - created

gen    _ORIGINAL_____________ = .
gen    _CREATED_________      = .

order  _ORIGINAL_____________ `origvars' _CREATED_________ `created'

label var created_dt                "Record created datetime (%tc)"
label var created_d                 "Record created date (%td)"
label var created_yr                "Record created year"
label var created_mo                "Record created month (1–12)"
label var test_score_num            "Test score (numeric)"
label var video_interview_score_num "Video interview score (numeric)"
label var coding_test_score_num     "Coding test score (numeric)"
label var overall_score_num         "Overall score (numeric)"
label var skillcount                "Skills linked to application (count)"

*--------- Compress and save ---------------------------------------------------

compress
save "$vars/applications_gpt_vars_creation.dta", replace
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	