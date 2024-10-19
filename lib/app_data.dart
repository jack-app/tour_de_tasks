const initialSpeedKmPerSec = 0.03;
const maxSpeedKmPerSec = 0.09;

// city: distance from Paris in km
const Map<String, double> cities = {
  'Paris': 1,
  'Angouleme': 16.2,
  'Osny': 41.5,
  'Beauvais': 89.9,
  'Reims': 259,
  'Troyes': 396,
  'Auxerre': 467,
  'Beaune': 624,
  'Lyon': 797,
  'Montpellier': 1125,
  'Toulouse': 1385,
};

enum Page { start, main, goal }
