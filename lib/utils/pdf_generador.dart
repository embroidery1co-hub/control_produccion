import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

// Función para generar un PDF de un pedido
Future<Uint8List> generarPdfPedido(Map<String, dynamic> pedidoData) async {
  final pdf = pw.Document();

  // Cargar una fuente personalizada (opcional)
  // final fontData = await rootBundle.load('assets/fonts/OpenSans-Regular.ttf');
  // final ttf = pw.Font.ttf(fontData);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(32), // <-- CONST ELIMINADO
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Encabezado
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PersonalizaMe',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo,
                      ),
                    ),
                    pw.SizedBox(height: 4), // <-- CONST ELIMINADO
                    pw.Text(
                      'Control de Producción',
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Fecha: ${pedidoData['fecha']}',
                      style: pw.TextStyle(fontSize: 12), // <-- CONST ELIMINADO
                    ),
                    pw.Text(
                      'Pedido: #${pedidoData['id']?.substring(0, 6) ?? ''}',
                      style: pw.TextStyle(fontSize: 12), // <-- CONST ELIMINADO
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 24), // <-- CONST ELIMINADO

            // Información del cliente
            pw.Container(
              padding: pw.EdgeInsets.all(12), // <-- CONST ELIMINADO
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)), // <-- CONST ELIMINADO
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Datos del Cliente',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8), // <-- CONST ELIMINADO
                  pw.Text('Nombre: ${pedidoData['cliente']}'),
                ],
              ),
            ),

            pw.SizedBox(height: 24), // <-- CONST ELIMINADO

            // Tabla de items
            pw.Text(
              'Detalle del Pedido',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8), // <-- CONST ELIMINADO

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: pw.FlexColumnWidth(3), // <-- CONST ELIMINADO
                1: pw.FlexColumnWidth(1), // <-- CONST ELIMINADO
                2: pw.FlexColumnWidth(2), // <-- CONST ELIMINADO
                3: pw.FlexColumnWidth(2), // <-- CONST ELIMINADO
              },
              children: [
                // Encabezado de la tabla
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey200), // <-- CONST ELIMINADO
                  children: [
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8), // <-- CONST ELIMINADO
                      child: pw.Text(
                        'Prenda',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8), // <-- CONST ELIMINADO
                      child: pw.Text(
                        'Cant.',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8), // <-- CONST ELIMINADO
                      child: pw.Text(
                        'Detalles',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8), // <-- CONST ELIMINADO
                      child: pw.Text(
                        'Precio',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),

                // Filas de datos
                ...List<pw.TableRow>.from(
                  (pedidoData['prendas'] as List).map((prenda) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8), // <-- CONST ELIMINADO
                          child: pw.Text(prenda['nombre']),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8), // <-- CONST ELIMINADO
                          child: pw.Text(
                            prenda['cantidad'].toString(),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8), // <-- CONST ELIMINADO
                          child: pw.Text(prenda['detalles']),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8), // <-- CONST ELIMINADO
                          child: pw.Text(
                            '\$${prenda['subtotal'].toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),

            pw.SizedBox(height: 24), // <-- CONST ELIMINADO

            // Total
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 200,
                padding: pw.EdgeInsets.all(12), // <-- CONST ELIMINADO
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)), // <-- CONST ELIMINADO
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total:'),
                        pw.Text(
                          '\$${pedidoData['total'].toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            pw.SizedBox(height: 40), // <-- CONST ELIMINADO

            // Notas
            pw.Text(
              'Notas:',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4), // <-- CONST ELIMINADO
            pw.Text(
              'Este es un documento generado automáticamente. Cualquier duda o aclaración, por favor contactar al departamento de producción.',
              style: pw.TextStyle(fontSize: 10), // <-- CONST ELIMINADO
            ),

            // Pie de página
            pw.Spacer(), // <-- CONST ELIMINADO
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Text(
                'PersonalizaMe - Todos los derechos reservados',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700), // <-- CONST ELIMINADO
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

// Función para generar un PDF de reporte general
Future<Uint8List> generarPdfReporteGeneral(Map<String, dynamic> reporteData) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(32), // <-- CONST ELIMINADO
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Encabezado
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PersonalizaMe',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo,
                      ),
                    ),
                    pw.SizedBox(height: 4), // <-- CONST ELIMINADO
                    pw.Text(
                      'Reporte de Producción',
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Fecha: ${DateTime.now().toString().split(' ')[0]}',
                      style: pw.TextStyle(fontSize: 12), // <-- CONST ELIMINADO
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 24), // <-- CONST ELIMINADO

            // Resumen
            pw.Container(
              padding: pw.EdgeInsets.all(12), // <-- CONST ELIMINADO
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)), // <-- CONST ELIMINADO
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Resumen de Pedidos',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8), // <-- CONST ELIMINADO
                  pw.Text('Total de Pedidos: ${reporteData['totalPedidos']}'),
                  pw.Text('Pedidos en Producción: ${reporteData['enProduccion']}'),
                  pw.Text('Pedidos Terminados: ${reporteData['terminados']}'),
                  pw.Text('Pedidos en Espera: ${reporteData['enEspera']}'),
                ],
              ),
            ),

            pw.SizedBox(height: 24), // <-- CONST ELIMINADO

            // Lista de pedidos
            pw.Text(
              'Lista de Pedidos',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8), // <-- CONST ELIMINADO

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: pw.FlexColumnWidth(1), // <-- CONST ELIMINADO
                1: pw.FlexColumnWidth(3), // <-- CONST ELIMINADO
                2: pw.FlexColumnWidth(2), // <-- CONST ELIMINADO
                3: pw.FlexColumnWidth(2), // <-- CONST ELIMINADO
              },
              children: [
                // Encabezado de la tabla
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey200), // <-- CONST ELIMINADO
                  children: [
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8), // <-- CONST ELIMINADO
                      child: pw.Text(
                        'ID',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8), // <-- CONST ELIMINADO
                      child: pw.Text(
                        'Cliente',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8), // <-- CONST ELIMINADO
                      child: pw.Text(
                        'Estado',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8), // <-- CONST ELIMINADO
                      child: pw.Text(
                        'Total',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),

                // Filas de datos
                ...List<pw.TableRow>.from(
                  (reporteData['pedidos'] as List).map((pedido) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8), // <-- CONST ELIMINADO
                          child: pw.Text('#${pedido['id'].substring(0, 6)}'),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8), // <-- CONST ELIMINADO
                          child: pw.Text(pedido['cliente']),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8), // <-- CONST ELIMINADO
                          child: pw.Text(pedido['estado']),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8), // <-- CONST ELIMINADO
                          child: pw.Text(
                            '\$${pedido['total'].toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),

            pw.SizedBox(height: 40), // <-- CONST ELIMINADO

            // Pie de página
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Text(
                'PersonalizaMe - Todos los derechos reservados',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700), // <-- CONST ELIMINADO
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}