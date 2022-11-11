/* ===========================================================================
Do file name:   graphs.do
Project:        RA outcomes
Date:           27/07/2022
Author:         Ruth Costello
Description:    Generates line graphs of rates of each outcome and strata per month
==============================================================================*/
cap log using ./logs/graphs.log, replace
cap mkdir ./output/graphs

* Generates line graphs with rate of outpatient appointments over time
foreach this_group in appt_rate  {
        import delimited using ./output/measures/join/measure_op_`this_group'.csv, numericcols(3) clear
        * Generate rate per 100,000
        gen rate = value*100000 
        * Format date
        gen dateA = date(date, "YMD")
        drop date
        format dateA %dD/M/Y
        * Generate line graph
        graph twoway line rate dateA, tlabel(01Apr2019(120)01Apr2022, angle(45) ///
        format(%dM-CY) labsize(small)) ytitle("Rate per 100,000") xtitle("Date") ylabel(#5, labsize(small) ///
        angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) graphregion(fcolor(white))

        graph export ./output/graphs/line_`this_group'.svg, as(svg) replace
        }

* Graphs stratified by medium of appointment
import delimited using ./output/measures/measure_op_appt_medium_rate.csv, numericcols(3) clear
* Take out missing medium or if 4 as this is <10 for all months
drop if op_appt_medium==. | op_appt_medium>=4
* Combine telephone and telemedicine (2 & 3)
* Flag for rows to combine
gen comb = (op_appt_medium == 2 | op_appt_medium == 3)
bys date: egen tele_appts = total(op_appt) if comb==1
bys date: egen tele_pop = total(population) if comb==1
replace op_appt = tele_appts if op_appt_medium==2
replace population = tele_pop if op_appt_medium==2
drop if op_appt_medium==3
drop comb tele_appts tele_pop

* Generate new population as all those with medium described
bys date: egen pop_new = total(population)
* Calculate rate
gen proportion = (op_appt/pop_new)*100

* Format date
gen dateA = date(date, "YMD")
drop date
format dateA %dD/M/Y
* reshape dataset so columns with rates for each ethnicity 
reshape wide value proportion population op_appt, i(dateA) j(op_appt_medium)
describe
* Label strata
label var proportion1 "Face to face"
label var proportion2 "Telephone"
* Generate line graph
graph twoway line proportion1 proportion2 dateA, tlabel(01Apr2019(120)01Apr2022, angle(45) ///
format(%dM-CY) labsize(small)) ytitle("Proportion") xtitle("Date") ylabel(#5, labsize(small) ///
angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) legend(row(1) size(small) ///
title("Consultation medium", size(small))) graphregion(fcolor(white))

graph export ./output/graphs/line_op_appt_medium.svg, as(svg) replace

* Generates line graphs with rate of hospitalisations over time
foreach this_group in ra cardiac vasculitis ild sepsis {
        import delimited using ./output/measures/measure_hosp_`this_group'_rate.csv, numericcols(3) clear
        * Generate rate per 100,000
        gen rate = value*100000 
        * Format date
        gen dateA = date(date, "YMD")
        drop date
        format dateA %dD/M/Y
        * Generate line graph
        graph twoway line rate dateA, tlabel(01Mar2018(120)01Apr2022, angle(45) ///
        format(%dM-CY) labsize(small)) ytitle("Rate per 100,000") xtitle("Date") ylabel(#5, labsize(small) ///
        angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) graphregion(fcolor(white))

        graph export ./output/graphs/line_hosp_`this_group'.svg, as(svg) replace
        }

* Graphs stratified by type of admission e.g. daycase
import delimited using ./output/measures/measure_hosp_ra_daycase_rate.csv, numericcols(3) clear
* Drop if ra_daycase missing
drop if ra_daycase==.
* Generate new population as all those with type of admission
bys date: egen pop_new = total(population)
* Calculate rate
gen proportion = (ra_hosp/pop_new)*100

* Format date
gen dateA = date(date, "YMD")
drop date
format dateA %dD/M/Y
* reshape dataset so columns with rates for each ethnicity 
reshape wide value proportion population ra_hosp, i(dateA) j(ra_daycase)
describe
* Label strata 
label var proportion1 "Ordinary admission"
label var proportion2 "Day case"
label var proportion3 "Regular admission"
* Generate line graph
graph twoway line proportion1 proportion2 proportion3 dateA, tlabel(01Mar2018(120)01Apr2022, angle(45) ///
format(%dM-CY) labsize(small)) ytitle("Rate per 100,000") xtitle("Date") ylabel(#5, labsize(small) ///
angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) legend(row(1) size(small) ///
title("Type of admission", size(small))) graphregion(fcolor(white))

graph export ./output/graphs/line_ra_daycase.svg, as(svg) replace

* Generates line graphs with rate of prescriptions over time
foreach this_group in gc opioid {
        import delimited using ./output/measures/measure_med_`this_group'_rate.csv, numericcols(3) clear
        * Generate rate per 100,000
        gen rate = value*100000 
        * Format date
        gen dateA = date(date, "YMD")
        drop date
        format dateA %dD/M/Y  
        * Generate line graph
        graph twoway line rate dateA, tlabel(01Mar2018(120)01Apr2022, angle(45) ///
        format(%dM-CY) labsize(small)) ytitle("Rate per 100,000") xtitle("Date") ylabel(#5, labsize(small) ///
        angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) graphregion(fcolor(white))

        graph export ./output/graphs/line_med_`this_group'.svg, as(svg) replace
        }