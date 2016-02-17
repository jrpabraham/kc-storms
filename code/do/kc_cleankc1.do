** Title: KC_CleanKC1
** Author: Justin Abraham
** Desc: Prepares KALAHI project database for merge with household survey
** Input: KALAHI_CIDDS DATABASE.xlsx
** Output: KC1.dta

import excel using "$data_dir/raw/KALAHI_CIDDS DATABASE.xlsx", sheet("KC1") cellrange(A4:AH5474) first clear

ren ofBrgys project_brgys
la var project_brgys "No. of barangays in project" 

ren Province adm_name
ren Barangay bnames
ren ProjectName project_name
ren EstimatedTotalCostP2ndMIBF project_cost
ren KALAHIGRANT project_KCgrant
ren CommunityLGUCounterpartCommi project_LGUgrant
ren GrantFundsReleased project_releasedgrant
ren GrantFundsUtilized project_usedgrant
ren FinancialAccomplishmentGrant project_financial
ren PhysicalProgressasofJune20 project_physical
ren DurationofSPConstructionCale project_duration
ren NoofDirectHHBeneficiaries project_beneficiaries
ren ofSPs project_number
ren StartDateSPI project_startdate

gen project_complete = 0
replace project_complete = 1 if project_physical >= 1
la var project_complete "Project complete by June 2010"

replace CompletionDate = "30jun2009" if CompletionDate == "30jun3009"

gen project_enddate = date(CompletionDate, "DMY")
format project_enddate %td

gen project_MIBFdate = date(stMIBFMIBFPDPRADate, "DMY")
format project_MIBFdate %td

gen project_id = 1
la var project_id "Project ID"

destring(F), gen(project_bgynum)

keep bnames adm_name project*

// reshape wide project* i(project_bgynum) j(project_id)

save "$data_dir/cleandata/KC1.dta", replace

/*
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

