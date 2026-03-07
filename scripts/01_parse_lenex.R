# Cargar la librería necesaria
library(xml2)

# 1. Definir la ruta de tu archivo (cámbialo por el nombre real de tu archivo)
archivo_lenex <- "data/raw/competicion.lxf" 

# 2. Descomprimir el archivo (R lo trata como un ZIP automáticamente)
# Lo extraemos en una carpeta temporal para no ensuciar tu proyecto
carpeta_temp <- tempdir()
archivos_extraidos <- unzip(archivo_lenex, exdir = carpeta_temp)

# 3. Localizar el archivo XML extraído 
# (Suele ser el único archivo dentro del ZIP)
ruta_xml <- archivos_extraidos[1]
cat("¡XML extraído con éxito en:", ruta_xml, "!\n")

# 4. Leer el XML directamente en R
datos_xml <- read_xml(ruta_xml)

# 5. Ver la estructura principal para comprobar que funciona
print(datos_xml)