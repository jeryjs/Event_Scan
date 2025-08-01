import 'package:event_scan/models/category_model.dart';
import 'package:event_scan/services/sound_manager.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/database.dart';
import 'result_dialog.dart';

class BarcodeScanner extends StatefulWidget {
  final CategoryModel category;
  final List<CategoryModel> categories;

  const BarcodeScanner({super.key, required this.category, required this.categories});

  @override
  State<BarcodeScanner> createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<BarcodeScanner> {
  final MobileScannerController controller = MobileScannerController(
    formats: [BarcodeFormat.code128],
  );

  void _onBarcodeScanned(String barcode) async {
    var result = await Database.checkBarcode(barcode, widget.category.name);

    if (result == null || result.code.isEmpty || result.isScanned == true) {
      SoundManager.playFailureSound();
    } else {
      SoundManager.playSuccessSound();
    }

    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      barrierDismissible: true,
      builder: (context) => ResultDialog(
        result: result,
        barcode: barcode,
        onDismissed: () {
          controller.start();
        },
        categories: widget.categories,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: controller,
      scanWindow: Rect.fromLTWH(
        MediaQuery.of(context).size.width * 0.1,
        MediaQuery.of(context).size.height * 0.35,
        MediaQuery.of(context).size.width * 0.8,
        MediaQuery.of(context).size.height * 0.2,
      ),
      overlayBuilder: (context, constraints) {
        return Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: constraints.maxWidth * 0.8,
                height: constraints.maxHeight * 0.1,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'Align the barcode within the frame',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                width: constraints.maxWidth * 0.8,
                height: constraints.maxHeight * 0.2,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueGrey, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
      onDetect: (data) {
        final barcode = data.barcodes.firstOrNull;
        if (barcode != null) {
          _onBarcodeScanned(barcode.rawValue!);
          controller.stop();
        }
      },
    );
  }
}
