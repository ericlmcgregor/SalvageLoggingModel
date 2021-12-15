####CLASSIFICATION MODEL#######


#number of trees
trees <- 1001

#check for colinearity
cl <- multi.collinear(trainset[,-1], n=999) #with 'class' field removed
#print to console which variables to remove
for(l in cl) {
  cl.test <- trainset[,-which(names(trainset)==l)]
  print(paste("Remove variable", l, sep=": "))
  multi.collinear(cl.test)
}

#remove collinear variables
trainset <- trainset[, !(colnames(trainset) %in% cl), drop=FALSE]
names(trainset)

#model selection to find most parsimonious
(rf.model <- rf.modelSel(x=trainset[,-1], y=trainset$class, imp.scale = "mir", seed = 13,
                         ntree=trees))

capture.output(rf.model, file =paste(outpath_cl, "/", outname, "ModSelect_out", ".csv", sep = ""))

#get names of selected variables to move forward
sel.vars <- rf.model$selvars


###Now run a single model to look at error convergence
# then tune mtry value
(rf.fit <- randomForest(x=trainset[,sel.vars], y=trainset$class, ntree=trees, importance=TRUE,
                        norm.votes=TRUE, seed=13))
#check error convergence and adjust trees if needed
plot(rf.fit) #see how error converges on plot
# trees <- 

####find optimal mtry value###
modeltune <- tuneRF(x=trainset[ ,sel.vars], y=trainset$class, ntreeTry = trees)

mtry_opt <- modeltune[,"mtry"][which.min(modeltune[,"OOBError"])] #select best mtry based on lowest OOB error

#Don't allow mtry = 1
mtry_opt <- ifelse(mtry_opt < 2, 2, mtry_opt)


#############################

#Train model a second time with tuned parameters
(rf.fit <- randomForest(x=trainset[,sel.vars], y=trainset$class,
                        mtry = mtry_opt, ntree=trees, keep.forest = TRUE, importance=TRUE,
                        norm.votes=TRUE, seed=13))


#export variable importance plot
pdf(file =paste(outpath_cl, "/", outname, "VarImpPlot_scaled", ".pdf", sep = ""))
varImpPlot(rf.fit, scale = TRUE, main = "Scaled Variable Importance Classification")
dev.off()

#export importance values as .csv
imp <- importance(rf.fit, scale = TRUE)
capture.output(imp, file =paste(outpath_cl, "/", outname, "VarImportance", ".csv", sep = ""))


# ##Perform a significance test for the model
# #is model significant based on p = 0.05
# rf.sig <- rf.significance(rf.fit, xdata=trainset[,-1], 
#                           q=0.99, nperm=999)
# rf.sig
# capture.output(rf.sig, file =paste(outpath_cl, "/", outname, "ModelSignificance_cl", ".csv", sep = ""))

#save a copy of the model
saveRDS(rf.fit, paste(outpath_cl, "/", outname, "FinalFitModel_cl", ".rds", sep = ""))
##use readRDS("./RFModel2.rds") to read in as a variable and reuse later

#get basic diagnostics with error rates
capture.output(rf.fit, file =paste(outpath_cl, "/", outname, "OOBErrorRates", ".csv", sep = ""))

#first convert testset$class to numeric for model diagnostics function
trainset$class <- as.numeric(as.character(trainset$class)) 
#get diagnostic outputs
pred_diag <- model.diagnostics(model.obj = rf.fit, qdata.trainfn = trainset ,
                               folder = outpath_cl, MODELfn = paste(outname, "Diagnostics", sep = ""),
                               response.name = "class", unique.rowname = FALSE,
                               seed=13, prediction.type = "OOB", device.type = "pdf", res = 300)


#select threshold where sensitivity and specificity are roughly equal
thresh <- list.files(outpath_cl, pattern = "optthresholds.csv$", full.names = TRUE)
thresh <- read.csv(thresh)
threshVal <- thresh$threshold[10]


#################PREDICT MAP using ModelMap approach###############################

####
#load raster look up table from inputs folder in Main.R (contains path to raster layer of each predictor)
rlt <- list.files(paste(inputF, "rastLUTs", sep = "/"), pattern = "rastLUT", full.names = TRUE)
#read raster LUT
rlt <- read.csv(rlt, header=FALSE)

#select variables of interest from LUT. Listed in Main.R
rlt <- rlt[rlt$V2 %in% vlist,]

#predict map
mm <- model.mapmake(model.obj = rf.fit, folder = outpath_cl, 
                    rastLUTfn = rlt, OUTPUTfn = paste(outname, ".tif", sep = ""))



##POST PREDICTION PROCESSING###
#list and load the output from mm
mn <- list.files(outpath_cl, pattern= "2015.tif$", full.names = TRUE)
mn <- raster(mn)
#Create mask by thresholding probability layer based on threshVal
#ThreshVal can be adjust by viewing the diagnostics output and selecting based on 
#different optimizations of specificity, sensitivity, kappa, etc.
classified <- mn >= threshVal
#write the classification output
writeRaster(classified, paste(outpath_cl, "/", outname, "_ThresholdMaskReqSens", ".tif", sep = ""))
#clean up memory
gc()


### Remove small patches
#function to filter out patches <= the patchsize threshold
patchsieve <- function(x){
  vals <- raster::clump(x,directions = 8)
  f <- data.frame(freq(vals))
  excludeID <- f$value[which(f$count <= patchsize)]
  patchlayer <- vals
  patchlayer[vals %in% excludeID]<- NA
  patchlayer <- patchlayer > 1
  return(patchlayer)
}

patchsize <- 4 #number of pixels that make up a patch
sv <- patchsieve(classified)
sv[is.na(sv[])] <- 0 
plot(sv)

### Clip to Beaver Fire footprint
#Load Beaver fire boundary
fire <- readOGR("Model_Inputs/BeaverFireBoundary/BeaverFireBoundary.shp")
plot(fire)
fire <- spTransform(fire, CRSobj = crs(sv))
#crop model output to fire perimeter
sv_msk <- mask(sv, fire)
writeRaster(sv_msk, paste(outpath_cl, "/", outname, "_ThresholdMaskReqSens_4PixSieve", ".tif", sep = ""), datatype='INT1U')


#################################################################################
#################################################################################
###Create stratified random sample to be interpreted for Accuracy Assessment###

#Let's generate a stratified random sample with 60 samples in each class and 
#output it as a shapefile
##Lillesand and Kiefer (chapter 7) suggest a heuristic on sample size: 50 per class
##So we'll do a little more to be on the safe side, the more the merrier. 
randSamp <- sampleStratified(sv_msk, size = 60, sp = T)
#remove column that identifies cover type
randSamp <- randSamp[,1]
#add coordinates to columns
randSamp$X <- randSamp@coords[,1]
randSamp$Y <- randSamp@coords[,2]
#Add coordinates to columns
#write shapefile output
writeOGR(randSamp, dsn= outpath_cl, layer = paste(outname, "_StratifiedRandomSample", sep = ""), driver = "ESRI Shapefile")


