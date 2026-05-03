#' marcas UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 
mod_marcas_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tags$style(HTML("
      /* Estilos corporativos integrados en la Sidebar */
      .sidebar-mod-marcas {
        background-color: #ffffff;
      }
      .titulo-sidebar-mod-marcas {
        color: #0A2463;
        font-weight: 800;
        font-family: 'Montserrat', sans-serif;
        margin-bottom: 0;
        padding-top: 10px;
      }
      
      .btn-marcas-buscar {
        background-color: #0A2463 !important;
        border-color: #0A2463 !important;
        font-family: 'Montserrat', sans-serif;
        font-weight: 600;
        border-radius: 8px;
        transition: all 0.3s ease;
      }
      .btn-marcas-buscar:hover {
        background-color: #3E92CC !important;
        border-color: #3E92CC !important;
        box-shadow: 0 4px 10px rgba(62,146,204,0.3);
      }
    ")),

    page_fillable(
      layout_sidebar(
        fillable = TRUE,
        sidebar = sidebar(
          width = 380,
          bg = "#ffffff",
          title = div(
            h4("Filtros", class = "titulo-sidebar-mod-marcas"),
            p("Buscador de mejores marcas", style = "font-size: 0.85rem; color: #6c757d; margin-top: 5px;")
          ),
          class = "sidebar-mod-marcas",


          

        selectInput(
          inputId = ns("filtro_distancia"),
          label = "Distancia",
          choices = c(50, 100, 200, 400, 800, 1500)
        ),

        selectInput(
          inputId = ns("filtro_estilo"),
          label = "Estilo",
          choices = c("BACK", "MEDLEY", "BREAST", "FREE", "FLY")
        ),

        selectInput(
          inputId = ns("filtro_genero"),
          label = "Género",
          choices = c("Todos" = "", "Masculino"="M", "Femenino" = "F")
        ),
        selectInput(
          inputId = ns("filtro_piscina"),
          label = "Tipo de Piscina",
          choices = c("Piscina Larga (LCM)" = "LCM", "Piscina Corta (SCM)" = "SCM")
        ),

        dateRangeInput(
          inputId = ns("filtro_rango_nacimiento"),
          label = "Fecha de realización de la marca:",
          start = "1900-01-01",      
          end = Sys.Date(),          
          min = "1890-01-01",        
          max = Sys.Date(),          
          language = "es",
          separator = " hasta ",
          weekstart = 1
        ),

        numericInput(
          inputId = ns("filtro_top_nadadores"),
          label = "Elige el top:",
          value = 10,
          min = 1,
          max = 100,
          step = 1

        ),

        actionButton(
          inputId = ns("btn_buscar"),
          label = "Aplicar filtro",
          icon = icon("magnifying-glass"),
          class = "btn-marcas-buscar w-100 mt-3 text-white"
        )


      ),

      

      card(
        style = "border: none; box-shadow: 0 4px 20px rgba(10,36,99,0.08); border-radius: 12px; margin-top: 10px;",
        card_body(
          uiOutput(ns("titulo_dinamico")),
          uiOutput(ns("dataframe_resultados"))
        )
      )
    ) 
    ) 
  )
}
    
