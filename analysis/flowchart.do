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
drop if has_ra==0
safecount
drop if has_follow_up!=1
safecount
drop if died==1
safecount 
drop if (age<18 | age>110)
safecount
drop if (sex=="U" | sex=="I")
safecount
drop if stp==""
safecount
tab imd 
drop if imd==0
safecount


