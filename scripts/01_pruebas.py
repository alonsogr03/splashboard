from __future__ import annotations

import json
import logging
import zipfile
from datetime import date
from pathlib import Path
from typing import Any

import xmltodict

logger = logging.getLogger(__name__)

def _xml_to_json_data(ruta_xml_str: str) -> dict[str, Any] | None:
    archivo_xml = Path(ruta_xml_str)
    
    if not archivo_xml.is_file():
        logger.error("El archivo %s no existe.", archivo_xml)
        return None
    
    try:
        logger.info("Procesando XML %s...", archivo_xml.name)

        # Leemos el contenido del archivo directamente como string
        datos_xml_str = archivo_xml.read_text(encoding='utf-8')

        # Convertimos el XML a diccionario
        datos_dict = xmltodict.parse(datos_xml_str, attr_prefix='')
        
        return datos_dict

    except Exception as e:
        # Aquí capturamos errores de lectura o si el XML está mal formado (ExpatError)
        logger.exception("Ocurrió un error inesperado procesando %s: %s", archivo_xml, e)
        return None

def _obtener_rango_calles(datos_pool: dict[str, Any] | None) -> dict[str, str] | None:
    if not datos_pool: 
        return None
        
    min_lane = datos_pool.get('lanemin')
    max_lane = datos_pool.get('lanemax')

    if min_lane is None or max_lane is None:
        return None

    try:
        return {'min_lane': min_lane, 'max_lane': max_lane}
    except (ValueError, TypeError):
        return None

def _extraer_fechas_inicio_fin(datos_sesiones: list[dict[str, Any]]) -> tuple[date | None, date | None]:
    if isinstance(datos_sesiones, list):
        fechas_sesiones = []
        for sesion in datos_sesiones:
            fecha = sesion.get('date')
            if fecha:
                try:
                    fechas_sesiones.append(date.fromisoformat(fecha))
                except ValueError:
                    pass
        return (min(fechas_sesiones) if fechas_sesiones else None,
                max(fechas_sesiones) if fechas_sesiones else None)
    return (None, None)

def _asegurar_lista(valor: Any) -> list:
    if valor is None:
        return []
    if isinstance(valor, list):
        return valor
    return [valor]

