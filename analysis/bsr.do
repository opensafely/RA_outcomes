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
forvalues i=2019/2021 {
    local j = `i'+1
    * Import data
    import delimited using ./output/measures/op/input_bsr_`i'-04-01.csv, clear

    *keep if has_ra==1
    * Drop variables not required
    /*drop first_ra_code-has_ra*/
    drop ethnicity-region

    * Check if any missing outpatient info
    egen all_miss_appts = rowmiss(op_appt_date_1 op_appt_date_2 op_appt_date_3 op_appt_date_4 op_appt_date_5 op_appt_date_6 op_appt_date_7 op_appt_date_8 op_appt_date_9 op_appt_date_10)
    tab all_miss_appts
    forvalues a=1/10 {
        gen op_nodate_medium_`a' = (op_appt_date_`a'=="" & op_appt_medium_`a'!=.)
        tab op_nodate_medium_`a'
    }

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
    tab op_appt_medium, m 

     * flag first record for each patient for summarising
    bys patient_id: gen flag=1 if _n==1
    tab flag 

    * Format dates
    gen op_appt_dateA = date(op_appt_date, "YMD")
    gen died_fuA = date(died_fu, "YMD")
    gen dereg_dateA = date(dereg_date, "YMD")
    if `i'!=2021 {
        gen end_fu = date("`j'-03-31", "YMD")
        }
    else {
        gen end_fu = date("`i'-12-31", "YMD")
        }
    * Follow-up time
    gen end_date = min(died_fuA, dereg_dateA, end_fu)
    drop end_fu
    di "Number where end date prior to follow-up start
    count if end_date<date("`j'-03-31", "YMD")
    * display value of end date in period
    di date("`j'-03-31", "YMD")
    * determine range of dates for outpatient appointments to determine which should be dropped
    sum op_appt_dateA
    drop if op_appt_dateA > end_date & op_appt_dateA!=.
    sum op_appt_dateA
    * take out records where end_date prior to start of follow-up
    drop if end_date<=date("`i'-04-01", "YMD")
    di "count if <6 months follow-up"
    count if end_date<date("`i'-10-01", "YMD") & flag==1
    * People with less than 6 months follow-up 
    gen short_fu = end_date<date("`i'-10-01", "YMD")
    tab short_fu 
    * determine length of follow-up during year
    gen days_fu = end_date - date("`i'-04-01", "YMD")
    sum days_fu
    gen fu_yr = days_fu/365
    sum fu_yr, d 

    * Categorise number of outpatient appointments
    bys patient_id: egen tot_appts = total(op_appt_dateA!=.)
    sum tot_appts if flag==1, d
    * Categorise number of outpatient appointments
    label define appt 0 "No appointments" 1 "1-2 per year" 2 "3+ per year"
    egen tot_appts_cat = cut(tot_appts), at(0, 1, 3, 1000) icodes
    bys tot_appts_cat: sum tot_appts
    label values tot_appts_cat appt
    tab tot_appts_cat if flag==1, m

    gen rate = tot_appts / fu_yr
    sum rate if flag==1, d 

    * Determine total number and proportion of in-person and telephone appointments
    * Determine number of appointments where medium is known
    bys patient_id: egen tot_appts_medium = total(op_appt_medium!=0)
    tab tot_appts_medium if flag==1
    * Determine appointments where mode is known 
    gen all_mode_available = (tot_appts_medium==tot_appts)
    replace all_mode_available = 2 if all_mode_available==0 & tot_appts_medium!=0
    label define ava 0 "No mode info" 1 "All appts have mode" 2 "Some appts have mode"
    label values all_mode_available ava 

    forvalues k=1/2 {
        bys patient_id: egen tot_medium_`k' = total(op_appt_medium==`k')
        sum tot_medium_`k' if flag==1, d
        gen prop_medium_`k' = (tot_medium_`k'/tot_appts_medium)*100
        sum prop_medium_`k' if flag==1, d
        }
    egen medium_person = cut(prop_medium_1), at(0, 1, 51, 101) icodes
    bys medium_person: sum prop_medium_1 

    keep patient_id tot_appts_cat tot_appts tot_appts_medium medium_person tot_medium_1 prop_medium_1 tot_medium_2 prop_medium_2 age_cat male urban_rural_bin short_fu all_mode_available 
    describe
    duplicates drop 
    codebook patient_id
    sum tot_appts tot_appts_medium, d 

    list in 1/10

    tab tot_appts_cat 
    tab tot_appts_cat if short_fu==0

    tab tot_appts_cat medium_person 
    tab tot_appts_cat medium_person  if short_fu==0

    di "Number where number of appointments does not equal number where medium is known"
    count if tot_appts!=tot_appts_medium

    sum prop_medium_*

    /*preserve
    table1_mc, vars(medium_person cate) by(tot_appts) missing clear 
    export delimited using ./output/tables/bsr_op_appt_`i'.csv
    restore
    tempfile tempfile
    forvalues b=0/2 {
        preserve 
        keep if medium_person==`b'
        table1_mc, vars(age_cat cate \ male cate \ urban_rural_bin cate) clear
        save tempfile
        restore 

        export delimited using ./output/tables/bsr_op_chars_`i'.csv
    

    tab tot_medium_1 tot_medium_2, m 
    
    tab medium_person tot_appts_cat, m
    */
    }
    




/*preserve
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
 