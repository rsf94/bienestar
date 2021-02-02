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



/*Prueba 
quaids share_gastoA004 share_gastoA008 share_gastoA012 share_gastoA015 share_gastoA224 share_gastoA233 share_gastoOtros, anot(10) prices(precioA004 precioA008 precioA012 precioA015 precioA224 precioA233 precioOtros) expenditure(gastototal) demographics(counter rural)
*/

*Funciona, pero tarda muchísimo en correr
