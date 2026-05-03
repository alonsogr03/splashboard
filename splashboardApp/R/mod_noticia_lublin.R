#' noticia_lublin UI Function
#' @noRd 
mod_noticia_lublin_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(
      class = "container mt-5 mb-5 shadow-sm p-5 bg-white rounded",
      style = "max-width: 900px; border-top: 5px solid #0A2463;",
      
      # Cabecera periodística
      div(
        class = "text-center mb-4",
        h1("Lublin 2025: España brilla en el escenario europeo", 
           style = "color: #0A2463; font-weight: 800;"),
        p(class = "lead text-muted", "Análisis de resultados y efectividad del bloque nacional en piscina corta."),
        hr(style = "width: 80px; margin: 20px auto; border-top: 3px solid #3E92CC;")
      ),
      
      # Firma de Autor (Idéntica a la noticia anterior)
      div(
        class = "d-flex align-items-center mb-5 p-3",
        style = "background-color: #f8f9fa; border-radius: 10px; border-left: 4px solid #0A2463;",
        tags$img(
          src = "www/foto_perfil_periodista.png", 
          style = "width: 50px; height: 50px; border-radius: 50%; object-fit: cover; margin-right: 15px;"
        ),
        div(
          h5("Por Alonso González Romero", style = "margin: 0; font-weight: bold; color: #0A2463;"),
          p(style = "margin: 0; font-size: 0.9rem; color: #666;", "Estudiante MUSA | a.gonzalezr.2021@alumnos.urjc.es |")
        )
      ),
      
      # Narrativa de la noticia
      div(
        style = "font-size: 1.15rem; line-height: 1.8; color: #444; margin-bottom: 40px;",
        p("El Campeonato de Europa de Piscina Corta (25m) celebrado en la ciudad polaca de Lublin nos ha dejado una de las actuaciones más sólidas de la Selección Española en los últimos años. Lejos de depender de destellos individuales, el equipo nacional ha demostrado una gran profundidad de banquillo y una excelente puesta a punto."),
        p("Para entender el alcance real de este éxito, debemos mirar más allá de la superficie. Analizando los datos extraídos directamente de los marcadores oficiales, observamos una altísima tasa de conversión en las rondas finales y un promedio de puntos FINA que sitúa al bloque español entre la élite continental. La estrategia de equipo ha funcionado: más nadadores superando el corte de eliminatorias y una efectividad letal en la lucha por las medallas.")
      ),
      
      # Resumen de Estadísticas (KPIs)
      h4("RESUMEN DE RENDIMIENTO", style = "font-weight: 700; color: #0A2463; margin-bottom: 20px;"),
      uiOutput(ns("resumen_metricas")),
      
      br(),
      
      # Medallero
      bslib::card(
        style = "border: none; background-color: #f8f9fa; margin-bottom: 30px;",
        bslib::card_body(
          uiOutput(ns("medallero_texto"))
        )
      ),

      # Listado de Finalistas
      h4("NADADORES FINALISTAS (Ronda FIN)", style = "font-weight: 700; color: #0A2463; margin-top: 30px;"),
      p(class = "text-muted", "Atletas que lograron superar las fases eliminatorias para alcanzar la última instancia competitiva en sus respectivas pruebas."),
      bslib::card(
        full_screen = TRUE,
        reactable::reactableOutput(ns("tabla_finalistas"))
      )
    )
  )
}

#' noticia_lublin Server Functions
#' @noRd 
mod_noticia_lublin_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Carga de datos reactiva
    datos_lublin <- shiny::reactive({
      obtener_datos_lublin_esp()
    })
    
    # 1. Bloques de métricas (Total nadadores y Media puntos)
    output$resumen_metricas <- shiny::renderUI({
      df <- datos_lublin()
      shiny::req(nrow(df) > 0)
      
      n_total <- length(unique(df$fullname))
      media_puntos <- round(mean(df$points, na.rm = TRUE), 1)
      
      # Aquí también contamos solo las participaciones en la ronda 'FIN'[cite: 1]
      n_finales <- sum(df$round == "FIN", na.rm = TRUE) 
      
      bslib::layout_columns(
        bslib::value_box(
          title = "Nadadores Totales",
          value = n_total,
          showcase = bsicons::bs_icon("people-fill"),
          theme = "primary"
        ),
        bslib::value_box(
          title = "Media Puntos FINA",
          value = media_puntos,
          showcase = bsicons::bs_icon("water"),
          theme = "info"
        ),
        bslib::value_box(
          title = "Puestos de Finalista",
          value = n_finales,
          showcase = bsicons::bs_icon("flag-fill"),
          theme = "secondary"
        )
      )
    })
    
    # 2. Texto del Medallero (CORREGIDO)
    output$medallero_texto <- shiny::renderUI({
      df <- datos_lublin()
      shiny::req(nrow(df) > 0)
      
      # Filtramos PRIMERO por la ronda "FIN" para no contar oros de series eliminatorias[cite: 1]
      df_finales <- df[df$round == "FIN", ]
      
      oros <- sum(df_finales$place == 1, na.rm = TRUE)
      platas <- sum(df_finales$place == 2, na.rm = TRUE)
      bronces <- sum(df_finales$place == 3, na.rm = TRUE)
      
      div(
        class = "text-center",
        h5("MEDALLERO ESPAÑOL", style = "letter-spacing: 2px; font-weight: 700;"),
        div(
          style = "display: flex; justify-content: space-around; margin-top: 15px;",
          div(h2(oros, style="color: #FFD700; margin:0;"), p("OROS", style="font-size: 0.8rem; font-weight: bold;")),
          div(h2(platas, style="color: #C0C0C0; margin:0;"), p("PLATAS", style="font-size: 0.8rem; font-weight: bold;")),
          div(h2(bronces, style="color: #CD7F32; margin:0;"), p("BRONCES", style="font-size: 0.8rem; font-weight: bold;"))
        )
      )
    })
    
    # 3. Tabla de Finalistas
    output$tabla_finalistas <- reactable::renderReactable({
      df <- datos_lublin()
      shiny::req(nrow(df) > 0)
      
      # Filtramos por ronda FIN para listar a los nadadores[cite: 1]
      finalistas <- df |> 
        dplyr::filter(round == "FIN") |> 
        dplyr::select(fullname, gender) |> 
        dplyr::distinct() |> 
        dplyr::arrange(fullname)
      
      reactable::reactable(
        finalistas,
        columns = list(
          fullname = reactable::colDef(name = "Nombre del Nadador", minWidth = 200),
          gender = reactable::colDef(name = "Género", width = 100, align = "center")
        ),
        striped = TRUE,
        highlight = TRUE,
        compact = TRUE,
        pagination = FALSE
      )
    })
  })
}