def _introducir_relevo(
    relevo: dict[str, Any],
    genero: str,
    info_atletas_auxiliar: dict[str, Any],
    info_eventos_auxiliar: dict[str, Any],
    code: str,
    club: dict[str, Any],
    name: str,
    shortname: str,
    club_nation: str,
    region: str,
    clubid: str,
) -> dict[str, Any]:

    eventid = relevo.get('eventid')
    points = int(relevo.get('points', 0) or 0)
    swimtime = _limpiar_tiempos(relevo.get('swimtime'))
    lane = int(relevo.get('lane', 0) or 0)
    entrytime = _limpiar_tiempos(relevo.get('entrytime'))
    entrycourse = relevo.get('entrycourse')

    info_evento = info_eventos_auxiliar.get(eventid, {})
    place_raw = relevo.get('place', 0)
    place = int(place_raw) if place_raw and str(place_raw).lstrip('-').isdigit() else 0
    genero = info_evento.get('gender') or genero
    numero_prueba = int(info_evento.get('number', 0) or 0)
    ronda = info_evento.get('round')
    estilo = info_evento.get('style')
    distancia = int(info_evento.get('distance', 0) or 0)
    isRelevo = info_evento.get('is_relay', True)
    date = info_evento.get('date', '')      
    daytime_sesion = info_evento.get('daytime_sesion', '')
    name_sesion = info_evento.get('name', '')
    
    heat = int(relevo.get('heat', 0) or 0)

    # ⚠️ AQUI ESTABA EL ERROR: Añadimos _asegurar_lista para evitar que se rompa si solo hay 1 split
    splits = _asegurar_lista((relevo.get('SPLITS') or {}).get('SPLIT', []))
    
    parciales_relevistas = []
    parcial_anterior = 0
    distancia_anterior = 0
    leg_time = 0
    
    for split in splits:
        tiempo_actual = _limpiar_tiempos(split.get('swimtime', 0))
        distancia_actual = int(split.get('distance', 0) or 0)
        parciales_relevistas.append({
            'distance': distancia_actual,
            'swimtime': tiempo_actual,
            'parcialswimtime': round(tiempo_actual - parcial_anterior, 2),
            'parcial_distancia': distancia_actual - distancia_anterior
        })
        parcial_anterior = tiempo_actual
        distancia_anterior = distancia_actual

    parciales_relevistas.append({
        'distance': distancia*4,
        'swimtime': swimtime,
        'parcialswimtime': round(swimtime - parcial_anterior, 2),
        'parcial_distancia': distancia*4 - distancia_anterior
    })

    # Eliminar último parcial si es duplicado
    if len(parciales_relevistas) >= 2:
        ultimo = parciales_relevistas[-1]
        penultimo = parciales_relevistas[-2]
        if ultimo['distance'] == penultimo['distance'] and ultimo['swimtime'] == penultimo['swimtime']:
            parciales_relevistas.pop()

    # ⚠️ También lo añadimos aquí por si un relevo tiene posiciones raras o le faltan datos
    relevistas = _asegurar_lista((relevo.get('RELAYPOSITIONS') or {}).get('RELAYPOSITION', []))
    
    resultados = []
    
    for relevista in relevistas:
        num_relevista = int(relevista.get('number') or 0)
        athleteid = relevista.get('athleteid')
        reactiontime_relevista = _limpiar_reactiontime(relevista.get('reactiontime', None))

        info_atleta = info_atletas_auxiliar.get(athleteid, {})
        license = info_atleta.get('license')
        firstname = info_atleta.get('firstname')
        lastname = info_atleta.get('lastname')
        birthdate = info_atleta.get('birthdate')
        gender = info_atleta.get('gender')
        nation = info_atleta.get('nation')

        parcial_inicial = (num_relevista - 1) * int(distancia)
        parcial_final = num_relevista * int(distancia)
        splits_relevista = []
        leg_time = 0
        
        for parcial in parciales_relevistas:
            distancia_parcial = parcial['distance']
            tiempo_parcial = parcial['swimtime']
            if int(distancia_parcial) > parcial_inicial and int(distancia_parcial) <= parcial_final:
                splits_relevista.append({
                    'distance': distancia_parcial,
                    'swimtime': tiempo_parcial,
                    'parcialswimtime': parcial['parcialswimtime'],
                    'parcial_distancia': parcial['parcial_distancia'], 
                    'leg_time': round(leg_time + parcial['parcialswimtime'], 2)
                })
                leg_time += parcial['parcialswimtime']
                leg_time = round(leg_time, 2)

        resultados.append({
            'athleteid': athleteid,
            'license': license,
            'firstname': firstname,
            'lastname': lastname,
            'birthdate': birthdate,
            'birthyear': birthdate[:4] if birthdate else None,
            'gender': gender,
            'nation': nation,
            'num_relevista': num_relevista,
            'reactiontime': reactiontime_relevista,
            'leg_time': leg_time,
            'splits': splits_relevista
        })

    return {
        'club_code': code,
        'club_nation': club_nation,
        'club_region': region,
        'clubid': clubid,
        'club_name': name,
        'club_shortname': shortname,
        'place': place,
        'daytime': info_evento.get('daytime', ''),
        'num_prueba': numero_prueba,
        'round': ronda,
        'style': estilo,
        'distance': distancia,
        'gender': genero,
        'is_relay': isRelevo,
        'date': date,
        'daytime_sesion': daytime_sesion,
        'name_sesion': name_sesion,
        'heat': heat,
        'lane': lane,
        'points': points,
        'swimtime': swimtime,
        'entrytime': entrytime,
        'entrycourse': entrycourse,
        'eventid': eventid,
        'relevistas': resultados
    }

def _limpiar_reactiontime(reactiontime: str | None) -> float | None:
    if reactiontime is None or reactiontime == '':
        return None
    try:
        return round(float(reactiontime.replace('+', ''))/100, 2)
    except ValueError:
        return None

def _limpiar_tiempos(tiempo: str | None) -> float:
    if tiempo is None or tiempo == 0:
        return 0
    try:
        partes = str(tiempo).split(':')
        if len(partes) == 3:
            horas, minutos, segundos = partes
            tiempo_segundos = int(horas) * 3600 + int(minutos) * 60 + float(segundos)
            return round(tiempo_segundos, 2)
        else:
            return 0
    except ValueError:
        return 0
    
