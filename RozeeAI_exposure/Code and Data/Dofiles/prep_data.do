clear all 

cap log close 
set more off 

global path "D:\Dropbox\Rozee AI Project\Code and Data"
global output_dir "${path}/Archive/12_Output"
global data "${path}/Analysis Data"

*global data_dir "${path}/EREA Site - Rozee/ADB_20250418 (1)/ADB_20250418"
*global tables "${path}/12_Output/21_RawTables"
*global graphs "${path}/12_Output/31_Graphs"
*global ai_data "${path}/11_Input/AI Exposure"

/*==============================================================================
	Merge all the matched datasets 
 ==============================================================================*/

/*--------------- Extract text (full dataset) ---------------*/
//Main 
import delimited "${output_dir}/1_ExtractedData/jobsdesc_extract.csv", ///
	varnames(1) clear bindquote(strict) maxquotedrows(1000)

keep job_id jid num_tasks 
save "${output_dir}/40_Tempfile/jobids.dta", replace


/*--------------- Previous matched tasks ---------------*/

//Main 
import delimited "${output_dir}/1_ExtractedData/tmain_match_tasks.csv", ///
	varnames(1) clear bindquote(strict) maxquotedrows(1000)
	
keeporder jid job_id title onet_task_id onet_task_text onet_soc_code occupation_title 

gen filetype = 1 
tempfile prev_main 
save `prev_main', replace

//Less 
import delimited "${output_dir}/1_ExtractedData/tless_match_tasks.csv", ///
	varnames(1) clear bindquote(strict) maxquotedrows(1000)

keeporder jid job_id title onet_task_id onet_task_text onet_soc_code occupation_title 
gen filetype = 2
tempfile prev_less
save `prev_less', replace

//Great 
import delimited "${output_dir}/1_ExtractedData/tgreat_match_tasks.csv", ///
	varnames(1) clear bindquote(strict) maxquotedrows(1000)

keeporder jid job_id title onet_task_id onet_task_text onet_soc_code occupation_title 
gen filetype = 3
tempfile prev_great
save `prev_great', replace

//Append and save
use `prev_main', clear
append using `prev_less'
append using `prev_great'

gen orig_order = _n
bysort jid (orig_order): gen rank = _n
drop orig_order 

merge m:1 jid job_id using "${output_dir}/40_Tempfile/jobids.dta", keep(match master)

drop if jid == .
tab _merge 
drop _merge

save "${output_dir}/40_Tempfile/matched_tasks.dta", replace


/*--------------- JID missing ---------------*/

//Main 
import delimited "${output_dir}/1_ExtractedData (Addition)/jidmissing_match_main_tasks.csv", ///
	varnames(1) clear bindquote(strict) maxquotedrows(1000)

keeporder jid job_id title onet_task_id onet_task_text onet_soc_code occupation_title 
gen filetype = 4 
tempfile missing_main 
save `missing_main', replace

//Less
import delimited "${output_dir}/1_ExtractedData (Addition)/jidmissing_match_less_tasks.csv", ///
	varnames(1) clear bindquote(strict) maxquotedrows(1000)

keeporder jid job_id title onet_task_id onet_task_text onet_soc_code occupation_title 
gen filetype = 5
tempfile missing_less
save `missing_less', replace

//Great
import delimited "${output_dir}/1_ExtractedData (Addition)/jidmissing_match_great_tasks.csv", ///
	varnames(1) clear bindquote(strict) maxquotedrows(1000)
keeporder jid job_id title onet_task_id onet_task_text onet_soc_code occupation_title 
gen filetype = 6
tempfile missing_great
save `missing_great', replace

//Append and save
use `missing_main', clear
append using `missing_less', force
append using `missing_great', force 

gen orig_order = _n
bysort jid (orig_order): gen rank = _n
drop orig_order 

merge m:1 jid jid job_id using "${output_dir}/40_Tempfile/jobids.dta", keep(match master)

//Append to previous matched tasks
drop _merge 
append using "${output_dir}/40_Tempfile/matched_tasks.dta", force 

