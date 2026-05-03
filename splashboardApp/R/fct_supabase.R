#' supabase 
#'
#' @description A fct function
#'
#' @return The return value, if any, from executing the function.
#'
#' @noRd

obtener_competiciones <- function() {
  
  url_api <- paste0(Sys.getenv("SUPABASE_URL"), "/rest/v1/competiciones?select=*")
  
  peticion <- httr2::request(url_api) |> 
    httr2::req_headers(
      apikey = Sys.getenv("SUPABASE_KEY"),
      Authorization = paste("Bearer", Sys.getenv("SUPABASE_KEY"))
    )
  
  respuesta <- httr2::req_perform(peticion)
  datos_df <- httr2::resp_body_json(respuesta, simplifyVector = TRUE)
  
  return(datos_df)
}

buscar_nadadores_api <- function(nombre = NULL, apellidos = NULL, genero = NULL, nacimiento = NULL) {
  
  # 1. Preparamos la petición base a la tabla 'nadadores'
  req <- httr2::request(paste0(Sys.getenv("SUPABASE_URL"), "/rest/v1/nadadores")) |> 
    httr2::req_headers(
      apikey = Sys.getenv("SUPABASE_KEY"),
      Authorization = paste("Bearer", Sys.getenv("SUPABASE_KEY"))
    )
  
  # 2. Creamos la lista de parámetros
  # Añadimos 'limit = 50' para que la BBDD solo trabaje con los primeros 50 aciertos
  params <- list(
    select = "*",
    limit  = 50
  )
  
  # 3. Añadimos filtros dinámicos (usando tus nombres de columna actualizados)
  if (!is.null(nombre) && trimws(nombre) != "") {
    params$firstname <- paste0("ilike.*", trimws(nombre), "*")
  }
  
  if (!is.null(apellidos) && trimws(apellidos) != "") {
    params$lastname <- paste0("ilike.*", trimws(apellidos), "*")
  }
  
  if (!is.null(genero) && genero != "") {
    params$gender <- paste0("eq.", genero)
  }
  
  if (!is.na(nacimiento)) {
    params$birthyear <- paste0("eq.", nacimiento)
  }

  # 4. EJECUCIÓN
  # req_url_query se encarga de codificar espacios (como en apellidos compuestos)
  respuesta <- req |> 
    httr2::req_url_query(!!!params) |> 
    httr2::req_perform()
  
  # Extraemos el cuerpo de la respuesta
  datos_df <- httr2::resp_body_json(respuesta, simplifyVector = TRUE)
  
  # Si no hay resultados, devolvemos un dataframe vacío para no romper el lapply del server
  if (length(datos_df) == 0) return(data.frame())
  
  return(as.data.frame(datos_df))
}

obtener_top_marcas <- function(p_dist, p_estilo, p_gen = "", p_top = 50, p_inicio, p_fin, p_piscina) {
  
  req <- httr2::request(paste0(Sys.getenv("SUPABASE_URL"), "/rest/v1/resultados_individuales")) |> 
    httr2::req_headers(
      apikey = Sys.getenv("SUPABASE_KEY"),
      Authorization = paste("Bearer", Sys.getenv("SUPABASE_KEY"))
    )
  
  # 1. Modificamos el SELECT para traer la tabla competiciones
  params <- list(
    select = "id,event_date,reactiontime,swimtime,round,daytime,nadadores!inner(firstname,lastname,birthyear,gender),parciales(cumswimtime,parcial_swimtime,distance),competiciones!inner(course)",
    
    distance = paste0("eq.", p_dist),
    style = paste0("eq.", p_estilo),
    event_date = c(paste0("gte.", p_inicio), paste0("lte.", p_fin)),
    or = "(estado.is.null,estado.eq.\"\")",
    order = "swimtime.asc",
    limit = p_top
  )
  
  # 2. Añadimos los filtros de las tablas "joineadas"
  params$`competiciones.course` <- paste0("eq.", p_piscina)
  
  if (!is.null(p_gen) && p_gen != "") {
    params$`nadadores.gender` <- paste0("eq.", p_gen)
  }
  
  respuesta <- req |> 
    httr2::req_url_query(!!!params, .multi = "explode") |> 
    httr2::req_perform()
  
  datos_list <- httr2::resp_body_json(respuesta, simplifyVector = TRUE)
  
  if (length(datos_list) == 0 || nrow(datos_list) == 0) return(data.frame())
  
  # 3. TRANSFORMACIÓN Y LIMPIEZA (Ignoramos datos_list$competiciones aquí)
  df_final <- data.frame(
    name         = paste(datos_list$nadadores$firstname, datos_list$nadadores$lastname),
    birthyear    = datos_list$nadadores$birthyear,
    event_date   = datos_list$event_date,
    daytime      = datos_list$daytime,
    round        = datos_list$round,
    reactiontime = datos_list$reactiontime,
    swimtime     = datos_list$swimtime
  )
  
  df_final$parciales <- datos_list$parciales
  
  return(df_final)
}

