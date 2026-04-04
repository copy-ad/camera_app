import 'package:intl/intl.dart';

String formatRemaining(DateTime? expiresAt, {required bool isKeptForever}) {
  if (isKeptForever) {
    return 'Forever';
  }
  if (expiresAt == null) {
    return 'Expired';
  }
  final now = DateTime.now();
  final difference = expiresAt.difference(now);
  if (difference.isNegative) {
    return 'Expired';
  }
  final days = difference.inDays;
  final hours = difference.inHours.remainder(24);
  final minutes = difference.inMinutes.remainder(60);
  if (days > 0) {
    return '${days}d ${hours}h';
  }
  if (difference.inHours > 0) {
    return '${difference.inHours}h ${minutes}m';
  }
  return '${difference.inMinutes}m';
}

String formatTimestamp(DateTime value) {
  return DateFormat('MMM d, yyyy • h:mm a').format(value);
}
