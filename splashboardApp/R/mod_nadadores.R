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



    page_fillable(
      layout_sidebar(
        fillable = TRUE,
        

        sidebar = sidebar(
          width = 380, 
          bg = "#ffffff",
          title = div(
            h4("Filtros", class = "titulo-sidebar-mod-nadadores"),
            p("Búsqueda de nadadores", style = "font-size: 0.85rem; color: #6c757d; margin-top: 5px;")
          ),
          class = "sidebar-mod-nadadores",

        


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
    ) 
    ) 
  ) 
}
    
#' nadadores Server Functions
#'
#' @noRd 
mod_nadadores_server <- function(id, mensajero, sesion_padre){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    

    texto_nombre <- reactive({input$filtro_nombre}) |> debounce(500) # Así no busca cada palabra!!
    texto_apellidos <- reactive({input$filtro_apellidos}) |> debounce(500)

    
    nadadores_filtrados <- reactive({
      val_nombre <- trimws(texto_nombre())
      val_apellidos <- texto_apellidos()
      val_genero <- input$filtro_genero
      val_nacimiento <- input$filtro_nacimiento

      
      todo_vacio <- (is.null(val_nombre) || trimws(val_nombre) == "") &&
                    (is.null(val_apellidos) || trimws(val_apellidos) == "") &&
                    (is.null(val_genero) || trimws(val_genero) == "") &&
                    (is.na(val_nacimiento))
      
      if (todo_vacio) {
        return(data.frame())
      }

      

      df <- buscar_nadadores_api(nombre = val_nombre, apellidos = val_apellidos, genero = val_genero, nacimiento = val_nacimiento)

      return (df)
    })





    
    output$caja_tarjetas <- renderUI({
      df <- nadadores_filtrados() 
      
      if (nrow(df) == 0) return(NULL)
      
      
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
      
      
      layout_column_wrap(
        width = "250px", 
        fixed_width = TRUE,
        gap = "1rem",
        !!!lista_cards
      )
    })


    
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
      
      
      updateSelectInput(
        session = session, 
        inputId = "filtro_genero", 
        selected = ""                
      )
      
      
      updateNumericInput(
        session = session, 
        inputId = "filtro_nacimiento", 
        value = NA                   
      )
  
})

    
    
    
    observeEvent(input$nadador_clicado, {
      print(paste("¡Botón pulsado! ID detectado:", input$nadador_clicado))

      id_real <- input$nadador_clicado

      mensajero$id_nadador_seleccionado <- id_real
      
      bslib::nav_select(
        id = "menu_principal", 
        selected = "perfil_detallado", 
        session = sesion_padre 
      )
  
    })

    


 
  })
}
    
## To be copied in the UI
# mod_nadadores_ui("nadadores_1")
    
## To be copied in the server
# mod_nadadores_server("nadadores_1")
