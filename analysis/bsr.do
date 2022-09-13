/* ===========================================================================
Do file name:   outpatients.do
Project:        RA outcomes
Date:           08/06/2022
Author:         Ruth Costello
Description:    Check data, tabulates frequency of outpatient appointments
==============================================================================*/
cap log using ./logs/bsr.log, replace

cap mkdir ./output/tables
* Import data
import delimited using ./output/input.csv

keep if has_ra

/* Format dates
gen died_fuA = date(died_fu, "YMD")
gen dereg_dateA = date(dereg_date, "YMD")
* Flag if either died or deregistered after 1st September 2019, 2020 and 2021
gen out_2019 = (died_fuA<date("01Sep2019", "DMY") | dereg_dateA<date("01Sep2019", "DMY"))
gen out_2020 = (died_fuA<date("01Sep2020", "DMY") | dereg_dateA<date("01Sep2020", "DMY"))
gen out_2021 = (died_fuA<date("01Sep2021", "DMY") | dereg_dateA<date("01Sep2021", "DMY"))
*/
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

* Determine frequency that mode of appointment captured each year
tab outpatient_medium_2019, m 
tab outpatient_medium_2020, m 
tab outpatient_medium_2021, m 
