#############################################################
# Shiny Web Application                                     #
# server-side of the application                            #
#                                                           #
# author : Robert Haase                                     #
# last change: 10/18/2015                                   #
# edited for publication: 09/11/2017                        #
#############################################################


#------------------ load required packages -----------------#

source("loadInstallPack.R", local = TRUE)

# set seed for random number generator
set.seed(1188)
repeatable(rngfunc, seed = 1188)

# enable multicore/parallel computation
registerDoParallel(cores = detectCores(all.tests = TRUE))


##################################################################################################################################
# Everything outside the "shinyServer" function is loaded once and available across multiple sessions that use this application. #
##################################################################################################################################

# server-side of the application
shinyServer(function(input, output, session) {
        
        ### possibility to load an image for user interface ###
        
        output$myLogo <- renderImage({
                
                # set path to image
                filename <- normalizePath(file.path(getwd(), paste('images/', 'logo','.png', sep='')))
                
                # Return a list containing the filename and alt text
                list(src = filename,
                     width = 310/5,
                     height = 520/5,
                     alt = "Logo")
                
        }, deleteFile = FALSE)
        
        #--------------------------------------------- Navigation Bar TAB 1 - "DATA" ---------------------------------------------#    
        ### read in chosen Excel/CSV file ###
        
        # +++ by default (uploaded) file size limit is 5MB - new limit is 1GB +++ #
        options(shiny.maxRequestSize = 1000 * 1024^2) 
        
        # read in data
        dataFile <- reactive({
                            if(!is.null(input$inputFile)){
                                    temp <- input$inputFile
                                    #dataFile <- read.xlsx(temp$datapath, 1)
                                    
                                    if(input$notation == "english"){dataFile <- read.csv(temp$datapath)}
                                    if(input$notation == "german"){dataFile <- read.csv2(temp$datapath)}
                                    
                                    # transform data types
                                    for (i in 2:input$colNum){
                                      dataFile[,i] <- as.numeric(dataFile[,i])
                                    }
                                    for (j in (input$colNum+1):length(colnames((dataFile)))){
                                      dataFile[,j] <- as.factor(dataFile[,j])
                                    }
                                    return(dataFile)
                            }
        })
        # Variable Selection User Interface to be sent to ui.R
        output$targetUI <- renderUI({
                            if (is.null(dataFile())) {return(NULL)}
                            else {
                              radioButtons("selectedTarget", "e.g ...", colnames(dataFile()))
                            }
        })
        
        # listen to User Variable Selection
        responseV <- reactive({input$selectedTarget})   

        # discretize target variable
        targetSegment <- reactive({
                          targetSegment <- discretize(dataFile()[,responseV()], 
                                                      method = "fixed", 
                                                      categories = c(0, input$cutpointNL, input$cutpointLH, 100),
                                                      labels = c("bottom", "middle", "upper"), 
                                                      ordered = FALSE
                          )
        })
        # create classification data set with discretized response variable
        dataFileClass <- reactive({
                                  dataFileClass <- cbind(targetSegment(),dataFile())
        })
        
        #------------------------------------- Navigation Bar TAB 2 - "Exploratory Analysis" -------------------------------------#
        
        ### create data set summary information ###
        # tab 1
        output$summary <- renderPrint({                       
                if(!is.null(input$inputFile)){
                        summary(dataFile())
                }
        })
        # tab 2
        output$structure <- renderPrint({                        
                if(!is.null(input$inputFile)){
                        return(str(dataFile()))
                }
        })
        # tab 3
        output$targetV <- renderPlot({
                if(!is.null(input$inputFile)){
                        histogram(~ dataFile()[,responseV()], xlab = "Target/Response Variable values", ylab = "Frequency",
                                  col = "deepskyblue")
                }
        })
        # tab 4
        output$segmentPlot <- renderPlot({
          if(!is.null(input$inputFile)){
                        histogram(~ targetSegment(), xlab = "SEGMENTED Target/Response Variable", ylab = "Frequency", col = "deepskyblue")
          }
        })
        
        #---------------------------------------- Navigation Bar TAB 3 - "Model Training" ----------------------------------------#
        
       # Criteria Selection
        output$predictorUI <- renderUI({
          if (is.null(dataFile())) {return(NULL)}
          else {
            checkboxGroupInput("selectedCriteria", "", colnames(dataFile()))
          }
        })
        # listen to user criteria selection
        criteria <- reactive({
                              criteria <- input$selectedCriteria
                              # save criteria for prediction
                              saveRDS(criteria, file = "trainedModels/criteriaVector.Rdata")
                              
                              return(criteria)
          })
        
        # return input values (seleceted criteria)
        output$oid1 <- renderPrint({ if(input$goButton >= 1) {
                                                              isolate(write(input$modelId, file = "trainedModels/models.txt"))
                                                              isolate(input$modelId)
                                                              }
          })
        
        # control parameters for model training using caret
        ctrl <- trainControl(method = "repeatedcv", number = 5, repeats = 1, verboseIter = TRUE)
        
        ######################## train models only if they were selected ###########################
        
        # set up formula for training models - formula example: responseVariable ~ X1+X2+...+Xn
        fmla <- reactive({
                          if(input$goButton >= 1){
                              fmla <- paste(criteria(), collapse = "+")
                              fmla <- paste(responseV(),"~", fmla)
              
                              # save formula for later reference
                              write(fmla, file = "trainedModels/formula.txt")
                              
                              return(as.formula(fmla))
                          }
        })
        # create formula with discrete response variable
        fmlaD <- reactive({
                          if(input$goButton >= 1){
                            fmlaD <- paste(criteria(), collapse = "+")
                            fmlaD <- paste( "targetSegment() " ,"~", fmlaD)
                            return(as.formula(fmlaD))
                          }
        })
        # reload formula from last training
        output$fmla2 <- reactive({fmla2 <- as.character(readLines("trainedModels/formula.txt"))})
        # reload learning algorithms from last training
        output$lAlg <- reactive({lAgl <- as.character(readLines("trainedModels/models.txt"))})
        
        
        ### model training ####
        # CART Decision Tree
        rpart_reg <- reactive({
                # training is only executed, if model is chosen and 'go button' was clicked
                if(input$goButton >= 1 & "CART" %in% input$modelId){
                        withProgress(message = 'Training in Progress - CART Tree', value = 0, {
                                rpart_reg <- isolate(train(fmla(),     
                                                      dataFile(), 
                                                      method = "rpart",
                                                      metric = "RMSE",
                                                      tuneLength = 10,
                                                      trControl = ctrl))
                                # save model for later use
                                saveRDS(rpart_reg, file = "trainedModels/CART.Rdata")
                                
                                return(rpart_reg)
                        })
                }
        })
        # Gradient Boosting
        XG_reg <- reactive({
                if(input$goButton >= 1 & "XGboost" %in% input$modelId){
                        withProgress(message = 'Training in Progress - Gradient Boosting', value = 0, {
                                XG_reg <- isolate(train(fmla(),
                                                      dataFile(), 
                                                      method = "xgbTree",
                                                      metric = "RMSE",
                                                      tuneLength = 10,
                                                      trControl = ctrl))
                                # save model for later use
                                saveRDS(XG_reg, file = "trainedModels/XGboost.Rdata")
                                
                                return(XG_reg)
                        })
                }
                
        })
        # Stochastic Gradient Boosting
        sgb_reg <- reactive({
                if(input$goButton >= 1 & "SGB" %in% input$modelId){
                        withProgress(message = 'Training in Progress - Stochastic G Boosting', value = 0, {
                                sgb_reg <- isolate(train(fmla(),
                                                      dataFile(),
                                                      method = "gbm",
                                                      metric = "RMSE",
                                                      tuneLength = 10,
                                                      trControl = ctrl))
                                # save model for later use
                                saveRDS(sgb_reg, file = "trainedModels/SGB.Rdata")
                                                                
                                return(sgb_reg)
                        })
                }
                
        })
        # Bayesian Regularized Neural Network
        brnn_reg <- reactive({
                            if(input$goButton >= 1 & "BRNN" %in% input$modelId){
                              withProgress(message = 'Training in Progress - Bayesian Neural Network', value = 0, {
                                
                                brnn_reg <- isolate(train(fmla(),
                                                      dataFile(),
                                                      method = "brnn",
                                                      metric = "RMSE",
                                                      tuneLength = 10,
                                                      trControl = ctrl))
                                # save model for later use
                                saveRDS(brnn_reg, file = "trainedModels/BRNN.RData")
                                
                                return(brnn_reg)
                        })
                }
          
        })
        # create list with selected models for resamples function
        modelList <- reactive({
                if      (input$goButton >= 1 & "CART" %in% input$modelId & "XGboost" %in% input$modelId & "SGB" %in% input$modelId & "BRNN" %in% input$modelId) 
                        return(list(CART = rpart_reg(), 
                                    XGboost = XG_reg(), 
                                    SGB = sgb_reg(),
                                    BRNN = brnn_reg()))
          
                else if (input$goButton >= 1 & "CART" %in% input$modelId & "XGboost" %in% input$modelId & "SGB" %in% input$modelId) 
                        return(list(CART = rpart_reg(),
                                    XGboost = XG_reg(),
                                    SGB = sgb_reg()))
                else if (input$goButton >= 1 & "CART" %in% input$modelId & "XGboost" %in% input$modelId & "BRNN" %in% input$modelId) 
                        return(list(CART = rpart_reg(),
                                    XGboost = XG_reg(),
                                    BRNN = brnn_reg()))
                else if (input$goButton >= 1 & "CART" %in% input$modelId & "SGB" %in% input$modelId & "BRNN" %in% input$modelId) 
                        return(list(CART = rpart_reg(),
                                    SGB = sgb_reg(),
                                    BRNN = brnn_reg()))
                else if (input$goButton >= 1 & "SGB" %in% input$modelId & "XGboost" %in% input$modelId & "BRNN" %in% input$modelId) 
                        return(list(SGB = sgb_reg(),
                                    XGboost = XG_reg(),
                                    BRNN = brnn_reg()))         
                         
                else if (input$goButton >= 1 & "CART" %in% input$modelId & "SGB" %in% input$modelId) return(list(CART = rpart_reg(),
                                                                                                                 SGB = sgb_reg()))
                else if (input$goButton >= 1 & "CART" %in% input$modelId & "XGboost" %in% input$modelId) return(list(CART = rpart_reg(),
                                                                                                                      XGboost = XG_reg()))
                else if (input$goButton >= 1 & "CART" %in% input$modelId & "BRNN" %in% input$modelId) return(list(CART = rpart_reg(),
                                                                                                                    BRNN = brnn_reg()))
                else if (input$goButton >= 1 & "XGboost" %in% input$modelId & "BRNN" %in% input$modelId) return(list(XGboost = XG_reg(),
                                                                                                                        BRNN = brnn_reg()))
                else if (input$goButton >= 1 & "XGboost" %in% input$modelId & "SGB" %in% input$modelId) return(list(XGboost = XG_reg(),
                                                                                                                    SGB = sgb_reg()))
                else return(list(BRNN = brnn_reg(), SGB = sgb_reg()))
        })
        # generate performance comparison dotplot
        output$distPlot <- renderPlot({
          
                if(input$goButton >= 1){
                        
                        cvValues <- isolate(resamples(modelList(), metric = "RMSE", decreasing = FALSE))
                        #creating plot to compare performances & save as image for later reference
                        plot <- isolate(dotplot(cvValues, metric = "RMSE", main = "Resampled Performance"))
                       
                        saveRDS(plot, file = "trainedModels/dotplot.rds")
                        
                        return(plot)
                }
        })
       
        
        #---------------------------------- Navigation Bar TAB 4 - "Properties of Trained Models" -----------------------------------#
        
        # tab 1
        # loading performance dotplot
        output$oldDistPlot <- renderPlot({
          old <- readRDS("trainedModels/dotplot.rds") 
          plot(old)
        })
        
        # tab 2
        # visualization of standalone decision tree
        output$treeVis <- renderPlot({
                          if(!exists("rpart_reg", mode = "train")) {
                                                             treeVis <- readRDS("trainedModels/CART.RData") 
                          }
                          else {treeVis <- rpart_reg()}
                          treeVis <- treeVis$finalModel
                          return(fancyRpartPlot(treeVis))
        })
        # tab 3
        output$importance <- renderPlot({
          
          if(!exists("sgb_reg", mode = "train")) {
            importance <- readRDS("trainedModels/SGB.RData")
          }
          else {
            importance <- sgb_reg()
          }        
          importance <- varImp(importance)
          
          importance <- as.data.frame(importance[1][1])
          
          importance <- importance[order(importance$Overall),,drop = FALSE]
          par(mar=c(10,8,4,2))
          importance <- barplot(importance[,1], main="Segmentation Criteria Importance", horiz=TRUE, names.arg = row.names(importance),
                                las = 2, col = "deepskyblue", border = "darkblue", cex.names = 1, xlab = "Relative Importance Score")
          
          return(importance)
        }, height = 1000, width = 1000 )
        
        
        #--------------------------------- Navigation Bar TAB 5 - "Predicting Segment Affiliation" ----------------------------------#
        
        ### return selected model names ###
        output$oidPred <- renderPrint({ if(input$goButtonPred >= 1) {isolate(input$modelIdPred)}})
        
        ### render prediction table & apply respective models ###
        predTable <- reactive({
                            
                            # create list to gather selected models
                            predictionList <- NULL
          
                            # check if there already is a pre-trained model, on the condition that the model was selected by the user
                            if("CART" %in% input$modelIdPred){
                              if(!exists("rpart_reg", mode = "train")) {CART_Model <-  readRDS("trainedModels/CART.RData")}
                              else {CART_Model <- rpart_reg()}
                            }
                            if("XGboost" %in% input$modelIdPred){
                              if(!exists("XG_reg", mode = "train")) {XG_Model <-  readRDS("trainedModels/XGboost.RData")}
                              else {XG_Model <- XG_reg()}
                            }
                            if("SGB" %in% input$modelIdPred){
                              if(!exists("sgb_reg", mode = "train")) {sgb_Model <-  readRDS("trainedModels/SGB.RData")}
                              else {sgb_Model <- sgb_reg()}
                            }
                            if("BRNN" %in% input$modelIdPred){
                              if(!exists("brnn_reg", mode = "train")) {brnn_Model <-  readRDS("trainedModels/BRNN.RData")}
                              else {brnn_Model <- brnn_reg()}
                            }
                          
                            # read in last training's formula for selecting relevant feature in new data set
                            if(!exists("criteria", mode = "character")) {
                               crits <- readRDS("trainedModels/criteriaVector.RData") 
                            }
                            else {crits <- criteria()}
                  
                            # preparing new data set for prediction
                            newData <- dataFile()
                            ID <- newData[,1]
                            newData <- newData[,crits]
                            
                            
                            # transforminto data frame
                            predictionTable <- as.character(ID)
                            predictionTable <- as.data.frame(predictionTable)
                            
                            
                            # prediction only if model was selected
                            if("CART" %in% input$modelIdPred){
                                CART_Prediction <- predict(CART_Model, newData, type = "raw") # you have to use the train object, not the train$finalModel for prediction
                                CART_Prediction <- as.data.frame(CART_Prediction)
                                
                                predictionTable <- cbind(predictionTable, CART_Prediction)
                                
                                # categorize the predictions
                                CART_Segment <- discretize(predictionTable$CART_Prediction, 
                                                           method = "fixed", 
                                                           categories = c(0, input$cutpointNL, input$cutpointLH, 100),
                                                           labels = c("bottom", "middle", "upper"), 
                                                           ordered = FALSE
                                )
                                predictionTable <- cbind(predictionTable, CART_Segment)
                            }
                            if("XGboost" %in% input$modelIdPred){
                              XGboost_Prediction <- predict(XG_Model, newData, type = "raw") # you have to use the train object, not the train$finalModel for prediction
                              XGboost_Prediction <- as.data.frame(XGboost_Prediction)
                              
                              predictionTable <- cbind(predictionTable, XGboost_Prediction)
                              
                              # categorize the predictions
                              XGboost_Segment <- discretize(predictionTable$XGboost_Prediction, 
                                                         method = "fixed", 
                                                         categories = c(0, input$cutpointNL, input$cutpointLH, 100),
                                                         labels = c("bottom", "middle", "upper"), 
                                                         ordered = FALSE
                              )
                              predictionTable <- cbind(predictionTable, XGboost_Segment)
                              colnames(predictionTable)[1] <- "ID"
                            }
                            if("SGB" %in% input$modelIdPred){
                              sgb_Prediction <- predict(sgb_Model, newData, type = "raw") # you have to use the train object, not the train$finalModel for prediction
                              sgb_Prediction <- as.data.frame(sgb_Prediction)
                              
                              predictionTable <- cbind(predictionTable, sgb_Prediction)
                              
                              # categorize the predictions
                              SGB_Segment <- discretize(predictionTable$sgb_Prediction, 
                                                            method = "fixed", 
                                                            categories = c(0, input$cutpointNL, input$cutpointLH, 100),
                                                            labels = c("bottom", "middle", "upper"), 
                                                            ordered = FALSE
                              )
                              predictionTable <- cbind(predictionTable, SGB_Segment)
                              colnames(predictionTable)[1] <- "ID"
                            }
                            if("BRNN" %in% input$modelIdPred){
                              brnn_Prediction <- predict(brnn_Model, newData, type = "raw") # you have to use the train object, not the train$finalModel for prediction
                              brnn_Prediction <- as.data.frame(brnn_Prediction)
                              
                              predictionTable <- cbind(predictionTable, brnn_Prediction)
                              
                              # categorize the predictions
                              BRNN_Segment <- discretize(predictionTable$brnn_Prediction, 
                                                        method = "fixed", 
                                                        categories = c(0, input$cutpointNL, input$cutpointLH, 100),
                                                        labels = c("bottom", "middle", "upper"), 
                                                        ordered = FALSE
                              )
                              predictionTable <- cbind(predictionTable, BRNN_Segment)
                              colnames(predictionTable)[1] <- "ID"
                            }
                            

                            return(as.data.frame(predictionTable))
                })
        # created this renderTable object in order to call the actual table from here to send to UI and from download handler
        output$pred <- renderDataTable({ if (input$goButtonPred >= 1){predTable()}})
        
        
        # load formula for namin download file
        fmla_name <- reactive({fmla_name <- as.character(readLines("trainedModels/formula.txt"))})
        # download handler for prediction file
        output$downloadData <- downloadHandler(
                                              filename = function() { 
                                                                      temp <- paste(Sys.Date(), '_predictions_', fmla_name(), '.csv',   sep='') 
                                                                      temp <- gsub(' ', '', temp)
                                              },
                                              content = function(file) {
                                                if(input$notation == "english"){write.csv(predTable(),  file, quote = FALSE, row.names = FALSE)}
                                                if(input$notation == "german"){write.csv2(predTable(),  file, quote = FALSE, row.names = FALSE)}
                                              }
                              )
       
        
        #--------------------------------------------- Navigation Bar TAB 6 - "Updates" ---------------------------------------------# 
        
#         updateR <- observeEvent(input$goButtonR,
#                       {
#                         # installing/loading the package:
#                         if(!require(installr)) {
#                           install.packages("installr") 
#                           require(installr)
#                         } #load / install+load installr
#                         
#                         # using the package:
#                         updateR() # this will start the updating process of your R installation.  
#                         # It will check for newer versions, and if one is available, will guide you through the decisions you'd need to make
#                         
#                       })
#         updatePack <- observeEvent(input$goButtonPack,
#                                    {
#                                      withProgress(update.packages(ask = FALSE), 
#                                                   message = "Update are currently being installed. We ask you to be a little patient.")
#                                    }
#                                    )
        # Before testing your application, you need to ensure that it will stop the websocket server started by shiny::runApp() and the underlying R process when the browser window is closed. To do this, you need to add the following to server.R:
		session$onSessionEnded(function() {
				stopApp()
		})
})
