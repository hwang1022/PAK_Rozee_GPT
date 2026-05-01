
/*======================================================================*
 |  Project:    Rozee 
 |  Author:     LA
 *======================================================================*/
 
version 18
clear all

global dir "/Users/abrockell/Library/CloudStorage/Dropbox-HarvardUniversity/Alec Brockell/PAK_Rozee_GPT/Data/"
global dir  "/Users/lalfonsi/Harvard University Dropbox/Livia Alfonsi/Research/PAK_Rozee_GPT/Data/"

**# Convert all datasets in DTA (will have to be moved)
	local in  "$dir/Raw/RozeeGPT/250918_Input_RozeeGPT"
	local out "$dir/Processed/RozeeGPT/250918_Input_RozeeGPT/"
	capture mkdir "`out'"

	local datasets applicant_personal_info_ha application_education_ha application_experience_ha application_skills_ha applications_ha cities_ha companies_ha countries_ha CV_Chat_Cleaned data_dictionary_ha jobs_ha jobs_skills_ha skills_ha user_skills_ha users_ha

	* LOOP: import -> compress -> save
	foreach ds of local datasets {
		local csv = "`in'/`ds'.csv"
		capture confirm file "`csv'"
		if _rc {
			di as error "Skipping (not found): `csv'"
			continue
		}
		di as txt "-> Importing `csv'"
		import delimited using "`csv'", varnames(1) encoding("UTF-8") clear
		compress
		save "`out'/`ds'.dta", replace
	}
	di as result "All done. DTA files saved to: `out'"

********************
**# Users dataset
********************
	use "$dir/Processed/RozeeGPT/250918_Input_RozeeGPT/users_ha.dta", clear
	count //76,191
	
	gen 	_RAW_____________=.
	order 	_RAW_____________, first
	
	gen 	_CREATED_________=.
	order 	_CREATED_________, after(last_login)

	
**## user_id
	isid user_id
	
**## user_type
	tab user_type, m //96% seeker
	
**## full_name
	count if full_name=="" //1
	g 	missing_full_name=1 if full_name ==""
	
	
**## seeker_type
	tab seeker_type, m
	/*
	 seeker_type |      Freq.     Percent        Cum.
	-------------+-----------------------------------
			   1 |          1        0.00        0.00
			NULL |     46,262       60.72       60.72
		employed |     24,051       31.57       92.29
	not-employed |          7        0.01       92.30
	professional |        153        0.20       92.50
		  select |          3        0.00       92.50
		 student |      5,714        7.50      100.00
	-------------+-----------------------------------
		   Total |     76,191      100.00
	*/
	g 		missing_seeker_type=1 if seeker_type =="NULL" | seeker_type=="1"| seeker_type=="select"

	
**## gender
	replace gender = lower(gender)
	replace gender = "male"   if gender == "Male"
	replace gender = "female" if gender == "Female"
	tab 	gender
	g 		missing_gender=1 if gender =="null"

	
