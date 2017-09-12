####################################################
# Script to load necessary R packages              #
#                                                  #
# author : Robert Haase                            #
# data: 08/31/2015                                 #
####################################################

#----------------- load or install packages -----------------#
if(!require(shiny)) {install.packages("shiny"); require(shiny)}
if(!require(nnet)) {install.packages("nnet"); require(nnet)} 
if(!require(jsonlite)) {install.packages("jsonlite"); require(jsonlite)} 
if(!require(mime)) {install.packages("mime"); require(mime)} 
if(!require(shinythemes)) {install.packages("shinythemes"); require(shinythemes)}
if(!require(doParallel)) {install.packages("doParallel"); require(shiny)}
if(!require(caret)) {install.packages("caret"); require(caret)}
#if(!require(rattle)) {install.packages("rattle"); require(rattle)}     excluded for shinyapps.io server
if(!require(lattice)) {install.packages("lattice"); require(lattice)}
if(!require(ggplot2)) {install.packages("ggplot2"); require(ggplot2)}
if(!require(arules)) {install.packages("arules"); require(arules)}
if(!require(e1071)) {install.packages("e1071"); require(e1071)}
if(!require(quantreg)) {install.packages("quantreg"); require(quantreg)}
if(!require(ipred)) {install.packages("ipred"); require(ipred)}

# added for server deployment
if(!require(xgboost)) {install.packages("xgboost"); require(xgboost)}
if(!require(brnn)) {install.packages("brnn"); require(brnn)}
if(!require(rpart)) {install.packages("rpart"); require(rpart)}
if(!require(gbm)) {install.packages("gbm"); require(gbm)}
