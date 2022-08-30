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
foreach this_group in appt_rate appt_first_rate {
        import delimited using ./output/measures/measure_op_`this_group'.csv, numericcols(3) clear
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
* Generate new population as all those with medium described
bys date: egen pop_new = total(population)
* Calculate rate
gen rate = (op_appt/pop_new)*100000

* Format date
gen dateA = date(date, "YMD")
drop date
format dateA %dD/M/Y
* reshape dataset so columns with rates for each ethnicity 
reshape wide value rate population op_appt, i(dateA) j(op_appt_medium)
describe
* Label strata
label var rate1 "Face to face"
label var rate2 "Telephone"
* Generate line graph
graph twoway line rate1 rate2 dateA, tlabel(01Apr2019(120)01Apr2022, angle(45) ///
format(%dM-CY) labsize(small)) ytitle("Rate per 100,000") xtitle("Date") ylabel(#5, labsize(small) ///
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
gen rate = (ra_hosp/pop_new)*100000

* Format date
gen dateA = date(date, "YMD")
drop date
format dateA %dD/M/Y
* reshape dataset so columns with rates for each ethnicity 
reshape wide value rate population ra_hosp, i(dateA) j(ra_daycase)
describe
* Label strata 
label var rate1 "Ordinary admission"
label var rate2 "Day case"
label var rate3 "Regular admission"
* Generate line graph
graph twoway line rate1 rate2 rate3 dateA, tlabel(01Mar2018(120)01Apr2022, angle(45) ///
format(%dM-CY) labsize(small)) ytitle("Rate per 100,000") xtitle("Date") ylabel(#5, labsize(small) ///
angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) legend(row(1) size(small) ///
title("Type of admission", size(small))) graphregion(fcolor(white))

graph export ./output/graphs/line_ra_daycase.svg, as(svg) replace

* Generates line graphs with rate of prescriptions over time
foreach this_group in gc {
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