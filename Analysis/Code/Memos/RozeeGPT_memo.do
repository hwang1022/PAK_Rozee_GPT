
/*======================================================================*
 |  Project:    Rozee 
 |  Author:     AB
 |  File: 		Exploratory analysis on RozeeGPT data
 *======================================================================*/
 
**********************
**# Packages
**********************

	local packagelist wbopendata ietoolkit estout
	foreach package in `packagelist' {
		quietly which `package'
		if _rc ssc install `package'
	}

***********
**# Setup
***********

	ieboilstart, versionnumber(18.0)
	`r(version)'

*********************
**# Set Directories
*********************

	if c(username) == "abrockell" {
		
		global dir "/Users/abrockell/Library/CloudStorage/Dropbox-HarvardUniversity/Alec Brockell/PAK_Rozee_GPT"
	
	}
	
	else if c(username) == "lalfonsi" {
		
		global dir "/Users/lalfonsi/Harvard University Dropbox/Livia Alfonsi/Research/PAK_Rozee_GPT"	
		
	}
	
	global  cleaned  	"$dir/Data/Cleaned/RozeeGPT/251017_Cleaned_RozeeGPT"
	global  vars     	"$dir/Data/Analysis/RozeeGPT/251017_Vars_Created_RozeeGPT"
	global  tex    		"$dir/Tex/Aux/RozeeGPT_memo"
	global  inputs 		"$tex/inputs"
	global 	temp 		"$dir/Data/temp"
	
	
************************************************
************************************************
**# USERS
************************************************
************************************************

