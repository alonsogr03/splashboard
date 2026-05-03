# Splashboard: Federación Mundial de Natación

## 1. Descripción del Proyecto y Objetivos
**Splashboard** es una página web interactiva diseñado para la visualización y análisis de datos de natación de élite. El objetivo principal es transformar datos brutos de competición en insights para entrenadores, analistas y nadadores.

La aplicación permite explorar récords, competiciones, noticias  y realizar un seguimiento detallado de nadadores individuales, todo bajo una misma interfaz.

## 2. Estructura del Dashboard y Funcionalidades
El proyecto se ha desarrollado siguiendo la metodología **`golem`**, estructurando la aplicación como un paquete de R para asegurar su escalabilidad y robustez.

- **Página de Inicio (Noticias):** Un portal dinámico con análisis periodísticos basados en datos reales (Doha 2024, Ciclo Olímpico, etc.).
- **Explorador de Marcas:** Buscador avanzado con filtrado dinámico por estilo, distancia y tipo de piscina.
- **Competiciones:** Mapa interactivo (`leaflet`) y calendario (`toastui`) para la gestión de eventos mundiales.
- **Buscador de Nadadores:** Interfaz de tarjetas con búsqueda *debounced* para consultar perfiles de atletas.
- **Perfil Detallado:** Vista profunda de un nadador con su historial de competiciones y mejores marcas personales.

## 3. Origen y Preparación de los Datos
- **Origen:** Datos extraídos de [Omega Timing](https://www.omegatiming.com) en formato XML (2022-2026).
- **Volumen:** 40 competiciones internacionales de alto nivel.
- **Procesado:** Los datos fueron parseados y limpiados mediante scripts de R y Python (disponibles en las carpetas `/scripts` y `/notebooks`).
- **Infraestructura:** Los datos se alojan en una base de datos **Supabase (PostgreSQL)**, consultada en tiempo real mediante una API REST con el paquete `httr2`. El esquema SQL se encuentra en la carpeta `/database`.

## 4. Distribución del Trabajo
El proyecto se ha desarrollado de manera individual. 
*Nota: Se ha contado con la asistencia de IA (Gemini) específicamente para la optimización de estilos CSS y efectos visuales avanzados.*

## 5. Enlace al Despliegue
La aplicación está disponible en el siguiente enlace:
 **[[Enlace a la Aplicación Web Desplegada](https://alonsogr03.shinyapps.io/fed-natacion-app/)]**

## 6. Fundamentos de Visualización de Datos
Se han aplicado principios de comunicación visual para maximizar el impacto de los datos:
- **Gráficos de Densidad:** Utilizados en el análisis de tiempos de reacción para comparar distribuciones estadísticas (Espalda vs Otros).
- **Boxplots Interactivos:** Para mostrar la varianza y periodización de marcas durante el ciclo olímpico.
- **Lollipop Charts:** En el análisis de Doha para destacar jerarquías en las finales sin saturar visualmente.
- **Reactividad Modular:** Uso de `bslib` y `plotly` para que el usuario explore los datos sin tiempos de carga innecesarios.

## 7. Conclusiones y Mejoras Futuras
El dashboard demuestra que una página web sencilla que involucre todos los datos de nadadores puede ser creada. Las federaciones españolas actuales tienen páginas web muy poco legibles en las que, es muy dificil navegar entre competiciones, o incluso ver tus propios resultados. También existe una falta de noticias a través del dato.

**Futuras líneas de desarrollo:**
1. **Módulo de Administración:** Panel para que periodistas redacten noticias directamente en la app.
2. **Ingesta Automatizada:** Sistema de carga de archivos XML para que los resultados de nuevas competiciones se sincronicen automáticamente con Supabase.
3. **Modelos Predictivos:** Implementación de Machine Learning para clasificar tipos de nadadores, competiciones o clubes.