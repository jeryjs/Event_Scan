import 'package:flutter/material.dart';

import '../../constants/day_colors.dart';

class ResultDialog extends StatefulWidget {
  final Map<String, dynamic>? result;
  final String barcode;
  final VoidCallback onDismissed;

  const ResultDialog({
    super.key,
    required this.result,
    required this.barcode,
    required this.onDismissed,
  });

  @override
  State<ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<ResultDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: widget.result?['isScanned'] == null
          ? Colors.amber[800]
          : widget.result?['isScanned']
              ? Colors.red
              : Colors.green,
    ).animate(_controller);
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.result?['name'] ?? 'Unknown';
    final code = widget.result?['code'] ?? 'Unknown';
    final mail = widget.result?['mail'] ?? 'Unknown';
    final phone = widget.result?['phone'] ?? 'Unknown';
    final scanned = widget.result?['scanned'] ?? {};
    final isScanned = scanned[widget.barcode]?.isNotEmpty ?? false;

    final alertIcon = isScanned == null
        ? Icons.warning_amber
        : isScanned
            ? Icons.close
            : Icons.check;
    final alertTitle = isScanned == null
        ? "Unknown Barcode"
        : isScanned
            ? "Already Scanned!"
            : "Scan Successful!";

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        _controller.reverse();
        widget.onDismissed();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            return AlertDialog(
              backgroundColor: _colorAnimation.value,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(alertIcon, color: Colors.white, size: 40),
                      const SizedBox(width: 10),
                      Text(alertTitle, style: const TextStyle(color: Colors.white, fontSize: 26)),
                    ],
                  ),
                  Text("Code: $code"),
                  Text("Name: $name"),
                  Text("Mail: $mail"),
                  Text("Phone: $phone"),
                  const SizedBox(height: 8),
                  _buildScannedDays(scanned),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScannedDays(Map<String, dynamic> scanned) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: scanned.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entry.value.map<Widget>((day) {
            final dayColor = dayColors[day] ?? Colors.grey;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: dayColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.key} - Day $day',
                    style: TextStyle(
                      color: dayColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
