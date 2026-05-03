# 🏊‍♂️ World Swimming Dashboard: End-to-End Data Pipeline

Este proyecto es un ecosistema completo de análisis de datos deportivos, desde la captación de resultados oficiales hasta la visualización avanzada para la toma de decisiones.

## 🚀 Enlace al proyecto
[Ver Aplicación en Vivo](https://alonsogr03.shinyapps.io/fed-natacion-app/)

## 🛠️ Arquitectura del Proyecto

El flujo de trabajo se divide en tres etapas principales:

### 1. Ingesta y ETL (Extract, Transform, Load)
- **Origen:** Datos extraídos de **Omega Timing** (formatos complejos de cronometraje oficial).
- **Procesamiento:** Scripts en R para la limpieza, normalización de nombres de nadadores, validación de tiempos y cálculo de puntos FINA.
- **Tecnologías:** `tidyverse`, `rvest`.

### 2. Infraestructura de Datos (Supabase)
- Los datos procesados se alojan en una base de datos relacional **PostgreSQL** en **Supabase**.
- Se ha diseñado un esquema optimizado para consultas rápidas de marcas históricas, perfiles de nadadores y calendarios de competiciones.
- La comunicación se realiza mediante una **API RESTful**.

### 3. Visualización (Shiny App con Golem)
- **Framework:** Desarrollado bajo la estructura de paquete `golem` para asegurar robustez y escalabilidad.
- **Módulos:**
  - **Mapa Mundial:** Localización de sedes mediante `leaflet`.
  - **Análisis de Marcas:** Evolución de tiempos y comparativas dinámicas.
  - **Perfil del Nadador:** Dashboard individualizado con marcas personales.
- **UI/UX:** Diseño institucional utilizando `bslib` y CSS personalizado.