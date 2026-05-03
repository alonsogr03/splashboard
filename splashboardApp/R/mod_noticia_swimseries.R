#' noticia_swimseries UI Function
#' @noRd 
mod_noticia_swimseries_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(
      class = "container mt-5 mb-5 shadow p-5 bg-white rounded",
      style = "max-width: 900px; border-top: 5px solid #0A2463;",
      
      # Cabecera principal
      div(
        class = "text-center mb-4",
        h1("Éxito Rotundo en las USA Swimming Pro Swim Series", 
           style = "color: #0A2463; font-weight: 800; font-family: 'Montserrat', sans-serif; font-size: 2.5rem; line-height: 1.2;"),
        hr(style = "border-top: 3px solid #3E92CC; width: 100px; margin: 30px auto;")
      ),
      
      # Firma de Autor
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
      
      # Cuerpo del artículo
      div(
        style = "font-size: 1.15rem; line-height: 1.8; color: #444;",
        
        # INTRODUCCIÓN CON DATOS DE AUSTIN
        p("La ciudad de Austin, Texas, se convirtió en el epicentro de la natación mundial del 14 al 17 de enero de 2026."),
        p("Durante estas jornadas de las Pro Swim Series, el Lee and Joe Jamail Texas Swimming Center albergó a la élite internacional en formato de Piscina Larga (50m), sirviendo como un termómetro crucial para medir el estado de forma de los nadadores en el inicio de la temporada."),
        
        br(),
        
        h3("Análisis de Rendimiento: La Vara de Medir de los Puntos FINA", style = "color: #0A2463; font-weight: 800;"),
        p("Para entender quién ha dominado realmente en Austin, no basta con mirar las medallas; debemos acudir a los Puntos FINA. Este sistema estandariza los tiempos comparándolos con los récords mundiales vigentes, permitiéndonos saber si un tiempo en los 800m libres es técnicamente 'superior' a un registro en los 100m mariposa."),
        
        p("En la categoría femenina, hemos asistido a un despliegue de versatilidad y potencia. Figuras como Ledecky y Summer McIntosh siguen demostrando su hegemonía en el fondo y estilos, mientras que especialistas como Regan Smith o Skyler Smith marcan la pauta en la velocidad y técnica pura."),
        
        # Gráfico Femenino
        bslib::card(
          style = "border: none; box-shadow: 0 4px 15px rgba(10,36,99,0.08); border-top: 5px solid #F48FB1; margin-bottom: 30px;",
          bslib::card_header(h4("Top 5 Femenino 🚺", style="margin:0; font-weight: 700; color: #0A2463; text-align: center;")),
          bslib::card_body(plotly::plotlyOutput(ns("plot_top_f"), height = "400px"))
        ),

        p("Por su parte, el cuadro masculino ha destacado por una competitividad feroz en las pruebas de velocidad y medio fondo. Nombres como Barna y Grousset han liderado la tabla de eficiencia, flanqueados por la solvencia de Petrashov y el empuje de jóvenes talentos como Guiliano."),

        # Gráfico Masculino
        bslib::card(
          style = "border: none; box-shadow: 0 4px 15px rgba(10,36,99,0.08); border-top: 5px solid #90CAF9; margin-bottom: 30px;",
          bslib::card_header(h4("Top 5 Masculino 🚹", style="margin:0; font-weight: 700; color: #0A2463; text-align: center;")),
          bslib::card_body(plotly::plotlyOutput(ns("plot_top_m"), height = "400px"))
        ),
        
        br(),
        
        h3("El MVP del Campeonato: Clasificación Global", style = "color: #0A2463; font-weight: 800;"),
        p("Al cruzar los datos de ambos sexos, la clasificación absoluta nos revela a los verdaderos protagonistas de Austin. Este Top Global no solo premia la victoria, sino la cercanía a la perfección técnica en cada brazada."),
        
        # Gráfico Top 5 Global
        bslib::card(
          style = "border: none; box-shadow: 0 4px 15px rgba(10,36,99,0.08); margin-top: 20px; margin-bottom: 40px;",
          bslib::card_header(h4("Top 5 Absoluto (Media Puntos FINA)", style="margin:0; font-weight: 700; color: #0A2463; text-align: center;")),
          bslib::card_body(plotly::plotlyOutput(ns("plot_top_global"), height = "500px"))
        )
      )
    )
  )
}

