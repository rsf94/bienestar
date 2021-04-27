clear
set more off

* estilo de gráficas
net install scheme-burd.pkg
set scheme burd
graph set window fontface "Times New Roman"

* para combinar gráficas
net install grc1leg.pkg

log using proyecto_final.log, replace

global path "C:\Users\rsf94\Google Drive\MAESTRÍA ITAM\2do semestre\Bienestar y política social\Bienestar_equipo\trabajo_final"

global data "$path\data_raw"
global graphs "$path\graphs"
global tables "$path\tables"

* ==================================================================
* CARGAR DATOS
* ==================================================================
* Abro base de hogares y guardo en formato de Stata para el merge
import delimited "$data/ponde_Hogar_ENA_2016_pp.csv", clear
rename ïid_hogar id_hogar
save "$data/hogares.dta",replace

clear

* Importar bases de datos: individuos y hogares
import delimited "$data/ENCODAT 2016_2017.csv", clear
split id_pers, parse()
rename id_pers1 id_hogar
rename id_pers2 id_ind

* Merge entre base de individuos y hogares
merge m:1 id_hogar using "$data/hogares.dta"
replace id_ind = "1" if _merge==1
keep if _merge != 2
drop _merge
gen CVE_MUN=substr(desc_ent,1,2)+substr(desc_mun,1,3)

tempfile base
save `base'

* ==================================================================
* PEGAR MARGINACION Y VIOLENCIA
* ==================================================================

import dbase using "$data/Mapa_de_grado_de_marginacion_por_municipio_2015/IMM_2015/IMM_2015.dbf", clear
save "marginacion.dta", replace

use `base'
merge m:1 CVE_MUN using "marginacion.dta", nogen keep(1 3) keepusing(POB_TOT IM GM)
tempfile base2
save `base2'


import delimited "$data/IDM_NM_jun2020.csv", encoding(ISO-8859-1) clear
keep if año>=2015 & año<=2017
drop bienjurídicoafectado modalidad
keep if tipodedelito=="Homicidio" | tipodedelito=="Feminicidio" 
*
*ALGUN OTRO DELITO?
*

gen total_=enero+febrero+marzo+abril+mayo+junio+julio+agosto+septiembre+octubre+noviembre+diciembre 
collapse  (sum) total_ ,by(año  cvemunicipio subtipodedelito)
tostring cvemunicipio, replace
replace cvemunicipio="0"+cvemunicipio if strlen(cvemunicipio)==4
replace subtipodedelito=regexr(subtipodedelito," ","_")
reshape wide total_, i(año cvemunicipio) j(subtipodedelito) string
reshape wide total_Feminicidio total_Homicidio_culposo total_Homicidio_doloso, i(cvemunicipio) j(año)
rename cvemunicipio CVE_MUN
compress, nocoalesce
tempfile baseSESNSP
save `baseSESNSP'

use `base2'
merge m:1 CVE_MUN using `baseSESNSP', nogen keep(1 3)

* ==================================================================
* GENERAMOS VARIABLES DE INTERÉS
* ==================================================================
* definimos base como datos tipo encuesta
svyset code_upm [pweight=ponde_ss]

*marginacion
rename IM indice_marginacion
rename GM grado_marginacion

*violencia
gen tasa_feminicidios_1517= 100000*(total_Feminicidio2015+total_Feminicidio2016+total_Feminicidio2017)/(3*POB_TOT)
gen tasa_homicidioscul_1517= 100000*(total_Homicidio_doloso2015+total_Homicidio_doloso2016+total_Homicidio_doloso2017)/(3*POB_TOT)
gen tasa_homicidiosdol_1517= 100000*(total_Homicidio_culposo2015+total_Homicidio_culposo2016+total_Homicidio_culposo2017)/(3*POB_TOT)
replace tasa_homicidiosdol_1517= 100000*total_Homicidio_doloso2017/POB_TOT  if tasa_homicidiosdol_1517==.
replace tasa_homicidioscul_1517=100000*total_Homicidio_culposo2017/POB_TOT  if tasa_homicidioscul_1517==.
replace tasa_feminicidios_1517=100000*total_Feminicidio2017/POB_TOT if tasa_feminicidios_1517==.

* ------ Sociodemográficas
* ds2: sexo
gen mujer =1 if ds2 ==2
replace mujer =0 if ds2==1

* ds3: edad
rename ds3 edad

