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
        *Value to percentage of population
        gen percent = value*100
        label variable percent "Percent of population"
        * Format date
        gen dateA = date(date, "YMD")
        drop date
        format dateA %dD/M/Y
        * Generate line graph
        graph twoway line percent dateA, tlabel(01Apr2019(120)01Apr2022, angle(45) ///
        format(%dM-CY) labsize(small)) ytitle("Percentage of population") xtitle("Date") ylabel(#5, labsize(small) ///
        angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) graphregion(fcolor(white))

        graph export ./output/graphs/line_`this_group'.svg, as(svg) replace
        }

* Graphs stratified by medium of appointment
import delimited using ./output/measures/join/measure_op_appt_medium_rate.csv, numericcols(3) clear
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
drop population

* Format date
gen dateA = date(date, "YMD")
drop date
format dateA %dD/M/Y
* reshape dataset so columns with rates for medium 
reshape wide value proportion op_appt, i(dateA) j(op_appt_medium)
describe
* Label strata
label var proportion1 "Face to face"
label var proportion2 "Telephone"
* Generate line graph - still not ideal - date displays as number
graph bar proportion1 proportion2, over(dateA, relabel(1 "Apr 2019" 2 " " 3 " " 4 "Jul 2019" 5 " " 6 " " 7 "Oct 2019" ///
8 " " 9 " " 10 "Jan 2020" 11 " " 12 " " 12 "Apr 2020" 13 " " 14 " " 15 "Jul 2020" 16 " " 17 " " 18 "Oct 2020" 19 " " 20 " " ///
21 "Jan 2021" 22 " " 23 " " 24 "Apr 2021" 25 " " 26 " " 27 "Jul 2021" 28 " " 29 " " 30 "Oct 2021" 31 " " 32 " " 33 "Jan 2022" ///
34 " " 35 " " 36 "Apr 2022") label( angle(45))) stack graphregion(fcolor(white)) intensity(50) legend(label(1 "Face to face") ///
label(2 "Telephone")) ytitle("Proportion of population")

graph export ./output/graphs/line_op_appt_medium.svg, as(svg) replace

* Generates line graphs with rate of hospitalisations over time
foreach this_group in ra ra_emergency {
        import delimited using ./output/measures/join/measure_hosp_`this_group'_rate.csv, numericcols(3) clear
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

        graph export ./output/graphs/line_hosp_`this_group'.svg, as(svg) replace
        }

* Graphs stratified by type of admission e.g. daycase
import delimited using ./output/measures/join/measure_hosp_ra_daycase_rate.csv, numericcols(3) clear
* Drop if ra_daycase missing or is mother-baby record
drop if (ra_daycase==. | ra_daycase==5 | ra_daycase==8)
* Combine 3 & 4 as both ordinary admission
gen comb = (ra_daycase == 3 | ra_daycase == 4)
bys date: egen ordin_appts = total(ra_hosp) if comb==1
bys date: egen ordin_pop = total(population) if comb==1
replace ra_hosp = ordin_appts if ra_daycase==3
replace population = ordin_pop if ra_daycase==3
drop if ra_daycase==4
drop comb ordin_appts ordin_pop
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
graph bar proportion1 proportion2 proportion3, over(dateA, relabel(1 "Apr 2019" 2 " " 3 " " 4 "Jul 2019" 5 " " 6 " " 7 "Oct 2019" ///
8 " " 9 " " 10 "Jan 2020" 11 " " 12 " " 12 "Apr 2020" 13 " " 14 " " 15 "Jul 2020" 16 " " 17 " " 18 "Oct 2020" 19 " " 20 " " ///
21 "Jan 2021" 22 " " 23 " " 24 "Apr 2021" 25 " " 26 " " 27 "Jul 2021" 28 " " 29 " " 30 "Oct 2021" 31 " " 32 " " 33 "Jan 2022" ///
34 " " 35 " " 36 "Apr 2022") label( angle(45))) stack graphregion(fcolor(white)) intensity(50) ///
legend(label(1 "Ordinary admission") label(2 "Day case") label(3 "Regular admission")) ytitle("Proportion of population")

graph export ./output/graphs/line_ra_daycase.svg, as(svg) replace

* Generates line graphs with rate of prescriptions over time
foreach this_group in gc opioid_strong opioid_weak ssri nsaid {
        import delimited using ./output/measures/join/measure_med_`this_group'_rate.csv, numericcols(3) clear
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

        graph export ./output/graphs/line_med_`this_group'.svg, as(svg) replace
        }