*==========================
* USERS: Original variables
*==========================

	preserve
		use "$cleaned/users_gpt_cleaned.dta", clear

		local users_orig_vars ///
			user_id user_type full_name seeker_type gender city_name country_id ///
			dob experience current_salary created_at last_login

		local N = _N
		local k : word count `users_orig_vars'
		matrix M = J(`k', 2, .)
		matrix rownames M = `users_orig_vars'
		matrix colnames M = Missing_N Missing_pct

		local vl ""
		local i = 0
		foreach v of local users_orig_vars {
			local ++i

			* type via storage/format
			local stype : type `v'
			local fmt   : format `v'
			local dtype "numeric"
			if strpos("`fmt'","%td")      local dtype "\%td"
			else if strpos("`fmt'","%tc") local dtype "\%tc"
			else if substr("`stype'",1,3)=="str" local dtype "string"

			* label (fallback)
			local lab : variable label `v'
			if `"`lab'"' == "" local lab "`v'"

			* missingness
			if (substr("`stype'",1,3)=="str") quietly count if ustrtrim(`v')==""
			else                               quietly count if missing(`v')
			local nmiss = r(N)
			local pmiss = cond(`N'>0, round(100*`nmiss'/`N',0.1), .)

			matrix M[`i',1] = `nmiss'
			matrix M[`i',2] = `pmiss'

			* make 3 label cells (Variable & Type & Description)
			local tdisp = cond(substr("`stype'",1,3)=="str","String (`stype')","Numeric (`stype')")
			local pretty "`v' & `tdisp' & `lab'"
			local vl `"`vl' `v' "`pretty'""'
		}

		local NL = char(10)
		esttab matrix(M) using "$inputs/users_original_vars.tex", replace fragment booktabs ///
			nomtitles nonumber noobs collabels(none) ///
			title("Users: Original variables (from \texttt{users\_gpt\_cleaned.dta})") ///
			varlabels(`vl') ///
			prehead("\begin{threeparttable}" `NL' "\begin{tabular}{@{}lllrr@{}}" `NL' "\toprule" `NL' ///
					"\textbf{Variable} & \textbf{Type} & \textbf{Description} & \textbf{Missing (N)} & \textbf{Missing (\%)} \\" `NL' "\midrule" `NL') ///
			postfoot("\bottomrule" `NL' "\end{tabular}" `NL' "\end{threeparttable}")
	restore

*==========================
* USERS: Created variables 
*==========================

	preserve
		use "$vars/users_gpt_vars_creation.dta", clear

		local users_created_vars ///
			country_id_num countryname ///
			dob_d age skillcount ///
			created_tc created_d created_yr ///
			lastlogin_tc lastlogin_d lastlogin_yr ///
			cursal_pkr cursal_usd_ppp

		local N = _N
		local k : word count `users_created_vars'
		matrix M2 = J(`k', 2, .)
		matrix rownames M2 = `users_created_vars'
		matrix colnames M2 = Missing_N Missing_pct

		local vl2 ""
		local i = 0
		foreach v of local users_created_vars {
			local ++i

			local stype : type `v'
			local fmt   : format `v'
			local dtype "numeric"
			if strpos("`fmt'","%td")      local dtype "\%td"
			else if strpos("`fmt'","%tc") local dtype "\%tc"
			else if substr("`stype'",1,3)=="str" local dtype "string"

			local lab : variable label `v'
			if `"`lab'"' == "" local lab "`v'"
			local lab_esc = subinstr("`lab'","%","\%",.)   // <-- add backslash before %

			if (substr("`stype'",1,3)=="str") quietly count if ustrtrim(`v')==""
			else                               quietly count if missing(`v')
			local nmiss = r(N)
			local pmiss = cond(`N'>0, round(100*`nmiss'/`N',0.1), .)

			matrix M2[`i',1] = `nmiss'
			matrix M2[`i',2] = `pmiss'

			local tdisp = cond(substr("`stype'",1,3)=="str","String (`stype')","Numeric (`stype')")
			local pretty "`v' & `tdisp' & `lab_esc'"
			local vl2 `"`vl2' `v' "`pretty'""'
		}

		local NL = char(10)
		esttab matrix(M2) using "$inputs/users_created_vars.tex", replace fragment booktabs ///
			nomtitles nonumber noobs collabels(none) ///
			title("Users: Created variables (from \texttt{users\_gpt\_vars\_creation.dta})") ///
			varlabels(`vl2') ///
			prehead("\begin{threeparttable}" `NL' "\begin{tabular}{@{}lllrr@{}}" `NL' "\toprule" `NL' ///
					"\textbf{Variable} & \textbf{Type} & \textbf{Description} & \textbf{Missing (N)} & \textbf{Missing (\%)} \\" `NL' "\midrule" `NL') ///
			postfoot("\bottomrule" `NL' "\end{tabular}" `NL' "\end{threeparttable}")
	restore

*==============================
* USERS: Total and Key Missing 
*==============================

    *--- Load
    use "$cleaned/users_gpt_cleaned.dta", clear

    *--- Count missing across ALL variables in the dataset
    gen int total_miss = 0

    ds, has(type numeric)
    foreach v of varlist `r(varlist)' {
        replace total_miss = total_miss + missing(`v')
    }

    ds, has(type string)
    foreach v of varlist `r(varlist)' {
        replace total_miss = total_miss + (ustrtrim(`v') == "")
    }

    *--- Count missing across KEY variables only
    gen int key_miss = 0
    local key_list gender dob experience

    foreach v of local key_list {
        capture confirm variable `v'
        if !_rc {
            local stype : type `v'
            if substr("`stype'",1,3) == "str" {
                replace key_miss = key_miss + (ustrtrim(`v') == "")
            }
            else {
                replace key_miss = key_miss + missing(`v')
            }
        }
    }

    *--- Sanity checks
    tab total_miss
    tab key_miss

    *--- newline helper for LaTeX headers/footers
    local NL = char(10)

    *--- LaTeX table: distribution of total_miss
    preserve
        estpost tabulate total_miss, nototal
        esttab using "$inputs/users_total_miss.tex", replace fragment booktabs ///
            nomtitles nonumber noobs collabels(none) ///
            cells("b(fmt(0)) pct(fmt(1))") ///
            prehead("\begin{threeparttable}" `NL' ///
                    "\begin{tabular}{@{}lrr@{}}" `NL' "\toprule" `NL' ///
                    "\textbf{Missing values per row} & \textbf{N} & \textbf{\%} \\" `NL' "\midrule" `NL') ///
            postfoot("\bottomrule" `NL' "\end{tabular}" `NL' "\end{threeparttable}")
    restore

    *--- LaTeX table: distribution of key_miss
    preserve
        estpost tabulate key_miss, nototal
        esttab using "$inputs/users_key_miss.tex", replace fragment booktabs ///
            nomtitles nonumber noobs collabels(none) ///
            cells("b(fmt(0)) pct(fmt(1))") ///
            prehead("\begin{threeparttable}" `NL' ///
                    "\begin{tabular}{@{}lrr@{}}" `NL' "\toprule" `NL' ///
                    "\textbf{Missing key values per row} & \textbf{N} & \textbf{\%} \\" `NL' "\midrule" `NL') ///
            postfoot("\bottomrule" `NL' "\end{tabular}" `NL' "\end{threeparttable}")
    restore
		
************************************************
**# DESCRIPTIVES
************************************************	

	use "$vars/users_gpt_vars_creation.dta", clear
	local NL = char(10)


	*---- AGE: bar chart of counts by single year (40+ bucket) ----------------
	preserve
		keep age

		quietly count
		local N_all   = r(N)
		drop if missing(age)
		quietly count
		local N_used  = r(N)
		local N_miss  = `N_all' - `N_used'
		local N_used_fmt  : display %12.0gc `N_used'
		local N_miss_fmt  : display %12.0gc `N_miss'

		gen age_top = age
		replace age_top = 40 if age_top >= 40
		label define ageb 40 "40+", replace
		label values age_top ageb

		contract age_top, freq(N)
		sort age_top

		set scheme s1mono
		twoway ///
			(bar N age_top, barwidth(0.9)), ///
			xlabel(15(5)35 40, labsize(small)) ///
			xtitle("Age (years)") ///
			ylabel(, grid labsize(small)) ///
			ytitle("Users (count)") ///
			title("Users: Age (14–39 by year; 40+ bucketed)", size(large)) ///
			subtitle(" ") ///
			note("N = `N_used_fmt'; Missing = `N_miss_fmt'", size(small)) ///
			legend(off) ///
			xsize(10) ysize(6)

		graph export "$inputs/fig_users_age_counts_vars.pdf", as(pdf) replace
	restore


	*---- COUNTRY: composition table (Pakistan / Non-Pakistan) ----------------
	preserve
		keep countryname
		replace countryname = ustrtrim(countryname)

		quietly count
		local N_all   = r(N)
		drop if missing(countryname) | countryname==""
		quietly count
		local N_used  = r(N)
		local N_miss  = `N_all' - `N_used'
		local N_used_fmt : display %12.0gc `N_used'
		local N_miss_fmt : display %12.0gc `N_miss'

		gen str20 _countrygrp = cond(countryname=="Pakistan","Pakistan","Non-Pakistan")

		estpost tab _countrygrp, nototal
		esttab using "$inputs/tab_users_country_vars.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' "\toprule" `NL' " & N & \% of total \\" `NL' "\midrule" `NL' "\multicolumn{3}{l}{\textbf{Country}}\\ ") ///
			postfoot("\midrule" `NL' "\multicolumn{3}{l}{\footnotesize N = `N_used_fmt'; Missing = `N_miss_fmt'}\\" `NL' "\bottomrule" `NL' "\end{tabular}" `NL')
	restore


	*---- SKILLCOUNT: composition table (0,1–5,6–10,11–15,16–20,21–30,31+) ----
	preserve
		keep skillcount

		quietly count
		local N_all = r(N)
		drop if missing(skillcount) | skillcount < 0
		quietly count
		local N_used  = r(N)
		local N_miss  = `N_all' - `N_used'
		local N_used_fmt : display %12.0gc `N_used'
		local N_miss_fmt : display %12.0gc `N_miss'

		gen str6 _skillgrp = ""
		replace _skillgrp = "0"                if skillcount==0
		replace _skillgrp = "1–5"              if inrange(skillcount,1,5)
		replace _skillgrp = "6–10"             if inrange(skillcount,6,10)
		replace _skillgrp = "11–15"            if inrange(skillcount,11,15)
		replace _skillgrp = "16–20"            if inrange(skillcount,16,20)
		replace _skillgrp = "21–30"            if inrange(skillcount,21,30)
		replace _skillgrp = "31+"              if skillcount>30

		estpost tab _skillgrp, nototal
		esttab using "$inputs/tab_users_skillcount_vars.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' "\toprule" `NL' " & N & \% of total \\" `NL' "\midrule" `NL' "\multicolumn{3}{l}{\textbf{Skills listed}}\\ ") ///
			postfoot("\midrule" `NL' "\multicolumn{3}{l}{\footnotesize N = `N_used_fmt'; Missing = `N_miss_fmt'}\\" `NL' "\bottomrule" `NL' "\end{tabular}" `NL')
	restore


	*---- CREATED YEAR: composition table -------------------------------------
	preserve
		keep created_yr

		quietly count
		local N_all = r(N)
		drop if missing(created_yr)
		quietly count
		local N_used  = r(N)
		local N_miss  = `N_all' - `N_used'
		local N_used_fmt : display %12.0gc `N_used'
		local N_miss_fmt : display %12.0gc `N_miss'

		estpost tab created_yr, nototal
		esttab using "$inputs/tab_users_created_year_vars.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' "\toprule" `NL' " & N & \% of total \\" `NL' "\midrule" `NL' "\multicolumn{3}{l}{\textbf{Account created (year)}}\\ ") ///
			postfoot("\midrule" `NL' "\multicolumn{3}{l}{\footnotesize N = `N_used_fmt'; Missing = `N_miss_fmt'}\\" `NL' "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

	*---- SALARY SUMMARY (PKR only) -------------------------------------------
	preserve
		keep cursal_pkr

		* counts (tabstat drops missings automatically)
		quietly count
		local N_all = r(N)
		quietly count if !missing(cursal_pkr)
		local N_cpk = r(N)
		local M_cpk = `N_all' - `N_cpk'
		local N_cpk_fmt : display %12.0gc `N_cpk'
		local M_cpk_fmt : display %12.0gc `M_cpk'

		label var cursal_pkr "Current salary (PKR)"

		estpost tabstat cursal_pkr, statistics(mean p5 p25 p50 p75 p95) columns(statistics)

		esttab using "$inputs/tab_users_salary_summary_vars.tex", ///
			cells("mean(fmt(%12.2fc)) p5(fmt(%12.2fc)) p25(fmt(%12.2fc)) p50(fmt(%12.2fc)) p75(fmt(%12.2fc)) p95(fmt(%12.2fc))") ///
			collabels("Mean" "p5" "p25" "p50" "p75" "p95") ///
			label nonumber noobs nomtitle booktabs fragment replace ///
			prehead("\begin{tabular}{lrrrrrrrr}" `NL' "\toprule" `NL') ///
			posthead("") ///
			postfoot("\bottomrule" `NL' "\multicolumn{8}{l}{\footnotesize N (PKR) = `N_cpk_fmt'; Missing (PKR) = `M_cpk_fmt'}\\" `NL' "\end{tabular}" `NL')
	restore
			
************************************************
************************************************
**# COMPANIES
************************************************
************************************************

*==============================
* COMPANIES: Original variables
*==============================

	preserve
		use "$cleaned/companies_gpt_cleaned.dta", clear

		local companies_orig_vars ///
			company_id user_id company_name created_at

		local N = _N
		local k : word count `companies_orig_vars'
		matrix M = J(`k', 2, .)
		matrix rownames M = `companies_orig_vars'
		matrix colnames M = Missing_N Missing_pct

		local vl ""
		local i = 0
		foreach v of local companies_orig_vars {
			local ++i

			* type via storage/format
			local stype : type `v'
			local fmt   : format `v'
			local dtype "numeric"
			if strpos("`fmt'","%td")      local dtype "\%td"
			else if strpos("`fmt'","%tc") local dtype "\%tc"
			else if substr("`stype'",1,3)=="str" local dtype "string"

			* label (fallback) + escape % for LaTeX
			local lab : variable label `v'
			if `"`lab'"' == "" local lab "`v'"
			local lab_esc = subinstr("`lab'","%","\%",.)

			* missingness
			if (substr("`stype'",1,3)=="str") quietly count if ustrtrim(`v')==""
			else                               quietly count if missing(`v')
			local nmiss = r(N)
			local pmiss = cond(`N'>0, round(100*`nmiss'/`N',0.1), .)

			matrix M[`i',1] = `nmiss'
			matrix M[`i',2] = `pmiss'

			* make 3 label cells (Variable & Type & Description)
			local tdisp = cond(substr("`stype'",1,3)=="str","String (`stype')","Numeric (`stype')")
			local pretty "`v' & `tdisp' & `lab_esc'"
			local vl `"`vl' `v' "`pretty'""'
		}

		local NL = char(10)
		esttab matrix(M) using "$inputs/companies_original_vars.tex", replace fragment booktabs ///
			nomtitles nonumber noobs collabels(none) ///
			title("Companies: Original variables (from \texttt{companies\_gpt\_cleaned.dta})") ///
			varlabels(`vl') ///
			prehead("\begin{threeparttable}" `NL' "\begin{tabular}{@{}lllrr@{}}" `NL' "\toprule" `NL' ///
					"\textbf{Variable} & \textbf{Type} & \textbf{Description} & \textbf{Missing (N)} & \textbf{Missing (\%)} \\" `NL' "\midrule" `NL') ///
			postfoot("\bottomrule" `NL' "\end{tabular}" `NL' "\end{threeparttable}")
	restore

*==============================
* COMPANIES: Created variables 
*==============================

	preserve
		use "$vars/companies_gpt_vars_creation.dta", clear

		* Only created variables per codebook
		local companies_created_vars ///
			created_dt created_d created_yr created_mo

		local N = _N
		local k : word count `companies_created_vars'
		matrix M2 = J(`k', 2, .)
		matrix rownames M2 = `companies_created_vars'
		matrix colnames M2 = Missing_N Missing_pct

		local vl2 ""
		local i = 0
		foreach v of local companies_created_vars {
			local ++i

			local stype : type `v'
			local fmt   : format `v'
			local dtype "numeric"
			if strpos("`fmt'","%td")      local dtype "\%td"
			else if strpos("`fmt'","%tc") local dtype "\%tc"
			else if substr("`stype'",1,3)=="str" local dtype "string"

			local lab : variable label `v'
			if `"`lab'"' == "" local lab "`v'"
			local lab_esc = subinstr("`lab'","%","\%",.)

			if (substr("`stype'",1,3)=="str") quietly count if ustrtrim(`v')==""
			else                               quietly count if missing(`v')
			local nmiss = r(N)
			local pmiss = cond(`N'>0, round(100*`nmiss'/`N',0.1), .)

			matrix M2[`i',1] = `nmiss'
			matrix M2[`i',2] = `pmiss'

			local tdisp = cond(substr("`stype'",1,3)=="str","String (`stype')","Numeric (`stype')")
			local pretty "`v' & `tdisp' & `lab_esc'"
			local vl2 `"`vl2' `v' "`pretty'""'
		}

		local NL = char(10)
		esttab matrix(M2) using "$inputs/companies_created_vars.tex", replace fragment booktabs ///
			nomtitles nonumber noobs collabels(none) ///
			title("Companies: Created variables (from \texttt{companies\_gpt\_vars\_creation.dta})") ///
			varlabels(`vl2') ///
			prehead("\begin{threeparttable}" `NL' "\begin{tabular}{@{}lllrr@{}}" `NL' "\toprule" `NL' ///
					"\textbf{Variable} & \textbf{Type} & \textbf{Description} & \textbf{Missing (N)} & \textbf{Missing (\%)} \\" `NL' "\midrule" `NL') ///
			postfoot("\bottomrule" `NL' "\end{tabular}" `NL' "\end{threeparttable}")
	restore

*=========================================
* COMPANIES: Total Missing 
*=========================================

	preserve
		use "$cleaned/companies_gpt_cleaned.dta", clear

		gen int total_miss = 0
		local orig4 company_id user_id company_name created_at

		foreach v of local orig4 {
			capture confirm variable `v'
			if !_rc {
				local stype : type `v'
				if substr("`stype'",1,3)=="str" {
					replace total_miss = total_miss + (ustrtrim(`v')=="")
				}
				else {
					replace total_miss = total_miss + missing(`v')
				}
			}
		}

		* tabulate distribution
		local NL = char(10)
		estpost tabulate total_miss, nototal

		esttab using "$inputs/companies_total_miss.tex", replace fragment booktabs ///
			nomtitles nonumber noobs collabels(none) ///
			cells("b(fmt(0)) pct(fmt(1))") ///
			prehead("\begin{threeparttable}" `NL' ///
					"\begin{tabular}{@{}lrr@{}}" `NL' "\toprule" `NL' ///
					"\textbf{Missing values per row (across 4 originals)} & \textbf{N} & \textbf{\%} \\" `NL' "\midrule" `NL') ///
			postfoot("\bottomrule" `NL' "\end{tabular}" `NL' "\end{threeparttable}")
	restore

************************************************
**# DESCRIPTIVES (Created year only)
************************************************

	preserve
		use "$vars/companies_gpt_vars_creation.dta", clear
		keep created_yr

		quietly count
		local N_all = r(N)
		drop if missing(created_yr)   // omit Unknowns
		quietly count
		local N_used = r(N)
		local N_miss = `N_all' - `N_used'
		local N_used_fmt : display %12.0gc `N_used'
		local N_miss_fmt : display %12.0gc `N_miss'
		local NL = char(10)

		estpost tab created_yr, nototal
		esttab using "$inputs/companies_created_year_vars.tex", replace fragment booktabs ///
			nomtitles nonumber noobs collabels(none) ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			prehead("\begin{tabular}{lrr}" `NL' "\toprule" `NL' " & N & \% of total \\" `NL' "\midrule" `NL' "\multicolumn{3}{l}{\textbf{Record created (year)}}\\ ") ///
			postfoot("\midrule" `NL' "\multicolumn{3}{l}{\footnotesize N = `N_used_fmt'; Missing = `N_miss_fmt'}\\" `NL' "\bottomrule" `NL' "\end{tabular}" `NL')
	restore	

************************************************
************************************************
**# JOBS
************************************************
************************************************

	local NL = char(10)

*==========================
* JOBS: Original variables
*==========================

	preserve
		use "$cleaned/jobs_gpt_cleaned.dta", clear

		local jobs_orig_vars ///
			jid user_id title description responsibilities hide_salary required_experience ///
			other_requirements manage_employees subordinates_count maximum_budget other_city ///
			workplace company_id created_at updated_at published_at apply_by deleted_at

		local N = _N
		local k : word count `jobs_orig_vars'
		matrix M = J(`k', 2, .)
		matrix rownames M = `jobs_orig_vars'
		matrix colnames M = Missing_N Missing_pct

		local vl ""
		local i = 0
		foreach v of local jobs_orig_vars {
			local ++i

			* storage/format -> type
			local stype : type `v'
			local fmt   : format `v'
			local dtype "numeric"
			if strpos("`fmt'","%td")      local dtype "\%td"
			else if strpos("`fmt'","%tc") local dtype "\%tc"
			else if substr("`stype'",1,3)=="str" local dtype "string"

			* label (escape %)
			local lab : variable label `v'
			if `"`lab'"' == "" local lab "`v'"
			local lab_esc = subinstr("`lab'","%","\%",.)

			* missingness
			if (substr("`stype'",1,3)=="str") quietly count if ustrtrim(`v')==""
			else                               quietly count if missing(`v')
			local nmiss = r(N)
			local pmiss = cond(`N'>0, round(100*`nmiss'/`N',0.1), .)

			matrix M[`i',1] = `nmiss'
			matrix M[`i',2] = `pmiss'

			* row label cells
			local tdisp = cond(substr("`stype'",1,3)=="str","String (`stype')","Numeric (`stype')")
			local pretty "`v' & `tdisp' & `lab_esc'"
			local vl `"`vl' `v' "`pretty'""'
		}

		esttab matrix(M) using "$inputs/jobs_original_vars.tex", replace fragment booktabs ///
			nomtitles nonumber noobs collabels(none) ///
			title("Jobs: Original variables (from \texttt{jobs\_gpt\_cleaned.dta})") ///
			varlabels(`vl') ///
			prehead("\begin{threeparttable}" `NL' "\begin{tabular}{@{}lllrr@{}}" `NL' "\toprule" `NL' ///
					"\textbf{Variable} & \textbf{Type} & \textbf{Description} & \textbf{Missing (N)} & \textbf{Missing (\%)} \\" `NL' "\midrule" `NL') ///
			postfoot("\bottomrule" `NL' "\end{tabular}" `NL' "\end{threeparttable}")
	restore

*==========================
* JOBS: Created variables
*==========================

	preserve
		use "$vars/jobs_gpt_vars_creation.dta", clear

		local jobs_created_vars ///
			created_dt created_d created_yr created_mo ///
			updated_dt updated_d updated_yr updated_mo ///
			published_dt published_d published_yr published_mo ///
			apply_by_dt apply_by_d apply_by_yr apply_by_mo ///
			hide_salary_num manage_employees_num ///
			subordinates_num max_budget_num ///
			req_exp_clean req_exp_min req_exp_max ///
			job_skillimp0_n job_skillimp1_n job_skillimp2_n job_skill_n

		local N = _N
		local k : word count `jobs_created_vars'
		matrix M2 = J(`k', 2, .)
		matrix rownames M2 = `jobs_created_vars'
		matrix colnames M2 = Missing_N Missing_pct

		local vl2 ""
		local i = 0
		foreach v of local jobs_created_vars {
			local ++i

			local stype : type `v'
			local fmt   : format `v'
			local dtype "numeric"
			if strpos("`fmt'","%td")      local dtype "\%td"
			else if strpos("`fmt'","%tc") local dtype "\%tc"
			else if substr("`stype'",1,3)=="str" local dtype "string"

			local lab : variable label `v'
			if `"`lab'"' == "" local lab "`v'"
			local lab_esc = subinstr("`lab'","%","\%",.)

			if (substr("`stype'",1,3)=="str") quietly count if ustrtrim(`v')==""
			else                               quietly count if missing(`v')
			local nmiss = r(N)
			local pmiss = cond(`N'>0, round(100*`nmiss'/`N',0.1), .)

			matrix M2[`i',1] = `nmiss'
			matrix M2[`i',2] = `pmiss'

			local tdisp = cond(substr("`stype'",1,3)=="str","String (`stype')","Numeric (`stype')")
			local pretty "`v' & `tdisp' & `lab_esc'"
			local vl2 `"`vl2' `v' "`pretty'""'
		}

		esttab matrix(M2) using "$inputs/jobs_created_vars.tex", replace fragment booktabs ///
			nomtitles nonumber noobs collabels(none) ///
			title("Jobs: Created variables (from \texttt{jobs\_gpt\_vars\_creation.dta})") ///
			varlabels(`vl2') ///
			prehead("\begin{threeparttable}" `NL' "\begin{tabular}{@{}lllrr@{}}" `NL' "\toprule" `NL' ///
					"\textbf{Variable} & \textbf{Type} & \textbf{Description} & \textbf{Missing (N)} & \textbf{Missing (\%)} \\" `NL' "\midrule" `NL') ///
			postfoot("\bottomrule" `NL' "\end{tabular}" `NL' "\end{threeparttable}")
	restore

************************************************
**# MISSINGNESS (original vars + key vars)
************************************************

	*--- Build total_miss and key_miss once, then emit two tables
	use "$cleaned/jobs_gpt_cleaned.dta", clear

	gen int total_miss = 0
	ds, has(type numeric)
	foreach v of varlist `r(varlist)' {
		replace total_miss = total_miss + missing(`v')
	}
	ds, has(type string)
	foreach v of varlist `r(varlist)' {
		replace total_miss = total_miss + (ustrtrim(`v') == "")
	}

	gen int key_miss = 0
	local key_list company_id title description required_experience maximum_budget 
	foreach v of local key_list {
		capture confirm variable `v'
		if !_rc {
			local stype : type `v'
			if substr("`stype'",1,3) == "str" {
				replace key_miss = key_miss + (ustrtrim(`v') == "")
			}
			else {
				replace key_miss = key_miss + missing(`v')
			}
		}
	}

	preserve
		estpost tabulate total_miss, nototal
		esttab using "$inputs/jobs_total_miss.tex", replace fragment booktabs ///
			nomtitles nonumber noobs collabels(none) ///
			cells("b(fmt(0)) pct(fmt(1))") ///
			prehead("\begin{threeparttable}" `NL' "\begin{tabular}{@{}lrr@{}}" `NL' "\toprule" `NL' ///
					"\textbf{Missing values per row} & \textbf{N} & \textbf{\%} \\" `NL' "\midrule" `NL') ///
			postfoot("\bottomrule" `NL' "\end{tabular}" `NL' "\end{threeparttable}")
	restore

	preserve
		estpost tabulate key_miss, nototal
		esttab using "$inputs/jobs_key_miss.tex", replace fragment booktabs ///
			nomtitles nonumber noobs collabels(none) ///
			cells("b(fmt(0)) pct(fmt(1))") ///
			prehead("\begin{threeparttable}" `NL' "\begin{tabular}{@{}lrr@{}}" `NL' "\toprule" `NL' ///
					"\textbf{Missing key values per row} & \textbf{N} & \textbf{\%} \\" `NL' "\midrule" `NL') ///
			postfoot("\bottomrule" `NL' "\end{tabular}" `NL' "\end{threeparttable}")
	restore

************************************************
**# DESCRIPTIVES
************************************************

	use "$vars/jobs_gpt_vars_creation.dta", clear

*----------------------------------------------*
* (1) Maximum budget buckets (with tail bin)
*----------------------------------------------*

	preserve
		keep max_budget_num
		quietly count
		local N_all = r(N)
		drop if missing(max_budget_num)
		quietly count
		local N_used = r(N)
		local N_miss = `N_all' - `N_used'
		local N_used_fmt : display %12.0gc `N_used'
		local N_miss_fmt : display %12.0gc `N_miss'

		gen byte bucket = .
		replace bucket = 1 if max_budget_num==0
		replace bucket = 2 if inrange(max_budget_num,     1,  49999)
		replace bucket = 3 if inrange(max_budget_num,  50000,  99999)
		replace bucket = 4 if inrange(max_budget_num, 100000, 199999)
		replace bucket = 5 if inrange(max_budget_num, 200000, 499999)
		replace bucket = 6 if inrange(max_budget_num, 500000, 999999)
		replace bucket = 7 if inrange(max_budget_num,1000000, 4999999)
		replace bucket = 8 if max_budget_num>=5000000

		label define mb 1 "0" 2 "1–49,999" 3 "50,000–99,999" 4 "100,000–199,999" ///
			5 "200,000–499,999" 6 "500,000–999,999" 7 "1,000,000–4,999,999" 8 "5,000,000+"
		label values bucket mb

		* Use estpost tab to keep labeled categories as row names (and preserve order)
		estpost tab bucket, nototal

		local NL = char(10)
		esttab using "$inputs/tab_jobs_max_budget_num.tex", replace fragment booktabs ///
			nonumber nomtitles noobs collabels(none) ///
			cells("b(fmt(0)) pct(fmt(2))") ///
			prehead("\begin{tabular}{lrr}" `NL' "\toprule" `NL' ///
					" & N & \% of total \\" `NL' "\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Maximum budget (PKR)}}\\ " `NL') ///
			postfoot("\midrule" `NL' "\multicolumn{3}{l}{\footnotesize N = `N_used_fmt'; Missing = `N_miss_fmt'}\\" `NL' "\bottomrule" `NL' "\end{tabular}")
	restore

*------------------------------------------------------*
* (2) Required experience: overlapping MIN vs MAX
*     (bucket to integers; 20 = 20+)
*------------------------------------------------------*

	preserve
		keep req_exp_min req_exp_max
		* ----- MIN -----
		quietly count
		local N_all_min = r(N)
		drop if missing(req_exp_min)
		quietly count
		local N_used_min = r(N)
		local N_miss_min = `N_all_min' - `N_used_min'
		tempfile _tmp
		save "`_tmp'", replace

		gen double _emin = req_exp_min
		replace _emin = 20 if _emin>20     // 20+ bucket
		contract _emin, freq(Nmin)
		sort _emin
		label define e20 20 "20+"
		label values _emin e20

		set scheme s1mono
		twoway ///
			(bar Nmin _emin, barw(0.9)), ///
			xlabel(0(1)10 15 20, labsize(small)) ///
			xtitle("Required experience (years; 20+ bucketed)") ///
			ylabel(, grid labsize(small)) ///
			ytitle("Jobs (count)") ///
			title("Jobs: Required experience — MIN", size(large)) ///
			note("N_min = `=string(`N_used_min', "%12.0gc")'; Missing_min = `=string(`N_miss_min', "%12.0gc")'", size(small)) ///
			legend(off)
		graph save "$inputs/fig_jobs_reqexp_min.gph",replace

		* ----- MAX -----
		use "`_tmp'", clear
		drop if missing(req_exp_max)
		quietly count
		local N_used_max = r(N)
		local N_miss_max = `N_all_min' - `N_used_max'

		gen double _emax = req_exp_max
		replace _emax = 20 if _emax>20
		contract _emax, freq(Nmax)
		sort _emax
		label values _emax e20

		set scheme s1mono
		twoway ///
			(bar Nmax _emax, barw(0.9)), ///
			xlabel(0(1)10 15 20, labsize(small)) ///
			xtitle("Required experience (years; 20+ bucketed)") ///
			ylabel(, grid labsize(small)) ///
			ytitle("Jobs (count)") ///
			title("Jobs: Required experience — MAX", size(large)) ///
			note("N_max = `=string(`N_used_max', "%12.0gc")'; Missing_max = `=string(`N_miss_max', "%12.0gc")'", size(small)) ///
			legend(off)
		graph save "$inputs/fig_jobs_reqexp_max.gph", replace

		* Combine vertically (stacked)
		graph combine "$inputs/fig_jobs_reqexp_min.gph" "$inputs/fig_jobs_reqexp_max.gph", ///
			rows(2) cols(1) imargin(small) ///
			title("Jobs: Required experience — min (top) vs max (bottom)", size(large))
		graph export "$inputs/fig_jobs_reqexp_minmax.pdf", as(pdf) replace
	restore

*----------------------------------------------*
* (3) Subordinates count buckets (tail bin)
*----------------------------------------------*

	preserve
		keep subordinates_num
		quietly count
		local N_all = r(N)
		drop if missing(subordinates_num)
		quietly count
		local N_used = r(N)
		local N_miss = `N_all' - `N_used'
		local N_used_fmt : display %12.0gc `N_used'
		local N_miss_fmt : display %12.0gc `N_miss'

		gen byte bucket = .
		replace bucket = 1 if subordinates_num==0
		replace bucket = 2 if inrange(subordinates_num,1,4)
		replace bucket = 3 if subordinates_num==5
		replace bucket = 4 if inrange(subordinates_num,6,9)
		replace bucket = 5 if subordinates_num==10
		replace bucket = 6 if inrange(subordinates_num,11,19)
		replace bucket = 7 if subordinates_num==20
		replace bucket = 8 if inrange(subordinates_num,21,49)
		replace bucket = 9 if subordinates_num==50
		replace bucket =10 if inrange(subordinates_num,51,99)
		replace bucket =11 if subordinates_num>=100

		label define sg 1 "0" 2 "1–4" 3 "5" 4 "6–9" 5 "10" 6 "11–19" 7 "20" ///
			8 "21–49" 9 "50" 10 "51–99" 11 "100+"
		label values bucket sg

		estpost tab bucket, nototal

		local NL = char(10)
		esttab using "$inputs/tab_jobs_subordinates_num.tex", replace fragment booktabs ///
			nonumber nomtitles noobs collabels(none) ///
			cells("b(fmt(0)) pct(fmt(2))") ///
			prehead("\begin{tabular}{lrr}" `NL' "\toprule" `NL' ///
					" & N & \% of total \\" `NL' "\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Subordinates count}}\\ " `NL') ///
			postfoot("\midrule" `NL' "\multicolumn{3}{l}{\footnotesize N = `N_used_fmt'; Missing = `N_miss_fmt'}\\" `NL' "\bottomrule" `NL' "\end{tabular}")
	restore

*----------------------------------------------*
* (4) Skills linked to job: total (tail bin)
*----------------------------------------------*

	preserve
		keep job_skill_n
		quietly count
		local N_all = r(N)
		drop if missing(job_skill_n)
		quietly count
		local N_used = r(N)
		local N_miss = `N_all' - `N_used'
		local N_used_fmt : display %12.0gc `N_used'
		local N_miss_fmt : display %12.0gc `N_miss'

		gen byte bucket = .
		replace bucket = 1 if job_skill_n==0
		replace bucket = 2 if inrange(job_skill_n,1,5)
		replace bucket = 3 if inrange(job_skill_n,6,10)
		replace bucket = 4 if inrange(job_skill_n,11,15)
		replace bucket = 5 if inrange(job_skill_n,16,20)
		replace bucket = 6 if job_skill_n>=21

		label define ks 1 "0" 2 "1–5" 3 "6–10" 4 "11–15" 5 "16–20" 6 "21+"
		label values bucket ks

		estpost tab bucket, nototal

		local NL = char(10)
		esttab using "$inputs/tab_jobs_job_skill_n.tex", replace fragment booktabs ///
			nonumber nomtitles noobs collabels(none) ///
			cells("b(fmt(0)) pct(fmt(2))") ///
			prehead("\begin{tabular}{lrr}" `NL' "\toprule" `NL' ///
					" & N & \% of total \\" `NL' "\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Skills linked to job (total)}}\\ " `NL') ///
			postfoot("\midrule" `NL' "\multicolumn{3}{l}{\footnotesize N = `N_used_fmt'; Missing = `N_miss_fmt'}\\" `NL' "\bottomrule" `NL' "\end{tabular}")
	restore

*--------------------------------------------------------------*
* (5) By Month/Year: Created, Updated, Published, Apply-by
*     (4 separate plots — no helper program)
*--------------------------------------------------------------*

	* Created by month
	preserve
		keep created_yr created_mo
		quietly count
		local N_all = r(N)
		drop if missing(created_yr) | missing(created_mo)
		quietly count
		local N_used = r(N)
		local N_miss = `N_all' - `N_used'
		local N_used_fmt : display %12.0gc `N_used'
		local N_miss_fmt : display %12.0gc `N_miss'

		gen int ym = ym(created_yr, created_mo)
		format ym %tm
		contract ym, freq(N)
		sort ym

		set scheme s1mono
		twoway (bar N ym, barwidth(0.9)), ///
			xtitle("Year-Month") ///
			xlabel(, angle(45) labsize(small)) ///
			ylabel(, grid labsize(small) format(%9.0fc)) ///
			ytitle("Jobs (count)") ///
			title("Jobs: Created by month", size(large)) ///
			subtitle(" ") ///
			note("N = `N_used_fmt'; Missing = `N_miss_fmt'", size(vsmall)) ///
			xsize(10) ysize(6)

		graph export "$inputs/fig_jobs_created_by_month.pdf", as(pdf) replace
	restore

	* Updated by month
	preserve
		keep updated_yr updated_mo
		quietly count
		local N_all = r(N)
		drop if missing(updated_yr) | missing(updated_mo)
		quietly count
		local N_used = r(N)
		local N_miss = `N_all' - `N_used'
		local N_used_fmt : display %12.0gc `N_used'
		local N_miss_fmt : display %12.0gc `N_miss'

		gen int ym = ym(updated_yr, updated_mo)
		format ym %tm
		contract ym, freq(N)
		sort ym

		set scheme s1mono
		twoway (bar N ym, barwidth(0.9)), ///
			xtitle("Year-Month") ///
			xlabel(, angle(45) labsize(small)) ///
			ylabel(, grid labsize(small) format(%9.0fc)) ///
			ytitle("Jobs (count)") ///
			title("Jobs: Updated by month", size(large)) ///
			subtitle(" ") ///
			note("N = `N_used_fmt'; Missing = `N_miss_fmt'", size(vsmall)) ///
			xsize(10) ysize(6)

		graph export "$inputs/fig_jobs_updated_by_month.pdf", as(pdf) replace
	restore

	* Published by month
	preserve
		keep published_yr published_mo
		quietly count
		local N_all = r(N)
		drop if missing(published_yr) | missing(published_mo)
		quietly count
		local N_used = r(N)
		local N_miss = `N_all' - `N_used'
		local N_used_fmt : display %12.0gc `N_used'
		local N_miss_fmt : display %12.0gc `N_miss'

		gen int ym = ym(published_yr, published_mo)
		format ym %tm
		contract ym, freq(N)
		sort ym

		set scheme s1mono
		twoway (bar N ym, barwidth(0.9)), ///
			xtitle("Year-Month") ///
			xlabel(, angle(45) labsize(small)) ///
			ylabel(, grid labsize(small) format(%9.0fc)) ///
			ytitle("Jobs (count)") ///
			title("Jobs: Published by month", size(large)) ///
			subtitle(" ") ///
			note("N = `N_used_fmt'; Missing = `N_miss_fmt'", size(vsmall)) ///
			xsize(10) ysize(6)

		graph export "$inputs/fig_jobs_published_by_month.pdf", as(pdf) replace
	restore

	* Apply-by by month
	preserve
		keep apply_by_yr apply_by_mo
		quietly count
		local N_all = r(N)
		drop if missing(apply_by_yr) | missing(apply_by_mo)
		quietly count
		local N_used = r(N)
		local N_miss = `N_all' - `N_used'
		local N_used_fmt : display %12.0gc `N_used'
		local N_miss_fmt : display %12.0gc `N_miss'

		gen int ym = ym(apply_by_yr, apply_by_mo)
		format ym %tm
		contract ym, freq(N)
		sort ym

		set scheme s1mono
		twoway (bar N ym, barwidth(0.9)), ///
			xtitle("Year-Month") ///
			xlabel(, angle(45) labsize(small)) ///
			ylabel(, grid labsize(small) format(%9.0fc)) ///
			ytitle("Jobs (count)") ///
			title("Jobs: Apply-by by month", size(large)) ///
			subtitle(" ") ///
			note("N = `N_used_fmt'; Missing = `N_miss_fmt'", size(vsmall)) ///
			xsize(10) ysize(6)

		graph export "$inputs/fig_jobs_applyby_by_month.pdf", as(pdf) replace
	restore	

************************************************
************************************************
**# APPLICATIONS
************************************************
************************************************
	
*==========================
* Original variables table
*==========================
preserve
    use "$cleaned/applications_gpt_cleaned.dta", clear

    local apps_orig_vars ///
        application_id user_id jid employer_status suggested match_score ///
        matching_reason test_status test_score video_interview_score ///
        coding_test_score overall_score score_status created_at source

    local N = _N
    local k : word count `apps_orig_vars'
    matrix M = J(`k', 2, .)
    matrix rownames M = `apps_orig_vars'
    matrix colnames M = Missing_N Missing_pct

    local vl ""
    local i = 0
    foreach v of local apps_orig_vars {
        local ++i
        local stype : type `v'
        local fmt   : format `v'
        local dtype "numeric"
        if strpos("`fmt'","%td")      local dtype "\%td"
        else if strpos("`fmt'","%tc") local dtype "\%tc"
        else if substr("`stype'",1,3)=="str" local dtype "string"

        local lab : variable label `v'
        if `"`lab'"' == "" local lab "`v'"
        local lab_esc = subinstr("`lab'","%","\%",.)

        if (substr("`stype'",1,3)=="str") quietly count if ustrtrim(`v')==""
        else                               quietly count if missing(`v')
        local nmiss = r(N)
        local pmiss = cond(`N'>0, round(100*`nmiss'/`N',0.1), .)

        matrix M[`i',1] = `nmiss'
        matrix M[`i',2] = `pmiss'

        local tdisp = cond(substr("`stype'",1,3)=="str","String (`stype')","Numeric (`stype')")
        local pretty "`v' & `tdisp' & `lab_esc'"
        local vl `"`vl' `v' "`pretty'""'
    }

    local NL = char(10)
    esttab matrix(M) using "$inputs/applications_original_vars.tex", replace fragment booktabs ///
        nomtitles nonumber noobs collabels(none) ///
        title("Applications: Original variables (from \texttt{applications\_gpt\_cleaned.dta})") ///
        varlabels(`vl') ///
        prehead("\begin{threeparttable}" `NL' "\begin{tabular}{@{}lllrr@{}}" `NL' "\toprule" `NL' ///
                "\textbf{Variable} & \textbf{Type} & \textbf{Description} & \textbf{Missing (N)} & \textbf{Missing (\%)} \\" `NL' "\midrule" `NL') ///
        postfoot("\bottomrule" `NL' "\end{tabular}" `NL' "\end{threeparttable}")
restore


*==========================
* Created variables table
*==========================
preserve
    use "$vars/applications_gpt_vars_creation.dta", clear

    local apps_created_vars ///
        created_dt created_d created_yr created_mo ///
        test_score_num video_interview_score_num coding_test_score_num ///
        overall_score_num skillcount

    local N = _N
    local k : word count `apps_created_vars'
    matrix M2 = J(`k', 2, .)
    matrix rownames M2 = `apps_created_vars'
    matrix colnames M2 = Missing_N Missing_pct

    local vl2 ""
    local i = 0
    foreach v of local apps_created_vars {
        local ++i
        local stype : type `v'
        local fmt   : format `v'
        local dtype "numeric"
        if strpos("`fmt'","%td")      local dtype "\%td"
        else if strpos("`fmt'","%tc") local dtype "\%tc"
        else if substr("`stype'",1,3)=="str" local dtype "string"

        local lab : variable label `v'
        if `"`lab'"' == "" local lab "`v'"
        local lab_esc = subinstr("`lab'","%","\%",.)

        if (substr("`stype'",1,3)=="str") quietly count if ustrtrim(`v')==""
        else                               quietly count if missing(`v')
        local nmiss = r(N)
        local pmiss = cond(`N'>0, round(100*`nmiss'/`N',0.1), .)

        matrix M2[`i',1] = `nmiss'
        matrix M2[`i',2] = `pmiss'

        local tdisp = cond(substr("`stype'",1,3)=="str","String (`stype')","Numeric (`stype')")
        local pretty "`v' & `tdisp' & `lab_esc'"
        local vl2 `"`vl2' `v' "`pretty'""'
    }

    local NL = char(10)
    esttab matrix(M2) using "$inputs/applications_created_vars.tex", replace fragment booktabs ///
        nomtitles nonumber noobs collabels(none) ///
        title("Applications: Created variables (from \texttt{applications\_gpt\_vars\_creation.dta})") ///
        varlabels(`vl2') ///
        prehead("\begin{threeparttable}" `NL' "\begin{tabular}{@{}lllrr@{}}" `NL' "\toprule" `NL' ///
                "\textbf{Variable} & \textbf{Type} & \textbf{Description} & \textbf{Missing (N)} & \textbf{Missing (\%)} \\" `NL' "\midrule" `NL') ///
        postfoot("\bottomrule" `NL' "\end{tabular}" `NL' "\end{threeparttable}")
restore

*==============================
* Missingness: total_miss & key_miss
*==============================
use "$cleaned/applications_gpt_cleaned.dta", clear
local NL = char(10)

* total_miss across ALL variables
gen int total_miss = 0
ds, has(type numeric)
foreach v of varlist `r(varlist)' {
    replace total_miss = total_miss + missing(`v')
}
ds, has(type string)
foreach v of varlist `r(varlist)' {
    replace total_miss = total_miss + (ustrtrim(`v')=="")
}

preserve
    estpost tabulate total_miss, nototal
    esttab using "$inputs/applications_total_miss.tex", replace fragment booktabs ///
        nomtitles nonumber noobs collabels(none) ///
        cells("b(fmt(0)) pct(fmt(1))") ///
        prehead("\begin{threeparttable}" `NL' "\begin{tabular}{@{}lrr@{}}" `NL' "\toprule" `NL' ///
                "\textbf{Missing values per row} & \textbf{N} & \textbf{\%} \\" `NL' "\midrule" `NL') ///
        postfoot("\bottomrule" `NL' "\end{tabular}" `NL' "\end{threeparttable}")
restore

* key_miss across selected key variables
gen int key_miss = 0
local key_list application_id user_id jid employer_status created_at source
foreach v of local key_list {
    capture confirm variable `v'
    if !_rc {
        local stype : type `v'
        if substr("`stype'",1,3)=="str" {
            replace key_miss = key_miss + (ustrtrim(`v')=="")
        }
        else replace key_miss = key_miss + missing(`v')
    }
}

preserve
    estpost tabulate key_miss, nototal
    esttab using "$inputs/applications_key_miss.tex", replace fragment booktabs ///
        nomtitles nonumber noobs collabels(none) ///
        cells("b(fmt(0)) pct(fmt(1))") ///
        prehead("\begin{threeparttable}" `NL' "\begin{tabular}{@{}lrr@{}}" `NL' "\toprule" `NL' ///
                "\textbf{Missing key values per row} & \textbf{N} & \textbf{\%} \\" `NL' "\midrule" `NL') ///
        postfoot("\bottomrule" `NL' "\end{tabular}" `NL' "\end{threeparttable}")
restore	
	
************************************************
************************************************
**# APPLICATIONS EXPERIENCE
************************************************
************************************************
	
*==========================
* Original variables table
*==========================
preserve
    use "$cleaned/applications_experience_gpt_cleaned.dta", clear

    local exp_orig_vars ///
        application_id title company location job_start job_end created_at

    local N = _N
    local k : word count `exp_orig_vars'
    matrix MX = J(`k', 2, .)
    matrix rownames MX = `exp_orig_vars'
    matrix colnames MX = Missing_N Missing_pct

    local vlx ""
    local i = 0
    foreach v of local exp_orig_vars {
        local ++i
        local stype : type `v'
        local fmt   : format `v'
        local dtype "numeric"
        if strpos("`fmt'","%td")      local dtype "\%td"
        else if strpos("`fmt'","%tc") local dtype "\%tc"
        else if substr("`stype'",1,3)=="str" local dtype "string"

        local lab : variable label `v'
        if `"`lab'"' == "" local lab "`v'"
        local lab_esc = subinstr("`lab'","%","\%",.)

        if (substr("`stype'",1,3)=="str") quietly count if ustrtrim(`v')==""
        else                               quietly count if missing(`v')
        local nmiss = r(N)
        local pmiss = cond(`N'>0, round(100*`nmiss'/`N',0.1), .)

        matrix MX[`i',1] = `nmiss'
        matrix MX[`i',2] = `pmiss'

        local tdisp = cond(substr("`stype'",1,3)=="str","String (`stype')","Numeric (`stype')")
        local pretty "`v' & `tdisp' & `lab_esc'"
        local vlx `"`vlx' `v' "`pretty'""'
    }

    local NL = char(10)
    esttab matrix(MX) using "$inputs/applications_experience_original_vars.tex", replace fragment booktabs ///
        nomtitles nonumber noobs collabels(none) ///
        title("Applications Experience: Original variables") ///
        varlabels(`vlx') ///
        prehead("\begin{threeparttable}" `NL' "\begin{tabular}{@{}lllrr@{}}" `NL' "\toprule" `NL' ///
                "\textbf{Variable} & \textbf{Type} & \textbf{Description} & \textbf{Missing (N)} & \textbf{Missing (\%)} \\" `NL' "\midrule" `NL') ///
        postfoot("\bottomrule" `NL' "\end{tabular}" `NL' "\end{threeparttable}")
restore

*==============================
* Missingness: total_miss only
*==============================
use "$cleaned/applications_experience_gpt_cleaned.dta", clear
local NL = char(10)

gen int total_miss = 0
ds, has(type numeric)
foreach v of varlist `r(varlist)' {
    replace total_miss = total_miss + missing(`v')
}
ds, has(type string)
foreach v of varlist `r(varlist)' {
    replace total_miss = total_miss + (ustrtrim(`v')=="")
}

preserve
    estpost tabulate total_miss, nototal
    esttab using "$inputs/applications_experience_total_miss.tex", replace fragment booktabs ///
        nomtitles nonumber noobs collabels(none) ///
        cells("b(fmt(0)) pct(fmt(1))") ///
        prehead("\begin{threeparttable}" `NL' "\begin{tabular}{@{}lrr@{}}" `NL' "\toprule" `NL' ///
                "\textbf{Missing values per row} & \textbf{N} & \textbf{\%} \\" `NL' "\midrule" `NL') ///
        postfoot("\bottomrule" `NL' "\end{tabular}" `NL' "\end{threeparttable}")
restore

************************************************
************************************************
**# APPLICATIONS PERSONAL INFO
************************************************
************************************************	
	
*==========================
* Original variables table
*==========================
preserve
    use "$cleaned/applications_personal_info_gpt_cleaned.dta", clear

    local apers_orig_vars ///
        application_id user_id gender summary city experience ///
        job_title job_company job_start job_end ///
        degree_title degree_major degree_institute degree_year qualification_data

    local N = _N
    local k : word count `apers_orig_vars'
    matrix MP = J(`k', 2, .)
    matrix rownames MP = `apers_orig_vars'
    matrix colnames MP = Missing_N Missing_pct

    local vlp ""
    local i = 0
    foreach v of local apers_orig_vars {
        local ++i
        local stype : type `v'
        local fmt   : format `v'
        local dtype "numeric"
        if strpos("`fmt'","%td")      local dtype "\%td"
        else if strpos("`fmt'","%tc") local dtype "\%tc"
        else if substr("`stype'",1,3)=="str" local dtype "string"

        local lab : variable label `v'
        if `"`lab'"' == "" local lab "`v'"
        local lab_esc = subinstr("`lab'","%","\%",.)

        if (substr("`stype'",1,3)=="str") quietly count if ustrtrim(`v')==""
        else                               quietly count if missing(`v')
        local nmiss = r(N)
        local pmiss = cond(`N'>0, round(100*`nmiss'/`N',0.1), .)

        matrix MP[`i',1] = `nmiss'
        matrix MP[`i',2] = `pmiss'

        local tdisp = cond(substr("`stype'",1,3)=="str","String (`stype')","Numeric (`stype')")
        local pretty "`v' & `tdisp' & `lab_esc'"
        local vlp `"`vlp' `v' "`pretty'""'
    }

    local NL = char(10)
    esttab matrix(MP) using "$inputs/applications_personal_info_original_vars.tex", replace fragment booktabs ///
        nomtitles nonumber noobs collabels(none) ///
        title("Applications Personal Info: Original variables") ///
        varlabels(`vlp') ///
        prehead("\begin{threeparttable}" `NL' "\begin{tabular}{@{}lllrr@{}}" `NL' "\toprule" `NL' ///
                "\textbf{Variable} & \textbf{Type} & \textbf{Description} & \textbf{Missing (N)} & \textbf{Missing (\%)} \\" `NL' "\midrule" `NL') ///
        postfoot("\bottomrule" `NL' "\end{tabular}" `NL' "\end{threeparttable}")
restore

*==============================
* Missingness: total_miss only
*==============================
use "$cleaned/applications_personal_info_gpt_cleaned.dta", clear
local NL = char(10)

gen int total_miss = 0
ds, has(type numeric)
foreach v of varlist `r(varlist)' {
    replace total_miss = total_miss + missing(`v')
}
ds, has(type string)
foreach v of varlist `r(varlist)' {
    replace total_miss = total_miss + (ustrtrim(`v')=="")
}

preserve
    estpost tabulate total_miss, nototal
    esttab using "$inputs/applications_personal_info_total_miss.tex", replace fragment booktabs ///
        nomtitles nonumber noobs collabels(none) ///
        cells("b(fmt(0)) pct(fmt(1))") ///
        prehead("\begin{threeparttable}" `NL' "\begin{tabular}{@{}lrr@{}}" `NL' "\toprule" `NL' ///
                "\textbf{Missing values per row} & \textbf{N} & \textbf{\%} \\" `NL' "\midrule" `NL') ///
        postfoot("\bottomrule" `NL' "\end{tabular}" `NL' "\end{threeparttable}")
restore

************************************************
************************************************
**# APPLICATIONS EDUCATION
************************************************
************************************************	

*==========================
* Original variables table
*==========================
preserve
    use "$cleaned/applications_education_gpt_cleaned.dta", clear

    local aedu_orig_vars ///
        application_id title institute location start_date end_date created_at

    local N = _N
    local k : word count `aedu_orig_vars'
    matrix ME = J(`k', 2, .)
    matrix rownames ME = `aedu_orig_vars'
    matrix colnames ME = Missing_N Missing_pct

    local vle ""
    local i = 0
    foreach v of local aedu_orig_vars {
        local ++i
        local stype : type `v'
        local fmt   : format `v'
        local dtype "numeric"
        if strpos("`fmt'","%td")      local dtype "\%td"
        else if strpos("`fmt'","%tc") local dtype "\%tc"
        else if substr("`stype'",1,3)=="str" local dtype "string"

        local lab : variable label `v'
        if `"`lab'"' == "" local lab "`v'"
        local lab_esc = subinstr("`lab'","%","\%",.)

        if (substr("`stype'",1,3)=="str") quietly count if ustrtrim(`v')==""
        else                               quietly count if missing(`v')
        local nmiss = r(N)
        local pmiss = cond(`N'>0, round(100*`nmiss'/`N',0.1), .)

        matrix ME[`i',1] = `nmiss'
        matrix ME[`i',2] = `pmiss'

        local tdisp = cond(substr("`stype'",1,3)=="str","String (`stype')","Numeric (`stype')")
        local pretty "`v' & `tdisp' & `lab_esc'"
        local vle `"`vle' `v' "`pretty'""'
    }

    local NL = char(10)
    esttab matrix(ME) using "$inputs/applications_education_original_vars.tex", replace fragment booktabs ///
        nomtitles nonumber noobs collabels(none) ///
        title("Applications Education: Original variables") ///
        varlabels(`vle') ///
        prehead("\begin{threeparttable}" `NL' "\begin{tabular}{@{}lllrr@{}}" `NL' "\toprule" `NL' ///
                "\textbf{Variable} & \textbf{Type} & \textbf{Description} & \textbf{Missing (N)} & \textbf{Missing (\%)} \\" `NL' "\midrule" `NL') ///
        postfoot("\bottomrule" `NL' "\end{tabular}" `NL' "\end{threeparttable}")
restore

*==============================
* Missingness: total_miss only
*==============================
use "$cleaned/applications_education_gpt_cleaned.dta", clear
local NL = char(10)

gen int total_miss = 0
ds, has(type numeric)
foreach v of varlist `r(varlist)' {
    replace total_miss = total_miss + missing(`v')
}
ds, has(type string)
foreach v of varlist `r(varlist)' {
    replace total_miss = total_miss + (ustrtrim(`v')=="")
}

preserve
    estpost tabulate total_miss, nototal
    esttab using "$inputs/applications_education_total_miss.tex", replace fragment booktabs ///
        nomtitles nonumber noobs collabels(none) ///
        cells("b(fmt(0)) pct(fmt(1))") ///
        prehead("\begin{threeparttable}" `NL' "\begin{tabular}{@{}lrr@{}}" `NL' "\toprule" `NL' ///
                "\textbf{Missing values per row} & \textbf{N} & \textbf{\%} \\" `NL' "\midrule" `NL') ///
        postfoot("\bottomrule" `NL' "\end{tabular}" `NL' "\end{threeparttable}")
restore
	
************************************************
************************************************
**# MERGING ANALYSIS
************************************************
************************************************

tempfile temp_jobs temp_users

/***********************************************************************
** 1) JOBS
************************************************************************/

	use "$cleaned/jobs_gpt_cleaned.dta", clear

	rename title title_job
	rename description description_job
	rename required_experience required_experience_job
	rename maximum_budget maximum_budget_job

	keep jid company_id title_job description_job required_experience_job maximum_budget_job 
	
	save "`temp_jobs'", replace

/***********************************************************************
** 2) USERS
************************************************************************/

	use "$cleaned/users_gpt_cleaned.dta", clear

	rename gender gender_user
	rename created_at created_at_user
	rename last_login last_login_user
	rename current_salary current_salary_user
	rename dob dob_user
	rename experience experience_user
	
	keep user_id user_type gender_user dob_user experience_user current_salary_user created_at_user last_login_user
	save "`temp_users'", replace

/***********************************************************************
** 3) EDUCATION
************************************************************************/

	use "$cleaned/applications_education_gpt_cleaned.dta", clear

	* Order entries within application_id (created_at -> start_date -> end_date)
	gen double created_tc = clock(created_at, "YMDhms")

	* Sequence number within application_id
	bysort application_id (created_tc title institute): gen edu_seq = _n

	bysort application_id: gen byte edu_overflow = (_N > 16)
	bysort application_id: gen byte edu_n        = _N if _n==1
	keep if edu_seq <= 16

	keep application_id edu_seq ///
		 title institute location start_date end_date

	* Reshape wide
	reshape wide title institute location start_date end_date, i(application_id) j(edu_seq)

	forvalues k = 1/16 {
		label var title`k'        "Education `k' — title"
		label var institute`k'    "Education `k' — institute"
		label var location`k'     "Education `k' — location"
		label var start_date`k'   "Education `k' — start date"
		label var end_date`k'     "Education `k' — end date"
	}

	* Save wide block
	tempfile edu_wide
	save "`edu_wide'", replace
	
/***********************************************************************
** 4) EXPERIENCE
************************************************************************/

	use "$cleaned/applications_experience_gpt_cleaned.dta", clear
	
	* Order entries within application_id (created_at -> start_date -> end_date)
	gen double created_tc = clock(created_at, "YMDhms")

	* Sequence number within application_id
	bysort application_id (created_tc title company): gen exp_seq = _n

	bysort application_id: gen byte exp_overflow = (_N > 20)
	bysort application_id: gen byte exp_n        = _N if _n==1
	keep if exp_seq < 20

	keep application_id exp_seq ///
		 title company location job_start job_end

	* Reshape wide
	reshape wide title company location job_start job_end, i(application_id) j(exp_seq)

	forvalues k = 1/19 {
		label var title`k'        "Experience `k' — title"
		label var company`k'    "Experience `k' — company"
		label var location`k'     "Experience `k' — location"
		label var job_start`k'   "Experience `k' — start date"
		label var job_end`k'     "Experience `k' — end date"
	}

	* Save wide block
	tempfile exp_wide
	save "`exp_wide'", replace
	
/***********************************************************************
** 5) PERSONAL INFO
************************************************************************/

    use "$cleaned/applications_personal_info_gpt_cleaned.dta", clear
	
	duplicates tag application_id, gen(tag)
	drop if tag > 0

    destring user_id, gen(user_id_pi)    // keep for post-merge consistency checks

    keep application_id user_id_pi gender summary city experience ///
         job_title job_company job_start job_end ///
         degree_title degree_major degree_institute degree_year ///

    tempfile pi_block
    save "`pi_block'", replace
	
/***********************************************************************
** 6) MAIN APPLICATIONS
************************************************************************/

	use "$cleaned/applications_gpt_cleaned.dta", clear

	*--- Merge Application Education
	merge 1:1 application_id using "`edu_wide'"	
	
	rename _merge edu_merge
	
	*--- Merge Application Experience
	merge 1:1 application_id using "`exp_wide'"	
	
	rename _merge exp_merge
	
	*--- Merge Application Personal Info
	merge 1:1 application_id using "`pi_block'"	
	
	rename _merge pi_merge
	
	*--- Merge Jobs (Apps many-to-one Jobs by jid)
	merge m:1 jid using "`temp_jobs'"
	
	rename _merge jobs_merge
	
	preserve
		keep if jobs_merge == 3 & !missing(jid)
		keep jid
		duplicates drop
		count    // -> unique jobs matched
	restore

	*--- Merge Users (Apps many-to-one Users by user_id)
	merge m:1 user_id using "`temp_users'"
	
	rename _merge users_merge

	preserve
		keep if users_merge == 3 & !missing(user_id)
		keep user_id
		duplicates drop
		count    // -> unique users matched
	restore

	*--- Merge Companies (Apps many-to-one Companies by company_id coming from Jobs)
	merge m:1 company_id using "$cleaned/companies_gpt_cleaned.dta"
	
	rename _merge comp_merge

	preserve
		keep if comp_merge == 3 & !missing(company_id)
		keep company_id
		duplicates drop
		count    // -> unique companies matched
	restore

	save "$temp/merged_datasets.dta", replace
	
/***********************************************************************
** 7) CORE SAMPLE
************************************************************************/	

	use "$temp/merged_datasets.dta", clear

	keep if !missing(company_id) & !missing(jid) & !missing(user_id) & !missing(company_id)

	gen ghost_job = 0
	replace ghost_job = 1 if missing(company_id) | title_job == "" | description_job == ""
	
	gen ghost_user = 0
	replace ghost_user = 1 if user_id != user_id_pi & user_id_pi != . & user_id != .
	replace ghost_user = 1 if summary == "" & gender == "" & gender_user == "" & dob_user == ""
	
	tab jobs_merge ghost_job, m
	tab users_merge ghost_user, m
	
	keep if ghost_job == 0 & ghost_user == 0
	
	count if summary == ""
	count if summary == "" & (job_company == "Interview Guru" | job_company == "Rozee.Pk")
	
/***********************************************************************
** 8) USERS BY START DATE AND APPLICATION DATE
************************************************************************/	

	use "$temp/merged_datasets.dta", clear

	keep if !missing(company_id) & !missing(jid) & !missing(user_id) & !missing(company_id)
	
	gen ghost_job = 0
	replace ghost_job = 1 if missing(company_id) | title_job == "" | description_job == ""
	
	gen ghost_user = 0
	replace ghost_user = 1 if user_id != user_id_pi & user_id_pi != . & user_id != .
	replace ghost_user = 1 if summary == "" & gender == "" & gender_user == "" & dob_user == ""
	
	keep if ghost_job == 0 & ghost_user == 0

	preserve
		keep if users_merge == 3 & !missing(user_id)
		keep user_id
		duplicates drop
		count    // -> unique users matched
	restore
	
	* core sample = 95,458 applications from 64,278 users
	save "$temp/gpt_core_sample.dta", replace
	
*-----------------------------------------------*
* How many users after April 1st cutoff?
*-----------------------------------------------*

	gen double created_at_dt        = clock(trim(created_at),        "YMDhms")
	gen double created_at_user_dt   = clock(trim(created_at_user),   "YMDhms")
	gen double last_login_user_dt   = clock(trim(last_login_user),   "YMDhms")
	format %tc created_at_dt created_at_user_dt last_login_user_dt

	local cutoff = clock("2025-04-01 00:00:00", "YMDhms")

	*--- 1) Keep by created_at
	preserve
		keep if !missing(created_at_dt) & created_at_dt > `cutoff'
		keep if users_merge == 3 & !missing(user_id)
		keep user_id
		duplicates drop
		count    // -> unique users with application after 1 Apr 2025
	restore

	*--- 2) Keep by created_at_user
	preserve
		keep if !missing(created_at_user_dt) & created_at_user_dt > `cutoff'
		keep if users_merge == 3 & !missing(user_id)
		keep user_id
		duplicates drop
		count    // -> unique users who created profile after 1 Apr 2025
	restore

	*--- 3) Keep by last_login_user
	preserve
		keep if !missing(last_login_user_dt) & last_login_user_dt > `cutoff'
		keep if users_merge == 3 & !missing(user_id)
		keep user_id
		duplicates drop
		count    // -> unique users who logged in after 1 Apr 2025
	restore
	
*-----------------------------------------------*
* How many of these are active Rozeena users?
*-----------------------------------------------*

* Application-level flags
gen byte app_post_apr  = !missing(created_at_dt)      & created_at_dt      > `cutoff'
gen byte user_post_apr = !missing(created_at_user_dt) & created_at_user_dt > `cutoff'

* Collapse to one row per user_id
preserve
    keep if users_merge == 3 & !missing(user_id)
    bysort user_id: egen app_post_apr_user  = max(app_post_apr)
    bysort user_id: egen user_post_apr_user = max(user_post_apr)
    keep user_id app_post_apr_user user_post_apr_user
    duplicates drop
    tempfile users_flags
    save `users_flags'
restore

* Load chat dataset of sessions
use "$temp/merged_chat_data.dta", clear

* Keep valid session + user_id
gen strL __sid = trim(chat_session_id)
replace __sid = upper(__sid)
drop if missing(__sid) | inlist(__sid, "", "NULL", "NA", ".")
drop if missing(user_id)
keep user_id
duplicates drop

* Total chat users with a valid chat_session_id
count
local N_chat_users = r(N) 

* Merge to user flags (whoever appears in merged_datasets)
merge m:1 user_id using `users_flags'
count if _merge==3
local N_any_app = r(N)     // users whose user_id appears in merged data

* Among matched chat users: post-April application and post-April account creation
count if _merge==3 & app_post_apr_user==1
local N_app_post_apr = r(N)

count if _merge==3 & user_post_apr_user==1
local N_user_post_apr = r(N)

* Report
local s_total          = 100
local s_any_app        = 100 * `N_any_app'        / `N_chat_users'
local s_app_post_apr   = 100 * `N_app_post_apr'   / `N_chat_users'
local s_user_post_apr  = 100 * `N_user_post_apr'  / `N_chat_users'

di as txt "Chat users with valid session: "     ///
   as res %9.0fc `N_chat_users' as txt " (" %5.1f `s_total' "%)"
di as txt "…with any application: "             ///
   as res %9.0fc `N_any_app'     as txt " (" %5.1f `s_any_app' "%)"
di as txt "…applied after 1 Apr 2025: "         ///
   as res %9.0fc `N_app_post_apr' as txt " (" %5.1f `s_app_post_apr' "%)"
di as txt "…created account after 1 Apr 2025: " ///
   as res %9.0fc `N_user_post_apr' as txt " (" %5.1f `s_user_post_apr' "%)"
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	