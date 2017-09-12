# R Shiny Web App for Portfolio Segmentation
This repository features a **R Shiny Web App** for training **Machine Learning** models for **Segmentation** tasks. This web app was initially implementend as part of my _master's thesis_ and now generalized to be published so that others have the chance of making use of it by adapting it for their purposes, for example. 

**Quickly explore it!**
Using the dummy dataset (dummyData.csv - which has German csv notation) you can **explore the app** by playing with it [here](https://r-haase.shinyapps.io/R-Shiny-Web-App-for-Segmentation/). I tried to make it as easy to follow as possible.

Running it locally requires **R 3.2.4** to enjoy all features.

**Limitations of shinyapps.io deployment**:
- **Hyperparameter tuning** is simplified by setting the _tuneLength_ parameter of the **caret** package to 1 in order to speed up training for demonstration purposes.   
- _Bayesian Neural Network_ does not work but the other three algorithms do     
-  The deployed version above won't allow the installation of the _RGtk2_ package so that the visualization of the trained decision tree won't work. The _RGtk2_ package itself is a dependency of the _rattle_ package, which is currently commented out for server deployment. You can include it for local installation.     
- It seems as if trained models cannot be saved on the server so that the **Criteria Importance** feature and the **Prediction Tab** features will not work   
