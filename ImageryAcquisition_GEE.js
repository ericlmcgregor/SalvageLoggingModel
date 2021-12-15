// create bounding box around area of interest
 aoi = 
    ee.Geometry.Polygon(
        [[[-123.39645724769346, 41.96809182293068],
          [-123.39645724769346, 41.4886991121181],
          [-122.72491794105284, 41.4886991121181],
          [-122.72491794105284, 41.96809182293068]]], null, false);


//////////////////////////////////////////////////////////////////////////////////
// SELECT Landsat imagery bands for use as covariates in the model////////////////
// The idea is to select imagery from three different dates:
// 1) Pre-fire (2014 before fire started)
// 2) Post-fire/Pre-logging (2014 after fire was out, but before logging was widespread)
// 3) Post-fire/Post-logging (2015 and/or 2016, after logging was implemented)

// Fire info found here: https://www.fs.fed.us/adaptivemanagement/reports/fbat/2014_FBATReport_BeaverFire_043015update_091015formatting.pdf
// Beaver Fire started on July 30, 2014, so we need imagery before then. 
var preFire = ee.ImageCollection("LANDSAT/LC08/C01/T1_SR")
    .filterDate('2014-07-01', '2014-07-29')
    .filterBounds(aoi)
    .filterMetadata('CLOUD_COVER', "not_greater_than", 20)
    .first()
    .select(['B4', 'B5', 'B6']);
print(preFire, "preFire");

// And full containment was August 30, 2014, so we'll get some imagery just after
var postFire = ee.ImageCollection("LANDSAT/LC08/C01/T1_SR") 
    .filterDate('2014-10-01', '2014-10-31') //This was 2014-09-15 on first iteration
    .filterBounds(aoi)
    .filterMetadata('CLOUD_COVER', "not_greater_than", 20)
    .first()
    .select(['B4', 'B5', 'B6']);
print(postFire, "postFire");

// And some imagery representing post-logging conditions
var postLog = ee.ImageCollection("LANDSAT/LC08/C01/T1_SR")
    .filterDate('2015-09-15', '2015-10-31')
    .filterBounds(aoi)
    .filterMetadata('CLOUD_COVER', "not_greater_than", 20)
    .first()
    .select(['B4', 'B5', 'B6']);
print(postLog, "postLogging");

// Calculate NDVI 
var preFireNDVI = preFire.normalizedDifference(['B5', 'B4']).rename('preFNDVI');
var postFireNDVI = postFire.normalizedDifference(['B5', 'B4']).rename('postFNDVI');
var postLogNDVI = postLog.normalizedDifference(['B5', 'B4']).rename('postLNDVI');
print(preFireNDVI);
// Calculate NDMI
var preFireNDMI = preFire.normalizedDifference(['B5', 'B6']).rename('preFNDMI');
var postFireNDMI = postFire.normalizedDifference(['B5', 'B6']).rename('postFNDMI');
var postLogNDMI = postLog.normalizedDifference(['B5', 'B6']).rename('postLNDMI');

// rename bands before combining
var preFireB = ee.Image(preFire).select(['B6']).rename('preFB6');
var postFireB = ee.Image(postFire).select(['B6']).rename('postFB6');
var postLogB = ee.Image(postLog).select(['B6']).rename('postLB6'); 
// print(preFireB, 'preFireB');
// combine images 
var covars = preFireB.addBands([postFireB, postLogB, preFireNDVI, postFireNDVI, postLogNDVI,
  preFireNDMI, postFireNDMI, postLogNDMI]);
  
 // Export covariate stack to google drive
Export.image.toDrive({
  image:covars.toFloat(),
  description:'PostLoggingCovariates', 
  folder:'GEE_Landsat_Exports', 
  region:aoi, 
  scale:30, 
  crs:"EPSG:26910", 
  maxPixels:1e13});
