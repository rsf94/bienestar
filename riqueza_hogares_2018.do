*Cálculo de la riqueza de los hogares 2010

*Vivienda 2010
use "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Vivienda 2010.dta" 
keep folioviv foliohog tenen renta estim factor
rename estim estim_pago
gen renta_roe= estim_pago
replace renta_roe=renta if renta_roe==.
gen renta_anual=renta_roe*12
gen tasa_int=0.049
gen inflacion=0.029
gen depreciacion=0.01
gen valor_viv=(renta_anual/(tasa_int- inflacion+depreciacion))
destring tenen, replace
gen propiedad=0
replace propiedad=1 if tenen==3
replace propiedad=1 if tenen==4
order folioviv foliohog renta estim_pago renta_roe renta_anual tasa_int inflacion depreciacion tenen propiedad valor_viv factor
label var renta_roe "Renta real o estimada"
label var renta_anual "Renta real o estimada anual"
label var tasa_int "Tasa de interÃ©s"
label var inflacion "Tasa de inflaciÃ³n"
label var depreciacion "Tasa de depreciaciÃ³n"
label var propiedad "Propiedad"
label var valor_viv "Valor de la vivienda"
label define tenen 1 "Rentada" 2 "Prestada" 3 "Propia pero la estÃ¡ pagando" 4 "Propia" 5 "Intestada o en litigio" 6 "Otra situaciÃ³n"
label values tenen tenen
label define propiedad 1 "Propia" 0 "No propia"
label values propiedad propiedad
gen val_viv_prop= valor_viv
label var val_viv_prop "Valor de la vivienda propia"
replace val_viv_prop=0 if propiedad==0
save "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Cálculo de riqueza\Vivienda refinada (riqueza física) 2010.dta"

*Ingresos
use "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Ingresos 2010.dta"
keep folioviv foliohog clave ing_tri
gen clave_ing=substr(clave,2,3)
destring clave_ing, replace
gen ing_anual= ing_tri*4
drop ing_tri
gen tasa_int=.
gen val_acervo=0
order folioviv foliohog clave_ing ing_anual tasa_int val_acervo clave  
destring foliohog, replace
label var clave_ing "Clave de ingreso"
label var ing_anual "Ingreso anual"
label var tasa_int "Tasa de interÃ©s"
label var val_acervo "Valor del acervo"
label define clave_ing 39 "Alquiler de tierras y terrenos, dentro y fuera del paÃ­s" 40 "Alquiler de casas, edificios, locales y otros inmuebles que estÃ¡n dentro del paÃ­s" 41 "Alquiler de casas, edificios, locales y otros inmuebles que estÃ¡n fuera del paÃ­s" 42 "Intereses provenientes de inversiones a largo plazo" 43 "Intereses provenientes de cuentas de ahorro" 44 "Intereses provenientes de prÃ©stamos a terceros" 45 "Rendimientos provenientes de bonos o cÃ©dulas" 46 "Alquiler de marcas, patentes y derechos de autor" 47 "Otros ingresos por renta de la propiedad" 
label values clave_ing clave_ing
replace tasa_int=0.11 if clave_ing==39
replace tasa_int=0.11 if clave_ing==40
replace tasa_int=0.11 if clave_ing==41
replace tasa_int=0.046 if clave_ing==42
replace tasa_int=0.023 if clave_ing==43
replace tasa_int=0.085 if clave_ing==44
replace tasa_int=0.2 if clave_ing==45
replace tasa_int=0.093 if clave_ing==46
replace tasa_int=0.093 if clave_ing==47
replace val_acervo= ing_anual/ tasa_int
replace val_acervo=0 if val_acervo==.
save "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Cálculo de riqueza\Ingresos refinada (riqueza financiera) 2010.dta"

*Deuda vivienda
use "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Vivienda 2010.dta"  
keep folioviv foliohog pagoviv
gen pagoviv_anual=pagoviv*12
gen deudaviv=.
gen tasa_int=0.028
gen n=20
replace deudaviv= pagoviv_anu /(tasa_int+(1/n))
drop tasa_int n pagoviv
destring foliohog, replace
save "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Cálculo de riqueza\deuda vivienda.dta"

