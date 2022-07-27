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
        graph twoway line rate date, tlabel(01Apr2019(120)01Apr2022, angle(45) ///
        format(%dM-CY) labsize(small)) ytitle("Rate per 100,000") xtitle("Date") ylabel(, labsize(small) ///
        angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) legend(row(1) size(small) title("Ethnic categories", size(small)))

        graph export ./output/graphs/line_`this_group'.svg, as(svg) replace
        }
* Graphs stratified by medium of appointment
import delimited using ./output/measures/measure_op_appt_medium_rate.csv, numericcols(3) clear
* Generate rate per 100,000
gen rate = value*100000 
* Format date
gen dateA = date(date, "YMD")
drop date
format dateA %dD/M/Y
* Drop if medium is missing
drop if op_appt_medium==.
* reshape dataset so columns with rates for each ethnicity 
reshape wide value rate population op_appt, i(dateA) j(op_appt_medium)
describe
* Generate line graph
graph twoway line rate1 rate2 rate3 rate4 rate5 rate6 rate7 rate8 rate98 date, tlabel(01Apr2019(120)01Apr2022, angle(45) ///
format(%dM-CY) labsize(small)) ytitle("Rate per 100,000") xtitle("Date") ylabel(, labsize(small) ///
angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) legend(row(1) size(small) title("Ethnic categories", size(small)))

graph export ./output/graphs/line_op_appt_medium.svg, as(svg) replace