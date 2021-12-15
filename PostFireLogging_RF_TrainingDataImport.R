

########LOAD TRAINING AND TEST DATA##################
##Load training and test data
trainset <- list.files(paste(inputF, "TrainingData", sep = "/"), pattern = ".shp$", full.names = TRUE)
trainset <- readOGR(trainset)
# trainset <- read.csv(trainset)
#rename class field
colnames(trainset@data)[colnames(trainset@data) == "landcover"] <- "class"
#drop unwanted column
trainset@data[ ,"Source"] <- list(NULL)

###load raster stack and extract values to training points###
covs <- stack(rlist)
#rename bands
names(covs) <- c('preFB6', 'postFB6', 'postLB6', 
                 'preFNDVI', 'postFNDVI', 'postLNDVI', 
                 'preFNDMI', 'postFNDMI', 'postLNDMI')

#extract raster values to point locations
trainset <- extract(covs, trainset, sp = T)
#keep only the dataframe
trainset <- trainset@data
#remove any rows containing NAs
trainset <- trainset[complete.cases(trainset),]

# #subset training to only include variables in vlist
trainset <- trainset[,which(names(trainset)%in%vlist)]







