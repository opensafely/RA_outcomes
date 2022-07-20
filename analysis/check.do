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
    di "number of missing age"
    count if age==. 
    di "number under age 18"
    count if age<18 
    di "number older than 110"
    count if age>110 & age!=.
    sum age, d
    di "number with missing gender"
    count if sex==""
    tab sex
    sum household, d
    tab care_home
    * Checking rheumatic disease
    di "number with no RA, psoriasis or psoriatic arthritis"
    count if has_ra_code==0 & has_psoriasis_code==0 & has_psoriatic_arthritis_code==0
    egen dis_tot = rowtotal(has_ra_code has_psoriatic_arthritis_code has_psoriasis_code)
    tab dis_tot
    * Frequency of and time since first rheumatic disease code
    foreach var in ra psoriasis psoriatic_arthritis {
        tab has_`var'_code
        gen time_`var' = 2018 - first_`var'_code
        sum time_`var', d
    }
    
    * Checking how frequently each type of drug is prescribed & bloods are montiored
    foreach var in metho leflu aza fbc lft creatinine {
        sum `var'_count, d
        gen `var'_monitored = (`var'_count>=3 & `var'_count!=.)
    }
    gen bloods_monitored=(fbc_count>=3 & lft_count>=3 & creatinine_count>=3)
    tab bloods_monitored, m

    di "People with 4+ prescriptions and rheum code"
    tab dmard_rheum_prior, m
    tab dmard_rheum_prior bloods_monitored

    gen dmard_monitored_prior = (dmard_rheum_prior==1 & bloods_monitored==1)

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

    * Flag if in a care-home
    gen care_home=care_home_type!="PR"

    * Tabulate
    table1_mc, vars(age_cat cate \ male cate \ region cate \ urban_rural_5 cate \ comorbidity cate \ imd cate \ care_home cate) by(dmard_monitored_prior)
    *export delimited using ./output/tables/op_appt_yrs.csv
}
log close