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
                      Text(
                          'Items: ${order.items.length}\nSubtotal: \$${order.totalPrecio.toStringAsFixed(2)}\nTiempo total: ${order.totalTiempoEstimado} min'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('Estado: '),
                          Chip(
                            label: Text(order.estado.name),
                            backgroundColor: _getEstadoColor(order.estado),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: 'Avanzar estado',
                    onPressed: () {
                      final currentIndex =
                          OrderEstado.values.indexOf(order.estado);
                      if (currentIndex < OrderEstado.values.length - 1) {
                        order.estado = OrderEstado.values[currentIndex + 1];
                        Provider.of<OrderProvider>(context, listen: false)
                            .updateOrder(order);
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

// Función para asignar color según estado
Color _getEstadoColor(OrderEstado estado) {
  switch (estado) {
    case OrderEstado.EnEspera:
      return Colors.grey.shade400;
    case OrderEstado.EnProduccion:
      return Colors.blue.shade300;
    case OrderEstado.Pausado:
      return Colors.orange.shade300;
    case OrderEstado.Terminado:
      return Colors.green.shade300;
    case OrderEstado.Entregado:
      return Colors.purple.shade300;
  }
}


