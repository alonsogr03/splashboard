#' pagina_inicio UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 
mod_pagina_inicio_ui <- function(id) {
  ns <- NS(id)
  tagList(
 
  )
}
    
#' pagina_inicio Server Functions
#'
#' @noRd 
mod_pagina_inicio_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session$ns
 
  })
}
    
## To be copied in the UI
# mod_pagina_inicio_ui("pagina_inicio_1")
    
## To be copied in the server
# mod_pagina_inicio_server("pagina_inicio_1")
