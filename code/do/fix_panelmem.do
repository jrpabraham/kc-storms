keep year region province mun barangay c9 c20 d56 panel hh_head respname famem idhh idmem wgt_mem treat bgystr

/* Recoding variables */

rename c9 sick
rename c20 enroll
rename d56 job

foreach var of varlist sick enroll job {
	replace `var' = 2 - `var'
	replace `var' = . if `var' < 0
}

/* Fill down mem by year 2000-2010 */

destring idhh, replace
destring idmem, replace
drop if wgt_mem == 888
xtset idmem year

set obs 32507
replace year = 1990 in 32507
set obs 32508
replace year = 2012 in 32508

tsfill, full
drop if idmem == .

replace idhh = floor(idmem/100) if idhh == .
replace barangay = floor(idhh/1000) if barangay == .
replace hh_head = idhh - (barangay*1000) if hh_head == .

egen OK1 = anymatch(barangay), values(2 4 6 11 14 23 24 26 27 28 30 31 34 36 38 39 48 49 58 59 63 64 66 67 70 72 78 81 85 87 88 89 90 91 100 110 112 114 118 123 126 129 130 133 134)
egen OK2 = anymatch(barangay), values(1 3 9 12 20 22 37 41 42 46 51 52 53 60 76 79 83 84 92 99 104 106 111 113 117 121 124 125 127 132)
egen OK3 = anymatch(barangay), values(13 15 18 19 25 35 43 45 50 54 55 62 74 77 82 93 95 96 97 98 101 108 116 131)
egen OK4 = anymatch(barangay), values(5 7 8 10 16 17 21 29 32 33 40 44 47 56 57 61 65 68 69 71 73 75 80 86 94 102 103 105 107 109 115 119 120 122 128 135)

forv prv = 1/4 {
	qui replace province = `prv' if OK`prv' == 1 & province == .
	drop OK`prv'
}

/* Create disaggregate treatment indicators */

replace treat = 0 if year == 2003 | treat == 2
drop if treat == 8

gen s_treat = 0
replace s_treat = 1 if treat == 1 & year <= 2007

gen l_treat = 0
replace l_treat = 1 if treat == 1 & year > 2007

/* Merge village project information */

merge m:1 barangay using barangay_names.dta
drop _merge

merge m:1 bnames using k1.dta
replace has_sp = 0 if has_sp == .
drop _merge

/*
Many-to-one merge of storm and KALAHI by province
merge m:1 province year using PHL_by_year_1950_2012.dta
drop _merge
drop if idhh == .
*/

/* Estimation */

foreach x of varlist maxs {
	foreach y of varlist enroll job sick {
	
	qui xtreg `y' i.treat L(0/4).`x', fe vce(cluster mun)
	outreg2 using `y'_`x'reg.doc , addtext(FE, Individual, Time Trend, None)
	
	qui xtreg `y' i.treat L(0/4).`x' i.year, fe vce(cluster mun)
	outreg2 using `y'_`x'reg.doc , append addtext(FE, Individual, Time Trend, Year FE)
	
	qui xtreg `y' i.treat L(0/4).`x' year, fe vce(cluster mun)
	outreg2 using `y'_`x'reg.doc , append addtext(FE, Individual, Time Trend, Linear)

	qui xtreg `y' i.treat##c.L(0/4).`x', fe vce(cluster mun)
	outreg2 using `y'_`x'reg.doc , append addtext(FE, Individual, Time Trend, None)
	
	qui xtreg `y' i.treat##c.L(0/4).`x' i.year, fe vce(cluster mun)
	outreg2 using `y'_`x'reg.doc , append addtext(FE, Individual, Time Trend, Year FE)
	
	qui xtreg `y' i.treat##c.L(0/4).`x' year, fe vce(cluster mun)
	outreg2 using `y'_`x'reg.doc , append addtext(FE, Individual, Time Trend, Linear)
		
	}
}
