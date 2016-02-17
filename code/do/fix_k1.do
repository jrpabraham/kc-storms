insheet using k1.csv
keep  region v2 province v4 municipality v6 barangay  projectname estimatedtotalcostp2ndmibf kalahigrant communitylgucounterpartcommitmen grantfundsreleased totalutilized stmibfmibfpdpradate ndmibfmibfecdate startdatespi completiondate durationofspconstructioncalendar noofdirecthhbeneficiaries ofsps
keep if v4 == 0505 | v4 == 0619 | v4 == 0973 | v4 == 1603

rename region rnames
rename barangay bnames
rename province adm_name
rename municipality mnames

rename v2 region
rename v4 province
rename v6 mun

rename estimatedtotalcostp2ndmibf pr_cost
rename communitylgucounterpartcommitmen com_funds
rename grantfundsreleased gf_released
rename totalutilized gf_used
rename durationofspconstructioncalendar duration

gen start_date = date(startdatespi, "DMY")
gen end_date = date(completiondate, "DMY")
gen MIBF_PDPRA = date(stmibfmibfpdpradate, "DMY")
gen MIBF_MIBFEC = date(ndmibfmibfecdate, "DMY")

merge m:1 bnames using barangay_names.dta
keep if _merge == 3
drop _merge
gen has_sp = 1

gen mult_sp = 0
replace mult_sp = 1 if bnames == "Barangay 1" | bnames == "Beray" | bnames == "Codingle" | bnames == "Don Alejandro" | bnames == "Guadalupe" | bnames == "Guinotos" | bnames == "Legarda Uno" | bnames == "Mahayahay" | bnames == "Rawis" | bnames == "San Juan"

drop rnames region adm_name province mun

//manually drop multiple subprojects

