// Magnified crops of the real captures: [source, x, y, width, height, crop-left, crop-top, zoom]
// Crop coordinates are source-image pixels; x/y/width/height are canvas pixels.
window.CALLOUTS = {
  iphone: {
    studio: [['studio', 40, 2340, 1240, 470, 10, 1760, 0.96]],
    style: [['style', 40, 1700, 1240, 500, 10, 840, 0.96]],
    radio: [['radio', 50, 2150, 1220, 660, -30, 1540, 0.88]],
    export: [['export-settings', 40, 1580, 1240, 317, 10, 640, 0.96]],
  },
  ipad: {
    studio: [['studio', 266, 1640, 2220, 320, 520, 1620, 1.0]],
    style: [['style', 1300, 1080, 1331, 715, 780, 780, 1.1]],
    radio: [['radio', 138, 1690, 2477, 252, 0, 1730, 0.9]],
    export: [['export-settings', 900, 1150, 1356, 300, 820, 640, 1.2]],
  },
};
