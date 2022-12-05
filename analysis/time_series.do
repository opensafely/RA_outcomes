/* ===========================================================================
Do file name:   time_series_checks.do
Project:        COVID Collateral
Date:     		11/08/2022
Author:         Ruth Costello (based on code by Dominik Piehlmaier)
Description:    Run model checks before time-series
==============================================================================*/
adopath + ./analysis/ado 

*Log file
cap log using ./logs/time_series.log, replace
cap mkdir ./output/time_series

* Outpatient appointments
* Autocorrelation indicates no autocorrelation for op_appt 
foreach file in op_appt hosp_ra hosp_ra_emergency med_gc med_opioid_strong med_opioid_weak med_ssri {
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
    graph export ./output/time_series/itsa_`file'.svg, as(svg) replace
    actest, lags(6)
    }

import delimited "./output/measures/join/measure_op_appt_medium_rate.csv", clear	//get csv
drop if op_appt_medium==. | op_appt_medium>=3
gen temp_date=date(date, "YMD")
format temp_date %td
gen month=mofd(temp_date)
format month %tm
drop temp_date
*Value to percentage of population
gen percent = value*100
label variable percent "Percent of population"
*Set time series
tsset op_appt_medium month 
itsa percent, trperiod(2020m4) treatid(1) figure lag(1) posttrend
graph export ./output/time_series/itsa_op_appt_medium.svg, as(svg) replace
actest, lags(6)

import delimited "./output/measures/join/measure_hosp_ra_daycase_rate.csv", clear	//get csv
drop if ra_daycase==. | ra_daycase>=4
gen temp_date=date(date, "YMD")
format temp_date %td
gen month=mofd(temp_date)
format month %tm
drop temp_date
*Value to percentage of population
gen percent = value*100
label variable percent "Percent of population"
*Set time series
tsset ra_daycase month
itsa percent, trperiod(2020m4) treatid(1) contid(2) figure lag(1) posttrend
graph export ./output/time_series/itsa_hosp_ra_daycase.svg, as(svg) replace
actest, lags(6)


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