#' noticia_swimseries Server Functions
#' @noRd 
mod_noticia_swimseries_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # 1. Obtención de datos (Ya vienen ordenados DESC de la función fct_supabase)
    datos_competicion <- shiny::reactive({
      obtener_top_fina_swimseries(id_competicion = 40)
    })
    
    # --- GRÁFICO FEMENINO ---
    output$plot_top_f <- plotly::renderPlotly({
      df <- datos_competicion() |> 
        dplyr::filter(gender == "F") |> 
        dplyr::arrange(dplyr::desc(media_fina)) |> # 1. Nos aseguramos de que los mejores están arriba
        utils::head(5) |>                          # 2. Cogemos a Ledecky, Regan, etc.
        dplyr::arrange(media_fina) |>               # 3. Invertimos para que Plotly pinte el #1 arriba
        dplyr::mutate(nombre_completo = factor(nombre_completo, levels = nombre_completo))
      
      shiny::req(nrow(df) > 0)
      
      plotly::plot_ly(df, x = ~media_fina, y = ~nombre_completo, type = 'bar', orientation = 'h',
                      marker = list(color = '#F48FB1'),
                      text = ~media_fina, textposition = 'auto', 
                      textfont = list(size = 16, family = "Arial Black")) |>
        plotly::layout(xaxis = list(title = "Puntos FINA"), yaxis = list(title = ""),
                       margin = list(l = 180, r = 20, t = 20, b = 50))
    })
    
    # --- GRÁFICO MASCULINO ---
    output$plot_top_m <- plotly::renderPlotly({
      df <- datos_competicion() |> 
        dplyr::filter(gender == "M") |> 
        dplyr::arrange(dplyr::desc(media_fina)) |> # 1. Mejores puntuaciones primero
        utils::head(5) |>                          # 2. Cogemos a Barna, Guiliano, etc.
        dplyr::arrange(media_fina) |>               # 3. Invertimos para la visualización
        dplyr::mutate(nombre_completo = factor(nombre_completo, levels = nombre_completo))
      
      shiny::req(nrow(df) > 0)
      
      plotly::plot_ly(df, x = ~media_fina, y = ~nombre_completo, type = 'bar', orientation = 'h',
                      marker = list(color = '#90CAF9'),
                      text = ~media_fina, textposition = 'auto',
                      textfont = list(size = 16, family = "Arial Black")) |>
        plotly::layout(xaxis = list(title = "Puntos FINA"), yaxis = list(title = ""),
                       margin = list(l = 180, r = 20, t = 20, b = 50))
    })
    
    # --- GRÁFICO GLOBAL ---
    output$plot_top_global <- plotly::renderPlotly({
      df <- datos_competicion() |> 
        dplyr::arrange(dplyr::desc(media_fina)) |> # 1. Top mundial absoluto
        utils::head(5) |> 
        dplyr::arrange(media_fina) |>               # 2. Invertimos para el gráfico
        dplyr::mutate(nombre_completo = factor(nombre_completo, levels = nombre_completo))
      
      df$color_genero <- ifelse(df$gender == "F", "#F48FB1", "#90CAF9")
      shiny::req(nrow(df) > 0)
      
      plotly::plot_ly(df, x = ~media_fina, y = ~nombre_completo, type = 'bar', orientation = 'h',
                      marker = list(color = ~color_genero),
                      text = ~media_fina, textposition = 'auto',
                      textfont = list(size = 18, family = "Arial Black")) |>
        plotly::layout(xaxis = list(title = "Puntos FINA"), yaxis = list(title = ""),
                       margin = list(l = 200, r = 20, t = 20, b = 50), showlegend = FALSE)
    })
  })
}