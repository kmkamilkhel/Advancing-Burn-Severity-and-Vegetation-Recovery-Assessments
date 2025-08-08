// Cloud masking function for Sentinel-2 SR
function cloudMask(image) {
  var scl = image.select('SCL');
  var mask = scl.eq(3).or(scl.gte(7).and(scl.lte(10))).eq(0);
  return image.select(['B4', 'B6', 'B7', 'B8', 'B8A', 'B11', 'B12'])
              .divide(10000)
              .updateMask(mask);
}

// --------------------
// Calculate NBR
function calcNBR(image) {
  return image.normalizedDifference(['B8', 'B12']).rename('NBR');
}

// --------------------
// Calculate BAIS2
function calcBAIS2(image) {
  return image.expression(
    '(1 - sqrt((B06 * B07 * B8A) / B04)) * ((B12 - B8A) / sqrt(B12 + B8A) + 1)', {
      'B04': image.select('B4').toFloat(),
      'B06': image.select('B6').toFloat(),
      'B07': image.select('B7').toFloat(),
      'B8A': image.select('B8A').toFloat(),
      'B12': image.select('B12').toFloat()
    }).rename('BAIS2');
}

// --------------------
// Pre-fire composite (e.g., Jan–Feb 2024)
var preFire = ee.ImageCollection('COPERNICUS/S2_SR')
  .filterBounds(geometry)
  .filterDate('2024-01-01', '2024-02-29')
  .map(cloudMask)
  .median()
  .clip(geometry);

// --------------------
// Post-fire composite (e.g., Sep–Oct 2024)
var postFire = ee.ImageCollection('COPERNICUS/S2_SR')
  .filterBounds(geometry)
  .filterDate('2024-09-01', '2024-10-31')
  .map(cloudMask)
  .median()
  .clip(geometry);

// --------------------
// Calculate NBR and BAIS2 for both periods
var nbrPre = calcNBR(preFire);
var nbrPost = calcNBR(postFire);
var bais2Pre = calcBAIS2(preFire);
var bais2Post = calcBAIS2(postFire);

// --------------------
// Compute dNBR and dBAIS2
var dNBR = nbrPre.subtract(nbrPost).rename('dNBR');
var dBAIS2 = bais2Pre.subtract(bais2Post).rename('dBAIS2');

// --------------------
// Compute RBR and RdNBR
var RBR = dNBR.divide(nbrPre.add(1.001)).rename('RBR');
var RdNBR = dNBR.divide(nbrPre.abs().sqrt()).rename('RdNBR');

// --------------------
// Stack all burn severity indices
var burnIndices = dNBR.addBands(dBAIS2).addBands(RBR).addBands(RdNBR).toFloat();

// --------------------
// Export burn severity indices to Google Drive
Export.image.toDrive({
  image: burnIndices,
  description: 'Burn_Severity_Indices_Yajiang_2024',
  scale: 10,
  region: geometry,
  crs: 'EPSG:4326',
  folder: 'Yajiang_Burn_Severity',
  fileFormat: 'GeoTIFF',
  maxPixels: 1e13
});
