/* TAREA 3: DESIGUALDAD
 Nombres:   Marcelo Torres
			Rafael Sandoval
			
*-----------------------------------------------------------------------------------------------------------------
*-----------------------------------------------------------------------------------------------------------------
*/
* Directorio
clear all
set more off


global data = "C:\Users\rsf94\Google Drive\MAESTRÍA ITAM\2do semestre\Bienestar y política social\Bienestar_equipo\Tareas\t3\data"



*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
* PENN WORLD TABLE 
*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
use "$data/pwt100"
desc
summarize *


* Hay 183 países, clave de 3 letras
tab country

* Cambiar nombres para posteriormente poder hacer merge por nombre de país (ya que difieren en el código XX vs YYY)
gen country2 = country
replace country = "Bolivia" if country2 == "Bolivia (Plurinational State of)"
replace country = "Cote d’Ivoire" if country2 == "Côte d'Ivoire"
replace country = "Curacao" if country2 == "Curaçao"
replace country = "Hong Kong" if country2 == "China, Hong Kong SAR"
replace country = "Iran" if country2 == "Iran (Islamic Republic of)"
replace country = "Korea" if country2 == "Republic of Korea"
replace country = "Lao PDR" if country2 == "Lao People's DR"
replace country = "Moldova" if country2 == "Republic of Moldova"
replace country = "Palestine" if country2 == "State of Palestine"
replace country = "USA" if country2 == "United States"
replace country = "Saint Vincent and the Grenadines" if country2 == "St. Vincent and the Grenadines"
replace country = "Venezuela" if country2 == "Venezuela (Bolivarian Republic of)"
replace country = "Virgin Islands, British" if country2 == "British Virgin Islands"

* Guardar y cargar base modificada
save "$data/penn_wt", replace
use "$data/penn_wt"


*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
* WORLD INEQUALITY DATABASE
*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
/* NOTA: es más facil hacer la consulta remota de las variables que queramos utilizar
1. Instalar: ssc install wid
2. Usar help file y ver cómo hacer consulta
3. Descargar y guardar data
4. Merge con World Penn
*/



* Consultamos la wid de las variables que queremos


wid, indicators(gptinc) age(992) areas(_all) pop(j) clear /*gini*/
drop variable age pop percentile
rename value gini
tempfile gini
save `gini'


wid, indicators(sptinc) age(992) areas(_all) pop(j) perc(p0p10 p10p20 p20p30 p30p40 p80p100 p90p100 p99p100 p0p50 p0p99) clear /*shares de ingreso por percentil*/
drop variable age pop
rename value sh_inc
replace percentile=subinstr(percentile,".","_",.)
reshape wide sh_inc, i(country year) j(percentile) s
gen sh_incp0p20=sh_incp0p10+sh_incp10p20 
gen sh_incp0p40=sh_incp0p10+sh_incp10p20+sh_incp20p30+sh_incp30p40 
gen kuznets1=sh_incp80p100/sh_incp0p20
gen kuznets2=sh_incp80p100/sh_incp0p40
gen top10vsbottom50=sh_incp90p100/sh_incp0p50
gen top1vsbottom50=sh_incp99p100/sh_incp0p50
gen top1vsbottom99=sh_incp99p100/sh_incp0p99

merge 1:1 country year using `gini', nogen




* Mergear con nombres de países (necesario para mergear con World Penn)
merge m:1 country using "$data/wdi_countries", keep(3) nogen
drop country
rename name country

* Ahora sí, mergear con World Penn y nos quedamos con países q sí tengan info
merge m:1 year country using "$data/penn_wt", nogen keep(3)
drop country2

order country year
sort country year
desc

encode country, gen(country2)
drop country
rename country2 country
order country, first

label variable sh_incp0p10 "income share bottom 10"
label variable sh_incp0p50 "income share bottom 50"
label variable sh_incp0p99 "income share pottom 99"
label variable sh_incp0p20 "income share bottom 0"
label variable sh_incp0p40 "income share bottom 40"
label variable kuznets1 "20rich/20poor"
label variable kuznets2 "20rich/40poor"


save base_final, replace

*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
* REGRESIONES
*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
gen lnpib = ln(rgdpna) 
label variable lnpib "log PIB real a precios constantes de 2017 (M USD)"
gen lnpib_a = ln(rgdpna/pop) 
label variable lnpib_a "log PIBpc real a precios constantes de 2017 (M USD)"
gen lnpib_b = ln(rgdpe) 
label variable lnpib_b "log PIB real a precios constantes de 2017 (M USD), expenditure side"
gen lnpib_c = ln(rgdpe/pop) 
label variable lnpib_c "log PIBpc real a precios constantes de 2017 (M USD), expenditure side"
gen gini_2=gini^2
gen kuznets1_2=kuznets1^2
gen kuznets2_2=kuznets2^2
gen top10vsbottom50_2=top10vsbottom50^2
gen top1vsbottom50_2=top1vsbottom50^2
gen top1vsbottom99_2=top1vsbottom99^2


* Definir datos tipo panel
xtset country year



***
*Pruebas


* Ia. Gini entre 1990-2019
xtabond d1.lnpib d1.gini if inrange(year,1990,2019)
eststo reg1

* Ia. Gini entre 2000-2019
xtabond d1.lnpib d1.gini if inrange(year,2000,2019)
eststo reg1

* Ib. Gini entre 2008-2019
xtabond d1.lnpib d1.gini if inrange(year,2008,2019)
eststo reg2

* IIa. Gini entre 2000-2019
xtabond d1.lnpib d1.kuznets1 if inrange(year,2000,2019)
eststo reg3

* IIb. 
xtabond d1.lnpib d1.top1vsbottom99 if inrange(year,2000,2019)
eststo reg4

xtabond d1.lnpib d1.gini d1.gini_2 if inrange(year,2000,2019)
eststo reg5


loc cont=1
foreach indvar of varlist lnpib lnpib_a lnpib_b lnpib_c  {
foreach depvar of varlist gini kuznets1 kuznets2 top10vsbottom50 top1vsbottom50 top1vsbottom99 {

di ""
di ""
di "**********************`indvar' `depvar' 1990"
xtabond d1.`indvar' d1.`depvar' d1.`depvar'_2 if inrange(year,2000,2019)
eststo r`cont'
loc cont=`cont'+1

}
}


esttab  r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 r12 r13 r14 r15 r16 r17 r18 r19 r20 r21 r22 r23 r24 r25 r26 r27 r28 r29 r30 r31  using "$data/regresiones.text", replace

* REGRESIONES FINALES
xtabond d1.lnpib d1.top1vsbottom50 d1.top1vsbottom50_2 if inrange(year,2000,2019), two
eststo rf1
estat abond
estat sargan

xtabond d1.lnpib d1.top1vsbottom99 d1.top1vsbottom99_2 if inrange(year,2000,2019), two
eststo rf2
estat abond
estat sargan

esttab rf1 rf2 using "$data/regresiones_finales.tex", replace se(4)




