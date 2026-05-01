
/*======================================================================*
 |  Project:    Rozee 
 |  Author:     AB
 |  File:       Cleaning RozeeGPT data
 |  Required:   Run 1.creation_gpt.do before this file
 *======================================================================*/

************************************************
************************************************
**# USERS
************************************************
************************************************

*--- Load ----------------------------------------------------

    use "$created/users_ha.dta", clear // 12 vars; 76,191 obs

    isid user_id
    duplicates report

*--- Clean strings -------------------------------------------

    foreach v in user_type full_name seeker_type gender city_name country_id ///
                 dob current_salary created_at last_login {
        replace `v' = trim(`v')
        replace `v' = "" if inlist(upper(`v'),"NULL",".","NA","N/A","NONE","MISSING")
    }

    * Seeker type (collapse noisy values)
    replace seeker_type = lower(seeker_type)
    replace seeker_type = ""              if inlist(seeker_type,"","select","1")
    replace seeker_type = "employed"      if seeker_type=="employed"
    replace seeker_type = "not-employed"  if seeker_type=="not-employed"
    replace seeker_type = "professional"  if seeker_type=="professional"
    replace seeker_type = "student"       if seeker_type=="student"

    * Gender (standardize case)
    replace gender = lower(gender)

    * Experience: normalize text to numbers/keywords
	replace experience = trim(experience)
	replace experience = "" if inlist(upper(experience),"NULL",".","NA","N/A","NONE","MISSING","TOTAL NUMB")

	replace experience = subinstr(experience,"Years","Year",.)
	replace experience = subinstr(experience,"years","Year",.)
	replace experience = subinstr(experience,"year","Year",.)
	replace experience = subinstr(experience,"Year","",.)

*--- Labels for original variables ---------------------------

    label var user_id        "User ID (original)"
    label var user_type      "User type (original)"
    label var full_name      "Full name (original)"
    label var seeker_type    "Seeker type (original)"
    label var gender         "Gender (original)"
    label var city_name      "City name (original)"
    label var country_id     "Country ID (original)"
    label var dob            "Date of birth (original)"
    label var experience     "Experience (original)"
    label var current_salary "Current salary (original)"
    label var created_at     "Datetime created (original)"
    label var last_login     "Datetime last login (original)"

*--- Compress and save ---------------------------------------

    compress
    save "$cleaned/users_gpt_cleaned.dta", replace

************************************************
************************************************
**# COMPANIES
************************************************
************************************************
*-----------------------------------------

*--- Load ----------------------------------------------------

	use "$created/companies_ha.dta", clear // 4 vars; 1,708 obs
	
	isid company_id
	
	/*
	
	tab company_id if company_name == "ROZEE.PK" | company_name == "rozee.pk" | company_name == "Rozee.pk"

	 company_id |      Freq.     Percent        Cum.
	------------+-----------------------------------
			121 |          1       10.00       10.00
		   2336 |          1       10.00       20.00
		   2618 |          1       10.00       30.00
		   2686 |          1       10.00       40.00
		   2810 |          1       10.00       50.00
		   2920 |          1       10.00       60.00
		   2938 |          1       10.00       70.00
		   2940 |          1       10.00       80.00
		   2944 |          1       10.00       90.00
		   3026 |          1       10.00      100.00
	------------+-----------------------------------
		  Total |         10      100.00

	*/
	
	duplicates report	
	
*--- Clean strings -------------------------------------------

    foreach v in company_name created_at {
        replace `v' = trim(`v')
        replace `v' = "" if inlist(upper(`v'),"NULL",".","NA","N/A","NONE","MISSING")
    }

*--- Labels for original variables ---------------------------

    label var company_id        "Company ID (original)"
    label var user_id      		"User ID (original)"
    label var company_name      "Company name (original)"
    label var created_at    	"Datetime created in system (original)"	
	
*--- Compress and save ---------------------------------------

    compress
    save "$cleaned/companies_gpt_cleaned.dta", replace
	
************************************************
************************************************
**# JOBS
************************************************
************************************************
*-----------------------------------------

*--- Load ----------------------------------------------------

	use "$created/jobs_ha.dta", clear // 19 vars; 3,249 obs
	
    isid jid
    duplicates report