# Convierte segundos (92.78) a formato natación (1:32.78)
formatear_tiempo_natacion <- function(segundos) {
  if (is.na(segundos) || segundos == 0) return("-")
  
  minutos <- as.integer(segundos %/% 60)
  secs <- segundos %% 60
  
  if (minutos > 0) {
    # Formato M:SS.hh
    return(sprintf("%d:%05.2f", minutos, secs))
  } else {
    # Formato SS.hh
    return(sprintf("%.2f", secs))
  }
}

#' Obtener datos específicos de competiciones
#' @noRd
obtener_datos_competiciones <- function() {
  # Definimos las columnas exactas que pediste
  columnas <- "name,city,course,timing,nation,pool_min_lane,pool_max_lane,start_date,end_date,latitud,longitud"
  
  url_api <- paste0(Sys.getenv("SUPABASE_URL"), "/rest/v1/competiciones?select=", columnas)
  
  peticion <- httr2::request(url_api) |> 
    httr2::req_headers(
      apikey = Sys.getenv("SUPABASE_KEY"),
      Authorization = paste("Bearer", Sys.getenv("SUPABASE_KEY"))
    )
  
  respuesta <- httr2::req_perform(peticion)
  datos_df <- httr2::resp_body_json(respuesta, simplifyVector = TRUE)
  
  return(datos_df)
}
#' Obtener información básica de un nadador
#' @param athleteid El ID del atleta
#' @return Un dataframe con los datos del nadador
#' @noRd
obtener_info_nadador <- function(athleteid) {
  req <- httr2::request(paste0(Sys.getenv("SUPABASE_URL"), "/rest/v1/nadadores")) |> 
    httr2::req_headers(
      apikey = Sys.getenv("SUPABASE_KEY"),
      Authorization = paste("Bearer", Sys.getenv("SUPABASE_KEY"))
    )
  
  params <- list(
    select = "*",
    athleteid = paste0("eq.", athleteid)
  )
  
  respuesta <- req |> 
    httr2::req_url_query(!!!params) |> 
    httr2::req_perform()
  
  datos_df <- httr2::resp_body_json(respuesta, simplifyVector = TRUE)
  if (length(datos_df) == 0) return(data.frame())
  return(as.data.frame(datos_df))
}

#' Obtener las competiciones a las que ha asistido un nadador
#' @param athleteid El ID del atleta
#' @return Un dataframe con las competiciones
#' @noRd
obtener_competiciones_nadador <- function(athleteid) {
  req <- httr2::request(paste0(Sys.getenv("SUPABASE_URL"), "/rest/v1/resultados_individuales")) |> 
    httr2::req_headers(
      apikey = Sys.getenv("SUPABASE_KEY"),
      Authorization = paste("Bearer", Sys.getenv("SUPABASE_KEY"))
    )
  
  params <- list(
    select = "competiciones!inner(id,name,city,start_date,course)",
    athleteid = paste0("eq.", athleteid)
  )
  
  respuesta <- req |> 
    httr2::req_url_query(!!!params) |> 
    httr2::req_perform()
  
  datos <- httr2::resp_body_json(respuesta, simplifyVector = TRUE)
  if (length(datos) == 0) return(data.frame())
  
  df <- as.data.frame(datos$competiciones)
  df <- unique(df)
  if ("start_date" %in% names(df)) {
    df <- df[order(df$start_date, decreasing = TRUE), ]
  }
  return(df)
}


