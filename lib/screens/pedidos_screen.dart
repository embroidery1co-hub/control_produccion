import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers/order_provider.dart';
import 'nuevo_pedido_screen.dart';

class PedidosScreen extends StatelessWidget {
  const PedidosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          final orders = orderProvider.orders;

          if (orders.isEmpty) {
            return const Center(child: Text('No hay pedidos'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('Pedido ${order.id} - Cliente ${order.clienteId}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Items: ${order.items.length}\nSubtotal: \$${order.totalPrecio.toStringAsFixed(2)}\nTiempo total: ${order.totalTiempoEstimado} min'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('Estado: '),
                          Chip(
                            label: Text(order.status.name),
                            backgroundColor: _getEstadoColor(order.status),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: 'Avanzar estado',
                    onPressed: () {
                      final currentIndex = OrderStatus.values.indexOf(order.status);
                      if (currentIndex < OrderStatus.values.length - 1) {
                        final updatedOrder = Order(
                          id: order.id,
                          clienteId: order.clienteId,
                          fechaRecepcion: order.fechaRecepcion,
                          fechaEntregaEstim: order.fechaEntregaEstim,
                          items: order.items,
                          status: OrderStatus.values[currentIndex + 1],
                        );
                        Provider.of<OrderProvider>(context, listen: false)
                            .updateOrder(updatedOrder);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NuevoPedidoScreen()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Crear Nuevo Pedido',
      ),
    );
  }

  Color _getEstadoColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.EnEspera:
        return Colors.grey.shade400;
      case OrderStatus.EnProduccion:
        return Colors.blue.shade300;
      case OrderStatus.Pausado:
        return Colors.orange.shade300;
      case OrderStatus.Terminado:
        return Colors.green.shade300;
      case OrderStatus.Entregado:
        return Colors.purple.shade300;
    }
  }
}