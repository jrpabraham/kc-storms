gen subp_type = 0

foreach num of numlist 20/39 120/126 {
	replace subp_type = 1 if e29 == `num'
}

foreach num of numlist 40/58 {
	replace subp_type = 2 if e29 == `num'
}

foreach num of numlist 130/139 {
	replace subp_type = 3 if e29 == `num'
}

foreach num of numlist 100/113 {
	replace subp_type = 4 if e29 == `num'
}

foreach num of numlist 78/97 {
	replace subp_type = 5 if e29 == `num'
}

foreach num of numlist 70/77 {
	replace subp_type = 6 if e29 == `num'
}

foreach num of numlist 16 65 183 187 {
	replace subp_type = 7 if e29 == `num'
}

label define types 0 "Other" 1 "Infrastructure" 2 "Water Systems" 3 "Health" 4 "Education" 5 "Agriculture" 6 "Business" 7 "Recreation"
label values subp_type types
label variable subp_type "subproject categories"
