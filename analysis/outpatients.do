/* ===========================================================================
Do file name:   outpatients.do
Project:        RA outcomes
Date:           08/06/2022
Author:         Ruth Costello
Description:    Check data, tabulates frequency of outpatient appointments
==============================================================================*/
adopath + ./analysis/ado 

cap log using ./logs/outpatients.log, replace

cap mkdir ./output/tables/
cap mkdir ./output/tempdata

* Import data
import delimited using ./output/input.csv
* Check data
count if age==. 
count if age<18 
count if age>110 & age!=.
sum age, d
count if sex==""
tab sex
* Checking RA algorithm variables
* Checking type of DMARD that meets inclusion
foreach dmard in metho leflu sulfa hydrox {
    gen `dmard'_multi = (`dmard'_count>=2)
    tab `dmard'_multi if has_dmards==1, m
}
gen dmard_multi = (metho_multi==1 | leflu_multi==1 | sulfa_multi==1 | hydrox_multi==1)
tab dmard_multi has_alt_dmard_diag
sum number_ra_codes
di "Number where no DMARDs but does have multiple RA codes and no alt diag"
count if has_dmards==0 & number_ra_codes>=2 & alt_diag!=1
tab has_ra, m
keep if has_ra
* Time since first RA code
gen first_ra_codeA = date(first_ra_code, "YMD")
format first_ra_codeA %dD/N/CY
gen time_ra = (date("01Mar2019", "DMY") - first_ra_codeA)/365.25
sum time_ra, d
sum number_ra_codes, d
sum metho_count, d
sum sulfa_count, d 
sum leflu_count, d 
sum hydrox_count, d 

sum outpatient*, d

forvalues i=2019/2021 {
    sum ra_hosp_beddays_`i' if ra_hosp_`i'>0, d 
}


* How many people are not on DMARDs and have no RA appointments?

* Format variables
*re-order ethnicity
 gen eth5=1 if ethnicity==1
 replace eth5=2 if ethnicity==3
 replace eth5=3 if ethnicity==4
 replace eth5=4 if ethnicity==2
 replace eth5=5 if ethnicity==5
 replace eth5=6 if ethnicity==0

 label define eth5 			1 "White"  					///
							2 "South Asian"				///						
							3 "Black"  					///
							4 "Mixed"					///
							5 "Other"                   ///
                            6 "Missing"					
					

label values eth5 eth5
safetab eth5, m

* formatting gender
gen male=(sex=="M")
replace male = 0 if sex == "F"
label define male 0"Female" 1"Male"
label values male male
safetab male, miss

*create a 4 category rural urban variable 
generate urban_rural_5=.
la var urban_rural_5 "Rural Urban in five categories"
replace urban_rural_5=1 if urban_rural==1
replace urban_rural_5=2 if urban_rural==2
replace urban_rural_5=3 if urban_rural==3|urban_rural==4
replace urban_rural_5=4 if urban_rural==5|urban_rural==6
replace urban_rural_5=5 if urban_rural==7|urban_rural==8
label define urban_rural_5 1 "Urban major conurbation" 2 "Urban minor conurbation" 3 "Urban city and town" 4 "Rural town and fringe" 5 "Rural village and dispersed"
label values urban_rural_5 urban_rural_5
safetab urban_rural_5, miss

*generate a binary rural urban (with missing assigned to urban)
generate urban_rural_bin=.
replace urban_rural_bin=1 if urban_rural<=4|urban_rural==.
replace urban_rural_bin=0 if urban_rural>4 & urban_rural!=.
label define urban_rural_bin 0 "Rural" 1 "Urban"
label values urban_rural_bin urban_rural_bin
safetab urban_rural_bin urban_rural, miss
label var urban_rural_bin "Rural-Urban"

* Make missing category for region
replace region = "missing" if region==""
* Make numeric region variable 
gen region_n = 1 if region=="East Midlands"
replace region_n = 2 if region=="East"
replace region_n = 3 if region=="London"
replace region_n = 4 if region=="North East"
replace region_n = 5 if region=="North West"
replace region_n = 6 if region=="South East"
replace region_n = 7 if region=="South West"
replace region_n = 8 if region=="West Midlands"
replace region_n = 9 if region=="Yorkshire and The Humber"
tab region*, m 

