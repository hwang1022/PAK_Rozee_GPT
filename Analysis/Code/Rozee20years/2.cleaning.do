
/*======================================================================*
 |  Project:    Rozee 
 |  Author:     AB
 |  File:       Cleaning Rozee20years DTA files
 |  Required:   Run 1.creation.do before this file
 *======================================================================*/

************************************************
************************************************
**# USERS
************************************************
************************************************

*--- Load ----------------------------------------------------

	use "$merged/users.dta", clear
	
	isid user_id
	duplicates report

*--- Clean strings -----------------------------------------

	foreach v in gender_id maritalstatus industry_id careerlevel_id country_id city_id cursal expsal experience {
		replace `v' = trim(`v')
		replace `v' = "" if inlist(upper(`v'),"NULL",".","NA","N/A","NONE","MISSING")
	}

	foreach v in gender_id maritalstatus industry_id careerlevel_id {
		replace `v' = "" if `v'=="0"
	}
	
	* Marital Status
	tab 	maritalstatus 	if 	regexm(maritalstatus, "[^0-9]")
	replace maritalstatus = "683" if maritalstatus == "683\'"
	
	* Industry ID
	tab 	industry_id 	 if regexm(industry_id, "[^0-9]") // 6 industry_id non-numeric and cannot be identified in data-dict; 2,709 industry_id == -1
	replace industry_id = "" if regexm(industry_id, "[^0-9]") // setting these industry_id as missing
	
	* Experience
	replace experience = "0" if ustrregexm(experience, "^(?i)\s*fresh\s*$") // Fresh -> "0"
	
	replace experience = "Less than 1 Year" if ///
		ustrregexm(experience, "(?i)^\s*less\b.*\b(1|one)\b.*\byear\b")  | ///
		ustrregexm(experience, "(?i)^\s*less\b.*\b(1|one)\b\s*$")        | ///
		ustrregexm(experience, "(?i)^\s*less\b.*\byear\b")               | ///
		inlist(lower(experience),"less","less than 1","less than a year")
		
	replace experience = ustrregexs(1) if ///
		experience != "Less than 1 Year" & ///
		ustrregexm(experience, "^\s*([0-9]+).*")
		
	replace experience = "" if ///
		experience != "Less than 1 Year" & experience != "More than 35 Years" & !ustrregexm(experience, "^[0-9]+$")

	
*--- Numeric copies ----------------------------------------------------

	destring gender_id       , gen(gender_id_num)      
	destring maritalstatus   , gen(maritalstatus_num)   
	destring industry_id	 , gen(industry_id_num)
	destring careerlevel_id  , gen(careerlevel_id_num)  
	destring country_id      , gen(country_id_num)      
	destring city_id         , gen(city_id_num)         
	destring cursal          , gen(cursal_pkr)          
	destring expsal          , gen(expsal_pkr)          
	
*--- Labels for original variables ------------------------------------

	label var user_id            "User ID (original)"
	label var firstname          "First name (original)"
	label var lastname           "Last name (original)"
	label var fullname           "Full name (original)"
	label var gender_id          "Gender ID (original)"
	label var dobirth            "Date of birth (original)"
	label var cursal             "Current salary (original)"
	label var expsal             "Expected salary (original)"
	label var nationality_id     "Nationality ID (original)"
	label var maritalstatus      "Marital status (original)"
	label var created            "Datetime created (original)"
	label var last_modified      "Datetime last modified (original)"
	label var experience         "Years of experience (original)"
	label var industry_id        "Industry ID (original)"
	label var department_id      "Department ID (original)"
	label var city_id            "City ID (original)"
	label var country_id         "Country ID (original)"
	label var careerlevel_id     "Career level ID (original)"
	label var profile_access     "Public or private profile (original)"
	
*--- Compress and save ----------------------------------------------------

	compress
	save "$proc/users_proc.dta", replace
	
************************************************
************************************************
**# USERS EDUCATION
************************************************
************************************************

*--- Load ----------------------------------------------------

	use "$merged/users_education.dta", clear

	isid eduid
	duplicates report