*Erogaciones
use "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Erogaciones 2010.dta"
keep folioviv foliohog clave ero_tri
gen clave_erog=substr(clave,2,3)
destring clave_erog, replace
drop if clave_erog<3
drop if clave_erog>5 & clave_erog<11
drop if clave_erog>11
gen ero_anual= ero_tri*4
drop ero_tri
gen tasa_int=.
gen deuda=.
order folioviv foliohog clave_erog ero_anual tasa_int deuda clave 
destring foliohog, replace
label var ero_anual "ErogaciÃ³n anual"
label var tasa_int "Tasa de interÃ©s"
label var deuda "Deuda"
label var clave_erog "Identificador del producto"
label define clave_erog 3 "Pagos a tarjeta de crÃ©dito bancaria o comercial (incluye intereses)" 4 "Pago de deudas a la empresa donde trabajan y/o a otras personas o instituciones (excluye crÃ©ditos hipotecarios)" 5 "Pago de intereses por prÃ©stamos recibidos" 11 "Pago de hipotecas de bienes inmuebles"
label values clave_erog clave_erog
gen rp=0.0735
label var rp "Rendimiento promedio"
replace tasa_int=rp+0.028 if clave_erog==11
replace tasa_int=rp+0.007 if clave_erog==5
replace tasa_int=rp+0.007 if clave_erog==4
replace tasa_int=rp+0.0012 if clave_erog==3
gen n=.
label var n "NÃºmero de aÃ±os a pagar por el principal"
replace n=2 if clave_erog==4
replace n=7/12 if clave_erog==3
replace deuda=ero_anual/(tasa_int+(1/n))
order folioviv foliohog clave_erog ero_anual rp tasa_int n deuda clave
save "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Cálculo de riqueza\Erogaciones refinada (deuda total) 2010.dta"

*Riqueza fÃ­sica
use "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Cálculo de riqueza\Vivienda refinada (riqueza física) 2010.dta"
keep folioviv foliohog val_viv_prop
destring foliohog, replace
gen riq_fis= val_viv_prop
replace riq_fis=0 if riq_fis==.
label var riq_fis "Riqueza fÃ­sica"
drop val_viv_prop  
save "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Cálculo de riqueza\Riqueza física 2010.dta"

*Riqueza financiera
use "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Cálculo de riqueza\Ingresos refinada (riqueza financiera) 2010.dta"
collapse (sum) val_acervo, by (folioviv foliohog)
rename val_acervo riq_fin
label var riq_fin "Riqueza financiera bruta"
save "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Cálculo de riqueza\Riqueza financiera bruta 2010.dta"

*Deuda
use "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Cálculo de riqueza\Erogaciones refinada (deuda total) 2010.dta" 
collapse (sum) deuda, by (folioviv foliohog)
merge m:m folioviv foliohog using "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Cálculo de riqueza\deuda vivienda.dta"
replace deuda=0 if deuda==.
replace deudaviv=0 if deudaviv==.
gen deuda_tot= deuda+ deudaviv
drop deuda deudaviv _merge pagoviv_anual
rename deuda_tot deuda
label var deuda "Deuda total"
save "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Cálculo de riqueza\Deuda 2010.dta"

*Riqueza total neta
use "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Cálculo de riqueza\Riqueza física 2010.dta"
merge 1:1 folioviv foliohog using "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Cálculo de riqueza\Deuda 2010.dta"
rename _merge _merge2
merge 1:1 folioviv foliohog using "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Cálculo de riqueza\Riqueza financiera bruta 2010.dta"
replace deuda=0 if deuda==.
replace riq_fin=0 if riq_fin==.
replace riq_fis=0 if riq_fis==.
drop _merge _merge2
order folioviv foliohog riq_fin deuda riq_fis
gen riq_fin_net= riq_fin- deuda
gen riq_tot= riq_fin_net+ riq_fis
gen riq_tot_bru= riq_fin+ riq_fis
label var riq_fin_net "Riqueza financiera neta"
label var riq_tot "Riqueza total neta"
label var riq_tot_bru "Riqueza total bruta"
gen estatus=.
replace estatus=1 if riq_tot<0
replace estatus=2 if riq_tot==0
replace estatus=3 if riq_tot>0
label var estatus "Estatus de la riqueza"
label define estatus 1 "Riqueza negativa" 2 "Riqueza nula" 3 "Riqueza positiva"
label values estatus estatus
order folioviv foliohog riq_fis riq_fin deuda riq_fin_net riq_tot riq_tot_bru estatus
save "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Cálculo de riqueza\Riqueza de los hogares 2010.dta"

