#' Noticia RT UI Function
#' @import shiny bslib plotly
#' @noRd
mod_noticia_rt_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    shiny::div(
      class = "container mt-5 mb-5 shadow-sm p-5 bg-white rounded-4",
      style = "max-width: 1000px; border-top: 8px solid #0A2463;",
      
      # Cabecera periodística
      shiny::div(
        class = "text-center mb-4",
        shiny::h1("La Ciencia del Tiempo de Reacción", 
           style = "color: #0A2463; font-weight: 900; font-family: 'Montserrat', sans-serif; font-size: 2.8rem; line-height: 1.2;"),
        shiny::p(class = "lead text-muted fw-bold", "¿Supone realmente una ventaja estadística la salida de espalda tras el sonido de la bocina?"),
        shiny::hr(style = "width: 80px; margin: 20px auto; border-top: 3px solid #3E92CC;")
      ),
      
      # Firma
      shiny::div(
        class = "d-flex align-items-center mb-5 p-3 rounded-3",
        style = "background-color: #f1f4f9;",
        shiny::tags$img(src = "www/foto_perfil_periodista.png", style = "width: 60px; height: 60px; border-radius: 50%; border: 2px solid #0A2463;"),
        shiny::div(
          style = "margin-left: 15px;",
          shiny::h6("Por Alonso González Romero", style = "margin:0; font-weight: 800; color: #0A2463;"),
          shiny::p("Estudiante MUSA | a.gonzalezr.2021@alumnos.urjc.es", style = "margin:0; font-size: 0.85rem; color: #666;")
        )
      ),
      
      # Introducción y Narrativa
      shiny::div(
        style = "font-size: 1.15rem; line-height: 1.8; color: #444;",
        
        shiny::p("Pocas cosas deciden el color de una medalla en escasas centésimas como la efectividad impulsiva desde el poyete de salida. En natación competitiva, el ", shiny::tags$strong("Tiempo de Reacción (RT)"), " mide exactamente los milisegundos que transcurren desde que un altavoz emite la señal acústica de inicio ('Take your marks... BEEP'), hasta que los pies del deportista pierden contacto con la plataforma."),
        
        shiny::p("Históricamente, existe una narrativa en los bordes de la piscina que sugiere que los nadadores de ", shiny::tags$em("Espalda"), " cuentan con una ventaja intrínseca. A diferencia de las pruebas de Libres, Mariposa o Braza —donde el atleta debe luchar contra la gravedad proyectando su cuerpo hacia delante desde el bloque—, el espaldista reacciona suspendido en el agua, utilizando la pared como un resorte balístico directo. ¿Se traduce esta diferencia biomecánica en un tiempo de reacción más rápido a nivel global?"),
        
        # Gráfico 1: Global
        bslib::card(
          style = "border: none; box-shadow: 0 4px 15px rgba(10,36,99,0.08); margin-top: 30px; margin-bottom: 40px;",
          bslib::card_header(shiny::h4("Densidad de Tiempo de Reacción Global (Espalda vs Resto)", style="margin:0; font-weight: 700; color: #0A2463;")),
          bslib::card_body(plotly::plotlyOutput(ns("plot_densidad_global"), height = "400px"))
        ),
        
        shiny::p("Al observar la curva de densidad global, la respuesta visual es contundente. La campana correspondiente a la salida de espalda (en azul claro) presenta un desplazamiento evidente hacia la izquierda, lo que indica una mayor concentración de tiempos bajos frente al resto de estilos (en azul oscuro)."),
        
        shiny::h3("¿Afecta la Biomecánica por Género?", style = "color: #0A2463; font-weight: 800; margin-top: 40px; margin-bottom: 20px;"),
        shiny::p("Para asegurar que esta ventaja biomecánica no es un sesgo dependiente de la masa muscular o la potencia de impulso que varía entre hombres y mujeres, hemos segmentado los datos. Si la teoría del 'resorte en la pared' es universal, el patrón debe replicarse idénticamente en ambos cuadros."),
        
        # Gráficos Separados por Género (Aumentados a 450px para la leyenda)
        bslib::layout_columns(
          col_widths = c(6, 6),
          bslib::card(
            style = "border: none; box-shadow: 0 4px 15px rgba(10,36,99,0.08); border-top: 5px solid #F48FB1;",
            bslib::card_header(shiny::h5("Femenino 🚺", style="margin:0; font-weight: 700; text-align: center; color: #0A2463;")),
            bslib::card_body(plotly::plotlyOutput(ns("plot_densidad_f"), height = "450px"))
          ),
          bslib::card(
            style = "border: none; box-shadow: 0 4px 15px rgba(10,36,99,0.08); border-top: 5px solid #90CAF9;",
            bslib::card_header(shiny::h5("Masculino 🚹", style="margin:0; font-weight: 700; text-align: center; color: #0A2463;")),
            bslib::card_body(plotly::plotlyOutput(ns("plot_densidad_m"), height = "450px"))
          )
        ),
        
        # Tarjeta Estadística (P-Valores)
        shiny::h3("Veredicto Estadístico (Test de Student)", style = "color: #0A2463; font-weight: 800; margin-top: 40px; margin-bottom: 20px;"),
        shiny::p("Las gráficas nos dan la intuición, pero los test de hipótesis nos dan la certeza. Hemos sometido nuestra base de datos a un T-Test para comparar si la diferencia en milisegundos es obra del azar o una ventaja estructural probada."),
        
        shiny::uiOutput(ns("tarjeta_estadistica")),
        
        shiny::br(),
        
        shiny::p(shiny::tags$strong("Conclusión: "), "Los datos no mienten. A la vista de los p-valores generados (todos muy por debajo del umbral del 0.05), podemos afirmar categóricamente que ", shiny::tags$em("salir de espalda es estadísticamente más rápido"), ". En promedio, un nadador de espalda gana ", shiny::tags$strong("aproximadamente 1 décima de segundo (0.1s)"), " extra en el tiempo de reacción solo por la naturaleza de la posición de salida. En un deporte donde el oro y quedarse fuera del podio se decide en centésimas, esta décima de 'regalo' biomecánico es un universo de diferencia.")
      )
    )
  )
}

