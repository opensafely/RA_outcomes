/* ===========================================================================
Do file name:   graphs.do
Project:        RA outcomes
Date:           27/07/2022
Author:         Ruth Costello
Description:    Generates line graphs of rates of each outcome and strata per month
==============================================================================*/
cap log using ./logs/graphs.log, replace
cap mkdir ./output/graphs

* Generates bar graphs with rate of outpatient appointments over time (rheumatology and then all)
* Rheumatology appointments
import delimited using ./output/measures/join/measure_op_appt_rate.csv, numericcols(3) clear
*Value to percentage of population
gen proportion = value*100
label variable proportion "Proportion of population"
* Format date
gen dateA = date(date, "YMD")
drop date
format dateA %dD/M/Y
* Generate bar graph
/*graph bar proportion, over(dateA, relabel(1 "Apr 2019" 2 " " 3 " " 4 "Jul 2019" 5 " " ///
6 " " 7 "Oct 2019" 8 " " 9 " " 10 "Jan 2020" 11 " " 12 " " 12 "Apr 2020" 13 " " ///
14 " " 15 "Jul 2020" 16 " " 17 " " 18 "Oct 2020" 19 " " 20 " " 21 "Jan 2021" 22 ///
" " 23 " " 24 "Apr 2021" 25 " " 26 " " 27 "Jul 2021" 28 " " 29 " " 30 "Oct 2021" ///
31 " " 32 " " 33 "Jan 2022" 34 " " 35 " " 36 "Apr 2022") label(angle(45) ticks)) ///
graphregion(fcolor(white)) ytitle("%")  ylabel(0(3)15) */
line proportion dateA, graphregion(fcolor(white)) ytitle("%")  ylabel(0(3)15)
graph export ./output/graphs/line_op_appt_rate.svg, as(svg) replace

* All outpatient appointments
import delimited using ./output/measures/join/measure_op_appt_all_rate.csv, numericcols(3) clear
*Value to percentage of population
gen proportion = value*100
label variable proportion "Proportion of population"
* Format date
gen dateA = date(date, "YMD")
drop date
format dateA %dD/M/Y
* Generate bar graph
/*graph bar proportion, over(dateA, relabel(1 "Apr 2019" 2 " " 3 " " 4 "Jul 2019" 5 " " ///
6 " " 7 "Oct 2019" 8 " " 9 " " 10 "Jan 2020" 11 " " 12 " " 12 "Apr 2020" 13 " " ///
14 " " 15 "Jul 2020" 16 " " 17 " " 18 "Oct 2020" 19 " " 20 " " 21 "Jan 2021" 22 ///
" " 23 " " 24 "Apr 2021" 25 " " 26 " " 27 "Jul 2021" 28 " " 29 " " 30 "Oct 2021" ///
31 " " 32 " " 33 "Jan 2022" 34 " " 35 " " 36 "Apr 2022") label(angle(45) ticks)) ///
graphregion(fcolor(white)) ytitle("%")  ylabel(0(5)35) */
line proportion dateA, graphregion(fcolor(white)) ytitle("%")  ylabel(0(5)35)
graph export ./output/graphs/line_op_appt_all_rate.svg, as(svg) replace