*--- Clean strings -------------------------------------------

	foreach v in user_id edulevel degreetypeid degreemajorid degreemajorsub ///
				 highestdegreeid eduyear educountryid educityid createdon   ///
				 edugradetype edugradeval edugradeoutof schoolname schooltype {
		replace `v' = trim(`v')
		replace `v' = "" if inlist(upper(`v'),"NULL",".","NA","N/A","NONE","MISSING")
	}

	* common "0"-as-missing for id-like strings
	foreach v in degreetypeid degreemajorid degreemajorsub highestdegreeid ///
				 educountryid educityid eduyear {
		replace `v' = "" if `v'=="0"
	}

	replace edugradeoutof = "100" if edugradetype == "Percentage" | edugradeoutof == "-100"
	
	* ensure id/year/grade fields are numeric-only; if not, set to missing (keep truly empty as "")
	foreach v in degreetypeid highestdegreeid ///
				 educountryid educityid eduyear edugradeoutof {
		replace `v' = "" if regexm(`v', "[^0-9]")
	}
	

*--- Numeric copies ------------------------------------------

	destring degreetypeid     , gen(degreetypeid_num)
	//destring degreemajorid    , gen(degreemajorid_num) -- going to take a lot to clean this
	destring highestdegreeid  , gen(highestdegreeid_num)
	destring educountryid     , gen(educountryid_num)
	destring educityid        , gen(educityid_num)
	destring eduyear          , gen(eduyear_num)
	destring edugradeoutof    , gen(edugradeoutof_num)


*--- Labels for original variables ---------------------------

	label var eduid            "Education ID (original)"
	label var user_id          "User ID (original)"
	label var edulevel         "Education ID level (original)"
	label var degreetypeid     "Degree type ID (original)"
	label var degreemajorid    "Degree major ID (original)"
	label var degreemajorsub   "Degree major subject (original)"
	label var highestdegreeid  "Highest degree ID (original)"
	label var eduyear          "Graduation/education year (original)"
	label var educountryid     "Education country ID (original)"
	label var educityid        "Education city ID (original)"
	label var createdon        "Datetime created (original)"
	label var edugradetype     "Grade type (original)"
	label var edugradeval      "Grade value (original)"
	label var edugradeoutof    "Grade out of (original)"
	label var schoolname       "School name (original)"
	label var schooltype       "School type (original)"


*--- Compress and save ---------------------------------------

	compress
	save "$proc/users_education_proc.dta", replace
	
	
************************************************
************************************************
**# USERS EXPERIENCE
************************************************
************************************************

*--- Load ----------------------------------------------------

	use "$merged/users_experience.dta", clear

	isid expid
	duplicates report // POTENTIAL ISSUE: exactly 1M observations
	
*--- Clean strings -------------------------------------------

	foreach v in user_id jobtitle jobstart jobend jobcompanyid jobcompany ///
				 empcityid empcountryid createdon manage_team {
		replace `v' = trim(`v')
		replace `v' = "" if inlist(upper(`v'),"NULL",".","NA","N/A","NONE","MISSING")
	}

	* treat "0" as missing for id-like strings
	foreach v in jobcompanyid empcityid empcountryid {
		replace `v' = "" if `v'=="0"
	}

*--- Numeric copies ------------------------------------------

	destring jobcompanyid     , gen(jobcompanyid_num)
	destring empcityid		  , gen(empcityid_num)
	destring empcountryid	  , gen(empcountryid_num)

*--- Labels for original variables ---------------------------

	label var expid         "Experience ID (original)"
	label var user_id       "User ID (original)"
	label var jobtitle      "Job title (original)"
	label var jobstart      "Job start date (original)"
	label var jobend        "Job end date (original)"
	label var jobcompanyid  "Employer/company ID (original)"
	label var jobcompany    "Employer/company name (original)"
	label var empcityid     "Employment city ID (original)"
	label var empcountryid  "Employment country ID (original)"
	label var createdon     "Datetime created (original)"
	label var manage_team   "Manages team? (original)"

*--- Compress and save ---------------------------------------

	compress
	save "$proc/users_experience_proc.dta", replace
	
	
************************************************
************************************************
**# USERS LANGUAGES
************************************************
************************************************

*--- Load ----------------------------------------------------

	use "$merged/users_languages.dta", clear

	duplicates report 	
	duplicates drop // 27 duplicates dropped
	
	
*--- Labels for original variables ---------------------------

	label var user_id       "User ID (original)"
	label var lang_id       "Language ID (original)"
	label var lang_level    "Language level (original)"
	label var added_on      "Language added date (original)"
	
*--- Compress and save ---------------------------------------

	compress
	save "$proc/users_languages_proc.dta", replace
	
	
************************************************
************************************************
**# USERS SKILLS
************************************************
************************************************

*--- Load ----------------------------------------------------

	use "$merged/users_skills.dta", clear

	duplicates report