*--- Clean strings -------------------------------------------

    foreach v in title description responsibilities required_experience ///
                other_requirements other_city workplace maximum_budget ///
                hide_salary manage_employees subordinates_count ///
                created_at updated_at published_at apply_by deleted_at {
        replace `v' = trim(`v')
        replace `v' = "" if inlist(upper(`v'),"NULL",".","NA","N/A","NONE","MISSING")
    }
	
	replace other_city = "" if other_city == "Array"

	* Required experience -- implausible numbers
    replace required_experience = "" if regexm(required_experience, "(-?[0-9]+(\.[0-9]+)?)") ///
    & (real(regexs(1)) < 0 | real(regexs(1)) > 60)
	
	* Subordinates -- implausible numbers/keywords
	replace subordinates_count = "" if regexm(subordinates_count, "(-?[0-9]+(\.[0-9]+)?)") ///
    & (real(regexs(1)) > 200000)
	

*--- Labels for original variables ---------------------------

    label var jid                  "Job ID (original)"
    label var user_id              "Poster user ID (original)"
    label var title                "Job title (original)"
    label var description          "Job description (original)"
    label var responsibilities     "Responsibilities (original)"
    label var hide_salary          "Hide salary (Y/N, original)"
    label var required_experience  "Required experience (original)"
    label var other_requirements   "Other requirements (original)"
    label var manage_employees     "Manages employees (Yes/No, original)"
    label var subordinates_count   "Subordinates count (original)"
    label var maximum_budget       "Maximum budget for position (original)"
    label var other_city           "Other city (original)"
    label var workplace            "Workplace (original)"
    label var company_id           "Company ID (original)"
    label var created_at           "Datetime created (original)"
    label var updated_at           "Datetime updated (original)"
    label var published_at         "Datetime published (original)"
    label var apply_by             "Apply-by datetime (original)"
    label var deleted_at           "Datetime deleted (original)"

*--- Compress and save ---------------------------------------

    compress
    save "$cleaned/jobs_gpt_cleaned.dta", replace

************************************************
************************************************
**# APPLICATIONS
************************************************
************************************************

*--- Load ----------------------------------------------------

	use "$created/applications_ha.dta", clear // 15 vars; 97,799 obs
	
	isid application_id
	duplicates report
	
*--- Clean strings -------------------------------------------

	ds, has(type string)
	local svars `r(varlist)'

	foreach v of local svars {
		replace `v' = ustrtrim(`v')
		replace `v' = "" if ustrregexm(`v', "(?i)^\s*(null|\.|na|n/?a|none|missing|unknown|not\s+(mentioned|specified|available|provided|specif|provid|availa|mentio))\s*$")
	}

*--- Labels for original variables ---------------------------

	label var application_id          "Application ID (original)"
	label var user_id                 "Applicant user ID (original)"
	label var jid                     "Job ID (original)"
	label var employer_status         "Employer decision status (original)"
	label var suggested               "Suggested flag (1/2, original)"
	label var match_score             "Match score (original)"
	label var matching_reason         "Matching explanation (original)"
	label var test_status             "Test status (original)"
	label var test_score              "Test score (original)"
	label var video_interview_score   "Video interview score (original)"
	label var coding_test_score       "Coding test score (original)"
	label var overall_score           "Overall score (original)"
	label var score_status            "Score calculation status (original)"
	label var created_at              "Datetime created (original)"
	label var source                  "Application source (original)"

*--- Compress and save ---------------------------------------

    compress
    save "$cleaned/applications_gpt_cleaned.dta", replace	

************************************************
************************************************
**# APPLICATIONS PERSONAL INFO
************************************************
************************************************

*--- Load ----------------------------------------------------

	use "$created/applicant_personal_info_ha.dta", clear // 15 vars; 100,681 obs	

	duplicates report 
	
	/*
	
	Duplicates in terms of all variables

	--------------------------------------
	   Copies | Observations       Surplus
	----------+---------------------------
			1 |       100674             0
			7 |            7             6
	--------------------------------------
	
	*/
	
