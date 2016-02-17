** Title: KC_CleanHH
** Author: Justin Abraham
** Desc: Prepares household data for analysis
** Input: clean_panelhh.dta
** Output: KC_master_hh.dta

use "$data_dir/raw/PHL_2003_KALAHI_v01_M_Stata8/clean_panelhh.dta", clear

e

***************
** Treatment **
***************

/* Fill out panel */
/*
forval year = 2000/2010 {

	if (`year' != 2003 & `year' != 2006 & `year' != 2010) {

		expand 2 if year == 2003, gen(y`year')
		replace year = `year' if y`year'

		foreach v in _all {
			if ~inlist("`v'", "year", "region", "province", "mun") & ~inlist("`v'", "hh_head", "ethnogrp", "religion") & ~inlist("`v'", "wgt_hh", "treat", "bgystr") & ~inlist("`v'", "barangay", "idhh", "cluster") {
				replace `v' = . if y`year'
			}
		}

		drop y`year'

	}

}
*/
destring idhh, replace

drop if idhh == .

xtset idhh year

/* Clean treatment variables */

la def dummy 0 "No" 1 "Yes"

la def region 5 "Bicol" 6 "W. Visayas" 9 "W. Mindanao" 16 "Caraga"
la val region region

la def prov 1 "Albay" 2 "Capiz" 3 "Zamboanga del Sur" 4 "Agusan del Sur"
la val province prov 

la def municipality 1 "Pio Duran" 2 "Libon" 3 "Malinao" 4 "Polangui" 5 "Ma-ayon" 6 "Dumarao" 7 "Pontevedra" 8 "Pres. Roxas" 9 "Dinas" 10 "Dumingag" 11 "Tambulig" 12 "Dimataling" 13 "Esperanza" 14 "San Luis" 15 "Bayugan" 16 "Veruela" 17 "Oas"
la val mun municipality

replace treat = 2 - treat
la var treat "Kalahi-CIDSS"

gen cluster = 0
la var cluster "Municipality cluster"

replace cluster = 1 if mun == 1 | mun == 17
replace cluster = 2 if mun == 2 | mun == 4
replace cluster = 3 if mun == 5 | mun == 7
replace cluster = 4 if mun == 6 | mun == 8
replace cluster = 5 if mun == 9 | mun == 11
replace cluster = 6 if mun == 10 | mun == 12
replace cluster = 7 if mun == 13 | mun == 15
replace cluster = 8 if mun == 14 | mun == 16

tab cluster, gen(cluster_)

gen posttreat = 0 if year == 2003
replace posttreat = 1 if year > 2003 // is this true for midline?
la var posttreat "Surveyed post-treatment" 
la val posttreat dummy

gen adm_name = ""
replace adm_name = "Albay" if province == 1
replace adm_name = "Capiz" if province == 2
replace adm_name = "Zamboanga del Sur" if province == 3
replace adm_name = "Agusan del Sur" if province == 4

/* Merge barangay project data 

merge m:1 barangay using "$data_dir/rawdata/barangay_names.dta"
drop _merge

merge m:1 bnames year using "$data_dir/cleandata/KC1.dta"
drop _merge

ren Province adm_name

/* Merge storm data 

merge m:1 adm_name year using "$data_dir/rawdata/LICRICE/PHL_by_year_2000_2012_Justin.dta"
drop _merge

*/
******************
** Demographics **
******************

*****************
** Consumption ** log pc exp, by category: food, non-food, share of this, trans, gifts/remit, hunger
*****************

************
** Assets ** gifts/remit, house, asset values, loans
************

***********
** Labor ** employment, education attendance, crop production, crop choice, fishing, produce sold, intensive labor (mem)
***********

************
** Health **
************

*****************
** Agriculture **
*****************

************************
** Access to services **
************************

********************
** Social Capital **
********************


***************************
** Subjective Well-being ** compare quality of life, times felt poor, subjective poverty
***************************
//poverty level, calamity, subjective crime/peace

//het: gender, poverty level, head of household, region
**************
** Barangay ** whether it has stuff
**************

