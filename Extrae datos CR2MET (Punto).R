# =====================================================================
# Codigo para extraer informacion de productos grillados CR2MET / Felipe Garcia
# =====================================================================

rm(list=ls())
graphics.off()

# CARGA DE PAQUETES (instalarlos si aparece error)
library(ncdf4)
library(openxlsx)

# DEFINICION DIRECTORIO DE TRABAJO
# Consideraciones importantes:
# Ruta no tan larga y que no tengan un caracter especial.
# Los slash deben ser como el siguiente: "/".
# Lo que debes cambiar en el codigo se encuentra indicado como comentario.
# En el directorio de trabajo debes tener una carpeta llamada "CR2MET" que contenga TODOS los archivos de los que quieres extraer informacion.

setwd("C:/Codigos/Extraer_CR2MET_punto") # Definicion directorio de trabajo. CAMBIAR
getwd()

# DEFINICION DE FUNCIONES
# Funcion para determinar el nodo mas cercano al punto en evaluacion
coordenadas <- function(netcdf, lat, lon) {
  
  QNlat <- (lat)
  corLat <- max(which(netcdf$dim$lat$vals<QNlat))
  if ((QNlat-netcdf$dim$lat$vals[corLat])>(netcdf$dim$lat$vals[corLat+1]-QNlat)){
    corLat=corLat+1
  }
  
  QNlon <- (lon)
  corLon<-max(which(netcdf$dim$lon$vals<QNlon))
  if ((QNlon-netcdf$dim$lon$vals[corLon])>(netcdf$dim$lon$vals[corLon+1]-QNlon)){
    corLon=corLon+1
  }
  resultados <- list(corLat = corLat, corLon = corLon)
  return(resultados)
}

# Funcion para extraer el nombre de la variable entre los dos primeros guiones bajos
extraer_variable <- function(nombre_archivo) {
  # Dividir el string por guiones bajos
  partes <- strsplit(nombre_archivo, "_")[[1]]
  # Retornar el segundo elemento (la variable)
  return(partes[2])
  #strsplit() divide el nombre del archivo usando "_" como separador
  #[[1]] extrae el vector resultante de la división
  #partes[2] toma el segundo elemento (primera posición después de "CR2MET")
}

# Funcion que inidica la unidad de medida de cada variable
UM_variable <- function(variable) {
  
  if (variable == 'pr'){
    UM <- 'mm'
  } else {
    UM <- '°C'
  }
  return(UM)
}

# =====================================================================
# LECTURA DE ARCHIVO EXCEL CON ESTACIONES Y SUS COORDENADAS
# 1) Lectura de archivo Excel:
estaciones <- read.xlsx(paste0(getwd(), "/Puntos.xlsx"))

# =====================================================================
# LECTURA DE ARCHIVOS NETCDF EN CARPETA
# 1) Directorio que contiene archivos netcdf:
nc_files_CR2MET <- paste0(getwd(),"/CR2MET")

# 2) Seteamos este directorio como el nuevo directorio de trabajo:
setwd(nc_files_CR2MET)

# 3) Lista de archivos netcdf en el directorio:
# Este codigo va a arrojar una lista con la ruta completa, desde C:/User/Usuario ...
archivos <- list.files(nc_files_CR2MET, pattern ="\\.nc$", full.names = TRUE)

# 4) Obtener solo los nombres de los archivos:
nombres_netcdf <- basename(archivos)

# 5) Obtener la variable de cada archivo (pr, t2m, tmax, tmin, etc)
variables <- sapply(nombres_netcdf, extraer_variable, USE.NAMES = FALSE)
  # sapply() aplica la funcion a todos los nombres en nombres_netcdf
  # USE.NAMES = FALSE evita que use los nombres originales como nombres de la lista

# 6) Se crea un diccionario para tener el par nombres_netcdf - variables:
dict_netcdf <- setNames(variables, nombres_netcdf)

