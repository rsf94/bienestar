* BASE DE DATOS PARA 9 DE FEBRERO DE 2020
set more off
clear

* directorio con bases de la ENIGH 2018
global directorio "C:\Users\rsf94\Google Drive\MAESTRÍA ITAM\2do semestre\Bienestar y política social\Bienestar_equipo\data"

* Cargo base gastoshogar
use "$directorio/gastoshogar"

desc
summarize


* Merge con base viviendas
merge m:1 folioviv using "$directorio/viviendas", nogenerate


*rural o urbano
gen rural_urb = substr(folioviv,3,1)
gen rural = 1 if rural_urb == "6"
replace rural = 0 if rural_urb != "6"
drop rural_urb


tempfile master
save `master'

*número de integrantes del hogar
use "$directorio/poblacion"
gen counter2 = 1
bysort folioviv foliohog: egen counter = count(foliohog)
keep folioviv foliohog counter


merge m:m folioviv foliohog using `master'



* Nos quedamos con bienes y servicios que queremos:
* A004 = Tortilla de maíz (de todo tipo y color)
* A008 = Tortilla de harina
* A012 = Pan blanco
* A015 = Pan para sándwich, hamburguesa, hotdog
* A224 = Cerveza
* A233 = Tequila
* 



/*Sumamos todos los gastos del mismo tipo para la base final, hay gastos que vienen más de una vez, con fecha. 
Primero hacemos que el gasto sea la variable gasto, o costo para los tipos de gasto que no monetarios para el consumo del hogar.
Luego agrupamos todas las otras categorías de gasto en "Otros" (hay un supuesto raro de sumar cantidad de cosas distintas, pero no
se me ocurre una forma "correcta" de hacerlo).
Los sumamos con collapse pot tipo de gasto.
*/

gen gastocosto=gasto if tipo_gasto=="G1" 
replace gastocosto=costo if (tipo_gasto=="G3" | tipo_gasto=="G4" | tipo_gasto=="G5" | tipo_gasto=="G6")
replace gastocosto=gasto_nm if tipo_gasto=="G7"
replace gastocosto=0 if gastocosto==. /*Si no, tira las observaciones con missing al colapsar*/
replace cantidad=0 if cantidad==. /*Si no, tira las observaciones con missing al colapsar*/

replace clave="Otros" if !inlist(clave,"A004","A008","A012","A015","A224","A233","Otros")

collapse (sum) gastocosto (sum) cantidad, by(folioviv foliohog clave factor upm est_dis counter rural ubica_geo) 

*generamos gasto total y proporciones del gasto

bysort folioviv foliohog: egen gastototal=total(gastocosto)
gen share_gasto=gastocosto/gastototal

* generamos precio de los bienes

gen precio = gastocosto/cantidad

*número de hogares por vivienda
destring(foliohog), replace
bysort folioviv: egen num_hogares=max(foliohog)

*entidad federativa
gen entidad_federativa = substr(folioviv,1,2)

*municipio
gen municipio = substr(ubica_geo,3,3)


*Arreglamos missiong values (no todos los hogares consumen todos los códigos)
*Imputamos precios para los hogares que no consumieron (promedios del municipio o del estado por clave de gasto)
reshape wide gastocosto cantidad precio share_gasto, i(folioviv foliohog) j(clave) string
reshape long gastocosto cantidad precio share_gasto, i(folioviv foliohog) j(clave) string
replace gastocosto=0 if gastocosto==.
replace cantidad=0 if cantidad==.
replace share_gasto=0 if share_gasto==.
bysort entidad_federativa municipio clave: egen preciomunicipio=mean(precio)
bysort entidad_federativa clave: egen precioestado=mean(precio)
replace precio=preciomunicipio if precio==.
replace precio=precioestado if precio==.
drop preciomunicipio precioestado
sort folioviv foliohog clave

*volvemos a reshapear para que sirva el comando quaids
reshape wide gastocosto cantidad precio share_gasto, i(folioviv foliohog) j(clave) string

* Guardar base final
save "$directorio/base_final", replace

* renombrar variables

