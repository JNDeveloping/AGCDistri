import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;
  bool _permissionGranted = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear código de barras')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _controller,
              errorBuilder: (context, error, child) {
                final text = error.toString().toLowerCase();
                if (text.contains('permission')) {
                  _permissionGranted = false;
                }
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No se pudo iniciar la cámara. Revisá permisos e intentá nuevamente.\n$error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
              onDetect: (capture) {
                if (_handled) return;
                if (capture.barcodes.isEmpty) return;
                final value = capture.barcodes.first.rawValue;
                if (value == null || value.trim().isEmpty) return;
                _handled = true;
                final code = value.trim();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Código detectado: $code')),
                );
                Navigator.pop(context, code);
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: Text(
              _permissionGranted
                  ? 'Apuntá la cámara al código de barras para escanear.'
                  : 'Permiso de cámara denegado. Habilitalo desde ajustes del sistema.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