* Define age categories
* Create age categories
egen age_cat = cut(age), at(18, 40, 60, 80, 120) icodes
label define age 0 "18 - 40 years" 1 "41 - 60 years" 2 "61 - 80 years" 3 ">80 years"
label values age_cat age
safetab age_cat, miss

* Smoking status
gen smoking = 0 if smoking_status=="N"
replace smoking = 1 if smoking_status=="S"
replace smoking = 2 if smoking_status=="E"
replace smoking = 3 if smoking==.

label define smok 1 "Current smoker" 2 "Ex-smoker" 0 "Never smoked" 3 "Unknown"
label values smoking smok

* BMI categories
egen bmi_cat = cut(bmi), at(0, 1, 18.5, 24.9, 29.9, 39.9, 100) icodes
bys bmi_cat: sum bmi
* add missing . to zero category
replace bmi_cat = 0 if bmi_cat==. 
label define bmi 0 "Missing" 1 "Underweight" 2 "Healthy range" 3 "Overweight" 4 "Obese" 5 "Morbidly obese"
label values bmi_cat bmi

* Determine if still in follow-up for each year
* Format dates
gen died_fuA = date(died_fu, "YMD")
gen dereg_dateA = date(dereg_date, "YMD")
gen end_fu = date("`j'-03-31", "YMD")
gen end_date = min(died_fuA, dereg_dateA, end_fu)
drop end_fu
sum end_date
di "Number where end date prior to follow-up start"
count if end_date<date("2019-04-01", "YMD")
* determine range of dates for outpatient appointments to determine which should be dropped
gen end_2020 = end_date<date("2020-03-31", "YMD")
gen end_2021 = end_date<date("2021-03-31", "YMD") 
gen end_2022 = end_date<date("2022-03-31", "YMD") 
gen end_2023 = end_date<date("2023-03-31", "YMD") 
tab end_2020
tab end_2021
tab end_2022
tab end_2023

* Set outpatient appointment count to missing if end prior to the end of the year 
forvalues i=2019/2022 {
    local j=`i'+1
    di `j'
    gen op_appt_`i'_orig = outpatient_appt_`i'
    replace outpatient_appt_`i'=. if end_`j'
    *gen op_medium_`i'_orig = outpatient_medium_`i'
    *replace outpatient_medium_`i'=. if end_`j'
    gen op_appt_all_`i'_orig = outpatient_appt_all_`i'
    replace outpatient_appt_all_`i'=. if end_`j'
}


* Categorise number of outpatient appointments
label define appt 0 "No appointments" 1 "1-2 per year" 2 "3 or more per year" 
forvalues i=2019/2022 {
    * Rheumatology outpatient appointments
    egen op_appt_`i'_cat = cut(outpatient_appt_`i'), at(0, 1, 3, 1000) icodes
    * Check all categorised
    bys op_appt_`i'_cat: sum outpatient_appt_`i'
    label values op_appt_`i'_cat appt
    * Same for orginal variables
    egen op_appt_`i'_orig_cat = cut(op_appt_`i'_orig), at(0, 1, 3, 1000) icodes
    * Check all categorised
    bys op_appt_`i'_orig_cat: sum op_appt_`i'_orig
    label values op_appt_`i'_orig_cat appt
    }

* Calculate difference in rheumatology appointments compared to 2019
gen diff_op_2020 = outpatient_appt_2020 - outpatient_appt_2019
gen diff_op_2021 = outpatient_appt_2021 - outpatient_appt_2019
gen diff_op_2022 = outpatient_appt_2022 - outpatient_appt_2019
sum diff_op_2020 diff_op_2021 diff_op_2022, d

* Identify people with no appointments in either year flag them and set difference to missing
forvalues i=2020/2022 {
    gen no_appts_`i' = diff_op_`i'==0 & op_appt_`i'_cat==0
    tab no_appts_`i' op_appt_`i'_cat
    replace diff_op_`i'=. if no_appts_`i'==1
}

* Identify of people with appointments whether they had fewer appointments 
forvalues i=2020/2022 {
    gen fewer_appts_`i' = (diff_op_`i' < 0) if diff_op_`i'!=.
    tab fewer_appts_`i' no_appts_`i'
}

