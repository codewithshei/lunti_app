/// Shared date formatting for order surfaces (the tracking timeline and the
/// PDF receipt). Kept dependency-free so both Flutter widgets and the pure-Dart
/// PDF builder can use the exact same format.
const List<String> _monthNames = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats [value] as e.g. `Nov 7, 2026 · 3:42 PM`.
String formatOrderDateTime(DateTime value) {
  final month = _monthNames[value.month - 1];
  final period = value.hour >= 12 ? 'PM' : 'AM';
  final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  return '$month ${value.day}, ${value.year} · $hour12:$minute $period';
}