* ds6: estado civil
gen matrimonio = 1 if ds6 ==1
replace matrimonio = 0 if ds6>1

* ds5 habla lengua indígena
rename ds5 habla_indigena
replace habla_indigena = 0 if habla_indigena == 2

* ds5a usted se considera indígena
rename ds5a indigena
replace indigena = 0 if indigena == 2


* ds7: religion sí incluir
gen alguna_religion = 1 if ds7 ==1 | ds7 ==2 | ds7 ==3 | ds7 ==4 | ds7 ==5
replace alguna_religion = 0 if ds7==6

rename ds7 religion

* padres juntos

* jefe de hogar
rename h312a grado_jefe

label define name_grado 0 "Ninguno" 1 "Preescolar o Kinder" 2 "Primaria" 3 "Secundaria" 4 "Secundaria tecnica" 5 "Carrera tecnica" 6 "Normal basica" 7 "Preparatoria" 8 "Carrera tecnica prepa" 9 "Normal superior" 10 "Licenciatura" 11 "Maestria" 12 "Doctorado" 99 "No responde" 88 "No sabe"

label values grado_jefe name_grado

* h315: ingreso autoreportado
rename h315 ingreso

* 2.1 número de personas
rename h305 num_personas

* beneficiario de programa del gobierno
*	1. Apoyo monetario Prospera h317a
		gen prospera_mon =1 if h317a==1
		replace prospera_mon = 0 if h317a!=1
		
*	2. Apoyo becas Prospera h317b
		gen prospera_bec = 1 if h317b==1
		replace prospera_bec = 0 if h317b != 1

* faltan las preguntas asociadas a trabajo


* //////////// Dependiente ////////////

* ds8: actualmente estudia
tab ds8 [aw=ponde_ss]
gen estudia =1 if ds8==3
replace estudia=0 if ds8<3

tab estudia [aw=ponde_ss]

* ds9: 	¿Cuál fue el último grado que ha completado ?
* 		creamos proxy
gen años_estudio = 9 if ds9 == 1
replace años_estudio = 12 if ds9 == 2
replace años_estudio = 14 if ds9 == 3
replace años_estudio = 15 if ds9 == 4
replace años_estudio = 16 if ds9 == 5 
replace años_estudio = 18 if ds9 == 6
replace años_estudio = 20 if ds9 == 7
replace años_estudio = 23 if ds9 == 8
replace años_estudio = 26 if ds9 == 9

* edad_estudiar: 1 si la persona tiene menos de 20 años
gen edad_estudiar = 1 if edad <= 22
replace edad_estudiar = 0 if edad > 22



* diferencia edad_Estudiar - años de estudio
gen dif_edad_añosestudio = edad - años_estudio


* //////////// Independientes ////////////

* desempleo si lleva más de 46 días desempleado (ds15) (requisito para retirar  de tu AFORE)
gen desempleo = 1 if ds15 > 46 & ds10==2
replace desempleo = 0 if ds10==1

* tb02: fuma
gen fuma = 1 if tb02<=2
replace fuma = 0 if tb02>2
tab fuma [aw=ponde_ss]


* para reducir sesgo de simultaneidad
* Asignar edades por grado
* Edad - edad esperada > 2 --> los tiramos

* ed1: te han regalado mariguana
* ed5: te han regalado otras drogas
* generamos variable que indica si ha recibido drogas regaladas
gen regalo = 1 if ed1==1 | ed5==1
replace regalo = 0 if ed1==2 & ed5==2

* ed11: facilidad de acceso a drogas
gen facilidad = 1 if ed11 >=4
replace facilidad = 0 if ed11 <4

* pc1: platica de prevencion
gen prevencion = 1 if pc1==1
replace prevencion = 0 if pc1 >1

* pc3 lugar de pláticas de prevención
gen prevencion_escuela = 1 if pc3==1
replace prevencion_escuela = 0 if pc3!=1

* ----------------- Drogas médicas -----------------

* FALTA METER LAS DE 30 DÍAS
* dm1 : ¿Ha tomado, usado o probado...?
* dm3 : ¿Cómo ha usado? (sin receta, etc)
* dm4 : edad de primera vez
* dm5 : Cuántas veces en su vida ha usado?
* dm6 : Ha usado __ fuera de prescripción médica en los últimos 12 meses?
* dm8 : Ha consumido en últimos 30 días
	* a Opiáceos
	* b Tranquilizantes
	* c Sedantes y Barbitúricos
	* d Anfetaminas

