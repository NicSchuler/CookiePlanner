# This is the user-interface definition of a Shiny web application. 

library(shiny)
library(shinythemes)
library(DT)
library(shinyWidgets)

# Define UI for application that draws a histogram
shinyUI(fluidPage(theme=shinytheme("yeti"), #setBackgroundColor(color="grey"),
                  
                  # initialize tab layout
                  navbarPage(title="CookiePlanner",
                             
                             # First Tab: load input
                             tabPanel("Load Input", icon=icon("upload"), 
                                      
                                      h1("Upload Recipes"),
                                      br(),
                                      
                                      sidebarLayout(
                                      
                                      # left panel
                                      sidebarPanel(
                                      # file input for input excel
                                      fileInput(inputId="excel", label = "Please select your input excel sheet.", multiple=FALSE, accept=c(".xlsx")),
                                      actionButton("load_excel", label = "Load Input"),
                                      br(),
                                      textOutput("load_info")),
                                      
                                      # main panel
                                      mainPanel(HTML("<p>Please use the template provided on <a href='https://github.com/NicSchuler/CookiePlanner'>Github</a>. You will also find some explanations to the functionalities in this app there.</p>"))
                                      
                             )),
                             
                             # Second Tab: Define Quantities
                             tabPanel("Plan Cookies", icon=icon("list"),
                                      
                                      h1("Plan your cookie production"),
                                      br(),
                                      splitLayout(cellWidths = c("45%", "55%"), cellArgs = list(style='white-space: normal;'),
                                                  p("To plan your cookie production, please use the input panel below.
                                                    You can either enter the multiplier directly (column 'Simple Multiplier') or specify the amount of one specific ingredient (only those that have App_Qty_Input = 'Yes').
                                                    Please be aware that only one non-zero or non-empty value is allowed per row.
                                                    To edit a cell you will need to double-click it."),
                                                  panel(
                                                    p(strong("Total Ingredients required")),
                                                    DTOutput(outputId = "totals_output")
                                                  )),
                                      splitLayout(cellWidths = c("35%", "10%", "55%"),
                                        panel(p(strong("Input")),
                                              DTOutput(outputId = "qty_input")),
                                        panel(p(strong("Multiplier")),
                                              DTOutput(outputId = "multiplier_output")),
                                        panel(p(strong("Output")),
                                              DTOutput(outputId = "qty_output"))
                             ))
                             
                  )
))
