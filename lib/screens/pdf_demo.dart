import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/pdf_generador.dart';

class PdfDemoPage extends StatefulWidget {
  final Map<String, dynamic>? pedidoData;
  final Map<String, dynamic>? reporteData;

  const PdfDemoPage({super.key, this.pedidoData, this.reporteData});

  @override
  State<PdfDemoPage> createState() => _PdfDemoPageState();
}

class _PdfDemoPageState extends State<PdfDemoPage> {
  bool _isLoading = true;
  String? _filePath;
  Uint8List? _pdfData;

  @override
  void initState() {
    super.initState();
    _generarPdf();
  }

  Future<void> _generarPdf() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Uint8List data;

      if (widget.pedidoData != null) {
        // Generar PDF de un pedido específico
        data = await generarPdfPedido(widget.pedidoData!);
      } else if (widget.reporteData != null) {
        // Generar PDF de reporte general
        data = await generarPdfReporteGeneral(widget.reporteData!);
      } else {
        // Generar PDF de ejemplo
        data = await generarPdfPedido({
          'id': '123456789',
          'cliente': 'Juan Pérez',
          'fecha': '2023-06-15',
          'prendas': [
            {
              'nombre': 'Camiseta Polo',
              'cantidad': 5,
              'detalles': 'Bordado en pecho',
              'precio': 25000,
              'subtotal': 125000,
              'ubicacion': 'Pecho',
            },
            {
              'nombre': 'Gorra',
              'cantidad': 10,
              'detalles': 'Estampado frontal',
              'precio': 15000,
              'subtotal': 150000,
              'ubicacion': 'Frente',
            },
          ],
          'total': 275000,
        });
      }

      // Guardar el PDF en el dispositivo
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/pedido_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(data);

      setState(() {
        _pdfData = data;
        _filePath = file.path;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e')),
        );
      }
    }
  }

  Future<void> _abrirPdf() async {
    if (_filePath != null) {
      await OpenFile.open(_filePath!);
    }
  }

  Future<void> _compartirPdf() async {
    if (_filePath != null) {
      await Share.shareFiles([_filePath!], text: 'Compartiendo PDF de pedido');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista previa de PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _isLoading ? null : _compartirPdf,
            tooltip: 'Compartir PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pdfData == null
          ? const Center(child: Text('No se pudo generar el PDF'))
          : Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Vista previa del PDF\n(En una app real, aquí se mostraría el PDF)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _abrirPdf,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir'),
                ),
                ElevatedButton.icon(
                  onPressed: _compartirPdf,
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}