label def filetype ///
	1 "Previous Main" ///
	2 "Previous Less" ///
	3 "Previous Great" ///
	4 "Missing JID Main" ///
	5 "Missing JID Less" ///
	6 "Missing JID Great"
label val filetype filetype

//Save 
save "${output_dir}/40_Tempfile/matched_tasks_full.dta", replace


/*==============================================================================
	Clean up 
 ==============================================================================*/

use "${output_dir}/40_Tempfile/matched_tasks_full.dta", clear

drop if jid == .
isid jid rank 

sort jid rank
drop if rank > 15 

//Remove if more than 15 tasks per job
bysort jid: egen n_tasks = count(onet_task_id)

//Checks 
codebook jid 
sum n_tasks, detail 
disp 338170/338219*100

codebook onet_task_id onet_task_text
disp 58415/2612395*100

save "${output_dir}/40_Tempfile/matched_tasks_full.dta", replace


/*==============================================================================
	Merge with Eloundou data
 ==============================================================================*/

use "${output_dir}/40_Tempfile/matched_tasks_full.dta", clear
/*--------------- Previous matched tasks ---------------*/

preserve 
import excel "${path}/Archive/11_Input/ONET/Task Statements.xlsx", firstrow clear
rename TaskID onet_task_id
tempfile onet_tasks
save `onet_tasks', replace
restore 

merge m:1 onet_task_id using `onet_tasks', nogen keep(match master)

drop onet_task_text onet_soc_code occupation_title

rename ONETSOCCode onet_soc_code
rename Title occupation_title
rename Task onet_task_text

drop TaskType IncumbentsResponding Date DomainSource

sort jid onet_task_id

save "${data}/extracted_tasks.dta", replace

/*==============================================================================
	Clean Eloundou data and merge with extracted tasks
 ==============================================================================*/

import delimited "${path}/Archive/11_Input/AI Exposure/eloundou_onet_tasks.tsv", clear 
drop v1 onetsoccode tasktype title

rename taskid onet_task_id
rename task eloundou_task 

tempfile eloundou_tasks
save `eloundou_tasks', replace

use "${data}/extracted_tasks.dta", clear
merge m:1 onet_task_id using `eloundou_tasks', nogen keep(match master)

gen check_task = (eloundou_task == onet_task_text)
tab check_task
drop check_task eloundou_task

sort jid onet_task_id

save "${data}/extracted_tasks_ai.dta", replace

/*==============================================================================
	SOC Structure
 ==============================================================================*/

//SOC Structure
import excel "${path}/Archive/11_Input/ONET/SOC_Structure.xlsx", firstrow clear
replace DetailedOccupation = DetailedONETSOC if missing(DetailedOccupation)
drop DetailedONETSOC

foreach var in MajorGroup MinorGroup BroadOccupation {
    replace `var' = `var'[_n-1] if `var' == ""
}

gen onet_occupation = SOCorONETSOC2019Title if DetailedOccupation != ""
drop if DetailedOccupation == ""
drop SOCorONETSOC2019Title

replace DetailedOccupation = DetailedOccupation + ".00" if strpos(DetailedOccupation, ".") == 0

tempfile soc_num
save `soc_num', replace

//Major Group
import excel "${path}/Archive/11_Input/ONET/SOC_Structure.xlsx", firstrow clear
drop if MajorGroup == ""
keep MajorGroup SOCorONETSOC2019Title
rename SOCorONETSOC2019Title major_occupation_title
tempfile soc_major
save `soc_major', replace

//Minor Group 
import excel "${path}/Archive/11_Input/ONET/SOC_Structure.xlsx", firstrow clear
drop if MinorGroup == ""
keep MinorGroup SOCorONETSOC2019Title
rename SOCorONETSOC2019Title minor_occupation_title
tempfile soc_minor
save `soc_minor', replace

//Broad Occupation
import excel "${path}/Archive/11_Input/ONET/SOC_Structure.xlsx", firstrow clear
drop if BroadOccupation == ""
keep BroadOccupation SOCorONETSOC2019Title
rename SOCorONETSOC2019Title broad_occupation_title
tempfile soc_broad
save `soc_broad', replace