* Variable que indica si la persona ha consumido alguna droga médica sin receta en los últimos 12 meses
gen consumo_medicas=0
replace consumo_medicas = 1 if dm6a == 1 | dm6b == 1 | dm6c == 1 | dm6d == 1


* 30 dias
gen consumo_medicas_30 = 0 
replace consumo_medicas_30 = 1 if dm8a <4


tab entidad consumo_medicas, row nofreq

	
* ----------------- Drogas ilegales -----------------

* di1 : ¿Ha tomado, usado, probado?
	* a Marihuana
	* b Cocaína
	* c Crack/piedra
	* d Alucinógenos
	* e Inhalables
	* f Heroína
	* g Anfetaminas: tachas, cristal, etc
	* h Ketamina (extásis líquido)
	* i Marihuana sintética
	
* Agrupemos a las drogas en 2: Marihuana e inhalables Y las demás que són "peores"

* Variable que indica si la persona ha consumido marihuana o derivados en los últimos 12 meses
gen consumo_marihuana = 0
replace consumo_marihuana = 1 if di6a==1
gen consumo_marihuana_30 = 0
replace consumo_marihuana_30 = 1 if di8a < 4


gen consumo_cocaina= 0
replace consumo_cocaina = 1 if di6b==1
gen consumo_cocaina_30 = 0
replace consumo_cocaina_30 = 1 if di8b < 4


gen consumo_menos_frecuentes =0 
replace consumo_menos_frecuentes = 1 if di6c==1 | di6d==1 | di6e==1 | di6f==1 | di6g==1 | di6h==1

gen consumo_menos_frecuentes_30 = 0 
replace consumo_menos_frecuentes_30 = 1 if di8c < 4 | di8d < 4  | di8e < 4  | di8f < 4 | di8g < 4  | di8h < 4 

										
										
* ----------------- Alcohol (AL) -----------------

gen alcoholismo = 1 if al8 <= 5
replace alcoholismo =0 if al8>5

gen homicidios_doloso_promedio = (total_Homicidio_doloso2015 + total_Homicidio_doloso2016 + total_Homicidio_doloso2017)/3


* ==================================================================
* FILTRADO DE BASE
* ==================================================================
* OJO: quitamos individuos que tienen más de 3 años de diferencia en la variable anterior

keep if dif_edad_añosestudio <4 & edad_estudiar==1

* ==================================================================
* ESTADISTICA DESCRIPTIVA
* ==================================================================

gen droga_12meses = 0 
replace droga_12meses = 1 if consumo_medicas == 1 
replace droga_12meses = 2 if consumo_marihuana == 1
replace droga_12meses = 3 if consumo_cocaina == 1
replace droga_12meses = 4 if consumo_menos_frecuentes == 1

gen droga_30dias = 0 
replace droga_30dias = 1 if consumo_medicas_30 == 1
replace droga_30dias = 2 if consumo_marihuana_30 == 1
replace droga_30dias = 3 if consumo_cocaina_30 == 1
replace droga_30dias = 4 if consumo_menos_frecuentes_30 == 1


label define name_drogas 1 "Médicas" 2 "Marihuana" 3 "Cocaína" 4 "Menos frecuentes" 
label values droga_12meses name_drogas
label values droga_30dias name_drogas

estpost tabstat estudia  mujer indigena religion  alguna_religion prospera_bec edad num_personas ingreso, statistics(mean) by(droga_12meses)
esttab . using "$tables\descriptive_12meses.tex", cells("estudia(fmt(%9.1f))  mujer indigena religion  alguna_religion prospera_bec edad num_personas ingreso")  replace 

* medicas
estpost tabstat estudia  mujer indigena religion  alguna_religion prospera_bec edad num_personas ingreso if consumo_medicas==1, statistics(mean)
esttab . using "$tables\descriptive_12meses_medicas.tex", cells("estudia(fmt(%9.1f))  mujer indigena religion  alguna_religion prospera_bec edad num_personas ingreso")  replace 

* marihuana
estpost tabstat estudia  mujer indigena religion  alguna_religion prospera_bec edad num_personas ingreso if consumo_marihuana==1, statistics(mean)
esttab . using "$tables\descriptive_12meses_marihuana.tex", cells("estudia(fmt(%9.1f))  mujer indigena religion  alguna_religion prospera_bec edad num_personas ingreso")  replace 

