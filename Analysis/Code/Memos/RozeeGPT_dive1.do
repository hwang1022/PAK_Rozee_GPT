
/*======================================================================*
 |  Project:    Rozee 
 |  Author:     AB
 *======================================================================*/
 
version 18
clear all

if "`c(username)'" == "lalfonsi" {
	global dir "/Users/lalfonsi/Harvard University Dropbox/Livia Alfonsi/Research/PAK_Rozee_GPT/Data/"
	}
	
if "`c(username)'" == "abrockell" {
	global dir "/Users/abrockell/Library/CloudStorage/Dropbox-HarvardUniversity/Alec Brockell/PAK_Rozee_GPT/Data/"
	}

global data "$dir/Processed/RozeeGPT/250918_Input_RozeeGPT/"

********************
**# CV chats dataset
********************

    use "$data/CV_Chat_Cleaned.dta", clear

    tab user_id, m // 4,999 obs total; 247 missing
     
    gen     _RAW_____________=.
    order   _RAW_____________, first
    
    gen     _CREATED_________=.
    order   _CREATED_________, after(answer)
    
**## user_id

    * Flag rows where user_id is numeric
    destring user_id, gen(user_id_num) force
    order user_id_num, after(_CREATED_________)
    
    tab user_id_num, m // 985 user_id observations not IDs
    
    * Replies per user
    preserve 
        drop if missing(user_id_num)
        bysort user_id_num: gen replies_per_user = _N
        bysort user_id_num: gen byte tag = _n==1
        tab replies_per_user if tag
    restore
    
    /*
    
    replies_per |
          _user |      Freq.     Percent        Cum.
    ------------+-----------------------------------
              1 |        544       56.43       56.43
              2 |        151       15.66       72.10
              3 |         68        7.05       79.15
              4 |         39        4.05       83.20
              5 |         17        1.76       84.96
              6 |         17        1.76       86.72
              7 |         11        1.14       87.86
              8 |          9        0.93       88.80
              9 |          7        0.73       89.52
             10 |          7        0.73       90.25
             11 |          3        0.31       90.56
             12 |          7        0.73       91.29
             13 |          2        0.21       91.49
             14 |          6        0.62       92.12
             15 |          4        0.41       92.53
             16 |          5        0.52       93.05
             17 |          5        0.52       93.57
             18 |          4        0.41       93.98
             19 |          3        0.31       94.29
             20 |          3        0.31       94.61
             21 |          4        0.41       95.02
             22 |          5        0.52       95.54
             23 |          3        0.31       95.85
             24 |          2        0.21       96.06
             25 |          3        0.31       96.37
             26 |          1        0.10       96.47
             27 |          3        0.31       96.78
             28 |          2        0.21       96.99
             29 |          3        0.31       97.30
             30 |          1        0.10       97.41
             31 |          3        0.31       97.72
             32 |          2        0.21       97.93
             33 |          2        0.21       98.13
             34 |          3        0.31       98.44
             37 |          4        0.41       98.86
             38 |          1        0.10       98.96
             39 |          1        0.10       99.07
             40 |          1        0.10       99.17
             41 |          1        0.10       99.27
             42 |          1        0.10       99.38
             45 |          1        0.10       99.48
             54 |          1        0.10       99.59
             55 |          2        0.21       99.79
             58 |          1        0.10       99.90
             92 |          1        0.10      100.00
    ------------+-----------------------------------
              Total |        964      100.00
    
    */
    
**## chat_session_id

    * Rows per session
    preserve
        contract chat_session_id, freq(rows_in_session)
        tab rows_in_session
    restore

    * Session start flag
    gsort chat_session_id created_at
    by chat_session_id: gen byte is_session_start = (_n==1)
    tab is_session_start

**## created_at

    * Parse "15/05/2025 18:30"
    gen double created_dt = clock(created_at, "DMY hm")
    format %tc created_dt
    gen created_date = dofc(created_dt)
    format %td created_date
    gen created_hour = hh(created_dt)

    tab created_hour, m
    tab created_date in 1/10, m

**## original_response

    gen byte has_origresp = !missing(original_response)
    tab has_origresp is_session_start, row

**## answer

    gen byte has_answer = !missing(answer) & ustrlen(strtrim(answer))>0
    gen long answer_len = ustrlen(answer)
    tab has_answer
    tabstat answer_len, stats(mean p50 p90 n)
	
	/*
	

	 has_answer |      Freq.     Percent        Cum.
	------------+-----------------------------------
			  0 |      1,823       36.47       36.47
			  1 |      3,176       63.53      100.00
	------------+-----------------------------------
		  Total |      4,999      100.00



		Variable |      Mean       p50       p90         N
	-------------+----------------------------------------
	  answer_len |  129.8312         6       109      4999
	------------------------------------------------------

	
	*/

**## data_quality

    * Likely bleedover (simple)
    gen byte likely_bleed = missing(user_id_num) | missing(created_dt)
    tab likely_bleed

**## Rozee observations

    gen byte q_has_rozee = strpos(strlower(question), "rozee")>0
    gen byte a_has_rozee = strpos(strlower(answer),   "rozee")>0

    count if q_has_rozee
    local q = r(N)
    count if a_has_rozee
    local a = r(N)
    count
    local N = r(N)

    di as txt "Share 'rozee' (question): " %6.3f (`q'/`N')
    di as txt "Share 'rozee' (answer):   " %6.3f (`a'/`N')

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