use `soc_num', clear
merge m:1 MajorGroup using `soc_major', nogen keep(match master)
merge m:1 MinorGroup using `soc_minor', nogen keep(match master)
merge m:1 BroadOccupation using `soc_broad', nogen keep(match master)

save "${data}/soc_structure.dta", replace

/*==============================================================================
	Save JID and Job title for occupation clustering
 ==============================================================================*/

/* ------------- Get SOC codes for previous ones ---------------*/
//Main 
import delimited "${output_dir}/1_ExtractedData/jobsdesc_onetsoc_tmain.csv", ///
	varnames(1) clear bindquote(strict) maxquotedrows(1000)

tempfile soc_prev_main 
save `soc_prev_main', replace

//Less
import delimited "${output_dir}/1_ExtractedData/jobsdesc_onetsoc_tless.csv", ///
	varnames(1) clear bindquote(strict) maxquotedrows(1000)

tempfile soc_prev_less
save `soc_prev_less', replace

//Great
import delimited "${output_dir}/1_ExtractedData/jobsdesc_onetsoc_tgreat.csv", ///
	varnames(1) clear bindquote(strict) maxquotedrows(1000)
tempfile soc_prev_great
save `soc_prev_great', replace

//Append and save
use `soc_prev_main', clear
append using `soc_prev_less'
append using `soc_prev_great'

drop jid 
merge m:1 job_id using "${output_dir}/40_Tempfile/jobids.dta", keep(match master) nogen 

tempfile soc_prev
save `soc_prev', replace

/* ------------- Get SOC codes for missing ones ---------------*/

//Main
import delimited "${output_dir}/1_ExtractedData (Addition)/jidmissing_match_main_occupations.csv", ///
	varnames(1) clear bindquote(strict) maxquotedrows(1000)
keep if rank == 1 
isid job_id 
drop rank occupation_explanation source_file

tempfile soc_missing_main
save `soc_missing_main', replace

//Less
import delimited "${output_dir}/1_ExtractedData (Addition)/jidmissing_match_less_occupations.csv", ///
	varnames(1) clear bindquote(strict) maxquotedrows(1000)
keep if rank == 1

duplicates drop job_id, force 

drop rank occupation_explanation source_file

tempfile soc_missing_less
save `soc_missing_less', replace

//Great
import delimited "${output_dir}/1_ExtractedData (Addition)/jidmissing_match_great_occupations.csv", ///
	varnames(1) clear bindquote(strict) maxquotedrows(1000)
keep if rank == 1

duplicates drop job_id, force 

drop rank occupation_explanation source_file

tempfile soc_missing_great
save `soc_missing_great', replace

//Append and save
use `soc_missing_main', clear
append using `soc_missing_less'
append using `soc_missing_great'

merge m:1 job_id using "${output_dir}/40_Tempfile/jobids.dta", keep(match master) nogen

append using `soc_prev', force
keep job_id jid onet_soc_code 

//Get job titles 
preserve 
use "${data}/extracted_tasks.dta", clear
keep job_id jid title 
duplicates drop	
tempfile jobs_title
save `jobs_title', replace
restore 

//Merge with job titles
merge m:1 job_id using `jobs_title', nogen keep(match master)

//Merge with SOC structure
rename onet_soc_code DetailedOccupation
merge m:1 DetailedOccupation using "${data}/soc_structure.dta", nogen keep(match master)

order jid title major_occupation_title minor_occupation_title broad_occupation_title onet_occupation 
gsort + jid 

bysort jid: egen max_major_group = mode(major_occupation_title), minmode 
bysort jid: egen max_minor_group = mode(minor_occupation_title), minmode
bysort jid: egen max_broad_occupation = mode(broad_occupation_title), minmode

keep jid title job_id max_broad_occupation
duplicates drop
drop if jid == .

save "${data}/job_titles_soc.dta", replace
