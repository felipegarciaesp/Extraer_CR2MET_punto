# Extraccion de datos CR2MET en puntos

Script en R para extraer series temporales desde archivos NetCDF de CR2MET en coordenadas puntuales definidas en un archivo Excel.

## Que hace este codigo

- Lee una lista de estaciones desde `Inputs/Puntos.xlsx`.
- Recorre archivos NetCDF en la carpeta `Inputs/`.
- Busca el nodo de grilla mas cercano a cada estacion.
- Extrae la serie temporal del punto (sin cargar el cubo completo en memoria).
- Exporta resultados por estacion y variable en formato Excel (`.xlsx`) en `Outputs/`.

## Estructura esperada

En el directorio de trabajo debes tener:

- `Extrae datos CR2MET (Punto).R`
- Carpeta `Inputs/` con `Puntos.xlsx` y archivos `.nc`
- Carpeta `Outputs/` (opcional, el script la crea si no existe)

Ejemplo:

```text
Extraer_CR2MET_punto/
|- Extrae datos CR2MET (Punto).R
|- Inputs/
|  |- Puntos.xlsx
|  |- CR2MET_pr_AAA_daily_1979_2020_005deg.nc
|  |- CR2MET_t2m_BBB_daily_1979_2020_005deg.nc
|- Outputs/
```

## Requisitos

- R (recomendado >= 4.2)
- Paquetes de R:
  - `ncdf4`
  - `openxlsx`

Instalacion de paquetes (una sola vez):

```r
install.packages(c("ncdf4", "openxlsx"))
```

## Preparacion

1. Edita en el script estas dos rutas:
   - `directorio_trabajo`
   - (opcional) confirma que `input_dir` y `output_dir` apunten a `Inputs` y `Outputs`
2. Verifica que `Puntos.xlsx` tenga, al menos, estas columnas:
   - `Estacion`
   - `Latitud`
   - `Longitud`

## Ejecucion

Desde R o RStudio, ejecuta:

```r
source("Extrae datos CR2MET (Punto).R")
```

## Salidas

Se generan archivos `.xlsx` en la carpeta `Outputs/` con formato:

- `variable_estacion.xlsx`

Ejemplo:

- `pr_Quinta_Normal.xlsx`
- `tmax_Valdivia.xlsx`

Cada archivo contiene:

- `fecha`
- columna de datos con nombre `variable (unidad)`

## Nota de rendimiento

La version actual evita errores de memoria del tipo:

- `Error: cannot allocate vector of size ...`

porque extrae solo la serie temporal del punto solicitado usando lectura parcial del NetCDF.

## Autor

- Felipe Garcia
