#' Noticia Evolución Ciclo Olímpico UI Function
#' @import shiny bslib plotly
#' @noRd
mod_noticia_estilos_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    shiny::div(
      class = "container mt-5 mb-5 shadow-sm p-5 bg-white rounded-4",
      style = "max-width: 1000px; border-top: 8px solid #0A2463;",
      
      # Cabecera periodística
      shiny::div(
        class = "text-center mb-5",
        shiny::h1("Evolución de Tiempos: El Camino hacia París 2024", 
           style = "color: #0A2463; font-weight: 900; font-family: 'Montserrat', sans-serif; font-size: 2.8rem; margin-bottom: 20px; line-height: 1.2;"),
        shiny::p(class = "lead text-muted fw-bold", "Análisis longitudinal de la mejora de métricas en competiciones de Piscina Larga (50m) en el transcurso del Ciclo Olímpico."),
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
          shiny::p("Estudiante MUSA | a.gonzalezr.2021@alumnos.urjc.es", style = "margin:0; font-size: 0.85rem; color: #666;")
        )
      ),
      
      # Introducción
      shiny::div(
        style = "font-size: 1.15rem; line-height: 1.8; color: #444;",
        
        shiny::p("La natación no es un deporte lineal. Los atletas periodizan exhaustivamente sus picos de forma a través de macrociclos de entrenamiento diseñados milimétricamente para explotar su máximo rendimiento durante los Juegos Olímpicos."),
        
        shiny::p("En el gráfico interactivo a continuación, puedes filtrar entre pruebas, estilos y géneros para ver cómo evoluciona la distribución del ", shiny::tags$strong("Top 50 Mundial"), " a medida que se desarrolla cada uno de los años del ciclo completo de preparación (2021 a 2024)."),
        
        # Dashboard Integrado (Filtros + Plotly)
        bslib::card(
          style = "border: none; box-shadow: 0 4px 15px rgba(10,36,99,0.08); margin-top: 30px; margin-bottom: 40px;",
          bslib::card_header(
            shiny::div(class="row align-items-center",
                shiny::div(class="col-md-3", shiny::h5("Parámetros:", style="margin:0; font-weight: 700; color: #0A2463;")),
                shiny::div(class="col-md-3", shiny::selectInput(ns("genero"), NULL, choices = c("Masculino"="M", "Femenino"="F"), selected = "M", width = "100%")),
                shiny::div(class="col-md-3", shiny::selectInput(ns("distancia"), NULL, choices = c("50m"=50, "100m"=100, "200m"=200, "400m"=400, "800m"=800, "1500m"=1500), selected = 100, width = "100%")),
                shiny::div(class="col-md-3", shiny::selectInput(ns("estilo"), NULL, choices = c("Libre"="FREE", "Espalda"="BACK", "Braza"="BREAST", "Mariposa"="FLY", "Estilos"="MEDLEY"), selected = "FLY", width = "100%"))
            )
          ),
          bslib::card_body(
            plotly::plotlyOutput(ns("plot_evolucion_marcas"), height = "450px")
          )
        ),
        
        shiny::h3("La Importancia de la Periodización", style = "color: #0A2463; font-weight: 800; margin-top: 20px; margin-bottom: 20px;"),
        
        shiny::p(shiny::tags$em("Se puede observar como en general, los tiempos en la mayoría de pruebas tienen una forma de U invertida. Esto se debe a que, 2022 fue un año post- juegos olímpicos, mientras que 2023 fue una época de preparación para los próximos juegos olímpicos, donde los nadadores acumularon la mayor carga de metros y entrenamientos. Llegando a la fecha señalada y con motivo de ir afinando detalles competitivos, los tiempos en cada prueba vuelven a bajar, siendo a veces en media, mejores que en 2022.")),
        
        shiny::br()
      )
    )
  )
}

#' Noticia Evolución Ciclo Olímpico Server Function
#' @noRd
mod_noticia_estilos_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Descarga reactiva: Se ejecuta SOLO cuando el usuario cambia un filtro
    datos_ciclo <- shiny::reactive({
      shiny::req(input$distancia, input$estilo, input$genero)
      # Pasamos los parámetros de la UI directamente a la base de datos
      obtener_marcas_ciclo_olimpico(input$distancia, input$estilo, input$genero)
    })
    
    # Render del Boxplot Reactivo
    output$plot_evolucion_marcas <- plotly::renderPlotly({
      df_top <- datos_ciclo()
      
      # Si la base de datos no tiene suficientes resultados para la prueba seleccionada
      if(is.null(df_top) || nrow(df_top) == 0) {
        return(plotly::plot_ly() |> plotly::layout(title = list(text = "No hay datos suficientes para esta prueba.", x = 0.5)))
      }
      
      # Boxplot con Plotly
      plotly::plot_ly(df_top, x = ~year, y = ~swimtime, type = "box",
                      color = ~year, colors = c("#829ab1", "#3E92CC", "#0A2463", "#FFD700"),
                      boxpoints = "outliers", # Destaca las marcas extraordinarias
                      marker = list(size = 6, opacity = 0.8)) |>
        plotly::layout(
          xaxis = list(title = "Temporada"),
          yaxis = list(title = "Tiempo (Segundos)", autorange = "reversed"), # Invertido: más arriba = más rápido
          showlegend = FALSE,
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          margin = list(b = 40, t = 20),
          hovermode = "closest"
        )
    })
  })
}