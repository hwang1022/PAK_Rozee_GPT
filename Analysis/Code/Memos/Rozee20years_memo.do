
/*======================================================================*
 |  Project:    Rozee 
 |  Author:     AB
 |  File: 		Exploratory analysis on Rozee20years data
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
		
		global dir "enter here"	
		
	}
	
	global  proc	 	"$dir/Data/Process/Rozee20years/251007_Process_Rozee20years"
	global	int 		"$dir/Data/Analysis/Rozee20years/251008_Intermediate_Rozee20years"
	global  tex    		"$dir/Tex/Aux/Rozee20years_memo"
	global  inputs 		"$tex/inputs"
		
********************************************
**# USERS
********************************************

*--- Load ----------------------------------------------------

	use "$int/users_int.dta", clear
	
*---- AGE: bar chart of counts by single year ---------------------------

		preserve
			keep age
			drop if missing(age)

			quietly count
			local Nused = r(N)

			* counts by age
			contract age, freq(N)
			sort age

			* figure
			set scheme s1mono
			twoway ///
				(bar N age, barwidth(0.9)), ///
				xlabel(15(5)90, labsize(small)) ///
				xtitle("Age (years)") ///
				ylabel(, grid labsize(small)) ///
				ytitle("Users (count)") ///
				title("Users: Age (trimmed 14–90)", size(large)) ///
				subtitle(" ") ///
				note("N = `=string(`Nused', "%12.0gc")'", size(small)) ///
				legend(off) ///
				xsize(10) ysize(6)

			graph export "$inputs/fig_users_age_counts.pdf", as(pdf) replace
		restore
		
*---- GENDER: composition table -------------------------------------------

		preserve
			keep gender_str
			gen str20 _gender = cond(trim(gender_str)!="", gender_str, "Unknown")

			quietly count
			local Nused = r(N)
			local Nused_fmt : display %12.0gc `Nused'

			estpost tab _gender, nototal

			esttab using "$inputs/tab_users_gender.tex", ///
				cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
				collabels(none) label nonumber noobs nomtitle ///
				booktabs fragment replace ///
				prehead("\begin{tabular}{lrr}" ///
						"\toprule" ///
						" & N & \% of total \\" ///
						"\midrule" ///
						"\multicolumn{3}{l}{\textbf{Gender}}\\ ") ///
				postfoot("\midrule" ///
						 "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" ///
						 "\bottomrule" "\end{tabular}")
		restore
	
*---- MARITAL STATUS: composition table ----------------------------------

		preserve
			keep maritalstatus_str
			gen str30 _mstatus = cond(trim(maritalstatus_str)!="", maritalstatus_str, "Unknown")

			quietly count
			local Nused = r(N)
			local Nused_fmt : display %12.0gc `Nused'

			estpost tab _mstatus, nototal

			esttab using "$inputs/tab_users_maritalstatus.tex", ///
				cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
				collabels(none) label nonumber noobs nomtitle ///
				booktabs fragment replace ///
				prehead("\begin{tabular}{lrr}" ///
						"\toprule" ///
						" & N & \% of total \\" ///
						"\midrule" ///
						"\multicolumn{3}{l}{\textbf{Marital status}}\\ ") ///
				postfoot("\midrule" ///
						 "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" ///
						 "\bottomrule" "\end{tabular}")
		restore

*---- CAREER LEVEL: composition table --------------------------------------

	preserve
		keep careerlevel_str

		gen str60 _car_raw = ustrtrim(careerlevel_str)

		gen str40 _careergrp = ""
		replace _careergrp = "Department Head"                         if _car_raw == "Department Head"
		replace _careergrp = "Entry Level"                             if _car_raw == "Entry Level"
		replace _careergrp = "Experienced Professional"                if _car_raw == "Experienced Professional"
		replace _careergrp = "GM / CEO / Country Head / President"     if _car_raw == "GM / CEO / Country Head / President"
		replace _careergrp = "Intern/Student"                          if _car_raw == "Intern/Student"
		replace _careergrp = "Unknown"  if missing(_car_raw) | _car_raw==""
		replace _careergrp = "Other"    if _careergrp=="" & !missing(_car_raw)
		drop _car_raw

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		estpost tab _careergrp, nototal

		esttab using "$inputs/tab_users_careerlevel.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			coeflabels( ///
				1 "Department Head" ///
				2 "Entry Level" ///
				3 "Experienced Professional" ///
				4 "GM / CEO / Country Head / President" ///
				5 "Intern/Student" ///
				6 "Other" ///
				7 "Unknown") ///
			prehead("\begin{tabular}{lrr}" `NL' "\toprule" `NL' " & N & \% of total \\" `NL' "\midrule" `NL' "\multicolumn{3}{l}{\textbf{Career level}}\\ ") ///
			postfoot("\midrule" `NL' "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

*---- COUNTRY: composition table (grouped; "Other" if count < 1,000) -----

	preserve
		keep country_name
		replace country_name = trim(country_name)

		* group unknowns
		gen str40 _countrygrp = cond(missing(country_name) | country_name=="", "Unknown", country_name)

		* mark rare countries and map to "Other"
		bysort country_name: egen long _Ncountry = count(country_name)
		replace _countrygrp = "Other" if _countrygrp!="Unknown" & _Ncountry < 1000
		drop _Ncountry

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		estpost tab _countrygrp, nototal

		esttab using "$inputs/tab_users_country.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' ///
					"\toprule" `NL' ///
					" & N & \% of total \\" `NL' ///
					"\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Country}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

*---- CITY: composition table (PK cities <10,000 -> "Other - Pakistan"; non-PK -> "Non-Pakistan") ----

	preserve
		keep city_name country_name
		replace city_name    = ustrtrim(city_name)
		replace country_name = ustrtrim(country_name)

		* initialize group
		gen str60 _citygrp = ""
		replace _citygrp = "Unknown" if missing(city_name) | city_name==""

		* Pakistan flag and PK-only counts by city
		gen byte is_pak = (country_name=="Pakistan")
		bysort city_name: egen long _Ncity_pk = total(is_pak)

		* assignment rules
		replace _citygrp = city_name              if _citygrp=="" & is_pak==1 & _Ncity_pk >= 10000
		replace _citygrp = "Other - Pakistan"     if _citygrp=="" & is_pak==1 & _Ncity_pk < 10000
		replace _citygrp = "Non-Pakistan"         if _citygrp=="" & is_pak==0

		drop _Ncity_pk is_pak

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		estpost tab _citygrp, nototal

		esttab using "$inputs/tab_users_city_grouped.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' ///
					"\toprule" `NL' ///
					" & N & \% of total \\" `NL' ///
					"\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{City}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

*---- EXPERIENCE BUCKET: bar chart of counts ---------------------------------

	preserve
		keep exp_bucket
		drop if missing(exp_bucket)

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'

		contract exp_bucket, freq(N)
		label values exp_bucket lexpb
		sort exp_bucket

		* counts in thousands
		gen double N_k = N/1000

		set scheme s1mono
		graph bar (sum) N_k, ///
			over(exp_bucket, label(labsize(small))) ///
			bargap(20) ///
			ylabel(, grid labsize(small) format(%9.0fc)) ///
			ytitle("Users (thousands)") ///
			title("Users: Experience Buckets", size(large)) ///
			subtitle(" ") ///
			note("N = `Nused_fmt'", size(small)) ///
			legend(off) ///
			xsize(10) ysize(6)

		graph export "$inputs/fig_users_experience_buckets.pdf", as(pdf) replace
	restore

*---- LANGUAGES: composition table (1,2,3,4,5,6+) ------------

	preserve
		keep lang_count
		drop if missing(lang_count) | lang_count < 1

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		* bucketize: 1,2,3,4,5,6+
		gen str3 _langgrp = ""
		replace _langgrp = "1"   if lang_count==1
		replace _langgrp = "2"   if lang_count==2
		replace _langgrp = "3"   if lang_count==3
		replace _langgrp = "4"   if lang_count==4
		replace _langgrp = "5"   if lang_count==5
		replace _langgrp = "6+"  if lang_count>=6

		* tabulate
		estpost tab _langgrp, nototal

		esttab using "$inputs/tab_users_langcount.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' ///
					"\toprule" `NL' ///
					" & N & \% of total \\" `NL' ///
					"\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Languages listed}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

*---- SALARY SUMMARY (PKR and PPP USD) ---------------------------------------

	preserve
		keep cursal_pkr expsal_pkr cursal_usd_ppp expsal_usd_ppp

		label var cursal_pkr     "Current salary (PKR)"
		label var expsal_pkr     "Expected salary (PKR)"
		label var cursal_usd_ppp "Current salary (PPP USD)"
		label var expsal_usd_ppp "Expected salary (PPP USD)"

		estpost tabstat cursal_pkr expsal_pkr cursal_usd_ppp expsal_usd_ppp, ///
			statistics(mean p5 p25 p50 p75 p95) columns(statistics)

		local NL = char(10)

		esttab using "$inputs/tab_users_salary_summary.tex", ///
			cells("mean(fmt(%12.2fc)) p5(fmt(%12.2fc)) p25(fmt(%12.2fc)) p50(fmt(%12.2fc)) p75(fmt(%12.2fc)) p95(fmt(%12.2fc))") ///
			collabels("Mean" "p5" "p25" "p50" "p75" "p95") ///
			label nonumber noobs nomtitle booktabs fragment replace ///
			prehead("\begin{tabular}{lrrrrrrrr}" `NL' "\toprule" `NL') ///
			posthead("" ) ///
			postfoot("\bottomrule" `NL' "\end{tabular}" `NL')
	restore

		
********************************************
**# USERS EDUCATION
********************************************

*--- Load ----------------------------------------------------	

	use "$int/users_education_int.dta", clear
	
*---- SCHOOL TYPE: composition table -------------------------------------

	preserve
		keep schooltype
		gen str20 _schooltype = ustrtrim(schooltype)
		replace _schooltype = proper(_schooltype)
		replace _schooltype = "Unknown" if missing(_schooltype) | _schooltype==""

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		estpost tab _schooltype, nototal

		esttab using "$inputs/tab_usersedu_schooltype.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' ///
					"\toprule" `NL' ///
					" & N & \% of total \\" `NL' ///
					"\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{School type}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

*---- DEGREE TYPE: collapse to {Bachelors, Masters, Other, Unknown} ------

	preserve
		keep degreetype_str
		gen strL _raw = ustrlower(ustrtrim(degreetype_str))

		* initialize
		gen str10 _deggrp = ""

		* map to Bachelors
		replace _deggrp = "Bachelors" if ///
			regexm(_raw, "bachelor") | ///
			regexm(_raw, "\bbs\b|\bbsc\b|\bbcs\b")

		* map to Masters
		replace _deggrp = "Masters" if _deggrp=="" & ( ///
			regexm(_raw, "master")   | ///
			regexm(_raw, "\bmba\b|\bmsc\b|\bms\b|\bm-?phil\b") )

		* Unknown if missing/blank
		replace _deggrp = "Unknown" if _deggrp=="" & (missing(_raw) | _raw=="")

		* Other = everything else non-missing not matched above
		replace _deggrp = "Other" if _deggrp=="" & !missing(_raw)

		drop _raw

		* set explicit display order
		gen byte _deggrp_num = .
		replace _deggrp_num = 1 if _deggrp=="Bachelors"
		replace _deggrp_num = 2 if _deggrp=="Masters"
		replace _deggrp_num = 3 if _deggrp=="Other"
		replace _deggrp_num = 4 if _deggrp=="Unknown"
		label define __ldeg 1 "Bachelors" 2 "Masters" 3 "Other" 4 "Unknown", replace
		label values _deggrp_num __ldeg

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		estpost tab _deggrp_num, nototal

		esttab using "$inputs/tab_usersedu_degreetype4.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' ///
					"\toprule" `NL' ///
					" & N & \% of total \\" `NL' ///
					"\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Degree type}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

*---- GRAD YEAR: composition table ----------------------------------------

	preserve
		keep grad_year_bucket
		drop if missing(grad_year_bucket)

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		estpost tab grad_year_bucket, nototal

		local labs `e(labels)'
		local i = 1
		local cl ""
		foreach L of local labs {
			local cl `"`cl' `i' "`L'""'
			local ++i
		}

		local coefopt
		if `"`cl'"' != "" {
			local coefopt coeflabels(`cl')
		}

		esttab using "$inputs/tab_usersedu_gradyear_buckets.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			`coefopt' ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' ///
					"\toprule" `NL' ///
					" & N & \% of total \\" `NL' ///
					"\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Graduation year bucket}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

*---- DEGREE COUNTRY: composition table (Other = <10,000) ----------------

	preserve
		keep country_name
		replace country_name = ustrtrim(country_name)

		* Group: Unknown (missing), country name, Other if <10k
		gen str40 _degcountry = cond(missing(country_name) | country_name=="", "Unknown", country_name)
		bysort country_name: egen long _Ncountry = count(country_name)
		replace _degcountry = "Other" if _degcountry!="Unknown" & _Ncountry < 10000
		drop _Ncountry

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		estpost tab _degcountry, nototal

		* Map numeric rows (1..k) to readable labels
		local labs `e(labels)'
		local i = 1
		local cl ""
		foreach L of local labs {
			local cl `"`cl' `i' "`L'""'
			local ++i
		}
		local coefopt
		if `"`cl'"' != "" {
			local coefopt coeflabels(`cl')
		}

		esttab using "$inputs/tab_usersedu_degree_country_grouped.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			`coefopt' ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' ///
					"\toprule" `NL' ///
					" & N & \% of total \\" `NL' ///
					"\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Degree country (Other = < 10{,}000)}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

*---- GRADE TYPE: composition table --------------------------------------

	preserve
		keep edugradetype
		replace edugradetype = ustrtrim(edugradetype)
		gen str20 _edugradetype = cond(missing(edugradetype) | edugradetype=="", "Unknown", edugradetype)

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		estpost tab _edugradetype, nototal

		esttab using "$inputs/tab_usersedu_edugradetype.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' "\toprule" `NL' " & N & \% of total \\" `NL' "\midrule" `NL' "\multicolumn{3}{l}{\textbf{Grade type}}\\ ") ///
			postfoot("\midrule" `NL' "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' "\bottomrule" `NL' "\end{tabular}" `NL')
	restore
	
*---- GRADES: three bar charts stacked (counts in thousands; leftmost bins) ----

	preserve
		keep edugradeval grade_is_gpa4
		drop if grade_is_gpa4 != 1

		gen double eduv = real(subinstr(subinstr(ustrtrim(edugradeval), "%", "", .), ",", "", .))
		drop if missing(eduv)
		replace eduv = max(0, min(4, eduv))   // clamp to [0,4]

		* bin: 0="<2.0", then 0.1-width bins from 2.0 to 4.0
		local bw = 0.1
		gen int x_ord = cond(eduv<2, 0, 1 + floor((eduv-2)/`bw'))
		replace x_ord = 1 + floor((4-2)/`bw') if x_ord > 1 + floor((4-2)/`bw')

		* readable labels
		capture label drop Lgpa4
		label define Lgpa4 0 "<2.0", replace
		forvalues i = 0/20 {
			local lo = 2 + `i'*`bw'
			local hi = `lo' + `bw'
			local k  = `i' + 1
			label define Lgpa4 `k' "`=string(`lo',"%3.1f")'–`=string(`hi',"%3.1f")'", add
		}
		label values x_ord Lgpa4

		contract x_ord, freq(N)
		gen double N_k = N/1000

		set scheme s1mono
		graph bar (sum) N_k, ///
			over(x_ord, label(labsize(tiny))) ///
			bargap(15) ///
			ylabel(, grid labsize(vsmall) format(%9.0fc)) ///
			ytitle("Users (thousands)") ///
			title("GPA (4.0 scale)", size(medsmall)) ///
			legend(off) ///
			name(g_gpa4, replace)
	restore

	preserve
		keep edugradeval grade_is_gpa5
		drop if grade_is_gpa5 != 1

		gen double eduv = real(subinstr(subinstr(ustrtrim(edugradeval), "%", "", .), ",", "", .))
		drop if missing(eduv)
		replace eduv = max(0, min(5, eduv))   // clamp to [0,5]

		local bw = 0.1
		gen int x_ord = cond(eduv<2, 0, 1 + floor((eduv-2)/`bw'))
		replace x_ord = 1 + floor((5-2)/`bw') if x_ord > 1 + floor((5-2)/`bw')

		capture label drop Lgpa5
		label define Lgpa5 0 "<2.0", replace
		forvalues i = 0/30 {
			local lo = 2 + `i'*`bw'
			local hi = `lo' + `bw'
			local k  = `i' + 1
			label define Lgpa5 `k' "`=string(`lo',"%3.1f")'–`=string(`hi',"%3.1f")'", add
		}
		label values x_ord Lgpa5

		contract x_ord, freq(N)
		gen double N_k = N/1000

		set scheme s1mono
		graph bar (sum) N_k, ///
			over(x_ord, label(labsize(tiny))) ///
			bargap(15) ///
			ylabel(, grid labsize(vsmall) format(%9.0fc)) ///
			ytitle("Users (thousands)") ///
			title("GPA (5.0 scale)", size(medsmall)) ///
			legend(off) ///
			name(g_gpa5, replace)
	restore

	preserve
		keep edugradeval grade_is_pct
		drop if grade_is_pct != 1

		gen double eduv = real(subinstr(subinstr(ustrtrim(edugradeval), "%", "", .), ",", "", .))
		drop if missing(eduv)
		replace eduv = max(0, min(100, eduv))  // clamp to [0,100]

		* bin: 0="<40", then 5-point bins 40–44, 45–49, ..., 95–100
		gen int x_ord = cond(eduv<40, 0, 1 + floor((eduv-40)/5))
		replace x_ord = 1 + floor((100-40)/5) if x_ord > 1 + floor((100-40)/5)

		capture label drop Lpct
		label define Lpct 0 "<40", replace
		forvalues i = 0/12 {
			local lo = 40 + 5*`i'
			local hi = `lo' + 4
			if `hi' > 100 local hi = 100
			local k  = `i' + 1
			label define Lpct `k' "`=string(`lo',"%2.0f")'–`=string(`hi',"%3.0f")'", add
		}
		label values x_ord Lpct

		contract x_ord, freq(N)
		gen double N_k = N/1000

		set scheme s1mono
		graph bar (sum) N_k, ///
			over(x_ord, label(labsize(vsmall))) ///
			bargap(15) ///
			ylabel(, grid labsize(vsmall) format(%9.0fc)) ///
			ytitle("Users (thousands)") ///
			title("Percentage grades", size(medsmall)) ///
			legend(off) ///
			name(g_pct, replace)
	restore

	* Combine 3 rows
	graph combine g_gpa4 g_gpa5 g_pct, rows(3) cols(1) ///
		title("Users Education: Grade Distributions", size(large)) ///
		imargin(2 2 2 2) graphregion(margin(4 4 4 4)) ///
		xsize(36) ysize(20)

	graph export "$inputs/fig_usersedu_grades_bars_3x1.pdf", as(pdf) replace


********************************************
**# USERS EXPERIENCE
********************************************

*--- Load ----------------------------------------------------

	use "$int/users_experience_int.dta", clear
	
*--- Build monthly dates & validity --------------------------

	gen int  _start_tm = ym(jobstart_yr, jobstart_mon)
	gen int  _end_tm   = ym(jobend_yr,   jobend_mon)
	format   _start_tm _end_tm %tm

	gen byte _has_start = !missing(_start_tm)
	gen byte _has_end   = !missing(_end_tm)
	gen byte _valid     = _has_start & _has_end & _start_tm <= _end_tm

*--- START YEAR: bar chart of counts --------------------------------------

	preserve
		keep if _has_start
		keep _start_tm jobstart_yr

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'

		contract jobstart_yr, freq(N)
		sort jobstart_yr

		set scheme s1mono
		graph bar (sum) N, ///
			over(jobstart_yr, label(labsize(vsmall) angle(90))) ///
			bargap(15) ///
			ylabel(, grid labsize(small) format(%12.0gc)) ///
			ytitle("Jobs (count)") ///
			title("Jobs: Start Year", size(large)) ///
			note("N = `Nused_fmt'", size(small)) legend(off) xsize(10) ysize(6)

		graph export "$inputs/fig_jobs_start_year.pdf", as(pdf) replace
	restore

*--- END YEAR: bar chart of counts ----------------------------------------

	preserve
		keep if _has_end
		keep _end_tm jobend_yr

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'

		contract jobend_yr, freq(N)
		sort jobend_yr

		set scheme s1mono
		graph bar (sum) N, ///
			over(jobend_yr, label(labsize(vsmall) angle(90))) ///
			bargap(15) ///
			ylabel(, grid labsize(small) format(%12.0gc)) ///
			ytitle("Jobs (count)") ///
			title("Jobs: End Year", size(large)) ///
			note("N = `Nused_fmt'", size(small)) legend(off) xsize(10) ysize(6)

		graph export "$inputs/fig_jobs_end_year.pdf", as(pdf) replace
	restore

*--- TENURE: months, binned bar chart -------------------------------------

	preserve
		keep if _valid
		gen int tenure_m = _end_tm - _start_tm + 1   // inclusive months
		drop if tenure_m<=0

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'

		* bins: 1–6, 7–12, 13–24, 25–36, 37–60, 61–120, 121+
		gen byte tbin = .
		replace tbin = 1 if inrange(tenure_m,  1,   6)
		replace tbin = 2 if inrange(tenure_m,  7,  12)
		replace tbin = 3 if inrange(tenure_m, 13,  24)
		replace tbin = 4 if inrange(tenure_m, 25,  36)
		replace tbin = 5 if inrange(tenure_m, 37,  60)
		replace tbin = 6 if inrange(tenure_m, 61, 120)
		replace tbin = 7 if tenure_m>=121

		label define ltb 1 "1–6" 2 "7–12" 3 "13–24" 4 "25–36" 5 "37–60" 6 "61–120" 7 "121+"
		label values tbin ltb

		contract tbin, freq(N)
		sort tbin

		set scheme s1mono
		graph bar (sum) N, ///
			over(tbin, label(labsize(small))) ///
			bargap(20) ///
			ylabel(, grid labsize(small) format(%12.0gc)) ///
			ytitle("Jobs (count)") ///
			title("Jobs: Tenure Distribution (Months)", size(large)) ///
			note("N = `Nused_fmt'", size(small)) legend(off) xsize(10) ysize(6)

		graph export "$inputs/fig_jobs_tenure_bins.pdf", as(pdf) replace
	restore

*---- MANAGE TEAM + TEAM SIZE: one combined table -------------------------

	preserve
		keep manage_team_ind team_size_bucket
		local NL = char(10)

		* ---------- (A) Manages a team ----------
		estpost tab manage_team_ind, nototal

		* build coeflabels from e(labels)
		local labs `e(labels)'
		local i = 1
		local cl1 ""
		foreach L of local labs {
			local cl1 `"`cl1' `i' "`L'""'
			local ++i
		}
		local coefopt1
		if `"`cl1'"' != "" local coefopt1 coeflabels(`cl1')

		esttab using "$inputs/tab_users_exp_manage_team_combo.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			`coefopt1' ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' ///
					"\toprule" `NL' ///
					" & N & \% of total \\" `NL' ///
					"\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Manages a team}}\\ ")

		* ---------- (B) Team size (Yes only) ----------
		estpost tab team_size_bucket if manage_team_ind==1, nototal

		* build coeflabels again for this tab
		local labs `e(labels)'
		local i = 1
		local cl2 ""
		foreach L of local labs {
			local cl2 `"`cl2' `i' "`L'""'
			local ++i
		}
		local coefopt2
		if `"`cl2'"' != "" local coefopt2 coeflabels(`cl2')

		esttab using "$inputs/tab_users_exp_manage_team_combo.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			`coefopt2' ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment append ///
			prehead("\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Team size (among 'Yes')}}\\ ") ///
			postfoot("\bottomrule" `NL' "\end{tabular}" `NL')
	restore

*---- COUNTRY: composition table (Other if <100; include Unknown) ----------

	preserve
		keep country_name
		replace country_name = ustrtrim(country_name)

		* group into Unknown / Other / named countries
		gen str40 _ctrygrp = ""
		replace _ctrygrp = "Unknown" if missing(country_name) | country_name==""

		egen _n_ctry = count(country_name), by(country_name)
		replace _ctrygrp = country_name if _ctrygrp==""
		replace _ctrygrp = "Other" if _ctrygrp!="Unknown" & _n_ctry < 100
		drop _n_ctry

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		estpost tab _ctrygrp, nototal

		esttab using "$inputs/tab_users_exp_country.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' ///
					"\toprule" `NL' ///
					" & N & \% of total \\" `NL' ///
					"\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Employment country}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

*---- CITY: composition table (Other–Pakistan <1000; Non-Pakistan; Unknown) --

	preserve
		keep city_name country_name
		replace city_name   = ustrtrim(city_name)
		replace country_name = ustrtrim(country_name)

		* Start with Unknown when city is missing/blank
		gen str60 _citygrp = ""
		replace _citygrp = "Unknown" if missing(city_name) | city_name==""

		* Count Pakistan observations per city (so we can flag < 1000)
		gen byte _is_pak = (country_name=="Pakistan")
		bysort city_name: egen long _n_pak_city = total(_is_pak)

		* Assign groups for non-missing city rows
		replace _citygrp = city_name ///
			if _citygrp=="" & country_name=="Pakistan" & _n_pak_city>=1000

		replace _citygrp = "Other - Pakistan" ///
			if _citygrp=="" & country_name=="Pakistan" & _n_pak_city<1000

		replace _citygrp = "Non-Pakistan" ///
			if _citygrp=="" & country_name!="" & country_name!="Pakistan"

		drop _is_pak _n_pak_city

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		estpost tab _citygrp, nototal

		esttab using "$inputs/tab_users_exp_city.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' ///
					"\toprule" `NL' ///
					" & N & \% of total \\" `NL' ///
					"\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Employment city}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

	
********************************************
**# JOBS
********************************************

*--- Load ----------------------------------------------------

	use "$int/jobs_int.dta", clear
	
*---- CURRENCY UNIT: composition table -------------------------------------

	preserve
		keep currency_unit
		replace currency_unit = ustrtrim(currency_unit)
		replace currency_unit = "" if inlist(upper(currency_unit),"NULL",".","NA","N/A","NONE","MISSING")

		gen str40 _curr = cond(currency_unit=="", "Unknown", currency_unit)

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		estpost tab _curr, nototal

		esttab using "$inputs/tab_jobs_currency_unit.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' ///
					"\toprule" `NL' ///
					" & N & \% of total \\" `NL' ///
					"\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Currency unit}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

*---- CAREER LEVEL: composition table -----------------------------------------

	preserve
		keep careerlevel_str
		replace careerlevel_str = ustrtrim(careerlevel_str)

		* Map to seven buckets
		gen str50 _careergrp = ""
		replace _careergrp = "Unknown"                                 if missing(careerlevel_str) | careerlevel_str==""
		replace _careergrp = "Department Head"                         if _careergrp=="" & careerlevel_str=="Department Head"
		replace _careergrp = "Entry Level"                             if _careergrp=="" & careerlevel_str=="Entry Level"
		replace _careergrp = "Experienced Professional"                if _careergrp=="" & careerlevel_str=="Experienced Professional"
		replace _careergrp = "GM / CEO / Country Head / President"     if _careergrp=="" & careerlevel_str=="GM / CEO / Country Head / President"
		replace _careergrp = "Intern/Student"                          if _careergrp=="" & careerlevel_str=="Intern/Student"
		replace _careergrp = "Other"                                   if _careergrp=="" & careerlevel_str!=""   // all remaining non-missing -> Other

		* Encode with explicit order
		encode _careergrp, gen(_careergrp_ord)
		label define __lcar ///
			1 "Department Head" ///
			2 "Entry Level" ///
			3 "Experienced Professional" ///
			4 "GM / CEO / Country Head / President" ///
			5 "Intern/Student" ///
			6 "Other" ///
			7 "Unknown", replace
		label values _careergrp_ord __lcar

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		* Tab the ordered numeric and supply readable row labels
		estpost tab _careergrp_ord, nototal

		local cl `" 1 "Department Head" 2 "Entry Level" 3 "Experienced Professional" 4 "GM / CEO / Country Head / President" 5 "Intern/Student" 6 "Other" 7 "Unknown" "'

		esttab using "$inputs/tab_jobs_careerlevel.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			coeflabels(`cl') ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' ///
					"\toprule" `NL' " & N & \% of total \\" `NL' "\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Career level}}\\ ") ///
			postfoot("\midrule" `NL' "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore


*---- JOB PACKAGE: composition table ---------------------------------------

	preserve
		keep jobpackage
		replace jobpackage = ustrtrim(jobpackage)

		gen str15 _pkg = cond(jobpackage=="", "Unknown", jobpackage)

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		estpost tab _pkg, nototal

		esttab using "$inputs/tab_jobs_jobpackage.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' ///
					"\toprule" `NL' ///
					" & N & \% of total \\" `NL' ///
					"\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Job package}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore
	
*---- JOB FILTERS: % Yes by filter -------------------------------------------

	preserve
		keep filter_gender_num filter_experience_num filter_degree_num ///
			 filter_age_num    filter_city_num

		local flist  filter_gender_num filter_experience_num filter_degree_num ///
					 filter_age_num    filter_city_num

		* build matrix of % Yes
		local k : word count `flist'
		tempname M
		matrix `M' = J(`k', 1, .)

		local i = 1
		foreach v of local flist {
			quietly summarize `v' if !missing(`v'), meanonly
			matrix `M'[`i',1] = 100 * r(mean)
			local ++i
		}

		* safe rownames (no spaces); pretty labels provided via varlabels()
		matrix rownames `M' = fg fe fd fa fc
		matrix colnames `M' = pct

		local NL = char(10)
		esttab matrix(`M') using "$inputs/tab_jobs_filters_pct.tex", ///
			replace booktabs fragment nonumber noobs nomtitle ///
			collabels(none) varlabels( ///
				fg "Filtered by Gender" ///
				fe "Filtered by Experience" ///
				fd "Filtered by Degree" ///
				fa "Filtered by Age" ///
				fc "Filtered by City" ) ///
			prehead("\begin{tabular}{lr}" `NL' ///
					"\toprule" `NL' ///
					"Filter & \% Yes \\" `NL' ///
					"\midrule" `NL' ///
					"\multicolumn{2}{l}{\textbf{Job filters}}\\ ") ///
			postfoot("\bottomrule" `NL' "\end{tabular}" `NL')
	restore

*---- MIN EDUCATION: bar chart (Masters vs Doctorates; <1000 -> Other) -----

	preserve
		keep min_education_str
		replace min_education_str = ustrtrim(min_education_str)

		* start with Unknown for blanks
		gen str30 _mingrp = cond(min_education_str=="", "Unknown", min_education_str)

		* consolidate Masters (incl. MBBS & M-Phil(l))
		replace _mingrp = "Masters" if inlist(_mingrp, "Masters","M-Phil","M-Phill","MBBS")

		* consolidate Doctorates (incl. Pharm-D & MD)
		replace _mingrp = "Doctorates" if inlist(_mingrp, "Doctorate","Pharm-D","MD")

		* collapse small remaining groups to Other (keep Unknown as its own)
		bysort _mingrp: gen long _ncat = _N
		replace _mingrp = "Other" if _mingrp!="Unknown" & _ncat < 1000
		drop _ncat

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'

		* counts & sort
		contract _mingrp, freq(N)
		gsort -N _mingrp

		set scheme s1mono
		graph hbar (sum) N, ///
			over(_mingrp, sort(1) descending label(labsize(small))) ///
			bargap(15) ///
			ytitle("") ///
			title("Jobs: Minimum Education") ///
			note("N = `Nused_fmt'", size(small)) ///
			legend(off) xsize(10) ysize(6)

		graph export "$inputs/fig_jobs_min_education.pdf", as(pdf) replace
	restore

*---- SALARY RANGE (FROM/TO): two bar charts combined (common bins) --------

	* Bin labels reused for both vars
	label define lsal 1 "0–9,999" 2 "10–14,999" 3 "15–24,999" 4 "25–39,999" ///
					 5 "40–59,999" 6 "60–99,999" 7 "100,000+", replace

	*--------------------------- FROM ------------------------------------------
	
	preserve
		keep sal_from_num currency_unit
		keep if currency_unit == "PKR"
		drop if missing(sal_from_num) | sal_from_num<0

		quietly count
		local Nfrom = r(N)
		local Nfrom_fmt : display %12.0gc `Nfrom'

		gen byte bfrom = .
		replace bfrom = 1 if inrange(sal_from_num,      0,   9999)
		replace bfrom = 2 if inrange(sal_from_num,  10000,  14999)
		replace bfrom = 3 if inrange(sal_from_num,  15000,  24999)
		replace bfrom = 4 if inrange(sal_from_num,  25000,  39999)
		replace bfrom = 5 if inrange(sal_from_num,  40000,  59999)
		replace bfrom = 6 if inrange(sal_from_num,  60000,  99999)
		replace bfrom = 7 if sal_from_num >= 100000 & sal_from_num < .
		label values bfrom lsal

		contract bfrom, freq(N)
		gen double Nk = N/1000   // thousands

		set scheme s1mono
		graph bar (sum) Nk, ///
			over(bfrom, label(valuelabel labsize(small))) ///
			bargap(20) ///
			ylabel(, grid labsize(small) format(%9.0fc)) ///
			ytitle("Jobs (thousands)") ///
			title("Salary Range — From", size(medsmall)) ///
			note("N = `Nfrom_fmt'", size(small)) ///
			legend(off) ///
			name(g_from, replace)
	restore

	*---------------------------- TO -------------------------------------------
	
	preserve
		keep sal_to_num currency_unit
		keep if currency_unit == "PKR"
		drop if missing(sal_to_num) | sal_to_num<0

		quietly count
		local Nto = r(N)
		local Nto_fmt : display %12.0gc `Nto'

		gen byte bto = .
		replace bto = 1 if inrange(sal_to_num,      0,   9999)
		replace bto = 2 if inrange(sal_to_num,  10000,  14999)
		replace bto = 3 if inrange(sal_to_num,  15000,  24999)
		replace bto = 4 if inrange(sal_to_num,  25000,  39999)
		replace bto = 5 if inrange(sal_to_num,  40000,  59999)
		replace bto = 6 if inrange(sal_to_num,  60000,  99999)
		replace bto = 7 if sal_to_num >= 100000 & sal_to_num < .
		label values bto lsal

		contract bto, freq(N)
		gen double Nk = N/1000   // thousands

		set scheme s1mono
		graph bar (sum) Nk, ///
			over(bto, label(valuelabel labsize(small))) ///
			bargap(20) ///
			ylabel(, grid labsize(small) format(%9.0fc)) ///
			ytitle("Jobs (thousands)") ///
			title("Salary Range — To", size(medsmall)) ///
			note("N = `Nto_fmt'", size(small)) ///
			legend(off) ///
			name(g_to, replace)
	restore

	*--------------------------- COMBINE & EXPORT -----------------------------
	
	graph combine g_from g_to, rows(2) cols(1) ///
		title("Jobs: Posted Salary Ranges (Only PKR)", size(medium)) ///
		imargin(2 2 2 2) graphregion(margin(4 4 4 4)) xsize(10) ysize(8)

	graph export "$inputs/fig_jobs_salary_fromto_bars_2x1.pdf", as(pdf) replace

*---- JOB CREATED YEAR: bar chart ----------------------------------------------

	preserve
		keep created_yr
		drop if missing(created_yr)

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'

		contract created_yr, freq(N)
		sort created_yr

		set scheme s1mono
		graph bar (sum) N, ///
			over(created_yr, label(angle(vertical) labsize(small))) ///
			bargap(20) ///
			ylabel(, grid labsize(small) format(%12.0gc)) ///
			ytitle("Jobs (count)") ///
			title("Jobs: Created Year", size(large)) ///
			note("N = `Nused_fmt'", size(small)) ///
			legend(off) ///
			xsize(10) ysize(6)

		graph export "$inputs/fig_jobs_created_year.pdf", as(pdf) replace
	restore
		
*---- JOBS CREATED BY MONTH in 2024: bar chart (show all 12 months) --------

	preserve
		keep created_yr created_mo
		keep if created_yr == 2024
		drop if missing(created_mo)

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'

		* counts by month present in the data
		contract created_mo, freq(N)
		tempfile cnts
		save "`cnts'", replace

		* make a full 1..12 scaffold so months with 0 count appear
		clear
		set obs 12
		gen created_mo = _n
		merge 1:1 created_mo using "`cnts'", nogenerate
		replace N = 0 if missing(N)

		* month labels
		label define lmo 1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" 8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec", replace
		label values created_mo lmo

		set scheme s1mono
		graph bar (sum) N, ///
			over(created_mo, label(valuelabel angle(vertical) labsize(small))) ///
			bargap(20) ///
			ylabel(, grid labsize(small) format(%12.0gc)) ///
			ytitle("Jobs (count)") ///
			title("Jobs: Created by Month — 2024", size(large)) ///
			note("N = `Nused_fmt'", size(small)) ///
			legend(off) ///
			xsize(10) ysize(6)

		graph export "$inputs/fig_jobs_created_month_2024.pdf", as(pdf) replace
	restore

	
*---- EXPERIENCE (REQ vs. MAX): 0–10 by year, 11+ bucket; y-axis in thousands

	* Value labels shared by both charts
	label define lyrs 0 "0", replace
	forvalues y=1/10 {
		label define lyrs `y' "`y'", add
	}
	label define lyrs 11 "11+", add

	*--------------------------- REQUIRED -------------------------------------
	
	preserve
		keep req_exp_yrs
		drop if missing(req_exp_yrs)

		quietly count
		local Nreq   = r(N)
		local Nreq_f : display %12.0gc `Nreq'

		gen byte req_cat = .
		forvalues y=0/10 {
			replace req_cat = `y' if req_exp_yrs==`y'
		}
		replace req_cat = 11 if req_exp_yrs>=11 & req_exp_yrs<.

		label values req_cat lyrs

		contract req_cat, freq(N)
		sort req_cat
		gen double Nk = N/1000  // thousands

		set scheme s1mono
		graph bar (sum) Nk, ///
			over(req_cat, label(valuelabel angle(vertical) labsize(vsmall))) ///
			bargap(15) ///
			ylabel(, grid labsize(small) format(%9.0fc)) ///
			ytitle("Jobs (thousands)") ///
			title("Required Experience", size(medsmall)) ///
			note("N = `Nreq_f'", size(small)) ///
			legend(off) ///
			name(g_req, replace)
	restore

	*---------------------------- MAXIMUM ------------------------------------
	
	preserve
		keep max_exp_yrs
		drop if missing(max_exp_yrs)

		quietly count
		local Nmax   = r(N)
		local Nmax_f : display %12.0gc `Nmax'

		gen byte max_cat = .
		forvalues y=0/10 {
			replace max_cat = `y' if max_exp_yrs==`y'
		}
		replace max_cat = 11 if max_exp_yrs>=11 & max_exp_yrs<.

		label values max_cat lyrs

		contract max_cat, freq(N)
		sort max_cat
		gen double Nk = N/1000  // thousands

		set scheme s1mono
		graph bar (sum) Nk, ///
			over(max_cat, label(valuelabel angle(vertical) labsize(vsmall))) ///
			bargap(15) ///
			ylabel(, grid labsize(small) format(%9.0fc)) ///
			ytitle("Jobs (thousands)") ///
			title("Maximum Experience", size(medsmall)) ///
			note("N = `Nmax_f'", size(small)) ///
			legend(off) ///
			name(g_max, replace)
	restore

	*--------------------------- COMBINE & EXPORT ----------------------------
	
	graph combine g_req g_max, rows(2) cols(1) ///
		title("Jobs: Experience Requirements (Years)", size(large)) ///
		imargin(2 2 2 2) graphregion(margin(4 4 4 4)) xsize(11) ysize(8)

	graph export "$inputs/fig_jobs_experience_11plus.pdf", as(pdf) replace
	

*---- AGE REQUIREMENTS (MIN vs. MAX): observed ages only; y-axis in thousands ----

	*--------------------------- MIN AGE -----------------------------------------
	
	preserve
		keep min_age_num
		drop if missing(min_age_num)

		quietly count
		local Nmin   = r(N)
		local Nmin_f : display %12.0gc `Nmin'

		contract min_age_num, freq(N)
		sort min_age_num
		gen double Nk = N/1000  // thousands

		set scheme s1mono
		graph bar (sum) Nk, ///
			over(min_age_num, label(labsize(vsmall) angle(vertical))) ///
			bargap(10) ///
			ylabel(, grid labsize(small) format(%9.0fc)) ///
			ytitle("Jobs (thousands)") ///
			title("Minimum Age", size(medsmall)) ///
			note("N = `Nmin_f'", size(small)) ///
			legend(off) ///
			name(g_minage, replace)
	restore

	*--------------------------- MAX AGE -----------------------------------------
	
	preserve
		keep max_age_num
		drop if missing(max_age_num)

		quietly count
		local Nmax   = r(N)
		local Nmax_f : display %12.0gc `Nmax'

		contract max_age_num, freq(N)
		sort max_age_num
		gen double Nk = N/1000  // thousands

		set scheme s1mono
		graph bar (sum) Nk, ///
			over(max_age_num, label(labsize(vsmall) angle(vertical))) ///
			bargap(10) ///
			ylabel(, grid labsize(small) format(%9.0fc)) ///
			ytitle("Jobs (thousands)") ///
			title("Maximum Age", size(medsmall)) ///
			note("N = `Nmax_f'", size(small)) ///
			legend(off) ///
			name(g_maxage, replace)
	restore

	*--------------------------- COMBINE & EXPORT --------------------------------
	
	graph combine g_minage g_maxage, rows(2) cols(1) ///
		title("Jobs: Age Requirements", size(medium)) ///
		imargin(2 2 2 2) graphregion(margin(4 4 4 4)) xsize(11) ysize(8)

	graph export "$inputs/fig_jobs_age_minmax.pdf", as(pdf) replace

		
*---- TARGET GENDER: composition table (Unknown for missing) ------------------

	preserve
		keep gender_str
		replace gender_str = ustrtrim(gender_str)

		// build display variable
		gen str20 _gender = cond(gender_str=="", "Unknown", gender_str)

		// enforce row order via encode + custom label
		encode _gender, gen(_gender_ord)
		label define __lg 1 "Female" 2 "Male" 3 "No Preference" 4 "Transgender" 5 "Unknown", replace
		label values _gender_ord __lg

		quietly count
		local Nused     = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		// tabulate and export as LaTeX fragment
		estpost tab _gender_ord, nototal

		esttab using "$inputs/tab_jobs_gender.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			coeflabels(1 "Female" 2 "Male" 3 "No Preference" 4 "Transgender" 5 "Unknown") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' ///
					"\toprule" `NL' ///
					" & N & \% of total \\" `NL' ///
					"\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Target gender}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

*---- TARGET COUNTRY: composition table (Other if <100; Unknown for missing) ----

	preserve
		keep country_name
		replace country_name = ustrtrim(country_name)

		// Map missing/blank to "Unknown"
		gen str40 _ctry = cond(country_name=="", "Unknown", country_name)

		// Count per country, then collapse small ones to "Other"
		bysort _ctry: gen long _nobs = _N
		replace _ctry = "Other" if _ctry!="Unknown" & _nobs < 100

		// Tab + export
		quietly count
		local Nused     = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		estpost tab _ctry, nototal

		esttab using "$inputs/tab_jobs_target_country.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' ///
					"\toprule" `NL' ///
					" & N & \% of total \\" `NL' ///
					"\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Target country}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

*---- TARGET INDUSTRY: composition table (Other < 1,000; LaTeX-safe labels) ----

	preserve
		// 1) Build buckets + ordered labels
		keep industry_str
		replace industry_str = ustrtrim(industry_str)

		gen str80 _industry = cond(industry_str=="", "Unknown", industry_str)

		bysort _industry: gen long _ncat = _N
		replace _industry = "Other" if _ncat < 1000 & _industry != "Unknown"
		drop _ncat

		// counts by bucket to define order
		contract _industry, freq(N)
		gsort -N _industry

		// order: big-to-small (excluding Other/Unknown), then Other, then Unknown
		local order
		quietly {
			forvalues i = 1/`=_N' {
				local nm = _industry[`i']
				if "`nm'"!="Other" & "`nm'"!="Unknown" {
					local order `"`order' "`nm'""'
				}
			}
		}
		local order `"`order' "Other" "Unknown""'

		// numeric order codes
		gen int _industry_ord = .
		local i = 1
		foreach nm of local order {
			replace _industry_ord = `i' if _industry=="`nm'"
			local ++i
		}

		// LaTeX-safe label to avoid breaking on & or %
		gen str100 _lab = subinstr(_industry, "&", "\&", .)
		replace   _lab = subinstr(_lab, "%", "\%", .)

		// build coeflabels() macro using sanitized _lab
		sort _industry_ord
		local cl
		forvalues j = 1/`=_N' {
			local rnum = _industry_ord[`j']
			local rlab = _lab[`j']
			local cl `"`cl' `rnum' "`rlab'""'
		}

		// save lookup to tempfile
		keep _industry _industry_ord
		duplicates drop
		tempfile t_lookup
		save `t_lookup'
	restore

	// 2) Back to the full data
	preserve
		keep industry_str
		replace industry_str = ustrtrim(industry_str)
		gen str80 _industry = cond(industry_str=="", "Unknown", industry_str)
		bysort _industry: gen long _ncat = _N
		replace _industry = "Other" if _ncat < 1000 & _industry != "Unknown"
		drop _ncat

		merge m:1 _industry using `t_lookup', keep(1 3) nogen

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		estpost tab _industry_ord, nototal

		esttab using "$inputs/tab_jobs_industry.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			coeflabels(`cl') ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' ///
					"\toprule" `NL' " & N & \% of total \\" `NL' "\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Target industry}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize Other = categories with < 1{,}000 jobs;\quad N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

		
*---- JOB IS DELETED: composition table ---------------------------------------

	preserve
		keep isdeleted

		// map 0/1 to readable labels
		gen str12 _delgrp = ""
		replace _delgrp = "Not Deleted" if isdeleted==0
		replace _delgrp = "Deleted"     if isdeleted==1

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		// tabulate and export
		estpost tab _delgrp, nototal

		esttab using "$inputs/tab_jobs_isdeleted.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' ///
					"\toprule" `NL' ///
					" & N & \% of total \\" `NL' ///
					"\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Job marked deleted}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

	
********************************************
**# COMPANIES
********************************************	

*--- Load ----------------------------------------------------

	use "$int/companies_int.dta", clear

*---- NUMBER OF OFFICES: composition table (with Unknown) --------------------

	preserve
		keep nooffices_num

		* Build display groups: numeric as text; missing -> "Unknown"
		gen str20 _offices_grp = cond(missing(nooffices_num), "Unknown", string(nooffices_num, "%9.0g"))

		quietly count
		local Nall = r(N)
		local Nall_fmt : display %12.0gc `Nall'
		local NL = char(10)

		estpost tab _offices_grp, nototal

		esttab using "$inputs/tab_companies_nooffices.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' ///
					"\toprule" `NL' ///
					" & N & \% of total \\" `NL' ///
					"\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Number of Offices}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize N = `Nall_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

*---- COMPANY STATUS: composition table (with Unknown) -----------------------

	preserve
		keep company_status
		replace company_status = ustrtrim(company_status)

		* Map to 5 buckets (case-insensitive)
		gen str10 _status = ""
		replace _status = "Unknown"  if missing(company_status) | company_status==""
		replace _status = "Invalid"  if _status=="" & lower(company_status)=="invalid"
		replace _status = "Pending"  if _status=="" & lower(company_status)=="pending"
		replace _status = "Valid"    if _status=="" & lower(company_status)=="valid"
		replace _status = "Verified" if _status=="" & lower(company_status)=="verified"

		* Desired display order
		gen byte _status_ord = .
		replace _status_ord = 1 if _status=="Verified"
		replace _status_ord = 2 if _status=="Valid"
		replace _status_ord = 3 if _status=="Pending"
		replace _status_ord = 4 if _status=="Invalid"
		replace _status_ord = 5 if _status=="Unknown"

		* Nice value labels for the numeric order var
		label define __lstat 1 "Verified" 2 "Valid" 3 "Pending" 4 "Invalid" 5 "Unknown", replace
		label values _status_ord __lstat

		quietly count
		local Nall = r(N)
		local Nall_fmt : display %12.0gc `Nall'
		local NL = char(10)

		* Tabulate with estpost (use the ordered numeric; supply readable row labels)
		estpost tab _status_ord, nototal

		local cl `" 1 "Verified" 2 "Valid" 3 "Pending" 4 "Invalid" 5 "Unknown" "'

		esttab using "$inputs/tab_companies_status.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			coeflabels(`cl') ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' ///
					"\toprule" `NL' ///
					" & N & \% of total \\" `NL' ///
					"\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Company verification status}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize N = `Nall_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

*---- EMPLOYEES: bar chart of counts by bucket -----------------------------

	preserve
		keep emp_bucket
		drop if missing(emp_bucket)

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'

		label define lempb 1 "1–10" 2 "11–50" 3 "51–100" 4 "101–500" ///
						  5 "501–1000" 6 "1001–5000" 7 "5001+"
		label values emp_bucket lempb

		* collapse to counts in the set order
		contract emp_bucket, freq(N)
		sort emp_bucket

		set scheme s1mono
		graph bar (sum) N, ///
			over(emp_bucket, label(labsize(small))) ///
			bargap(20) ///
			ylabel(, grid labsize(small) format(%12.0gc)) ///
			ytitle("Companies (count)") ///
			title("Companies: Number of Employees", size(large)) ///
			note("N = `Nused_fmt'", size(small)) ///
			legend(off) ///
			xsize(10) ysize(6)

		graph export "$inputs/fig_companies_emp_bucket_counts.pdf", as(pdf) replace
	restore

*---- CREATED YEAR: bar chart of counts -----------------------------------

	preserve
		keep created_yr
		drop if missing(created_yr)

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'

		contract created_yr, freq(N)
		sort created_yr

		set scheme s1mono
		graph bar (sum) N, ///
			over(created_yr, label(labsize(vsmall) angle(90))) ///
			bargap(15) ///
			ylabel(, grid labsize(small) format(%12.0gc)) ///
			ytitle("Companies (count)") ///
			title("Companies: Created Year", size(large)) ///
			note("N = `Nused_fmt'", size(small)) ///
			legend(off) ///
			xsize(10) ysize(6)

		graph export "$inputs/fig_companies_created_year.pdf", as(pdf) replace
	restore

*---- COMPANY TYPE: composition table -------------------------------------

	preserve
		keep company_type_str
		replace company_type_str = ustrtrim(company_type_str)
		drop if missing(company_type_str) | company_type_str==""

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		estpost tab company_type_str, nototal

		esttab using "$inputs/tab_companies_companytype.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' ///
					"\toprule" `NL' ///
					" & N & \% of total \\" `NL' ///
					"\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Company ownership type}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

*---- OPERATING SINCE: bar chart of counts by year ------------------------

	preserve
		keep opsince_yr
		drop if missing(opsince_yr)

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'

		contract opsince_yr, freq(N)
		sort opsince_yr

		set scheme s1mono
		graph bar (sum) N, ///
			over(opsince_yr, label(angle(90) labsize(tiny))) ///
			bargap(15) ///
			ylabel(, grid labsize(small) format(%12.0gc)) ///
			ytitle("Companies (count)") ///
			title("Companies: Operating Since (Year)", size(large)) ///
			note("N = `Nused_fmt'", size(small)) ///
			legend(off) xsize(20) ysize(10)

		graph export "$inputs/fig_companies_opsince_year.pdf", as(pdf) replace
	restore


*---- INDUSTRY: composition table (Other < 1,000; Unknown for missing) --------

	preserve
		keep industry_str
		replace industry_str = ustrtrim(industry_str)

		* Build groups
		gen str100 _grp = industry_str
		replace _grp = "Unknown" if missing(_grp) | _grp==""

		bysort _grp: gen long _n_in_grp = _N
		replace _grp = "Other" if _grp!="Unknown" & _n_in_grp < 1000
		drop _n_in_grp

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		* Encode to numeric with value labels
		encode _grp, gen(_grp_ord)

		* Tabulate (numeric) for estpost/esttab
		estpost tab _grp_ord, nototal

		* Build coeflabels() from the encoded levels (escape LaTeX specials)
		levelsof _grp_ord, local(levels)
		local vl : value label _grp_ord
		local cl ""
		foreach v of local levels {
			local L : label (`vl') `v'
			local L = subinstr("`L'","&","\&",.)
			local L = subinstr("`L'","%","\%",.)
			local L = subinstr("`L'","_","\_",.)
			local cl `"`cl' `v' "`L'""'
		}

		esttab using "$inputs/tab_companies_industry.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			coeflabels(`cl') collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' "\toprule" `NL' ///
					" & N & \% of total \\" `NL' "\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Industry}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

*---- COUNTRY: table (Other < 50; Unknown for missing) ------------------------

	preserve
		keep country_name
		replace country_name = ustrtrim(country_name)

		* Grouping
		gen str80 _grp = country_name
		replace _grp = "Unknown" if missing(_grp) | _grp==""

		bysort _grp: gen long _n_in_grp = _N
		replace _grp = "Other" if _grp!="Unknown" & _n_in_grp < 50
		drop _n_in_grp

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		* Encode to numeric to control row labels cleanly
		encode _grp, gen(_grp_ord)

		* Tabulate encoded variable
		estpost tab _grp_ord, nototal

		* Build coeflabels() from value labels, escaping LaTeX specials
		levelsof _grp_ord, local(levels)
		local vl : value label _grp_ord
		local cl ""
		foreach v of local levels {
			local L : label (`vl') `v'
			local L = subinstr("`L'","&","\&",.)
			local L = subinstr("`L'","%","\%",.)
			local L = subinstr("`L'","_","\_",.)
			local cl `"`cl' `v' "`L'""'
		}

		esttab using "$inputs/tab_companies_country.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			coeflabels(`cl') collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' "\toprule" `NL' ///
					" & N & \% of total \\" `NL' "\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Country}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore


*---- CITY: table (Pakistan cities <1,000 -> "Other - Pakistan"; non-Pakistan -> "Non-Pakistan") ----

	preserve
		keep city_name country_name
		replace city_name   = ustrtrim(city_name)
		replace country_name = ustrtrim(country_name)

		* Count by (country, city)
		bysort country_name city_name: gen long _n_cc = _N

		* Build grouping
		gen str60 _grp = ""
		replace _grp = "Unknown"            if missing(city_name) | city_name==""
		replace _grp = city_name            if _grp=="" & country_name=="Pakistan" & _n_cc>=1000
		replace _grp = "Other - Pakistan"   if _grp=="" & country_name=="Pakistan" & _n_cc<1000
		replace _grp = "Non-Pakistan"       if _grp=="" & country_name!="Pakistan"

		quietly count
		local Nused      = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		* Tabulate and build readable labels (escape LaTeX specials)
		estpost tab _grp, nototal
		local labs `e(labels)'
		local cl ""
		local i = 1
		foreach L of local labs {
			local L2 = subinstr("`L'","&","\&",.)
			local L3 = subinstr("`L2'","%","\%",.)
			local L4 = subinstr("`L3'","_","\_",.)
			local L5 = subinstr("`L4'","\","\",.)
			local cl `"`cl' `i' "`L5'""'
			local ++i
		}

		esttab using "$inputs/tab_companies_city.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			coeflabels(`cl') collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' "\toprule" `NL' ///
					" & N & \% of total \\" `NL' "\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{City (grouped)}}\\ ") ///
			postfoot("\midrule" `NL' "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore
		
	
********************************************
**# APPLICATIONS
********************************************	

*--- Load ----------------------------------------------------

	use "$int/applications_sample_int.dta", clear	
	
*---- APPLICATIONS: bar chart by month–year -----------------------------------

	preserve
		keep apply_yr apply_mo
		drop if missing(apply_yr) | missing(apply_mo)

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'

		* Monthly time and counts
		gen int apply_tm = ym(apply_yr, apply_mo)
		contract apply_tm, freq(N)
		sort apply_tm

		* Build xlabel list: only January months, label like "January 2025"
		gen byte _is_jan = month(dofm(apply_tm))==1
		levelsof apply_tm if _is_jan, local(jans)

		local xlbl
		foreach t of local jans {
			local lab : display %tdMonth_CCYY dofm(`t')
			local xlbl `"`xlbl' `t' "`lab'" "'
		}

		set scheme s1mono
		twoway ///
			(bar N apply_tm, barwidth(0.9) base(0)), ///
			xlabel(`xlbl', angle(45) labsize(vsmall)) ///
			xtitle(" ") ///
			ylabel(, grid labsize(small) format(%12.0gc)) ///
			ytitle("Applications (count)") ///
			title("Applications by Month–Year", size(large)) ///
			note("N = `Nused_fmt' (Applications Subsample)", size(small)) ///
			legend(off) xsize(13) ysize(6)

		graph export "$inputs/fig_apps_by_monthyear_jans.pdf", as(pdf) replace
	restore

*---- EMPLOYER APPLICATION STATUS: composition table -------------------------

	preserve
		keep emp_status
		replace emp_status = ustrtrim(emp_status)

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		estpost tab emp_status, nototal

		esttab using "$inputs/tab_apps_empstatus.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' "\toprule" `NL' ///
					" & N & \% of total \\" `NL' "\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Employer application status}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore
		
*---- TEST STATUS: composition table (Unknown for missing) --------------------

	preserve
		keep test_status
		replace test_status = ustrtrim(test_status)

		gen str20 _grp = test_status
		replace _grp = "Unknown" if missing(_grp) | _grp==""

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		estpost tab _grp, nototal

		esttab using "$inputs/tab_apps_test_status.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' ///
					"\toprule" `NL' ///
					" & N & \% of total \\" `NL' ///
					"\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Test status}}\\ ") ///
			postfoot("\midrule" `NL' ///
					 "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

	
*---- APPLICATION SALARIES: two bar charts ------------------------------------

	capture label drop _lsal
	label define _lsal 1 "0–9,999" 2 "10–14,999" 3 "15–24,999" 4 "25–39,999" ///
					   5 "40–59,999" 6 "60–99,999" 7 "100,000+"

	* CURRENT --------------------------------------------------------------------
	
	preserve
		keep cursal_app
		drop if missing(cursal_app) | cursal_app<0

		local Ncur = _N
		local Ncur_fmt : display %12.0gc `Ncur'

		gen byte b_cur = .
		replace b_cur = 1 if inrange(cursal_app,      0,   9999)
		replace b_cur = 2 if inrange(cursal_app,  10000,  14999)
		replace b_cur = 3 if inrange(cursal_app,  15000,  24999)
		replace b_cur = 4 if inrange(cursal_app,  25000,  39999)
		replace b_cur = 5 if inrange(cursal_app,  40000,  59999)
		replace b_cur = 6 if inrange(cursal_app,  60000,  99999)
		replace b_cur = 7 if  cursal_app >= 100000 & cursal_app < .
		label values b_cur _lsal

		contract b_cur, freq(N)
		sort b_cur

		set scheme s1mono
		graph bar (sum) N, over(b_cur, label(labsize(small))) bargap(20) ///
			ylabel(, grid labsize(small) format(%12.0gc)) ///
			ytitle("Applications (count)") ///
			title("Current salary", size(medsmall)) ///
			note("N =`Ncur_fmt'", size(small)) legend(off) ///
			name(g_cur, replace)
	restore

	* EXPECTED -------------------------------------------------------------------
	
	preserve
		keep expsal_app
		drop if missing(expsal_app) | expsal_app<0

		local Nexp = _N
		local Nexp_fmt : display %12.0gc `Nexp'

		gen byte b_exp = .
		replace b_exp = 1 if inrange(expsal_app,      0,   9999)
		replace b_exp = 2 if inrange(expsal_app,  10000,  14999)
		replace b_exp = 3 if inrange(expsal_app,  15000,  24999)
		replace b_exp = 4 if inrange(expsal_app,  25000,  39999)
		replace b_exp = 5 if inrange(expsal_app,  40000,  59999)
		replace b_exp = 6 if inrange(expsal_app,  60000,  99999)
		replace b_exp = 7 if  expsal_app >= 100000 & expsal_app < .
		label values b_exp _lsal

		contract b_exp, freq(N)
		sort b_exp

		set scheme s1mono
		graph bar (sum) N, over(b_exp, label(labsize(small))) bargap(20) ///
			ylabel(, grid labsize(small) format(%12.0gc)) ///
			ytitle("Applications (count)") ///
			title("Expected salary", size(medsmall)) ///
			note("N =`Nexp_fmt'", size(small)) legend(off) ///
			name(g_exp, replace)
	restore

	* COMBINE --------------------------------------------------------------------
	
	graph combine g_cur g_exp, rows(2) cols(1) ///
		title("Applications: Salary Ranges (PKR?)", size(large)) ///
		imargin(2 2 2 2) graphregion(margin(4 4 4 4)) xsize(10) ysize(7)

	graph export "$inputs/fig_apps_salaries_2x1.pdf", as(pdf) replace

	
*---- APPLICATIONS: Salary Gap (Expected - Current) --------------------------

	preserve
		keep sal_gap_app
		drop if missing(sal_gap_app)

		quietly count
		local Nused = r(N)
		local Nused_fmt : display %12.0gc `Nused'
		local NL = char(10)

		gen str12 _gap = ""
		replace _gap = "<=0"               if sal_gap_app <= 0
		replace _gap = "1-4,999"           if inrange(sal_gap_app,     1,   4999)
		replace _gap = "5-9,999"           if inrange(sal_gap_app,  5000,   9999)
		replace _gap = "10-14,999"         if inrange(sal_gap_app, 10000,  14999)
		replace _gap = "15-24,999"         if inrange(sal_gap_app, 15000,  24999)
		replace _gap = "25-39,999"         if inrange(sal_gap_app, 25000,  39999)
		replace _gap = "40-59,999"         if inrange(sal_gap_app, 40000,  59999)
		replace _gap = "60-99,999"         if inrange(sal_gap_app, 60000,  99999)
		replace _gap = "100,000+"          if sal_gap_app >= 100000 & sal_gap_app < .

		encode _gap, gen(_gap_o)
		label define _lgap ///
			1 "<=0" 2 "1-4,999" 3 "5-9,999" 4 "10-14,999" 5 "15-24,999" ///
			6 "25-39,999" 7 "40-59,999" 8 "60-99,999" 9 "100,000+", replace
		label values _gap_o _lgap

		estpost tab _gap_o, nototal
		esttab using "$inputs/tab_apps_salary_gap.tex", ///
			cells("b(fmt(%12.0gc)) pct(fmt(%5.2f))") ///
			collabels(none) label nonumber noobs nomtitle ///
			booktabs fragment replace ///
			prehead("\begin{tabular}{lrr}" `NL' "\toprule" `NL' ///
					" & N & \% of total \\" `NL' "\midrule" `NL' ///
					"\multicolumn{3}{l}{\textbf{Salary gap}}\\ ") ///
			postfoot("\midrule" `NL' "\multicolumn{3}{l}{\footnotesize N = `Nused_fmt'}\\" `NL' ///
					 "\bottomrule" `NL' "\end{tabular}" `NL')
	restore

		
********************************************
********************************************
**# End of do file
********************************************
********************************************	
	
	
	
	
	
	
	
	
	
	
	
	
	
	