* Categorise number of outpatient appointments (all specialties)
label define appt_all 0 "No appointments" 1 "1-2 per year" 2 "3-5 per year" 3 "6 or more per year"
forvalues i=2019/2022 {
    sum outpatient_appt_all_`i', d
    egen op_appt_all_`i'_cat = cut(outpatient_appt_all_`i'), at(0, 1, 3, 6, 1000) icodes
    * Check all categorised
    bys op_appt_all_`i'_cat: sum outpatient_appt_all_`i'
    label values op_appt_all_`i'_cat appt_all
    * Same for orginal variables
    egen op_appt_all_`i'_orig_cat = cut(op_appt_all_`i'_orig), at(0, 1, 3, 6, 1000) icodes
    * Check all categorised
    bys op_appt_all_`i'_orig_cat: sum op_appt_all_`i'_orig
    label values op_appt_all_`i'_orig_cat appt_all
    }

* Calculate difference in all outpatient appointments compared to 2019
gen diff_op_all_2020 = outpatient_appt_all_2020 - outpatient_appt_all_2019
gen diff_op_all_2021 = outpatient_appt_all_2021 - outpatient_appt_all_2019
gen diff_op_all_2022 = outpatient_appt_all_2022 - outpatient_appt_all_2019
sum diff_op_all_2020 diff_op_all_2021 diff_op_2022, d

* Identify people with no appointments in either year flag them and set difference to missing
forvalues i=2020/2022 {
    gen no_appts_all_`i' = diff_op_all_`i'==0 & op_appt_all_`i'_cat==0
    tab no_appts_all_`i' op_appt_all_`i'_cat
    replace diff_op_all_`i'=. if no_appts_all_`i'==1
    }

* Identify of people with appointments whether they had fewer appointments 
forvalues i=2020/2022 {
    gen fewer_appts_all_`i' = (diff_op_all_`i' < 0) if diff_op_all_`i'!=.
}

