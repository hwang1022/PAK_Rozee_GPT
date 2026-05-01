clear all
clear matrix 
clear mata 
set more off
set maxvar 20000

*******************************
*** SET WORKING DIRECTORIES ***
*******************************
	
	set seed 120993
	set sortseed 120993
	
	if "`c(username)'" == "LIVIA" {
		global root ""
		global folder "$root/PAK_Rozee"
	}
	
	if "`c(username)'" == "devap" {
		global root "C:/Users/`c(username)'/Dropbox"
		global folder "$root/Rozee_ADB"
	}
	
	if "`c(username)'" == "277282638" {
		global root "E:\科研\Livia"
		global folder "$root/PAK_Rozee"
	}
	
	global input "$folder/Input"
	global dofiles "$folder/Code"
	*global paper "$folder/PAPER"
	global output "$folder/Output"
		global description "$output/Rozee_description"
			global figdes "$description/Figures"
			global tabdes "$description/Tables"
		global descriptionv2 "$output/Rozee_description_v2"
			global figdesv2 "$descriptionv2/Figures"
			global tabdesv2 "$descriptionv2/Tables"
		global expsal "$output/Rozee_expsal"
			global figexp "$expsal/Figures"
			global tabexp "$expsal/Tables"
	
	capture program drop valuetex
	program valuetex
		args glname filename val
		tempname valuefile
		file open `valuefile' using "$`glname'/`filename'.tex", write replace
		file write `valuefile' "`val'"
		file close `valuefile'
	end
		
	exit 