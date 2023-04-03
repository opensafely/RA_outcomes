/* ===========================================================================
Do file name:   time_series.do
Project:        RA_outcomes
Date:     		11/08/2022
Author:         Ruth Costello
Description:    Run time-series analysis
==============================================================================*/
adopath + ./analysis/ado 

*Log file
cap log using ./logs/time_series.log, replace
cap mkdir ./output/time_series
cap mkdir ./output/tables
cap mkdir ./output/tempdata

* Outpatient appointments amd hospitalisations
* Autocorrelation indicates no autocorrelation for op_appt 
foreach file in op_appt op_appt_all hosp_ra /*hosp_ra_emergency*/ hosp_all med_gc med_opioid_strong med_opioid_weak med_ssri med_nsaid {
    import delimited "./output/measures/join/measure_`file'_rate.csv", clear	//get csv
    gen temp_date=date(date, "YMD")
    format temp_date %td
    gen month=mofd(temp_date)
    format month %tm
    drop temp_date
    *Value to percentage of population
    gen percent = value*100
    label variable percent "Percent of population"
    *Set time series
    tsset month 
    itsa percent, trperiod(2020m4) figure single lag(1) posttrend
    parmest, label saving("./output/tempdata/`file'_itsa_output", replace)
    graph export ./output/time_series/itsa_`file'.svg, as(svg) replace
    actest, lags(6)
    }

* Medium of rheumatology outpatient appointments
import delimited "./output/measures/join/measure_op_appt_medium_rate.csv", clear	//get csv
drop if op_appt_medium==. | op_appt_medium>=3
gen temp_date=date(date, "YMD")
format temp_date %td
gen month=mofd(temp_date)
format month %tm
drop temp_date
* Generate new population as all those with medium described
bys date: egen pop_new = total(population)
* Calculate rate
gen percent = (op_appt/pop_new)*100
drop population
label variable percent "Percent of population"
*Set time series
tsset op_appt_medium month 
itsa percent, trperiod(2020m4) treatid(2) figure lag(1) posttrend
parmest, label saving("./output/tempdata/op_appt_medium_itsa_output", replace)
graph export ./output/time_series/itsa_op_appt_medium.svg, as(svg) replace
actest, lags(6)

* Daycase admissions vs regular/ordinary 
import delimited "./output/measures/join/measure_hosp_ra_daycase_rate.csv", clear	//get csv
drop if ra_daycase==. | ra_daycase>=4
gen temp_date=date(date, "YMD")
format temp_date %td
gen month=mofd(temp_date)
format month %tm
gen postcovid=(temp_date>=date("23/03/2020", "DMY"))
drop temp_date
* Generate new population as all those with medium described
bys date: egen pop_new = total(population)
* Calculate percentage
gen percent = (ra_hosp/pop_new)*100
drop population
label variable percent "Percent of population"
*Set time series
tsset ra_daycase month
newey percent ra_daycase##postcovid, lag(1) force 
* Itsa compared treat group to all other groups
itsa percent, trperiod(2020m4) treatid(2) figure lag(1) posttrend
parmest, label saving("./output/tempdata/ra_daycase_itsa_output", replace)
graph export ./output/time_series/itsa_hosp_ra_daycase.svg, as(svg) replace
actest, lags(6)


* Method of admission - elective vs emergency
* Graphs stratified by admission method
import delimited using ./output/measures/join/measure_hosp_ra_elective_rate.csv, numericcols(3) clear
* Drop if ra_elective missing or is mother-baby record
drop if (ra_elective=="" | ra_elective=="31" | ra_elective=="32" | ra_elective=="82" | ra_elective=="83")
table ra_elective
* generate binary variable for elective admissions 
gen ra_elective_n = (ra_elective == "81" | ra_elective == "11" | ra_elective == "11.0" | ra_elective == "12" | ra_elective == "12.0" | ra_elective == "13"| ra_elective == "13.0")
tab ra_elective*
bys ra_elective_n: table ra_elective
* Update number of hospitalisations and population to combine all categories combined
bys date ra_elective_n: egen ra_hosp_n = total(ra_hosp)
bys date: egen population_n = total(population)
drop ra_elective ra_hosp population value
* Elective variable is now proportion of all hospitalisations that are elective
* Keep only elective as elective==0 is opposite i.e. same information 
drop if ra_elective_n == 0
* Calculate proportion
gen percent = (ra_hosp_n/population_n)*100
duplicates drop
* Format date
gen dateA = date(date, "YMD")
drop date
format dateA %td
gen month=mofd(dateA)
format month %tm
*Set time series
tsset month 
itsa percent, trperiod(2020m4) figure single lag(1) posttrend
parmest, label saving("./output/tempdata/ra_elective_itsa_output", replace)
graph export ./output/time_series/itsa_ra_elective.svg, as(svg) replace
actest, lags(6)

* Append results together
tempfile tempfile
use "./output/tempdata/ra_elective_itsa_output", clear
gen outcome = "ra_elective"
save `tempfile', replace

foreach var in op_appt op_appt_all hosp_ra /*hosp_ra_emergency*/ hosp_all med_gc med_opioid_strong med_opioid_weak med_ssri med_nsaid op_appt_medium ra_daycase {
    use "./output/tempdata/`var'_itsa_output", clear
    gen outcome = "`var'"
    append using `tempfile'
    save `tempfile', replace
}
use `tempfile', clear 
describe 
export delimited using "./output/tables/all_itsa_output.csv", replace

/* Outpatient medium
import delimited "./output/measures/join/measure_op_appt_medium_rate.csv", clear	//get csv
putexcel set ./output/time_series/tsreg_tables, sheet(op_appt_medium) modify
drop if op_appt_medium==. | op_appt_medium>=3
gen temp_date=date(date, "YMD")
format temp_date %td
gen postcovid=(temp_date>=date("23/03/2020", "DMY"))
gen month=mofd(temp_date)
format month %tm
drop temp_date
* Generate new population as all those with medium described
bys date: egen pop_new = total(population)
* Calculate rate
gen rate = (op_appt/pop_new)*100000
label variable rate "Rate of op appts per 100,000"
*Set time series
tsset op_appt_medium month
newey rate i.op_appt_medium##i.postcovid, lag(1) force
*Export results
putexcel E1=("Number of obs") G1=(e(N))
putexcel E2=("F") G2=(e(F))
putexcel E3=("Prob > F") G3=(Ftail(e(df_m), e(df_r), e(F)))
matrix a = r(table)'
putexcel A6 = matrix(a), rownames
putexcel save
*quietly margins postcovid
*marginsplot
*graph export ./output/time_series/margins_op_appt_medium.svg, as(svg) replace
* Itsa model
itsa rate, trperiod(2020m4) figure treatid(1) lag(1)
graph export ./output/time_series/itsa_appt_medium.svg, as(svg) replace
import excel using ./output/time_series/tsreg_tables.xlsx, sheet (op_appt_medium) clear
export delimited using ./output/time_series/tsreg_op_appt_medium.csv, replace

* Hospitalisations
local a "cardiac ild ra sepsis vasculitis"
forvalues i=1/5 {
    local c: word `i' of `a' 
		import delimited "./output/measures/join/measure_hosp_`c'_rate.csv", clear	//get csv
        putexcel set ./output/time_series/tsreg_tables, sheet(hosp_`c') modify
		gen temp_date=date(date, "YMD")
		format temp_date %td
		gen postcovid=(temp_date>=date("23/03/2020", "DMY"))
		gen month=mofd(temp_date)
		format month %tm
		drop temp_date
		*Value to rate per 100k
		gen rate = value*100000
		label variable rate "Rate of hospitalisations `c' per 100,000"
		*Set time series
		tsset month 
		newey rate i.postcovid, lag(1) force
        *Export results
        putexcel E1=("Number of obs") G1=(e(N))
        putexcel E2=("F") G2=(e(F))
        putexcel E3=("Prob > F") G3=(Ftail(e(df_m), e(df_r), e(F)))
        matrix a = r(table)'
        putexcel A6 = matrix(a), rownames
        putexcel save
        *quietly margins postcovid
        *marginsplot
        *graph export ./output/time_series/margins_hosp_`c'.svg, as(svg) replace
        itsa rate, trperiod(2020m4) figure single lag(1)
        graph export ./output/time_series/itsa_`c'.svg, as(svg) replace
        import excel using ./output/time_series/tsreg_tables.xlsx, sheet (hosp_`c') clear
        export delimited using ./output/time_series/tsreg_hosp_`c'.csv, replace
	}

* RA daycase
import delimited "./output/measures/join/measure_hosp_ra_daycase_rate.csv", clear	//get csv
putexcel set ./output/time_series/tsreg_tables, sheet(hosp_ra_daycase) modify
drop if ra_daycase==. | ra_daycase>=4
gen temp_date=date(date, "YMD")
format temp_date %td
gen postcovid=(temp_date>=date("23/03/2020", "DMY"))
gen month=mofd(temp_date)
format month %tm
drop temp_date
* Generate new population as all those with type of admission
bys date: egen pop_new = total(population)
* Calculate rate
gen rate = (ra_hosp/pop_new)*100000
label variable rate "Rate of op appts per 100,000"
*Set time series
tsset ra_daycase month
newey rate i.ra_daycase##i.postcovid, lag(1) force
*Export results
putexcel E1=("Number of obs") G1=(e(N))
putexcel E2=("F") G2=(e(F))
putexcel E3=("Prob > F") G3=(Ftail(e(df_m), e(df_r), e(F)))
matrix a = r(table)'
putexcel A6 = matrix(a), rownames
putexcel save
*quietly margins postcovid
*marginsplot
*graph export ./output/time_series/margins_hosp_ra_daycase.svg, as(svg) replace
* Itsa model
itsa rate, trperiod(2020m4) figure treatid(2) lag(1)
graph export ./output/time_series/itsa_ra_daycase.svg, as(svg) replace
import excel using ./output/time_series/tsreg_tables.xlsx, sheet (hosp_ra_daycase) clear
export delimited using ./output/time_series/tsreg_hosp_ra_daycase.csv, replace

import delimited "./output/measures/join/measure_med_gc_rate.csv", clear	//get csv
putexcel set ./output/time_series/tsreg_tables, sheet(med_gc) modify
gen temp_date=date(date, "YMD")
format temp_date %td
gen postcovid=(temp_date>=date("23/03/2020", "DMY"))
gen month=mofd(temp_date)
format month %tm
drop temp_date
*Value to rate per 100k
gen rate = value*100000
label variable rate "Rate of GC prescribing per 100,000"
*Set time series
tsset month 
newey rate i.postcovid, lag(1) force
*Export results
putexcel E1=("Number of obs") G1=(e(N))
putexcel E2=("F") G2=(e(F))
putexcel E3=("Prob > F") G3=(Ftail(e(df_m), e(df_r), e(F)))
matrix a = r(table)'
putexcel A6 = matrix(a), rownames
putexcel save
*quietly margins postcovid
*marginsplot
*graph export ./output/time_series/margins_med_gc.svg, as(svg) replace
itsa rate, trperiod(2020m4) figure single lag(1)
graph export ./output/time_series/itsa_med_gc.svg, as(svg) replace
import excel using ./output/time_series/tsreg_tables.xlsx, sheet (med_gc) clear
export delimited using ./output/time_series/tsreg_med_gc.csv, replace
