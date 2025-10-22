import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;

class PdfGenerador {
  static Future<Uint8List> generarPdfCliente({
    required String nombreCliente,
    required String documento,
    required String telefono,
    required String correo,
    required String fecha,
    required List<Map<String, dynamic>> prendas,
    required double total,
    String? observaciones,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('📌 Empresa PersonalizaMe', style: pw.TextStyle(fontSize: 20)),
              pw.Text('Fecha: $fecha'),
              pw.SizedBox(height: 10),
              pw.Text('Cliente: $nombreCliente'),
              pw.Text('Documento: $documento'),
              pw.Text('Teléfono: $telefono'),
              pw.Text('Correo: $correo'),
              pw.SizedBox(height: 10),
              pw.Text('Prendas:', style: pw.TextStyle(fontSize: 18)),
              pw.Table.fromTextArray(
                headers: ['Nombre', 'Cantidad', 'Detalles', 'Precio', 'Subtotal'],
                data: prendas.map((p) => [
                  p['nombre'],
                  p['cantidad'].toString(),
                  p['detalles'],
                  p['precio'].toString(),
                  p['subtotal'].toString(),
                ]).toList(),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Total: \$${total.toStringAsFixed(0)}',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              if (observaciones != null && observaciones.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 10),
                  child: pw.Text('Observaciones: $observaciones'),
                ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
