import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../utils/pdf_generador.dart';

class PdfDemoPage extends StatelessWidget {
  const PdfDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prueba de PDF')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final prendas = [
              {
                'nombre': 'Camiseta',
                'cantidad': 2,
                'detalles': 'Logo en pecho + espalda',
                'precio': 30000,
                'subtotal': 60000,
              },
              {
                'nombre': 'Gorra',
                'cantidad': 1,
                'detalles': 'Logo frontal',
                'precio': 25000,
                'subtotal': 25000,
              },
            ];

            final pdf = await PdfGenerador.generarPdfCliente(
              nombreCliente: 'Juan Pérez',
              documento: '123456789',
              telefono: '3001234567',
              correo: 'juan@example.com',
              fecha: '2025-10-16',
              prendas: prendas,
              total: 85000,
              observaciones: 'Entrega urgente',
            );

            await Printing.layoutPdf(onLayout: (format) async => pdf);
          },
          child: const Text('Generar PDF Cliente'),
        ),
      ),
    );
  }
}
