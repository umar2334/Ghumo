class Expedition {
  final String id;
  final String name;
  final String location;
  final String imageUrl;
  final double rating;
  final String difficulty;
  final String duration;
  final List<String> tags;
  final String description;
  final double lat;
  final double lon;
  bool isSaved;

  Expedition({
    required this.id,
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.rating,
    required this.difficulty,
    required this.duration,
    required this.tags,
    required this.description,
    required this.lat,
    required this.lon,
    this.isSaved = false,
  });
}

class WeatherData {
  final double temperature;
  final int weatherCode;
  final double windspeed;

  const WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.windspeed,
  });

  String get icon {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 3) return '⛅';
    if (weatherCode <= 48) return '🌫️';
    if (weatherCode <= 67) return '🌧️';
    if (weatherCode <= 77) return '❄️';
    if (weatherCode <= 82) return '🌦️';
    if (weatherCode <= 86) return '🌨️';
    return '⛈️';
  }

  String get tempStr => '${temperature.round()}°C';
}

class ExpenseItem {
  final String id;
  final String title;
  final String date;
  final String category;
  double amount;
  final String emoji;

  ExpenseItem({
    required this.id,
    required this.title,
    required this.date,
    required this.category,
    required this.amount,
    required this.emoji,
  });
}

class TripStop {
  int number;
  String phase;
  String name;
  String? description;
  String? temperature;
  String? hotel;
  String? activity;
  List<String>? tags;
  bool isCompleted;
  bool isInProgress;

  TripStop({
    required this.number,
    required this.phase,
    required this.name,
    this.description,
    this.temperature,
    this.hotel,
    this.activity,
    this.tags,
    this.isCompleted = false,
    this.isInProgress = false,
  });
}

class MapRegion {
  final String name;
  final String size;
  String detail;
  bool isDownloaded;
  double downloadProgress;

  MapRegion({
    required this.name,
    required this.size,
    required this.detail,
    this.isDownloaded = false,
    this.downloadProgress = 0.0,
  });
}

// ─── Sample data ────────────────────────────────────────────────────────────

List<Expedition> featuredExpeditions = [
  Expedition(
    id: '1',
    name: 'HUNZA',
    location: 'Gilgit-Baltistan',
    imageUrl: '',
    rating: 4.8,
    difficulty: 'Moderate',
    duration: '7 Days',
    tags: ['Mountains', 'Culture', 'Trekking'],
    description:
        'Explore the breathtaking Hunza Valley with its ancient forts, crystal-clear Attabad Lake, and majestic views of Rakaposhi. Home to the Aga Khan\'s heritage.',
    lat: 36.3167,
    lon: 74.6500,
  ),
  Expedition(
    id: '2',
    name: 'SKARDU',
    location: 'Gilgit-Baltistan',
    imageUrl: '',
    rating: 4.9,
    difficulty: 'Challenging',
    duration: '10 Days',
    tags: ['K2', 'Glaciers', 'Adventure'],
    description:
        "Gateway to the world's highest peaks and most spectacular glaciers including Baltoro and Siachen. Base for K2 expeditions.",
    lat: 35.2971,
    lon: 75.6130,
  ),
  Expedition(
    id: '3',
    name: 'SWAT',
    location: 'KPK, Pakistan',
    imageUrl: '',
    rating: 4.6,
    difficulty: 'Easy',
    duration: '5 Days',
    tags: ['Valley', 'History', 'Scenic'],
    description:
        'The Switzerland of the East. Lush valleys, roaring rivers, and rich Buddhist history. Visit Mingora, Malam Jabba, and Kalam.',
    lat: 35.2227,
    lon: 72.4258,
  ),
  Expedition(
    id: '4',
    name: 'NARAN',
    location: 'Mansehra, KPK',
    imageUrl: '',
    rating: 4.7,
    difficulty: 'Easy',
    duration: '4 Days',
    tags: ['Scenic', 'Lakes', 'Nature'],
    description:
        'Home to the stunning Saif ul Malook Lake and gateway to Babusar Pass. Drive through the Kaghan Valley alongside the Kunhar River.',
    lat: 34.9041,
    lon: 73.6514,
  ),
  Expedition(
    id: '5',
    name: 'FAIRY MEADOWS',
    location: 'Diamer, GB',
    imageUrl: '',
    rating: 4.9,
    difficulty: 'Challenging',
    duration: '6 Days',
    tags: ['Trekking', 'Camping', 'Adventure'],
    description:
        "Meadows at the base of Nanga Parbat — the world's 9th highest peak. Accessible only by a steep jeep track and a 3-hour hike.",
    lat: 35.3736,
    lon: 74.5783,
  ),
];

