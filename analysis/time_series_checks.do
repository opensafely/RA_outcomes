/* ===========================================================================
Do file name:   time_series_checks.do
Project:        COVID Collateral
Date:     		11/08/2022
Author:         Ruth Costello (based on code by Dominik Piehlmaier)
Description:    Run model checks before time-series
==============================================================================*/

*Log file
cap log using ./logs/time_series_checks.log, replace
cap mkdir ./output/time_series
* Outpatient appointments
local a "appt_first appt"
forvalues i=1/2 {
    local c: word `i' of `a' 
		import delimited "./output/measures/measure_op_`c'_rate.csv", clear	//get csv
		gen temp_date=date(date, "YMD")
		format temp_date %td
		gen postcovid=(temp_date>=date("23/03/2020", "DMY"))
		gen month=mofd(temp_date)
		format month %tm
		drop temp_date
		*Value to rate per 100k
		gen rate = value*100000
		label variable rate "Rate of op `c' per 100,000"
		*Set time series
		tsset month 
		*Kernel density plots to check for normality and extreme values
		kdensity rate, normal name(kd_`c', replace)
		*Autoregression plots by ethnicity
		ac rate, name(ac_`c', replace)
		*Partial autoregression plots by ethnicity
		pac rate, name(pac_`c', replace)
		*Combine Graphs
		graph combine kd_`c' ac_`c' pac_`c' , altshrink
		graph export ./output/time_series/checks_`c'.svg, as(svg) replace
	}

* Outpatient medium
import delimited "./output/measures/measure_op_appt_medium_rate.csv", clear	//get csv
drop if op_appt_medium==. | op_appt_medium>=4
gen temp_date=date(date, "YMD")
format temp_date %td
gen postcovid=(temp_date>=date("23/03/2020", "DMY"))
gen month=mofd(temp_date)
format month %tm
drop temp_date
*Value to rate per 100k
gen rate = value*100000
label variable rate "Rate of op appts per 100,000"
*Set time series
tsset op_appt_medium month
*Kernel density plots to check for normality and extreme values
kdensity rate if op_appt_medium==1, normal name(kd_op_appt_medium_1, replace)
kdensity rate if op_appt_medium==2, normal name(kd_op_appt_medium_2, replace)
kdensity rate if op_appt_medium==3, normal name(kd_op_appt_medium_3, replace)
*Autoregression plots by ethnicity
ac rate if op_appt_medium==1, name(ac_op_appt_medium_1, replace)
ac rate if op_appt_medium==2, name(ac_op_appt_medium_2, replace)
ac rate if op_appt_medium==3, name(ac_op_appt_medium_3, replace)
*Partial autoregression plots by ethnicity
pac rate if op_appt_medium==1, name(pac_op_appt_medium_1, replace)
pac rate if op_appt_medium==2, name(pac_op_appt_medium_2, replace)
pac rate if op_appt_medium==3, name(pac_op_appt_medium_3, replace)

*Combine Graphs
graph combine kd_op_appt_medium_1 kd_op_appt_medium_2 kd_op_appt_medium_3, altshrink 
graph export ./output/time_series/checks_kd_op_appt_medium.svg, as(svg) replace
graph combine ac_op_appt_medium_1 ac_op_appt_medium_2 ac_op_appt_medium_3, altshrink 
graph export ./output/time_series/checks_ac_op_appt_medium.svg, as(svg) replace
graph combine pac_op_appt_medium_1 pac_op_appt_medium_2 pac_op_appt_medium_3, altshrink
graph export ./output/time_series/checks_pac_op_appt_medium.svg, as(svg) replace

/* Hospitalisations
local a "cardiac ild ra sepsis vasculitis"
forvalues i=1/5 {
    local c: word `i' of `a' 
		import delimited "./output/measures/measure_hosp_`c'_rate.csv", clear	//get csv
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
		*Kernel density plots to check for normality and extreme values
		kdensity rate, normal name(kd_`c', replace)
		*Autoregression plots by ethnicity
		ac rate, name(ac_`c', replace)
		*Partial autoregression plots by ethnicity
		pac rate, name(pac_`c', replace)
		*Combine Graphs
		graph combine kd_`c' ac_`c' pac_`c' , altshrink
		graph export ./output/time_series/checks_`c'.svg, as(svg) replace
	}
*/
* RA daycase
import delimited "./output/measures/measure_hosp_ra_daycase_rate.csv", clear	//get csv
drop if ra_daycase==. | ra_daycase==5
gen temp_date=date(date, "YMD")
format temp_date %td
gen postcovid=(temp_date>=date("23/03/2020", "DMY"))
gen month=mofd(temp_date)
format month %tm
drop temp_date
*Value to rate per 100k
gen rate = value*100000
label variable rate "Rate of op appts per 100,000"
*Set time series
tsset ra_daycase month
*Kernel density plots to check for normality and extreme values
kdensity rate if ra_daycase==1, normal name(kd_ra_daycase_1, replace)
kdensity rate if ra_daycase==2, normal name(kd_ra_daycase_2, replace)
kdensity rate if ra_daycase==3, normal name(kd_ra_daycase_3, replace)
kdensity rate if ra_daycase==4, normal name(kd_ra_daycase_4, replace)
*Autoregression plots by ethnicity
ac rate if ra_daycase==1, name(ac_ra_daycase_1, replace)
ac rate if ra_daycase==2, name(ac_ra_daycase_2, replace)
ac rate if ra_daycase==3, name(ac_ra_daycase_3, replace)
ac rate if ra_daycase==4, name(ac_ra_daycase_4, replace)
*Partial autoregression plots by ethnicity
pac rate if ra_daycase==1, name(pac_ra_daycase_1, replace)
pac rate if ra_daycase==2, name(pac_ra_daycase_2, replace)
pac rate if ra_daycase==3, name(pac_ra_daycase_3, replace)
pac rate if ra_daycase==4, name(pac_ra_daycase_4, replace)

*Combine Graphs
graph combine kd_ra_daycase_1 kd_ra_daycase_2 kd_ra_daycase_3, altshrink 
graph export ./output/time_series/checks_kd_ra_daycase.svg, as(svg) replace
graph combine ac_ra_daycase_1 ac_ra_daycase_2 ac_ra_daycase_3, altshrink 
graph export ./output/time_series/checks_ac_ra_daycase.svg, as(svg) replace
graph combine pac_ra_daycase_1 pac_ra_daycase_2 pac_ra_daycase_3, altshrink
graph export ./output/time_series/checks_pac_ra_daycase.svg, as(svg) replace

/*import delimited "./output/measures/measure_med_gc_rate.csv", clear	//get csv
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
*Kernel density plots to check for normality and extreme values
kdensity rate, normal name(kd_gc, replace)
*Autoregression plots by ethnicity
ac rate, name(ac_gc, replace)
*Partial autoregression plots by ethnicity
pac rate, name(pac_gc, replace)
*Combine Graphs
graph combine kd_gc ac_gc pac_gc , altshrink
graph export ./output/time_series/checks_gc.svg, as(svg) replace
*/