tempfile tempfile
* rheumatology and all appointments together
keep op_appt_all proportion dateA 
rename proportion proportion_all
save `tempfile'

import delimited using ./output/measures/join/measure_op_appt_rate.csv, numericcols(3) clear
*Value to percentage of population
gen proportion_rheum = value*100
label variable proportion_rheum "Proportion of population"
* Format date
gen dateA = date(date, "YMD")
drop date
format dateA %dD/M/Y
merge 1:1 date using `tempfile'
drop _merge 
gen proportion_other = proportion_all - proportion_rheum 
* Generate stacked bar chart
graph bar proportion_rheum proportion_other, over(dateA, relabel(1 "Apr 2019" 2 " " 3 " " 4 "Jul 2019" 5 " " 6 " " 7 "Oct 2019" ///
8 " " 9 " " 10 "Jan 2020" 11 " " 12 " " 12 "Apr 2020" 13 " " 14 " " 15 "Jul 2020" 16 " " 17 " " 18 "Oct 2020" 19 " " 20 " " ///
21 "Jan 2021" 22 " " 23 " " 24 "Apr 2021" 25 " " 26 " " 27 "Jul 2021" 28 " " 29 " " 30 "Oct 2021" 31 " " 32 " " 33 "Jan 2022" ///
34 " " 35 " " 36 "Apr 2022") label(angle(45) ticks)) graphregion(fcolor(white)) intensity(50) legend(label(1 "Rheumatology") ///
label(2 "Other")) ytitle("%")  ylabel(0(5)20)
graph export ./output/graphs/line_op_appt_both.svg, as(svg) replace


* Graphs stratified by medium of rheumatology appointment
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
* Generate stacked bar chart
graph bar proportion1 proportion2, over(dateA, relabel(1 "Apr 2019" 2 " " 3 " " 4 "Jul 2019" 5 " " 6 " " 7 "Oct 2019" ///
8 " " 9 " " 10 "Jan 2020" 11 " " 12 " " 12 "Apr 2020" 13 " " 14 " " 15 "Jul 2020" 16 " " 17 " " 18 "Oct 2020" 19 " " 20 " " ///
21 "Jan 2021" 22 " " 23 " " 24 "Apr 2021" 25 " " 26 " " 27 "Jul 2021" 28 " " 29 " " 30 "Oct 2021" 31 " " 32 " " 33 "Jan 2022" ///
34 " " 35 " " 36 "Apr 2022") label(angle(45) ticks)) graphregion(fcolor(white)) intensity(50) legend(label(1 "Face to face") ///
label(2 "Telephone")) ytitle("%")  ylabel(0(3)15)

graph export ./output/graphs/line_op_appt_medium.svg, as(svg) replace

* Generates bar graphs with rate of hospitalisations over time
foreach this_group in ra /*ra_emergency*/ all {
        import delimited using ./output/measures/join/measure_hosp_`this_group'_rate.csv, numericcols(3) clear
        * Generate rate per 100,000
        gen proportion = value*100 
        * Format date
        gen dateA = date(date, "YMD")
        drop date
        format dateA %dD/M/Y
        * Generate line graph
        /*graph twoway line rate dateA, tlabel(01Apr2019(120)01Apr2023, angle(45) ///
        format(%dM-CY) labsize(small)) ytitle("Rate per 100,000") xtitle("Date") ylabel(#5, labsize(small) ///
        angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) graphregion(fcolor(white))*/
        /*graph bar proportion, over(dateA, relabel(1 "Apr 2019" 2 " " 3 " " 4 "Jul 2019" ///
        5 " " 6 " " 7 "Oct 2019" 8 " " 9 " " 10 "Jan 2020" 11 " " 12 " " 12 "Apr 2020" 13 ///
        " " 14 " " 15 "Jul 2020" 16 " " 17 " " 18 "Oct 2020" 19 " " 20 " "21 "Jan 2021" 22 ///
        " " 23 " " 24 "Apr 2021" 25 " " 26 " " 27 "Jul 2021" 28 " " 29 " " 30 "Oct 2021" 31 ///
        " " 32 " " 33 "Jan 2022" 34 " " 35 " " 36 "Apr 2022") label(angle(45) ticks)) ///
        graphregion(fcolor(white)) ytitle("%")  ylabel(0(1)5)*/
        line proportion dateA, graphregion(fcolor(white)) ytitle("%")  ylabel(0(1)5)
        graph export ./output/graphs/line_hosp_`this_group'.svg, as(svg) replace
        }