*--- Clean strings -------------------------------------------

	ds, has(type string)
	local svars `r(varlist)'

	foreach v of local svars {
		replace `v' = ustrtrim(`v')
		replace `v' = "" if ustrregexm(`v', "(?i)^\s*(null|\.|na|n/?a|none|missing|unknown|not\s+(mentioned|specified|available|provided|specif|provid|availa|mentio))\s*$")
	}
		
	* ----------- Gender
	replace gender = proper(gender)
	replace gender = "Male" if gender == "Masculine"
	replace gender = "" if !inlist(gender, "Male", "Female", "Transgender")
	
	* ----------- Experience 
	replace experience = "" if regexm(ustrlower(experience), ///
		"^(not[ ]+(mentio(ned)?|provid(ed)?|specif(ied)?)|unknown|total[ ]+numb)") 

	* ----------- Job start
	replace job_start = "" if job_start == "0000-00-00"
	replace job_start = "" if job_start!="" & ustrregexm(trim(job_start), "^[^0-9]+$")
	
	* ----------- Job end 
	tab job_end if job_end!="" & ustrregexm(trim(job_end), "^[^0-9]+$")
	
	* normalize case/space and some punctuation
	replace job_end = ustrlower(ustrtrim(job_end))

	* strip trailing dots and collapse runs of dots
	replace job_end = ustrregexra(job_end, "\.+$", "")
	
	* collapse extra spaces
	replace job_end = ustrregexra(job_end, "\s+", " ")

	* normalize "ongoing/present"
	local present_re "(?:present|presently|current|currently|continue|continued|continues|continuing|continuous|cont|contd|on[- ]?going|ongoing|onward|onwards|till date|till now|till today|till to[- ]?date|till present|to[- ]?date|todate|up[- ]?to[- ]?date|uptodate|today|now|still (?:work|working|continue|continuing|on duty|now)|nowadays|tbd|xx/xxxx|actualidad)"
	replace job_end = "present" if job_end!="" ///
		& ustrregexm(job_end, "`present_re'") ///
		& ustrregexm(job_end, "^[^0-9]+$")

	* more single-token ongoing variants (no digits)
	replace job_end = "present" if job_end!="" & ustrregexm(job_end, ///
		"^(till|till[- ]?date|till the date|till to|till time|till working|to till|still|still here|still working|still continue|still continuing|onwrds|onward|onwards|on job|pres)$") ///
		& ustrregexm(job_end, "^[^0-9]+$")

	* Arabic mojibake "until now" seen in data → present
	replace job_end = "present" if inlist(job_end,"ø­øªù‰ ø§ù„ø¢ù†")

	* also catch "till … / still …" phrases (e.g., "till appear", "till workingâ€¦")
	replace job_end = "present" if job_end!="" ///
		& ustrregexm(job_end, "^(till\b.*|still\b.*)") ///
		& ustrregexm(job_end, "^[^0-9]+$")

	* broad "not … / unknown … / end date … / month-year unknown …" stems
	local miss_re "^(?:not (?:applicable|available|provided|specified|mentioned|found|present|stated)|unavailable|unknown|unspecified|undefined|nill|date not (?:provid|specif)|month/?year (?:not|unknown)|year not (?:provid|specif)|end date(?: unknown)?|na)$"
	replace job_end = "" if job_end!="" ///
		& ustrregexm(job_end, "`miss_re'") ///
		& ustrregexm(job_end, "^[^0-9]+$")

	* generic stems without a real date
	replace job_end = "" if job_end!="" & inlist(job_end, "date","end date","end_date","duration_to","ff")

	* more "end/date/duration …" stems (no digits)
	replace job_end = "" if job_end!="" ///
		& ustrregexm(job_end, "^(end date|ending date|date |date$|date of|date not|date period|duration|duration_to)") ///
		& ustrregexm(job_end, "^[^0-9]+$")

	* single months / month-year placeholders (no digits)
	replace job_end = "" if job_end!="" & ///
		( inlist(job_end,"august","december","sept","month","month year","month/year","month: not spec") ///
		  | ustrregexm(job_end,"^month/?year") ) ///
		& ustrregexm(job_end, "^[^0-9]+$")

	* "recent/expected/starting/progress/running/professional ex" etc. (no digits)
	replace job_end = "" if job_end!="" ///
		& ustrregexm(job_end, "^(recent|recently|most recent|expected|starting|in[- ]?progress|in process|running|professional ex)$") ///
		& ustrregexm(job_end, "^[^0-9]+$")

	* durations without concrete dates (no digits)
	replace job_end = "" if job_end!="" ///
		& inlist(job_end,"one month","eight months","one year","two years") ///
		& ustrregexm(job_end, "^[^0-9]+$")

	* bracketed / leftovers
	replace job_end = "" if job_end=="[end date]"
	replace job_end = "" if job_end=="unspecified end"

	* a few remaining literals from your tab
	replace job_end = "" if inlist(job_end,"completed","end duration of","final semester","recent duration","recent experien","recent job end","recent_job_end_","recently enroll","year of experie")

	* sanity check
	tab job_end if job_end!="" & ustrregexm(trim(job_end), "^[^0-9]+$")		

