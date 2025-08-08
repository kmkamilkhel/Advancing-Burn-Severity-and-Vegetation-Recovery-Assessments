function cloudMask(image) {
  var scl = image.select('SCL');
  var mask = scl.eq(3).or(scl.gte(7).and(scl.lte(10))).eq(0);
  return image.select(['B2', 'B3', 'B4', 'B6', 'B7', 'B8', 'B8A', 'B9', 'B11', 'B12'])
              .divide(10000)
              .updateMask(mask);
}

function calculateNBR(image) {
  return image.normalizedDifference(['B8', 'B12']).rename('NBR');
}

function calculateNBR2(image) {
  return image.normalizedDifference(['B8A', 'B12']).rename('NBR2');
}

function calculateNDVI(image) {
  return image.normalizedDifference(['B8', 'B4']).rename('NDVI');
}

function calculateNDWI(image) {
  return image.normalizedDifference(['B8', 'B11']).rename('NDWI');
}

function calculateVARI(image) {
  return image.expression(
    '(G - R) / (G + R + 0.0001)', {
      'G': image.select('B3'),
      'R': image.select('B4')
    }).rename('VARI');
}

function calculateMSAVI(image) {
  return image.expression(
    '((2 * NIR + 1) - sqrt((2 * NIR + 1) * (2 * NIR + 1) - 8 * (NIR - R))) / 2', {
      'NIR': image.select('B8').toFloat(),
      'R': image.select('B4').toFloat()
    }).rename('MSAVI');
}

function calculateBAIS2(image) {
  return image.expression(
    '(1 - sqrt((B06 * B07 * B8A) / B04)) * ((B12 - B8A) / sqrt(B12 + B8A) + 1)', {
      'B04': image.select('B4').toFloat(),
      'B06': image.select('B6').toFloat(),
      'B07': image.select('B7').toFloat(),
      'B8A': image.select('B8A').toFloat(),
      'B12': image.select('B12').toFloat()
    }).rename('BAIS2');
}

function calculateMIRBI(image) {
  return image.expression(
    '10 + SWIR2 + (9.8 * SWIR1)', {
      'SWIR1': image.select('B11'),
      'SWIR2': image.select('B12')
    }).rename('MIRBI');
}

function calculateCSI(image) {
  return image.expression(
    'NIR / SWIR1', {
      'NIR': image.select('B8'),
      'SWIR1': image.select('B11')
    }).rename('CSI');
}

var s2 = ee.ImageCollection('COPERNICUS/S2_SR')
  .filterBounds(geometry)
  .filterDate('2024-01-01', '2024-10-31')
  .map(cloudMask)
  .median()
  .clip(geometry);

var nbr = calculateNBR(s2);
var nbr2 = calculateNBR2(s2);
var ndvi = calculateNDVI(s2);
var ndwi = calculateNDWI(s2);
var vari = calculateVARI(s2);
var msavi = calculateMSAVI(s2);
var bais2 = calculateBAIS2(s2);
var mirbi = calculateMIRBI(s2);
var csi = calculateCSI(s2);

var allIndices = nbr
  .addBands(nbr2)
  .addBands(ndvi)
  .addBands(ndwi)
  .addBands(vari)
  .addBands(msavi)
  .addBands(bais2)
  .addBands(mirbi)
  .addBands(csi)
  .toFloat();

Export.image.toDrive({
  image: allIndices,
  description: 'Sentinel2_Indices_Yajiang_2024',
  scale: 10,
  region: geometry,
  crs: 'EPSG:4326',
  folder: 'Yajiang_Burn_Indices',
  fileFormat: 'GeoTIFF',
  maxPixels: 1e13
});