save "$data_dir/cleandata/KC_LongHHData_$S_DATE", replace
/*
********************
** Treatment Vars ** need indicator for if/not received uct
********************
la define dummy 0 "No" 1 "Yes"

gen baseline = 1
la variable baseline "Respondent completed baseline"
la value baseline dummy

gen endline = .
la variable endline "Respondent completed endline" 
la value endline dummy
replace endline = 1 if wave_1 == 2

gen attr = 0
la variable attr "Respondent attrited"
la value attr dummy
replace attr = 1 if endline == .

gen bad_drop = to_drop // Is that list exhaustive of all never-takers?
replace bad_drop = 0 if bad_drop == .
la variable bad_drop "Forced attrition"
la value bad_drop dummy

gen complier = 1 - bad_drop
la variable complier "Complied with treatment assignment"
la value complier dummy

gen self_attr = 0
la variable self_attr "Respondent self-attrited"
la value self_attr dummy
replace self_attr = 1 if attr & ~bad_drop

gen participation = 0
la variable participation "Participation"
la define participation 0 "Excluded"  1 "Complete" 2 "Self attrition" 3 "Forced attrition"
la value participation participation
replace participation = 0 if baseline
replace participation = 1 if endline
replace participation = 2 if attr & ~bad_drop
replace participation = 3 if bad_drop

la variable treatmentgroup "Treatment group"
la define groupla 1 "Control" 2 "Ins" 3 "UCT"
la value treatmentgroup groupla

gen control = 0
la variable control "Respondent in control group"
replace control = 1 if treatmentgroup == 1

gen treat = 0
la variable treat "Respondent in either treatment arm"
la value treat dummy
replace treat = 1 - control

gen insured = 0
la variable insured "Insurance"
replace insured = 1 if treatmentgroup == 2

gen uct = 0
la variable uct "UCT"
replace uct = 1 if treatmentgroup == 3

gen got_insured = 0
replace got_insured = 1 if cic_joindate1 != .
la variable got_insured "Enrolled in CIC insurance plan"
la value got_insured dummy

gen got_uct = 0
replace got_uct = 1 if uct & complier
la variable got_uct "Received cash transfer"
la value got_uct dummy

gen treatperiod = endlinedate - baselinedate
la variable treatperiod "Days between surveys"

gen returninterview_1 = 0
gen returninterviewstart_1 = .
gen returninterviewend_1 = .

forval wv = 0/1 {
	clonevar interviewstart_`wv' = firstinterviewstart_`wv'
	la variable interviewstart_`wv' "Time of round `wv' interview"
	replace interviewstart_`wv' = returninterviewstart_`wv' if returninterviewstart_`wv' != .
	clonevar interviewend_`wv' = firstinterviewend_`wv'
	la variable interviewend_`wv' "Time of round `wv' interview"
	replace interviewend_`wv' = returninterviewend_`wv' if returninterviewend_`wv' != .
}

******************
** Demographics **
******************
gen female = v3_1_0 - 1
la define gend 0 "Male" 1 "Female"
la value female gend

replace hhsize_0 = 1 if hhsize_0 < 1

gen cohabitating_0 = 0
la variable cohabitating_0 "Cohabitating with partner"
la value cohabitating_0 dummy
replace cohabitating_0 = 1 if v4_1_0 == 2 | v4_1_0 == 3 | v4_1_0 == 5

ren v11_1 v11_1_1

forval wv = 0/1 {

	gen noschool_`wv' = 0
	la variable noschool_`wv' "Received no education"
	replace noschool_`wv' = 1 if v11_1_`wv' == 1

	gen stdschool_`wv' = 0
	la variable stdschool_`wv' "Completed std schooling"
	replace stdschool_`wv' = 1 if v11_1_`wv' >= 10

	gen formschool_`wv' = 0
	la variable formschool_`wv' "Completed formal schooling"
	replace formschool_`wv' = 1 if v11_1_`wv' >= 16

	gen college_`wv' = 0
	la variable college_`wv' "Completed higher education"
	replace college_`wv' = 1 if v11_1_`wv' == 20 | v11_1_`wv' == 24

	gen school_yrs_`wv' = v11_1_`wv' - 1 
	la variable school_yrs_`wv' "Years of formal education"
	replace school_yrs_`wv' = v11_1_`wv' - 2 if v11_1_`wv' > 1 & v11_1_`wv' < 15
	replace school_yrs_`wv' = v11_1_`wv' - 16 if v11_1_`wv'> 16
	replace school_yrs_`wv' = school_yrs_`wv' + 1 if v11_1_`wv' == 15
	replace school_yrs_`wv' = school_yrs_`wv' + 1 if v11_1_`wv' == 16

}

************
** Assets **
************
loc anum 133
forval n = 10/28 {
	rename own`n'_1 v`anum'own_1
	loc ++anum
}

loc anum 133
foreach v of varlist value*_1 {
	rename `v' v`anum'value_1
	loc ++anum
}

foreach v of varlist v*own* v129_0 v579_1 v126_0 v576_1{
	replace `v' = . if `v' < 0
	replace `v' = 2 - `v'
}

foreach v of varlist v*value* {
	replace `v' = . if `v' < 0
}


forval wv = 0/1 {
	ren v133own_`wv' as_phoneown_`wv'
	ren v133value_`wv' as_phonevalue_`wv'
	ren v134own_`wv' as_sofaown_`wv'
	ren v134value_`wv' as_sofavalue_`wv'
	ren v138own_`wv' as_bikeown_`wv'
	ren v138value_`wv' as_bikevalue_`wv'
	ren v139own_`wv' as_radioown_`wv'
	ren v139value_`wv' as_radiovalue_`wv'
	ren v140own_`wv' as_batteryown_`wv'
	ren v140value_`wv' as_batteryvalue_`wv'
	ren v141own_`wv' as_generatorown_`wv'
	ren v141value_`wv' as_generatorvalue_`wv'
	ren v142own_`wv' as_motorcycleown_`wv'
	ren v142value_`wv' as_motorcyclevalue_`wv'
	ren v143own_`wv' as_carown_`wv'
	ren v143value_`wv' as_carvalue_`wv'
	ren v144own_`wv' as_solarown_`wv'
	ren v144value_`wv' as_solarvalue_`wv'
	ren v145own_`wv' as_tvown_`wv'
	ren v145value_`wv' as_tvvalue_`wv'
	ren v146own_`wv' as_toolsown_`wv'
	ren v146value_`wv' as_toolsvalue_`wv'
	ren v148own_`wv' as_wheelbarrowown_`wv'
	ren v148value_`wv' as_wheelbarrowvalue_`wv'
	ren v149own_`wv' as_cartown_`wv'
	ren v149value_`wv' as_cartvalue_`wv'
	ren v150own_`wv' as_stoveown_`wv'
	ren v150value_`wv' as_stovevalue_`wv'
	ren v151own_`wv' as_fridgeown_`wv'
	ren v151value_`wv' as_fridgevalue_`wv'

	gen as_totalvalue_`wv' = 0
	la variable as_totalvalue_`wv' "Total value of owned assets"
	foreach v of varlist as_*value_`wv' {
		replace as_totalvalue_`wv' = as_totalvalue_`wv' + `v' if `v' != .
	}
	if (`wv' == 1) replace as_totalvalue_`wv' = . if attr

	xtile temp = as_totalvalue_`wv', n(2)
	gen as_totalvalueupper_`wv' = .
	la variable as_totalvalueupper_`wv' "Above median asset value"
	replace as_totalvalueupper_`wv' = temp - 1
	drop temp
}

replace as_totalvalue_1 = . if attr

rename v129_0 as_electr_0
rename v579_1 as_electr_1
rename v126_0 as_moved_0
rename v576_1 as_moved_1
rename v127_0 as_house_0
rename v577_1 as_house_1

forval wv = 0/1 {
	gen rent_house_`wv' = 0
	la variable rent_house_`wv' "Respondent rents home"
	replace rent_house_`wv' = 1 if as_house_`wv' == 1

	gen own_house_`wv' = 0
	la variable own_house_`wv' "Respondent owns home"
	replace own_house_`wv' = 1 if as_house_`wv' == 2

	egen as_ownindex_`wv' = weightave(as_*own_`wv'), normby(control)
	la variable as_ownindex_`wv' "Weighted index of asset ownership"

}

*****************
** Consumption **
*****************
ren v154spent_0 cons_rentspent_0
ren v154amount_0 cons_rentamount_0
ren v155spent_0 cons_mortgagespent_0
ren v155amount_0 cons_mortgageamount_0
ren v156spent_0 cons_foodspent_0
ren v156amount_0 cons_foodamount_0
ren v157spent_0 cons_drinksspent_0
ren v157amount_0 cons_drinksamount_0
ren v158spent_0 cons_internetspent_0
ren v158amount_0 cons_internetamount_0
ren cigarettesspent_0 cons_cigarettesspent_0
ren cigarettesamount_0 cons_cigarettesamount_0
ren alcoholspent_0 cons_alcoholspent_0
ren alcoholamount_0 cons_alcoholamount_0
ren v160spent_0 cons_restaurantspent_0
ren v160amount_0 cons_restaurantamount_0
ren v161spent_0 cons_travelspent_0
ren v161amount_0 cons_travelamount_0
ren v162spent_0 cons_gamblingspent_0
ren v162amount_0 cons_gamblingamount_0
ren v163spent_0 cons_clothingspent_0
ren v163amount_0 cons_clothingamount_0
ren v164spent_0 cons_schoolspent_0
ren v164amount_0 cons_schoolamount_0
ren v165spent_0 cons_medicalspent_0
ren v165amount_0 cons_medicalamount_0
ren v166spent_0 cons_firedamagespent_0
ren v166amount_0 cons_firedamageamount_0
ren v167spent_0 cons_waterdamagespent_0
ren v167amount_0 cons_waterdamageamount_0
ren v168spent_0 cons_workmaterialsspent_0
ren v168amount_0 cons_workmaterialsamount_0
ren v169spent_0 cons_religiousspent_0
ren v169amount_0 cons_religiousamount_0
ren v170spent_0 cons_socialspent_0
ren v170amount_0 cons_socialamount_0
ren v171spent_0 cons_friendsspent_0
ren v171amount_0 cons_friendsamount_0
ren v172spent_0 cons_electricityspent_0
ren v172amount_0 cons_electricityamount_0
ren v173spent_0 cons_waterspent_0
ren v173amount_0 cons_wateramount_0
ren v174spent_0 cons_domesticstaffspent_0
ren v174amount_0 cons_domesticstaffamount_0
ren v175spent_0 cons_insurancespent_0
ren v175amount_0 cons_insuranceamount_0
ren v176spent_0 cons_bridespent_0
ren v176amount_0 cons_brideamount_0
ren v177spent_0 cons_fuelspent_0
ren v177amount_0 cons_fuelamount_0

ren spent_1 cons_rentspent_1
ren amount_1 cons_rentamount_1
ren spent2_1 cons_mortgagespent_1
ren amount2_1 cons_mortgageamount_1
ren spent3_1 cons_foodspent_1
ren amount3_1 cons_foodamount_1
ren spent4_1 cons_drinksspent_1
ren amount4_1 cons_drinksamount_1
ren spent5_1 cons_internetspent_1
ren amount5_1 cons_internetamount_1
ren spent6_1 cons_cigarettesspent_1
ren amount6_1 cons_cigarettesamount_1
ren spent7_1 cons_alcoholspent_1
ren amount7_1 cons_alcoholamount_1
ren spent8_1 cons_restaurantspent_1
ren amount8_1 cons_restaurantamount_1
ren spent9_1 cons_travelspent_1
ren amount9_1 cons_travelamount_1
ren spent10_1 cons_gamblingspent_1
ren amount10_1 cons_gamblingamount_1
ren spent11_1 cons_clothingspent_1
ren amount11_1 cons_clothingamount_1
ren spent12_1 cons_schoolspent_1
ren amount12_1 cons_schoolamount_1
ren spent13_1 cons_medicalspent_1
ren amount13_1 cons_medicalamount_1
ren spent14_1 cons_firedamagespent_1
ren amount14_1 cons_firedamageamount_1
ren spent15_1 cons_waterdamagespent_1
ren amount15_1 cons_waterdamageamount_1
ren spent16_1 cons_religiousspent_1
ren amount16_1 cons_religiousamount_1
ren spent17_1 cons_socialspent_1
ren amount17_1 cons_socialamount_1
ren spent18_1 cons_electricityspent_1
ren amount18_1 cons_electricityamount_1
ren spent19_1 cons_waterspent_1
ren amount19_1 cons_wateramount_1
ren spent20_1 cons_domesticstaffspent_1
ren amount20_1 cons_domesticstaffamount_1
ren spent21_1 cons_insurancespent_1
ren amount21_1 cons_insuranceamount_1
ren spent22_1 cons_bridespent_1
ren amount22_1 cons_brideamount_1
ren spent23_1 cons_fuelspent_1
ren amount23_1 cons_fuelamount_1
ren unknownexpenses_1 cons_unknownspent_1
ren unknownexpensesamount_1 cons_unknownamount_1

foreach v of varlist cons_*spent_* {
	replace `v' = . if `v' < 0
	replace `v' = 2 - `v'
}

foreach v of varlist cons_*amount_* {
	replace `v' = . if `v' < 0
}

loc tot "rent mortgage food drinks internet cigarettes alcohol restaurant travel gambling clothing school medical firedamage waterdamage religious social electricity water domesticstaff insurance bride fuel"
loc heal "medical insurance"
loc tempt "cigarettes alcohol gambling"
loc soc "restaurant religious social bride"

forval wv = 0/1 {

	foreach x in `category' {
		replace cons_`x'amount_`wv' = 0 if ~cons_`x'spent_`wv'
	}

	gen cons_totexp_`wv' = 0
	la variable cons_totexp_`wv' "Total household expenditure last month"
	foreach x in `tot' {
		replace cons_totexp_`wv' = cons_totexp_`wv' + cons_`x'amount_`wv' if cons_`x'amount_`wv' != .
	}

	gen cons_healthexp_`wv' = 0
	la variable cons_healthexp_`wv' "Health expenditure last month"
	foreach x in `heal' {
		replace cons_healthexp_`wv' = cons_healthexp_`wv' + cons_`x'amount_`wv' if cons_`x'amount_`wv' != .
	}

	gen cons_temptexp_`wv' = 0
	la variable cons_temptexp_`wv' "Spent on temptation goods last month"
	foreach x in `tempt' {
		replace cons_temptexp_`wv' = cons_temptexp_`wv' + cons_`x'amount_`wv' if cons_`x'amount_`wv' != .
	}
	
	gen cons_socialexp_`wv' = 0
	la variable cons_socialexp_`wv' "Social expenditure last month"
	foreach x in `soc' {
		replace cons_socialexp_`wv' = cons_socialexp_`wv' + cons_`x'amount_`wv' if cons_`x'amount_`wv' != .
	}

	if `wv' == 1 {
		replace cons_totexp_`wv' = cons_totexp_`wv' + cons_unknownamount_1
		replace cons_totexp_`wv' = . if attr
		replace cons_healthexp_`wv' = . if attr
		replace cons_temptexp_`wv' = . if attr
		replace cons_socialexp_`wv' = . if attr
	}
	else if `wv' == 0 {
		replace cons_socialexp_`wv' = cons_socialexp_`wv' + cons_friendsamount_0
		replace cons_totexp_`wv' = cons_totexp_`wv' + cons_workmaterialsamount_0
	}
}

**************************
** Borrowing and saving **
**************************
loc lend "v366_1 v373_1 v380_1 v387_1 v394_1 v401_1 v408_1 v415_1 v422_1 v429_1"
loc i 1
foreach v in `lend' {
	rename `v' v63_`i'_1
	loc ++i
}

foreach v of varlist v63_*_* {
	replace `v' = . if `v' < 0
}

loc ability0 "v67_1_0 v67_2_0 v67_3_0 v67_4_0 v67_5_0 v67_6_0 v67_7_0 v67_8_0 v67_9_0 v67_10_0"
loc ability1 "v370_1 v377_1 v384_1 v391_1 v398_1 v405_1 v412_1 v419_1 v426_1 v433_1"

loc amt_0 "v73_1_0 v73_2_0 v73_3_0 v73_4_0 v73_5_0 v73_6_0 v73_7_0 v73_8_0 v73_9_0 v73_10_0"
loc amt_1 "v436_1 v440_1 v444_1 v448_1 v452_1 v456_1 v460_1 v464_1 v468_1 v472_1"

loc gr_0 "v82_1_0 v82_2_0 v82_3_0 v82_4_0 v82_5_0 v82_6_0 v82_7_0 v82_8_0 v82_9_0 v82_10_0"
loc gr_1 "v479_1 v483_1 v487_1 v491_1 v495_1 v499_1 v503_1 v507_1 v511_1 v515_1"

forval wv = 0/1 {
	ren loan_`wv' bs_borrowed_`wv'
	replace bs_borrowed_`wv' = 0 if bs_borrowed_`wv' == 2
	gen bs_loansamount_`wv' = 0
	la variable bs_loansamount_`wv' "Total amount in loans"

	foreach v of varlist v63_*_`wv' {
		replace bs_loansamount_`wv' = bs_loansamount_`wv' + `v' if `v' != .
	}

	gen bs_payloans_`wv' = 1
	la variable bs_payloans_`wv' "Can pay all loans"

	foreach v in `ability`wv'' {
		replace bs_payloans_`wv' = 0 if `v' == 2
	}

	replace bs_payloans_`wv' = . if ~bs_borrowed_`wv'
	
	gen bs_rmsend_`wv' = 0
	la variable bs_rmsend_0 "Remittances sent"
	gen bs_rmget_`wv' = 0
	la variable bs_rmget_0 "Remittances received"

	gen bs_savings_`wv' = 0
	la variable bs_savings_`wv' "Amount currently saved"

	foreach v in `amt_`wv'' {
		replace bs_savings_`wv' = bs_savings_`wv' + `v' if `v' != . & `v' >= 0
	}

	xtile temp = bs_savings_`wv', n(2)
	gen bs_savingsupper_`wv' = .
	la variable bs_savingsupper_`wv' "Above median savings"
	replace bs_savingsupper_`wv' = temp - 1
	drop temp

	gen bs_groupsavings_`wv' = 0
	la variable bs_groupsavings_`wv' "Amount currently saved with group"

	foreach v in `gr_`wv'' {
		replace bs_groupsavings_`wv' = bs_groupsavings_`wv' + `v' if `v' != . & `v' >= 0
	}

	gen bs_securesave_`wv' = .
	la variable bs_securesave_`wv' "How secure do your savings make you feel?"
	gen bs_coverhealth_`wv' = .
	la variable bs_coverhealth_`wv' "Can savings cover health expenses?"

	if `wv' == 1 {
		replace bs_loansamount_`wv' = . if attr
		replace bs_payloans_`wv' = . if attr
		replace bs_rmsend_`wv' = . if attr
		replace bs_rmget_`wv' = . if attr 
		replace bs_savings_`wv' = . if attr
		replace bs_groupsavings_`wv' = . if attr
	}
}

forval n = 1/10 {
	replace bs_rmsend_0 = bs_rmsend_0 + v60_`n'_0 if v59_`n'_0 == 1
	replace bs_rmget_0 = bs_rmget_0 + v60_`n'_0 if v59_`n'_0 == 2
}

forval n = 291(3)363 {
	loc m = `n' - 1
	replace bs_rmsend_1 = bs_rmsend_1 + v`n'_1 if v`m'_1 == 1
	replace bs_rmget_1 = bs_rmget_1 + v`n'_1 if v`m'_1 == 2
}

replace bs_securesave_0 = v77_0 if v77_0 > 0 & v77_0 < 6
replace bs_securesave_1 = v475_1 if v475_1 > 0 & v475_1 < 6

replace bs_coverhealth_0 = 2 - v78_0 if v78_0 > 0
replace bs_coverhealth_0 = . if bs_coverhealth_0 < 0
replace bs_coverhealth_1 = 2 - v476_1 if v476_1 > 0
replace bs_coverhealth_1 = . if bs_coverhealth_1 < 0

************
** Health ** hospitalization vs treatment costs, respondent vs household costs, hospitalization contributions
************
rename sickdays_1 sickdays_1_1
rename sickinjured_1 sickinjured1_1
rename affordtreatment_1 affordtreatment_1_1
rename ailmentworkrelated_1_0 ailmentworkrelated_0
rename healthconsult_1_0 healthconsult_0 
rename v116_0 med_hospcontribution_0
rename v571_1 med_hospcontribution_1
rename v115_0 med_hospitalization_0
rename v570_1 med_hospitalization_1
rename treatmentcost_1 treatmentcost1_1
rename v30_1_0 med_nightshospitalized_0
rename v33_1_0 med_shouldhospitalized_0 
rename v30_1 med_nightshospitalized_1
rename v33_1 med_shouldhospitalized_1

forval n = 1/15 {
	rename sickinjured`n'_1 sickinjured_`n'_1
}

loc hsick0 "sickinjured_1_0 sickinjured_2_0 sickinjured_3_0 sickinjured_4_0 sickinjured_5_0 sickinjured_6_0 sickinjured_7_0 sickinjured_8_0 sickinjured_9_0 sickinjured_10_0 sickinjured_11_0 sickinjured_12_0 sickinjured_13_0 sickinjured_14_0 sickinjured_15_0"
loc hsick1 "sickinjured_1_1 sickinjured_2_1 sickinjured_3_1 sickinjured_4_1 sickinjured_5_1 sickinjured_6_1 sickinjured_7_1 sickinjured_8_1 sickinjured_9_1 sickinjured_10_1 sickinjured_11_1 sickinjured_12_1 sickinjured_13_1 sickinjured_14_1 sickinjured_15_1"
loc age0 "v2_1_0 v2_2_0 v2_3_0 v2_4_0 v2_5_0 v2_6_0 v2_7_0 v2_8_0 v2_9_0 v2_10_0 v2_11_0 v2_12_0 v2_13_0 v2_14_0 v2_15_0"
loc age1 "v2_1 v10_1 v40_1 v59_1 v78_1 v97_1 v116_1 v135_1 v154_1 v173_1 v192_1 v211_1 v230_1 v249_1 v268_1"

foreach v of varlist `hsick0' `hsick1' ailmentworkrelated_* childcheckup_* healthconsult_* med_hospitalization_* affordtreatment_1_0 affordtreatment_1_1{
	replace `v' = . if `v' < 0	
	replace `v' = 2 - `v'
	la value `v' dummy
}

clonevar childmortality_0 = childmortality_1
foreach v of varlist v121_1_0 v121_2_0 v121_3_0 {
	replace childmortality_0 = childmortality_0 + 1 if `v' == 1 | `v' == 2
}

foreach v of varlist childvaccination* {
	replace `v' = . if `v' < 0 
	replace `v' = 0 if `v' == 2 | `v' == 1 
	replace `v' = 1 if `v' == 3
	la variable `v' "All children under 14 are vaccinated"
	la value `v' dummy
}

foreach v of varlist med_hospcontribution_* treatmentcost* med_nightshospitalized_* v32_1_0 v32_1 v37_1 {
	replace `v' = . if `v' < 0
}

forval wv = 0/1 {
	gen med_hhsick_`wv' = 0
	la variable med_hhsick_`wv' "Household members sick in the past month"

	foreach v in `hsick`wv'' {
		replace med_hhsick_`wv' = med_hhsick_`wv' + `v' if `v' != .
	}

	gen med_propsick_`wv' = med_hhsick_`wv' / hhsize_0
	la variable med_propsick_`wv' "Proportion of household sick in past month"

	gen children_`wv' = 0
	la variable children_`wv' "Number of children under 15 in household"
	gen med_childsick_`wv' = 0
	la variable med_childsick_`wv' "Sick/injured children in household"

	gen med_hhtreatmentcosts_`wv' = 0
	la variable med_hhtreatmentcosts_`wv' "Total household treatment costs past 4 weeks"

	if `wv' == 0 {
		forval n = 1/15 {
			replace children_`wv' = children_`wv' + 1 if v2_`n'_0 < 15
			replace med_childsick_`wv' = med_childsick_`wv' + 1 if v2_`n'_0 < 15 & sickinjured_`n'_0
			replace med_hhtreatmentcosts_`wv' = med_hhtreatmentcosts_`wv' + treatmentcost_`n'_0 if treatmentcost_`n'_0 != . 
		}
	}

	if `wv' == 1 {
		loc i 1
		foreach v in `age1' {
			replace children_`wv' = children_`wv' + 1 if `v' < 14
			replace med_childsick_`wv' = med_childsick_`wv' + 1 if `v' < 14 & sickinjured_`i'_1
			loc ++i
		}
		forval n = 1/15 {
			replace med_hhtreatmentcosts_`wv' = med_hhtreatmentcosts_`wv' + treatmentcost`n'_1 if treatmentcost`n'_1 != . 
		}
	}

	gen med_propchildsick_`wv' = med_childsick_`wv' / children_`wv'
	la variable med_propchildsick_`wv' "Proportion of children in household sick"
	gen med_propchildvac_`wv' = 0 / children_`wv'
	la variable med_propchildvac_`wv' "Proportion of children in household vaccinated"

	replace sickdays_1_`wv' = 0 if ~sickinjured_1_`wv'

	replace med_hospcontribution_`wv' = 0 if ~med_hospitalization_`wv'
	la variable med_hospcontribution_`wv' "Contribution to medical expenses in the past year"

	if `wv' == 1 {
		foreach v of varlist med_hhtreatmentcosts_`wv' med_hhsick_`wv' med_propsick_`wv' children_`wv' med_childsick_`wv' med_propchildsick_`wv' med_propchildvac_`wv' {
			replace `v' = . if attr
		}
	}

	la variable med_shouldhospitalized_`wv' "Nights should have been hospitalized but wasn't"
	ren sickinjured_1_`wv' med_sicklastmonth_`wv'
	ren sickdays_1_`wv' med_sickdays_`wv'
	ren ailmentworkrelated_`wv' med_workrelated_`wv'
	ren childcheckup_`wv' med_childcheckup_`wv'
	ren affordtreatment_1_`wv' med_affordtreatment_`wv'
	ren childmortality_`wv' med_childmortality_`wv'
	ren healthconsult_`wv' med_healthconsult_`wv'
	ren childvaccination_`wv' med_childvaccination_`wv'
}



**************************
** Labor and Occupation ** do we entrepreneur?, perceived risk stuff, risk by job AND product, productivity by returns, weighted indices
**************************
ren selfemployed1_1_0 selfemployed_0
ren v85_0 isshedleader_0
ren v518_1 isshedleader_1
ren v55_0 formaltraining_0
ren v56_0 informaltraining_0
ren v286_1 formaltraining_1
ren v287_1 informaltraining_1
ren v87_0 trustcoworkers_0
ren v520_1 trustcoworkers_1
ren primaryinc_0 inc_primarysource_0
ren primaryincomesource_1 inc_primarysource_1
ren secondaryinc_0 inc_secondarysource_0
ren secondaryincomesource_1 inc_secondarysource_1
ren product_1_0 product1_0
ren product_2_0 product2_0
ren product_1 product1_1
ren produceorsell_1_0 produceorsell1_0
ren produceorsell_2_0 produceorsell2_0
ren producesell_1 produceorsell1_1
ren producesell2_1 produceorsell2_1
ren v89_0 workplacesafety_0
ren v522_1 workplacesafety_1
ren v84_0 workplacesize_0
ren v517_1 workplacesize_1
ren hoursperday1_1_0 hoursperday1_0
ren hoursperday2_1_0 hoursperday2_0
ren hoursperday_1 hoursperday1_1
ren daysperweek1_1_0 daysperweek1_0
ren daysperweek2_1_0 daysperweek2_0
ren daysperweek_1 daysperweek1_1 
ren avgpieces_1_0 avgpieces_0
ren pieceslastwk_1_0 pieceslastwk_0

foreach v of varlist  willleavejka* willmovewithinjka* selfemployed_0 selfemployed_1 attendedschool_1_0 attendedschool_1 formaltraining_* informaltraining_* hasjob*{
	replace `v' = . if `v' < 0
	replace `v' = 2 - `v'
	la value `v' dummy
}

gen jobcount_0 = hasjob1_1_0 + hasjob2_1_0
la variable jobcount_0 "Number of jobs held by respondent"

gen jobcount_1 = hasjob_1 + hasjob2_1
la variable jobcount_1 "Number of jobs held by respondent"

gen inc_hhtotal_0 = 0
la variable inc_hhtotal_0 "Total weekly household income"
gen inc_hhtotal_1 = 0
la variable inc_hhtotal_1 "Total weekly household income"

forval j=1/15 { 
	forvalues i=1/2 {
		replace wklyinclastyr`i'_`j'_0 = 0 if wklyinclastyr`i'_`j'_0 == . | wklyinclastyr`i'_`j'_0 < 0
		replace wklyinclastwk`i'_`j'_0 = wklyinclastyr`i'_`j'_0 if  wklyinclastwk`i'_`j'_0 == . | wklyinclastyr`i'_`j'_0 < 0
		replace inc_hhtotal_0 = inc_hhtotal_0 + wklyinclastwk`i'_`j'_0
		}
	}

ren wklyinclastwk_1 wklyinclastwk1_1 
ren wklyinclastyr_1 wklyinclastyr1_1

forval n = 1/15 {
	replace wklyinclastyr`n'_1 = 0 if  wklyinclastyr`n'_1 == . | wklyinclastyr`n'_1 < 0
		replace wklyinclastwk`n'_1 = wklyinclastyr`n'_1 if  wklyinclastwk`n'_1 == . | wklyinclastyr`n'_1 < 0
		replace inc_hhtotal_1 = inc_hhtotal_1 + wklyinclastwk`n'_1
		replace inc_hhtotal_1 = . if attr
}

gen inc_wklylastwk_0 = wklyinclastwk1_1_0
replace inc_wklylastwk_0 = inc_wklylastwk_0 + wklyinclastwk2_1_0 if wklyinclastwk2_1_0 != . 
la variable inc_wklylastwk_0 "Weekly income last week from both jobs"

gen inc_wklylastyr_0 = wklyinclastyr1_1_0
replace inc_wklylastyr_0 = inc_wklylastyr_0 + wklyinclastyr2_1_0 if wklyinclastyr2_1_0 != .
la variable inc_wklylastyr_0 "Weekly income last year from both jobs"

gen inc_wklynextwk_0 = wklyincnxtwk1_1_0
replace inc_wklynextwk_0 = inc_wklynextwk_0 + wklyincnxtwk2_1_0 if wklyincnxtwk2_1_0 != .
la variable inc_wklynextwk_0 "Weekly income next week from both jobs"

gen inc_wklylastwk_1 = wklyinclastwk1_1
replace inc_wklylastwk_1 = inc_wklylastwk_1 + wklyinclastwk2_1 if wklyinclastwk2_1 != .
la variable inc_wklylastwk_1 "Weekly income last week from both jobs"

gen inc_wklylastyr_1 = wklyinclastyr1_1
replace inc_wklylastyr_1 = inc_wklylastyr_1 + wklyinclastyr2_1 if wklyinclastyr2_1 != .
la variable inc_wklylastyr_1 "Weekly income last year from both jobs"

gen inc_wklynextwk_1 = wklyincnxtwk_1
replace inc_wklynextwk_1 = inc_wklynextwk_1 + wklyincnxtwk2_1 if wklyincnxtwk2_1 != .
la variable inc_wklynextwk_1 "Weekly income next week from both jobs"

foreach v of varlist inc_hhtotal* inc_wkly* wklyinc* workplacesafety_* {
	replace `v' = . if `v' < 0
}

foreach v of varlist hoursperday*_* {
	replace `v' = . if `v' > 24 | `v' == 0.01
}

foreach v of varlist daysperweek*_* {
	replace `v' = . if `v' > 7 | `v' == 0.01
}

foreach v of varlist trustcoworkers_* avgpieces_0 pieceslastwk_0 avgpieces_2_0 pieceslastwk_2_0 avgpieces_1 pieceslastwk_1 avgpieces2_1 pieceslastwk2_1 {
	replace `v' = . if `v' < 1
}

clonevar workplacetemp = workplace_0
replace workplacetemp = workplace_1
drop workplace_1
ren workplacetemp workplace_1
replace workplace_1 = 60 if workplace_1 == 61

la define incgroup 0 "Low" 1 "Middle" 2 "High"

forval wv = 0/1 {

	replace isshedleader_`wv' = 3 if isshedleader_`wv' == 1
	replace isshedleader_`wv' = . if isshedleader_`wv' < 0
	replace isshedleader_`wv' = 3 - isshedleader_`wv'

	gen tothoursperday_`wv' = hoursperday1_`wv'
	replace tothoursperday_`wv' = tothoursperday_`wv' + hoursperday2_`wv' if hoursperday2_`wv' != .
	replace tothoursperday_`wv' = . if tothoursperday_`wv' > 24
	la variable tothoursperday_`wv' "Hours worked per day for all jobs"

	gen totdaysperweek_`wv' = daysperweek1_`wv'
	replace totdaysperweek_`wv' = totdaysperweek_`wv' + daysperweek2_`wv' if daysperweek2_`wv' != .
	replace totdaysperweek_`wv' = . if totdaysperweek_`wv' > 7
	la variable totdaysperweek_`wv' "Days worked per week for all jobs"

	gen tothoursperweek_`wv' = tothoursperday_`wv' * totdaysperweek_`wv'
	la variable tothoursperweek_`wv' "Hours worked per week for all jobs"

	pctile incpctile_`wv' = inc_wklylastwk_`wv', nq(3)
	mkmat incpctile_`wv', matrix(matinc_`wv') nomissing
	drop incpctile_`wv'

	gen inc_highgroup_`wv' = 0
		la variable inc_highgroup_`wv' "HH income group: > 66%-tile"
		replace inc_highgroup_`wv' = 1 if inc_wklylastwk_`wv' > matinc_`wv'[2,1]

	gen inc_midgroup_`wv' = 0
		la variable inc_midgroup_`wv' "HH income group: > 33%-tile & < 66%tile"
		replace inc_midgroup_`wv' = 1 if inc_wklylastwk_`wv' <= matinc_`wv'[2,1] & inc_wklylastwk_`wv' > matinc_`wv'[1,1]

	gen inc_lowgroup_`wv' = 0
		la variable inc_lowgroup_`wv' "HH income group: < 33%-tile"
		replace inc_lowgroup_`wv' = 1 if inc_wklylastwk_`wv' <= matinc_`wv'[1,1]

	gen inc_group_`wv' = .
		la variable inc_group_`wv' "Income group by weekly income"
		la values inc_group_`wv' incgroup
		replace inc_group_`wv' = 0 if inc_lowgroup_`wv' 
		replace inc_group_`wv' = 1 if inc_midgroup_`wv'
		replace inc_group_`wv' = 2 if inc_highgroup_`wv'

	gen shed_samplesize_`wv' = 0
	la variable shed_samplesize_`wv' "Number of workers in shed sampled"

	gen shed_estimatedsize_`wv' = 0
	la variable shed_estimatedsize_`wv' "Estimated number of workers in shed"

	gen shed_treatuct_`wv' = 0
	la variable shed_treatuct_`wv' "Number of workers in shed assigned UCT"

	gen shed_gotuct_`wv' = 0
	la variable shed_gotuct_`wv' "Number of workers in shed received UCT"

	gen shed_treatinsurance_`wv' = 0
	la variable shed_treatinsurance_`wv' "Number of workers in shed assigned insurance"

	gen shed_gotinsurance_`wv' = 0
	la variable shed_gotinsurance_`wv' "Number of workers in shed received insurance"

	gen shed_treated_`wv' = 0
	la variable shed_treated_`wv' "Number of workers in shed assigned to treatment"

	forval n = 1/60 {

		count if workplace_`wv' == `n'
		replace shed_samplesize_`wv' = r(N) if workplace_`wv' == `n'

		sum workplacesize_`wv' if workplace_`wv' == `n', d
		replace shed_estimatedsize_`wv' = r(p50) if workplace_`wv' == `n'
		replace shed_estimatedsize_`wv' = shed_samplesize_`wv' if shed_estimatedsize_`wv' < shed_samplesize_`wv'

		count if workplace_`wv' == `n' & uct
		replace shed_treatuct_`wv' = r(N) if workplace_`wv' == `n'

		count if workplace_`wv' == `n' & insured
		replace shed_treatinsurance_`wv' = r(N) if workplace_`wv' == `n'

		count if workplace_`wv' == `n' & got_uct
		replace shed_gotuct_`wv' = r(N) if workplace_`wv' == `n'

		count if workplace_`wv' == `n' & got_insured
		replace shed_gotinsurance_`wv' = r(N) if workplace_`wv' == `n'

		count if workplace_`wv' == `n' & (uct | insured)
		replace shed_treated_`wv' = r(N) if workplace_`wv' == `n'

	}

	gen shed_treatprop_`wv' = shed_treated_`wv' / shed_estimatedsize_`wv'
	la variable shed_treatprop_`wv' "Prop. shed treated"

	gen shed_uctprop_`wv' = shed_treatuct_`wv' / shed_estimatedsize_`wv'
	la variable shed_uctprop_`wv' "Prop. shed assigned UCT"

	gen shed_insprop_`wv' = shed_treatinsurance_`wv' / shed_estimatedsize_`wv'
	la variable shed_insprop_`wv' "Prop. shed assigned insurance"

	gen shed_gotuctprop_`wv' = shed_gotuct_`wv' / shed_estimatedsize_`wv'
	la variable shed_gotuctprop_`wv' "Prop. shed received UCT"

	gen shed_gotinsprop_`wv' = shed_gotinsurance_`wv' / shed_estimatedsize_`wv'
	la variable shed_gotinsprop_`wv' "Prop. shed received insurance"

	foreach v of varlist shed_treatprop_`wv' shed_uctprop_`wv' shed_insprop_`wv' shed_gotuctprop_`wv' shed_gotinsprop_`wv' {
		
		clonevar `v'_cent = `v'
		clonevar `v'_dummy = `v'
		
		sum `v', d

		replace `v'_cent = `v' - r(mean)
		replace `v'_dummy = 0 if `v' <= r(p50)
		replace `v'_dummy = 1 if `v' > r(p50)

	}


	gen selfreportedrisk_`wv' = 5 - workplacesafety_`wv'
	la variable selfreportedrisk_`wv' "Perceived risk level of own job"

	gen objectiverisk_`wv' = (product1_`wv' == 1)*5 + (product1_`wv' == 2)*5 + (product1_`wv' == 3)*3 + (product1_`wv' == 4)*5 + (product1_`wv' == 5)*3 + (product1_`wv' == 6)*5 + (product1_`wv' == 7)*3 + (product1_`wv' == 8)*5 + (product1_`wv' == 9)*3 + (product1_`wv' == 10)*3 + (product1_`wv' == 11)*5 + (product1_`wv' == 12)*3 + (product1_`wv' == 13)*3 + (product1_`wv' == 14)*3 + (product1_`wv' == 15)*3 + (product1_`wv' == 16)*3 + (product1_`wv' == 17)*3 + (product1_`wv' == 18)*2 + (product1_`wv' == 19)*2 + (product1_`wv' == 20)*5 + (product1_`wv' == 21)*4 + (product1_`wv' == 22)*3
	la variable objectiverisk_`wv' "Perceived risk of own job from focus groups"
	replace objectiverisk_`wv' = . if product1_`wv' > 22 | product1_`wv' == .

	egen jobriskindex_`wv' = weightave(selfreportedrisk_`wv' objectiverisk_`wv'), normby(control)
	la variable jobriskindex_`wv' "Weighted index of job risk"

	egen labormobilityindex_`wv' = weightave(willmovewithinjka_`wv' willleavejka_`wv'), normby(control)
	la variable labormobilityindex_`wv' "Weighted index of labor mobility"

	//productivityindex is now under currency conversion

	if `wv' == 1 {
		foreach v of varlist objectiverisk_`wv' shed_samplesize_`wv' shed_treatuct_`wv' shed_treatinsurance_`wv' shed_treated_`wv' inc_*group_`wv' {
			replace `v' = . if attr
		}
	}
}

************************
** Insurance policies ** no obs for usage, weighted indices
************************
ren own_1 fireown_1
la variable fireown_1 "Ownership of fire insurance"
ren own3_1 inpatientown_1
la variable inpatientown_1 "Ownership of inpatient insurance"
ren own4_1 outpatientown_1
la variable outpatientown_1 "Ownership of outpatient insurance"
ren own5_1 lifeown_1
la variable lifeown_1 "Ownership of life insurance"
ren own6_1 accidentown_1
la variable accidentown_1 "Ownership of accident insurance"

ren v111_critillness_0 critwtp_0
ren v111_fire_0 firewtp_0
ren v111_inpatient_0 inpatientwtp_0
ren v111_life_0 lifewtp_0
ren v111_outcopay_0 outcopaywtp_0
ren v111_outnocopay_0 outnocopaywtp_0

ren v538_1 critwtp_1
la variable critwtp_1 "Willingness to pay for critical illness insurance"
ren v542_1 firewtp_1
la variable firewtp_1 "Willingness to pay for fire insurance"
ren v546_1 inpatientwtp_1
la variable inpatientwtp_1 "Willingness to pay for inpatient insurance"
ren v554_1 lifewtp_1
la variable lifewtp_1 "Willingness to pay for life insurance"
ren v558_1 outcopaywtp_1
la variable outcopaywtp_1 "Willingness to pay for outpatient insurance (copay)"
ren v562_1 outnocopaywtp_1
la variable outnocopaywtp_1 "Willingness to pay for outpatient insurance (no copay)"
/*
ren ins_inpatientusedlastmonth_0 v112_inpatient_0
ren ins_outcopayusedlastmonth_0 v112_outcopay_0
ren ins_outnocopayusedlastmonth_0 v112_outnocopay_0
ren ins_lifeusedlastmonth_0 v112_life_0
ren ins_critusedlastmonth_0 v112_critillness_0
ren ins_fireusedlastmonth_0 v112_fire_0

ren ins_inpatientusedtotal_0 v113_inpatient_0
ren ins_outcopayusedtotal_0 v113_outcopay_0
ren ins_outnocopayusedtotal_0 v113_outnocopay_0
ren ins_lifeusedtotal_0 v113_life_0
ren ins_critillnessusedtotal_0 v113_critillness_0
ren ins_fireusedtotal_0 v113_fire_0
*/
ren v109_0 ins_trust_0
ren v532_1 ins_trust_1

