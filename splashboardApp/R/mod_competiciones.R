#' competiciones UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 

mod_competiciones_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tags$style(HTML("
      /* Buscador profesional */
      .buscador-competiciones input {
        border-radius: 8px !important;
        border: 1px solid #d9e2ec !important;
        padding: 12px 15px !important;
        box-shadow: 0 2px 8px rgba(10,36,99,0.03) !important;
        transition: all 0.3s ease !important;
      }
      .buscador-competiciones input:focus {
        border-color: #3E92CC !important;
        box-shadow: 0 0 0 3px rgba(62, 146, 204, 0.15) !important;
      }
      /* Tarjetas institucionales */
      .competicion-card {
        border: none !important;
        border-radius: 10px !important;
        box-shadow: 0 4px 15px rgba(10, 36, 99, 0.05) !important;
        transition: all 0.2s ease !important;
      }
      .competicion-card:hover {
        transform: translateY(-3px) !important;
        box-shadow: 0 8px 20px rgba(10, 36, 99, 0.12) !important;
      }
      /* Adaptamos la barra de scroll */
      .panel-competiciones ::-webkit-scrollbar {
        width: 5px;
      }
      .panel-competiciones ::-webkit-scrollbar-thumb {
        background-color: #cbd5e1;
        border-radius: 10px;
      }
    ")),
    page_fillable( # Para que ocupe toda la pantalla disponible
      layout_sidebar(
        fillable = TRUE,
        sidebar = sidebar(
          title = div(
            h4("Competiciones", style = "color: #0A2463; font-weight: 800; font-family: 'Montserrat', sans-serif; margin-bottom: 0; padding-top: 10px;"),
            p("Eventos oficiales confirmados", style = "font-size: 0.85rem; color: #6c757d; margin-top: 5px;")
          ),
          width = 380,
          bg = "#ffffff", # Fondo blanco limpio para la sidebar
          # Creamos un contenedor con scroll para la lista
          div(
            class = "panel-competiciones",
            uiOutput(ns("lista_competiciones"))
          )
        ),
        
        # El mapa en el área principal
        card(
          style = "border: none; box-shadow: 0 4px 20px rgba(10,36,99,0.08); border-radius: 12px; overflow: hidden;",
          full_screen = TRUE,
          leaflet::leafletOutput(ns("mapa_mundial"), height = "100%")
        )
      )
    )
  )
}
    
#' competiciones Server Functions
#'
#' @noRd 


