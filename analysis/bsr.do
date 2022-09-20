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
    describe 
    * Check if any missing outpatient info
    egen all_miss_appts = rowmiss(op_appt_date_1 op_appt_date_2 op_appt_date_3 op_appt_date_4 op_appt_date_5 op_appt_date_6 op_appt_date_7 op_appt_date_8 op_appt_date_9 op_appt_date_10)
    tab all_miss_appts
    forvalues a=1/10 {
        gen op_appt_dateA_`a' = date(op_appt_date_`a', "YMD")
        drop op_appt_date_`a'
        gen op_appt_flag_`a' = (op_appt_dateA_`a'!=.)
        tab op_appt_medium_`a'
        gen op_nodate_medium_`a' = (op_appt_dateA_`a'==. & op_appt_medium_`a'!=.)
        tab op_nodate_medium_`a'
    }

    list in 1/5

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
    reshape long op_appt_dateA_ op_appt_medium_, i(patient_id) j(op_appt_number) 
    rename op_appt_dateA_ op_appt_dateA 
    rename op_appt_medium_ op_appt_medium

    /* Check if multiple appointments on same day 
    bys patient_id: gen multi = op_appt_dateA==op_appt_dateA[_n-1] & patient_id==patient_id[_n-1] & op_appt_dateA!=.
    tab multi
    bys patient_id: egen multi_tot = max(multi)
    tab multi_tot*/

    * set talk type (medium=4) to missing and combine telephone and telemedicine
    tab op_appt_medium, m
    replace op_appt_medium = . if op_appt_medium==4
    replace op_appt_medium = 2 if op_appt_medium==3
    tab op_appt_medium, m 

     * flag first record for each patient for summarising
    bys patient_id: gen flag=1 if _n==1
    tab flag 

    * Format dates
    gen died_fuA = date(died_fu, "YMD")
    gen dereg_dateA = date(dereg_date, "YMD")
    if `i'!=2021 {
        gen end_fu = date("`j'-03-31", "YMD")
        }
    else {
        gen end_fu = date("`i'-12-31", "YMD")
        }
    
    list end_fu in 1/5
    * Follow-up time
    gen end_date = min(died_fuA, dereg_dateA, end_fu)
    drop end_fu
    sum end_date
    di "Number where end date prior to follow-up start
    count if end_date<date("`i'-04-01", "YMD")
    * display value of end date in period
    di date("`j'-03-31", "YMD")
    * determine range of dates for outpatient appointments to determine which should be dropped
    sum op_appt_dateA
    replace op_appt_dateA=. if end_date < op_appt_dateA 
    replace op_appt_medium=. if end_date < op_appt_dateA 
    sum op_appt_dateA
    * take out records where end_date prior to start of follow-up
    di "Count of people where end date prior to start of follow-up" 
    count if end_date<=date("`i'-04-01", "YMD") & flag==1
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
    tab tot_appts if flag==1, m
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
    bys patient_id: egen tot_appts_medium = total(op_appt_medium!=.)
    tab tot_appts_medium if flag==1
    di "Count if number of appointments with medium is more than total appointments 
    count if tot_appts < tot_appts_medium & tot_appts_medium!=.
    * Determine appointments where mode is known 
    gen all_mode_available = (tot_appts_medium==tot_appts)
    replace all_mode_available = . if tot_appts==0
    replace all_mode_available = 2 if all_mode_available==0 & tot_appts_medium!=0
    label define ava 0 "No mode info" 1 "All appts have mode" 2 "Some appts have mode"
    label values all_mode_available ava 
    tab tot_appts all_mode_available if flag==1, m
    tab tot_appts_medium all_mode_available if flag==1, m
    tab all_mode_available, m
    tab tot_appts tot_appts_medium if all_mode_available==1

    di "Check if mode information but not all_mode available"
    count if op_appt_medium==1 & all_mode_available!=1
    bys patient_id: egen tot_medium_1 = total(op_appt_medium==1)
    bys patient_id: egen tot_medium_2 = total(op_appt_medium==2)
    di "Count if total of 2 types of appointment does not equal total"
    count if tot_medium_1 + tot_medium_2 != tot_appts_medium

    tab tot_medium_1 all_mode_available, m
    replace tot_medium_1=. if all_mode_available!=1
    tab tot_medium_2 all_mode_available, m
    replace tot_medium_2=. if all_mode_available!=1
    * Determine proportion where f2f
    gen prop_medium_1 = (tot_medium_1/tot_appts_medium)*100
    list tot_medium_1 tot_appts_medium if prop_medium_1==0 & all_mode_available==1 in 1/5
    
    egen medium_person = cut(prop_medium_1), at(0, 50, 101) icodes
    bys medium_person: sum prop_medium_1 


    * Categorise as no appointments, appointments + medium known and all remote, appointments + medium known and at least one f2f, appointment + medium unknown 
    gen medium_remote = 0 if all_mode_available==. & tot_appts==0
    replace medium_remote = 1 if tot_medium_2==tot_appts_medium & tot_medium_2!=0
    replace medium_remote = 2 if all_mode_available==1 & medium_remote==. & tot_medium_1>=1
    replace medium_remote = 3 if (all_mode_available==0 | all_mode_available==2) & medium_remote==.
    tab medium_remote, m
    tab medium_remote all_mode_available, m

    keep patient_id tot_appts_cat tot_appts tot_appts_medium medium_person tot_medium_1 prop_medium_1 age_cat male urban_rural_bin short_fu all_mode_available medium_remote
    describe
    duplicates drop 
    codebook patient_id
    tab tot_appts tot_appts_medium
    tab all_mode_available, m

    list in 1/10

    tab tot_appts_cat 
    tab tot_appts_cat if short_fu==0

    tab tot_appts_cat all_mode_available, m

    tab tot_appts_cat medium_person, row col 
    tab tot_appts_cat medium_person  if short_fu==0, row col
    bys all_mode_available: tab tot_appts_cat medium_person  if short_fu==0, row col

    di "Number where number of appointments does not equal number where medium is known"
    count if tot_appts!=tot_appts_medium

    sum prop_medium_*

    * Create table of number of op appts 
    preserve
    table1_mc, vars(tot_appts_cat cate) missing clear 
    export delimited using ./output/tables/bsr_op_appt_`i'.csv 
    restore
    * Medium of appointment - first 50% at least in person
    preserve 
    table1_mc, vars(medium_person cate) missing clear 
    export delimited using ./output/tables/bsr_op_medium_`i'.csv
    restore
    * Medium of appointment - all remote
    preserve 
    table1_mc, vars(medium_remote cate) missing clear 
    export delimited using ./output/tables/bsr_op_remote_`i'.csv
    restore
    * Create table of number of appointment and mode where mode info available for all appts
    preserve
    keep if all_mode_available==1
    table1_mc, vars(medium_person cate) by(tot_appts_cat) missing clear 
    export delimited using ./output/tables/bsr_op_appt_medium_`i'.csv
    restore
    tempfile tempfile
    preserve 
    keep if medium_person==0 & all_mode_available==1
    table1_mc, vars(age_cat cate \ male cate \ urban_rural_bin cate) clear
    save tempfile, replace
    restore 
    preserve
    keep if medium_person==1 & all_mode_available==1
    table1_mc, vars(age_cat cate \ male cate \ urban_rural_bin cate) clear
    append using tempfile
    export delimited using ./output/tables/bsr_op_medium_chars_`i'.csv
    restore
    preserve 
    keep if medium_remote==0 
    table1_mc, vars(age_cat cate \ male cate \ urban_rural_bin cate) clear
    save tempfile, replace
    restore 
    preserve
    keep if medium_remote==1 
    table1_mc, vars(age_cat cate \ male cate \ urban_rural_bin cate) clear
    append using tempfile
    restore
    preserve
    keep if medium_remote==2 
    table1_mc, vars(age_cat cate \ male cate \ urban_rural_bin cate) clear
    append using tempfile
    restore
    preserve
    keep if medium_remote==3 
    table1_mc, vars(age_cat cate \ male cate \ urban_rural_bin cate) clear
    append using tempfile
    export delimited using ./output/tables/bsr_op_remote_chars_`i'.csv
    restore
    preserve
    keep if all_mode_available==0
    table1_mc, vars(age_cat cate \ male cate \ urban_rural_bin cate) clear
    append using tempfile
    export delimited using ./output/tables/bsr_op_no_medium_chars_`i'.csv
    restore
    preserve
    keep if all_mode_available==2
    table1_mc, vars(age_cat cate \ male cate \ urban_rural_bin cate) clear
    append using tempfile
    export delimited using ./output/tables/bsr_op_uk_medium_chars_`i'.csv
    restore
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
 