rm(list=ls())
graphics.off()
library(ncdf4)
library(openxlsx)

# Ruta no tan larga y que no tengan un caracter especial
# Los slash deben ser como el siguiente: "/"
# Lo que debes cambiar en el codigo se encuentra indicado como comentario.

setwd("C:/Codigos/Extraer_CR2MET_punto/CR2MET") # Ruta donde se ubica el netcdf. CAMBIAR
name<-"CR2MET_tmin_v2_0_day_1979_2020_005deg.nc" #Nombre del archivo, debe tener extension. CAMBIAR
Salida<-'C:/Codigos/Extraer_CR2MET_punto/tmin_Iglesia_Colorada.xlsx' # Archivo de salida. CAMBIAR
nc<-nc_open(name)
data <- ncvar_get(nc, varid = "tmin") # Variable a extraer, debe coincidir con nombre del archivo. CAMBIAR
#Coordenadas del punto a evaluar
QNlat<-(-28.1572) # Latitud en grados. CAMBIAR
QNlon<-(-69.8808) # Longitud en grados. CAMBIAR

#Seleccion de grillas
corLat<-max(which(nc$dim$lat$vals<QNlat))
if ((QNlat-nc$dim$lat$vals[corLat])>(nc$dim$lat$vals[corLat+1]-QNlat)){
  corLat=corLat+1}

corLon<-max(which(nc$dim$lon$vals<QNlon))
if ((QNlon-nc$dim$lon$vals[corLon])>(nc$dim$lon$vals[corLon+1]-QNlon)){
  corLon=corLon+1}

aux<-as.data.frame(data[corLon,corLat, ])
fecha<-seq(as.Date("1979-01-01"), length=dim(aux)[1], by="day") # Fecha inicio archivo netcdf. CAMBIAR

write.xlsx(cbind(fecha,aux), file=Salida,overwrite = TRUE)

