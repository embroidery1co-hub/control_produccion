import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers/order_provider.dart';

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
                      // CORREGIDO: Usar getters que ya existen
                      Text(
                          'Items: ${order.items.length}\nSubtotal: \$${order.total.toStringAsFixed(2)}\nTiempo total: ${order.totalTiempoEstimado} min'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('Estado: '),
                          Chip(
                            // CORREGIDO: Usar status en lugar de estado y OrderStatus en lugar de OrderEstado
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
        child: const Icon(Icons.add),
        onPressed: () {
          // Crear un pedido de prueba
          final newOrder = Order(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            clienteId: 'ClientePrueba',
            fechaRecepcion: DateTime.now(),
            fechaEntregaEstim: DateTime.now().add(const Duration(days: 3)),
            items: [
              OrderItem(
                id: 'item1',
                tipo: ItemTipo.Bordado,
                tamano: ItemTamano.Mediano,
                ubicacion: 'Frente',
                cantidad: 2,
                precio: 25.0,
                tiempoEstimadoMin: 15,
              ),
              OrderItem(
                id: 'item2',
                tipo: ItemTipo.Estampado,
                tamano: ItemTamano.Grande,
                ubicacion: 'Espalda',
                cantidad: 1,
                precio: 40.0,
                tiempoEstimadoMin: 20,
              ),
            ],
          );

          Provider.of<OrderProvider>(context, listen: false)
              .addOrder(newOrder);
        },
      ),
    );
  }
}

// CORREGIDO: Usar OrderStatus en lugar de OrderEstado
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