preserve
* Tabulate number of rheumatology appointments per year of those with whole year available
table1_mc, vars(op_appt_2019_cat cat \ op_appt_2020_cat cat \ op_appt_2021_cat cat \ op_appt_2022_cat cat \ no_appts_2020 cat \ no_appts_2021 cat \ no_appts_2022 cat \ fewer_appts_2020 cat \ fewer_appts_2021 cat \ fewer_appts_2022 cat) clear
export delimited using ./output/tables/op_appt_yrs.csv
* Rounding numbers in table to nearest 5
describe
destring _columna_1, gen(n) ignore(",") force
destring _columnb_1, gen(percent) ignore("-" "%" "(" ")") force
gen rounded_n = round(n, 7)
keep factor level rounded_n percent
export delimited using ./output/tables/op_appt_yrs_rounded.csv
restore 
preserve
* Tabulate number of rheumatology appointments per year (includes people who end follow-up during year)
table1_mc, vars(op_appt_2019_orig_cat cat \ op_appt_2020_orig_cat cat \ op_appt_2021_orig_cat cat \ op_appt_2022_orig_cat cat) clear
export delimited using ./output/tables/op_appt_orig_yrs.csv
restore 
preserve
* Tabulate number of all outpatient appointments per year of those with whole year available
table1_mc, vars(op_appt_all_2019_cat cat \ op_appt_all_2020_cat cat \ op_appt_all_2021_cat cat \ op_appt_all_2022_cat cat \ no_appts_all_2020 cat \ no_appts_all_2021 cat \ no_appts_all_2022 cat \ fewer_appts_all_2020 cat \ fewer_appts_all_2021 cat \ fewer_appts_all_2022 cat) clear
export delimited using ./output/tables/op_appt_all_yrs.csv
* Rounding numbers in table to nearest 5
describe
destring _columna_1, gen(n) ignore(",") force
destring _columnb_1, gen(percent) ignore("-" "%" "(" ")") force
gen rounded_n = round(n, 7)
keep factor level rounded_n percent
export delimited using ./output/tables/op_appt_all_yrs_rounded.csv
restore 
* Tabulate overall characteristics 
preserve
table1_mc, vars(age_cat cat \ male cat \ urban_rural_bin cat \ region cat \ imd cat \  smoking cat \ time_ra contn \ bmi_cat cat \ eth5 cat) clear
export delimited using ./output/tables/op_chars.csv
* Rounding numbers in table to nearest 5
describe
destring _columna_1, gen(n) ignore(",") force
destring _columnb_1, gen(percent) ignore("-" "%" "(" ")") force
gen rounded_n = round(n, 7)
keep factor level rounded_n percent
export delimited using ./output/tables/op_chars_rounded.csv
restore
* Tabulate characteristics by category of outpatient appointments for each year
forvalues i=2019/2022 {
    preserve
    table1_mc, vars(age_cat cat \ male cat \ urban_rural_bin cat \ region cat \ imd cat \ smoking cat \ time_ra contn \ bmi_cat cat \ eth5 cat) by(op_appt_`i'_cat) clear
    export delimited using ./output/tables/characteristics_strata`i'.csv
    destring _columna_0, gen(n0) ignore(",") force
    destring _columnb_0, gen(percent0) ignore("-" "%" "(" ")") force
    destring _columna_1, gen(n1) ignore(",") force
    destring _columnb_1, gen(percent1) ignore("-" "%" "(" ")") force
    destring _columna_2, gen(n2) ignore(",") force
    destring _columnb_2, gen(percent2) ignore("-" "%" "(" ")") force
    gen rounded_n0 = round(n0, 5)
    gen rounded_n1 = round(n1, 5)
    gen rounded_n2 = round(n2, 5)
    keep factor level rounded_n0 percent0 rounded_n1 percent1 rounded_n2 percent2
    export delimited using ./output/tables/characteristics_strata`i'_rounded.csv
    restore

    /* Tabulate characteristics by whether hospitalised with RA for each year
    preserve
    keep if ra_hosp_`i'==0
    table1_mc, vars(age_cat cate \ male cate \ urban_rural_5 cate \ prescribed_biologics cate \ imd cate \ smoking cate \ time_ra contn \ bmi_cat cate) clear
    save `tempfile', replace
    restore
    preserve
    keep if ra_hosp_`i'==1
    table1_mc, vars(age_cat cate \ male cate \ urban_rural_5 cate \ prescribed_biologics cate \ imd cate \ smoking cate \ time_ra contn \ bmi_cat cate) clear
    append using `tempfile'
    save `tempfile', replace
    export delimited using ./output/tables/characteristics_ra_hosp_`i'.csv
    restore*/
}
* Characteristics by whether prescribed specific drugs 
* Weak opioids 
preserve
table1_mc, vars(age_cat cat \ male cat \ urban_rural_bin cat \ region cat \ imd cat) by(prescribed_weak_opioids) clear
export delimited using ./output/tables/drug_weak_op_chars.csv
* Rounding numbers in table to nearest 5
destring _columna_1, gen(n1) ignore(",") force
destring _columna_0, gen(n0) ignore(",") force
destring _columnb_1, gen(percent1) ignore("-" "%" "(" ")")  force
destring _columnb_0, gen(percent0) ignore("-" "%" "(" ")")  force
gen rounded_n1 = round(n1, 7)
gen rounded_n0 = round(n0, 7)
keep factor level rounded_n0 percent0 rounded_n1 percent1
export delimited using ./output/tables/drug_weak_op_chars_rounded.csv
restore

*Strong opioids 
preserve
table1_mc, vars(age_cat cat \ male cat \ urban_rural_bin cat \ region cat \ imd cat) by(prescribed_strong_opioids) clear
export delimited using ./output/tables/drug_strong_op_chars.csv
* Rounding numbers in table to nearest 5
destring _columna_1, gen(n1) ignore(",") force
destring _columna_0, gen(n0) ignore(",") force
destring _columnb_1, gen(percent1) ignore("-" "%" "(" ")")  force
destring _columnb_0, gen(percent0) ignore("-" "%" "(" ")")  force
gen rounded_n1 = round(n1, 7)
gen rounded_n0 = round(n0, 7)
keep factor level rounded_n0 percent0 rounded_n1 percent1
export delimited using ./output/tables/drug_strong_op_chars_rounded.csv
restore

*GCs 
preserve
table1_mc, vars(age_cat cat \ male cat \ urban_rural_bin cat \ region cat \ imd cat) by(prescribed_gcs) clear
export delimited using ./output/tables/drug_gc_chars.csv
* Rounding numbers in table to nearest 5
destring _columna_1, gen(n1) ignore(",") force
destring _columna_0, gen(n0) ignore(",") force
destring _columnb_1, gen(percent1) ignore("-" "%" "(" ")")  force
destring _columnb_0, gen(percent0) ignore("-" "%" "(" ")")  force
gen rounded_n1 = round(n1, 7)
gen rounded_n0 = round(n0, 7)
keep factor level rounded_n0 percent0 rounded_n1 percent1
export delimited using ./output/tables/drug_gc_chars_rounded.csv
restore

* Tabulate characteristics by categories of differences in rheumatology outpatient appointments for each year
drop if region=="missing"
tempfile tempfile
forvalues i=2020/2022 {
    * Same number or more appointments 
    preserve
    table1_mc, vars(age_cat cat \ male cat \ urban_rural_bin cat \ region cat \ imd cat \ smoking cat \ time_ra contn \ bmi_cat cat \ eth5 cat) by(fewer_appts_`i') clear
    export delimited using ./output/tables/characteristics_fewer_appts_`i'.csv    
    destring _columna_1, gen(n1) ignore(",") force
    destring _columna_0, gen(n0) ignore(",") force
    destring _columnb_1, gen(percent1) ignore("-" "%" "(" ")")  force
    destring _columnb_0, gen(percent0) ignore("-" "%" "(" ")")  force
    gen rounded_n1 = round(n1, 7)
    gen rounded_n0 = round(n0, 7)
    keep factor level rounded_n0 percent0 rounded_n1 percent1
    export delimited using ./output/tables/characteristics_fewer_appts_`i'_rounded.csv
    restore 
    * No appointments
    preserve 
    table1_mc, vars(age_cat cat \ male cat \ urban_rural_bin cat \ region cat \ imd cat \ smoking cat \ time_ra contn \ bmi_cat cat \ eth5 cat) by(no_appts_`i') clear
    export delimited using ./output/tables/characteristics_no_appts_`i'.csv    
    destring _columna_1, gen(n1) ignore(",") force
    destring _columna_0, gen(n0) ignore(",") force
    destring _columnb_1, gen(percent1) ignore("-" "%" "(" ")")  force
    destring _columnb_0, gen(percent0) ignore("-" "%" "(" ")")  force
    gen rounded_n1 = round(n1, 7)
    gen rounded_n0 = round(n0, 7)
    keep factor level rounded_n0 percent0 rounded_n1 percent1
    export delimited using ./output/tables/characteristics_no_appts_`i'_rounded.csv
    restore
    * Logistic regression 
    foreach var in ib1.age_cat male urban_rural_bin i.imd ib3.region_n i.eth5 {
        logit fewer_appts_`i' `var', or 
        est sto m1 
        parmest, label eform format(estimate p min95 max95) saving("./output/tempdata/`var'_diff_rheum_`i'", replace) idstr("`var'_rheum_`i'")
        }
    logit fewer_appts_`i' ib1.age_cat male urban_rural_bin i.imd ib3.region_n i.eth5, or 
    est sto m1
    parmest, label eform format(estimate p min95 max95) saving("./output/tempdata/multi_diff_rheum_`i'", replace) idstr("multi_rheum_`i'")
    }
* Put together 2020 and 2021 logistic regression results
preserve 
use "./output/tempdata/ib1.age_cat_diff_rheum_2020", clear 
append using "./output/tempdata/male_diff_rheum_2020"
append using "./output/tempdata/urban_rural_bin_diff_rheum_2020"
append using "./output/tempdata/i.imd_diff_rheum_2020"
append using "./output/tempdata/ib3.region_n_diff_rheum_2020"
append using "./output/tempdata/i.eth5_diff_rheum_2020"
append using "./output/tempdata/multi_diff_rheum_2020"
append using "./output/tempdata/ib1.age_cat_diff_rheum_2021"
append using "./output/tempdata/male_diff_rheum_2021"
append using "./output/tempdata/urban_rural_bin_diff_rheum_2021"
append using "./output/tempdata/i.imd_diff_rheum_2021"
append using "./output/tempdata/ib3.region_n_diff_rheum_2021"
append using "./output/tempdata/i.eth5_diff_rheum_2021"
append using "./output/tempdata/multi_diff_rheum_2021"
append using "./output/tempdata/ib1.age_cat_diff_rheum_2022"
append using "./output/tempdata/male_diff_rheum_2022"
append using "./output/tempdata/urban_rural_bin_diff_rheum_2022"
append using "./output/tempdata/i.imd_diff_rheum_2022"
append using "./output/tempdata/ib3.region_n_diff_rheum_2022"
append using "./output/tempdata/i.eth5_diff_rheum_2022"
append using "./output/tempdata/multi_diff_rheum_2022"
drop stderr z 
export delimited using ./output/tables/logistic_diff_results.csv 
restore


* Tabulate characteristics by categories of differences in all outpatient appointments for each year
* When stratified there are small numbers with missing region therefore tabulate only those without region missing
drop if region=="missing"
tempfile tempfile
forvalues i=2020/2022 {
    preserve
    table1_mc, vars(age_cat cat \ male cat \ urban_rural_bin cat \ region cat \ imd cat \ smoking cat \ time_ra contn \ bmi_cat cat \ eth5 cat) by(fewer_appts_all_`i') clear
    export delimited using ./output/tables/characteristics_fewer_appts_all_`i'.csv    
    destring _columna_1, gen(n1) ignore(",") force
    destring _columna_0, gen(n0) ignore(",") force
    destring _columnb_1, gen(percent1) ignore("-" "%" "(" ")")  force
    destring _columnb_0, gen(percent0) ignore("-" "%" "(" ")")  force
    gen rounded_n1 = round(n1, 7)
    gen rounded_n0 = round(n0, 7)
    keep factor level rounded_n0 percent0 rounded_n1 percent1
    export delimited using ./output/tables/characteristics_fewer_appts_all_`i'_rounded.csv
    restore 
    * No appointments 
    preserve
    table1_mc, vars(age_cat cat \ male cat \ urban_rural_bin cat \ region cat \ imd cat \ smoking cat \ time_ra contn \ bmi_cat cat \ eth5 cat) by(no_appts_all_`i') clear
    export delimited using ./output/tables/characteristics_no_appts_all_`i'.csv    
    destring _columna_1, gen(n1) ignore(",") force
    destring _columna_0, gen(n0) ignore(",") force
    destring _columnb_1, gen(percent1) ignore("-" "%" "(" ")")  force
    destring _columnb_0, gen(percent0) ignore("-" "%" "(" ")")  force
    gen rounded_n1 = round(n1, 7)
    gen rounded_n0 = round(n0, 7)
    keep factor level rounded_n0 percent0 rounded_n1 percent1
    export delimited using ./output/tables/characteristics_no_appts_all_`i'_rounded.csv
    restore
    * Logistic regression 
    foreach var in urban_rural_bin i.imd i.region_n i.eth5 {
        logit fewer_appts_all_`i' `var' ib1.age_cat male, or 
        est sto m2
        parmest, label eform format(estimate p min95 max95) saving("./output/tempdata/`var'_diff_all_`i'", replace) idstr("`var'_all_`i'")
        }
    logit fewer_appts_all_`i' ib1.age_cat male urban_rural_bin i.imd ib3.region_n i.eth5, or 
    est sto m2
    parmest, label eform format(estimate p min95 max95) saving("./output/tempdata/multi_diff_all_`i'", replace) idstr("multi_all_`i'")
    }
* Put together 2020 and 2021 logistic regression results
use "./output/tempdata/ib1.age_cat_diff_rheum_2020", clear 
append using "./output/tempdata/male_diff_rheum_2020"
append using "./output/tempdata/urban_rural_bin_diff_rheum_2020"
append using "./output/tempdata/i.imd_diff_rheum_2020"
append using "./output/tempdata/ib3.region_n_diff_rheum_2020"
append using "./output/tempdata/i.eth5_diff_rheum_2020"
append using "./output/tempdata/multi_diff_rheum_2020"
append using "./output/tempdata/ib1.age_cat_diff_rheum_2021"
append using "./output/tempdata/male_diff_rheum_2021"
append using "./output/tempdata/urban_rural_bin_diff_rheum_2021"
append using "./output/tempdata/i.imd_diff_rheum_2021"
append using "./output/tempdata/ib3.region_n_diff_rheum_2021"
append using "./output/tempdata/i.eth5_diff_rheum_2021"
append using "./output/tempdata/multi_diff_rheum_2021"
append using "./output/tempdata/ib1.age_cat_diff_rheum_2022"
append using "./output/tempdata/male_diff_rheum_2022"
append using "./output/tempdata/urban_rural_bin_diff_rheum_2022"
append using "./output/tempdata/i.imd_diff_rheum_2022"
append using "./output/tempdata/ib3.region_n_diff_rheum_2022"
append using "./output/tempdata/i.eth5_diff_rheum_2022"
append using "./output/tempdata/multi_diff_rheum_2022"
drop stderr z 
export delimited using ./output/tables/logistic_diff_all_results.csv

    

log close

