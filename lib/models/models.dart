import 'package:flutter/material.dart';

enum DestinationCategory {
  mountains('Mountains', Icons.terrain_rounded, Color(0xFF1E3A5C)),
  valleys('Valleys & Lakes', Icons.water_rounded, Color(0xFF1A4A3C)),
  heritage('History', Icons.account_balance_rounded, Color(0xFF4A3218)),
  cities('Cities', Icons.location_city_rounded, Color(0xFF34284E)),
  coast('Coast', Icons.beach_access_rounded, Color(0xFF144A5A));

  const DestinationCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

/// Editorial destination information bundled with the app, so it works offline.
class Destination {
  const Destination({
    required this.id,
    required this.name,
    required this.region,
    required this.category,
    required this.lat,
    required this.lon,
    required this.elevationM,
    required this.difficulty,
    required this.suggestedStay,
    required this.bestSeason,
    required this.description,
    required this.highlights,
    required this.gettingThere,
  });

  final String id;
  final String name;
  final String region;
  final DestinationCategory category;
  final double lat;
  final double lon;

  /// Approximate elevation of the main settlement or site, in metres.
  final int elevationM;
  final String difficulty;
  final String suggestedStay;
  final String bestSeason;
  final String description;
  final List<String> highlights;
  final String gettingThere;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        region.toLowerCase().contains(q) ||
        category.label.toLowerCase().contains(q) ||
        highlights.any((h) => h.toLowerCase().contains(q));
  }
}

enum ExpenseCategory {
  stay('Stay', Icons.hotel_rounded, Color(0xFFFF8855)),
  transport('Transport', Icons.directions_car_rounded, Color(0xFF5C9DFF)),
  food('Food & drink', Icons.restaurant_rounded, AppPalette.amber),
  activities('Activities', Icons.hiking_rounded, Color(0xFF44CC88)),
  shopping('Shopping', Icons.shopping_bag_rounded, Color(0xFFCC88FF)),
  medical('Medical', Icons.medical_services_rounded, Color(0xFF44CCCC)),
  other('Other', Icons.more_horiz_rounded, Color(0xFF9CCDBB));

  const ExpenseCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;

  static ExpenseCategory fromName(String? name) => ExpenseCategory.values
      .firstWhere((c) => c.name == name, orElse: () => ExpenseCategory.other);
}

class AppPalette {
  static const Color amber = Color(0xFFF2B759);
}

class Expense {
  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  final String id;
  String title;
  double amount;
  ExpenseCategory category;
  DateTime date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category.name,
        'date': date.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'] as String,
        title: j['title'] as String,
        amount: (j['amount'] as num).toDouble(),
        category: ExpenseCategory.fromName(j['category'] as String?),
        date: DateTime.parse(j['date'] as String),
      );
}

class TripStop {
  TripStop({
    required this.id,
    required this.name,
    this.day,
    this.notes,
    this.destinationId,
    this.done = false,
  });

  final String id;
  String name;
  int? day;
  String? notes;
  String? destinationId;
  bool done;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'day': day,
        'notes': notes,
        'destinationId': destinationId,
        'done': done,
      };

  factory TripStop.fromJson(Map<String, dynamic> j) => TripStop(
        id: j['id'] as String,
        name: j['name'] as String,
        day: (j['day'] as num?)?.toInt(),
        notes: j['notes'] as String?,
        destinationId: j['destinationId'] as String?,
        done: j['done'] as bool? ?? false,
      );
}

class Trip {
  Trip({
    required this.id,
    required this.name,
    required this.budget,
    this.destinationId,
    this.isSample = false,
    List<TripStop>? stops,
    List<Expense>? expenses,
  })  : stops = stops ?? [],
        expenses = expenses ?? [];

  final String id;
  String name;
  double budget;
  String? destinationId;

  /// Sample trips are labelled in the UI so demo data is never mistaken for
  /// the user's own.
  final bool isSample;
  final List<TripStop> stops;
  final List<Expense> expenses;

  double get totalSpent => expenses.fold(0.0, (sum, e) => sum + e.amount);
  double get remaining => budget - totalSpent;
  bool get isOverBudget => remaining < 0;
  double get budgetUsed =>
      budget > 0 ? (totalSpent / budget).clamp(0.0, 1.0) : 0.0;
  int get completedStops => stops.where((s) => s.done).length;

  /// Spend per category, largest first.
  List<MapEntry<ExpenseCategory, double>> get spendByCategory {
    final totals = <ExpenseCategory, double>{};
    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  /// Expenses, most recent first.
  List<Expense> get expensesByDate =>
      [...expenses]..sort((a, b) => b.date.compareTo(a.date));

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'budget': budget,
        'destinationId': destinationId,
        'isSample': isSample,
        'stops': stops.map((s) => s.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
      };

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
        id: j['id'] as String,
        name: j['name'] as String,
        budget: (j['budget'] as num).toDouble(),
        destinationId: j['destinationId'] as String?,
        isSample: j['isSample'] as bool? ?? false,
        stops: (j['stops'] as List? ?? [])
            .map((s) => TripStop.fromJson(s as Map<String, dynamic>))
            .toList(),
        expenses: (j['expenses'] as List? ?? [])
            .map((e) => Expense.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ChecklistItem {
  ChecklistItem({required this.id, required this.label, this.checked = false});

  final String id;
  final String label;
  bool checked;

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'checked': checked};

  factory ChecklistItem.fromJson(Map<String, dynamic> j) => ChecklistItem(
        id: j['id'] as String,
        label: j['label'] as String,
        checked: j['checked'] as bool? ?? false,
      );
}
