#
# This is the server logic of a Shiny web application. 
#
# More about building applications with Shiny here:
#    http://shiny.rstudio.com/
#

library(shiny)
library(leaflet)
library(leaflet.extras)
library(dplyr)
library(ggplot2)
library(ggpubr)
library(lubridate)

shootings <- read.csv(file = "data/shootingTracker2014_2018.csv",stringsAsFactors = F) 

shootings$formattedDate <- as.Date(shootings$formattedDate)
shootings$dayofweek <- ordered(shootings$dayofweek, 
                               levels=c("Mon", "Tues", "Wed", "Thurs", "Fri", "Sat", "Sun"))

shootings$month <- as.Date(cut(as.Date(shootings$formattedDate), "month"))
shootings$month2 <- month(shootings$formattedDate, label = T)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
   
   shootingsSub <- reactive({
                shootings %>% 
                        filter(formattedDate >= input$DateRange[1]) %>% 
                        filter(formattedDate <= input$DateRange[2])
        })
        
   output$map <- renderLeaflet({
                   leaflet() %>%
                  
                   addProviderTiles(provider = providers$Esri.WorldTopoMap, 
                                    options = providerTileOptions(noWrap = F)) %>%
                  
                   #default view 
                   setView(lat=37,lng = -88,zoom=3) 
  
                })
   
   
   InBounds <- reactive({
           if (is.null(input$map_bounds))
                   return(shootingsSub()[FALSE,])
           bounds <- input$map_bounds
           latRng <- range(bounds$north, bounds$south)
           lngRng <- range(bounds$east, bounds$west)
           
           subset(shootingsSub(),
                  lat >= latRng[1] & lat <= latRng[2] &
                          lng >= lngRng[1] & lng <= lngRng[2])
   })
   
   ak47Icon <- makeIcon(iconUrl = "ak47.png", iconWidth = 27, iconHeight = 27)
   
   observe({
           leafletProxy("map") %>%
           clearMarkers() %>% clearMarkerClusters() %>% clearHeatmap() %>%
           addHeatmap(data = shootingsSub(), lng= shootingsSub()$lng, lat= shootingsSub()$lat, 
                      max=0.8, blur = 50,radius = 30)  %>%         
           addMarkers(data = shootingsSub(), lat = shootingsSub()$lat, lng = shootingsSub()$lng, 
                      icon = ak47Icon,
                      clusterOptions = markerClusterOptions(), 
                      popup = sprintf("Date: %s <br/> Killed: %s <br/> Injured: %s <br/> %s", 
                                shootingsSub()$incident_date,
                                shootingsSub()$no_killed, shootingsSub()$no_injured,
                                shootingsSub()$moreInfo)) 
                
   })
   
   #output table
   output$leaftable <- DT::renderDataTable({
           
           datatable(data = shootingsSub() %>% select(-moreInfo,-GoogleAdd,-formattedDate,-month), 
                     extensions = 'Buttons', 
                     options = list(
                             dom = 'Blfrtip',
                             buttons = c("csv","excel"),
                             
                             # customize the length menu
                             lengthMenu = list( c(10, -1) # declare values
                                                , c(10, "All") # declare titles
                                                
                             )
                     )
           )
          
            })
   
   output$bar <- renderPlot({
           if (nrow(InBounds()) == 0)
                   return(NULL)
           

           temp <- InBounds()
           
           temp <- temp[names(temp) %in% c(input$hurt,"dayofweek","month2")]
          
           names(temp) <- c("y","x","time") 
           
           #day of week
           g1 <- ggplot(temp,aes(x=x, y=y)) + geom_bar(stat="identity",fill="blue") + 
                   labs(title = sprintf("%s in viewable area is %d",input$hurt,sum(temp$y)), x= "weekday", y ="count") +
                   theme_minimal()
           #month of year
           g2 <- ggplot(temp,aes(x=time, y=y)) + geom_bar(stat="identity",fill="red") + 
                   labs(x= "date", y ="count") + theme_minimal()
           
           gout <- ggarrange(g1,g2,nrow = 2)
           
           gout
           
           
   })
  
   
    
})
