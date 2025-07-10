import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:event_scan/services/database.dart';
class DayHeader extends StatelessWidget {
  final int day;
  // Future<Map<String, dynamic>> settings;

  const DayHeader({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: Database.getSettings(),
      builder: (context, snapshot) {
        final settings = snapshot.data??{};
        final title = settings['eventTitle'] ?? 'Event Scan';
        return Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 40,
            bottom: 20,
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue[100]!.withOpacity(0.1),
                      Colors.blue[600]!.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: Text(
                        title,
                        key: ValueKey<String>(title),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getDayText(settings['startDate'], settings['endDate']).key,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: _getDayText(settings['startDate'], settings['endDate']).value),
                          duration: const Duration(seconds: 1),
                          builder: (context, value, child) {
                            return Text(
                              '$value',
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Pair<String, int> _getDayText(dynamic startDate, dynamic endDate) {
    try {
      final start = DateTime.fromMillisecondsSinceEpoch(startDate.millisecondsSinceEpoch);
      final end = DateTime.fromMillisecondsSinceEpoch(endDate.millisecondsSinceEpoch);
      final now = DateTime.now();

      if (start.isAfter(now)) {
        return Pair('Days to start: ', start.difference(now).inDays + 1);
      } else if (end.isBefore(now.subtract(Duration(days: 1)))) {
        return Pair('Days since ended: ', now.difference(end).inDays);
      } else {
        final currentDay = now.difference(start).inDays + 1;
        return Pair('Day: ', currentDay);
      }
    } catch (e) {
      return Pair('Day: ', day);
    }
  }
}

class Pair<K, V> {
  final K key;
  final V value;

  Pair(this.key, this.value);
}

class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.style,
  });

  final String text;
  final Gradient gradient;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}