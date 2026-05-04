*************************************************
*************************************************
* 	PAK Rozee Projects -  MASTER DOFILE			*
* 	Created: Apr 30, 2026 by HW	                *
* 	Last edited: May 1, 2026 by HW             	*
*************************************************
*************************************************

	ieboilstart, version(18.0)
	`r(version)'

	grstyle init
	grstyle set plain, nogrid 
	graph set window fontface "Helvetica"


************************
**# 1. Set Directories
************************

****
**## 1.1 Set Main Directory
****

	global dir 	`"~/Dropbox/PAK_Rozee_GPT"'

	* If your PAK Rozee directory is not what's defined above, customize youe directory below
	if "`c(username)'" == "liviaterenzialfonsi" global dir 	`"...."'



****
**## 1.2 Set ADB Directory
****

	global adb_dir 			`"~/Dropbox/PAK_Rozee_GPT/Project_ADB"'
	global adb_data 		`"$adb_dir/Data"'
	global adb_raw 			`"$adb_data/Raw"'
	global adb_cleaned 		`"$adb_data/Cleaned"'
	global adb_temp 		`"$adb_data/Temp"'

	global adb_code 			`"$adb_dir/Code"'
	global adb_code_cleaning 	`"$adb_code/0_cleaning"'
	global adb_code_analysis 	`"$adb_code/1_analysis"'

	global adb_output 		`"$adb_dir/Output"'
	global adb_figures 		`"$adb_output/Figures"'
	global adb_tables 		`"$adb_output/Tables"'
	global adb_stats		`"$adb_output/Stats"'

	global adb_memo			`"$adb_dir/Memo"'


****
**## 1.3 Set Rozeena Directory
****

	global rozeena_dir 			`"~/Dropbox/PAK_Rozee_GPT/Project_Rozeena"'
	global rozeena_data 		`"$rozeena_dir/Data"'
	global rozeena_raw 			`"$rozeena_data/Raw"'
	global rozeena_cleaned 		`"$rozeena_data/Cleaned"'
	global rozeena_temp 		`"$rozeena_data/Temp"'

	global rozeena_code 			`"$rozeena_dir/Code"'
	global rozeena_code_cleaning 	`"$rozeena_code/0_cleaning"'
	global rozeena_code_analysis 	`"$rozeena_code/1_analysis"'

	global rozeena_output 		`"$rozeena_dir/Output"'
	global rozeena_figures 		`"$rozeena_output/Figures"'
	global rozeena_tables 		`"$rozeena_output/Tables"'
	global rozeena_stats		`"$rozeena_output/Stats"'

	global rozeena_memo			`"$rozeena_dir/Memo"'


****
**## 1.4 Set 20-Year Directory
****

	global score_dir 			`"~/Dropbox/PAK_Rozee_GPT/Project_Score"'
	global score_data 			`"$score_dir/Data"'
	global score_raw 			`"$score_data/Raw"'
	global score_cleaned 		`"$score_data/Cleaned"'
	global score_temp 			`"$score_data/Temp"'

	global score_code 			`"$score_dir/Code"'
	global score_code_cleaning 	`"$score_code/0_cleaning"'
	global score_code_analysis 	`"$score_code/1_analysis"'

	global score_output 		`"$score_dir/Output"'
	global score_figures 		`"$score_output/Figures"'
	global score_tables 		`"$score_output/Tables"'
	global score_stats			`"$score_output/Stats"'

	global score_memo			`"$score_dir/Memo"'