*--- Clean strings -------------------------------------------

	foreach v in user_id level added_on {
		replace `v' = trim(`v')
		replace `v' = "" if inlist(upper(`v'),"NULL",".","NA","N/A","NONE","MISSING")
	}

*--- Numeric copy of level -----------------------------------

	destring level, gen(skill_level_num)

*--- Labels for original variables ---------------------------

	label var user_id          "User ID (original)"
	label var skill_id         "Skill ID (original)"
	label var level            "Skill level (original)"
	label var added_on         "Skill added date (original)"

*--- Compress and save ---------------------------------------

	compress
	save "$proc/users_skills_proc.dta", replace

	
************************************************
************************************************
**# COMPANIES
************************************************
************************************************
*-----------------------------------------

*--- Load ----------------------------------------------------

	use "$merged/companies.dta", clear
	
	/*
	
	tab company_id if company_name == "ROZEE.PK" | company_name == "rozee.pk" | company_name == "Rozee.pk"

	 company_id |      Freq.     Percent        Cum.
	------------+-----------------------------------
		   5289 |          1       11.11       11.11
		 449420 |          1       11.11       22.22
		 463770 |          1       11.11       33.33
		 467124 |          1       11.11       44.44
		 478172 |          1       11.11       55.56
		 573066 |          1       11.11       66.67
		 580410 |          1       11.11       77.78
		 597290 |          1       11.11       88.89
		 603286 |          1       11.11      100.00
	------------+-----------------------------------
		  Total |          9      100.00

	*/
	
	isid company_id
	duplicates report
	
*--- Clean key string fields (IDs, counts, statuses, dates, text) -------------

	foreach v in company_name company_detail city_id country_id no_of_employee ///
				operating_since created industry_id ppsp companyowntype ///
				contact_name contact_designation nooffices origincompany ///
				company_status company_address {
		replace `v' = trim(`v')
		replace `v' = "" if inlist(upper(`v'),"NULL",".","NA","N/A","NONE","MISSING")
	}

	tab nooffices if regexm(nooffices, "[^0-9]") 
	
	* Number of offices 
	replace nooffices = "1" 	if nooffices == "1\'"
	replace nooffices = "20" 	if nooffices == "20+"
	replace nooffices = "35"	if nooffices == "35+"
	
	* Number of employees
	replace no_of_employee = "More than " + ustrregexs(1) if ///
		ustrregexm(no_of_employee, "^\s*([0-9]+)\s*\+\s*$")

	replace no_of_employee = ustrregexra(no_of_employee, "[^0-9\-]", "") ///
		if !ustrregexm(no_of_employee, "^(?i)\s*more\s+than\s+[0-9]+\s*$")
		
	* Company type
	gen str40 company_type_str = ustrtrim(companyowntype)

	replace company_type_str = subinstr(company_type_str, "Public\'", "Public", .)
	replace company_type_str = "Public" if inlist(company_type_str, "Public", "Government", "government")
	replace company_type_str = "" if ustrregexm(company_type_str, "[0-9]")
	replace company_type_str = "" if ustrregexm(company_type_str, "[^\x20-\x7E]")

	replace company_type_str = "" if company_type_str != "" & ///
		!inlist(company_type_str, "Public", "Private", "NGO", "Sole Proprietorship")

		
*--- Numeric copies (IDs, counts) ---------------------------------------------

	destring city_id     , gen(city_id_num)     
	destring country_id  , gen(country_id_num)  
	destring industry_id , gen(industry_id_num) 
	destring nooffices   , gen(nooffices_num)   
	
*--- Labels for original company variables -----------------------------

	label var company_id           "Company ID (original)"
	label var company_name         "Company name (original)"
	label var company_detail       "Company description/details (original)"
	label var city_id              "City ID (original)"
	label var country_id           "Country ID (original)"
	label var no_of_employee       "Number of employees (original)"
	label var operating_since      "Operating since / founding year (original)"
	label var created              "Datetime created (original)"
	label var industry_id          "Industry ID (original)"
	label var ppsp                 "Business type (original)"
	label var companyowntype       "Ownership type (original)"
	label var contact_name         "Primary contact name (original)"
	label var contact_designation  "Primary contact designation/title (original)"
	label var nooffices            "Number of offices (original)"
	label var origincompany        "Company origin country (original)"
	label var company_status       "Company verified status (original)"
	label var company_address      "Company address (original)"

*--- Compress and save ----------------------------------------------------

	compress
	save "$proc/companies_proc.dta", replace

************************************************
************************************************
**# JOBS
************************************************
************************************************

