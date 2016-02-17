/* Import outcomes and identifiers */

keep year region province mun barangay treat hh_head respname resptype rreplace ethnogrp religion idhh wgt_hh fsize c44i c44ii c44iii c44iv food pcfood nonfood pcnonfoo toexp pcexp pcexp10 panel poor e147a e147b e170 e154e e154d e172_m e172_f e191 e153a e142 d114a d65 d75 d85 d132 bgystr

rename d132 pov_self
rename d65 farming
rename d75 livestock
rename d85 fishing

rename c44i water
rename c44ii electr
rename c44iii healthcr
rename c44iv school
 
rename d114a trexp
rename e142 bayanihan
rename e147a give_time
rename e147b give_cash
rename e153a com_trust
rename e154d loc_trust
rename e154e nat_trust
rename e170 assembly
rename e172_m attend_m
rename e172_f attend_f
rename e191 vote

foreach var of varlist pcexp toexp pcexp10 food nonfood pcfood pcnonfoo trexp {
	gen ln`var' = ln(`var')
}


/* Recode variables to missing */ 

foreach var of varlist pov_self water electr healthcr school {
	replace `var' = . if `var' == 99 | `var' == 88
	qui tab `var', gen(`var')
}

replace attend_m = . if attend_m == 88 | attend_m == 99
replace attend_f = . if attend_f == 88 | attend_f == 99

foreach var of varlist give_time give_cash assembly vote {
	qui replace `var' = 0 if `var' == 2
	qui replace `var' = 1 if `var' == 3
	qui replace `var' = . if `var' == 9 | `var' == 8
}

foreach var of varlist farming livestock fishing bayanihan {
	qui replace `var' = 2 - `var'
}

gen agr = 0
qui replace agr = 1 if farming == 1 & livestock == 1 & fishing == 1
qui replace agr = . if farming == 99 | livestock == 99 | fishing == 99


/* Fill down hh by year observations 2000-2010 */

destring idhh, replace
xtset idhh year

set obs 6403
replace year = 2000 in 6403
set obs 6404
replace year = 2001 in 6404
set obs 6405
replace year = 2002 in 6405

tsfill, full

drop if idhh == .

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
merge m:1 province year using PHL_by_year_2000_2012_Justin.dta
drop _merge
drop if idhh == .
gen tr_pddi = treat*pddi
gen tr_maxs = treat*maxs

*/

/* Estimation

foreach var of varlist toexp pcexp pcexp10 food pcfood nonfood pcnonfoo pov_self1 agr trexp water1 electr1 healthcr1 school1 bayanihan give_time give_cash com_trust loc_trust nat_trust assembly attend_m attend_f {
	foreach x of varlist maxs pddi {
		xtreg `var' tr_`x' treat `x' L.`x' L2.`x' L3.`x', fe vce(cluster barangay)
		xtreg `var' tr_`x' treat `x' L.`x' L2.`x' L3.`x', fe vce(cluster mun)
	}
}
*/

/*
Errata:

Mahayag 427/4, 320/3
San Jose 117/1, 316/3
San Ramon must recode manually 2Libon 120 17Oas 147
San Vicente must recode manually 150Oas 114Libon
*/