* Graphs stratified by type of admission e.g. daycase
import delimited using ./output/measures/join/measure_hosp_ra_daycase_rate.csv, numericcols(3) clear
* Determine total population size
bys date: egen tot_population = total(population)
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
*bys date: egen pop_new = total(population)
* Calculate rate
gen proportion = (ra_hosp/tot_population)*100

* Format date
gen dateA = date(date, "YMD")
drop date
format dateA %dD/M/Y
* reshape dataset so columns with rates for each ethnicity 
reshape wide value proportion population tot_population ra_hosp, i(dateA) j(ra_daycase)
describe
* Label strata 
label var proportion1 "Ordinary admission"
label var proportion2 "Day case"
label var proportion3 "Regular admission"
* Generate line graph
graph bar proportion1 proportion2 proportion3, over(dateA, relabel(1 "Apr 2019" 2 " " 3 " " 4 "Jul 2019" 5 " " 6 " " 7 "Oct 2019" ///
8 " " 9 " " 10 "Jan 2020" 11 " " 12 " " 12 "Apr 2020" 13 " " 14 " " 15 "Jul 2020" 16 " " 17 " " 18 "Oct 2020" 19 " " 20 " " ///
21 "Jan 2021" 22 " " 23 " " 24 "Apr 2021" 25 " " 26 " " 27 "Jul 2021" 28 " " 29 " " 30 "Oct 2021" 31 " " 32 " " 33 "Jan 2022" ///
34 " " 35 " " 36 "Apr 2022") label(angle(45) ticks)) graphregion(fcolor(white)) intensity(50) ///
legend(label(1 "Ordinary admission") label(2 "Day case") label(3 "Regular admission")) ytitle("%")  ylabel(0(3)15)

graph export ./output/graphs/line_ra_daycase.svg, as(svg) replace

* Elective vs emergency admission 
* Graphs stratified by admission method
import delimited using ./output/measures/join/measure_hosp_ra_elective_rate.csv, numericcols(3) clear
* Determine total population size
bys date: egen tot_population = total(population)
* Drop if ra_elective missing or is mother-baby record
drop if (ra_elective=="" | ra_elective=="31" | ra_elective=="32" | ra_elective=="82" | ra_elective=="83" | ra_elective=="99")
table ra_elective
* generate binary variable for elective admissions 
gen ra_elective_n = (ra_elective == "81" | ra_elective == "11" | ra_elective == "11.0" | ra_elective == "12" | ra_elective == "12.0" | ra_elective == "13"| ra_elective == "13.0")
tab ra_elective*
bys ra_elective_n: table ra_elective
* Update number of hospitalisations and population to combine all categories combined
bys date ra_elective_n: egen ra_hosp_n = total(ra_hosp)
*bys date: egen population_n = total(population)
drop ra_elective ra_hosp population value

* Calculate proportion
gen proportion = (ra_hosp_n/tot_population)*100
duplicates drop
* Format date
gen dateA = date(date, "YMD")
drop date
format dateA %dD/M/Y
* reshape dataset so columns with rates for each ethnicity 
reshape wide proportion tot_population ra_hosp_n, i(dateA) j(ra_elective)
describe
* Label strata 
label var proportion0 "Emergency admission"
label var proportion1 "Elective admission"
* Export dataset for output checking 
export delimited using ./output/graphs/elective_data.csv 
* Generate line graph
graph bar proportion0 proportion1, over(dateA, relabel(1 "Apr 2019" 2 " " 3 " " 4 "Jul 2019" 5 " " 6 " " 7 "Oct 2019" ///
8 " " 9 " " 10 "Jan 2020" 11 " " 12 " " 12 "Apr 2020" 13 " " 14 " " 15 "Jul 2020" 16 " " 17 " " 18 "Oct 2020" 19 " " 20 " " ///
21 "Jan 2021" 22 " " 23 " " 24 "Apr 2021" 25 " " 26 " " 27 "Jul 2021" 28 " " 29 " " 30 "Oct 2021" 31 " " 32 " " 33 "Jan 2022" ///
34 " " 35 " " 36 "Apr 2022") label(angle(45) ticks)) graphregion(fcolor(white)) intensity(50) ///
legend(label(1 "Emergency admission") label(2 "Elective admission")) ytitle("%")  ylabel(0(1)5)