obtener_mejores_tiempos_nadador <- function(athleteid) {
  req <- httr2::request(paste0(Sys.getenv("SUPABASE_URL"), "/rest/v1/resultados_individuales")) |> 
    httr2::req_headers(
      apikey = Sys.getenv("SUPABASE_KEY"),
      Authorization = paste("Bearer", Sys.getenv("SUPABASE_KEY"))
    )
  
  params <- list(
    select = "distance,style,swimtime,competiciones!inner(course),event_date",
    athleteid = paste0("eq.", athleteid),
    swimtime = "not.is.null",
    order = "swimtime.asc"
  )
  
  respuesta <- req |> 
    httr2::req_url_query(!!!params) |> 
    httr2::req_perform()
  
  datos <- httr2::resp_body_json(respuesta, simplifyVector = TRUE)
  if (length(datos) == 0) return(data.frame())
  
  df <- data.frame(
    distance = datos$distance,
    style = datos$style,
    swimtime = datos$swimtime,
    course = datos$competiciones$course,
    event_date = datos$event_date
  )
  
  # Nos quedamos con el mejor tiempo (el menor) para cada combinación
  df <- df[!duplicated(df[, c("distance", "style", "course")]), ]
  df <- df[order(df$style, df$distance), ]
  return(df)
}


