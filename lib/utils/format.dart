const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Formats an amount as Pakistani rupees, e.g. `Rs 12,500`.
String formatPkr(double amount) {
  final negative = amount < 0;
  final digits = amount.abs().round().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${negative ? '-' : ''}Rs $grouped';
}

/// Parses user-entered money. Returns null unless it is a positive number.
double? parseAmount(String input) {
  final value = double.tryParse(input.replaceAll(',', '').trim());
  if (value == null || value.isNaN || value.isInfinite || value <= 0) return null;
  return value;
}

String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String formatDistance(double km) =>
    km >= 1 ? '${km.toStringAsFixed(km >= 100 ? 0 : 1)} km' : '${(km * 1000).round()} m';

String formatDuration(int seconds) {
  if (seconds < 3600) return '${(seconds / 60).round()} min';
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  return minutes == 0 ? '$hours h' : '$hours h $minutes min';
}
