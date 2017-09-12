#############################################################
# Shiny Web Application                                     #
# User Interface of the application                         #
#                                                           #
# author : Robert Haase                                     #
# last change: 10/18/2015                                   #
# edited for publication: 09/11/2017                        #
#############################################################

library(shiny)
library(shinythemes)

shinyUI(fluidPage(
                  # Theme
                  theme = shinytheme("flatly"),
                  
                  # Application title
                  fluidRow(
                          column(width = 2, offset = 0,
                                imageOutput("myLogo", width = "auto", height = "auto", inline = FALSE) 
                                # image source: https://commons.wikimedia.org/wiki/File:Logo_TV_2015.png
                                ),
                          column(width = 10,
                                titlePanel("Segmentation Tool"),
                                h6("by Robert Haase")
                                )
                          ),
          
                  # dark blue navigation bar
                  navbarPage(":)",
                             #--------------------------------------------- Navigation Bar TAB 1 - "DATA" ---------------------------------------------#  
                             tabPanel("Data Center",
                                      fluidRow(
                                        column(6,
                                               h4("1. Please, choose a CSV file from your local directory:"),
                                               radioButtons("notation", "German (;) or Anglo-Saxon (,) delimiters?",
                                                            c("German" = "german",
                                                              "Anglo-Saxon" = "english")),
                                               fileInput("inputFile", "Input (.csv file)", width = "600px")
                                               ),
                                        column(6, 
                                               h4("2. To distinguish between numeric and categorical variables, please insert the column number of 
                                                  the last numeric variable*:"),
                                               numericInput("colNum", label = "Column number (e.g. 10):", value = 3),
                                               h6("* The uploaded data table has to have the following order of variable/column data types:
                                                  [ID/Primary Key] - [all numceric variables] - [all categorical variables].")
                                               )
                                        ),
                                      fluidRow(
                                        column(6,div(style = "height:50px")),
                                        column(6,div(style = "height:50px"))
                                      ),
                                      fluidRow(
                                        column(6,
                                               h4("3. Choose (numeric) Segmentation Response Variable:"),
                                               h6("This step can be skipped, if you do not intend to train new models."),
                                               uiOutput("targetUI")
                                               ),
                                        column(6,
                                               h4("4. Please, set segment boundaries for any (numeric) response variable*."),
                                               h5("Make sure the first boundary value is greater than the second one!"),
                                               #Simple Integer Interval
                                               sliderInput("cutpointNL", "boundary between bottom and middle segment:", min = 0, max = 100, value = 80,
                                                            width = "600px"),
                                               sliderInput("cutpointLH", "boundary between middle and upper segment:", min = 0, max = 100, value = 30,
                                                            width = "600px"),
                                               h6("* As is, this feature is only useful for response variables on a scale from (0-100). It dynamically affects the 
                                                  histogram in the << Exploratory Analysis >> section.")
                                              )
                                      )
                                    ),
                       
                             #------------------------------------- Navigation Bar TAB 2 - "Exploratory Analysis" -------------------------------------#  
                             tabPanel("Exploratory Analysis",
                                      tabsetPanel(
                                                  type = c("pills"),
                                                  tabsetPanel( # create second level tabs
                                                              tabPanel("Structure",
                                                                       h3("Variable Data Type Verification:"),
                                                                       h4("Here you can verify, if all variables have been properly read in as numeric 
                                                                          or categorical variable, based on the (last numeric) column number you provided
                                                                          in the << Data Center >> section."),
                                                                       verbatimTextOutput("structure"),
                                                                       h5("Legend: num = numeric variable; factor = categorical variable; number of factor levels = 
                                                                          number of distinct values within respective categorical variable")
                                                                       ),
                                                              tabPanel("Summary", 
                                                                       h3("Basic Data Summary:"),
                                                                       h4("This tab provides desriptive distribution indicators for numeric criteria
                                                                          and frequency counts for categorcial criteria."),
                                                                       verbatimTextOutput("summary")
                                                              ), 
                                                              tabPanel("Response Variable Distribution",
                                                                       h3("Response Variable Distribution:"),
                                                                       h5("Plot based on response variable selected in step 3 of the << Data Center >> section."),
                                                                       plotOutput("targetV")
                                                                       ),
                                                              tabPanel("Segment Distribution",
                                                                       h3("Response Variable Distribution:"),
                                                                       h5("Plot based on response variable selected in step3 and the boundaries set in 
                                                                          step 4 of the << Data Center>> section."),
                                                                       plotOutput("segmentPlot")
                                                                       )
                                                              )
                                                  )
                                      ),
                             #---------------------------------------- Navigation Bar TAB 3 - "Model Training" ----------------------------------------#
                             tabPanel("Model Training",
                                      tabsetPanel(
                                                  type = c("pills"),
                                                  tabsetPanel( # create second level tabs
                                                              tabPanel("Criteria Selection",
                                                                        h4("Choose all Criteria you want to be included in the
                                                                           training process (multiple choices possible):"),
                                                                        uiOutput("predictorUI")
                                                                       ),
                                                              tabPanel("Learning Algorithm Selection",
                                                                       sidebarLayout(
                                                                         sidebarPanel(
                                                                           h3("Choose Learning Algorithm for Training:"),
                                                                           checkboxGroupInput("modelId", "Checkbox (choose at least 2)",
                                                                                              c("CART decision tree" = "CART", 
                                                                                                "Gradient Boosting" = "XGboost", 
                                                                                                "Stochastic Gradient Boosting" = "SGB",
                                                                                                "Bayesian Neural Network" = "BRNN"), 
                                                                                              selected = NULL), 
                                                                           actionButton("goButton", "Start Training!"),
                                                                           fluidRow(
                                                                             column(12,div(style = "height:20px"))
                                                                           ),
                                                                           helpText(a("What is CART ?", 
                                                                                      href="https://en.wikipedia.org/wiki/Decision_tree_learning",
                                                                                      target ="_blank")
                                                                           ),
                                                                           helpText(a("What is Gradient Boosting ?", 
                                                                                      href="https://en.wikipedia.org/wiki/Gradient_boosting",
                                                                                      target ="_blank")
                                                                           ),
                                                                           helpText(a("What are Neural Networks ?", 
                                                                                      href="https://en.wikipedia.org/wiki/Artificial_neural_network",
                                                                                      target ="_blank")
                                                                           ),
                                                                           helpText(a("What is Cross-Validation ?", 
                                                                                      href="https://en.wikipedia.org/wiki/Cross-validation_(statistics)",
                                                                                      target ="_blank")
                                                                           )
                                                                         ),
                                                                         mainPanel(
                                                                           h3("Model Performance based on 5-fold cross validation"),
                                                                           h4('You selected:'), 
                                                                           verbatimTextOutput("oid1"), 
                                                                           h3("Training Results:"),
                                                                           h5("This might take a while - depending on data set size and hardware.
                                                                              The top right corner of the browser window indicates what the tool 
                                                                              is currently working on."),
                                                                           h6("RMSE: Average deviance between true values and model predictions."),
                                                                           plotOutput("distPlot"),
                                                                           h5("Legend:"),
                                                                           h6("The respective dots in the plot show the expected model performance.
                                                                              These dots are accompanied by their 95% performance confidence interval.")
                                                                                  )
                                                                                )
                                                                       )
                                                              )
                                                )
                                      ),
                            #--------------------------------- Navigation Bar TAB 4 - "Properties of Trained Models" ----------------------------------#

                             tabPanel("Properties of Trained Models",
                                      tabsetPanel(
                                                  type = c("pills"),
                                                  tabsetPanel( # create second level tabs
                                                              tabPanel("Last Training's Models",
                                                                       h4("Last Training's Learning Algorithms:"),
                                                                       verbatimTextOutput("lAlg"),
                                                                       fluidRow(
                                                                         column(12,div(style = "height:20px"))
                                                                       ),
                                                                       h4("Last Training's Criteria:"),
                                                                       h5("[Response variable] ~ [Criterion1 + Criterion2 + ... + CriterionN]"),
                                                                       verbatimTextOutput("fmla2"),
                                                                       h6("Only the models corresponding to the above-dislayed 
                                                                          learning algorithm and variable selection, can be resused for segmentation
                                                                          of new data."),
                                                                       #h1("."),
                                                                       fluidRow(
                                                                         column(12,div(style = "height:20px"))
                                                                         ),
                                                                       h4("Last Training's Model Performances:"),
                                                                       plotOutput("oldDistPlot")
                                                                       ),
                                                              tabPanel("Decison Tree",
                                                                       h4("Visualization for ad hoc segmentation based on (last trained !) CART decision tree model:"),
                                                                       plotOutput("treeVis")
                                                                      ),
                                                              tabPanel("Criteria Importance",
                                                                       h4("Criteria Importance Plot based on (last trained !) Stochastic Gradient Boosting Model:"),
                                                                       h5("Relative Importance Scores - the larger the value, the more important the respective 
                                                                          criterion was for segmentation."),
                                                                       plotOutput("importance"),
                                                                       plotOutput("impPlot")
                                                                       )
                                                              
                                                  )
                                      )
                             ),
                            #-------------------------------- Navigation Bar TAB 5 - "Predicting Segment Affiliation" --------------------------------#
                             tabPanel("Predicting Segment Affiliation of New Data",
                                               sidebarLayout(
                                                 sidebarPanel(
                                                   h5("Have you uploaded (new) data yet? If not, please return to  << Data Center >>."),
                                                   fluidRow(
                                                     column(12,div(style = "height:10px"))
                                                   ),
                                                   h3("Choose Learning Algorithm for Prediction:"),
                                                   checkboxGroupInput("modelIdPred", "Choose only the models that were trained
                                                                                              on the same data structure (cf. Last Training's Models)",
                                                                      c("CART decision tree" = "CART", 
                                                                        "Gradient Boosting" = "XGboost", 
                                                                        "Stochastic Gradient Boosting" = "SGB",
                                                                        "Bayesian Neural Network" = "BRNN"), 
                                                                      selected = NULL), 
                                                   actionButton("goButtonPred", "Predict!"),
                                                   h3(" "),
                                                   h4("Download Prediction Data:"),
                                                   downloadButton('downloadData', 'Download')
                                                 ),
                                                 mainPanel(
                                                   h3("Expected Response Values & Segment Affiliation"),
                                                   h4('You selected for Prediction:'), 
                                                   verbatimTextOutput("oidPred"), 
                                                   h3("Prediction Results:"),
                                                   h5("The affiliation to one of the << high, low, or no touch >> segments indicates the need of 
                                                      post-treatment of statistical forecasts based on good or poor performance of statistical forecast
                                                      methods used in the past."),
                                                   dataTableOutput("pred")
                                                 )
                                               )
                                      
                             )
                            #------------------------------------------- Navigation Bar TAB 6 - "Updating" -------------------------------------------#
                            ### This feature caused problems, since it could only be run from within R or RStudio, and updates often require 
                            ### new packages, which have to be added by interacting with R.
                            
                            
                            
#                              navbarMenu("Check for Updates",
#                                         tabPanel("R Version",
#                                                  h4("Please, click the  < Go! button >  to check for a new R Version."),
#                                                  actionButton("goButtonR", "Go!")
#                                                  ),
#                                         tabPanel("Packages",
#                                                  h4("Please, click the  < Go! button >  to update Package Versions."),
#                                                  actionButton("goButtonPack", "Go!"))
#                                         )
                            )
                  ) # fluidpage
        ) # shinyUI
  
  
  