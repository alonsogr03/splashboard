#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function(input, output, session) {
  mensajero <- reactiveValues(
    id_nadador_seleccionado = NULL
  )


  mod_noticias_server("noticias_1", sesion_padre = session)
  mod_noticia_doha_server("noticia_doha_1")
  mod_noticia_estilos_server("noticia_estilos_1")
  mod_noticia_rt_server("noticia_rt_1")
  mod_noticia_swimseries_server("noticia_swimseries_1")
  mod_noticia_lublin_server("noticia_lublin_1")
  mod_marcas_server("marcas_1")
  mod_competiciones_server("competiciones_1")
  mod_nadadores_server("nadadores_1", 
                       mensajero = mensajero,
                       sesion_padre = session
                       )
  mod_perfil_nadador_server("perfil_nadador_1", mensajero = mensajero)
  
  # Vigila si alguien hace clic en el logo
  observeEvent(input$logo_inicio, {
    
    # Si hacen clic, fuerza al menú a cambiar a la pestaña "noticias"
    nav_select(
      id = "menu_principal", 
      selected = "noticias"
    )
    
  })

  

}