loc instype "fire inpatient outpatient life accident"

forval wv = 0/1 {
	foreach v of varlist *wtp_`wv' {
		rename `v' ins_`v'
	}
	foreach v in `instype' {
		rename `v'own_`wv' ins_`v'own_`wv'  
	}
}

foreach v of varlist ins_*own_* {
	replace `v' = . if `v' < 0
	replace `v' = 2 - `v'
	la value `v' dummy
}

foreach v of varlist ins_*wtp_* {
	replace `v' = . if `v' < 0
}

la define trust 1 "Not at all" 2 "Not much" 3 "A bit" 4 "Very much"
foreach v of varlist ins_trust_* {
	replace `v' = . if `v' < 0
	la values `v' trust
}

loc instype "fire inpatient outpatient life accident"

forval wv = 0/1 {
	gen ins_count_`wv' = 0
	la variable ins_count_`wv' "No. of insurance policies owned"
	foreach v in `instype' {
		replace ins_count_`wv' = ins_count_`wv' + ins_`v'own_`wv'
	}
	egen ins_ownindex_`wv' = weightave(ins_*own_`wv'), normby(control)
	la variable ins_ownindex_`wv' "Weighted index of insurance ownership"
	egen ins_wtpindex_`wv' = weightave(ins_*wtp_`wv'), normby(control)
	la variable ins_wtpindex_`wv' "Weighted index of insurance willingness to pay"
}

************************
** CIC Microinsurance **
************************
gen cic_daystoenroll = cic_joindate1 - date_0
la variable cic_daystoenroll "Days from baseline to CIC enrollment"

replace insurance2014_1 = 2 - insurance2014_1
la value insurance2014_1 dummy

la define insreason 1 "Too expensive" 2 "Not useful" 3 "No trust in insurance companies" 4 "I already have a policy" 5 "Other"
la value insurance2014reason_1 insreason

gen cic_numberofclaims = 0
la variable cic_numberofclaims "Total claims made during study period"

gen cic_selfclaims = 0
la variable cic_selfclaims "Number of claims made for respondent"

gen cic_otherclaims = 0
la variable cic_otherclaims "Number of claims made for other household members"

gen cic_outpatientclaims = 0
la variable cic_outpatientclaims "Number of outpatient claims"

gen cic_inpatientclaims = 0
la variable cic_inpatientclaims "Number of inpatient claims"

gen cic_maternityclaims = 0
la variable cic_maternityclaims "Number of maternity claims"

gen cic_totclaimsincurred = 0
la variable cic_totclaimsincurred "Total value of claims incurred by CIC"

gen cic_totclaimspaid = 0
la variable cic_totclaimspaid "Total value of claims CIC paid"

foreach v of varlist cic_daystoenroll cic_numberofclaims cic_selfclaims cic_otherclaims cic_outpatientclaims cic_inpatientclaims cic_maternityclaims cic_totclaimsincurred cic_totclaimspaid {
	replace `v' = . if ~got_insured
}

