gen province = 0

replace province = 1 if adm_name == "Albay"
replace province = 2 if adm_name == "Capiz"
replace province = 3 if adm_name == "Zamboanga del Sur"
replace province = 4 if adm_name == "Agusan del Sur"