obtener_top_fina_swimseries <- function(id_competicion = 40) {
  
  req <- httr2::request(paste0(Sys.getenv("SUPABASE_URL"), "/rest/v1/resultados_individuales")) |> 
    httr2::req_headers(
      apikey = Sys.getenv("SUPABASE_KEY"),
      Authorization = paste("Bearer", Sys.getenv("SUPABASE_KEY"))
    )
  
  # Cambiamos "puntos_fina" por "points" tal y como está en tu esquema
  params <- list(
    select = "athleteid,points,nadadores!inner(firstname,lastname,gender)",
    competicion_id = paste0("eq.", id_competicion),
    points = "gt.0"
  )
  
  respuesta <- req |> 
    httr2::req_url_query(!!!params) |> 
    httr2::req_perform()
  
  datos_list <- httr2::resp_body_json(respuesta, simplifyVector = TRUE)
  
  if (length(datos_list) == 0 || nrow(datos_list) == 0) return(data.frame())
  
  # Aplanamos la lista en un dataframe limpio
  df_raw <- data.frame(
    athleteid = datos_list$athleteid,
    points    = as.numeric(datos_list$points),
    firstname = datos_list$nadadores$firstname,
    lastname  = datos_list$nadadores$lastname,
    gender    = datos_list$nadadores$gender
  )
  
  # Agrupamos y calculamos la media
  df_final <- df_raw |>
    dplyr::group_by(athleteid, firstname, lastname, gender) |>
    dplyr::summarise(
      media_fina = mean(points, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      nombre_completo = paste(firstname, lastname),
      media_fina = round(media_fina, 1)
    ) |>
    dplyr::arrange(dplyr::desc(media_fina))
  
  return(df_final)
}


#' Obtener datos de españoles en Lublin (ID 38)
#' @export
obtener_datos_lublin_esp <- function() {
  
  req <- httr2::request(paste0(Sys.getenv("SUPABASE_URL"), "/rest/v1/resultados_individuales")) |> 
    httr2::req_headers(
      apikey = Sys.getenv("SUPABASE_KEY"),
      Authorization = paste("Bearer", Sys.getenv("SUPABASE_KEY"))
    )
  
  # Filtramos por Lublin (38) y el código de club nacional 'ESP'
  params <- list(
    select = "points,place,round,nadadores!inner(firstname,lastname,gender)",
    competicion_id = "eq.38",
    club_code = "eq.ESP"
  )
  
  respuesta <- req |> 
    httr2::req_url_query(!!!params) |> 
    httr2::req_perform()
  
  datos_list <- httr2::resp_body_json(respuesta, simplifyVector = TRUE)
  
  if (length(datos_list) == 0 || nrow(datos_list) == 0) return(data.frame())
  
  # Estructuramos el dataframe
  df <- data.frame(
    points = as.numeric(datos_list$points),
    place = as.numeric(datos_list$place),
    round = datos_list$round,
    gender = datos_list$nadadores$gender,
    fullname = paste(datos_list$nadadores$firstname, datos_list$nadadores$lastname)
  )
  
  return(df)
}

obtener_datos_reaccion_rt <- function() {
  
  req <- httr2::request(paste0(Sys.getenv("SUPABASE_URL"), "/rest/v1/resultados_individuales")) |> 
    httr2::req_headers(
      apikey = Sys.getenv("SUPABASE_KEY"),
      Authorization = paste("Bearer", Sys.getenv("SUPABASE_KEY"))
    )
  
  # Pedimos el tiempo de reacción, el estilo y el género mediante el JOIN de athleteid[cite: 1]
  # Filtramos tiempos mayores a 0.4s para evitar salidas nulas/falsas y limitamos a una muestra grande.
  params <- list(
    select = "reactiontime,style,nadadores!inner(gender)",
    reactiontime = "gt.0.4",
    limit = 10000 
  )
  
  respuesta <- req |> 
    httr2::req_url_query(!!!params) |> 
    httr2::req_perform()
  
  datos_list <- httr2::resp_body_json(respuesta, simplifyVector = TRUE)
  
  if (length(datos_list) == 0 || nrow(datos_list) == 0) return(data.frame())
  
  df <- data.frame(
    reactiontime = as.numeric(datos_list$reactiontime),
    style = toupper(datos_list$style),
    gender = datos_list$nadadores$gender
  )
  
  # Creamos la variable agrupada: Espalda vs Resto
  df$grupo_estilo <- ifelse(df$style == "BACK", "Espalda", "Resto de Estilos")
  
  return(df)
}

#' Obtener Top 50 marcas por año para el Ciclo Olímpico
#' @param distancia_in Distancia de la prueba (ej: 100)
#' @param estilo_in Estilo de la prueba (ej: 'FREE')
#' @param genero_in Género (ej: 'M' o 'F')
#' @export
obtener_marcas_ciclo_olimpico <- function(distancia_in, estilo_in, genero_in) {
  
  req <- httr2::request(paste0(Sys.getenv("SUPABASE_URL"), "/rest/v1/resultados_individuales")) |> 
    httr2::req_headers(
      apikey = Sys.getenv("SUPABASE_KEY"),
      Authorization = paste("Bearer", Sys.getenv("SUPABASE_KEY"))
    )
  
  # Filtramos directamente en la base de datos por los parámetros del usuario
  # Elevamos el limit a 15000 para burlar el corte por defecto y asegurar que bajan todos los años
  params <- list(
    select = "swimtime,competiciones!inner(start_date,course),nadadores!inner(gender)",
    "competiciones.course" = "eq.LCM",
    "competiciones.start_date" = "gte.2021-01-01",
    distance = paste0("eq.", distancia_in),
    style = paste0("eq.", estilo_in),
    "nadadores.gender" = paste0("eq.", genero_in),
    limit = 15000 
  )
  
  respuesta <- req |> 
    httr2::req_url_query(!!!params) |> 
    httr2::req_perform()
  
  datos_list <- httr2::resp_body_json(respuesta, simplifyVector = TRUE)
  
  if (length(datos_list) == 0 || nrow(datos_list) == 0) return(data.frame())
  
  # Aplanamos los datos esenciales
  df <- data.frame(
    swimtime = as.numeric(datos_list$swimtime),
    fecha = as.Date(datos_list$competiciones$start_date)
  )
  
  # Extraemos el año y extraemos estrictamente el TOP 50 por año
  df$year <- format(df$fecha, "%Y")
  
  df_top50 <- df |> 
    dplyr::filter(year <= "2024", !is.na(swimtime), swimtime > 10) |> 
    dplyr::group_by(year) |> 
    dplyr::arrange(swimtime) |> 
    dplyr::slice_head(n = 50) |>  # Nos quedamos con los 50 más rápidos por año
    dplyr::ungroup()
  
  return(df_top50)
}


obtener_datos_doha <- function() {
  
  req <- httr2::request(paste0(Sys.getenv("SUPABASE_URL"), "/rest/v1/resultados_individuales")) |> 
    httr2::req_headers(
      apikey = Sys.getenv("SUPABASE_KEY"),
      Authorization = paste("Bearer", Sys.getenv("SUPABASE_KEY"))
    )
  
  # Pedimos puntos, puesto y ronda de la competición 19 (Doha)
  params <- list(
    select = "points,place,round,style,distance",
    competicion_id = "eq.19",
    limit = 15000 
  )
  
  respuesta <- req |> 
    httr2::req_url_query(!!!params) |> 
    httr2::req_perform()
  
  datos_list <- httr2::resp_body_json(respuesta, simplifyVector = TRUE)
  
  if (length(datos_list) == 0 || nrow(datos_list) == 0) return(data.frame())
  
  
  df <- data.frame(
    points = as.numeric(datos_list$points),
    place = as.numeric(datos_list$place),
    round = datos_list$round,
    style = datos_list$style
  )
  
  return(df)
}