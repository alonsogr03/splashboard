#' Noticia Doha UI Function
#' @import shiny bslib plotly
#' @noRd
mod_noticia_doha_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    shiny::div(
      class = "container mt-5 mb-5 shadow-sm p-5 bg-white rounded-4",
      style = "max-width: 1000px; border-top: 8px solid #0A2463;",
      
      # Cabecera periodística
      shiny::div(
        class = "text-center mb-5",
        shiny::h1("El Extraño Mundial de Doha 2024: ¿Un Espejismo Estadístico?", 
           style = "color: #0A2463; font-weight: 900; font-family: 'Montserrat', sans-serif; font-size: 2.8rem; line-height: 1.2;"),
        shiny::p(class = "lead text-muted fw-bold", "Análisis interno del rendimiento y la dosificación de esfuerzo en el atípico certamen de febrero."),
        shiny::hr(style = "border-top: 3px solid #3E92CC; width: 80px; margin: 30px auto;")
      ),
      
      # Firma
      shiny::div(
        class = "d-flex align-items-center mb-5 p-3 rounded-3",
        style = "background-color: #f1f4f9;",
        shiny::tags$img(src = "www/foto_perfil_periodista.png", style = "width: 60px; height: 60px; border-radius: 50%; border: 2px solid #0A2463;"),
        shiny::div(
          style = "margin-left: 15px;",
          shiny::h6("Por Alonso González Romero", style = "margin:0; font-weight: 800; color: #0A2463;"),
          shiny::p("Analista de Datos Deportivos | a.gonzalezr.2021@alumnos.urjc.es", style = "margin:0; font-size: 0.85rem; color: #666;")
        )
      ),
      
      # Narrativa
      shiny::div(
        style = "font-size: 1.15rem; line-height: 1.8; color: #444;",
        
        shiny::p("Nunca antes un Campeonato del Mundo de Natación de gran calibre había sido agendado en el mes de febrero de un año olímpico. La cita en la ciudad catarí de Doha generó una inmensa controversia en su colocación en el calendario, provocando una avalancha de ausencias entre las potencias occidentales e invitando a una profunda lectura táctica por parte de los analistas de datos."),
        
        shiny::p("Al celebrarse en pleno bloque de entrenamiento invernal ('base training'), el estado de forma general del pelotón estaba mermado. Lejos de ver un aluvión de Récords del Mundo, asistimos a un campeonato táctico, donde la gestión de la energía entre las series matinales y las finales vespertinas fue la verdadera clave del éxito."),
        
        shiny::br(),
        
        # Gráfico 1: Puntos por Puesto
        shiny::h3("La Barrera de las Finales", style = "color: #0A2463; font-weight: 800; margin-top: 20px; margin-bottom: 20px;"),
        shiny::p("El siguiente gráfico extrae de la base de datos oficial el promedio exacto de Puntos FINA obtenidos por los nadadores en cada una de las 8 posiciones de las finales de Doha. Nos permite entender qué calidad técnica (puntos) era matemáticamente necesaria para colgarse un metal o ganar el codiciado diploma mundialista."),
        
        bslib::card(
          style = "border: none; box-shadow: 0 4px 15px rgba(10,36,99,0.08); margin-bottom: 40px;",
          bslib::card_header(shiny::h5("Calidad Media en Finales (Posición 1 al 8)", style="margin:0; font-weight: 700; color: #0A2463;")),
          bslib::card_body(plotly::plotlyOutput(ns("plot_posiciones"), height = "400px"))
        ),
        
        # Gráfico 2: Evolución por Ronda
        shiny::h3("Dosificación de Esfuerzo: Sobrevivir a las Mañanas", style = "color: #0A2463; font-weight: 800; margin-top: 20px; margin-bottom: 20px;"),
        shiny::p("Una de las métricas más reveladoras de un campeonato 'lento' es la varianza entre rondas. Como muestra la distribución inferior, las eliminatorias matinales (PRE) registraron una calidad media notablemente más baja. Los atletas de élite nadaron 'con el freno de mano echado' para asegurar el pase, reservando su pico anaeróbico exclusivamente para la ronda final (FIN)."),
        
        bslib::card(
          style = "border: none; box-shadow: 0 4px 15px rgba(10,36,99,0.08); border-top: 5px solid #FFD166;",
          bslib::card_header(shiny::h5("Densidad de Puntos por Ronda Competitiva", style="margin:0; font-weight: 700; color: #0A2463;")),
          bslib::card_body(plotly::plotlyOutput(ns("plot_rondas"), height = "400px"))
        ),
        
        shiny::h3("Conclusión Periodística", style = "color: #0A2463; font-weight: 800; margin-top: 20px; margin-bottom: 20px;"),
        shiny::p("Los datos demuestran que Doha 2024 no pasará a la historia por su exuberancia cronométrica, sino por ser un torneo de pura supervivencia. Los nadadores que dominaron el medallero fueron aquellos capaces de especular con los puntos mínimos en eliminatorias y exprimir un último cartucho de energía en la final, reservando su verdadero potencial para el macrociclo de París.")
      )
    )
  )
}

