##Load Required Packages
library(raster)
library(rgdal)
library(randomForest)
library(dplyr)
library(RStoolbox)
library(pryr)
library(rfUtilities)
library(caret)
library(rgeos)
library(snow)
library(ModelMap)

##This code (including associated modules) implements a random forest classification
##to detect instances of post-wildfire salvage logging. Training data (presence/absence) were created
##through visual interpretation of high-res NAIP imagery in Google Earth Engine. Landsat 8
##SWIR1 bands from three time-steps were used to develop covariates: 
##1)pre-fire, 2)post-fire/pre-logging, and 3) post-fire/post-logging. 


##########################################################
########SPECIFY SOME PARAMETERS###############
#set working directory
setwd("C:/Users/ericm/Documents/ProjectRequests/KlamathFisher/RF_Model")

#point to where code modules are stored
codePath <-  file.path(getwd())

#point to where rasters are stored, for extracting to training data
rDir <- file.path(paste(getwd(),"/Model_Inputs/Imagery", sep=""))
rlist <- list.files(rDir, full.names = T)


#Give the model a name
mname <- "MODEL1"

#specify name to be attached to output
outType <- "PostFireLogging"

#specify year for analysis
yr <- "2015"


#set land cover class for this model (if multiple)
lclass <- "class"

#list variables of interest for this model & include class
vlist <- c(lclass,'preFB6', 'postFB6', 'postLB6')


##################END PARMETER SPECIFICATION######################
###########################################################################


########GENERATE OUTPUT PATHS AND FOLDERS, ETC###############
#set seed
set.seed(13)
#set raster options to show progress
rasterOptions(progress = "text", timer=TRUE)

#Create prefix that will be added to all file outputs
outname <- paste(mname, outType, yr, sep = "_")

#specify working folder for outputs
Dir <- file.path(paste(getwd(), "Model_Prediction", sep = "/"))

#specify folder containing necessary inputs to model
#this directory contains other folders with training data, etc.
inputF <- file.path(paste(getwd(), "Model_Inputs", sep = "/"))


#create a folder for all outputs to be stored
dir.create(file.path(paste(Dir,"/", "Model_outputs_", outType, sep = "")))
#create an object from the file path for easy access for saving files
outpath <- file.path(paste(Dir, "/Model_outputs_", outType, sep = ""))

#create folder for classification and regression outputs
dir.create(file.path(outpath, "classification"))
outpath_cl <- file.path(paste(outpath, "/classification", sep = ""))



####################BEGIN RUNNING MODEL MODULES#####################

#######Import Training and Test data#########
#Prepares data for both Classification and Regression Models
#If data are zero-rich the number of zeros is reduced to twice
#the number of presences
source(paste(codePath, "/PostFireLogging_RF_TrainingDataImport_NoSplit.R", sep = ""))
head(MasterTrainset)
#######################
############################

##Run classification model
source(paste(codePath, "/PostFireLogging_RF_Classification_OOBonly.R", sep = ""))