graph export ./output/graphs/line_ra_elective.svg, as(svg) replace

* Generates bar graphs with rate of prescriptions over time
foreach this_group in gc opioid_strong /*opioid_weak*/ ssri nsaid {
        import delimited using ./output/measures/join/measure_med_`this_group'_rate.csv, numericcols(3) clear
        * Generate rate per 100,000
        gen proportion = value*100 
        * Format date
        gen dateA = date(date, "YMD")
        drop date
        format dateA %dD/M/Y  
        * Generate line graph
        /*graph twoway line rate dateA, tlabel(01Apr2019(120)01Apr2022, angle(45) ///
        format(%dM-CY) labsize(small)) ytitle("Rate per 100,000") xtitle("Date") ylabel(#5, labsize(small) ///
        angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) graphregion(fcolor(white))*/
        /*graph bar proportion, over(dateA, relabel(1 "Apr 2019" 2 " " 3 " " 4 "Jul 2019" 5 " " ///
        6 " " 7 "Oct 2019" 8 " " 9 " " 10 "Jan 2020" 11 " " 12 " " 12 "Apr 2020" 13 " " ///
        14 " " 15 "Jul 2020" 16 " " 17 " " 18 "Oct 2020" 19 " " 20 " "21 "Jan 2021" 22 " " ///
        23 " " 24 "Apr 2021" 25 " " 26 " " 27 "Jul 2021" 28 " " 29 " " 30 "Oct 2021" 31 " " ///
        32 " " 33 "Jan 2022" 34 " " 35 " " 36 "Apr 2022") label(angle(45) ticks)) ///
        graphregion(fcolor(white)) ytitle("%")  ylabel(0(3)15)*/
        line proportion dateA, graphregion(fcolor(white)) ytitle("%")  ylabel(0(3)15)
        graph export ./output/graphs/line_med_`this_group'.svg, as(svg) replace
        }

* Weak opioids has different axis
import delimited using ./output/measures/join/measure_med_opioid_weak_rate.csv, numericcols(3) clear
* Generate rate per 100,000
gen proportion = value*100 
* Format date
gen dateA = date(date, "YMD")
drop date
format dateA %dD/M/Y  
* Generate line graph
/*graph twoway line rate dateA, tlabel(01Apr2019(120)01Apr2022, angle(45) ///
format(%dM-CY) labsize(small)) ytitle("Rate per 100,000") xtitle("Date") ylabel(#5, labsize(small) ///
angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) graphregion(fcolor(white))*/
/*graph bar proportion, over(dateA, relabel(1 "Apr 2019" 2 " " 3 " " 4 "Jul 2019" 5 " " ///
6 " " 7 "Oct 2019" 8 " " 9 " " 10 "Jan 2020" 11 " " 12 " " 12 "Apr 2020" 13 " " ///
14 " " 15 "Jul 2020" 16 " " 17 " " 18 "Oct 2020" 19 " " 20 " "21 "Jan 2021" 22 " " ///
23 " " 24 "Apr 2021" 25 " " 26 " " 27 "Jul 2021" 28 " " 29 " " 30 "Oct 2021" 31 " " ///
32 " " 33 "Jan 2022" 34 " " 35 " " 36 "Apr 2022") label(angle(45) ticks)) ///
graphregion(fcolor(white)) ytitle("%")  ylabel(0(5)25)*/
line proportion dateA, graphregion(fcolor(white)) ytitle("%")  ylabel(0(5)25)
graph export ./output/graphs/line_med_opioid_weak.svg, as(svg) replace