*--- Load ----------------------------------------------------

	use "$merged/jobs.dta", clear
	
	isid jid
	duplicates report

	
*--- Clean strings ----------------------------------------------------

	foreach v in title job_type_id job_shift_id genderid city_id area_id country_id ///
				req_experience max_experience salary_range_from salary_range_to ///
				salary_range_from_hide salary_range_to_hide currency_unit ///
				created displaydate applyby deactivateafterapplyby min_age max_age ///
				industry_id department_id min_education max_education_id ///
				careerlevelid jobpackage isfeatured istopjob ispremiumjob ///
				applyjobquestion tb_id tb_require description totalpositions ///
				filter_gender filter_experience filter_degree filter_age filter_city {
		replace `v' = trim(`v')
		replace `v' = "" if inlist(upper(`v'),"NULL",".","NA","N/A","NONE","MISSING")
	}

	tab city_id 		if regexm(city_id, "[^0-9, ]") 			// 2,573 cities without numeric ID -- 2,222 "All Cities"
	tab area_id			if regexm(area_id, "[^0-9,]") 			// 10,380 areas without numeric ID -- 10,367 "All Areas"
	tab totalpositions	if regexm(totalpositions, "[^0-9,]")
	
	* Total positions
	local bad  `" "1'" "1+" "15+" "300+" "35+" "Multiple" "No of" "'
	local good `" "1"  "1"  "15"  "300"  "35"  ""         ""      "'
	local n : word count `bad'

	forvalues i = 1/`n' {
		local b : word `i' of `bad'
		local g : word `i' of `good'
		replace totalpositions = "`g'" if totalpositions == "`b'"
	}
	
	* Currency unit
	replace    currency_unit = "PKR" if inlist(currency_unit, "Pakistani Rupee", "2855")
	replace    currency_unit = "USD" if inlist(currency_unit, "447")
	
	* Required experience
	replace req_experience = "Less than 1 Year" if ///
		ustrregexm(req_experience,"(?i)\bfresh\b")                          | ///
		ustrregexm(req_experience,"(?i)\bmonth\b")                          | ///
		ustrregexm(req_experience,"(?i)^\s*\d+\s*-\s*\d+\s*months?\s*$")    | ///
		ustrregexm(req_experience,"(?i)^\s*6\s*month\s*-\s*1\s*year\s*$")   | ///
		ustrregexm(req_experience,"(?i)^\s*less\s+than\s+1\s*year\s*$")

	replace req_experience = "More than 10 Years" if ///
		req_experience == "10+ Years"

	replace req_experience = cond(ustrregexs(1)=="1","1 Year",ustrregexs(1)+" Years") if ///
		ustrregexm(req_experience,"^(?i)\s*([0-9]+)\s*years?\s*$") ///
		& req_experience!="Not Required"
		
	* Flags
	local flags deactivateafterapplyby isfeatured istopjob ispremiumjob applyjobquestion ///
	filter_gender filter_experience filter_degree filter_age filter_city tb_require
		
	foreach f in `flags'{
		replace `f' = "1" if `f' == "Y"
		replace `f' = "0" if `f' == "N"
	}
	
*--- Numeric copies ----------------------------------------------------

	destring job_type_id,       	 gen(job_type_id_num)       
	destring job_shift_id,      	 gen(job_shift_id_num)      
	destring genderid,          	 gen(genderid_num)          
	//destring city_id,          	 	 gen(city_id_num)           
	//destring area_id,          	 	 gen(area_id_num)           
	destring country_id,        	 gen(country_id_num)
	destring industry_id,       	 gen(industry_id_num)       
	destring department_id,     	 gen(department_id_num)     
	destring min_education,      	 gen(min_education_num)     
	destring max_education_id,   	 gen(max_education_num)  
	destring careerlevelid,      	 gen(careerlevelid_num)     
	destring tb_id,             	 gen(tb_id_num)             
	destring totalpositions,    	 gen(totalpositions_num)                    
	destring salary_range_from,      gen(sal_from_num)          
	destring salary_range_to,        gen(sal_to_num)            
	destring salary_range_from_hide, gen(sal_from_hide_num)     
	destring salary_range_to_hide,   gen(sal_to_hide_num)       
	destring min_age,           	 gen(min_age_num)           
	destring max_age,           	 gen(max_age_num)
	destring deactivateafterapplyby, gen(deactivateafterapplyby_num)
	destring isfeatured,			 gen(isfeatured_num)
	destring istopjob,				 gen(istopjob_num)
	destring ispremiumjob,			 gen(ispremiumjob_num)
	destring applyjobquestion,		 gen(applyjobquestion_num)
	destring filter_gender,			 gen(filter_gender_num)
	destring filter_experience,		 gen(filter_experience_num)
	destring filter_degree,			 gen(filter_degree_num)
	destring filter_age,			 gen(filter_age_num)
	destring filter_city,			 gen(filter_city_num)
	destring tb_require,			 gen(tb_require_num)
	
	
