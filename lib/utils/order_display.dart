/// Shared order display helpers.
///
/// Order History and Order Details format timestamps the same way so the same
/// order never looks different between the list and the detail page.
library;

/// "Nov 1, 2026 · 2:05 PM" — compact and unambiguous for order lists.
String formatOrderDate(DateTime dt) {
  const months = [
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
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour < 12 ? 'AM' : 'PM';
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year} \u00B7 '
      '$hour:$minute $period';
}
