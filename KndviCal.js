// Define the months and year for analysis (pre-fire and post-fire)
var monthsEval = ee.List([
  {'month': 1, 'label': 'PreFire'},      // January 2024
  {'month': 10, 'label': 'PostFire'}     // October 2024
]);

// Sentinel-2 Level-2A image collection
var S2 = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED');

// Define study area (make sure 'studyarea' is already defined)
Map.centerObject(studyarea, 8);

// Function to apply cloud and shadow masking using SCL
var maskS2Clouds = function(image) {
  var scl = image.select('SCL');
  var mask = scl.neq(3)  // shadow
                 .and(scl.neq(7))  // cloud low prob
                 .and(scl.neq(8))  // cloud medium prob
                 .and(scl.neq(9))  // cloud high prob
                 .and(scl.neq(10));  // cirrus
  return image.updateMask(mask).copyProperties(image, image.propertyNames());
};

// Function to compute kNDVI
var calculateKNDVI = function(nir, red, sigma) {
  var kndvi = ee.Image().expression(
    'tanh((pow((nir - red), 2)) / (2 * pow(sigma, 2)))',
    {
      'nir': nir,
      'red': red,
      'sigma': sigma
    }
  ).rename('kNDVI');
  return kndvi;
};

// Function to estimate sigma
var estimateSigma = function(collection) {
  var diff = collection.map(function(img) {
    return img.select('B8').subtract(img.select('B4')).abs();
  });
  var sigma = diff.mean().reduceRegion({
    reducer: ee.Reducer.mean(),
    geometry: studyarea.geometry(),
    scale: 10,
    maxPixels: 1e9
  }).get('B8');
  return ee.Number(sigma);
};

// Function to calculate and export kNDVI for a given month
var calculateMonthlyKNDVI = function(entry) {
  var month = ee.Dictionary(entry).get('month');
  var label = ee.Dictionary(entry).get('label');

  var start = ee.Date.fromYMD(2024, month, 1);
  var end = start.advance(1, 'month');

  var collection = S2
    .filterBounds(studyarea)
    .filterDate(start, end)
    .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', 40))
    .map(maskS2Clouds)
    .select(['B4', 'B8']); // Red and NIR

  var scaled = collection.map(function(img) {
    return img.divide(10000);
  });

  var sigma = estimateSigma(scaled);

  var kndviCollection = scaled.map(function(img) {
    return calculateKNDVI(img.select('B8'), img.select('B4'), sigma)
      .copyProperties(img, img.propertyNames());
  });

  var kndviMedian = kndviCollection.median()
                      .clip(studyarea)
                      .set('month', month)
                      .rename('kNDVI_' + label);

  // Visualise on map
  Map.addLayer(kndviMedian, {min: -1, max: 1, palette: ['blue', 'white', 'green']}, 'kNDVI_' + label);

  // Export to Drive
  Export.image.toDrive({
    image: kndviMedian,
    description: 'kNDVI_' + label + '_2024',
    folder: 'kNDVI_Yajiang',
    fileNamePrefix: 'kNDVI_' + label + '_2024',
    region: studyarea.geometry(),
    scale: 10,
    crs: 'EPSG:4326',
    maxPixels: 1e13
  });
};

// Apply function to each selected month
monthsEval.evaluate(function(monthList) {
  monthList.forEach(function(m) {
    calculateMonthlyKNDVI(m);
  });
});
