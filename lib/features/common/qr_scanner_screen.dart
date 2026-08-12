import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/utils/responsive.dart';

/// A generic camera QR scanner — push it with `Navigator.push` and await
/// the result; it pops with the decoded string as soon as one barcode is
/// read, or null if the person backs out.
///
/// Used today from Faculty's attendance screen to read a student's Digital
/// ID payload (`PGPC-ID|...`), but works for any QR payload — the visitor
/// pass and payment-reference QR codes decode with the same widget.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key, this.title = 'Scan QR Code'});
  final String title;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final value = barcodes.first.rawValue;
    if (value == null) return;
    _handled = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final frameSize = Responsive.scanFrameSize(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Container(
            width: frameSize,
            height: frameSize,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          Positioned(
            bottom: Responsive.spacing(context, normal: 32, compact: 16),
            left: Responsive.pagePadding(context).left,
            right: Responsive.pagePadding(context).right,
            child: Text(
              'Align the QR code within the frame',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    shadows: const [Shadow(blurRadius: 8, color: Colors.black54)],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
