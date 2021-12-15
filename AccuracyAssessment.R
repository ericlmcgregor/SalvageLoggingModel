library(raster)
library(rgdal)
library(dplyr)
library(caret)

#set working directory
setwd("C:/Users/ericm/Documents/ProjectRequests/KlamathFisher/RF_Model")

#load reference data
ref <- readOGR("Model_Prediction/Model_outputs_PostFireLoggingModel/AccuracyAssessment/PostFireLogging_2015_StratifiedRandomSample_Iter4.shp")
head(ref)

#load predictions (i.e., the raster output)
r <- raster("Model_Prediction/Model_outputs_PostFireLoggingModel/classification/KlamathFisher_PostFireLoggingModel_2015_ThresholdMask_4PixSieve.tif")

#extract predicted values to reference points
ref <- extract(r, ref, sp = T)
head(ref)

#clean up data frame
ref <- ref@data
ref <- rename(ref, Predicted = KlamathFisher_PostFireLoggingModel_2015_ThresholdMask_4PixSieve)
ref <- rename(ref, Observed = Reference)
#move unique ID to first column
ref <- ref[,c(5, 1:4, 6)]
head(ref)

#convert columns to factor
ref$Observed <- as.factor(as.character(ref$Observed))
ref$Predicted <- as.factor(as.character(ref$Predicted))

#Calculate confusion matrix with caret confusionMatrix
cm <- confusionMatrix(ref$Predicted, ref$Observed, positive = "1")
cm
cm$table
capture.output(confusionMatrix(ref$Predicted, ref$Observed, positive = "1"),
               file = "Model_Prediction/Model_outputs_PostFireLoggingModel/AccuracyAssessment/KlamathFisher_SalvageLogging_ConfMatrixStats_Iter4.csv")