gen cic_fullname1 = cic_lastname1 + " " + cic_othernames1

la define benefit 0 "Outpatient" 1 "Inpatient" 2 "Maternity"
la define claimant 0 "Self" 1 "Spouse" 2 "Child" 3 "Other"

forval n = 1/42 {
	gen cic_benefit_type`n' = .
	replace cic_benefit_type`n' = 0 if cic_claim_benefit`n' == "OUTPATIENT INSURED COVER"
	replace cic_benefit_type`n' = 1 if cic_claim_benefit`n' == "HOSPITALISATION COVER"
	replace cic_benefit_type`n' = 2 if cic_claim_benefit`n' == "MATERNITY COVER"

	replace cic_numberofclaims = cic_numberofclaims + 1 if cic_claim_month`n' != .
	replace cic_totclaimsincurred = cic_totclaimsincurred + cic_claims_incurred`n' if cic_claims_incurred`n' != .
	replace cic_totclaimspaid = cic_totclaimspaid + cic_claims_paid`n' if cic_claims_paid`n' != .
	replace cic_outpatientclaims = cic_outpatientclaims + 1 if cic_claim_month`n' != . & cic_benefit_type`n' == 0
	replace cic_inpatientclaims = cic_inpatientclaims + 1 if cic_claim_month`n' != . & cic_benefit_type`n' == 1
	replace cic_maternityclaims = cic_maternityclaims + 1 if cic_claim_month`n' != . & cic_benefit_type`n' == 2
	replace cic_selfclaims = cic_selfclaims + 1 if cic_claim_month`n' != . & cic_claimant_name`n' == cic_fullname1
	replace cic_otherclaims = cic_otherclaims + 1 if cic_claim_month`n' != . & cic_claimant_name`n' != cic_fullname1
}