**## city_name
	g 		missing_city_name=1 if city_name=="NULL"

	clonevar city_raw = city_name
	replace city_name = ustrnormalize(city_name, "nfc")   // keep if you have Unicode; else drop this line
	replace city_name = lower(city_name)
	replace city_name = strtrim(itrim(subinstr(city_name, char(160), " ", .)))  // trim & collapse spaces

	* NULL / not provided -> missing
	replace city_name = "" if regexm(city_name, "^(null|n/?a|unknown|not.*provided.*|only city.*|city from address|any city)$")

	* If there's a comma, keep the part before the first comma (e.g., "Lahore, Punjab")
	replace city_name = regexs(1) if regexm(city_name, "^([^,]+),.*")
	replace city_name = strtrim(itrim(city_name))

	* Remove generic suffixes/noise words
	replace city_name = regexr(city_name, "\b(cantt\.?|cant|cantonment|city|district|tehsil|province)\b", "")
	replace city_name = strtrim(itrim(city_name))

	* Big 5 + common abbrevs/variants
	replace city_name = "lahore"      if inlist(city_name,"lhr","lhr cantt","lahore cantt","lahore city") | regexm(city_name,"^lahore")
	replace city_name = "karachi"     if inlist(city_name,"khi","north karachi","new karachi","karachi-75100") | regexm(city_name,"karach|karahi")
	replace city_name = "islamabad"   if inlist(city_name,"isb") | regexm(city_name,"islamab|islambad|islmabad")
	replace city_name = "rawalpindi"  if inlist(city_name,"rwp") | regexm(city_name,"rawal.*pind|rawalpnd|rawalpndi")
	replace city_name = "faisalabad"  if inlist(city_name,"fsd") | regexm(city_name,"fais(a|l)|fasial|faisla|faisalbad|faislabad")

	* Frequent large cities
	replace city_name = "multan"           if regexm(city_name,"^multan")
	replace city_name = "peshawar"         if regexm(city_name,"^peshaw|pesahwar|peshawer")
	replace city_name = "quetta"           if regexm(city_name,"^quetta|quett")
	replace city_name = "hyderabad"        if regexm(city_name,"^hyd(er|)|hyderbad|hyderb(ad|ab)")

	replace city_name = "gujranwala"       if regexm(city_name,"gujra(nwala|nwla|n wala)|\bgrw\b|gujrawala|gujr(a|)khan\b==0")
	replace city_name = "sialkot"          if regexm(city_name,"^sialkot|sial k|sialkot\b")
	replace city_name = "rawalpindi"       if regexm(city_name,"rawal.*pind")
	replace city_name = "rahim yar khan"   if regexm(city_name,"rahim[ -]?yar[ -]?khan|rahimy?ar[ -]?khan|rahim[- ]yar[- ]khan")
	replace city_name = "dera ghazi khan"  if regexm(city_name,"(d[ .-]?g[ .-]?khan|dera ghazi)")
	replace city_name = "dera ismail khan" if regexm(city_name,"(d[ .-]?i[ .-]?khan|dera ismail)")
	replace city_name = "muzaffargarh"     if regexm(city_name,"muzaff|muzaf+ar|muzzaf|muzaf+argarh|muzaffr?agarh")
	replace city_name = "mirpur khas"      if regexm(city_name,"mirpur ?khas")
	replace city_name = "wah cantt"        if regexm(city_name,"^wah( |$)")
	replace city_name = "bahawalpur"       if regexm(city_name,"bah(a|)wal ?pur|bahawal ?nagar==0")
	replace city_name = "nawabshah"        if regexm(city_name,"nawab ?shah|shaheed benazir(abad)?")

	* Encoding/mojibake fixes seen in your list
	replace city_name = "karachi"          if inlist(city_name,"karÃ„Âchi","karÃÂchi","karÃ¢â¬â¢chi","karaach","karach","karahi")
	replace city_name = "khairpur mirs"    if regexm(city_name,"khairpur.*mir") | inlist(city_name,"khair pur mir","khairpur mir\'s","khairpur mirs")
	replace city_name = "islamabad"        if inlist(city_name,"islÃ„ÂmÃ„ÂbÃ„Âd")
	replace city_name = "faisalabad"       if inlist(city_name,"faisalÃ„ÂbÃ„Âd")

	* Common typos → canonical
	replace city_name = "gujrat"           if inlist(city_name,"gujrat","gujrat ")
	replace city_name = "sargodha"         if regexm(city_name,"sargodh")
	replace city_name = "sahiwal"          if regexm(city_name,"sahiwal|sahi wal")
	replace city_name = "mardan"           if regexm(city_name,"^mardan")
	replace city_name = "lodhran"          if regexm(city_name,"lodhr(am|an)|lodhran")
	replace city_name = "layyah"           if regexm(city_name,"layyah|laihya|layya")
	replace city_name = "sheikhupura"      if regexm(city_name,"she(ik|ikh)h?upur(a|a)?|sheikhpura|shekhupura|sheikhupora")
	replace city_name = "jhang"            if regexm(city_name,"^jhang")
	replace city_name = "jhelum"           if regexm(city_name,"jeh?lum|jelum")
	replace city_name = "attock"           if regexm(city_name,"^attock|atock")
	replace city_name = "wah cantt"        if regexm(city_name,"wah ?cantt?\.?")
	replace city_name = "mirpur"           if regexm(city_name,"^mirpur( ?\(ajk\)|  \(ajk\)|  \(.*\))?$")

	* Province-only entries -> missing (Punjab, Sindh, etc.)
	replace city_name = "" if regexm(city_name, "^(punjab|sindh|kpk|kp|ministry|gilgit(-| )?baltistan)$")

	* Final tidy + nice casing

	replace city_name = strtrim(itrim(city_name))
	gen str40 city_clean = proper(city_name)

	* Optional: check results
	tab city_clean if !missing(city_clean), sort
	
**## country_id
	tab country_id
	g 	missing_country_id=1 if country_id=="NULL"

