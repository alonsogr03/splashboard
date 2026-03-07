import os
import json
import logging
from pathlib import Path
from dotenv import load_dotenv
from supabase import create_client, Client

# Configurar el nivel de detalle de la terminal
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

# ==========================================
# 0. CONEXIÓN A SUPABASE
# ==========================================
# Cargar variables del archivo .Renviron
load_dotenv(".Renviron")
url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_KEY")

if not url or not key:
    raise ValueError("⚠️ Faltan SUPABASE_URL o SUPABASE_KEY en .Renviron. Asegúrate de usar la service_role key.")

# Iniciar el cliente
supabase: Client = create_client(url, key)

def procesar_competicion(ruta_json: Path):
    logging.info(f"🚀 Iniciando procesamiento de: {ruta_json.name}")
    
    with open(ruta_json, 'r', encoding='utf-8') as f:
        datos = json.load(f)
        
    # ==========================================
    # 1. CLUBES (Batch)
    # ==========================================
    clubes_dict = {}
    for res in datos.get("individual_results", []) + datos.get("relay_results", []):
        code = res.get("club_code")
        if code and code not in clubes_dict:
            clubes_dict[code] = {
                "club_code": code,
                "club_nation": res.get("club_nation"),
                "club_region": res.get("club_region"),
                "club_name": res.get("club_name"),
                "club_shortname": res.get("club_shortname"),
                "es_federacion": False
            }
            
    if clubes_dict:
        supabase.table("clubes").upsert(list(clubes_dict.values())).execute()
        logging.info(f"✅ Upsert de {len(clubes_dict)} clubes completado.")

    # ==========================================
    # 2. NADADORES (Batch)
    # ==========================================
    nadadores_dict = {}
    
    # Extraer de resultados individuales
    for res in datos.get("individual_results", []):
        ath_id = res.get("athleteid")
        if ath_id and ath_id not in nadadores_dict:
            nadadores_dict[ath_id] = {
                "athleteid": ath_id,
                "firstname": res.get("firstname"),
                "lastname": res.get("lastname"),
                "birthdate": res.get("birthdate") or None,
                "birthyear": res.get("birthyear"),
                "gender": res.get("gender"),
                "nation": res.get("nation")
            }
            
    # Extraer de relevistas
    for relevo in datos.get("relay_results", []):
        for relevista in relevo.get("relevistas", []):
            ath_id = relevista.get("athleteid")
            if ath_id and ath_id not in nadadores_dict:
                nadadores_dict[ath_id] = {
                    "athleteid": ath_id,
                    "firstname": relevista.get("firstname"),
                    "lastname": relevista.get("lastname"),
                    "birthdate": relevista.get("birthdate") or None,
                    "birthyear": relevista.get("birthyear"),
                    "gender": relevista.get("gender"),
                    "nation": relevista.get("nation")
                }

    if nadadores_dict:
        supabase.table("nadadores").upsert(list(nadadores_dict.values())).execute()
        logging.info(f"✅ Upsert de {len(nadadores_dict)} nadadores completado.")

    # ==========================================
    # 3. NADADORES_CLUBES (Batch)
    # ==========================================
    nadadores_clubes_set = set()
    for res in datos.get("individual_results", []):
        if res.get("athleteid") and res.get("club_code"):
            nadadores_clubes_set.add((res["athleteid"], res["club_code"]))
            
    if nadadores_clubes_set:
        data_nc = [{"athleteid": a, "club_code": c} for a, c in nadadores_clubes_set]
        supabase.table("nadadores_clubes").upsert(data_nc).execute()

    # ==========================================
    # 4. COMPETICIÓN
    # ==========================================
    competicion_data = {
        "name": datos.get("name"),
        "city": datos.get("city"),
        "course": datos.get("course"),
        "timing": datos.get("timing"),
        "nation": datos.get("nation"),
        "pool_min_lane": datos.get("pool_dimensions", {}).get("min_lane") if datos.get("pool_dimensions") else None,
        "pool_max_lane": datos.get("pool_dimensions", {}).get("max_lane") if datos.get("pool_dimensions") else None,
        "start_date": datos.get("start_date") or None,
        "end_date": datos.get("end_date") or None
    }
    
    # Usamos la restricción UNIQUE para obtener el ID sin duplicar
    res_comp = supabase.table("competiciones").upsert(
        competicion_data, 
        on_conflict="name,city,start_date"
    ).execute()
    
    comp_id = res_comp.data[0]['id']
    logging.info(f"✅ Competición registrada/actualizada (BBDD ID: {comp_id})")

    # ==========================================
    # 5. RESULTADOS INDIVIDUALES Y PARCIALES
    # ==========================================
    resultados_data = []
    for res in datos.get("individual_results", []):
        resultados_data.append({
            "competicion_id": comp_id,
            "athleteid": res.get("athleteid"),
            "club_code": res.get("club_code"),
            "place": res.get("place") if res.get("place") != -1 else None,
            "orden": res.get("order"),
            "daytime": res.get("daytime"),
            "num_prueba": res.get("num_prueba"),
            "round": res.get("round"),
            "style": res.get("style"),
            "distance": res.get("distance"),
            "event_date": res.get("date") or None,
            "heat": res.get("heat"),
            "lane": res.get("lane"),
            "points": res.get("points"),
            "reactiontime": res.get("reactiontime"),
            "swimtime": res.get("swimtime"),
            "entry_swimtime": res.get("entrytime"),
            "entry_course": res.get("entrycourse"),
            "estado": res.get("status")
        })

    if resultados_data:
        # Subimos todos los resultados individuales de golpe
        res_indiv = supabase.table("resultados_individuales").upsert(
            resultados_data, on_conflict="competicion_id,athleteid,num_prueba,round"
        ).execute()
        logging.info(f"✅ Insertados {len(resultados_data)} resultados individuales.")

        # Mapear los IDs devueltos para asignar los parciales
        mapa_ids = {(r["athleteid"], r["num_prueba"], r["round"]): r["id"] for r in res_indiv.data}

        splits_batch = []
        for res in datos.get("individual_results", []):
            splits = res.get("splits") or []
            if splits:
                db_id = mapa_ids.get((res.get("athleteid"), res.get("num_prueba"), res.get("round")))
                if db_id:
                    for sp in splits:
                        splits_batch.append({
                            "resultado_indiv_id": db_id,
                            "distance": sp.get("distance"),
                            "cumswimtime": sp.get("swimtime"),
                            "parcial_swimtime": sp.get("parcialswimtime"),
                            "parcial_distance": sp.get("parcial_distancia"),
                            "leg_time": None
                        })
                        
        if splits_batch:
            supabase.table("parciales").insert(splits_batch).execute() 
            logging.info(f"✅ Insertados {len(splits_batch)} tiempos parciales individuales.")

    # ==========================================
    # 6. RELEVOS Y SUS PARCIALES (100% EN BLOQUE)
    # ==========================================
    relevos_data = []
    for rel in datos.get("relay_results", []):
        relevos_data.append({
            "competicion_id": comp_id,
            "club_code": rel.get("club_code"),
            "place": rel.get("place") if rel.get("place") != -1 else None,
            "orden": rel.get("order"),
            "daytime": rel.get("daytime"),
            "num_prueba": rel.get("num_prueba"),
            "round": rel.get("round"),
            "style": rel.get("style"),
            "distance": rel.get("distance"),
            "gender": rel.get("gender"),
            "event_date": rel.get("date") or None,
            "heat": rel.get("heat"),
            "lane": rel.get("lane"),
            "points": rel.get("points"),
            "swimtime": rel.get("swimtime"),
            "entry_swimtime": rel.get("entrytime"),
            "entry_course": rel.get("entrycourse"),
            "estado": rel.get("status")
        })

    if relevos_data:
        # 6.1 Subir los equipos (Relevos) en bloque
        res_rel = supabase.table("resultados_relevos").upsert(
            relevos_data, on_conflict="competicion_id,club_code,num_prueba,round"
        ).execute()
        logging.info(f"✅ Insertados {len(relevos_data)} equipos de relevos.")

        # Mapeamos los IDs de los equipos (club, num_prueba, round -> ID en BBDD)
        mapa_relevos_ids = {(r["club_code"], r["num_prueba"], r["round"]): r["id"] for r in res_rel.data}
        
        # 6.2 Preparar los Relevistas (Nadadores) en bloque
        relevistas_data = []
        for rel in datos.get("relay_results", []):
            rel_db_id = mapa_relevos_ids.get((rel.get("club_code"), rel.get("num_prueba"), rel.get("round")))
            if rel_db_id:
                for relevista in rel.get("relevistas", []):
                    relevistas_data.append({
                        "relevo_id": rel_db_id, 
                        "athleteid": relevista.get("athleteid"),
                        "num_relevista": relevista.get("num_relevista"),
                        "reactiontime": relevista.get("reactiontime"), 
                        "leg_time": relevista.get("leg_time")
                    })
                    
        if relevistas_data:
            # Subir todos los relevistas de golpe
            res_relevistas = supabase.table("relevistas").upsert(
                relevistas_data, on_conflict="relevo_id,num_relevista"
            ).execute()
            
            # Mapeamos los IDs de los relevistas (relevo_id, num_relevista -> ID en BBDD)
            mapa_relevistas_ids = {(r["relevo_id"], r["num_relevista"]): r["id"] for r in res_relevistas.data}
            
            # 6.3 Preparar los parciales de los relevistas en bloque
            splits_relevistas_batch = []
            for rel in datos.get("relay_results", []):
                rel_db_id = mapa_relevos_ids.get((rel.get("club_code"), rel.get("num_prueba"), rel.get("round")))
                if rel_db_id:
                    for relevista in rel.get("relevistas", []):
                        relevista_db_id = mapa_relevistas_ids.get((rel_db_id, relevista.get("num_relevista")))
                        if relevista_db_id:
                            splits_relevista = relevista.get("splits") or []
                            for sp in splits_relevista:
                                splits_relevistas_batch.append({
                                    "relevista_id": relevista_db_id, 
                                    "distance": sp.get("distance"),
                                    "cumswimtime": sp.get("swimtime"), 
                                    "parcial_swimtime": sp.get("parcialswimtime"),
                                    "parcial_distance": sp.get("parcial_distancia"),
                                    "leg_time": sp.get("leg_time")
                                })
            
            if splits_relevistas_batch:
                # Subir parciales de los relevistas de golpe
                supabase.table("parciales").insert(splits_relevistas_batch).execute()
                logging.info(f"✅ Insertados {len(splits_relevistas_batch)} parciales de relevistas en bloque.")

    logging.info(f"🏁 ¡Competición procesada y guardada con éxito!\n" + "-"*40)


if __name__ == '__main__':
    # Ruta donde caen los JSON procesados
    ruta_base = Path("data/processed/")
    
    # Buscar recursivamente todos los archivos .json
    archivos_json = list(ruta_base.rglob('*.json'))
    
    if not archivos_json:
        logging.warning("⚠️ No se han encontrado archivos JSON en la carpeta data/processed/")
    else:
        logging.info(f"📦 Se han encontrado {len(archivos_json)} competiciones para subir a Supabase.")
        
        # Bucle mágico que procesa todos los archivos
        for archivo in archivos_json:
            try:
                procesar_competicion(archivo)
            except Exception as e:
                logging.error(f"❌ Error crítico procesando {archivo.name}: {e}")
                
        logging.info("🎉 ¡INGESTA FINALIZADA! Tu base de datos está lista para conectar con Shiny.")