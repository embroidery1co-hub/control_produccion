import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers/order_provider.dart';

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
            Text('Estado: ${order.estado.name}', style: const TextStyle(fontSize: 16)),
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
                      title: Text('${item.tipo.name} - ${item.tamano?.name ?? 'N/A'}'),
                      subtitle: Text(
                          'Ubicación: ${item.ubicacion}\nCantidad: ${item.cantidad}\nPrecio unitario: \$${item.precio}\nSubtotal: \$${item.subtotal}\nTiempo total: ${item.totalTiempo} min'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  final currentIndex = OrderEstado.values.indexOf(order.estado);
                  if (currentIndex < OrderEstado.values.length - 1) {
                    order.estado = OrderEstado.values[currentIndex + 1];
                    Provider.of<OrderProvider>(context, listen: false)
                        .updateOrder(order);
                  }
                },
                child: const Text('Avanzar estado'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
