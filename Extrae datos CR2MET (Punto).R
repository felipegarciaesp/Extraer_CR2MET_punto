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
# En el directorio de trabajo debes tener una carpeta "Inputs" con los .nc y el archivo Puntos.xlsx.
# Los resultados se guardaran en la carpeta "Outputs".

# 1) Define el directorio de trabajo, donde se encuentra el codigo y donde se guardaran los resultados.
directorio_trabajo <- "C:/Codigos/Extraer_CR2MET_punto" # Definicion directorio de trabajo. CAMBIAR

# 2) Define carpetas de entrada y salida dentro del directorio de trabajo.
input_dir <- file.path(directorio_trabajo, "Inputs")
output_dir <- file.path(directorio_trabajo, "Outputs")

# Crear carpeta de salida si no existe
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

setwd(directorio_trabajo) # Se identifica el directorio de trabajo
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

# Extrae solo la serie temporal del punto solicitado, evitando cargar todo el cubo en memoria
extraer_serie_punto <- function(nc, variable, corLon, corLat) {
  var_obj <- nc$var[[variable]]
  dim_names <- tolower(sapply(var_obj$dim, function(d) d$name))
  n_dims <- length(dim_names)
  
  if (n_dims < 2) {
    stop(paste("La variable", variable, "no tiene dimensiones espaciales esperadas."))
  }
  
  start <- rep(1, n_dims)
  count <- rep(1, n_dims)
  
  idx_lon <- which(dim_names %in% c("lon", "longitude", "x"))
  idx_lat <- which(dim_names %in% c("lat", "latitude", "y"))
  idx_time <- which(dim_names %in% c("time", "t"))
  
  if (length(idx_lon) == 0 || length(idx_lat) == 0) {
    stop(paste("No se encontraron dimensiones lon/lat en la variable", variable))
  }
  
  start[idx_lon[1]] <- corLon
  start[idx_lat[1]] <- corLat
  
  if (length(idx_time) > 0) {
    count[idx_time[1]] <- -1
  }
  
  serie <- ncvar_get(nc, varid = variable, start = start, count = count)
  as.vector(serie)
}

# =====================================================================
# LECTURA DE ARCHIVO EXCEL CON ESTACIONES Y SUS COORDENADAS
# 1) Lectura de archivo Excel:
estaciones <- read.xlsx(file.path(input_dir, "Puntos.xlsx"))

# =====================================================================
# LECTURA DE ARCHIVOS NETCDF EN CARPETA
# 1) Seteamos la ruta de los netcdf como el nuevo directorio de trabajo:
setwd(input_dir)

# 3) Lista de archivos netcdf en el directorio:
# Este codigo va a arrojar una lista con la ruta completa, desde C:/User/Usuario ...
archivos <- list.files(input_dir, pattern ="\\.nc$", full.names = TRUE)

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
    
    # Extraer solo la serie temporal del punto (sin cargar todo el netcdf)
    serie <- extraer_serie_punto(nc, variable, coords$corLon, coords$corLat)
    aux <- data.frame(valor = serie)
    
    # Crear encabezado con variable y unidad de medida
    unidad <- UM_variable(variable)
    nombre_columna <- paste0(variable, " (", unidad, ")")
    colnames(aux) <- nombre_columna
    
    # Crear fechas
    fecha <- seq(as.Date("1979-01-01"), length=nrow(aux), by="day")
    
    # Crear nombre descriptivo para el archivo de salida
    nombre_salida <- paste0(variable, "_", estacion_nombre, ".xlsx")
    
    # Guardar archivo
    write.xlsx(cbind(fecha, aux), file=file.path(output_dir, nombre_salida), overwrite = TRUE)
    
    cat("     Archivo guardado:", nombre_salida, "\n")
  }
  
  # Clausura de archivo netcdf
  nc_close(nc)
  cat("Archivo cerrado:", nombre_archivo, "\n")
  
  # Volvemos al directorio de los netcdf para empezar el ciclo nuevamente.
  setwd(input_dir)
}

cat("\n¡Procesamiento completado!\n")