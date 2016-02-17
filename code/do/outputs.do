// Comparing storm intensity by province
tw (connected maxs year if province == 1) (connected maxs year if province == 2) (connected maxs year if province == 3) (connected maxs year if province == 4), ytitle(Max Wind Speed) xtitle(Year) legend(order(1 "Albay" 2 "Capiz" 3 "Z. del Sur" 4 "A. del Sur"))
tw (connected maxs year if province == 1) (connected maxs year if province == 2) (connected maxs year if province == 3) (connected maxs year if province == 4) if year > 1999 , ytitle(Max Wind Speed) xtitle(Year) legend(order(1 "Albay" 2 "Capiz" 3 "Z. del Sur" 4 "A. del Sur"))
tw (connected maxs year if province == 1) (connected pddi year if province == 2) (connected pddi year if province == 3) (connected pddi year if province == 4), ytitle(Energy Dissipation) xtitle(Year) legend(order(1 "Albay" 2 "Capiz" 3 "Z. del Sur" 4 "A. del Sur"))
tw (connected maxs year if province == 1) (connected pddi year if province == 2) (connected pddi year if province == 3) (connected pddi year if province == 4) if year > 1999 , ytitle(Energy Dissipation) xtitle(Year) legend(order(1 "Albay" 2 "Capiz" 3 "Z. del Sur" 4 "A. del Sur"))

// Balanced study groups
replace control = 1 if treat == 0
graph bar treat control if year > 1999, over(year) legend(order(1 "Treated" 2 "Untreated")) 

// Lagged Effect
