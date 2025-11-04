import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers/order_provider.dart';
import 'nuevo_pedido_screen.dart';
import 'pedido_detail_screen.dart';
import 'historial_screen.dart'; // <-- Asegúrate de tener esta importación

class PedidosScreen extends StatelessWidget {
  const PedidosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // <-- 1. Envuelve todo en un Scaffold
      appBar: AppBar( // <-- 2. Añade el AppBar aquí
        title: const Text('Pedidos Activos'),
        centerTitle: true,
        actions: [
          // Botón para ir al historial
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Ver Historial de Pedidos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistorialScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          final orders = orderProvider.orders.where((order) => order.status != OrderStatus.Archivado).toList();

          if (orders.isEmpty) {
            return const Center(child: Text('No hay pedidos activos.')); // Mensaje un poco más claro
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PedidoDetailScreen(order: order),
                      ),
                    );
                  },
                  title: Text('Pedido #${order.id.substring(0, 6)} - ${order.clienteId}'),
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
                    tooltip: 'Ver detalles',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PedidoDetailScreen(order: order),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton( // <-- 3. Añade el FAB aquí
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

  // Asegúrate de que esta función esté aquí y corregida
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
      case OrderStatus.Archivado: // <-- AÑADIDO
        return Colors.brown.shade300;
    }
  }

  String _getSiguientePasoTexto(OrderStatus status) {
    switch (status) {
      case OrderStatus.EnEspera:
        return 'INICIAR PRODUCCIÓN';
      case OrderStatus.EnProduccion:
        return 'MARCAR COMO TERMINADO';
      case OrderStatus.Pausado:
        return 'REANUDAR PRODUCCIÓN';
      case OrderStatus.Terminado:
        return 'MARCAR COMO ENTREGADO';
      case OrderStatus.Entregado:
        return 'ARCHIVAR PEDIDO';
      case OrderStatus.Archivado: // <-- AÑADE ESTE CASE
        return 'YA ARCHIVADO'; // O cualquier texto que indique que no se puede hacer nada
    }
  }
}