* cocaina
estpost tabstat estudia  mujer indigena religion  alguna_religion prospera_bec edad num_personas ingreso if consumo_cocaina==1, statistics(mean)
esttab . using "$tables\descriptive_12meses_cocaina.tex", cells("estudia(fmt(%9.1f))  mujer indigena religion  alguna_religion prospera_bec edad num_personas ingreso")  replace 

* menos frecuentes
estpost tabstat estudia  mujer indigena religion  alguna_religion prospera_bec edad num_personas ingreso if consumo_menos_frecuentes==1, statistics(mean)
esttab . using "$tables\descriptive_12meses_menos_frecuentes.tex", cells("estudia(fmt(%9.1f))  mujer indigena religion  alguna_religion prospera_bec edad num_personas ingreso")  replace 

* ninguna
estpost tabstat estudia  mujer indigena religion  alguna_religion prospera_bec edad num_personas ingreso if droga_12meses==0, statistics(mean)
esttab . using "$tables\descriptive_12meses_ninguna.tex", cells("estudia(fmt(%9.1f))  mujer indigena religion  alguna_religion prospera_bec edad num_personas ingreso")  replace 



estpost tabstat estudia  mujer indigena religion  alguna_religion prospera_bec edad num_personas ingreso, s(mean) by(droga_30dias) 
esttab . using "$tables\descriptive_30dias.tex", cells("estudia  mujer indigena religion  alguna_religion prospera_bec edad num_personas ingreso") b(%12.2f) replace 

* Estudia Y está en edad de estudiar
tab estudia [iweight=ponde_ss]

* Histograma edad
 hist edad, bin(10)

* Porcentaje de mujeres y hombres que estudian
 * base balanceada por geénero: SI 
tab  estudia mujer [iweight=ponde_ss], row nofreq

* dentro de gente casada
tab estudia matrimonio [iweight=ponde_ss], row nofreq


* //////////// Gráficas ////////////

graph bar [pweight = ponde_ss], over(edad) ytitle("Frecuencia relativa (%)") b1title("Edad") note("Elaboración propia con datos de la ENCODAT 2016")
graph export "$graphs/edades.pdf", replace
 
* ==================================================================
* MISSING VALUES
* ==================================================================
* Veamos comportamiento por región
* ver documento metodológico

tab entidad di1a, row nofreq
tab entidad di1b, row nofreq


* ==================================================================
* PROBANDO PROBIT
* ==================================================================
* Nos querdamos con población en edad de estudiar?

local indep consumo_marihuana consumo_cocaina
probit estudia `indep' if edad_estudiar==1
estimates store m1
 
local indep consumo_marihuana consumo_cocaina consumo_medicas
probit estudia `indep' if edad_estudiar==1
estimates store m2

local indep consumo_marihuana consumo_cocaina  consumo_menos_frecuentes
probit estudia `indep' if edad_estudiar==1
estimates store m3

local indep consumo_marihuana consumo_cocaina consumo_medicas consumo_menos_frecuentes
probit estudia `indep' if edad_estudiar==1
estimates store m4 

local indep consumo_marihuana consumo_cocaina   mujer 
probit estudia `indep' if edad_estudiar==1
estimates store m5   
 
local indep consumo_marihuana consumo_cocaina   mujer indice_marginacion
probit estudia `indep' if edad_estudiar==1
estimates store m6   
 
local indep consumo_marihuana consumo_cocaina   mujer indice_marginacion tasa_homicidiosdol_1517
probit estudia `indep' if edad_estudiar==1
estimates store m7 

local indep consumo_marihuana consumo_cocaina   mujer indice_marginacion homicidios_doloso_promedio 
probit estudia `indep' if edad_estudiar==1
estimates store m8 
 
esttab m*,nobaselevels label
 
/* menú de variables dependientes pa elegir
indep_m1 mujer edad matrimonio ingreso prospera_mon prospera_bec fuma regalo facilidad prevencion prevencion_escuela consumo_medicas consumo_marihuana consumo_cocaina consumo_menos_frecuentes alcoholismo mujer edad matrimonio ingreso prospera_mon prospera_bec fuma regalo facilidad prevencion prevencion_escuela consumo_medicas consumo_marihuana consumo_cocaina consumo_menos_frecuentes alcoholismo 
indice_marginacion grado_marginacion
total_Feminicidio2015
total_Homicidio_culposo2015 
total_Homicidio_doloso2015
total_Feminicidio2016
total_Homicidio_culposo2016 
total_Homicidio_doloso2016
total_Feminicidio2017
total_Homicidio_culposo2017 
total_Homicidio_doloso2017
tasa_feminicidios_1517
tasa_homicidioscul_1517
tasa_homicidiosdol_1517
*/ 