*--- Labels for original variables ---------------------------

	label var application_id       "Application ID (original)"
	label var user_id              "Applicant user ID (original)"
	label var gender               "Applicant gender (original)"
	label var summary              "Applicant summary/profile (original)"
	label var city                 "Applicant city (original)"
	label var experience           "Experience summary (original)"
	label var job_title            "Job title (original)"
	label var job_company          "Job company/employer (original)"
	label var job_start            "Job start (original)"
	label var job_end              "Job end (original)"
	label var degree_title         "Degree title (original)"
	label var degree_major         "Degree major/field (original)"
	label var degree_institute     "Degree institute/university (original)"
	label var degree_year          "Degree year (original)"
	label var qualification_data   "Qualification data (JSON, original)"

*--- Compress and save ---------------------------------------

    compress
    save "$cleaned/applications_personal_info_gpt_cleaned.dta", replace	

************************************************
************************************************
**# APPLICATIONS EDUCATION
************************************************
************************************************

*--- Load ----------------------------------------------------

	use "$created/application_education_ha.dta", clear // 7 vars; 140,496 obs	

	duplicates report 
	
	/*
	
	Duplicates in terms of all variables

	--------------------------------------
	   Copies | Observations       Surplus
	----------+---------------------------
			1 |       139711             0
			2 |          638           319
			3 |          117            78
			4 |           16            12
			6 |            6             5
			8 |            8             7
	--------------------------------------
	
	*/
	
*--- Clean strings -------------------------------------------

	ds, has(type string)
	local svars `r(varlist)'

	foreach v of local svars {
		replace `v' = ustrtrim(`v')
		replace `v' = "" if ustrregexm(`v', "(?i)^\s*(null|\.|na|n/?a|none|missing|unknown|not\s+(mentioned|specified|available|provided|specif|provid|availa|mentio))\s*$")
	}		
	
	destring application_id, replace

*--- Labels for original variables ---------------------------

	label var application_id       	"Application ID (original)"
	label var title            	   	"Education title (original)"
	label var institute          	"Institute/university (original)"
	label var location            	"Education city/country (original)"
	label var start_date            "Education start date (original)"
	label var end_date         		"Education end date (original)"
	label var created_at			"Datetime created in system (original)"

*--- Compress and save ---------------------------------------

    compress
    save "$cleaned/applications_education_gpt_cleaned.dta", replace	
	
	
************************************************
************************************************
**# APPLICATIONS EXPERIENCE
************************************************
************************************************

*--- Load ----------------------------------------------------

	use "$created/application_experience_ha.dta", clear // 7 vars; 197,022 obs	

	duplicates report 
	
	/*
	
	Duplicates in terms of all variables

	--------------------------------------
	   Copies | Observations       Surplus
	----------+---------------------------
			1 |       196968             0
			2 |           32            16
			3 |            9             6
			4 |            8             6
			5 |            5             4
	--------------------------------------
	
	*/
	
*--- Clean strings -------------------------------------------

	ds, has(type string)
	local svars `r(varlist)'

	foreach v of local svars {
		replace `v' = ustrtrim(`v')
		replace `v' = "" if ustrregexm(`v', "(?i)^\s*(null|\.|na|n/?a|none|missing|unknown|not\s+(mentioned|specified|available|provided|specif|provid|availa|mentio))\s*$")
	}
			
	destring application_id, replace
	
*--- Labels for original variables ---------------------------

	label var application_id       	"Application ID (original)"
	label var title            	   	"Job title (original)"
	label var company          		"Company/employer (original)"
	label var location            	"Job city/country (original)"
	label var job_start            	"Job start date (original)"
	label var job_end         		"Job end date (original)"
	label var created_at			"Datetime created in system (original)"

*--- Compress and save ---------------------------------------

    compress
    save "$cleaned/applications_experience_gpt_cleaned.dta", replace	
		
	


	
	
	
	
	
	
	
	
	