/* ===========================================================================
Do file name:   outpatients.do
Project:        RA outcomes
Date:           08/06/2022
Author:         Ruth Costello
Description:    Check data, tabulates frequency of outpatient appointments
==============================================================================*/
adopath + ./analysis/ado 

cap log using ./logs/bsr.log, replace

cap mkdir ./output/tables
* Import data
import delimited using ./output/measures/op/input_bsr_2019-04-01.csv

* Drop variables not required
/*drop first_ra_code-has_ra*/
drop ethnicity-region

* Format variables

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

* Define age categories
* Create age categories
egen age_cat = cut(age), at(18, 40, 60, 80, 120) icodes
label define age 0 "18 - 40 years" 1 "41 - 60 years" 2 "61 - 80 years" 3 ">80 years"
label values age_cat age
safetab age_cat, miss

* Reshape to long format 
reshape long op_appt_date_ op_appt_medium_, i(patient_id) j(op_appt_number) 
rename op_appt_date_ op_appt_date 
rename op_appt_medium_ op_appt_medium

* set talk type (medium=4) to missing and combine telephone and telemedicine
replace op_appt_medium = . if op_appt_medium==4
replace op_appt_medium = 2 if op_appt_medium==3
replace op_appt_medium = 0 if op_appt_medium==.

* Format dates
gen op_appt_dateA = date(op_appt_date, "YMD")
gen died_fuA = date(died_fu, "YMD")
gen dereg_dateA = date(dereg_date, "YMD")
* Follow-up time
gen end_date = min(died_fuA, dereg_dateA, date("2020-03-31", "YMD"))
* display value of end date in period
di date("2020-03-31", "YMD")
* determine range of dates for outpatient appointments to determine which should be dropped
sum op_appt_dateA
drop if op_appt_dateA > end_date
sum op_appt_dateA

* Categorise number of outpatient appointments
bys patient_id: egen tot_appts = total(op_appt_dateA!=.)
sum tot_appts, d

* Determine total number and proportion of in-person and telephone appointments
forvalues i=0/2 {
    bys patient_id: egen tot_medium_`i' = total(op_appt_medium==`i')
    sum tot_medium_`i', d
    gen prop_medium_`i' = (tot_medium_`i'/tot_appts)*100
    sum prop_medium_`i', d
    }

/*gen year = 2019

preserve
* Tabulate number of appointments per year
table1_mc, vars(op_appt_2019_cat cate \ op_appt_2020_cat cate \ op_appt_2021_cat cate) clear
export delimited using ./output/tables/op_appt_yrs.csv
restore 
* Tabulate mode of last appointments per year
preserve 
table1_mc, vars(outpatient_medium_2019 cate \ outpatient_medium_2020 cate \ outpatient_medium_2021 cate) clear
export delimited using ./output/tables/bsr_op_appt_medium_yr.csv
restore 
* Tabulate overall characteristics 
preserve
table1_mc, vars(age_cat cate \ male cate \ urban_rural_5 cate) clear
export delimited using ./output/tables/bsr_op_chars.csv
restore
* Characteristics by mode of appointment
tempfile tempfile
forvalues i=2019/2021 {
    preserve
    keep if outpatient_medium_`i'==0
    table1_mc, vars(age_cat cate \ male cate \ urban_rural_5 cate ) clear
    save `tempfile', replace
    restore
    forvalues j=1/2 {
        preserve
        keep if outpatient_medium_`i'==`j'
        table1_mc, vars(age_cat cate \ male cate \ urban_rural_5 cate) clear
        append using `tempfile'
        save `tempfile', replace
        if `j'==2 {
            export delimited using ./output/tables/bsr_characteristics_strata`i'.csv
        }
        restore
    }
} 
*/  
/*gen fu_2019 = ((end_date - date("01Apr2019", "DMY")) /365) if end_date<date("31Mar2020", "DMY")
gen exit = end_date!=.
replace end_date = date("31Mar2022", "DMY") if end_date==.
gen start = date("01Apr2019", "DMY")

stset end_date, failure(exit) origin(start) id(patient_id)
stsplit time_period, at(365, 730, 1095)
preserve 

gen total_appt_2019 = total(outpatient_appt_2019) if time_period==0
gen total_appt_2020 = total(outpatient_appt_2020) if time_period==365
gen total_appt_2021 = total(outpatient_appt_2021) if time_period==730
gen op_appt_no = outpatient_appt_2019 if time_period==0
replace op_appt_no = outpatient_appt_2020 if time_period==365
replace op_appt_no = outpatient_appt_2021 if time_period==730
tab time_period
sum op_appt_no

strate op_appt_no if time_period==0
*/
log close
 