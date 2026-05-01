
/*======================================================================*
 |  Project:    Rozee 
 |  Author:     AB
 *======================================================================*/
 
version 18
clear all

global dir "/Users/abrockell/Library/CloudStorage/Dropbox-HarvardUniversity/Alec Brockell/PAK_Rozee_GPT/Data/Sample"

*******************************************************************************
******************* APPLICATIONS DATASET **************************************
*******************************************************************************

import delimited "$dir/applications.csv", clear

format cv_id %20.0f

********* Checking for mistakes within unique identifiers *********

local varlist cv_log_id user_id cv_id jid company_id

foreach v of local varlist {
	
    capture confirm string variable `v'
	
    if _rc==0 {
		
        tempvar flag
        quietly gen `flag' = regexm(`v', "[^0-9]") if !missing(`v')
        list `v' if `flag'==1
		
    }
}

/*

NOTE: Following user IDs seem to be mistaken.

     +-------------------+
     |           user_id |
     |-------------------|
175. |         ziaafridi |
188. |         omer_sami |
625. |    intelboyinside |
635. |       ahmedharoon |
639. |       ahmedharoon |
     |-------------------|
645. |       ahmedharoon |
673. |    intelboyinside |
693. |         mrshah111 |
748. |           omar263 |
882. |           tid_bid |
     |-------------------|
887. |           tid_bid |
894. |           tid_bid |
908. |           tid_bid |
916. |           tid_bid |
999. | asifharoonwilliam |
     +-------------------+

*/

********* Checking values for other variables *********

tab emp_status

/*


 emp_status |      Freq.     Percent        Cum.
------------+-----------------------------------
     active |        828       82.88       82.88
   rejected |          7        0.70       83.58
shortlisted |         28        2.80       86.39
     viewed |        136       13.61      100.00
------------+-----------------------------------
      Total |        999      100.00


*/

tab test_status // what is the test?


/*

NOTE: 820/999 NULL values.

test_Status |      Freq.     Percent        Cum.
------------+-----------------------------------
  Completed |        176       17.62       17.62
       NULL |        820       82.08       99.70
    Pending |          3        0.30      100.00
------------+-----------------------------------
      Total |        999      100.00


*/

*******************************************************************************
******************* EDUCATION DATASET **************************************
*******************************************************************************

import delimited "$dir/user_educations.csv", clear

tab degreetypeid

tab degreemajorid

/*

NOTE: 695 NULL values for degree type.

degreeTypeI |
          D |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |          2        0.20        0.20
       1173 |          3        0.30        0.50
       1183 |          1        0.10        0.60
       1187 |         10        1.00        1.60
       1189 |         31        3.10        4.70
       1191 |         16        1.60        6.31
       1193 |         23        2.30        8.61
       1195 |          1        0.10        8.71
       1197 |          1        0.10        8.81
       1207 |          6        0.60        9.41
       1209 |          1        0.10        9.51
       1211 |         11        1.10       10.61
       1213 |         49        4.90       15.52
       1215 |          8        0.80       16.32
       1217 |         92        9.21       25.53
       1219 |          2        0.20       25.73
       1223 |          1        0.10       25.83
       1225 |          1        0.10       25.93
       1227 |          7        0.70       26.63
       1266 |          6        0.60       27.23
       1279 |          2        0.20       27.43
       1281 |          7        0.70       28.13
       1446 |          2        0.20       28.33
       1567 |          1        0.10       28.43
       1568 |          1        0.10       28.53
       1928 |          3        0.30       28.83
       2255 |          1        0.10       28.93
       2420 |          5        0.50       29.43
       2422 |          8        0.80       30.23
       2790 |          2        0.20       30.43
       NULL |        695       69.57      100.00
------------+-----------------------------------
      Total |        999      100.00

*/


*******************************************************************************
******************* EXPERIENCES DATASET **************************************
*******************************************************************************

import delimited "$dir/user_experiences.csv", clear

duplicates report user_id

duplicates list jobcompanyid 

* NOTE: Both 0 and NULL values used for missing jobcompanyid.


*******************************************************************************
******************* USERS DATASET **************************************
*******************************************************************************

import delimited "$dir/users.csv", clear

* NOTE: We have full names (first + last) in this sample.

local varlist firstname lastname fullname 

foreach v of local varlist {
	
    capture confirm string variable `v'
	
    if _rc==0 {
        tempvar flag
        quietly gen byte `flag' = !regexm(`v', "[A-Za-z]") if !missing(`v')
        list `v' if `flag'==1
		
    }
}

/*

NOTE: Some obs with non-English letters.

E.g.

     +-----------------------------------------+
     |                               firstname |
     |-----------------------------------------|
892. |                            ÃÂ³ÃÂ­ÃÂ± |
899. |                       ÃÂ®ÃÂ§ÃâÃÂ¯ |
906. |     ÃÂ¹ÃÂ¨ÃÂ¯ÃÂ§ÃâÃâ¦ÃâÃÆ |
914. |                       ÃÂ³ÃÂ§ÃÂ±Ãâ¡ |
925. |   ÃÂ¹ÃÂ¨ÃÂ¯ÃÂ§ÃâÃÂ¹ÃÂ²ÃÅ ÃÂ² |
     |-----------------------------------------|
937. |                    ÃÂ¨ÃÂ¯ÃÂ±ÃÅ ÃÂ© |
946. |                           Ãâ ÃËÃÂ |
947. |                  ÃÂ§ÃÂ­ÃâÃÂ§Ãâ¦ |
949. |                      Ãâ ÃÂ¬ÃËÃâ¦ |
954. |                       ÃÂ®ÃÂ§ÃâÃÂ¯ |
     |-----------------------------------------|
964. | ÃÂ¹ÃÂ¨ÃÂ¯ÃÂ§ÃâÃÂ±ÃÂ­Ãâ¦Ãâ  |
981. |                  Ãâ¦ÃÂ´ÃÂ§ÃÂ¹Ãâ |
982. |                   ÃÂÃÂ±ÃÅ ÃÂ§Ãâ |
983. |                          Ãâ¦Ãâ¡ÃÂ§ |
996. |                        ÃÂ§ÃÅ ÃËÃÂ¨ |
     +-----------------------------------------+


*/



















