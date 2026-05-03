#' calendario_noticias UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 
mod_calendario_noticias_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(
      class = "calendario_widget",
      div(
        class = "calendario_widget-header",
        h3("Calendario de competiciones", class = "calendario_widget-title"),
        p("Próximos eventos oficiales", class = "calendario_widget-subtitle")
      ),
      toastui::calendarOutput(ns("mini_calendario_noticias"), height = "580px")
    )
 
  )
}
    
#' calendario_noticias Server Functions
#'
#' @noRd 
mod_calendario_noticias_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    output$mini_calendario_noticias <- toastui::renderCalendar({
      
      # 1. Obtención de datos
      datos_brutos <- obtener_competiciones()
      
      # 2. Definición de la paleta institucional
      azul_oscuro  <- "#0A2463"
      azul_medio   <- "#3E92CC"
      azul_suave   <- "#E1F5FE" # Fondo de las celdas de evento

      # 3. Mapeo de datos (CORREGIDO el error de los puntos suspensivos)
      # Usamos los nombres de las columnas de tu objeto 'datos_brutos'
      datos_calendario <- data.frame (
        id          = datos_brutos$id, 
        title       = datos_brutos$name, 
        start       = datos_brutos$start_date, 
        end         = datos_brutos$end_date,
        category    = "allday", 
        bgColor     = azul_suave,  # Fondo azul muy clarito
        color       = azul_oscuro, # Texto azul oscuro
        borderColor = azul_oscuro, # Borde definido
        # Aquí pasamos cada columna individualmente para que la función las procese
        body = crear_descripcion_competicion(
          name          = datos_brutos$name,
          city          = datos_brutos$city,
          course        = datos_brutos$course,
          timing        = datos_brutos$timing,
          nation        = datos_brutos$nation,
          pool_min_lane = datos_brutos$pool_min_lane,
          pool_max_lane = datos_brutos$pool_max_lane
        )
      )

      # 4. Renderizado con Tema Profesional
      toastui::calendar(datos_calendario, view = "month", navigation = TRUE) |>
        toastui::cal_props(
          month = list(
            startDayOfWeek = 1, # Lunes primer dia
            narrowWeekend = FALSE,
            visibleWeeksCount = 6, # Dejamos suficiente espacio para que no se superpongan
            isAlways6Week = FALSE, # Evita forzar 6 semanas si el mes termina antes
            dayname = list(color = azul_oscuro, fontWeight = "bold")
          )
        ) |>
        toastui::cal_theme(
          # Eliminamos los bordes agresivos
          common.border = "1px solid #f0f4f8",
          common.backgroundColor = "white",
          
          # Cabecera de días más limpia y sin bordes
          month.dayname.backgroundColor = "transparent",
          month.dayname.borderLeft = "none",
          
          # Días de otros meses casi invisibles para no distraer
          month.dayExceptThisMonth.color = "#d9e2ec",
          
          # Estilo del día actual (Hoy) moderno
          common.today.color = "white",
          common.today.backgroundColor = azul_medio,
          
          # Cuadrícula interior más suave
          month.holidayExceptThisMonth.color = "#d9e2ec"
        )
    })

    # 5. El observador del clic (Se mantiene igual, ya recibe el body con HTML)
    observeEvent(input$mini_calendario_noticias_click, {
      evento <- input$mini_calendario_noticias_click
      
      showModal(modalDialog(
        title = tags$h4(
          tags$strong(evento$title), 
          style = paste0("color: ", "#0A2463", "; margin-bottom: 0;")
        ), 
        div(
          style = "font-size: 1.1rem; line-height: 1.8; color: #444; padding: 10px 5px;",
          HTML(evento$body) 
        ),
        easyClose = TRUE,
        fade = TRUE,
        size = "m",
        footer = modalButton("Cerrar") 
      ))
    })
  })
}