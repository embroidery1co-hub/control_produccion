import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart'; // ✅ Para getTemporaryDirectory
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart'; // ✅ Para OpenFile.open()

class PdfGenerador {
  /// 🧾 Genera el PDF del cliente (tipo factura)
  static Future<Uint8List> generarPdfCliente({
    required String nombreCliente,
    required String documento,
    required String telefono,
    required String correo,
    required String fecha,
    required List<Map<String, dynamic>> prendas,
    required double total,
    required String observaciones,
  }) async {
    final pdf = pw.Document();

    // Logo
    final logo = pw.MemoryImage(
      (await rootBundle.load('assets/logo.png')).buffer.asUint8List(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Center(child: pw.Image(logo, height: 80)),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              'PERSONALIZAME',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Center(child: pw.Text('Comprobante de Pedido', style: pw.TextStyle(fontSize: 14))),
          pw.Divider(),
          pw.SizedBox(height: 10),

          pw.Text('📅 Fecha: $fecha'),
          pw.Text('👤 Cliente: $nombreCliente'),
          pw.Text('🧾 Documento: $documento'),
          pw.Text('📞 Teléfono: $telefono'),
          pw.Text('✉️ Correo: $correo'),
          pw.SizedBox(height: 20),

          pw.Table.fromTextArray(
            headers: ['Prenda', 'Cantidad', 'Detalles', 'Precio', 'Subtotal'],
            data: prendas.map((p) => [
              p['nombre'],
              p['cantidad'].toString(),
              p['detalles'] ?? '',
              '\$${p['precio']}',
              '\$${p['subtotal']}',
            ]).toList(),
          ),

          pw.SizedBox(height: 20),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total: \$${total.toStringAsFixed(0)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Observaciones:'),
          pw.Text(observaciones),
          pw.Divider(),
          pw.Center(child: pw.Text('Gracias por confiar en PersonalizaMe 💛')),
        ],
      ),
    );

    // Guardar en archivo temporal
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Pedido_Cliente.pdf");
    await file.writeAsBytes(await pdf.save());

    // Abrir el archivo
    await OpenFile.open(file.path);

    return await pdf.save();
  }

  /// 🏭 Genera el PDF para producción (orden interna)
  static Future<Uint8List> generarPdfProduccion({
    required String nombreCliente,
    required String fecha,
    required List<Map<String, dynamic>> prendas,
    required String observaciones,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Center(
            child: pw.Text(
              'ORDEN DE PRODUCCIÓN',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Divider(),
          pw.Text('Cliente: $nombreCliente'),
          pw.Text('Fecha: $fecha'),
          pw.SizedBox(height: 20),

          pw.Table.fromTextArray(
            headers: ['Prenda', 'Cantidad', 'Detalles', 'Estado'],
            data: prendas.map((p) => [
              p['nombre'],
              p['cantidad'].toString(),
              p['detalles'] ?? '',
              'Pendiente',
            ]).toList(),
          ),

          pw.SizedBox(height: 20),
          pw.Text('Notas de producción:'),
          pw.Text(observaciones),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Orden_Produccion.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);

    return await pdf.save();
  }
}
