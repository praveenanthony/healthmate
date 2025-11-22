import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final double? goal;      // optional goal
  final double? progress;  // 0.0 to 1.0

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    this.goal,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final double safeProgress =
        (progress != null) ? progress!.clamp(0.0, 1.0) : 0.0;
    final int progressPercent = (safeProgress * 100).toInt();
    final bool goalCompleted = safeProgress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + value
          Row(
            children: [
              Icon(icon, color: Colors.white),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Label
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),

          // Goal progress bar
          if (goal != null && progress != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Percentage text above the bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Goal: ${goal!.toInt()}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '$progressPercent%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: safeProgress,
                        backgroundColor: Colors.white24,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 5, // increased height
                      ),
                    ),
                    if (goalCompleted)
                      const Positioned(
                        right: 0,
                        top: -6,
                        child: Icon(
                          Icons.emoji_events,
                          color: Colors.yellowAccent,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
