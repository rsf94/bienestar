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
merge m:1 folioviv using "$directorio/viviendas"


*rural o urbano
gen rural_urb = substr(folioviv,3,1)
gen rural = 1 if rural_urb == "6"
replace rural = 0 if rural_urb != "6"
drop rural_urb

*entidad federativa
gen entidad_federativa = substr(folioviv,1,2)

*municipio
gen municipio = substr(ubica_geo,3,3)

* Variables que nos interesan
keep folioviv foliohog clave tipo_gasto cantidad gasto


* Nos quedamos con bienes y servicios que queremos:
* E027 = Cines
* E028 = Teatros y conciertos
* E030 = Espectáculos deportivos
keep if clave =="E027" | clave =="E028" | clave == "E030"

* Guardar base final
save "$directorio/base_final"