#' Noticia Doha Server Function
#' @noRd
mod_noticia_doha_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Carga Reactiva de Datos
    datos_doha <- shiny::reactive({
      obtener_datos_doha() # Esta función se queda igual que antes en tu fct_supabase.R
    })
    
    # 1. Gráfico: Puntos medios por puesto en la final (Lollipop Chart)
    output$plot_posiciones <- plotly::renderPlotly({
      df <- datos_doha()
      shiny::req(nrow(df) > 0)
      
      df_pos <- df |> 
        dplyr::filter(round == "FIN", !is.na(place), place <= 8) |> 
        dplyr::group_by(place) |> 
        dplyr::summarise(media_puntos = round(mean(points, na.rm = TRUE), 0))
      
      # Definimos colores de medalla
      df_pos$color <- dplyr::case_when(
        df_pos$place == 1 ~ "#FFD700",
        df_pos$place == 2 ~ "#C0C0C0",
        df_pos$place == 3 ~ "#CD7F32",
        TRUE ~ "#0A2463"
      )
      
      plotly::plot_ly(df_pos) |>
        plotly::add_segments(x = ~place, xend = ~place, y = 800, yend = ~media_puntos, 
                             line = list(color = "#ccc", width = 3)) |>
        plotly::add_markers(x = ~place, y = ~media_puntos, size = 25, 
                            marker = list(color = ~color, line = list(color = "#333", width = 2)),
                            text = ~paste(media_puntos, "pts"), hoverinfo = "text") |>
        plotly::layout(
          xaxis = list(title = "Puesto en la Final", dtick = 1),
          yaxis = list(title = "Promedio Puntos FINA", range = c(750, 1000)),
          showlegend = FALSE,
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)'
        )
    })
    
    # 2. Gráfico: Boxplot de Dosificación por Ronda (PRE, SEM, FIN)
    output$plot_rondas <- plotly::renderPlotly({
      df <- datos_doha()
      shiny::req(nrow(df) > 0)
      
      # Limpiamos rondas y ordenamos cronológicamente
      df_rondas <- df |> 
        dplyr::filter(round %in% c("PRE", "SEM", "FIN"), !is.na(points), points > 400) |>
        dplyr::mutate(round = factor(round, levels = c("PRE", "SEM", "FIN")))
      
      plotly::plot_ly(df_rondas, x = ~round, y = ~points, type = "box",
                      color = ~round, colors = c("#829ab1", "#3E92CC", "#0A2463"),
                      boxpoints = "outliers", marker = list(size = 4, opacity = 0.5)) |>
        plotly::layout(
          xaxis = list(title = "Fase de la Competición"),
          yaxis = list(title = "Puntos FINA"),
          showlegend = FALSE,
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)'
        )
    })
    
  })
}