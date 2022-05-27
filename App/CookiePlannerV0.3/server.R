# This is the server logic of a Shiny web application. 

# load packages----
library(shiny)
library(readxl)
library(dplyr)
library(tidyr)
library(R.utils)
library(shinythemes)
library(DT)
library(writexl)
library(hdd)

# define own functions----

# # Function that loads the ingredients and recipes tables from the input excel and processes them
# # Not working in the deployed app, therefore loading 2 csvs
# load_input_excel <- function(file="Input_Excel.xlsx"){
#   # read the ingredients table
#   ingredients_tbl <- read_excel(path=file, sheet="Ingredients") %>%
#     select(Number, Ingredient, Measure, App_Qty_Input, Ingr_full_name) %>%
#     filter(!is.na(Ingredient))
# 
#   ingr <- ingredients_tbl$Ingr_full_name
# 
#   # read the recipes table
#   recipes_tbl <- read_excel(path=file, sheet="Recipes") %>%
#     select(c("Number", "Recipe", "Comment", all_of(ingr))) %>%
#     filter(!is.na(Recipe)) %>%
#     mutate_at(c(4:(length(ingr)+3)), ~replace(., is.na(.), 0))
# 
#   # combine ingredients and recipes table to a list and return the list
#   data <- list(ingredients=ingredients_tbl, recipes=recipes_tbl)
# 
#   return(data)
# }

# Function that loads the ingredients and recipes tables from the input csvs and processes them
load_input_csvs <- function(ingredients_csv, recipes_csv){
  # read the ingredients table
  ingredients_tbl <- read.csv2(file=ingredients_csv, encoding = "UTF-8", sep=guess_delim(ingredients_csv), dec=".") %>%
    rename(Number=1) %>% 
    select(Number, Ingredient, Measure, App_Qty_Input, Ingr_full_name) %>%
    filter(!is.na(Ingredient) & Ingredient !="")
  
  ingr <- ingredients_tbl$Ingr_full_name
  
  # read the recipes table
  recipes_tbl <- read.csv2(file=recipes_csv, encoding = "UTF-8", sep=guess_delim(recipes_csv), dec=".", col.names = c("Number", "Recipe", "Comment", all_of(ingr), paste("X", c(1:(30-length(ingr))), sep="")), check.names=FALSE) %>%
    select(c("Number", "Recipe", "Comment", all_of(ingr))) %>%
    filter(!is.na(Recipe) & Recipe !="") %>%
    mutate_all(~replace_na(., 0))
  
  # combine ingredients and recipes table to a list and return the list
  data <- list(ingredients=ingredients_tbl, recipes=recipes_tbl)
  
  return(data)
}


# function that initializes the quantity input table (bottom left in the app), given the recipes and ingredients from the input excel
create_qty_input_table <- function(data=loaded_data){
  # create vector with all ingredients for which it is possible to enter the quantity
  ingr_to_incl <- (data$ingredients %>% filter(App_Qty_Input == "Yes"))$Ingr_full_name
  
  # default values: Multiplier = 1, input ingredients = 0
  qty_input_table <- data$recipes %>% select(Recipe)
  qty_input_table[,"Multiplier"] <- 1
  for(ingr in ingr_to_incl){
    qty_input_table[,ingr] <- 0
  }
  
  return(qty_input_table)
  
}

# function that computes a table with the multipliers and required ingredients based on the quantity input table and the loaded excel
derive_qty_output_table <- function(qty_input, data=loaded_data){
  # create vectors with all input ingredients and all ingredients
  inp_ingr=(data$ingredients %>% filter(App_Qty_Input=="Yes"))$Ingr_full_name
  all_ingr=data$ingredients$Ingr_full_name
  
  # derive the multiplier per recipe based on the input table
  multipliers <- qty_input %>%
    mutate(negs=rowSums(.<0, na.rm=TRUE)) %>% 
    filter(negs==0) %>% 
    mutate(counter=rowSums(.!=0&.!=""&!is.na(.))-1) %>% 
    filter(counter==1) %>% 
    pivot_longer(cols=c(all_of(inp_ingr), "Multiplier"), names_to = "ingr", values_to = "val_inp") %>% 
    filter(val_inp!=0&val_inp!="") %>% 
    left_join((data$recipes %>% 
                 mutate("Multiplier"=1) %>%
                 select(c(Recipe, "Multiplier", all_of(inp_ingr))) %>% 
                 pivot_longer(cols=c(all_of(inp_ingr), "Multiplier"), names_to = "ingr", values_to = "val_rec")),
              by=c("Recipe", "ingr")) %>% 
    mutate(Multiplier=val_inp/val_rec) %>% 
    select(Recipe, Multiplier)
  
  # scale all ingredients for all recipes based on the multiplier
  out <- data$recipes %>% 
    left_join(multipliers, by="Recipe") %>% 
    mutate(Multiplier=replace_na(Multiplier,0)) %>% 
    select(Recipe, all_of(all_ingr), Multiplier) %>% 
    mutate(across(all_of(all_ingr), ~ round(.* Multiplier,2))) %>% 
    mutate(Multiplier=round(Multiplier,2))
  
  return(out)
}

