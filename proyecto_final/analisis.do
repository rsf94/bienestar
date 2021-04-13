clear
set more off

log using proyecto_final.log, replace

global data "C:\Users\rsf94\Google Drive\MAESTRÍA ITAM\2do semestre\Bienestar y política social\Bienestar_equipo\trabajo_final\data_raw"

* =================================
* CARGAR DATOS
* =================================
* Abro base de hogares y guardo en formato de Stata para el merge
import delimited "$data\ponde_Hogar_ENA_2016_pp.csv"
rename ïid_hogar id_hogar
save "$data\hogares.dta",replace

clear

* Importar bases de datos: individuos y hogares
import delimited "$data\ENCODAT 2016_2017.csv"
split id_pers, parse()
rename id_pers1 id_hogar
rename id_pers2 id_ind

* Merge entre base de individuos y hogares
merge m:1 id_hogar using "$data\hogares.dta"
replace id_ind = "1" if _merge==1
keep if _merge != 2

* =================================
* LIMPIEZA DE DATOS
* =================================


* =================================
* GENERAMOS VARIABLES DE INTERÉS
* =================================

* ------ Sociodemográficas
* ds2: sexo
gen mujer =1 if ds2 ==2
replace mujer =0 if ds2==1

* ds3: edad
rename ds3 edad

* ds6: estado civil
gen matrimonio = 1 if ds6 ==1
replace matrimonio = 0 if ds6>1

* ds7: religion

* h315: ingreso autoreportado
rename h315 ingreso

* beneficiario de programa del gobierno
*	1. Apoyo monetario Prospera h317a
		gen prospera_mon =1 if h317a==1
		replace prospera_mon = 0 if h317a!=1
*	2. Apoyo becas Prospera h317b
		gen prospera_bec = 1 if h317b==1
		replace prospera_bec = 0 if h317b != 1

* faltan las preguntas asociadas a trabajo


* ------ Tratamiento y respuesta

* ds8: actualmente estudia
tab ds8 [aw=ponde_ss]
gen estudia =1 if ds8==3
replace estudia=0 if ds8<3

tab estudia [aw=ponde_ss]

* edad_estudiar: 1 si la persona tiene menos de 2_ años
gen edad_estudiar = 1 if edad <= 20
replace edad_estudiar = 0 if edad > 20

* desempleo si lleva más de 46 días desempleado (ds15) (requisito para retirar  de tu AFORE)
gen desempleo = 1 if ds15 > 46 & ds10==2
replace desempleo = 0 if ds10==1

* tb02: fuma
gen fuma = 1 if tb02<=2
replace fuma = 0 if tb02>2
tab fuma [aw=ponde_ss]


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

* //////////// Drogas médicas

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
	tab1 dm1a dm1b dm1c dm1d
	tab1 dm3a dm3b dm3c dm3d

	tab dm6a dm3a
	
	

* //////////// Drogas ilegales

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
	
* dp5 : ¿Cuántos días en los últimos 12 meses fue totalmente incapaz de trabajar o de hacer sus actividades habituales, debido a su consumo de esta sustancia ?

* //////////// Dependencia a drogas 

* dd1 : 
* dd5
* dd6
* dd7

* //////////// Alcohol (AL)


* =================================
* RELACIONES ENTRE VARIABLES
* =================================

* Estudia Y está en edad de estudiar
tab edad_estudiar estudia [aw=ponde_ss], cell

* Desempleados si están en edad de estudiar
 tab desempleo edad_estudiar

 
 * Histograma edad
 hist edad, bin(10)
 
 close log
 clear