#' marcas Server Functions
#'
#' @noRd 
mod_marcas_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    datos_filtrados <- eventReactive(input$btn_buscar, {
      req(input$filtro_top_nadadores, input$filtro_rango_nacimiento)
      
      obtener_top_marcas(
        p_dist = input$filtro_distancia,
        p_estilo = input$filtro_estilo,
        p_gen = input$filtro_genero,
        p_top = input$filtro_top_nadadores,
        p_inicio = input$filtro_rango_nacimiento[1],
        p_fin = input$filtro_rango_nacimiento[2],
        p_piscina = input$filtro_piscina 
      )
    }, ignoreNULL = FALSE)

    texto_titulo <- eventReactive(input$btn_buscar, {
      
      distancia <- input$filtro_distancia
      estilo <- input$filtro_estilo
      piscina <- if(input$filtro_piscina == "LCM") "Piscina Larga" else "Piscina Corta"
      
      paste("Top Marcas:", distancia, "m", estilo, "-", piscina)
    }, ignoreNULL = FALSE)

    
    output$titulo_dinamico <- renderUI({
      h3(texto_titulo(), 
         class = "contenedor-marcas-titulo mb-4", 
         style = "color: #0A2463; font-weight: bold; border-bottom: 2px solid #0A2463; padding-bottom: 10px;")
    })


    output$dataframe_resultados <- renderUI({
      df <- datos_filtrados()
      if (is.null(df) || nrow(df) == 0){
        return(div(class = "text-center py-5",
                   icon("circle-exclamation", class = "fa-3x mb-3 text-muted"),
                   h4("Sin resultados", class = "text-muted"),
                   p("Prueba a ampliar el rango de fechas.")))
      }
      reactable::reactableOutput(ns("tabla_marcas_top"))
    })

    output$tabla_marcas_top <- reactable::renderReactable({
      df <- datos_filtrados()
      
      reactable::reactable(
        df,
        searchable = TRUE, 
        highlight = TRUE,
        defaultColDef = reactable::colDef(vAlign = "center"),
        columns = list(
          name = reactable::colDef(
            name = "Nadador/a", 
            minWidth = 180,
            cell = function(value) {
              tagList(
                icon("user", class = "me-2 text-muted"),
                span(value, style = "font-weight: 600; color: #0A2463;")
              )
            }
          ),
          birthyear = reactable::colDef(name = "Año", width = 70, align = "center", style = list(color = "#666")),
          gender = reactable::colDef(
            name = "Gen.", width = 70, align = "center",
            cell = function(value) {
              class <- if(value == "M") "bg-info" else "bg-danger" 
              label <- if(value == "M") "M" else "F"
              span(class = paste("badge rounded-pill", class), label)
            }
          ),
          event_date = reactable::colDef(name = "Fecha", width = 110, align = "center"),
          round = reactable::colDef(
            name = "Ronda", width = 80, align = "center",
            cell = function(value) {
              
              color <- if(value == "FIN") "#0A2463" else "#3E92CC"
              span(value, class = "badge", style = paste0("background-color: ", color))
            }
          ),
          reactiontime = reactable::colDef(
            name = "R.T.", width = 80, align = "center",
            cell = function(value) {
              if (is.na(value)) return("-")
              span(sprintf("+%.2f", value), style = "color: #888; font-size: 0.85rem;")
            }
          ),
          swimtime = reactable::colDef(
            name = "Marca", align = "right", width = 120,
            cell = function(value) formatear_tiempo_natacion(value),
            style = list(fontFamily = "JetBrains Mono, monospace", fontSize = "1.1rem", fontWeight = "700", color = "#0A2463")
          ),
          daytime = reactable::colDef(show = FALSE),
          id = reactable::colDef(show = FALSE),
          distance = reactable::colDef(show = FALSE),
          style = reactable::colDef(show = FALSE),
          parciales = reactable::colDef(show = FALSE)
        ),
        
        
        details = function(index) {
          df_p <- df$parciales[[index]]
          if (is.null(df_p) || nrow(df_p) == 0) return(NULL)
          
          df_p <- df_p[order(df_p$distance), ]
          
          div(
            style = "padding: 20px; background-color: #fcfcfc; border-bottom: 2px solid #eee;",
            h6("Desglose de la Carrera", style = "text-transform: uppercase; font-size: 0.75rem; color: #999; letter-spacing: 1px;"),
            reactable::reactable(
              df_p,
              compact = TRUE,
              fullWidth = FALSE,
              columns = list(
                distance = reactable::colDef(name = "Mts", width = 60, style = list(fontWeight = "bold")),
                parcial_swimtime = reactable::colDef(
                  name = "Parcial", width = 100, align = "center",
                  cell = function(v) formatear_tiempo_natacion(v)
                ),
                cumswimtime = reactable::colDef(
                  name = "Acumulado", width = 110, align = "right",
                  cell = function(v) formatear_tiempo_natacion(v),
                  style = list(color = "#3E92CC", fontWeight = "600")
                )
              ),
              theme = reactable::reactableTheme(
                backgroundColor = "transparent",
                headerStyle = list(fontSize = "0.7rem", color = "#aaa", borderBottom = "1px solid #eee")
              )
            )
          )
        },
        
        
        theme = reactable::reactableTheme(
          headerStyle = list(
            backgroundColor = "#f8f9fa",
            color = "#495057",
            fontWeight = "700",
            borderBottom = "2px solid #0A2463"
          ),
          rowStyle = list(fontSize = "0.95rem", borderBottom = "1px solid #f0f0f0"),
          searchInputStyle = list(width = "100%", marginBottom = "15px")
        )
      )
    })
  })
}
## To be copied in the UI
# mod_marcas_ui("marcas_1")
    
## To be copied in the server
# mod_marcas_server("marcas_1")