**## dob
	tab dob
	gen dob_date = date(dob, "YMD")
	format dob_date %td   // display as date
	gen missing_dob   = 1 if dob=="NULL"

	* Extract year, month, and day
	gen dob_year  = year(dob_date)
	gen dob_month = month(dob_date)
	gen dob_day   = day(dob_date)
	
	* Age in years (integer, based on birthday)
	local today = daily("`c(current_date)'", "DMY")
	gen age = floor((`today' - dob_date) / 365.25)
	hist age if age > 0 & age <100	
	sum  age if age > 0 & age <100	//27
	gen missing_age   = 1 if dob=="NULL"

	
**## experience
	tab experience	
	* Step 1: Clean and normalize the string
	gen strL exp_str = lower(strtrim(experience))

	* Step 2: Remove the words "year" or "years"
	replace exp_str = subinstr(exp_str, "years", "", .)
	replace exp_str = subinstr(exp_str, "year", "", .)

	* Step 3: Handle special cases
	replace exp_str = ""   if exp_str=="null"
	replace exp_str = "25" if exp_str=="25+ "   // cap 25+ at 25
	replace exp_str = ""   if exp_str=="total numb"   

	* Step 4: Convert to numeric
	destring exp_str, gen(exp_years) ignore("+")

	* Step 5: Inspect
	tab exp_years, m
	sum exp_years
	gen missing_exp_years   = 1 if exp_years==.
	
	
**## current_salary	
	gen missing_current_salary   = 1 if current_salary=="NULL"
	gen strL sal_s = lower(strtrim(current_salary))

	* treat obvious nulls as missing
	replace sal_s = "" if inlist(sal_s,"null","")

	* remove currency words/symbols that can appear before/after
	replace sal_s = subinstr(sal_s, "pkr", "", .)
	replace sal_s = subinstr(sal_s, "rs",  "", .)
	replace sal_s = subinstr(sal_s, "$",   "", .)
	replace sal_s = strtrim(itrim(sal_s))

	* Handle "k" shorthand (e.g. 30k, 30 k, 30.5k)
	gen double sal_num = .
	replace sal_num = real(regexs(1))*1000 if regexm(sal_s,"^([0-9]+(?:\.[0-9]+)?)\s*k$")
	replace sal_s    = ""                  if regexm(sal_s,"^([0-9]+(?:\.[0-9]+)?)\s*k$")

	* Handle values typed with a dot as thousands sep, e.g. 67.000 -> 67000
	replace sal_s = subinstr(sal_s,".","",.) if regexm(sal_s,"^[0-9]{1,3}\.[0-9]{3}$")

	* Remove commas/spaces/units anywhere else
	replace sal_s = subinstr(sal_s, ",", "", .)
	replace sal_s = regexr(sal_s, "[^0-9\.\-]", "")   // keep only digits, dot, minus
	replace sal_s = strtrim(sal_s)

	* Convert what remains to numeric and combine with the "k" cases
	destring sal_s, gen(sal_num2) force
	replace sal_num = sal_num2 if missing(sal_num)
	drop sal_s sal_num2

	label var sal_num "Current salary (numeric)"
	summ sal_num
	g missing_sal_num=1 if sal_num==.
	
	* Convert PKR -> USD
	local pkr_per_usd = 283
	gen double sal_num_usd = sal_num / `pkr_per_usd' if !missing(sal_num)
	format sal_num_usd %12.2fc
	label var sal_num_usd "Current salary (USD), using `pkr_per_usd' PKR/USD"
	sum sal_num_usd
	preserve
		replace sal_num_usd=. if sal_num_usd<0
		sum sal_num_usd
	restore
	

**## created_at	
	* Parse to a proper Stata datetime
	gen double created_dt = clock(created_at, "YMDhms")
	format created_dt %tc

	* Date only
	gen created_date = dofc(created_dt)
	format created_date %td

	* Components
	gen created_year  = year(created_date)
	gen created_month = month(created_date)        // month (in case you need it)
	gen created_day   = day(created_date)           // day of month

	gen created_hour = hh(created_dt)              // hour (0–23)
	gen created_min  = mm(created_dt)              // minutes
	gen created_sec  = ss(created_dt)              // seconds

	* Optional: day of week (0=Sun ... 6=Sat)
	gen created_dow = dow(created_date)
	label define dow 0 "Sun" 1 "Mon" 2 "Tue" 3 "Wed" 4 "Thu" 5 "Fri" 6 "Sat"
	label values created_dow dow
	
	tab created_month, m
	tab created_month if created_year==2024 
	gen missing_created_month=1 if created_month==.


**## last_login	
	* Convert the string into a Stata datetime variable
	gen double last_login_dt = clock(last_login, "YMDhms")
	format  last_login_dt %tc  // full datetime

	gen    last_login_date = dofc(last_login_dt)
	format last_login_date %td
	
	* Year, month, hour, minute, second
	gen 	last_login_year = year(last_login_date)
	gen 	last_login_month 	 = month(last_login_date)
	gen 	last_login_month_lbl = month(last_login_date)
	label define monthlbl 1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" ///
						  7 "Jul" 8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec"
	label values last_login_month_lbl monthlbl

	gen login_hour   = hh(last_login_dt)
	gen login_minute = mm(last_login_dt)
	gen login_second = ss(last_login_dt)
	
	gen missing_last_login_date=1 if last_login_date==.


	egen tot_missings=rowtotal(missing_full_name missing_seeker_type missing_gender missing_city_name missing_country_id missing_dob missing_age missing_exp_years missing_current_salary missing_sal_num missing_created_month missing_last_login_date)
	tab tot_missings
	
	**************************************************
	* 0) Parse dates (run once; skip if you already did)
	**************************************************
	* Cohorts
	gen created_yq = yq(year(created_date), quarter(created_date))
	format created_yq %tq
	gen created_ym = ym(year(created_date), month(created_date))
	format created_ym %tm

	* Days since last login & idle buckets
	local today = daily("`c(current_date)'","DMY")
	gen days_since_login = `today' - last_login_date

	gen byte idle_bucket = .
	replace idle_bucket = 0 if missing(last_login_date)                       // never logged in
	replace idle_bucket = 1 if days_since_login < 30 & !missing(days_since_login)
	replace idle_bucket = 2 if inrange(days_since_login, 30, 89)
	replace idle_bucket = 3 if inrange(days_since_login, 90, 179)
	replace idle_bucket = 4 if inrange(days_since_login, 180, 365)
	replace idle_bucket = 5 if days_since_login > 365
	label define idle 0 "Never" 1 "<30d" 2 "30–89d" 3 "90–179d" 4 "180–365d" 5 "1y+"
	label values idle_bucket idle
	
	**************************************************
	* 1) Build the list of missing flags & row-level share
	**************************************************
	ds missing_*, has(type numeric)
	local missvars `r(varlist)'
	local missvars : list missvars - tot_missings   // drop the total from the list

	* Share of fields missing per row (0–1)
	local K : word count `missvars'
	gen double miss_share = tot_missings/`K'
	label var miss_share "Share of fields missing"
	**************************************************
	* 2) Quick overall missingness patterns
	**************************************************
	* Which combos of missingness show up often?
	misstable patterns `missvars', freq

	* How correlated are missing flags with each other?
	pwcorr `missvars', sig
	**************************************************
	* 3) By creation cohort
	**************************************************
	* Average share missing by quarter the account was created
	tabstat miss_share, by(created_yq) stat(mean n) format(%5.3f)

	* Bar chart by quarter (comment out if too many quarters)
	graph bar (mean) miss_share, over(created_yq, sort(1) label(angle(45))) ///
		ytitle("Avg share missing") 
	**************************************************
	* 4) By recency of last login (idle)
	**************************************************
	* Average share missing by idle bucket
	tabstat miss_share, by(idle_bucket) stat(mean n) format(%5.3f)

	* Means of each individual flag by idle bucket (table)
	tabstat `missvars', by(idle_bucket) stat(mean) columns(statistics) format(%4.2f)

	* Bar chart
	graph bar (mean) miss_share, over(idle_bucket) ytitle("Avg share missing")
	**************************************************
	* 5) Optional: model probability of being incomplete
	**************************************************
	* Any missing at all?
	egen miss_any = rowmax(`missvars')
	logit miss_any i.created_yq c.days_since_login
	margins created_yq, at(days_since_login=(0 30 90 180 365)) post
	marginsplot		
	
	
	
**# Users skills dataset
	use "$dir/Processed/RozeeGPT/250918_Input_RozeeGPT/users_ha.dta", clear
	merge 1:m user_id using "$dir/Processed/RozeeGPT/250918_Input_RozeeGPT/user_skills_ha.dta"
	
	merge 1:m user_id using "$dir/Processed/RozeeGPT/250918_Input_RozeeGPT/CV_Chat_Cleaned.dta"
	
	use "$dir/Processed/RozeeGPT/250918_Input_RozeeGPT/CV_Chat_Cleaned.dta"
	
	
	
	
	
	
	
	
	
	
	