mod_competiciones_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session$ns
    
    # --- 1. CARGA Y TRANSFORMACIÓN DE DATOS ---
    datos_reactivos <- reactive({
      # Traemos los datos de Supabase
      df <- obtener_datos_competiciones()
      
      # Transformamos con dplyr (asegúrate de tener library(dplyr) o usar los ::)
      df |> 
        dplyr::mutate(
          # Convertimos a fechas reales de R
          inicio = as.Date(start_date),
          fin = as.Date(end_date),
          # Lógica: ¿Ha terminado ya?
          esta_pasada = fin < Sys.Date(),
          # Cálculo de calles
          num_calles = pool_max_lane - pool_min_lane,
          # ID único para los botones (usamos el nombre si no hay ID)
          id_temp = 1:dplyr::n() 
        ) |> 
        # Ordenamos: De más reciente a más antigua
        dplyr::arrange(dplyr::desc(inicio))
    })

    # --- 2. RENDER DEL MAPA (Voyager Style) ---
    output$mapa_mundial <- leaflet::renderLeaflet({
      df <- datos_reactivos()
      
      leaflet::leaflet(df) |>
        leaflet::addProviderTiles(leaflet::providers$CartoDB.Voyager) |>
        leaflet::addMarkers(
          lng = ~longitud, 
          lat = ~latitud, 
          layerId = ~id_temp, 
          label = ~name
        )
    })

    # --- 3. LISTA CON NAVEGACIÓN Y FILTRO ---
    # Para no tener una lista infinita, vamos a añadir un buscador simple arriba
    output$lista_competiciones <- renderUI({
      df <- datos_reactivos()
      
      # Añadimos un buscador de texto arriba de la lista
      tagList(
        div(
          class = "buscador-competiciones",
          textInput(ns("buscar_comp"), NULL, placeholder = "🔍 Buscar competición o ciudad..."),
          hr(style = "border-top: 1px solid #e2e8f0; margin: 15px 0;")
        ),
        div(
          style = "overflow-y: auto; max-height: calc(100vh - 230px); padding-right: 5px; padding-bottom: 20px;",
          uiOutput(ns("sublista_filtrada"))
        )
      )
    })

    # Renderizamos la sublista según el buscador
    output$sublista_filtrada <- renderUI({
      df <- datos_reactivos()
      busqueda <- input$buscar_comp
      
      # Filtramos si el usuario escribe algo
      if (!is.null(busqueda) && busqueda != "") {
        df <- df |> dplyr::filter(
          grepl(busqueda, name, ignore.case = TRUE) | 
          grepl(busqueda, city, ignore.case = TRUE)
        )
      }

      lapply(1:nrow(df), function(i) {
        comp <- df[i, ]
        
        # Color según si ha pasado o no (Paleta Corporativa)
        color_borde <- if(comp$esta_pasada) "#e2e8f0" else "#3E92CC"
        label_estado <- if(comp$esta_pasada) "Finalizada" else "Próximamente"
        
        # Estilos de los "badges" para que parezcan premium
        badge_style <- if(comp$esta_pasada) {
          "background-color: #f1f5f9; color: #64748b; border: 1px solid #e2e8f0; border-radius: 6px; padding: 4px 8px; font-size: 0.72rem; font-weight: 600;"
        } else {
          "background-color: #E1F5FE; color: #0A2463; border: 1px solid #bae1f4; border-radius: 6px; padding: 4px 8px; font-size: 0.72rem; font-weight: 700;"
        }
        
        div(
          class = "card mb-3 competicion-card",
          style = paste0("border-left: 5px solid ", color_borde, " !important; background-color:", if(comp$esta_pasada) "#fcfcfc" else "#ffffff", ";"),
          div(
            class = "card-body p-3",
            actionLink(
              ns(paste0("comp_", comp$id_temp)),
              label = tagList(
                div(class="d-flex justify-content-between align-items-center", style = "margin-bottom: 8px;",
                  h6(comp$name, style = "margin:0; font-weight: 700; color: #0A2463; font-size: 0.95rem; line-height: 1.3; padding-right: 10px;"),
                  span(style = badge_style, label_estado)
                ),
                div(style = "color: #555555; font-size: 0.85rem; margin-bottom: 4px; font-family: 'Montserrat', sans-serif;",
                  paste("📍", comp$city, "|", comp$nation)
                ),
                div(style="color: #829ab1; font-size: 0.8rem; font-weight: 500;", 
                  paste("📅", format(comp$inicio, "%d %b %Y"), "al", format(comp$fin, "%d %b %Y"))
                )
              ),
              class = "text-decoration-none",
              style = "display: block;"
            )
          )
        )
      })
    })

    # --- 4. OBSERVADORES DE CLIC (El Vuelo) ---
    observe({
      df <- datos_reactivos()
      for (i in 1:nrow(df)) {
        local({
          row <- df[i, ]
          observeEvent(input[[paste0("comp_", row$id_temp)]], {
            leaflet::leafletProxy("mapa_mundial") |>
              leaflet::flyTo(lng = row$longitud, lat = row$latitud, zoom = 14) |>
              leaflet::addPopups(
                lng = row$longitud, lat = row$latitud,
                popup = paste0(
                  "<div style='min-width:150px;'>",
                  "<b>", row$name, "</b><br>",
                  "Piscina: ", row$course, " (", row$num_calles, " calles)<br>",
                  "Cronometraje: ", row$timing,
                  "</div>"
                )
              )
          })
        })
      }
    })
  })
}










## To be copied in the UI
# mod_competiciones_ui("competiciones_1")
    
## To be copied in the server
# mod_competiciones_server("competiciones_1")
