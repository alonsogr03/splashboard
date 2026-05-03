#' noticias UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList HTML tags
#' 


crear_noticia_card <- function(id_btn, titulo, resumen, imagen_url) {
  card(
    class = "tarjeta-noticia shadow-sm", 
    style = "border-radius: 12px; border: none; overflow: hidden; transition: all 0.3s ease;",
    
    
    div(
      style = "width: 100%; height: 200px; background-color: #f4f7f6; display: flex; justify-content: center; align-items: center; overflow: hidden; padding: 10px;",
      tags$img(
        src = imagen_url,
        class = "imagen-noticia", 
        style = "width: 100%; height: 100%; object-fit: contain; object-position: center; transition: transform 0.5s ease;"
      )
    ),
    
    
    card_body(
      h4(tags$strong(titulo), style = "color: #0A2463; font-size: 1.15rem; margin-top: 5px; margin-bottom: 10px; line-height: 1.3;"),
      p(resumen, style = "font-size: 0.9rem; color: #555; margin-bottom: 0;"),
      fill = TRUE
    ),
    
    
    card_footer(
      style = "background-color: white; border-top: none; padding: 15px 20px 20px 20px;",
      actionButton(
        inputId = id_btn,
        label = "Leer estudio completo",
        class = "btn-primary w-100", 
        style = "background-color: #0A2463; border: none; border-radius: 8px; font-weight: 600; padding: 10px;"
      )
    )
  )
}


mod_noticias_ui <- function(id) {
  ns <- NS(id)
  tagList(
    
    tags$style(HTML("
      /* Cuando el ratón pasa por la tarjeta, se eleva y aumenta la sombra */
      .tarjeta-noticia:hover {
        transform: translateY(-5px);
        box-shadow: 0 12px 24px rgba(10, 36, 99, 0.15) !important;
      }
      /* Cuando el ratón pasa por la tarjeta, la imagen hace zoom */
      .tarjeta-noticia:hover .imagen-noticia {
        transform: scale(1.08);
      }
    ")),
    
    layout_columns(
      col_widths = c(8, 4),
      
      
      div(
        class = "container mt-5",
        h2("Últimas Noticias e Informes", class = "mod_noticias_titulo", 
           style = "color: #0A2463; font-weight: 800; margin-bottom: 30px;"),
        
        layout_column_wrap(
          width = 1/2, 
          heights_equal = "row",
          gap = "1.5rem", 
          
          
          crear_noticia_card(ns("ir_estudio_4"), "Top 5 mejores nadadores de USA Swimming Pro Swim Series", "Un estudio sobre el rendimiento en FINA Points de los nadadores más destacados durante la competición", "www/usa_pro_swim_series.png"),
          crear_noticia_card(ns("ir_estudio_5"), "¿Ha sido el Europeo de Lublin el mejor campeonato para la Selección Española?", "Un análisis de las medallas, marcas y tiempos conseguidos", "www/European-Short-Course-Swimming-Championships-2025.jpg"),
          crear_noticia_card(ns("ir_estudio_2"), "Evolución de las marcas durante el ciclo olímpico", "Análisis longitudinal de las mejores marcas de cada temporada en el ciclo olímpico", "www/olimpiadas_paris.jpeg"),
          crear_noticia_card(ns("ir_estudio_1"), "Análisis Mundial Doha 2024", "Un análisis de los mejores nadadores", "www/doha_logo.png"),
          crear_noticia_card(ns("ir_estudio_3"), "¿Qué salida es más rápida?", "Estudio cinemático sobre los cambios en la patada de delfín en la última década.", "www/espalda_vs_no.png")
        )
      ),

      
      div(
        class = "container mt-5 calendario_noticias",
        mod_calendario_noticias_ui(ns("calendario_noticias_1"))
      )
    )
  )
}
    
#' noticias Server Functions
#'
#' @noRd 
mod_noticias_server <- function(id, sesion_padre){
  moduleServer(id, function(input, output, session){
    ns <- session$ns
    
    
    observeEvent(input$ir_estudio_1, {
      
      nav_select(id = "menu_principal", selected = "estudio_doha", session = sesion_padre)
    })
    
    observeEvent(input$ir_estudio_2, {
      
      nav_select(id = "menu_principal", selected = "estudio_estilos", session = sesion_padre)
    })

    observeEvent(input$ir_estudio_3, {
      
      nav_select(id = "menu_principal", selected = "estudio_rt", session = sesion_padre)
    })

    observeEvent(input$ir_estudio_4, {
      
      nav_select(id = "menu_principal", selected = "estudio_swimseries", session = sesion_padre)
    })

    observeEvent(input$ir_estudio_5, {
      
      nav_select(id = "menu_principal", selected = "estudio_lublin", session = sesion_padre)
    })




    
    mod_calendario_noticias_server("calendario_noticias_1")
  })
}
    
## To be copied in the UI
# mod_noticias_ui("noticias_1")
    
## To be copied in the server
# mod_noticias_server("noticias_1")
