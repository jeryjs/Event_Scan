import 'package:flutter/material.dart';

class ResultDialog extends StatefulWidget {
  final bool isScanned;
  final String barcode;
  final VoidCallback onDismissed;

  const ResultDialog({
    super.key,
    required this.isScanned,
    required this.barcode,
    required this.onDismissed
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
      end: widget.barcode == "Unknown Barcode" ? Colors.amber[800] : widget.isScanned ? Colors.red : Colors.green,
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
    return WillPopScope(
      onWillPop: () async {
        widget.onDismissed();
        return true;
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
                      Icon(widget.isScanned ? Icons.close : Icons.check, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                          widget.isScanned
                              ? "Already Scanned!"
                              : "Scan Successful!",
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  Text(widget.barcode),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
