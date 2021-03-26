clear
set more off

* Importar base previamente limpiada en R
import delimited "C:\Users\rsf94\Google Drive\MAESTRÍA ITAM\2do semestre\Bienestar y política social\Bienestar_equipo\trabajo_final\data_clean\base.csv"

* =================================
* LIMPIEZA DE DATOS
* =================================
drop entidadx
rename entidady entidad


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

* =================================
* RELACIONES BÁSICAS ENTRE VARIABLES
* =================================
