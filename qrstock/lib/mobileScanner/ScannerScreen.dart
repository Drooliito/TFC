import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late MobileScannerController controller;
  bool _isBarcodeCaptured = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    controller.barcodes.listen((barcodeCapture) {
      final barcodes = barcodeCapture.barcodes;
      for (final barcode in barcodes) {
        if (!_isBarcodeCaptured && barcode.rawValue != null) {
          _isBarcodeCaptured = true;
          Navigator.pop(context, barcode.rawValue!);
          break;
        }
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan code')),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (barcodeCapture) {
              final barcodes = barcodeCapture.barcodes;
              for (final barcode in barcodes) {
                if (!_isBarcodeCaptured && barcode.rawValue != null) {
                  _isBarcodeCaptured = true;
                  Navigator.pop(context, barcode.rawValue!);
                  break;
                }
              }
            },
            errorBuilder: (context, error, child) {
              return Center(
                child: Text(
                  'Error: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            },
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.yellow, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Scanning...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