gen cic_madeclaim = 0
replace cic_madeclaim = 1 if cic_numberofclaims > 0 & insured
la variable cic_madeclaim "Made a claim"
la value cic_madeclaim dummy

gen cic_madeoutclaim = 0
replace cic_madeoutclaim = 1 if cic_outpatientclaims > 0 & insured
la variable cic_madeoutclaim "Made at least one outpatient claim during study period"
la value cic_madeoutclaim dummy

gen cic_madeinclaim = 0
replace cic_madeinclaim = 1 if cic_inpatientclaims > 0 & insured
la variable cic_madeinclaim "Made at least one inpatient claim during study period"
la value cic_madeinclaim dummy

mat claimsinshed = J(60, 1, 1)
gen shed_insclaims = .
la variable shed_insclaims "Total CIC claims made in by shed workers"
gen shed_claimsprop = .
la variable shed_claimsprop "Avg. shed claims"

forval n = 1/60 {
	sum cic_numberofclaims if workplace_0 == `n'
	replace shed_insclaims = r(N) if workplace_1 == `n'
	replace shed_claimsprop = shed_insclaims / shed_estimatedsize_1
}

clonevar shed_claimsprop_cent = shed_claimsprop
gen shed_claimsprop_dummy = .

sum shed_claimsprop, d
replace shed_claimsprop_cent = shed_claimsprop_cent - r(mean)
replace shed_claimsprop_dummy = 0 if shed_claimsprop <= r(p50)
replace shed_claimsprop_dummy = 1 if shed_claimsprop > r(p50)