* ==================================================================
*GRAFICAS
* ==================================================================

label define name_sexo 0 "Hombre" 1 "Mujer"

label values mujer name_sexo

/*

graph pie, over(droga_12meses) plabel(_all percent, format("%2.1f")) graphregion(color(white)) ///
title("Drogas consumidas en los últimos 12 meses ") name(12m) ///
note("La categoría “menos frecuentes” es la compilación de aquellas drogas ilegales que por sí solas no son muy frecuentes.")

graph export 12m.pdf

graph pie, over(droga_30dias) plabel(_all percent, format("%2.1f")) graphregion(color(white)) ///
title("Drogas consumidas en los últimos 30 días") name(30d) ///
note("La categoría “menos frecuentes” es la compilación de aquel las drogas ilegales que por sí solas no son muy frecuentes.")

graph export 30d.pdf

graph pie, over(droga_30dias) plabel(_all percent, format("%2.1f")) graphregion(color(white)) ///
by(mujer, title("Drogas consumidas en los últimos 30 días") name(30d_sexo) ///
note("La categoría “menos frecuentes” es la compilación de aquel las drogas ilegales que por sí solas no son muy frecuentes."))

graph pie, over(droga_12meses) plabel(_all percent, format("%2.1f")) graphregion(color(white)) ///
by(mujer, title("Drogas consumidas en los últimos 12 meses") name(12m_sexo) ///
note("La categoría “menos frecuentes” es la compilación de aquel las drogas ilegales que por sí solas no son muy frecuentes."))

*/

*capture graph drop _30d
graph bar (mean) consumo_medicas_30 consumo_marihuana_30 consumo_cocaina_30 consumo_menos_frecuentes_30  if droga_30dias!=0, /// 
 graphregion(color(white)) note("El total excede 1 ya que algunas personas usaron más de un tipo de droga." "Menos frecuentes: crack, alucinógenos, inhalables, heroína, estimulantes y otros.") /// 
 blab(bar, format("%3.2f")) leg(lab(1 "Médicas")lab(2 "Marihuana")lab(3 "Cocaína")lab(4 "Menos frecuentes")) ///
title("Tipo de droga consumida por las personas que consumieron" "en los últimos 30 días") name(_30d, replace) ytitle("Proporción") bar(1, bcolor(blue)) bar(2, bcolor(green)) bar(3, bcolor(red)) bar(4, bcolor(orange))

*capture graph drop _12m
graph bar consumo_medicas consumo_marihuana consumo_cocaina consumo_menos_frecuentes  if droga_12meses!=0, ///
 graphregion(color(white)) note("El total excede 1 ya que algunas personas usaron más de un tipo de droga." "Menos frecuentes: crack, alucinógenos, inhalables, heroína, estimulantes y otros.") /// 
 blab(bar, format("%3.2f")) leg(lab(1 "Médicas")lab(2 "Marihuana")lab(3 "Cocaína")lab(4 "Menos frecuentes"))  ///
title("Tipo de droga consumida por las personas que consumieron" "en los últimos 12 meses") name(_12m, replace) ytitle("Proporción") bar(1, bcolor(blue)) bar(2, bcolor(green)) bar(3, bcolor(red)) bar(4, bcolor(orange))

*capture graph drop _30dsexo
graph bar consumo_medicas_30 consumo_marihuana_30 consumo_cocaina_30 consumo_menos_frecuentes_30  if droga_30dias!=0, ///
 graphregion(color(white))  /// 
blab(bar, format("%3.2f")) leg(lab(1 "Médicas")lab(2 "Marihuana")lab(3 "Cocaína")lab(4 "Menos frecuentes"))  ///
by(mujer,title("Tipo de droga consumida por las personas que consumieron" "en los últimos 30 días") note("El total excede 1 ya que algunas personas usaron más de un tipo de droga." "Menos frecuentes: crack, alucinógenos, inhalables, heroína, estimulantes y otros." "Elaboración propia")) name(_30dsexo, replace) ytitle("Proporción") bar(1, bcolor(blue)) bar(2, bcolor(green)) bar(3, bcolor(red)) bar(4, bcolor(orange))