# function that creates the total quantity per ingredient given the required quantities per recipe
derive_totals_table <- function(qty_output_table){
  out <- qty_output_table %>% 
    select(-c(Multiplier)) %>% 
    summarize_all(sum)
  
  return(out)
}

# Server----
shinyServer(function(input, output) {
  # 1. Load input page----
  # process uploaded data when load button is pressed
  loaded_data <- eventReactive(input$load_excel, {
    ingr_file <- input$ingr_csv
    reci_file <- input$reci_csv
    load_input_csvs(ingredients_csv = ingr_file$datapath, recipes_csv = reci_file$datapath)})
  
  # Give info whether loading data was successful
  output$load_info <- renderText({tryCatch({suppressWarnings(paste("You have successfully loaded ", nrow(loaded_data()$recipes), " recipes with ", nrow(loaded_data()$ingredients), " different ingredients.", sep=""))}, error=function(cond){return("No data loaded.")})})
  
  # 2. Plan cookies page----
  # initialize reactive value for the quantity input table
  qty <- reactiveValues(x=NULL)
  
  # initialize quantity input table based on loaded data
  observe({qty$x <- create_qty_input_table(data=loaded_data())})
  
  # update quantity input table internally after it has been edited
  observeEvent(input$qty_input_cell_edit, {
    qty$x <<- editData(qty$x, input$qty_input_cell_edit, 'qty_input', rownames = FALSE)
  })
  
  # calculate multipliers and required quantities per recipe based on quantity input table
  qty_output_table <- reactive({derive_qty_output_table(qty_input = qty$x, data=loaded_data())})
  
  # calculate totals table based on required quantities per recipe
  totals_table <- reactive({derive_totals_table(qty_output_table = qty_output_table() %>% select(-Recipe))})
  
  # render quantity input table
  output$qty_input <- renderDT(if(is.null(qty$x)){datatable(data.frame(Input="No data loaded"), rownames=FALSE, options = list(dom='t',ordering=F), selection = 'none')}
                               else{tryCatch({datatable(qty$x, rownames=FALSE, editable=list(target = 'cell', disable = list(columns = c(0))), extensions = c("FixedHeader", "FixedColumns"), fillContainer = TRUE,
                                                        options = list(dom='t',ordering=F,escape=F, pageLength=nrow(loaded_data()$recipes), fixedHeader=TRUE, fixedColumns = list(leftColumns = 1), scrollY=30+34*nrow(loaded_data()$recipes)), selection = 'none')},
                                             error=function(cond){return(datatable(data.frame(Input="No data loaded"), rownames=FALSE, options = list(dom='t',ordering=F), selection = 'none'))})})
  
  # # render multiplier table
  # output$multiplier_output <- renderDT({tryCatch({datatable(qty_output_table() %>% select(Multiplier), rownames=FALSE, editable=FALSE,
  #                                                           options = list(dom='t',ordering=F, pageLength=nrow(loaded_data()$recipes)), selection = 'none')},
  #                                                error=function(cond){return(datatable(data.frame(Multipliers="No data loaded"), rownames=FALSE, options = list(dom='t',ordering=F), selection = 'none'))})})
  
  # render quantity required per recipe table
  output$qty_output <- renderDT({tryCatch({datatable(qty_output_table() %>% select(-Multiplier) %>% select(-Recipe), rownames=FALSE, editable=FALSE, extensions = "FixedHeader", fillContainer = TRUE,
                                                     options = list(dom='t',ordering=F, pageLength=nrow(loaded_data()$recipes), fixedHeader=TRUE, scrollY = 30+34*nrow(loaded_data()$recipes)), selection = 'none')},
                                          error=function(cond){return(datatable(data.frame(Output="No data loaded"), rownames=FALSE, options = list(dom='t',ordering=F), selection = 'none'))})})
  
  # render totals table (per ingredient)
  output$totals_output <- renderDT({tryCatch({datatable(totals_table(), rownames=FALSE, editable=FALSE, fillContainer=TRUE, options = list(dom='t',ordering=F, pageLength=1, scrollY=65), selection = 'none')},
                                             error=function(cond){return(datatable(data.frame(Totals="No data loaded"), rownames=FALSE, options = list(dom='t',ordering=F), selection = 'none'))})})
  
  # create downloabable excel and handle downloads
  data_list <- reactive({list(shoppinglist = totals_table(), recipes_and_quantities = qty_output_table())})
  
  output$download_planned_cookies <- downloadHandler(
    filename = function() {"PlannedCookies.xlsx"},
    content = function(file) {write_xlsx(data_list(), path = file)}
  )
})
