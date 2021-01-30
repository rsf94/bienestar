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

label variable sh_incp0p10 "income share p10"
label variable sh_incp0p50 "income share p50"
label variable sh_incp0p99 "income share p99"
label variable sh_incp0p20 "income share p20"
label variable sh_incp0p40 "income share p40"
label variable kuznets1 "20rich/20poor"
label variable kuznets2 "20rich/40poor"


save base_final, replace

*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
* REGRESIONES
*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
gen lnpib = ln(rgdpna)
label variable lnpib "PIB real a precios constantes de 2017 (M USD)"


* Definir datos tipo panel
xtset country year

xtabond 