gen cic_usage = 0
la variable cic_usage "Usage of CIC Microinsurance"
la define usage 0 "Uninsured" 1 "Assigned" 2 "Enrolled" 3 "Made claims"
la value cic_usage usage
replace cic_usage = 0 if ~insured
replace cic_usage = 1 if insured
replace cic_usage = 2 if got_insured
replace cic_usage = 3 if cic_madeclaim

*******************************
** KSH to USD PPP Conversion **
*******************************
if $USDconvertflag {
	foreach mvar of varlist as_*value_* cons_*amount_* cons_*exp_* bs_loansamount_* bs_rmsend_* bs_rmget_* bs_savings_* bs_groupsavings_* med_hospcontribution_* med_hhtreatmentcosts_* inc_hhtotal_* inc_wkly* *wtp_* cic_totclaimsincurred cic_totclaimspaid {
		replace `mvar' = `mvar' * $ppprate
	}	
}

foreach mvar of varlist med_hospcontribution_* med_hhtreatmentcosts_* inc_hhtotal_* inc_wkly* {
	clonevar ln`mvar' = `mvar'
	replace ln`mvar' = log(ln`mvar')
}

forval wv = 0/1 {
	egen productivityindex_`wv' = weightave(lninc_*_`wv' tothoursperday_`wv' totdaysperweek_`wv' avgpieces_`wv' pieceslastwk_`wv'), normby(control)
	la variable productivityindex_`wv' "Weighted index of labor productivity"	
}

******************************
** Self-Reported Well Being **
******************************
//Rotter LOC: high = bad 
//CESD higher = bad

ren v184_0 psy_WVS1score_0
ren v185_0 psy_WVS2score_0
ren v186_0 psy_WVS3score_0
ren v187_0 psy_WVS4score_0

ren v584_1 psy_WVS1score_1
ren v585_1 psy_WVS2score_1
ren v586_1 psy_WVS3score_1
ren v587_1 psy_WVS4score_1

loc exper0 "v93experienced_0 v94experienced_0 poorspousalrelationsexp_0 v95experienced_0 v96experienced_0 v97experienced_0 toomuchworkexperienced_0 v98experienced_0 v99experienced_0 v100experienced_0 v101experienced_0 slowbusinessexperienced_0 unemploymentexperienced_0 v102experienced_0 v103experienced_0 v104experienced_0 v105experienced_0 v106experienced_0 v107experienced_0 v108experienced_0"

loc worry0 "v93worry_0 v94worry_0 poorspousalrelationsworry_0 v95worry_0 v96worry_0 v97worry_0  toomuchworkworry_0 v98worry_0 v99worry_0 v100worry_0 v101worry_0 slowbusinessworry_0 unemploymentworry_0 v102worry_0 v103worry_0 v104worry_0 v105worry_0 v106worry_0 v107worry_0 v108worry_0"

loc exper1 "experienced_1 experienced2_1 experienced3_1 experienced4_1 experienced5_1 experienced6_1 experienced7_1 experienced8_1 experienced9_1 experienced10_1 experienced11_1 experienced12_1 experienced13_1 experienced14_1 experienced15_1 experienced16_1 experienced17_1 experienced18_1 experienced19_1 experienced20_1 experienced21_1 experienced22_1 experienced23_1"

loc worry1 "howworried_1 howworried2_1 howworried3_1 howworried4_1 howworried5_1 howworried6_1 howworried7_1 howworried8_1 howworried9_1 howworried10_1 howworried11_1 howworried12_1 howworried13_1 howworried14_1 howworried15_1 howworried16_1 howworried17_1 howworried18_1 howworried19_1 howworried20_1 howworried21_1 howworried22_1 howworried23_1 v107_prompt_1 v108_prompt_1"

forval wv = 0/1 {

	foreach v of varlist `exper`wv'' {
		replace `v' = 2 - `v'
		la value `v' dummy
	}

	gen psy_experienced_`wv' = 0
	la variable psy_experienced_`wv' "No. of accidents/disasters experienced"
	foreach v in `exper`wv'' {
		replace psy_experienced_`wv' = psy_experienced_`wv' + 1 if `v'
	}

	gen psy_worried_`wv' = 0
	la variable psy_worried_`wv' "No. of accidents/disasters worried about"
	foreach v in `worry`wv'' {
		replace psy_worried_`wv' = psy_worried_`wv' + 1 if `v' > 1
	}

	ren rotterscore_`wv' psy_rotterscore_`wv'
	ren cesdscore_`wv' psy_cesdscore_`wv'

	gen psy_invrotterscore_`wv' = 21 - psy_rotterscore_`wv'
	gen psy_invcesdscore_`wv' = 60 - psy_cesdscore_`wv'

	if (`wv' == 1) {
		replace psy_experienced_`wv' = . if attr
		replace psy_worried_`wv' = . if attr
	}

}

ren v93worry_0 psy_healthworry_0
la variable psy_healthworry_0 "How worried are you about family's health?"
ren v96worry_0 psy_accidentworry_0
la variable psy_accidentworry_0 "How worried are you about accidents/disasters?"
ren v101worry_0 psy_medicineworry_0
la variable psy_medicineworry_0 "How worried are you about affording medication?"
ren v105worry_0 psy_deathworry_0
la variable psy_deathworry_0 "How worried are you about a member of your family dying?"

ren howworried_1 psy_healthworry_1
la variable psy_healthworry_1 "How worried are you about family's health?"
ren howworried4_1 psy_accidentworry_1
la variable psy_accidentworry_1 "How worried are you about accidents/disasters?"
ren howworried9_1 psy_medicineworry_1
la variable psy_medicineworry_1 "How worried are you about affording medication?"
ren howworried13_1 psy_deathworry_1
la variable psy_deathworry_1 "How worried are you about a member of your family dying?"

************
** PSS-14 **
************
//high = bad

loc pss_a "v178_1 v178_2 v178_3 v178_8 v178_11 v178_14"
loc pss_b "v178_4 v178_5 v178_6 v178_7 v178_9 v178_10 v178_12 v178_13"
ren v178_one_1 v178_1_1

forval wv = 0/1 {

	gen psy_pssscore_`wv' = 0
	la variable psy_pssscore_`wv' "Perceived Stress Scale"
	foreach x in `pss_a' {
		replace psy_pssscore_`wv' = psy_pssscore_`wv' + `x'_`wv'
	}

	foreach y in `pss_b' {
		replace psy_pssscore_`wv' = psy_pssscore_`wv' + (6 -`y'_`wv')
	}

	gen psy_invpssscore_`wv' = 57 - psy_pssscore_`wv'

}

