rm(list=ls())
graphics.off()
library(ncdf4)
library(openxlsx)

setwd("C:/Users/eduardo.loyola/OneDrive - Ausenco/Escritorio/Eduardo/Datos/Datos Grillados/CR2MET")
name<-"CR2MET_pr_v2.5_day_1960_2021_005deg.nc"
Salida<-'C:/Users/eduardo.loyola/OneDrive - Ausenco/Escritorio/Eduardo/Manto Verde/Trabajo/Datos CR2MET/PP_Las_Vegas.xlsx'
nc<-nc_open(name)
data <- ncvar_get(nc, varid = "pr")
#Coordenadas del punto a evaluar
QNlat<-(-32.706944)
QNlon<-(-71.329166)

#Seleccion de grillas
corLat<-max(which(nc$dim$lat$vals<QNlat))
if ((QNlat-nc$dim$lat$vals[corLat])>(nc$dim$lat$vals[corLat+1]-QNlat)){
  corLat=corLat+1}

corLon<-max(which(nc$dim$lon$vals<QNlon))
if ((QNlon-nc$dim$lon$vals[corLon])>(nc$dim$lon$vals[corLon+1]-QNlon)){
  corLon=corLon+1}

aux<-as.data.frame(data[corLon,corLat, ])
fecha<-seq(as.Date("1960-01-01"), length=dim(aux)[1], by="day")

write.xlsx(cbind(fecha,aux), file=Salida,overwrite = TRUE)
