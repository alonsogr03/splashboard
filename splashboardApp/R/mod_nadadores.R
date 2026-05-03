#' nadadores UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 
mod_nadadores_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tags$style(HTML("
      /* Estilos corporativos en la Sidebar */
      .sidebar-mod-nadadores {
        background-color: #ffffff;
      }
      .titulo-sidebar-mod-nadadores {
        color: #0A2463;
        font-weight: 800;
        font-family: 'Montserrat', sans-serif;
        margin-bottom: 0;
        padding-top: 10px;
      }
      .btn-outline-danger {
        border-color: #e53e3e !important;
        color: #e53e3e !important;
        transition: all 0.3s ease;
        border-radius: 8px;
        font-weight: 600;
      }
      .btn-outline-danger:hover {
        background-color: #e53e3e !important;
        color: white !important;
      }
    ")),

    # Queremos una pagina que tenga filtros y salgan los nadadores que se adecúen a dichos filtros. Usamos layour_sidebar para ello.

    page_fillable(
      layout_sidebar(
        fillable = TRUE,
        # 1. Los filtros por un lado

        sidebar = sidebar(
          width = 380, # La anchura del sidebar
          bg = "#ffffff",
          title = div(
            h4("Filtros", class = "titulo-sidebar-mod-nadadores"),
            p("Búsqueda de nadadores", style = "font-size: 0.85rem; color: #6c757d; margin-top: 5px;")
          ),
          class = "sidebar-mod-nadadores",

        # Añadimos filtros de nombre, apellidos, género y año de nacimiento.


        # Filtro de nombre

        textInput(
          inputId = ns("filtro_nombre"),
          label = "Nombre",
          placeholder = "Escriba su nombre"
        ),

        # Filtro de apellidos

        textInput(
          inputId = ns("filtro_apellidos"), 
          label = "Apellidos", 
          placeholder = "Escriba sus apellidos"
        ), 

        # Filtro de género
        selectInput(
          inputId = ns("filtro_genero"),
          label = "Género",
          choices = c("Todos" = "", "Masculino"="M", "Femenino" = "F")
        ), 

        # Filtro de año de nacimiento

        numericInput(
          inputId = ns("filtro_nacimiento"),
          label = "Año de nacimiento", 
          value = NULL, 
          min = 1900, max = as.numeric(format(Sys.Date(), "%Y"))
        ),

        # Botón para poder borrar los filtros

        actionButton(
          inputId = ns("btn_limpiar"), 
          label = "Borrar Filtros",
          icon = icon("trash-can"),
          class = "btn-outline-danger mt-4 w-100"
        )

      ), 

      # 2. El área donde salen las cartas con los perfiles de cada nadador

      card(
        style = "border: none; box-shadow: 0 4px 20px rgba(10,36,99,0.08); border-radius: 12px; margin-top: 10px;",
        card_body(
          h3("Resultados de la búsqueda", class = "titulo-resultados", style="color: #0A2463; font-weight: 800; font-family: 'Montserrat', sans-serif;"), 
          uiOutput(ns("caja_tarjetas"))
        )
      )
    ) # Cierra layout_sidebar
    ) # Cierra page_fillable
  ) # Cierra tagList
}
    
#' nadadores Server Functions
#'
#' @noRd 
mod_nadadores_server <- function(id, mensajero, sesion_padre){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    # Configuramos los filtros

    texto_nombre <- reactive({input$filtro_nombre}) |> debounce(500) # Así no busca cada palabra!!
    texto_apellidos <- reactive({input$filtro_apellidos}) |> debounce(500)

    # La búsqueda reactiva de nadadores
    nadadores_filtrados <- reactive({
      val_nombre <- trimws(texto_nombre())
      val_apellidos <- texto_apellidos()
      val_genero <- input$filtro_genero
      val_nacimiento <- input$filtro_nacimiento

      # Verificamos si está todo vacío para no devolver nada. Metemos la posibilidad de poner "     " y que se rompiese...
      todo_vacio <- (is.null(val_nombre) || trimws(val_nombre) == "") &&
                    (is.null(val_apellidos) || trimws(val_apellidos) == "") &&
                    (is.null(val_genero) || trimws(val_genero) == "") &&
                    (is.na(val_nacimiento))
      
      if (todo_vacio) {
        return(data.frame())
      }

      # Si hay cositas, las cargamos con la llamada a la API. 

      df <- buscar_nadadores_api(nombre = val_nombre, apellidos = val_apellidos, genero = val_genero, nacimiento = val_nacimiento)

      return (df)
    })





    # Mostrar las cards de manera reactiva. 
    output$caja_tarjetas <- renderUI({
      df <- nadadores_filtrados() 
      
      if (nrow(df) == 0) return(NULL)
      
      # Generamos la lista de tarjetas
      lista_cards <- lapply(1:nrow(df), function(i) {
        crear_card_nadador(
          ns = ns,
          id_nadador = df$athleteid[i],
          nombre     = df$firstname[i],
          apellidos  = df$lastname[i],
          nacimiento = df$birthyear[i],
          foto_url   = "https://www.shutterstock.com/image-vector/default-avatar-social-media-display-600nw-2632690107.jpg"
        )
      })
      
      # Las metemos en un grid
      layout_column_wrap(
        width = "250px", 
        fixed_width = TRUE,
        gap = "1rem",
        !!!lista_cards
      )
    })


    # Eliminacion de filtros
    observeEvent(input$btn_limpiar, {
      updateTextInput(
        session = session, 
        inputId = "filtro_nombre",
        value = ""                   
      )
      
      updateTextInput(
        session = session, 
        inputId = "filtro_apellidos", 
        value = ""
      )
      
      # 2. Restauramos el selector de género a "Todos"
      updateSelectInput(
        session = session, 
        inputId = "filtro_genero", 
        selected = ""                
      )
      
      # 3. Vaciamos el año de nacimiento
      updateNumericInput(
        session = session, 
        inputId = "filtro_nacimiento", 
        value = NA                   
      )
  
})

    
    
    # Este bloque detecta clics en botones dinámicos (ej: ver_perfil_1, ver_perfil_2...)
    observeEvent(input$nadador_clicado, {
      print(paste("¡Botón pulsado! ID detectado:", input$nadador_clicado))
      # 1. Obtenemos el ID que nos ha mandado el botón de JavaScript
      id_real <- input$nadador_clicado
      
      # 2. Se lo pasamos al mensajero para que mod_perfil_nadador pueda usarlo
      mensajero$id_nadador_seleccionado <- id_real
      
      # 3. Viajamos a la pestaña
      bslib::nav_select(
        id = "menu_principal", 
        selected = "perfil_detallado", 
        session = sesion_padre # IMPORTANTE: Explicación en el paso 3
      )
  
    })

    


 
  })
}
    
## To be copied in the UI
# mod_nadadores_ui("nadadores_1")
    
## To be copied in the server
# mod_nadadores_server("nadadores_1")