*******************
** Scheier LOT-R **
*******************
//high = good

loc schA "v180_1 v180_3 v180_6"
loc schB "v180_2 v180_4 v180_5"
ren v180_one_1 v180_1_1 

forval wv = 0/1 {
	gen psy_lotrscore_`wv' = 0
	la variable psy_lotrscore_`wv' "Life Orientation Test"

	foreach x in `schA' {
		replace psy_lotrscore_`wv' = psy_lotrscore_`wv' + `x'_`wv'
	}

	foreach y in `schB' {
		replace psy_lotrscore_`wv' = psy_lotrscore_`wv' + (4 - `y'_`wv')
	}
}

***************************
** Rosenberg Self-Esteem **
***************************
//high = good

loc rosA "v181_1 v181_3 v181_4 v181_7 v181_10"
loc rosB "v181_2 v181_5 v181_6 v181_8 v181_9"
ren v181_one_1 v181_1_1

forval wv = 0/1 {

	gen psy_selfesteemscore_`wv' = 0
	la variable psy_selfesteemscore_`wv' "Rosenberg Self-Esteem"
	foreach x in `rosA' {
		replace psy_selfesteemscore_`wv' = psy_selfesteemscore_`wv' + (`x'_`wv' - 1)
	}

	foreach y in `rosB' {
		replace psy_selfesteemscore_`wv' = psy_selfesteemscore_`wv' + (4 - `y'_`wv')
	}

	egen psy_index_`wv' = weightave(psy_invpssscore_`wv' psy_lotrscore_`wv' psy_selfesteemscore_`wv' psy_invrotterscore_`wv' psy_invcesdscore_`wv' psy_WVS3score_`wv' psy_WVS4score_`wv'), normby(control)
	la variable psy_index_`wv' "Weighted index of subjective wellbeing"

	foreach v in $yswb {
		egen norm`v'_`wv' = weightave(`v'_`wv'), normby(control)
		clonevar `v'_z_`wv' = `v'_`wv'
		replace `v'_z_`wv' = norm`v'_`wv'
		drop norm`v'_`wv'
	}
}

*********************
** Cortisol levels **
*********************
ren didactivity_1 eattoday_1
ren didactivity2_1 smoketoday_1
ren didactivity3_1 drinkteatoday_1
ren didactivity4_1 alcoholtoday_1
ren didactivity5_1 physicalactivitytoday_1
ren didactivity6_1 medicationtoday_1
ren didactivity7_1 miraatoday_1
ren didactivity8_1 chewingtobaccotoday_1

ren activitytime_1 eattime_1
ren activitytime2_1 smoketime_1
ren activitytime3_1 drinkteatime_1
ren activitytime4_1 alcoholtime_1
ren activitytime5_1 physicalactivitytime_1
ren activitytime6_1 medicationtime_1
ren activitytime7_1	miraatime_1
ren activitytime8_1 chewingtobaccotime_1

loc controls "eat smoke drinktea alcohol physicalactivity medication miraa chewingtobacco waking"
loc fullcontrols0 "eattoday_0 smoketoday_0 drinkteatoday_0 alcoholtoday_0 physicalactivitytoday_0 medicationtoday_0 miraatoday_0 chewingtobaccotoday_0"
loc fullcontrols1 "eattoday_1 smoketoday_1 drinkteatoday_1 alcoholtoday_1 physicalactivitytoday_1 medicationtoday_1 miraatoday_1 chewingtobaccotoday_1"

forval wv = 0/1 {
	foreach v of varlist `fullcontrols`wv'' {
		replace `v' = 2 - `v'
		la value `v' dummy 
	}
	foreach act in `controls' {
		fillmisstime2 `act'time_`wv', replace
		clonevar `act'diff_`wv' = `act'time_`wv'
		replace `act'diff_`wv' = interviewend_`wv' - `act'time__full`wv'
		replace `act'diff_`wv' = . if `act'time_`wv' > interviewend_`wv'
		la variable `act'diff_`wv' "Time since last did activity"
	}
}

