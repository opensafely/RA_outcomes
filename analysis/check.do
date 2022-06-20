/* ===========================================================================
Do file name:   check.do
Project:        RA outcomes
Date:           16/06/2022
Author:         Ruth Costello
Description:    Checks data and tabulates baseline characteristics 
==============================================================================*/
adopath + ./analysis/ado 
cap log using ./logs/baseline.log, replace
* loop through both cohorts
foreach year in 2018-03-01 2020-03-23 {
    import delimited using "./output/input_monitor_bl_`year'.csv", clear
    * Inital check of frequency of DMARD prescribing and blood tests
    count if age==. 
    count if age<18 
    count if age>110 & age!=.
    sum age, d
    count if sex==""
    tab sex
    sum household, d
    tab care_home
    * Time since first RA code
    gen time_ra = 2018 - first_ra_code
    sum time_ra, d
    sum number_ra_codes, d
    * Checking how frequently each type of drug is prescribed
    foreach var in metho sulfa leflu fbc lft {
        sum `var'_count, d
    }
    foreach drug in metho leflu sulfa {
        egen `drug'_3_mth_total = rowtotal(`drug'_3_0 `drug'_6_3 `drug'_9_6 `drug'_12_9)
        tab `drug'_3_mth_total if (`drug'_count>4 & `drug'_count!=.)
    }
    
    tab dmard_monitored_prior, m

    * Format variables
    *re-order ethnicity
    gen eth5=1 if ethnicity==1
    replace eth5=2 if ethnicity==3
    replace eth5=3 if ethnicity==4
    replace eth5=4 if ethnicity==2
    replace eth5=5 if ethnicity==5
    replace eth5=. if ethnicity==.

    label define eth5 			1 "White"  					///
                                2 "South Asian"				///						
                                3 "Black"  					///
                                4 "Mixed"					///
                                5 "Other"					
                        

    label values eth5 eth5
    safetab eth5, m

    * formatting gender
    gen male=(sex=="M")
    replace male = 0 if sex == "F"
    label define male 0"Female" 1"Male"
    label values male male
    safetab male, miss

    * Make region numeric
    generate region2=.
    replace region2=0 if region=="East"
    replace region2=1 if region=="East Midlands"
    replace region2=2 if region=="London"
    replace region2=3 if region=="North East"
    replace region2=4 if region=="North West"
    replace region2=5 if region=="South East"
    replace region2=6 if region=="South West"
    replace region2=7 if region=="West Midlands"
    replace region2=8 if region=="Yorkshire and The Humber"
    drop region
    rename region2 region
    label var region "region of England"
    label define region 0 "East" 1 "East Midlands"  2 "London" 3 "North East" 4 "North West" 5 "South East" 6 "South West" 7 "West Midlands" 8 "Yorkshire and The Humber"
    label values region region
    safetab region, miss

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

    * Tabulate
    table1_mc if dmard_monitored_prior==1, vars(age_cat cate \ male cate \ region cate \ urban_rural_5 cate \ comorbidity cate \ imd cate)
    table1_mc if dmard_monitored_prior==0, vars(age_cat cate \ male cate \ region cate \ urban_rural_5 cate \ comorbidity cate \ imd cate)
    *export delimited using ./output/tables/op_appt_yrs.csv
}
log close