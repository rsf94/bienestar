# -------------
# Preparación
# -------------

packages <- c(
  "dplyr",
  "tidyr",
  'naniar'
)

# instala los que no tengas
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# cargar paquetes
lapply(packages,
       library,
       character.only = TRUE)


# funcion para NAs
check_nas <- function(df){
  df %>%
    select_if(~sum(is.na(.)) > 0) %>%
    miss_var_summary()
}


# -------------
# Cargar datos
# -------------

data_path <- file.path("C:/Users/rsf94/Google Drive/MAESTRÍA ITAM/2do semestre/Bienestar y política social/Bienestar_equipo/trabajo_final/data_raw")
data_clean <- file.path("C:/Users/rsf94/Google Drive/MAESTRÍA ITAM/2do semestre/Bienestar y política social/Bienestar_equipo/trabajo_final/data_clean")

data_ind<-read.csv(file.path(data_path,"ENCODAT 2016_2017.csv"))

data_hogar <- read.csv(file.path(data_path,"ponde_Hogar_ENA_2016_pp.csv"))

str(data_ind)
str(data_hogar)

colnames(data_hogar)[1] <- "id_hogar"

data_ind <- data_ind %>% separate(ID_PERS,c("id_hogar","id_ind")," ")

# elimino 19 registros donde no contamos con el ID del individuo
data_ind <- data_ind  %>% filter(!is.na(id_ind))

check_nas(data_ind) %>% filter(pct_miss>90)

length(data_ind)
nrow(check_nas(data_ind) %>% filter(pct_miss>90))

# primer análisis
a <- data_ind %>% select(c(ds8, ds10, ds15, dp5, ds14, ed1, ed5, ts9a, tb02, di6b, di8b))

check_nas(a) 


# JOIN características de hogares
data <- left_join(data_ind,data_hogar,by="id_hogar")

write.csv(data, file.path(data_clean,"base.csv"))

#data <- svydesign(id = ~ code_upm,
#                  weights = ~ ponde_ss,
#                  strata = ~  est_var,
#                  nest=TRUE,
#                  data=data)

