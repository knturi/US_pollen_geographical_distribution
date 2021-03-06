
library(shiny)
server <- function(session, input, output) {
  
  Average_state_pollen<- cities_pollen %>%
    group_by(state) %>%
    summarize(state_pollen=mean(POLLSUM, na.rm = TRUE))
  
  reactive_pollen <- reactive({
    cities_pollen_spec_long_nogeo %>%
      group_by(state, city) %>%
      summarize(city_pollen=mean(POLLSUM, na.rm = TRUE)) %>% 
      arrange(state, city, desc(city_pollen), by_group=TRUE) %>%
      dplyr::filter(state==input$state) %>%
      mutate(city = fct_reorder(city, desc(city_pollen)))
  }
  )
  
  reactive_species <- reactive({
    cities_pollen_spec_long_nogeo %>%
      filter(value!=0| value!=NA) %>%
      group_by(state, city) %>% 
      arrange(state, city, desc(value), by_group=TRUE) %>% 
      slice_max(order_by = value, n=10) %>% 
      filter(state %in% input$state & city %in% input$city) %>%
      mutate(species = fct_reorder(species, desc(value)))
  })
  
  observe({
    updateSelectInput(session, 
                      "city",
                      choices = unique(cities_pollen_spec_long_nogeo[cities_pollen_spec_long_nogeo$state %in%
                                                                       input$state, "city"]))
  })
  
  output$Avrg_st_pollen <- renderPlot(
    ggplot(Average_state_pollen) + geom_col(aes(x=reorder(state, -state_pollen), y=state_pollen),fill="dark blue") +
      theme(plot.title = element_text(size = 24, face = "bold"),
            axis.title = element_text(size = 20),
            axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1, size = 14) ) +
      labs(title="States with total pollen count",
           x ="State", y = "Pollen count")
  )
  
  output$Avrg_cty_pollen <- renderPlot(
    ggplot(reactive_pollen()) + geom_col(aes(x=reorder(city, -city_pollen), y=city_pollen),fill="steelblue") +
      theme(plot.title = element_text(size = 24, face = "bold"),
            axis.title = element_text(size = 20),
            axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1, size = 14) ) +
      labs(title="Cities with total pollen count",
           x ="Cities", y = "Pollen count")
    
  )
  
  output$citytopspecies <- renderPlot(
    ggplot(reactive_species(), aes(species, value)) + 
      geom_col(fill="green") +
      theme(plot.title = element_text(size = 24, face = "bold"),
            axis.title = element_text(size = 20),
            axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1, size = 14)) +
      labs(title="Top pollen genuses",
           x ="Genus", y = "Pollen count")
  )
  
  output$mymap <- renderLeaflet({
    leaflet(width = 800, height = 1000) %>%  
      addProviderTiles("OpenStreetMap") %>%
      addAwesomeMarkers(lat = pollen_spec_clean_usa$latitude, 
                        lng = pollen_spec_clean_usa$longitude,
                        clusterOptions = markerClusterOptions(),
                        icon = awesomeIcons(icon = "flower-sharp", markerColor = 'green'),
                        popup = paste("Genus: ", pollen_spec_clean_usa$species,"<br/>Pollen count: ", pollen_spec_clean_usa$value)) %>% 
      setView(map, lng = -96,
              lat = 37.8,
              zoom = 5) 
  })
}


