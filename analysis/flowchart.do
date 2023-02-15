/* ===========================================================================
Do file name:   flowchart.do
Project:        RA outcomes
Date:           23/11/2022
Author:         Ruth Costello
Description:    Generates numbers for flowchart
==============================================================================*/
cap log using ./logs/flowchart.log, replace
cap mkdir ./output/flowchart

import delimited using ./output/input_flowchart.csv, clear
* has_follow_up AND
* (age >=18 AND age <=110) AND
* (NOT died) AND
* (sex = 'M' OR sex = 'F') AND
* (stp != 'missing') AND
* (imd != 0) AND
* has_ra

* Open file to write values to 
file open table using ./output/flowchart/values.txt, write text replace  
file write table ("Total start") _tab 

describe
safecount
file write table ("`r(N)'") _n ("Has RA") _tab
safetab has_ra, m
keep if has_ra
safecount
file write table ("`r(N)'") _n ("Has follow-up") _tab 
safetab has_follow_up, m
keep if has_follow_up
safecount
file write table ("`r(N)'") _n ("Died") _tab 
safetab died, m
keep if died!=1
safecount
file write table ("`r(N)'") _n ("Age ineligible") _tab  
sum age
keep if (age>=18 & age<=110)
safecount
file write table ("`r(N)'") _n ("Missing sex, stp or IMD") _tab 
safetab sex, m
keep if (sex=="F" | sex=="M")
safecount
count if stp!=""
drop if stp==""
safecount
safetab imd 
drop if imd==0
safecount
file write table ("`r(N)'") _n  



