/* ===========================================================================
Do file name:   flowchart.do
Project:        RA outcomes
Date:           23/11/2022
Author:         Ruth Costello
Description:    Generates numbers for flowchart
==============================================================================*/
cap log using ./logs/flowchart.log, replace

import delimited using ./output/input_flowchart.csv, clear
* has_follow_up AND
* (age >=18 AND age <=110) AND
* (NOT died) AND
* (sex = 'M' OR sex = 'F') AND
* (stp != 'missing') AND
* (imd != 0) AND
* has_ra


describe
safecount
safetab has_ra_code, m
keep if has_ra_code
safecount
safetab has_follow_up, m
keep if has_follow_up
safecount
safetab died, m
keep if died==0
safecount 
sum age
keep if (age>=18 & age<=110)
safecount
safetab sex, m
keep if (sex=="F" | sex=="M")
safecount
count if stp!=""
drop if stp==""
safecount
safetab imd 
drop if imd==0
safecount
safetab has_ra, m
drop if has_ra==0


