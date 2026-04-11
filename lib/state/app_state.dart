import 'package:flutter/material.dart';
import '../models/models.dart';

/// Global reactive state shared across screens.
class AppState {
  AppState._();

  static final ValueNotifier<List<ExpenseItem>> expenses =
      ValueNotifier(List.from(recentExpenses));

  static final ValueNotifier<double> totalBudget = ValueNotifier(2000.0);

  static final ValueNotifier<List<TripStop>> stops =
      ValueNotifier(List.from(tripStops));

  // ─── Computed ──────────────────────────────────────────────────────────────

  static double get totalSpent =>
      expenses.value.fold(0.0, (s, e) => s + e.amount);

  static double get remaining => totalBudget.value - totalSpent;

  static double get budgetPercent {
    final t = totalBudget.value;
    return t > 0 ? (totalSpent / t).clamp(0.0, 1.0) : 0.0;
  }

  // ─── Expense actions ───────────────────────────────────────────────────────

  static void addExpense(ExpenseItem item) {
    expenses.value = [...expenses.value, item];
  }

  static void removeExpense(String id) {
    expenses.value = expenses.value.where((e) => e.id != id).toList();
  }

  // ─── Trip stop actions ─────────────────────────────────────────────────────

  static void addStop(TripStop stop) {
    final list = List<TripStop>.from(stops.value);
    stop.number = list.length + 1;
    list.add(stop);
    stops.value = list;
  }

  static void toggleComplete(int index) {
    final list = List<TripStop>.from(stops.value);
    final s = list[index];
    s.isCompleted = !s.isCompleted;
    if (s.isCompleted) s.isInProgress = false;
    stops.value = list;
  }

  static void updateBudget(double budget) {
    totalBudget.value = budget;
  }
}
