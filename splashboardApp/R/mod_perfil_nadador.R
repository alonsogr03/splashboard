#' perfil_nadador UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 
#' @import bslib
#' @import reactable
#' @import plotly
mod_perfil_nadador_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(
      class = "container mt-5 mb-5",
      
      # Tarjeta superior con la info del atleta en grande
      uiOutput(ns("cabecera_nadador")),
      
      br(),
      
      # Dos columnas para sus stats y competiciones
      layout_columns(
        col_widths = c(6, 6),
        
        # Columna Izquierda: Gráfico de sus marcas o historial + Data de mejores tiempos
        card(
          card_header(
            h4("Mejores Marcas Personales", class = "mb-0", style = "color: #0A2463;")
          ),
          card_body(
            reactableOutput(ns("tabla_mejores_tiempos"))
          )
        ),
        
        # Columna Derecha: Competiciones a las que ha asistido
        card(
          card_header(
            h4("Historial de Competiciones", class = "mb-0", style = "color: #0A2463;")
          ),
          card_body(
            reactableOutput(ns("tabla_competiciones"))
          )
        )
      )
    )
  )
}
    
#' perfil_nadador Server Functions
#'
#' @noRd 
mod_perfil_nadador_server <- function(id, mensajero){
  moduleServer(id, function(input, output, session){
    ns <- session$ns
    
    # 1. Info básica
    info_basica <- reactive({
      req(mensajero$id_nadador_seleccionado)
      obtener_info_nadador(mensajero$id_nadador_seleccionado)
    })
    
    # 2. Competiciones
    competiciones <- reactive({
      req(mensajero$id_nadador_seleccionado)
      obtener_competiciones_nadador(mensajero$id_nadador_seleccionado)
    })
    
    # 3. Mejores tiempos
    mejores_tiempos <- reactive({
      req(mensajero$id_nadador_seleccionado)
      obtener_mejores_tiempos_nadador(mensajero$id_nadador_seleccionado)
    })
    
    # ------------------ RENDERS ------------------
    
    output$cabecera_nadador <- renderUI({
      df <- info_basica()
      if (is.null(df) || nrow(df) == 0) return(h4("No se pudo cargar la información del nadador."))
      
      card(
        class = "shadow-sm border-0",
        style = "background: linear-gradient(135deg, #0A2463 0%, #247BA0 100%); color: white;",
        card_body(
          class = "d-flex align-items-center",
          div(
            style = "flex: 0 0 120px;",
            tags$img(
              src = "https://www.shutterstock.com/image-vector/default-avatar-social-media-display-600nw-2632690107.jpg", 
              style = "width: 100px; height: 100px; border-radius: 50%; border: 3px solid white; object-fit: cover;"
            )
          ),
          div(
            style = "flex: 1;",
            h1(paste(df$firstname[1], df$lastname[1]), class = "mb-1 text-white fw-bold"),
            p(
              class = "lead mb-0 text-white-50",
              paste0(
                "Nacimiento: ", df$birthyear[1], " | ",
                "Género: ", ifelse(df$gender[1] == "M", "Masculino", "Femenino")
              )
            )
          )
        )
      )
    })
    
    output$tabla_competiciones <- renderReactable({
      df <- competiciones()
      req(nrow(df) > 0)
      
      reactable(
        df,
        columns = list(
          id = colDef(show = FALSE),
          name = colDef(name = "Competición", minWidth = 200),
          city = colDef(name = "Ciudad"),
          start_date = colDef(name = "Fecha Inicio"),
          course = colDef(name = "Piscina")
        ),
        theme = reactableTheme(
          stripedColor = "#f9f9f9",
          highlightColor = "#f0f0f0",
          cellPadding = "8px 12px"
        ),
        striped = TRUE,
        highlight = TRUE,
        pagination = TRUE,
        defaultPageSize = 10
      )
    })
    
    output$tabla_mejores_tiempos <- renderReactable({
      df <- mejores_tiempos()
      req(nrow(df) > 0)
      
      # Filtramos las pruebas en las que no hay tiempo o es 0
      df <- df[!is.na(df$swimtime) & df$swimtime > 0, ]
      req(nrow(df) > 0)
      
      # Formateamos el tiempo con la función existente
      df$swimtime_fmt <- sapply(df$swimtime, formatear_tiempo_natacion)
      
      reactable(
        df,
        columns = list(
          distance = colDef(name = "Distancia", width = 90),
          style = colDef(name = "Estilo"),
          course = colDef(name = "Piscina", width = 80),
          swimtime = colDef(show = FALSE),
          swimtime_fmt = colDef(name = "Marca"),
          event_date = colDef(name = "Fecha", width = 110)
        ),
        theme = reactableTheme(
          stripedColor = "#f9f9f9",
          highlightColor = "#f0f0f0",
          cellPadding = "8px 12px"
        ),
        striped = TRUE,
        highlight = TRUE
      )
    })
  })
}
    
## To be copied in the UI
# mod_perfil_nadador_ui("perfil_nadador_1")
    
## To be copied in the server
# mod_perfil_nadador_server("perfil_nadador_1")
