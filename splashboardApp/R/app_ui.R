#' The application User-Interface
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @import bslib
#' @noRd
app_ui <- function(request) {
  tagList(
    golem_add_external_resources(),
    page_fluid(
      theme = bs_theme(preset = "minty"),

      # Cabecera con logo y nombre de la aplicacion
      div(
        id = "cabecera_hero",
        class = "d-flex flex-column justify-content-center align-items-center text-center",
        
        tags$a(
          id = "logo_inicio",
          class = "action-button", 
          href = "#", 
          tags$img(
            src = "www/logo_federacion.png", 
            class = "logo-hero", 
            alt = "Logo Federación"
          )
        ),
        
        h1("Federación Mundial de Natación", class = "titulo-hero"),
        p("Construyendo deporte", class = "lema-hero"),
        p("Dedicación • Trabajo en equipo • Esfuerzo", class = "sublema-hero")   
      ), 

      # Menú de navegación
      navset_underline(
        id = "menu_principal",
        selected = "noticias", 
        
        # PÁGINAS OCULTAS
          nav_panel_hidden(
            value = "noticias",
            mod_noticias_ui("noticias_1") 
          ),
          # PÁGINAS VISIBLES EN EL MENÚ
          nav_panel("Marcas", mod_marcas_ui("marcas_1")),
          nav_panel_hidden(
            value = "estudio_lublin", 
            mod_noticia_lublin_ui("noticia_lublin_1")
          ),
          nav_panel_hidden(
            value = "perfil_detallado",
            mod_perfil_nadador_ui("perfil_nadador_1")
          ),
          nav_panel("Competiciones", mod_competiciones_ui("competiciones_1")),
          nav_panel_hidden(
            value = "estudio_rt", 
            mod_noticia_rt_ui("noticia_rt_1")
          ),
          nav_panel_hidden(
            value = "estudio_swimseries", 
            mod_noticia_swimseries_ui("noticia_swimseries_1")
          ), 
          nav_panel("Nadadores", mod_nadadores_ui("nadadores_1")), 
          nav_panel_hidden(
            value = "estudio_doha", 
            mod_noticia_doha_ui("noticia_doha_1")
          ),
          nav_panel_hidden(
            value = "estudio_estilos", 
            mod_noticia_estilos_ui("noticia_estilos_1")
          )


        )
  ))
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