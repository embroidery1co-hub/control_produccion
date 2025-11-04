import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers/order_provider.dart';
import 'pedido_detail_screen.dart';

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pedidos'),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          // FILTRAR para mostrar SOLO los pedidos archivados o entregados
          final pedidosHistorial = orderProvider.orders.where((order) =>
          order.status == OrderStatus.Archivado || order.status == OrderStatus.Entregado
          ).toList();

          if (pedidosHistorial.isEmpty) {
            return const Center(
              child: Text(
                'No hay pedidos en el historial.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          // Ordenar del más reciente al más antiguo
          pedidosHistorial.sort((a, b) => b.fechaRecepcion.compareTo(a.fechaRecepcion));

          return ListView.builder(
            itemCount: pedidosHistorial.length,
            itemBuilder: (context, index) {
              final pedido = pedidosHistorial[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  onTap: () {
                    // Permitir ver los detalles de un pedido archivado
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PedidoDetailScreen(order: pedido),
                      ),
                    );
                  },
                  title: Text('Pedido #${pedido.id.substring(0, 6)}'),
                  subtitle: Text('Cliente: ${pedido.clienteId}'),
                  trailing: Text(
                    '\$${pedido.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}