def _configurar_splits_individual(splits: list[dict[str, Any]] | None, distancia_total: int, tiempo_total: float) -> list[dict[str, Any]] | None:
    if splits is None or len(splits) == 0:
        return []
    
    parcial_anterior = 0
    distancia_anterior = 0
    datos_ordenados = sorted(splits, key=lambda x: int(x["distance"]))
    for split in datos_ordenados:
        split['distance'] = int(split['distance'])
        split['swimtime'] = _limpiar_tiempos(split['swimtime'])
        split['parcialswimtime'] = round(split['swimtime'] - parcial_anterior, 2)
        split['parcial_distancia'] = split['distance'] - distancia_anterior
        parcial_anterior = split['swimtime']
        distancia_anterior = split['distance']

    datos_ordenados.append({
        'distance': distancia_total,
        'swimtime': tiempo_total,
        'parcialswimtime': round(tiempo_total - parcial_anterior, 2),
        'parcial_distancia': distancia_total - distancia_anterior
    })
    
    # Eliminar último split si es duplicado (distancia y tiempo iguales al anterior)
    if len(datos_ordenados) >= 2:
        ultimo = datos_ordenados[-1]
        penultimo = datos_ordenados[-2]
        if ultimo['distance'] == penultimo['distance'] and ultimo['swimtime'] == penultimo['swimtime']:
            datos_ordenados.pop()
    
    return datos_ordenados

