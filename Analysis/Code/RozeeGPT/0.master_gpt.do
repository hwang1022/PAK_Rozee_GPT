
******************************************
******************************************
**				   						**
**     MASTER DOFILE FOR ROZEE GPT		**
**				  						**
**				   						**
**	  Created by AB on Oct 17 2025		**
**				  						**
******************************************
******************************************

**********************
**# Packages
**********************

	local packagelist wbopendata ietoolkit

	foreach package in `packagelist' {
		which `package'
		if _rc ssc install `package'
	}
	
***********
**# Setup
***********
	
	* Harmonize settings across users
	ieboilstart, versionnumber(18.0)
    `r(version)'	
	
**********************
**# Programs
**********************

	* Convert CSV to DTA
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
	
	* Convert PKR to USD PPP
	program define pppconvert
		version 18
		syntax varname(numeric) , YEARvar(name) GENerate(name)

		tempvar _lnk
		frlink m:1 `yearvar', frame(ppp) generate(`_lnk')
		frget  ppp_pak_lcu_per_intdol, from(`_lnk')

		frame ppp: quietly summarize ppp_usa_usd_per_intdol if `yearvar'==2024
		scalar PPP_US_2024 = r(mean)

		gen double `generate' = .
		replace   `generate' = (`varlist' / ppp_pak_lcu_per_intdol) * PPP_US_2024 ///
			if inrange(`yearvar',2004,2024)

		label var `generate' "2024 USD (PPP) from `varlist'"
		drop `_lnk' ppp_pak_lcu_per_intdol
	end

*********************
**# Set Directories
*********************

	* Main Directory
	if c(username) == "abrockell" {
		global dir `"/Users/abrockell/Library/CloudStorage/Dropbox-HarvardUniversity/Alec Brockell/PAK_Rozee_GPT"'
	}
	else if c(username) == "lalfonsi" {
		global dir `"enter here"'
	}

	* Raw: CSV files
	global  in      	"$dir/Data/Raw/RozeeGPT/250918_Input_RozeeGPT"
	global  in2     	"$in/data-dict"

	* Raw: DTA files
	global  created     "$dir/Data/Raw/RozeeGPT/251017_Creation_RozeeGPT"
	global  created2    "$created/data-dict"

	* Cleaning
	global  cleaned  	"$dir/Data/Cleaned/RozeeGPT/251017_Cleaned_RozeeGPT"

	* Analysis
	global  vars     	"$dir/Data/Analysis/RozeeGPT/251017_Vars_Created_RozeeGPT"
	global  final   	"tbd"

	* Data dictionary
	global  dict    	"$created/data-dict"

	* Code
	global  code    	"$dir/Code/RozeeGPT"

*********************
**# Do
*********************
x
	do "$code/1.creation_gpt.do"
	do "$code/2.cleaning_gpt.do"
	do "$code/3.vars_creation_gpt.do"
	
********************************************
********************************************
**# End of do file
********************************************
********************************************
	
	
	
	
