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
use "$data\pwt100"
desc
summarize *


* Hay 183 países, clave de 3 letras
tab country

* Cambiar nombres para posteriormente poder hacer merge por nombre de país (ya que difieren en el código XX vs YYY)
gen country2 = country
replace country = "Bolivia" if country2 == "Bolivia (Plurinational State of)"
replace country = "Cote d’Ivoire" if country2 == "Côte d'Ivoire"
replace country = "Curacao" if country2 == "Curaçao"
replace country = "Hong Kong" if country	2 == "China, Hong Kong SAR"
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
save "$data\penn_wt", replace
use "$data\penn_wt"


*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
* WORLD INEQUALITY DATABASE
*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
/* NOTA: es más facil hacer la consulta remota de las variables que queramos utilizar
1. Instalar: ssc install wid
2. Usar help file y ver cómo hacer consulta
3. Descargar y guardar data
4. Merge con World Penn
*/

help wid

* EJEMPLO: wid, indicators(anninc) areas(ME) age(999) NOTA: hay que cambiar dependiendo de la consulta que queramos

wid, indicators(mfiinc) age(999) areas(_all)

* Mergear con nombres de países (necesario para mergear con World Penn)
merge m:1 country using "$data\wdi_countries", keep(match)

drop country _merge pop
rename name country

* Ahora sí, mergear con World Penn y nos quedamos con países q sí tengan info
drop pop
merge m:1 year country using "$data\penn_wt"
drop if _merge==1 | _merge==2
drop _merge

desc

