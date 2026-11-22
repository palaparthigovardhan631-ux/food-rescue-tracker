import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/utils/countdown_formatter.dart';

class LiveCountdownBadge extends StatefulWidget {
  final DateTime bestBefore;

  const LiveCountdownBadge({super.key, required this.bestBefore});

  @override
  State<LiveCountdownBadge> createState() => _LiveCountdownBadgeState();
}

class _LiveCountdownBadgeState extends State<LiveCountdownBadge> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Re-render countdown every second for accurate countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urgency = CountdownFormatter.getUrgency(widget.bestBefore);
    final color = CountdownFormatter.getUrgencyColor(urgency);
    final text = CountdownFormatter.formatRemaining(widget.bestBefore);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            urgency == UrgencyLevel.critical
                ? Icons.alarm_on_rounded
                : Icons.schedule_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
