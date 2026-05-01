
/*======================================================================*
 |  Project:    Rozee 
 |  Author:     AB
 |  File:       Converting and merging raw Rozee20years data
 |  Required:   Run 0.master.do before this file
 *======================================================================*/

********************************************
********************************************
**# Converting datasets
********************************************
********************************************

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
	
	set seed 251014
	sample 10000, count
	
	save "$merged/applications_sample.dta", replace

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
**# End of do file
********************************************
********************************************







