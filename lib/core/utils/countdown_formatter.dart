import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum UrgencyLevel { critical, warning, safe, expired }

class CountdownFormatter {
  /// Evaluates urgency based on time remaining until [bestBefore].
  static UrgencyLevel getUrgency(DateTime bestBefore) {
    final now = DateTime.now();
    final difference = bestBefore.difference(now);

    if (difference.isNegative || difference.inSeconds <= 0) {
      return UrgencyLevel.expired;
    } else if (difference.inMinutes <= 60) {
      return UrgencyLevel.critical; // < 1 hour
    } else if (difference.inHours <= 3) {
      return UrgencyLevel.warning;  // 1 to 3 hours
    } else {
      return UrgencyLevel.safe;     // > 3 hours
    }
  }

  /// Returns the corresponding color for the urgency status.
  static Color getUrgencyColor(UrgencyLevel urgency) {
    switch (urgency) {
      case UrgencyLevel.critical:
        return AppColors.urgencyCritical;
      case UrgencyLevel.warning:
        return AppColors.urgencyWarning;
      case UrgencyLevel.safe:
        return AppColors.urgencySafe;
      case UrgencyLevel.expired:
        return AppColors.urgencyExpired;
    }
  }

  /// Formats the remaining duration into human-readable text.
  static String formatRemaining(DateTime bestBefore) {
    final now = DateTime.now();
    final difference = bestBefore.difference(now);

    if (difference.isNegative || difference.inSeconds <= 0) {
      return "Expired";
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    final seconds = difference.inSeconds.remainder(60);

    if (hours > 24) {
      final days = difference.inDays;
      return "${days}d ${hours.remainder(24)}h left";
    } else if (hours > 0) {
      return "${hours}h ${minutes}m left";
    } else if (minutes > 0) {
      return "${minutes}m ${seconds}s left";
    } else {
      return "${seconds}s left";
    }
  }
}
