import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:party_scan/services/sound_manager.dart';

import '../services/database.dart';
import 'result_dialog.dart';

class BarcodeScanner extends StatefulWidget {
  final String collectionName;
  const BarcodeScanner({super.key, required this.collectionName});

  @override
  State<BarcodeScanner> createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<BarcodeScanner> {
  final MobileScannerController controller = MobileScannerController(
    formats: [BarcodeFormat.code128],
  );

  void _onBarcodeScanned(String barcode) async {
    late bool isScanned;
    await Database.checkBarcode(barcode).then((value) {
      if (value == null) {
        isScanned = true;
        barcode = "Unknown Barcode";
      } else {
        isScanned = value;
      }
    });

    if (isScanned) {
      SoundManager.playFailureSound();
    } else {
      SoundManager.playSuccessSound();
    }

    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      barrierDismissible: true,
      builder: (context) => ResultDialog(
        isScanned: isScanned,
        barcode: barcode,
        onDismissed: () {
          controller.start();
        },
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
                  color: Colors.black.withOpacity(0.5),
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
        if (barcode != null && barcode.rawValue!.startsWith("9")) {
          _onBarcodeScanned(barcode.rawValue!);
          controller.stop();
        }
      },
    );
  }
}
