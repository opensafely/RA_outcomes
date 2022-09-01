/* ===========================================================================
Do file name:   outpatients.do
Project:        RA outcomes
Date:           08/06/2022
Author:         Ruth Costello
Description:    Check data, tabulates frequency of outpatient appointments
==============================================================================*/
adopath + ./analysis/ado 

cap log using ./logs/outpatients.log, replace

cap mkdir ./output/tables
* Import data
import delimited using ./output/input.csv
* Check data
count if age==. 
count if age<18 
count if age>110 & age!=.
sum age, d
count if sex==""
tab sex
sum household, d
tab care_home_type
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
* Time since first RA code
gen first_ra_codeA = date(first_ra_code, "YMD")
format first_ra_codeA %dD/N/CY
gen time_ra = (date("01Mar2018", "DMY") - first_ra_codeA)/365.25
sum time_ra, d
sum number_ra_codes, d
sum metho_count, d
sum sulfa_count, d 
sum leflu_count, d 
sum hydrox_count, d 

sum outpatient*, d

keep if has_ra

* How many people are not on DMARDs and have no RA appointments?


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
label define bmi 0 "Missing" 1 "Underweight" 2 "Healthy range" 3 "Overweight" 4 "Obese" 5 "Morbidly obese"
label values bmi_cat bmi

* Categorise number of outpatient appointments
label define appt 0 "No appointments" 1 "1-2 per year" 2 "3-6 per year" 3 "7-12 per year" 4 "More than 12 per year"
forvalues i=2019/2021 {
    egen op_appt_`i'_cat = cut(outpatient_appt_`i'), at(0, 1, 3, 7, 13, 1000) icodes
    label values op_appt_`i'_cat appt
    }
preserve
* Tabulate number of appointments per year
table1_mc, vars(op_appt_2019_cat cate \ op_appt_2020_cat cate \ op_appt_2021_cat cate) clear
export delimited using ./output/tables/op_appt_yrs.csv
restore 
* Tabulate overall characteristics 
preserve
table1_mc, vars(age_cat cate \ male cate \ region cate \ urban_rural_5 cate \ prescribed_biologics cate \ imd cate \ care_home cate \ smoking cate \ time_ra contn \ bmi_cat cate) clear
export delimited using ./output/tables/op_chars.csv
restore
* Tabulate characteristics by category of outpatient appointments for each year
tempfile tempfile
forvalues i=2019/2021 {
    preserve
    keep if op_appt_`i'_cat==0
    table1_mc, vars(age_cat cate \ male cate \ region cate \ urban_rural_5 cate \ prescribed_biologics cate \ imd cate \ care_home cate \ smoking cate \ time_ra contn \ bmi_cat cate) clear
    save `tempfile', replace
    restore
    forvalues j=1/4 {
        preserve
        keep if op_appt_`i'_cat==`j'
        table1_mc, vars(age_cat cate \ male cate \ region cate \ urban_rural_5 cate \ prescribed_biologics cate \ imd cate \ care_home cate \ smoking cate \ time_ra contn \ bmi_cat cate) clear
        append using `tempfile'
        save `tempfile', replace
        if `j'==2 {
            export delimited using ./output/tables/characteristics_strata`i'.csv
        }
        restore
        }
    * Tabulate characteristics by whether hospitalised with RA for each year
    preserve
    keep if ra_hosp_`i'==1
    table1_mc, vars(age_cat cate \ male cate \ region cate \ urban_rural_5 cate \ prescribed_biologics cate \ imd cate \ care_home cate \ smoking cate \ time_ra contn \ bmi_cat cate) clear
    export delimited using ./output/tables/characteristics_ra_hosp_`i'.csv
    restore
    }
preserve
    keep if ra_hosp_2018==1
    table1_mc, vars(age_cat cate \ male cate \ region cate \ urban_rural_5 cate \ prescribed_biologics cate \ imd cate \ care_home cate \ smoking cate \ time_ra contn \ bmi_cat cate) clear
    export delimited using ./output/tables/characteristics_ra_hosp_2018.csv
    restore
log close