ren cortisol1_0 cort_raw1_0
ren cortisol2_0 cort_raw2_0
ren cortisol1_1 cort_raw1_1
ren cortisol2_1 cort_raw2_1

foreach s of varlist cort_raw* {
	replace `s' = . if `s' < 0
	gen ln`s' = log(`s')
}

forval wv = 0/1 {
	gen cort_full_`wv' = 1
	replace cort_full_`wv' = 0 if cort_raw1_`wv' == . | cort_raw2_`wv' == .
	la variable cort_full_`wv' "Both samples in round `wv'"
	la value cort_full_`wv' dummy

	egen cort_avg_`wv' = rmean(cort_raw1_`wv' cort_raw2_`wv')
	la variable cort_avg_`wv' "Average cortisol level"
	replace cort_avg_`wv' = . if ~cort_full_`wv'

	gen lncort_avg_`wv' = log(cort_avg_`wv')
	la variable lncort_avg_`wv' "Log average cortisol level"

	gen cort_avgtrim50_`wv' = cort_avg_`wv' if cort_avg_`wv' <= 50
	la variable cort_avgtrim50_`wv' "Average cortisol less 50"
	
	gen lncort_avgtrim50_`wv' = log(cort_avgtrim50_`wv')
	la variable lncort_avgtrim50_`wv' "Log average cortisol less 50"
	
	gen cort_avgtrim100_`wv' = cort_avg_`wv' if cort_avg_`wv' <= 100
	la variable cort_avgtrim100_`wv' "Average cortisol less 100"
	
	gen lncort_avgtrim100_`wv' = log(cort_avgtrim100_`wv')
	la variable lncort_avgtrim100_`wv' "Log average cortisol less 100"
	
	winsor cort_avg_`wv', generate(cort_avgwins_`wv') p(0.005)
	la variable cort_avgwins_`wv' "Average cortisol 99 pct. Winsorized"
	
	gen lncort_avgwins_`wv' = log(cort_avgwins_`wv')
	la variable lncort_avgwins_`wv' "Log average cortisol 99 pct. Winsorized"
	
	foreach c of varlist cort_raw*_`wv' lncort_raw*_`wv' cort_avg*`wv' lncort_avg*`wv' {
		reg `c' `fullcontrols`wv'' interviewend_`wv'
		predict `c'_resid, r
	}
}

replace cort_full_1 = . if attr

*****************
** Preferences **
*****************
ren donation_0 pref_donation_0
ren baselinedonation_1 pref_donation_1

forval i = 189/190 {
	forval j = 1/6 {
		ren v`i'`j'_1 v`i'_`j'_1
	}
}

forval i = 1/9 {
	ren v1940`i'_1 v194_`i'_1
}

forval i = 10/21 {
	ren v194`i'_1 v194_`i'_1
}

forval wv = 0/1 {

	forval i = 1/5 {
		loc next = 	`i' + 1
		
		gen soonswitch`i'to`next' = 0
		gen soonbadswitch`i'to`next' = 0
		replace soonswitch`i'to`next' = 1 if v189_`i'_`wv' == 2 & v189_`next'_`wv' == 1
		replace soonbadswitch`i'to`next' = 1 if v189_`i'_`wv' == 1 & v189_`next'_`wv' == 2
		
		gen lateswitch`i'to`next' = 0
		gen latebadswitch`i'to`next' = 0
		replace lateswitch`i'to`next' = 1 if v190_`i'_`wv' == 2 & v190_`next'_`wv' == 1
		replace latebadswitch`i'to`next' = 1 if v190_`i'_`wv' == 1 & v190_`next'_`wv' == 2
	}

	egen sumsoonswitch = rowtotal(soonswitch*to*)
	egen sumsoonbadswitch = rowtotal(soonbadswitch*to*)

	egen sumlateswitch = rowtotal(lateswitch*to*)
	egen sumlatebadswitch = rowtotal(latebadswitch*to*)

	gen pref_indiffsoon_`wv' = .
	replace pref_indiffsoon_`wv' = 0 if sumsoonswitch == 0 & v189_1_`wv' == 1
	replace pref_indiffsoon_`wv' = 78 if sumsoonswitch == 0 & v189_6_`wv' == 2
	replace pref_indiffsoon_`wv' = 53 if soonswitch1to2 == 1
	replace pref_indiffsoon_`wv' = 58 if soonswitch2to3 == 1
	replace pref_indiffsoon_`wv' = 63 if soonswitch3to4 == 1
	replace pref_indiffsoon_`wv' = 68 if soonswitch4to5 == 1
	replace pref_indiffsoon_`wv' = 73 if soonswitch5to6 == 1
	replace pref_indiffsoon_`wv' = . if sumsoonbadswitch > 0

	gen pref_indifflate_`wv' = .
	replace pref_indifflate_`wv' = 0 if sumlateswitch == 0 & v190_1_`wv' == 1
	replace pref_indifflate_`wv' = 78 if sumlateswitch == 0 & v190_6_`wv' == 2
	replace pref_indifflate_`wv' = 53 if lateswitch1to2 == 1
	replace pref_indifflate_`wv' = 58 if lateswitch2to3 == 1
	replace pref_indifflate_`wv' = 63 if lateswitch3to4 == 1
	replace pref_indifflate_`wv' = 68 if lateswitch4to5 == 1
	replace pref_indifflate_`wv' = 73 if lateswitch5to6 == 1
	replace pref_indifflate_`wv' = . if sumlatebadswitch > 0

	gen pref_impatiencesoon_`wv' = (2 - v189_1_`wv') + (2 - v189_2_`wv') + (2 - v189_3_`wv') + (2 - v189_4_`wv') + (2 - v189_5_`wv') + (2 - v189_6_`wv') 
	gen pref_impatiencelate_`wv' = (2 - v190_1_`wv') + (2 - v190_2_`wv') + (2 - v190_3_`wv') + (2 - v190_4_`wv') + (2 - v190_5_`wv') + (2 - v190_6_`wv')

	drop *soonswitch* *soonbadswitch* *lateswitch* *latebadswitch*

	forval i = 1/2 {
		if `i' == 1 {
			loc time "soon"
		}
		else {
			loc time "late"
		}

		gen pref_expdiscount`time'_`wv' = -ln(pref_indiff`time'_`wv'/75)/0.0833
		replace pref_expdiscount`time'_`wv' = 0 if pref_indiff`time'_`wv' == 0
		replace pref_expdiscount`time'_`wv' = 99 if pref_indiff`time'_`wv' == 78
		la variable pref_expdiscount`time'_`wv' "Exponential discount factor"

		gen pref_hypdiscount`time'_`wv' = (75/pref_indiff`time'_`wv' - 1)/0.0833
		replace pref_hypdiscount`time'_`wv' = 0 if pref_indiff`time'_`wv' == 0
		replace pref_hypdiscount`time'_`wv' = 99 if pref_indiff`time'_`wv' == 78
		la variable pref_hypdiscount`time'_`wv' "Hyperbolic discount factor"
	}

	gen indiffpoint = 0

	forval i = 1/20 {
		loc next = `i' + 1 
		gen riskswitch`i'to`next' = 0
		gen badriskswitch`i'to`next' = 0
		replace riskswitch`i'to`next' = 1 if v194_`i'_`wv' == 2 & v194_`next'_`wv' == 1
		replace indiffpoint = `i' if v194_`i'_`wv' == 2 & v194_`next'_`wv' == 1
		replace badriskswitch`i'to`next' = 1 if v194_`i'_`wv' == 1 & v194_`next'_`wv' == 2 
	}

	egen sumriskswitch = rowtotal(riskswitch*to*)
	egen sumbadriskswitch = rowtotal(badriskswitch*)

	gen pref_indiffrisk_`wv' = .
	replace pref_indiffrisk_`wv' = (indiffpoint * 5) + 48
	replace pref_indiffrisk_`wv' = 0 if v194_1_`wv' == 1
	replace pref_indiffrisk_`wv' = 999 if sumriskswitch == 0 & sumbadriskswitch == 0
	replace pref_indiffrisk_`wv' = . if sumbadriskswitch > 0
	
	drop *riskswitch* indiffpoint

	gen pref_CRRA_`wv' = 1 - ln(pref_indiffrisk_`wv')/ln(75)
	la variable pref_CRRA_`wv' "Relative risk aversion"

	ren donate_`wv' pref_donate_`wv'

	replace pref_donate_`wv' = 2 - pref_donate_`wv'
	replace pref_donation_`wv' = . if pref_donation_`wv' < 0 | pref_donate_`wv' == .
	replace pref_donation_`wv' = 0 if ~pref_donate_`wv'

	if (`wv' == 1) {
		foreach v of varlist pref_expdiscountsoon_`wv' pref_hypdiscountsoon_`wv' pref_expdiscountlate_`wv' pref_hypdiscountlate_`wv' pref_CRRA_`wv' {
			replace `v' = . if attr
		}
	}
}