List<ExpenseItem> recentExpenses = [
  ExpenseItem(
      id: '1',
      title: 'Karakoram Hotel',
      date: '14 OCT, 2023',
      category: 'ACCOMMODATION',
      amount: 120.00,
      emoji: '🏨'),
  ExpenseItem(
      id: '2',
      title: 'PSO Fuel Skardu',
      date: '13 OCT, 2023',
      category: 'TRANSPORT',
      amount: 45.00,
      emoji: '⛽'),
  ExpenseItem(
      id: '3',
      title: 'Local Dhaba Dinner',
      date: '13 OCT, 2023',
      category: 'FOOD & DRINK',
      amount: 18.50,
      emoji: '🍛'),
  ExpenseItem(
      id: '4',
      title: 'Gift Shop Hunza',
      date: '12 OCT, 2023',
      category: 'SOUVENIRS',
      amount: 35.00,
      emoji: '🛍️'),
];

List<TripStop> tripStops = [
  TripStop(
    number: 1,
    phase: 'ARRIVAL',
    name: 'ATTABAD LAKE',
    temperature: '8°C CRYSTAL CLEAR',
    hotel: 'Luxus Grand',
    activity: 'Jet Skiing',
    isCompleted: true,
  ),
  TripStop(
    number: 2,
    phase: 'HIGH PEAKS',
    name: 'Passu Cones Exploration',
    description:
        'A morning drive towards the iconic cathedral peaks, followed by a walk along the Hunza river edge...',
    tags: ['TREKKING', 'PHOTOGRAPHY', '4X4 JEEP'],
    isInProgress: true,
  ),
  TripStop(
    number: 3,
    phase: 'GLACIER WALK',
    name: 'Baltit Fort',
    isCompleted: false,
  ),
];

List<MapRegion> mapRegions = [
  MapRegion(
      name: 'Hunza Valley',
      size: '120MB',
      detail: 'High Detail',
      isDownloaded: false,
      downloadProgress: 0.0),
  MapRegion(
      name: 'Skardu & Baltistan',
      size: '185MB',
      detail: 'Downloaded',
      isDownloaded: true,
      downloadProgress: 1.0),
  MapRegion(
      name: 'Swat Valley',
      size: '95MB',
      detail: 'Mid Detail',
      isDownloaded: false,
      downloadProgress: 0.0),
  MapRegion(
      name: 'Gilgit City',
      size: '45MB',
      detail: 'Navigation only',
      isDownloaded: false,
      downloadProgress: 0.0),
];

const List<String> expenseCategories = [
  'ACCOMMODATION',
  'TRANSPORT',
  'FOOD & DRINK',
  'ACTIVITIES',
  'SOUVENIRS',
  'SHOPPING',
  'MEDICAL',
  'OTHER',
];

const Map<String, String> categoryEmojis = {
  'ACCOMMODATION': '🏨',
  'TRANSPORT': '🚗',
  'FOOD & DRINK': '🍛',
  'ACTIVITIES': '🧗',
  'SOUVENIRS': '🛍️',
  'SHOPPING': '🛒',
  'MEDICAL': '💊',
  'OTHER': '📦',
};

const List<String> tripPhases = [
  'ARRIVAL',
  'TRANSIT',
  'HIGH PEAKS',
  'GLACIER WALK',
  'SIGHTSEEING',
  'DEPARTURE',
];
