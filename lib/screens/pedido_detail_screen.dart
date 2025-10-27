import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers/order_provider.dart';
import '../utils/pdf_generador.dart';

class PedidoDetailScreen extends StatelessWidget {
  final Order order;

  const PedidoDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle Pedido ${order.id}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${order.clienteId}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            // CORREGIDO: Cambiar 'estado' por 'status'
            Text('Estado: ${order.status.name}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Fecha recepción: ${order.fechaRecepcion}', style: const TextStyle(fontSize: 14)),
            Text('Fecha entrega estimada: ${order.fechaEntregaEstim}', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            const Text('Items:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

            Expanded(
              child: ListView.builder(
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text('${item.tipo.name} - ${item.tamano.name}'),
                      subtitle: Text(
                        'Ubicación: ${item.ubicacion}\n'
                            'Cantidad: ${item.cantidad}\n'
                            'Precio unitario: \$${item.precio}\n'
                        // CORREGIDO: Usar getters que ya existen
                            'Subtotal: \$${item.subtotal}\n'
                            'Tiempo total: ${item.totalTiempo} min',
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // CORREGIDO: Usar OrderStatus en lugar de OrderEstado
                      final currentIndex = OrderStatus.values.indexOf(order.status);
                      if (currentIndex < OrderStatus.values.length - 1) {
                        // CORREGIDO: Crear nuevo pedido con estado actualizado
                        final updatedOrder = Order(
                          id: order.id,
                          clienteId: order.clienteId,
                          fechaRecepcion: order.fechaRecepcion,
                          fechaEntregaEstim: order.fechaEntregaEstim,
                          items: order.items,
                          status: OrderStatus.values[currentIndex + 1],
                        );
                        // CORREGIDO: Usar método updateOrder que ya existe
                        Provider.of<OrderProvider>(context, listen: false).updateOrder(updatedOrder);
                      }
                    },
                    child: const Text('Avanzar estado'),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('🧾 Generar PDF Cliente'),
                    onPressed: () async {
                      await PdfGenerador.generarPdfCliente(
                        nombreCliente: order.clienteId,
                        documento: 'N/A',
                        telefono: 'N/A',
                        correo: '',
                        prendas: order.items.map((item) => {
                          'nombre': item.tipo.name,
                          'cantidad': item.cantidad,
                          'ubicacion': item.ubicacion,
                          'precio': item.precio,
                          // CORREGIDO: Usar getter que ya existe
                          'subtotal': item.subtotal,
                          'detalles': '${item.tipo.name} - ${item.tamano.name}',
                        }).toList(),
                        // CORREGIDO: Usar getter que ya existe
                        total: order.total,
                        observaciones: '',
                        fecha: order.fechaEntregaEstim.toString(),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.factory),
                    label: const Text('🏭 Generar PDF Producción'),
                    onPressed: () async {
                      await PdfGenerador.generarPdfProduccion(
                        nombreCliente: order.clienteId,
                        fecha: order.fechaEntregaEstim.toString(),
                        prendas: order.items.map((item) => {
                          'nombre': item.tipo.name,
                          'cantidad': item.cantidad,
                          'ubicacion': item.ubicacion,
                          'detalles': '${item.tipo.name} - ${item.tamano.name}',
                        }).toList(),
                        observaciones: '',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
