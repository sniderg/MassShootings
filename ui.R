#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(dplyr)
library(leaflet)
library(DT)

# Choices for drop-downs
vars <- c(
        "Casualties" = "casualties",
        "Killed" = "no_killed",
        "Injured" = "no_injured"
)


# Define UI 
shinyUI(
 

navbarPage(title = "Mass shootings in USA", id="nav",
           
           tabPanel(title = "Map",
          # Application title
                    
          tags$style(type = "text/css", "html, body {width:100%;height:100%}"),         
          
          leafletOutput("map",height = "800px"),
          
          # Sidebar with a slider input for number of bins
          absolutePanel(top = 100, right = 20, width = 300, draggable = TRUE,
                        
                        wellPanel(style = "opacity: 0.8",  
                        
                        h3("Data explorer"),
                        
                        selectInput("hurt", "Select metric", vars,selected = "Casualties"),
                        sliderInput("DateRange",
                                    "Dates:", step = 7,
                                    min = as.Date("2014-01-01","%Y-%m-%d"),
                                    max = as.Date("2018-03-31","%Y-%m-%d"),
                                    value = as.Date(c("2014-01-01","2018-03-31")),timeFormat="%Y-%m-%d"),
                       
                        #plot day of week and time of year shootings
                        plotOutput("bar",height = 300)
                        
                        )
            )),
          
          #Show table of distribution
          tabPanel(title = "Table", id="tab",
                   h4("All data from", a("gunviolencearchive.org",href="http://www.gunviolencearchive.org")),
                    DT::dataTableOutput(outputId = "leaftable"))
  
    )
)

