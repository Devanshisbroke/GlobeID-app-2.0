/// Low-poly continent outlines used by the cinematic globe renderer.
///
/// Each entry is a closed polygon expressed as a list of (lat, lng)
/// pairs in degrees. The shapes are intentionally low-fidelity — the
/// renderer projects each vertex onto the sphere via the great-circle
/// camera, so even a sparse polygon reads as a recognizable continent.
///
/// This module is hand-curated from public-domain Natural Earth data
/// (admin_0_countries) sub-sampled to ~12-24 points per landmass to
/// keep the painter cost flat. Higher fidelity would require shipping
/// a binary asset; punted for V1.
class WorldOutlines {
  WorldOutlines._();

  /// All landmass outlines.
  static const List<List<List<double>>> all = [
    // North America (approximate)
    [
      [70, -160], [70, -130], [60, -120], [60, -100], [55, -85],
      [50, -70], [44, -65], [38, -75], [30, -82], [25, -97],
      [20, -105], [22, -110], [30, -115], [38, -123], [48, -125],
      [55, -135], [60, -145], [65, -160],
    ],
    // South America (approximate)
    [
      [12, -72], [10, -62], [5, -52], [-5, -35], [-15, -38],
      [-23, -42], [-30, -50], [-40, -58], [-50, -68], [-55, -70],
      [-50, -73], [-40, -73], [-30, -71], [-20, -70], [-10, -78],
      [0, -80], [8, -78],
    ],
    // Africa (approximate)
    [
      [35, -10], [37, 8], [33, 12], [31, 22], [27, 35],
      [15, 40], [12, 50], [4, 45], [-4, 40], [-15, 40],
      [-25, 33], [-34, 25], [-34, 18], [-30, 16], [-22, 14],
      [-12, 13], [0, 9], [5, -3], [10, -10], [15, -17],
      [20, -16], [27, -12],
    ],
    // Eurasia (very rough, two-loop big landmass)
    [
      [70, 30], [72, 60], [75, 100], [70, 140], [65, 165],
      [55, 175], [45, 145], [40, 130], [35, 115], [30, 105],
      [22, 100], [15, 105], [10, 100], [12, 90], [20, 88],
      [22, 75], [25, 70], [25, 60], [20, 55], [25, 45],
      [35, 40], [40, 28], [45, 15], [50, 5], [55, 10],
      [62, 20], [70, 25],
    ],
    // South-east Asia / Indonesia (rough)
    [
      [5, 95], [3, 100], [0, 105], [-2, 110], [-6, 115],
      [-7, 120], [-5, 130], [-8, 140], [-10, 132], [-9, 122],
      [-7, 110], [-5, 102], [0, 96],
    ],
    // Australia (approximate)
    [
      [-12, 130], [-10, 142], [-15, 148], [-22, 150], [-30, 153],
      [-37, 150], [-39, 144], [-35, 138], [-32, 130], [-28, 120],
      [-22, 115], [-17, 122], [-12, 130],
    ],
    // Greenland (rough)
    [
      [82, -42], [80, -20], [70, -22], [62, -42], [60, -48],
      [70, -55], [78, -60], [82, -42],
    ],
    // British Isles / Scandinavia hint
    [
      [60, -8], [58, 0], [54, -2], [50, -6], [55, -8], [60, -8],
    ],
    [
      [70, 18], [62, 15], [60, 22], [65, 28], [70, 25], [70, 18],
    ],
    // Japan archipelago (rough)
    [
      [44, 144], [40, 142], [36, 140], [33, 131], [38, 138],
      [42, 142], [44, 144],
    ],
    // Madagascar (rough)
    [
      [-13, 49], [-18, 45], [-25, 45], [-25, 47], [-18, 50],
      [-13, 49],
    ],
    // New Zealand (rough)
    [
      [-34, 173], [-37, 175], [-41, 176], [-46, 168], [-44, 168],
      [-40, 172], [-34, 173],
    ],
    // Iberia (rough)
    [
      [44, -9], [43, 0], [40, 2], [36, -5], [38, -10], [44, -9],
    ],
    // India sub-continent
    [
      [33, 75], [28, 88], [22, 90], [12, 80], [8, 78],
      [12, 73], [22, 72], [28, 70], [33, 75],
    ],
    // Antarctic peninsula hint (north tip only)
    [
      [-65, -65], [-66, -60], [-67, -58], [-68, -62], [-65, -65],
    ],
  ];

  /// Capital city / hub airport seeds for the globe markers strip.
  /// (lat, lng, label).
  static const List<MapHub> hubs = [
    MapHub(40.6413, -73.7781, 'JFK'),
    MapHub(51.4700, -0.4543, 'LHR'),
    MapHub(49.0097, 2.5479, 'CDG'),
    MapHub(35.5494, 139.7798, 'HND'),
    MapHub(1.3644, 103.9915, 'SIN'),
    MapHub(25.2528, 55.3644, 'DXB'),
    MapHub(-33.9399, 151.1753, 'SYD'),
    MapHub(19.0896, 72.8656, 'BOM'),
    MapHub(-23.4356, -46.4731, 'GRU'),
    MapHub(34.0522, -118.2437, 'LAX'),
    MapHub(22.3080, 113.9185, 'HKG'),
    MapHub(43.6777, -79.6248, 'YYZ'),
  ];
}

class MapHub {
  const MapHub(this.lat, this.lng, this.code);
  final double lat;
  final double lng;
  final String code;
}
