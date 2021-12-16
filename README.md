## Salvage Logging Model
This set of modules implements a random forest classification model to identify post-wildfire salvage logging activities. The model is based on training data created by visually interpreting presence/absence over high resolution NAIP imagery on Google Earth Engine (GEE). 
Landsat 8 SWIR1 data was acquired on GEE (ImageryAcquisition_GEE.js) for three time-steps: 1) pre-fire, 2)post-fire/pre-logging, and 3)post-fire/post-logging. 
Training data import (PostFireLogging_RF_TrainingDataImport.R) and RF classification (PostFireLogging_RF_Classification.R) are executed from Main.R.
Additional reference data created from a stratified random sample of the model output and visual interpretation over NAIP imagery are input to the AccuraccyAssessment.R script for final map evaluation.