#' Noticia RT Server Function
#' @noRd
mod_noticia_rt_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # 1. Traer datos
    datos_rt <- shiny::reactive({
      obtener_datos_reaccion_rt()
    })
    
    # Función auxiliar para plotear densidades
    generar_plot_densidad <- function(df) {
      shiny::req(nrow(df) > 10) 
      
      back <- df$reactiontime[df$grupo_estilo == "Espalda"]
      resto <- df$reactiontime[df$grupo_estilo == "Resto de Estilos"]
      
      dens_back <- density(back, na.rm = TRUE)
      dens_resto <- density(resto, na.rm = TRUE)
      
      plotly::plot_ly() |>
        plotly::add_lines(x = ~dens_back$x, y = ~dens_back$y, name = "Espalda (BACK)", 
                          fill = 'tozeroy', fillcolor = 'rgba(62,146,204,0.4)', 
                          line = list(color = '#3E92CC', width=3)) |>
        plotly::add_lines(x = ~dens_resto$x, y = ~dens_resto$y, name = "Resto (Libre/Braza/Mariposa)", 
                          fill = 'tozeroy', fillcolor = 'rgba(10,36,99,0.4)', 
                          line = list(color = '#0A2463', width=3)) |>
        plotly::layout(
          xaxis = list(title = "Tiempo de Reacción (s)"),
          yaxis = list(title = "Densidad", showticklabels = FALSE),
          # Leyenda ajustada para que no estorbe abajo
          legend = list(orientation = 'h', x = 0, y = -0.3),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          hovermode = "x unified",
          margin = list(b = 60) # Más margen inferior para la leyenda
        )
    }
    
    # Render Plot 1: Global
    output$plot_densidad_global <- plotly::renderPlotly({
      generar_plot_densidad(datos_rt())
    })
    
    # Render Plot 2: Femenino
    output$plot_densidad_f <- plotly::renderPlotly({
      df_f <- datos_rt() |> dplyr::filter(gender == "F")
      generar_plot_densidad(df_f)
    })
    
    # Render Plot 3: Masculino
    output$plot_densidad_m <- plotly::renderPlotly({
      df_m <- datos_rt() |> dplyr::filter(gender == "M")
      generar_plot_densidad(df_m)
    })
    
    # Tarjeta de Análisis Estadístico (P-Valores)
    output$tarjeta_estadistica <- shiny::renderUI({
      df <- datos_rt()
      shiny::req(nrow(df) > 0)
      
      # Función auxiliar para T-Test sin problemas de NA
      calcular_test <- function(data) {
        test <- t.test(reactiontime ~ grupo_estilo, data = data)
        
        # Forzamos el cálculo de medias exactas para asegurar el orden
        media_espalda <- mean(data$reactiontime[data$grupo_estilo == "Espalda"], na.rm = TRUE)
        media_resto <- mean(data$reactiontime[data$grupo_estilo == "Resto de Estilos"], na.rm = TRUE)
        
        list(
          media_back = round(media_espalda, 3),
          media_resto = round(media_resto, 3),
          p_valor_str = format.pval(test$p.value, eps = 0.001), # String para imprimir
          is_sig = test$p.value < 0.05                          # Booleano real para lógica
        )
      }
      
      res_global <- calcular_test(df)
      res_f <- calcular_test(df[df$gender == "F", ])
      res_m <- calcular_test(df[df$gender == "M", ])
      
      # Construcción de la tabla
      shiny::HTML(paste0("
        <div class='table-responsive'>
          <table class='table table-bordered table-hover' style='background-color: #fff; text-align: center; border-radius: 10px; overflow: hidden; box-shadow: 0 4px 10px rgba(0,0,0,0.05); font-size: 1.1rem;'>
            <thead style='background-color: #0A2463; color: white;'>
              <tr>
                <th>Categoría</th>
                <th>Media Espalda (s)</th>
                <th>Media Resto (s)</th>
                <th>P-Valor</th>
                <th>Significancia (< 0.05)</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td style='font-weight: bold;'>Global Absoluto</td>
                <td>", res_global$media_back, "</td>
                <td>", res_global$media_resto, "</td>
                <td style='font-weight: bold; color: ", ifelse(res_global$is_sig, "#28a745", "#dc3545"), ";'>", res_global$p_valor_str, "</td>
                <td>", ifelse(res_global$is_sig, "✅ Sí", "❌ No"), "</td>
              </tr>
              <tr>
                <td style='font-weight: bold; color: #E1306C;'>Femenino</td>
                <td>", res_f$media_back, "</td>
                <td>", res_f$media_resto, "</td>
                <td style='font-weight: bold; color: ", ifelse(res_f$is_sig, "#28a745", "#dc3545"), ";'>", res_f$p_valor_str, "</td>
                <td>", ifelse(res_f$is_sig, "✅ Sí", "❌ No"), "</td>
              </tr>
              <tr>
                <td style='font-weight: bold; color: #3E92CC;'>Masculino</td>
                <td>", res_m$media_back, "</td>
                <td>", res_m$media_resto, "</td>
                <td style='font-weight: bold; color: ", ifelse(res_m$is_sig, "#28a745", "#dc3545"), ";'>", res_m$p_valor_str, "</td>
                <td>", ifelse(res_m$is_sig, "✅ Sí", "❌ No"), "</td>
              </tr>
            </tbody>
          </table>
        </div>
      "))
    })
    
  })
}