*--- Labels for original job variables -------------------------

	label var jid              		   "Job ID (original; numeric)"
	label var title            		   "Job title (original)"
	label var job_type_id              "Job type ID (original)"
	label var job_shift_id             "Job shift ID (original)"
	label var genderid                 "Gender requirement ID (original)"
	label var city_id                  "City ID (original)"
	label var area_id                  "Area/zone ID (original)"
	label var country_id               "Country ID (original)"
	label var req_experience           "Minimum required experience (original)"
	label var max_experience           "Maximum required experience (original)"
	label var salary_range_from        "Salary range: from (original)"
	label var salary_range_to          "Salary range: to (original)"
	label var salary_range_from_hide   "Hide salary 'from' bound (original)"
	label var salary_range_to_hide     "Hide salary 'to' bound (original)"
	label var currency_unit            "Currency unit (original)"
	label var created                  "Datetime created (original)"
	label var displaydate              "Display date (original)"
	label var applyby                  "Apply-by date (original)"
	label var deactivateafterapplyby   "Deactivate after apply-by (original)"
	label var company_id               "Company ID (original; numeric)"
	label var industry_id              "Industry ID (original)"
	label var department_id            "Department ID (original)"
	label var min_education            "Minimum education required (original)"
	label var max_education_id         "Maximum education level ID (original)"
	label var totalpositions           "Total positions (original)"
	label var careerlevelid            "Career level ID (original)"
	label var careerlevel              "Career level (original)"
	label var min_age                  "Minimum age (original)"
	label var max_age                  "Maximum age (original)"
	label var jobpackage               "Job package rating (original)"
	label var isfeatured               "Featured job flag (original)"
	label var istopjob                 "Top job flag (original)"
	label var ispremiumjob             "Premium job flag (original)"
	label var applyjobquestion         "Has application questions (original)"
	label var tb_id                    "TB ID (original)"
	label var tb_require               "TB required (original)"
	label var description              "Job description (original)"
	label var filter_gender            "Filter: gender (original)"
	label var filter_experience        "Filter: experience (original)"
	label var filter_degree            "Filter: degree (original)"
	label var filter_age               "Filter: age (original)"
	label var filter_city              "Filter: city (original)"

	
*--- Compress and save ----------------------------------------------------

	compress
	save "$proc/jobs_proc.dta", replace
	
	
************************************************
************************************************
**# APPLICATIONS -- RANDOM SUBSAMPLE
************************************************
************************************************

*--- Load ----------------------------------------------------

	use "$merged/applications_sample.dta", clear
	
	isid app_id
	duplicates report

*--- Clean key string fields (IDs, statuses, salaries, dates) ------------------

	foreach v in emp_status test_code test_status currentsalary expectedsalary {
		replace `v' = trim(`v')
		replace `v' = "" if inlist(upper(`v'),"NULL",".","NA","N/A","NONE","MISSING")
	}
	
	* Application status
	replace emp_status = "shortlisted" if emp_status == "Shortlisted By PBL"
	replace emp_status = proper(emp_status)

*--- Numeric copies ----------------------------------------------------

	destring currentsalary   , gen(cursal_app)  
	destring expectedsalary  , gen(expsal_app)  
	
*--- Labels for original job variables -------------------------

	label var app_id				   	"Application ID (original; numeric)"
	label var user_id				   	"User ID (original; numeric)"
	label var jid              		   	"Job ID (original; numeric)"
	label var company_id               	"Company ID (original; numeric)"
	label var apply_date			   	"Application datetime (original)"
	label var emp_status			   	"Employer application status (original)"
	label var test_code				   	"Test ID (original)"
	label var test_status			   	"Test status (original)"
	label var currentsalary				"Current salary (original)"
	label var expectedsalary			"Expected salary (original)"
	
*--- Compress and save ----------------------------------------------------
	
	compress
	save "$proc/applications_sample_proc.dta", replace	

*/
	
********************************************
********************************************
**# End of do file
********************************************
********************************************	
	
	
	
	
	