def lxf_to_json(ruta_lxf: str, ruta_json_salida: str) -> None:
    resultado = _xml_to_json_data(ruta_lxf)
    if resultado is None:
        logger.error("No se pudo procesar el archivo LXF: %s", ruta_lxf)
        return None
    
    datos_competicion = resultado['LENEX']['MEETS']['MEET']
    datos_sesiones = _asegurar_lista(datos_competicion.get('SESSIONS', {}).get('SESSION', []))
    fecha_inicio, fecha_fin = _extraer_fechas_inicio_fin(datos_sesiones)
    
    resultados_competicion = {
        'extracted_from': 'XML',
        'name': datos_competicion.get('name'),
        'city': datos_competicion.get('city'),
        'course': datos_competicion.get('course'),
        'timing': datos_competicion.get('timing'),
        'touchpad': datos_competicion.get('touchpad'),
        'nation': datos_competicion.get('nation'),
        'pool_dimensions': _obtener_rango_calles(datos_competicion.get('POOL')),
        'federation': "FFN", # Modificado para que ponga la federación francesa si quieres
        'start_date': fecha_inicio.isoformat() if fecha_inicio else None,
        'end_date': fecha_fin.isoformat() if fecha_fin else None,
    }

    info_eventos_auxiliar: dict[str, Any] = {}

    for sesion in datos_sesiones:
        fecha_sesion = sesion.get('date')
        hora_sesion = sesion.get('daytime')
        nombre_sesion = sesion.get('name')
        id_sesion = int(sesion.get('number', 0))
        pruebas = _asegurar_lista((sesion.get('EVENTS') or {}).get('EVENT', []))

        for prueba in pruebas:
            eventid = prueba.get('eventid')
            hora_prueba = prueba.get('daytime')
            genero = prueba.get('gender')
            numero_prueba = prueba.get('number')
            ronda = prueba.get('round')
            estilo = (prueba.get('SWIMSTYLE') or {}).get('stroke')
            distancia = (prueba.get('SWIMSTYLE') or {}).get('distance')
            isRelevo = int((prueba.get('SWIMSTYLE') or {}).get('relaycount', 0)) > 1

            info_eventos_auxiliar[eventid] = {
                'daytime': hora_prueba,
                'gender': genero,
                'number': numero_prueba,
                'round': ronda,
                'style': estilo,
                'distance': distancia,
                'is_relay': isRelevo,
                'date': fecha_sesion,
                'daytime_sesion': hora_sesion,
                'name': nombre_sesion,
            }

    resultados_competicion['individual_results'] = []
    resultados_competicion['relay_results'] = []
                                                                                                                                                                        
    clubes = _asegurar_lista((datos_competicion.get('CLUBS') or {}).get('CLUB', []))

    for club in clubes:
        code = club.get('code')
        club_nation = club.get('nation')
        region = club.get('region')
        clubid = club.get('clubid')
        name = club.get('name')
        shortname = club.get('shortname')

        atletas = _asegurar_lista((club.get('ATHLETES') or {}).get('ATHLETE', []))
        info_atletas_auxiliar: dict[str, Any] = {}
        
        for atleta in atletas:
            athleteid = atleta.get('athleteid')
            # ⚠️ Si license es None (formato francés), usa el athleteid como licencia.
            license = atleta.get('license') or athleteid
            firstname = atleta.get('firstname')
            lastname = atleta.get('lastname')
            birthdate = atleta.get('birthdate')
            gender = atleta.get('gender')
            nation = atleta.get('nation')

            info_atletas_auxiliar[athleteid] = {
                'license': license,
                'firstname': firstname,
                'lastname': lastname,
                'birthdate': birthdate,
                'gender': gender,
                'nation': nation
            }

            resultados_atleta = _asegurar_lista((atleta.get('RESULTS') or {}).get('RESULT', []))

            for resultado_atleta in resultados_atleta:
                eventid = resultado_atleta.get('eventid')
                info_prueba = info_eventos_auxiliar.get(eventid, {})
                
                splits_crudos = _asegurar_lista((resultado_atleta.get('SPLITS') or {}).get('SPLIT'))
                distancia_pr = int(info_prueba.get('distance', 0) or 0)
                tiempo_pr = _limpiar_tiempos(resultado_atleta.get('swimtime'))
                
                splits_procesados = _configurar_splits_individual(splits_crudos, distancia_pr, tiempo_pr)
                
                place_raw = resultado_atleta.get('place', 0)
                place_val = int(place_raw) if place_raw and str(place_raw).lstrip('-').isdigit() else 0
                
                resultados_competicion['individual_results'].append({
                    'athleteid': athleteid,
                    'license': license,
                    'firstname': firstname,
                    'lastname': lastname,
                    'birthdate': birthdate,
                    'birthyear': birthdate[:4] if birthdate else None,
                    'gender': gender,
                    'nation': nation,
                    'club_code': code,
                    'club_nation': club_nation,
                    'club_region': region,
                    'clubid': clubid,
                    'club_name': name,
                    'club_shortname': shortname,
                    'place': place_val,
                    'daytime': info_prueba.get('daytime', ''),
                    'num_prueba': int(info_prueba.get('number', 0) or 0),
                    'round': info_prueba.get('round', ''),
                    'style': info_prueba.get('style', ''),
                    'distance': distancia_pr,
                    'is_relay': info_prueba.get('is_relay', False),
                    'date': info_prueba.get('date', ''),
                    'daytime_sesion': info_prueba.get('daytime_sesion', ''),
                    'name_sesion': info_prueba.get('name', ''),
                    'heat': int(resultado_atleta.get('heat', 0) or 0),
                    'lane': int(resultado_atleta.get('lane', 0) or 0),
                    'points': int(resultado_atleta.get('points', 0) or 0),
                    'reactiontime': _limpiar_reactiontime(resultado_atleta.get('reactiontime')),
                    'swimtime': tiempo_pr,
                    'entrytime': _limpiar_tiempos(resultado_atleta.get('entrytime')),
                    'entrycourse': resultado_atleta.get('entrycourse', ''),
                    'status': resultado_atleta.get('status', ''),
                    'gender_prueba': info_prueba.get('gender', ''),
                    'splits': splits_procesados,
                })


        tipos_relevos = _asegurar_lista((club.get('RELAYS') or {}).get('RELAY', []))

        for tipo_relevo in tipos_relevos:
            genero = tipo_relevo.get('gender')
            relevos = _asegurar_lista((tipo_relevo.get('RESULTS') or {}).get('RESULT', []))
            for relevo in relevos:
                resultados_competicion['relay_results'].append(_introducir_relevo(relevo, genero, info_atletas_auxiliar, info_eventos_auxiliar, code, club, name, shortname, club_nation, region, clubid))


    nombre_comp = resultados_competicion.get('name') or 'Competicion'
    ciudad = resultados_competicion.get('city') or 'Ciudad'

    fecha_completa = resultados_competicion.get('start_date')
    fecha_str = fecha_completa[:10] if fecha_completa else 'SinFecha'

    nombre_bruto = f"{fecha_str}_{ciudad}_{nombre_comp}"

    nombre_limpio = "".join(c for c in nombre_bruto if c.isalnum() or c in " _-").replace(' ', '_')
    nombre_archivo = f"{nombre_limpio}.json"

    carpeta_destino = Path(ruta_json_salida)
    archivo_final_json = carpeta_destino / nombre_archivo

    with archivo_final_json.open('w', encoding='utf-8') as f:
        json.dump(resultados_competicion, f, ensure_ascii=False, indent=4)

    logger.info("Guardado con éxito -> %s", archivo_final_json.name)


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    ruta_inicial = Path("data/raw/")
    ruta_base_salida = Path("data/processed/")
    
    for archivo in ruta_inicial.rglob('*.xml'):
        if archivo.is_file():
            ruta_relativa = archivo.relative_to(ruta_inicial)
            carpeta_relativa = ruta_relativa.parent
            carpeta_salida = ruta_base_salida / carpeta_relativa
            
            carpeta_salida.mkdir(parents=True, exist_ok=True)
            
            path_actual = str(archivo)
            path_salida_carpeta = str(carpeta_salida)
            
            lxf_to_json(path_actual, path_salida_carpeta)