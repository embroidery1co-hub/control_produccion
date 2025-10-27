import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../utils/pdf_generador.dart';

class PdfDemoPage extends StatelessWidget {
  final Map<String, dynamic>? pedidoData;

  const PdfDemoPage({super.key, this.pedidoData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vista PDF')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              // Usar datos reales si existen, si no usar datos de prueba
              final datos = pedidoData ?? _getDatosPrueba();

              final Uint8List pdfBytes = await PdfGenerador.generarPdfCliente(
                nombreCliente: datos['cliente'] ?? 'Sin nombre',
                documento: datos['documento'] ?? '',
                telefono: datos['telefono'] ?? '',
                correo: datos['correo'] ?? '',
                prendas: datos['prendas'] ?? [],
                total: datos['total'] ?? 0,
                observaciones: datos['observaciones'] ?? '',
                fecha: datos['fecha'] ?? DateTime.now().toString().split(' ')[0],
              );

              await Printing.layoutPdf(
                onLayout: (PdfPageFormat format) async => pdfBytes,
              );
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al generar PDF: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Generar PDF'),
        ),
      ),
    );
  }

  Map<String, dynamic> _getDatosPrueba() {
    return {
      'cliente': 'Juan Pérez',
      'documento': '123456789',
      'telefono': '3001234567',
      'correo': 'juan@example.com',
      'prendas': [
        {
          'nombre': 'Camiseta',
          'cantidad': 2,
          'detalles': 'Logo en pecho + espalda',
          'precio': 30000,
          'subtotal': 60000,
          'ubicacion': 'Frente y espalda'
        },
      ],
      'total': 85000,
      'observaciones': 'Entrega urgente',
      'fecha': '2025-10-22',
    };
  }
}
