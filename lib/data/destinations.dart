import '../models/models.dart';

/// Curated travel guide. Coordinates and elevations are approximate and
/// refer to the main settlement or site. This data ships with the app.
const List<Destination> destinations = [
  Destination(
    id: 'hunza', name: 'Hunza Valley', region: 'Gilgit-Baltistan',
    category: DestinationCategory.mountains, lat: 36.3167, lon: 74.6500,
    elevationM: 2500, difficulty: 'Moderate', suggestedStay: '4-7 days',
    bestSeason: 'April to October',
    description: 'A valley on the Karakoram Highway ringed by high peaks, known for its centuries-old forts, apricot orchards and spring blossom.',
    highlights: ['Baltit Fort', 'Altit Fort', 'Eagle\'s Nest viewpoint', 'Views of Rakaposhi and Ultar Sar'],
    gettingThere: 'By road from Gilgit along the Karakoram Highway, typically 2-3 hours. Flights from Islamabad to Gilgit depend on the weather.',
  ),
  Destination(
    id: 'attabad', name: 'Attabad Lake', region: 'Gojal, Gilgit-Baltistan',
    category: DestinationCategory.valleys, lat: 36.3333, lon: 74.8667,
    elevationM: 2550, difficulty: 'Easy', suggestedStay: '1-2 days',
    bestSeason: 'May to October',
    description: 'A striking turquoise lake formed by a massive landslide in 2010 that blocked the Hunza River. The Karakoram Highway now runs alongside it through tunnels.',
    highlights: ['Boating', 'Karakoram Highway tunnels', 'Lakeside stays'],
    gettingThere: 'On the Karakoram Highway, a short drive north of Karimabad.',
  ),
  Destination(
    id: 'passu', name: 'Passu', region: 'Gojal, Gilgit-Baltistan',
    category: DestinationCategory.mountains, lat: 36.4833, lon: 74.8833,
    elevationM: 2400, difficulty: 'Moderate', suggestedStay: '2-3 days',
    bestSeason: 'May to October',
    description: 'A small village beneath the jagged Passu Cones, with glaciers and suspension bridges within reach on foot.',
    highlights: ['Passu Cones', 'Passu Glacier', 'Hussaini suspension bridge', 'Borith Lake'],
    gettingThere: 'On the Karakoram Highway, north of Attabad Lake.',
  ),
  Destination(
    id: 'khunjerab', name: 'Khunjerab Pass', region: 'Pakistan-China border',
    category: DestinationCategory.mountains, lat: 36.8500, lon: 75.4200,
    elevationM: 4693, difficulty: 'Moderate', suggestedStay: 'Day trip',
    bestSeason: 'May to October',
    description: 'The high-altitude border crossing on the Karakoram Highway and one of the highest paved border crossings in the world. Altitude sickness is a real risk, so ascend sensibly.',
    highlights: ['Pakistan-China border gate', 'Khunjerab National Park', 'Sost'],
    gettingThere: 'A long day trip north from Passu or Karimabad via Sost.',
  ),
  Destination(
    id: 'gilgit', name: 'Gilgit', region: 'Gilgit-Baltistan',
    category: DestinationCategory.cities, lat: 35.9208, lon: 74.3080,
    elevationM: 1500, difficulty: 'Easy', suggestedStay: '1-2 days',
    bestSeason: 'March to November',
    description: 'The regional capital and main transport hub for the northern areas, useful for restocking supplies and arranging onward travel.',
    highlights: ['Gilgit bazaar', 'Kargah Buddha', 'Naltar Valley excursion'],
    gettingThere: 'Flights from Islamabad when the weather allows, or a long drive on the Karakoram Highway.',
  ),
  Destination(
    id: 'skardu', name: 'Skardu', region: 'Baltistan, Gilgit-Baltistan',
    category: DestinationCategory.mountains, lat: 35.2976, lon: 75.6333,
    elevationM: 2228, difficulty: 'Moderate', suggestedStay: '5-8 days',
    bestSeason: 'May to September',
    description: 'The gateway to the Karakoram giants and K2 expeditions, set in a wide valley with a cold desert, lakes and an old fort above the town.',
    highlights: ['Shangrila and Upper Kachura Lake', 'Katpana Cold Desert', 'Shigar Fort', 'Kharpocho Fort'],
    gettingThere: 'Flights from Islamabad, or by road via the Karakoram Highway and the Jaglot-Skardu road.',
  ),
  Destination(
    id: 'deosai', name: 'Deosai Plains', region: 'Gilgit-Baltistan',
    category: DestinationCategory.mountains, lat: 35.0000, lon: 75.4000,
    elevationM: 4114, difficulty: 'Challenging', suggestedStay: '1-2 days',
    bestSeason: 'July to September',
    description: 'A vast high-altitude plateau and national park that blooms with wildflowers in summer and is home to Himalayan brown bears. Snow closes it for much of the year.',
    highlights: ['Sheosar Lake', 'Himalayan brown bear habitat', 'Summer wildflowers'],
    gettingThere: 'By 4x4 from Skardu or Astore during the summer months. Carry fuel and warm layers.',
  ),
  Destination(
    id: 'fairy-meadows', name: 'Fairy Meadows', region: 'Diamer, Gilgit-Baltistan',
    category: DestinationCategory.mountains, lat: 35.3833, lon: 74.5833,
    elevationM: 3300, difficulty: 'Challenging', suggestedStay: '2-4 days',
    bestSeason: 'June to September',
    description: 'An alpine meadow with close views of Nanga Parbat, the world\'s ninth highest mountain. The last stretch cannot be driven.',
    highlights: ['Nanga Parbat views', 'Beyal Camp', 'Nanga Parbat Base Camp trek'],
    gettingThere: 'Jeep from Raikot Bridge on the Karakoram Highway to Tato, then a hike of a few hours.',
  ),
  Destination(
    id: 'naran', name: 'Naran & Kaghan', region: 'Mansehra, Khyber Pakhtunkhwa',
    category: DestinationCategory.valleys, lat: 34.9093, lon: 73.6507,
    elevationM: 2409, difficulty: 'Easy', suggestedStay: '3-4 days',
    bestSeason: 'May to September',
    description: 'A popular summer valley following the Kunhar River, and the base for visiting Lake Saif-ul-Malook and crossing Babusar Pass.',
    highlights: ['Lake Saif-ul-Malook', 'Lulusar Lake', 'Babusar Pass', 'Kunhar River'],
    gettingThere: 'By road from Islamabad via the Hazara Motorway and Balakot. Upper roads usually close in winter.',
  ),
  Destination(
    id: 'swat', name: 'Swat Valley', region: 'Khyber Pakhtunkhwa',
    category: DestinationCategory.valleys, lat: 34.7717, lon: 72.3600,
    elevationM: 984, difficulty: 'Easy', suggestedStay: '3-5 days',
    bestSeason: 'March to October',
    description: 'A green river valley with deep Buddhist history, orchards and a ski resort. Mingora is the main town, with Kalam further up the valley.',
    highlights: ['Malam Jabba', 'Kalam and Ushu Forest', 'Butkara Stupa', 'Swat Museum'],
    gettingThere: 'By road from Islamabad or Peshawar via the Swat Motorway.',
  ),
  Destination(
    id: 'chitral', name: 'Chitral', region: 'Khyber Pakhtunkhwa',
    category: DestinationCategory.mountains, lat: 35.8518, lon: 71.7864,
    elevationM: 1494, difficulty: 'Moderate', suggestedStay: '3-5 days',
    bestSeason: 'May to October',
    description: 'A remote town beneath Tirich Mir, the highest peak of the Hindu Kush, known for its polo traditions and historic Shahi Mosque.',
    highlights: ['Chitral Fort', 'Shahi Mosque', 'Tirich Mir views', 'Shandur Pass polo festival'],
    gettingThere: 'By road through the Lowari Tunnel from Dir, or by flight when operating.',
  ),
  Destination(
    id: 'kalash', name: 'Kalash Valleys', region: 'Chitral, Khyber Pakhtunkhwa',
    category: DestinationCategory.valleys, lat: 35.7167, lon: 71.6833,
    elevationM: 1900, difficulty: 'Moderate', suggestedStay: '2-3 days',
    bestSeason: 'May to October',
    description: 'Bumburet, Rumbur and Birir are home to the Kalash people, with their own language, customs and seasonal festivals. Please ask before photographing people.',
    highlights: ['Bumburet village', 'Chilam Joshi spring festival', 'Kalash museum'],
    gettingThere: 'By jeep or car from Chitral town, around two hours.',
  ),
  Destination(
    id: 'neelum', name: 'Neelum Valley', region: 'Azad Kashmir',
    category: DestinationCategory.valleys, lat: 34.7833, lon: 74.1833,
    elevationM: 1981, difficulty: 'Moderate', suggestedStay: '3-5 days',
    bestSeason: 'April to October',
    description: 'A long forested valley following the Neelum River from Muzaffarabad, with quiet villages such as Keran and Sharda. Check local advice as the valley runs close to the Line of Control.',
    highlights: ['Sharda', 'Keran', 'Arang Kel', 'Ratti Gali Lake'],
    gettingThere: 'By road from Muzaffarabad. Upper sections are best by 4x4.',
  ),
  Destination(
    id: 'murree', name: 'Murree', region: 'Punjab',
    category: DestinationCategory.mountains, lat: 33.9070, lon: 73.3943,
    elevationM: 2291, difficulty: 'Easy', suggestedStay: '1-2 days',
    bestSeason: 'March to November',
    description: 'A colonial-era hill station close to Islamabad. It gets crowded in peak season, and heavy snowfall can make its roads dangerous.',
    highlights: ['Mall Road', 'Patriata chairlift', 'Nathia Gali excursion'],
    gettingThere: 'Around 1-2 hours by road from Islamabad.',
  ),
  Destination(
    id: 'ziarat', name: 'Ziarat', region: 'Balochistan',
    category: DestinationCategory.mountains, lat: 30.3817, lon: 67.7250,
    elevationM: 2449, difficulty: 'Easy', suggestedStay: '1-2 days',
    bestSeason: 'April to September',
    description: 'A cool hill town among some of the world\'s oldest juniper forests, and home to the residency where Quaid-e-Azam spent his final days.',
    highlights: ['Quaid-e-Azam Residency', 'Juniper forests'],
    gettingThere: 'By road from Quetta. Check current travel advisories first.',
  ),
  Destination(
    id: 'islamabad', name: 'Islamabad', region: 'Capital Territory',
    category: DestinationCategory.cities, lat: 33.6844, lon: 73.0479,
    elevationM: 540, difficulty: 'Easy', suggestedStay: '2-3 days',
    bestSeason: 'October to April',
    description: 'Pakistan\'s planned capital at the foot of the Margalla Hills, and the usual starting point for trips north.',
    highlights: ['Faisal Mosque', 'Daman-e-Koh', 'Margalla Hills trails', 'Pakistan Monument'],
    gettingThere: 'International airport, with motorway links to Lahore and Peshawar.',
  ),
  Destination(
    id: 'lahore', name: 'Lahore', region: 'Punjab',
    category: DestinationCategory.cities, lat: 31.5204, lon: 74.3587,
    elevationM: 217, difficulty: 'Easy', suggestedStay: '3-4 days',
    bestSeason: 'October to March',
    description: 'The cultural heart of Punjab, with grand Mughal monuments and celebrated street food in its old walled city.',
    highlights: ['Badshahi Mosque', 'Lahore Fort', 'Wazir Khan Mosque', 'Shalimar Gardens'],
    gettingThere: 'International airport, with motorway and rail links across the country.',
  ),
  Destination(
    id: 'rohtas', name: 'Rohtas Fort', region: 'Jhelum, Punjab',
    category: DestinationCategory.heritage, lat: 32.9667, lon: 73.5750,
    elevationM: 300, difficulty: 'Easy', suggestedStay: 'Half day',
    bestSeason: 'October to March',
    description: 'A UNESCO World Heritage Site built in the 16th century under Sher Shah Suri, with massive walls and monumental gates.',
    highlights: ['Sohail Gate', 'Fort walls', 'Haveli Man Singh'],
    gettingThere: 'A short drive from Dina on the Grand Trunk Road.',
  ),
  Destination(
    id: 'taxila', name: 'Taxila', region: 'Rawalpindi, Punjab',
    category: DestinationCategory.heritage, lat: 33.7463, lon: 72.8397,
    elevationM: 550, difficulty: 'Easy', suggestedStay: '1 day',
    bestSeason: 'October to April',
    description: 'A UNESCO World Heritage Site with ruins of an ancient city that was a centre of Gandharan art and Buddhist learning.',
    highlights: ['Taxila Museum', 'Sirkap', 'Dharmarajika Stupa', 'Jaulian'],
    gettingThere: 'Around an hour by road from Islamabad.',
  ),
  Destination(
    id: 'takht-i-bahi', name: 'Takht-i-Bahi', region: 'Mardan, Khyber Pakhtunkhwa',
    category: DestinationCategory.heritage, lat: 34.2864, lon: 71.9465,
    elevationM: 500, difficulty: 'Easy', suggestedStay: 'Half day',
    bestSeason: 'October to April',
    description: 'A remarkably well-preserved Buddhist monastic complex on a hilltop, listed by UNESCO. Expect a short uphill walk to reach it.',
    highlights: ['Monastic complex', 'Hilltop views', 'Sahr-i-Bahlol nearby'],
    gettingThere: 'By road from Mardan or Peshawar.',
  ),
  Destination(
    id: 'mohenjo-daro', name: 'Mohenjo-daro', region: 'Larkana, Sindh',
    category: DestinationCategory.heritage, lat: 27.3292, lon: 68.1389,
    elevationM: 50, difficulty: 'Easy', suggestedStay: '1 day',
    bestSeason: 'November to February',
    description: 'One of the great cities of the Indus Valley Civilisation, around 4,500 years old, and a UNESCO World Heritage Site. Summers are extremely hot.',
    highlights: ['The Great Bath', 'Buddhist stupa', 'Site museum'],
    gettingThere: 'By road from Larkana or Sukkur.',
  ),
  Destination(
    id: 'makli', name: 'Makli Necropolis', region: 'Thatta, Sindh',
    category: DestinationCategory.heritage, lat: 24.7500, lon: 67.9000,
    elevationM: 30, difficulty: 'Easy', suggestedStay: 'Half day',
    bestSeason: 'November to February',
    description: 'One of the largest funerary sites in the world and a UNESCO World Heritage Site, with finely carved stone tombs spread across a hill.',
    highlights: ['Tomb of Jam Nizamuddin II', 'Shah Jahan Mosque in Thatta'],
    gettingThere: 'Around two hours by road from Karachi.',
  ),
  Destination(
    id: 'karachi', name: 'Karachi', region: 'Sindh',
    category: DestinationCategory.cities, lat: 24.8607, lon: 67.0011,
    elevationM: 10, difficulty: 'Easy', suggestedStay: '2-4 days',
    bestSeason: 'November to February',
    description: 'Pakistan\'s largest city and main port, with colonial architecture, a busy coastline and a huge food scene.',
    highlights: ['Mazar-e-Quaid', 'Frere Hall', 'Mohatta Palace', 'Clifton Beach'],
    gettingThere: 'International airport, with rail links and highways to the rest of the country.',
  ),
  Destination(
    id: 'hingol', name: 'Hingol National Park', region: 'Balochistan',
    category: DestinationCategory.coast, lat: 25.5000, lon: 65.5000,
    elevationM: 100, difficulty: 'Moderate', suggestedStay: '1-2 days',
    bestSeason: 'November to February',
    description: 'Pakistan\'s largest national park, with wind-carved rock formations, mud volcanoes and empty beaches along the Makran coast.',
    highlights: ['Princess of Hope', 'Kund Malir Beach', 'Chandragup mud volcano'],
    gettingThere: 'By road from Karachi on the Makran Coastal Highway. Services are sparse, so carry fuel and water and check advisories.',
  ),
  Destination(
    id: 'gwadar', name: 'Gwadar', region: 'Balochistan',
    category: DestinationCategory.coast, lat: 25.1264, lon: 62.3225,
    elevationM: 10, difficulty: 'Moderate', suggestedStay: '2-3 days',
    bestSeason: 'November to February',
    description: 'A port town on a hammerhead peninsula with a dramatic coastline on the Arabian Sea. Check current travel advisories before planning a visit.',
    highlights: ['Hammerhead peninsula', 'Ormara Beach on the way', 'Coastal drives'],
    gettingThere: 'By road on the Makran Coastal Highway, or by flight when operating.',
  ),
];

Destination? destinationById(String? id) {
  if (id == null) return null;
  for (final d in destinations) {
    if (d.id == id) return d;
  }
  return null;
}

const List<String> defaultChecklist = [
  'CNIC or passport, with copies',
  'Cash in PKR (ATMs are scarce up north)',
  'Power bank',
  'First aid kit',
  'Personal and altitude medication',
  'Warm layers and a rain jacket',
  'Sunscreen and sunglasses',
  'Refillable water bottle',
];

class EmergencyContact {
  const EmergencyContact(this.title, this.subtitle, this.number);
  final String title;
  final String subtitle;
  final String number;
}

const List<EmergencyContact> emergencyContacts = [
  EmergencyContact('Police', 'Nationwide emergency line', '15'),
  EmergencyContact('Rescue 1122', 'Ambulance, fire and rescue. Coverage varies by region', '1122'),
  EmergencyContact('Edhi Ambulance', 'Volunteer ambulance service', '115'),
  EmergencyContact('Motorway Police', 'National Highways & Motorway Police helpline', '130'),
];
