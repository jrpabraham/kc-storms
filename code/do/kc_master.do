** Title: KC_Master
** Author: Justin Abraham
** Desc: Kalahi-CIDSS master do file for re-creating dataset and running analysis
** Input: 
** Output: 
** Note: New users must change filepaths

clear all
log close _all
set maxvar 10000
set matsize 11000
set more off

***********
** Setup **
***********

/* Specify directories */

global user "Justin"

glo KC_dir "/Users/$user/Google Drive/Documents/Projects/CDD_disasters"
glo ado_dir "$KC_dir/ado"
glo data_dir "$KC_dir/data"
glo do_dir "$KC_dir/do"
glo fig_dir "$KC_dir/figures"
glo tab_dir "$KC_dir/tables"
glo pub_dir "$KC_dir/publication"
glo log_dir "$KC_dir/log"

sysdir set PERSONAL "$ado_dir"

glo cleanHHdo "KC_CleanHH_2015.06.30.do"
glo cleankc1do "KC_CleanKC1.2015.06.30.do"

/* Customize program */

glo cleandataflag = 1 		// Creates KC_Master.dta from raw
glo summaryflag = 0 		// Outputs summary statistics
glo figuresflag = 0			// Outputs graphs and figures
glo estimateflag = 0		// Outputs regression tables

glo USDconvertflag = 1 		// Runs analysis in USD-PPP
glo ppprate = (0.0229) 		// PPP exchange rate from PHP (2009-2013)

/* Variable list */

glo ydemo "fsize"
glo yaccess ""
glo yagro ""
glo yassets ""
glo ycons ""
glo yexp ""
glo yhealth ""
glo ylabor ""
glo ysocial ""
glo yswb ""

glo ybrgy ""

*************
** Program **
*************

glo currentdate = date("$S_DATE", "DMY")
loc stringdate : di %td_CY.N.D date("$S_DATE", "DMY")
glo stamp = trim("`stringdate'")

log using "$log_dir/KC_${stamp}.log", name($user) text replace

timer clear
timer on 1

/* Select most recent .do files */

foreach root in CleanHH CleanKC1 Summary Figures Estimation {

	loc dofilelist : dir "$do_dir" files "KC_`root'_*.do"
	loc mindistance = 9999

	foreach dofile in `dofilelist' {

		loc dodate = date(substr("`dofile'", -13, 10), "YMD")
		loc distance = $currentdate - `dodate'

		if `mindistance' >= `distance' {
			loc mindistance = `distance'
			loc `root'_top "`dofile'"
		}

	}

}
/* Execute .do files */

if $cleandataflag {

	* do "$do_dir/`CleanKC1_top'"
	do "$do_dir/`CleanHH_top'"

}

if $summaryflag do "$do_dir/`Summary_top'"
if $figuresflag do "$do_dir/`Figures_top'"
if $estimateflag do "$do_dir/`Estimation_top'"

timer off 1
qui timer list
di "Finished in `r(t1)' seconds."

log close _all

/**********
** Notes **
***********

wide or long data?
DD or ANCOVA?
what to do with the midline?
cluster fixed effects?
do we just care about aggregate historical exposure or separate lags?
check outcome autocorrelations
need to check that everyone received training before their midline date
can look at ATE and short/long term effects
storm exposure - intensity, pddi, freq 
project database is not complete - assume everyone received social prep and 612 had registered projects
treatment - assignment, training, completed projects
storms as a dimension of heterogeneity*

Panel DD:
reg y i.K i.year L().maxs, cluster fe

Panel ANCOVA:
reg y1 K KxL().maxs if postsurvey




