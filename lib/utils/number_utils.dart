import 'package:intl/intl.dart';
import 'dart:math' as math;

class NumberUtils {
  /// Format number as currency
  static String formatCurrency(
    num amount, {
    String currencySymbol = '\$',
    int decimalPlaces = 2,
  }) {
    final formatter = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: decimalPlaces,
    );
    return formatter.format(amount);
  }

  /// Format number with thousands separator
  static String formatNumber(num number, {int decimalPlaces = 0}) {
    final formatter = NumberFormat('#,##0' +
        (decimalPlaces > 0 ? '.' + '0' * decimalPlaces : ''));
    return formatter.format(number);
  }

  /// Format number as percentage
  static String formatPercentage(num number, {int decimalPlaces = 2}) {
    return '${number.toStringAsFixed(decimalPlaces)}%';
  }

  /// Check if string is a valid number
  static bool isNumeric(String str) {
    return double.tryParse(str) != null;
  }

  /// Check if string is a valid integer
  static bool isInteger(String str) {
    return int.tryParse(str) != null;
  }

  /// Clamp number between min and max
  static num clamp(num value, num min, num max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// Round to nearest value
  static double roundToNearest(double value, double nearest) {
    return (value / nearest).round() * nearest;
  }

  /// Calculate percentage
  static double calculatePercentage(num value, num total) {
    if (total == 0) return 0;
    return (value / total) * 100;
  }

  /// Format bytes to human readable format
  static String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return ((bytes / math.pow(1024, i)).toStringAsFixed(decimals)) +
        ' ' +
        suffixes[i];
  }
}
