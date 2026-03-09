#' The application User-Interface
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @import bslib
#' @noRd
app_ui <- function(request) {
  tagList(
    golem_add_external_resources(),
    
    # ¡Aquí empieza tu barra de navegación!
    page_navbar(
      title = "Splashboard", 
      id = "nav",
      theme = bs_theme(preset = "cerulean"), 
      
      # Pestaña 1: Inicio
      nav_panel(
        title = "Inicio", 
        h2("Bienvenido a Splashboard", class = "mt-4 text-center"),
        p("Aquí irán las noticias de las competiciones.", class = "text-center")
      ),
      
      # Pestaña 2: Competiciones
      nav_panel(
        title = "Competiciones", 
        h2("Página de Competiciones", class = "mt-4")
      ),
      
      # Pestaña 3: Estadísticas
      nav_panel(
        title = "Estadísticas y Marcas", 
        h2("Análisis de Rendimiento", class = "mt-4")
      )
    )
  )
}

#' Add external Resources to the Application
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path(
    "www",
    app_sys("app/www")
  )

  tags$head(
    favicon(),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = "splashboardApp"
    )
  )
}