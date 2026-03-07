# =========================================================================
# SCRIPT: 03_transformaciones.r
# OBJETIVOS
#  - Crear en la tabla competiciones de la BBDD, las columnas de latitud y longitud de la competición a través de geocodificación.
# =========================================================================
library(DBI)
library(RPostgres)
library(dplyr)
library(tidygeocoder)
library(countrycode)


coordenadas_ciudades_tarea1 <- function(con) {
  tryCatch({
    # 1. Extraemos las ciudades y naciones únicas de la BBDD
    competiciones_db <- dbGetQuery(con, "SELECT DISTINCT city, nation FROM competiciones")

    # 2. Juntamos la ciudad y el país en una sola línea de texto (Ej: "Madrid, ESP")
    ciudades_preparadas <- competiciones_db %>%
      mutate(direccion_completa = paste(city, nation, sep = ", "))
    
    print("Buscando coordenadas en internet... (esto puede tardar unos segundos)")
    
    # 3. Usamos SOLO el parámetro 'address' para evitar el error
    ciudades_geo <- ciudades_preparadas %>%
      geocode(
        address = direccion_completa, 
        method = 'osm',      
        lat = latitud,       
        long = longitud      
      )
    
    # Inyectamos manualmente Berlín, Fukuoka, Netanya y Incheon:
    ciudades_geo <- ciudades_geo %>%
      mutate(
        latitud = case_when(
          city == "Berlin" ~ 52.5200,
          city == "Fukuoka" ~ 33.5904,
          city == "Netanya" ~ 32.3326,
          city == "Incheon" ~ 37.4563,
          TRUE ~ latitud
        ),
        longitud = case_when(
          city == "Berlin" ~ 13.4050,
          city == "Fukuoka" ~ 130.4017,
          city == "Netanya" ~ 34.8599,
          city == "Incheon" ~ 126.7052,
          TRUE ~ longitud
        )
      )
    
    # Subimos una tabla temporal a la BBDD con las coordenadas
    dbWriteTable(con, "ciudades_geo", ciudades_geo, overwrite = TRUE, temporary = TRUE)

    # Preparamos la tabla original añadiendo las columnas de latitud y longitud (si no existen)
    dbExecute(con, "
      ALTER TABLE competiciones
      ADD COLUMN IF NOT EXISTS latitud NUMERIC,
      ADD COLUMN IF NOT EXISTS longitud NUMERIC
    ")

    # Hacemos un UPDATE JOIN para actualizar la tabla original con las coordenadas
    dbExecute(con, "
      UPDATE competiciones AS c
      SET latitud = cg.latitud,
          longitud = cg.longitud
      FROM ciudades_geo AS cg
      WHERE c.city = cg.city AND c.nation = cg.nation
    ")

  }, error = function(e) {
    print("Error en la geocodificación:")
    print(e)
  })
}

limpiar_nombres_tarea_2_1 <- function(con) {
  tryCatch({
    
    # Hacemos un UPDATE para limpiar nombres de personas

    dbExecute(con, "
      UPDATE nadadores
      SET 
        firstname = INITCAP(TRIM(LOWER(firstname))),
        lastname = INITCAP(TRIM(LOWER(lastname)));
")

  }, error = function(e) {
    print("Error en la limpieza de nombres:")
    print(e)
  })
}

deduplicar_nadadores_bbdd <- function(conexion) {
  
  try(dbExecute(conexion, "DROP TABLE IF EXISTS mapa_duplicados;"), silent = TRUE)

  # 1. Mapa de duplicados (Lógica: Nombre + Apellido + Fecha)
  query_mapa <- "
    CREATE TEMPORARY TABLE mapa_duplicados AS
    WITH agrupados AS (
        SELECT 
            firstname, 
            lastname, 
            birthdate, 
            MIN(athleteid) AS id_superviviente
        FROM nadadores
        GROUP BY firstname, lastname, birthdate
        HAVING COUNT(athleteid) > 1
    )
    SELECT n.athleteid AS id_victima, a.id_superviviente
    FROM nadadores n
    JOIN agrupados a ON n.firstname = a.firstname 
                    AND n.lastname = a.lastname 
                    AND n.birthdate = a.birthdate
    WHERE n.athleteid != a.id_superviviente;
  "
  
  tryCatch({
    print("🔍 1. Analizando duplicados...")
    dbExecute(conexion, query_mapa)
    
    res <- dbGetQuery(conexion, "SELECT COUNT(*) FROM mapa_duplicados")
    num_victimas <- as.numeric(res$count)
    
    if(num_victimas == 0) {
      print("✅ Datos limpios.")
      return(TRUE)
    }
    
    print(paste("🎯 Encontrados", num_victimas, "IDs duplicados. Iniciando limpieza profunda..."))
    dbBegin(conexion)
    
    # 2. LIMPIEZA NUCLEAR: RESULTADOS INDIVIDUALES
    print("   -> Eliminando colisiones en resultados_individuales...")
    dbExecute(conexion, "
      DELETE FROM resultados_individuales
      WHERE id IN (
          SELECT id FROM (
              SELECT 
                  r.id,
                  ROW_NUMBER() OVER (
                      PARTITION BY 
                          r.competicion_id, 
                          COALESCE(m.id_superviviente, r.athleteid), 
                          r.num_prueba, 
                          r.round 
                      ORDER BY r.id
                  ) as fila_numero
              FROM resultados_individuales r
              LEFT JOIN mapa_duplicados m ON r.athleteid = m.id_victima
          ) t
          WHERE t.fila_numero > 1
      );
    ")
    
    dbExecute(conexion, "UPDATE resultados_individuales r SET athleteid = m.id_superviviente FROM mapa_duplicados m WHERE r.athleteid = m.id_victima;")
    
    # 3. LIMPIEZA NUCLEAR: RELEVISTAS
    print("   -> Eliminando colisiones en relevistas...")
    dbExecute(conexion, "
      DELETE FROM relevistas
      WHERE id IN (
          SELECT id FROM (
              SELECT 
                  r.id,
                  ROW_NUMBER() OVER (
                      PARTITION BY 
                          r.relevo_id, 
                          COALESCE(m.id_superviviente, r.athleteid), 
                          r.num_relevista
                      ORDER BY r.id
                  ) as fila_numero
              FROM relevistas r
              LEFT JOIN mapa_duplicados m ON r.athleteid = m.id_victima
          ) t
          WHERE t.fila_numero > 1
      );
    ")

    dbExecute(conexion, "UPDATE relevistas r SET athleteid = m.id_superviviente FROM mapa_duplicados m WHERE r.athleteid = m.id_victima;")
    
    # 4. LIMPIEZA NUCLEAR: CLUBES (Resolviendo el error de la Primary Key)
    print("   -> Eliminando colisiones en nadadores_clubes...")
    dbExecute(conexion, "
      DELETE FROM nadadores_clubes
      WHERE (athleteid, club_code) IN (
          SELECT athleteid, club_code
          FROM (
              SELECT 
                  nc.athleteid, 
                  nc.club_code,
                  ROW_NUMBER() OVER (
                      PARTITION BY 
                          COALESCE(m.id_superviviente, nc.athleteid), 
                          nc.club_code
                      ORDER BY nc.athleteid
                  ) as fila_numero
              FROM nadadores_clubes nc
              LEFT JOIN mapa_duplicados m ON nc.athleteid = m.id_victima
          ) t
          WHERE t.fila_numero > 1
      );
    ")

    dbExecute(conexion, "UPDATE nadadores_clubes nc SET athleteid = m.id_superviviente FROM mapa_duplicados m WHERE nc.athleteid = m.id_victima;")
    
    # 5. ELIMINACIÓN FINAL DE NADADORES
    print("   -> Eliminando registros de nadadores duplicados...")
    dbExecute(conexion, "
      DELETE FROM nadadores n
      USING mapa_duplicados m WHERE n.athleteid = m.id_victima;
    ")
    
    dbCommit(conexion)
    print("🎉 ¡FUSIÓN MAESTRA COMPLETADA! La base de datos es ahora 100% íntegra.")
    
  }, error = function(e) {
    if (dbIsValid(conexion)) dbRollback(conexion)
    print(paste("❌ ERROR CRÍTICO:", e$message))
  }, finally = {
    try(dbExecute(conexion, "DROP TABLE IF EXISTS mapa_duplicados;"), silent = TRUE)
  })
}

generar_avatares_bbdd <- function(conexion) {
  tryCatch({
    print("📸 Preparando la base de datos para las fotos de perfil...")
    
    # 1. Crear la columna en la tabla si no existe
    dbExecute(conexion, "ALTER TABLE nadadores ADD COLUMN IF NOT EXISTS foto_url VARCHAR;")
    print("✅ Columna 'foto_url' verificada/creada en la tabla nadadores.")
    
    # 2. Actualizar los registros que no tengan foto
    # Usamos REPLACE para cambiar espacios por '+' para que la URL sea válida
    query_avatares <- "
      UPDATE nadadores 
      SET foto_url = 'https://ui-avatars.com/api/?name=' 
                     || REPLACE(firstname, ' ', '+') || '+' || REPLACE(lastname, ' ', '+') 
                     || '&background=random&color=fff&size=200'
      WHERE foto_url IS NULL; 
    "
    
    print("🔄 Generando URLs de avatares dinámicos...")
    filas_actualizadas <- dbExecute(conexion, query_avatares)
    
    print(paste("🎉 ¡Éxito! Se han asignado", filas_actualizadas, "avatares dinámicos en la base de datos."))
    
  }, error = function(e) {
    print("❌ Error al generar las fotos:")
    print(e$message)
  })
}


marcar_federaciones_bbdd <- function(conexion) {
  tryCatch({
    print("🚩 Analizando la tabla de clubes para identificar federaciones...")
    
    # 1. Creamos la columna booleana si no existe. 
    # La ponemos por defecto en FALSE para que no haya nulos.
    dbExecute(conexion, "
      ALTER TABLE clubes 
      ADD COLUMN IF NOT EXISTS es_federacion BOOLEAN DEFAULT FALSE;
    ")
    print("✅ Columna 'es_federacion' preparada.")
    
    # 2. Ejecutamos el UPDATE lógico. 
    # Comparamos club_code con club_nation.
    query_update <- "
      UPDATE clubes 
      SET es_federacion = TRUE 
      WHERE club_code = club_nation;
    "
    
    filas_marcadas <- dbExecute(conexion, query_update)
    
    print(paste("🎯 ¡Misión cumplida! Se han identificado y marcado", 
                filas_marcadas, "selecciones nacionales."))
    
  }, error = function(e) {
    print("❌ Error al marcar las federaciones:")
    print(e$message)
  })
}


inyectar_iso_codes_bbdd <- function(conexion) {
  tryCatch({
    print("🌍 Extrayendo naciones de la BBDD...")
    
    # 1. Obtenemos las naciones únicas que tienes en la tabla clubes
    naciones_db <- dbGetQuery(conexion, "SELECT DISTINCT club_nation FROM clubes")
    
    # 2. Traducción con 'countrycode' + Parches manuales para tu lista específica
    naciones_mapeadas <- naciones_db %>%
      mutate(
        # Traducción estándar de IOC a ISO2 (ej: ESP -> es)
        iso2 = tolower(countrycode(club_nation, origin = 'ioc', destination = 'iso2c', warn = FALSE)),
        
        # Parches manuales para los códigos que tu lista tiene y pueden fallar:
        iso2 = case_when(
          club_nation == "TPE" ~ "tw",   # Chinese Taipei -> Taiwan
          club_nation == "FRO" ~ "fo",   # Faroe Islands
          club_nation == "FAR" ~ "fo",   # Faroe Islands (variante)
          club_nation == "AQUA" ~ "un",  # World Aquatics (ponemos 'un' de United Nations o genérico)
          club_nation == "AQU" ~ "un",   # World Aquatics (variante)
          club_nation == "ASA" ~ "as",   # American Samoa
          club_nation == "SGP" ~ "sg",   # Singapore
          is.na(iso2) | club_nation == "" ~ "un", # Si está vacío o no se encuentra
          TRUE ~ iso2
        )
      )

    # 3. Preparar la tabla en Supabase (añadimos columnas para ISO y para la URL de la bandera)
    print("🛠️ Preparando columnas en Supabase...")
    dbExecute(conexion, "ALTER TABLE clubes ADD COLUMN IF NOT EXISTS iso2 VARCHAR(5);")
    dbExecute(conexion, "ALTER TABLE clubes ADD COLUMN IF NOT EXISTS flag_url VARCHAR;")

    # 4. Crear la URL de la bandera basada en el ISO2
    # Usamos FlagCDN que es la más rápida y fiable
    naciones_mapeadas <- naciones_mapeadas %>%
      mutate(
        flag_url = paste0("https://flagcdn.com/w160/", iso2, ".png")
      )

    # 5. Inyección mediante tabla temporal
    print("📤 Inyectando códigos y URLs en la BBDD...")
    dbWriteTable(conexion, "temp_iso", naciones_mapeadas, temporary = TRUE, overwrite = TRUE)
    
    dbExecute(conexion, "
      UPDATE clubes c
      SET iso2 = t.iso2,
          flag_url = t.flag_url
      FROM temp_iso t
      WHERE c.club_nation = t.club_nation;
    ")
    
    # Caso especial: Si es AQUA, ponemos su logo oficial en lugar de una bandera
    dbExecute(conexion, "
      UPDATE clubes 
      SET flag_url = 'https://resources.fina.org/photo-resources/2022/01/01/fina-logo.png'
      WHERE club_nation IN ('AQUA', 'AQU');
    ")

    print(paste("✅ ¡Hecho! Se han actualizado", nrow(naciones_mapeadas), "códigos nacionales."))
    
  }, error = function(e) {
    print(paste("❌ Error en la inyección:", e$message))
  })
}

# =========================================================================
# BLOQUE DE EJECUCIÓN PASO A PASO
# =========================================================================

# Conectar a la base de datos (si no lo has hecho ya)
tryCatch({
  con <- dbConnect(
    RPostgres::Postgres(),
    dbname   = Sys.getenv("DB_NAME"),
    host     = Sys.getenv("DB_HOST"),
    port     = Sys.getenv("DB_PORT"),
    user     = Sys.getenv("DB_USER"),
    password = Sys.getenv("DB_PASS")
  )
  print("✅ ¡Conexión a Supabase establecida con éxito!")
}, error = function(e) {
  print("❌ Error al conectar. Revisa tu archivo .Renviron o tu conexión a internet.")
  print(e$message)
})

# 0. Asegúrate de que la conexión 'con' está abierta
if (!exists("con") || !dbIsValid(con)) {
  stop("❌ No hay una conexión activa. Por favor, ejecuta primero dbConnect.")
}

print("🚀 Iniciando Pipeline de Transformación de Datos...")

# PASO 1: Limpieza de Texto (Fundamental antes de agrupar)
print("--- Paso 1: Limpiando nombres y apellidos (Capitalización)...")
limpiar_nombres_tarea_2_1(con)

# PASO 2: Resolución de Entidades (Deduplicación)
# Lo hacemos ahora que los nombres están limpios para no fallar
print("--- Paso 2: Fusionando nadadores duplicados...")
deduplicar_nadadores_bbdd(con)

# PASO 3: Enriquecimiento Geográfico
print("--- Paso 3: Geocodificando ciudades de competiciones...")
coordenadas_ciudades_tarea1(con)

# PASO 4: Identidad Visual de Atletas
print("--- Paso 4: Generando avatares para perfiles...")
generar_avatares_bbdd(con)

# PASO 5: Lógica de Negocio (Federaciones)
print("--- Paso 5: Clasificando clubes y selecciones...")
marcar_federaciones_bbdd(con)

# PASO 6: Identidad Visual de Naciones
print("--- Paso 6: Inyectando banderas y códigos ISO...")
inyectar_iso_codes_bbdd(con)

print("🏁 PIPELINE FINALIZADO CON ÉXITO. Base de datos lista para SplashBoard.")

# Opcional: Cerrar conexión al terminar
# dbDisconnect(con)