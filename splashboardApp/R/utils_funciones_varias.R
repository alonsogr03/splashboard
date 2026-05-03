#' funciones_varias 
#'
#' @description A utils function
#'
#' @return The return value, if any, from executing the utility.
#'
#' @noRd
#' 
#' 

crear_descripcion_competicion <- function(name, city, course, timing, nation, pool_min_lane, pool_max_lane) {
  
  num_calles <- pool_max_lane - pool_min_lane + 1
  texto_montado <- paste0(
    "<b>📍 Ciudad:</b> ", city, "<br>",
    "<b>🏊 Tipo de piscina:</b> ", course, "<br>",
    "<b>⏱️ Cronometraje:</b> ", timing, "<br>",
    "<b>🌍 Nación organizadora:</b> ", nation, "<br>",
    "<b>📏 Número de calles:</b> ", num_calles
  )
  
  return(texto_montado)
}

# Función auxiliar para crear la card de bslib
crear_card_nadador <- function(ns, id_nadador, nombre, apellidos, nacimiento, foto_url) {
  card(
    class = "tarjeta-nadador shadow-sm h-100",
    full_screen = FALSE,
    card_image(
      file = foto_url,
      href = NULL, 
      height = "200px"
    ),
    card_body(
      class = "text-center",
      tags$h5(paste(nombre, apellidos), class = "mb-1"),
      tags$small(paste("Año:", nacimiento), class = "text-muted"),
      
      actionButton(
        inputId = ns(paste0("btn_ignorar_", id_nadador)), 
        label = "Ver Perfil Completo",
        icon = icon("user-check"),
        class = "btn-primary btn-sm mt-3 w-100",

        onclick = sprintf(
          "Shiny.setInputValue('%s', '%s', {priority: 'event'})", 
          ns("nadador_clicado"), 
          id_nadador
        )
      )
    )
  )
}