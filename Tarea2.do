version 16 
set more off
clear all
capture log close 
macro drop _all 
cd "" /* cambiar el directorio */


/*Nota: no se usan acentos ni enies, ni en la base de datos ni en el do file 
para evitar problemas con computadoras con encodings distintos a UTF8 */

********************************************************************************
* File-Name:      Tarea2.do                                                    *
* Date:           01/2021                                                      *
* Author:         Marcelo Torres, Rafael Sandoval                              *
* Purpose:        Resultados para la tarea 2                                   *
* Input File:     various, ENIGH 2018                                          *
* Output Files:   tbd                                                          *
* Data Output:    tbd                                                          *
* Previous file:  none                                                         *
* Status:         in use                                                       *
********************************************************************************


gl b=""