*Factor de expansiÃ³n
use "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Concentrado 2010.dta" 
keep folioviv foliohog factor
destring foliohog, replace
save "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Cálculo de riqueza\Factor 2010.dta"

*Deciles de ingreso
use "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Ingresos 2010.dta" 
keep folioviv foliohog ing_tri
collapse (sum) ing_tri, by (folioviv foliohog)
sort ing_tri
gen decil=.
replace decil=1 in 1/2800
replace decil=2 in 2801/5600
replace decil=3 in 5601/8400
replace decil=4 in 8401/11200
replace decil=5 in 11201/14000
replace decil=6 in 14001/16800
replace decil=7 in 16801/19600
replace decil=8 in 19601/22400
replace decil=9 in 22401/25200
replace decil=10 in 25201/27593
label var decil "Decil de ingreso"
destring foliohog, replace
save "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Cálculo de riqueza\Decil 2010.dta" 

*Riqueza con decil y factor
use "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Cálculo de riqueza\Riqueza de los hogares 2010.dta" 
merge m:m folioviv foliohog using "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Cálculo de riqueza\Decil 2010.dta"
drop if _merge==1
drop _merge
merge m:m folioviv foliohog using "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Cálculo de riqueza\factor 2010.dta"
drop if _merge==2
drop _merge
**Riqueza en pesos de 2000
gen rfb_p2000= riq_fin/1.55
gen deuda_p2000= deuda/1.55
gen rfn_p2000= rfb_p2000- deuda_p2000
gen rfis_p2000= riq_fis/1.55
gen rt_p2000= rfn_p2000+ rfis_p2000
gen rtb_p2000= rfb_p2000+ rfis_p2000
label var rfb_p2000 "Riqueza financiera bruta en pesos de 2000"
label var deuda_p2000 "Deuda en pesos de 2000"
label var rfn_p2000 "Riqueza financiera neta en pesos de 2000"
label var rfis_p2000 "Riqueza fÃ­sica en precios de 2000"
label var rt_p2000 "Riqueza total neta en precios de 2000"
label var rtb_p2000 "Riqueza total buta en pesos de 2000"
**Riqueza promedio de los hogares
table decil [iw=factor], c(freq sum rfb_p2000 mean rfb_p2000)
table decil [iw=factor], c(freq sum deuda_p2000 mean deuda_p2000)
table decil [iw=factor], c(freq sum rfn_p2000 mean rfn_p2000)
table decil [iw=factor], c(freq sum rfis_p2000 mean rfis_p2000)
table decil [iw=factor], c(freq sum rt_p2000 mean rt_p2000)
*Ajuste a cuentas nacionales
gen rfn_aju= riq_fin_net*2.57
gen rfn_p2000_aju= rfn_p2000*2.57
gen rfis_aju=riq_fis*2.22
gen rfis_p2000_aju=rfis_p2000*2.22
gen rt_aju= rfn_aju+ rfis_aju
gen rt_p2000_aju= rfn_p2000_aju+ rfis_p2000_aju
label var rfn_aju "Riqueza financiera neta ajustada"
label var rfis_aju "Riqueza fÃ­sica ajustada"
label var rt_aju "Riqueza total neta ajustada"
label var rfn_p2000_aju "Riqueza financiera neta ajustada en pesos de 2000"
label var rfis_p2000_aju "Riqueza fÃ­sica ajustada en pesos de 2000"
label var rt_p2000_aju "Riqueza total neta ajustada en pesos de 2000"
order folioviv foliohog decil riq_fin deuda riq_fin_net riq_fis riq_tot riq_tot_bru rfb_p2000 deuda_p2000 rfn_p2000 rfis_p2000 rt_p2000 rtb_p2000 rfn_aju rfis_aju rt_aju rfn_p2000_aju rfis_p2000_aju rt_p2000_aju estatus factor
save "C:\Users\ceey\Desktop\Luis David Jácome\Bases ENIGH 2010\Cálculo de riqueza\Riqueza de los hogares 2010.dta", replace
