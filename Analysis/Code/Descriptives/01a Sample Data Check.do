*************************
*** SAMPLE DATA CHECK ***
*************************

	*** Load data 
		import excel "$input/Rozee_sample/sample Rozee.xlsx", firstrow clear 
	

/// OLD SAMPLE

	*** Load data 
		import delimited "$input/Rozee_sample/data/applications.csv", clear
		
		
		import delimited "$input/Rozee_sample/data/apply_job_qucik_questions.csv", clear
		tempfile q 
		save `q'
		
		import delimited "$input/Rozee_sample/data/apply_job_qucik_answers.csv", clear
		rename jobquestionid questionid
		merge m:1 jid questionid using `q'
		
		import delimited "$input/Rozee_sample/data/companies.csv", clear
		keep company_id nooffices 
		tempfile offices 
		save `offices'
		
		import delimited "$input/Rozee_sample/data/jobs.csv", clear
		merge m:1 company_id using `offices'		
		
		import delimited "$input/Rozee_sample/data-dictionary/cities.csv", clear

		import delimited "$input/Rozee_sample/data/user_experiences.csv", clear
		
		import delimited "$input/Rozee_sample/data/user_educations.csv", clear
		import delimited "$input/Rozee_sample/data/users.csv", clear	
		
		import delimited "$input/Rozee_sample/data/users_skills.csv", clear		
		
		import delimited "$input/Rozee_sample/data/users.csv", clear			