# El objetivo principal de este script es transformar el archivo LEF a un formato que sea compatible. Todos los datos los cambiaremos a .xml.
import logging
from pathlib import Path




logging.basicConfig(level=logging.INFO)
ruta_inicial = Path("data/raw/")

for archivo in ruta_inicial.rglob('*.lef'):
    if archivo.is_file():
        archivo_cambiado = archivo.with_suffix('.xml')
        archivo.rename(archivo_cambiado)
        logging.info(f"Archivo {archivo} renombrado a {archivo_cambiado}")

print("Transformación de archivos LEF a XML completada.")