*capture graph drop _12msexo
graph bar consumo_medicas consumo_marihuana consumo_cocaina consumo_menos_frecuentes  if droga_12meses!=0, ///
graphregion(color(white))  /// 
blab(bar, format("%3.2f")) leg(lab(1 "Médicas")lab(2 "Marihuana")lab(3 "Cocaína")lab(4 "Menos frecuentes"))  ///
by(mujer,title("Tipo de droga consumida por las personas que consumieron" "en los últimos 12 meses") note("El total excede 1 ya que algunas personas usaron más de un tipo de droga." "Menos frecuentes: crack, alucinógenos, inhalables, heroína, estimulantes y otros." "Elaboración propia")) name(_12msexo, replace) ytitle("Proporción") bar(1, bcolor(blue)) bar(2, bcolor(green)) bar(3, bcolor(red)) bar(4, bcolor(orange))



* Gráfica combinada 30 días vs 12 meses
graph bar (mean) consumo_medicas_30 consumo_marihuana_30 consumo_cocaina_30 consumo_menos_frecuentes_30  if droga_30dias!=0, /// 
 graphregion(color(white)) /// 
 blab(bar, format("%3.2f")) leg(lab(1 "Médicas")lab(2 "Marihuana")lab(3 "Cocaína")lab(4 "Menos frecuentes")) legend(size(small)) ///
title("Tipo de droga consumida por las personas" " que consumieron en los últimos 30 días", size(medium)) name(_30da, replace) ytitle("Proporción") bar(1, bcolor(blue)) bar(2, bcolor(green)) bar(3, bcolor(red)) bar(4, bcolor(orange))

graph bar consumo_medicas consumo_marihuana consumo_cocaina consumo_menos_frecuentes  if droga_12meses!=0, ///
 graphregion(color(white)) /// 
 blab(bar, format("%3.2f")) leg(lab(1 "Médicas")lab(2 "Marihuana")lab(3 "Cocaína")lab(4 "Menos frecuentes")) legend(size(small)) ///
title("Tipo de droga consumida por las personas" "que consumieron en los últimos 12 meses", size(medium)) name(_12ma, replace) ytitle("Proporción") bar(1, bcolor(blue)) bar(2, bcolor(green)) bar(3, bcolor(red)) bar(4, bcolor(orange)) yscale(r(0 1)) ylabel(0(0.2)1)

grc1leg _30da _12ma , legendfrom(_30da) note("El total excede 1 ya que algunas personas usaron más de un tipo de droga." "Menos frecuentes: crack, alucinógenos, inhalables, heroína, estimulantes y otros.")
graph export "$graphs/tipo_30d_12m.pdf", replace

* Gráfica combinada 30 días vs 12 meses ( POR sexo)
graph bar consumo_medicas_30 consumo_marihuana_30 consumo_cocaina_30 consumo_menos_frecuentes_30  if droga_30dias!=0, ///
 graphregion(color(white))  /// 
blab(bar, format("%3.2f")) leg(lab(1 "Médicas")lab(2 "Marihuana")lab(3 "Cocaína")lab(4 "Menos frecuentes"))  ///
by(mujer,title("Tipo de droga consumida por las personas que consumieron" "en los últimos 30 días")) name(_30dsexoa, replace) ytitle("Proporción") bar(1, bcolor(blue)) bar(2, bcolor(green)) bar(3, bcolor(red)) bar(4, bcolor(orange))
graph export "$graphs/tipo_30d_xsexo.pdf", replace

graph bar consumo_medicas consumo_marihuana consumo_cocaina consumo_menos_frecuentes  if droga_12meses!=0, ///
graphregion(color(white))  /// 
blab(bar, format("%3.2f")) leg(lab(1 "Médicas")lab(2 "Marihuana")lab(3 "Cocaína")lab(4 "Menos frecuentes"))  ///
by(mujer,title("Tipo de droga consumida por las personas que consumieron" "en los últimos 12 meses") note("El total excede 1 ya que algunas personas usaron más de un tipo de droga." "Menos frecuentes: crack, alucinógenos, inhalables, heroína, estimulantes y otros.")) name(_12msexoa, replace) ytitle("Proporción") bar(1, bcolor(blue)) bar(2, bcolor(green)) bar(3, bcolor(red)) bar(4, bcolor(orange)) yscale(r(0 1)) ylabel(0(0.2)1) 
graph export "$graphs/tipo_12m_xsexo.pdf", replace



close log
clear
 