# =====================================================================

# PROCESAMIENTO DE INFO DE CADA NETCDF Y CADA ESTACION
# 1) Empieza el proceso de iteracion:
for(nombre_archivo in names(dict_netcdf)) {
  variable <- dict_netcdf[nombre_archivo]
  
  cat("\n========================================\n")
  cat("Abriendo archivo:", nombre_archivo, "\n")
  cat("Variable:", variable, "\n")
  cat("========================================\n")
  
  # Apertura de archivo netcdf_
  nc <- nc_open(nombre_archivo)
  
  # Extraer datos para todas las estaciones
  for(i in 1:nrow(estaciones)) {
    estacion_nombre <- estaciones$Estacion[i]
    lat <- estaciones$Latitud[i]
    lon <- estaciones$Longitud[i]
    
    cat("  -> Extrayendo datos para estación:", estacion_nombre, "\n")
    
    # Obtener coordenadas de grilla
    coords <- coordenadas(nc, lat, lon)
    
    # Extraer datos de la variable
    data <- ncvar_get(nc, varid = variable)
    aux <- as.data.frame(data[coords$corLon, coords$corLat, ])
    
    # Crear encabezado con variable y unidad de medida
    unidad <- UM_variable(variable)
    nombre_columna <- paste0(variable, " (", unidad, ")")
    colnames(aux) <- nombre_columna
    
    # Crear fechas
    fecha <- seq(as.Date("1979-01-01"), length=nrow(aux), by="day")
    
    # Crear nombre descriptivo para el archivo de salida
    nombre_salida <- paste0(variable, "_", estacion_nombre, ".xlsx")
    
    # Guardar archivo
    # Lo primero es volver al directorio de trabajo donde esta el codigo, aca queremos guardar las planillas.
    setwd("C:/Codigos/Extraer_CR2MET_punto") # Definicion directorio de trabajo. CAMBIAR
    write.xlsx(cbind(fecha, aux), file=nombre_salida, overwrite = TRUE)
    
    cat("     Archivo guardado:", nombre_salida, "\n")
  }
  
  # Clausura de archivo netcdf
  nc_close(nc)
  cat("Archivo cerrado:", nombre_archivo, "\n")
  
  # Volvemos al directorio de los netcdf para empezar el ciclo nuevamente.
  setwd(nc_files_CR2MET)
}

cat("\n¡Procesamiento completado!\n")










#name<-"CR2MET_tmin_v2_0_day_1979_2020_005deg.nc" #Nombre del archivo, debe tener extension. CAMBIAR
#Salida<-'C:/Codigos/Extraer_CR2MET_punto/tmin_Iglesia_Colorada.xlsx' # Archivo de salida. CAMBIAR
#nc<-nc_open(name)
#data <- ncvar_get(nc, varid = "tmin") # Variable a extraer, debe coincidir con nombre del archivo. CAMBIAR
##Coordenadas del punto a evaluar
#QNlat<-(-28.1572) # Latitud en grados. CAMBIAR
#QNlon<-(-69.8808) # Longitud en grados. CAMBIAR

##Seleccion de grillas
#corLat<-max(which(nc$dim$lat$vals<QNlat))
#if ((QNlat-nc$dim$lat$vals[corLat])>(nc$dim$lat$vals[corLat+1]-QNlat)){
#  corLat=corLat+1}

#corLon<-max(which(nc$dim$lon$vals<QNlon))
#if ((QNlon-nc$dim$lon$vals[corLon])>(nc$dim$lon$vals[corLon+1]-QNlon)){
#  corLon=corLon+1}

#aux<-as.data.frame(data[corLon,corLat, ])
#fecha<-seq(as.Date("1979-01-01"), length=dim(aux)[1], by="day") # Fecha inicio archivo netcdf. CAMBIAR

#write.xlsx(cbind(fecha,aux), file=Salida,overwrite = TRUE)