rename share_gastoA004 share_tortillasmaiz
rename share_gastoA008 share_tortillasharina
rename share_gastoA012 share_panblanco
rename share_gastoA015 share_pansandwich
rename share_gastoA224 share_cerveza
rename share_gastoA233 share_tequila


label var share_tortillasmaiz "share tortillas maiz"
label var share_tortillasharina "share tortillas harina"
label var share_panblanco "share pan blanco"
label var share_pansandwich "share pan sándwich, hamburguesa, hotdog"
label var share_cerveza "share cerveza"
label var share_tequila "share tequila"

gen ln_gastotal = ln(gastototal)
* curvas de Engel ---------------------------------------------------------------------------------------------------------------------------

* relación lineal?
loc bienes share_tortillasmaiz share_tortillasharina share_panblanco share_pansandwich share_cerveza share_tequila
foreach var in share_tortillasmaiz share_tortillasharina share_panblanco share_pansandwich share_cerveza share_tequila share_gastoOtros {
local lbl: variable label `var'
twoway scatter  `var' ln_gastotal || lfitci `var' ln_gastotal  , ///
ytitle("`lbl'") xtitle("log(gasto)") ///
legend(off) ///
name("graph_`var'", replace)
}

graph combine graph_share_tortillasmaiz graph_share_tortillasharina graph_share_panblanco graph_share_pansandwich graph_share_cerveza graph_share_tequila graph_share_gastoOtros

* relación cuadrática?
loc bienes share_tortillasmaiz share_tortillasharina share_panblanco share_pansandwich share_cerveza share_tequila
foreach var in share_tortillasmaiz share_tortillasharina share_panblanco share_pansandwich share_cerveza share_tequila share_gastoOtros {
local lbl: variable label `var'
twoway lpoly `var' ln_gastotal  , ///
ytitle("`lbl'") xtitle("log(gasto)") ///
legend(off) ///
name("graph_q`var'", replace)
}

graph combine graph_qshare_tortillasmaiz graph_qshare_tortillasharina graph_qshare_panblanco graph_qshare_pansandwich graph_qshare_cerveza graph_qshare_tequila graph_qshare_gastoOtros


* tabla estadística descriptiva
estpost sum share_*, detail
estout using shares_descr.tex, cells("mean sd min p25 p50 p75 max") replace

* QUAIDS ---------------------------------------------------------------------------------------------------------------------------

quaids share_gastoA004 share_gastoA008 share_gastoA012 share_gastoA015 share_gastoA224 share_gastoA233 share_gastoOtros, anot(10) prices(precioA004 precioA008 precioA012 precioA015 precioA224 precioA233 precioOtros) expenditure(gastototal) demographics(counter rural) nolog



*Elasticidades

*Precio no compensada
estat uncompensated, atmeans
matrix up=r(uncompelas)
estat uncompensated if rural, atmeans
matrix uprural=r(uncompelas)
estat uncompensated if !rural, atmeans
matrix upurban=r(uncompelas)

esttab matrix(uprural) using "$directorio/elasticidades", tex replace
esttab matrix(upurban) using "$directorio/elasticidades", tex append
esttab matrix(up) using "$directorio/elasticidades", tex append



*Precio compensada

estat compensated, atmeans
matrix cp=r(compelas)
estat compensated if rural, atmeans
matrix cprural=r(compelas)
estat compensated if !rural, atmeans
matrix cpurban=r(compelas)

esttab matrix(cprural) using "$directorio/elasticidades", tex append
esttab matrix(cpurban) using "$directorio/elasticidades", tex append
esttab matrix(cp) using "$directorio/elasticidades", tex append

*Ingreso

estat expenditure, atmeans
matrix ex=r(expelas)
estat expenditure if rural, atmeans
matrix exrural=r(expelas)
estat expenditure if !rural, atmeans
matrix exurban=r(expelas)

esttab matrix(exrural) using "$directorio/elasticidades", tex append
esttab matrix(exurban) using "$directorio/elasticidades", tex append
esttab matrix(ex) using "$directorio/elasticidades", tex append

