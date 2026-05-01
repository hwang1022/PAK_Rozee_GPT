
/*======================================================================*
 |  Project:    Rozee 
 |  Author:     AB
 |  File:       Creating RozeeGPT DTA files
 |  Required:   Run 0.master_gpt.do before this file
 *======================================================================*/

********************************************
********************************************
**# Converting datasets
********************************************
********************************************

	* Convert main inputs
	convert_csv_folder, inpath("$in")  outpath("$created")
	convert_csv_folder, inpath("$in2") outpath("$created2")

	di as result "All done. DTA files saved to:"
	di as result "$created"
	di as result "$created2"

********************************************
********************************************
**# End of do file
********************************************
********************************************
