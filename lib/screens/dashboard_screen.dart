import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    // Contadores
    final totalPedidos = orderProvider.orders.length;
    final enProduccion = orderProvider.getOrdersByStatus(OrderStatus.EnProduccion).length;
    final terminados = orderProvider.getOrdersByStatus(OrderStatus.Terminado).length;
    final enEspera = orderProvider.getOrdersByStatus(OrderStatus.EnEspera).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard - PersonalizaMe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generar PDF',
            onPressed: () {
              // Aquí llamarías a tu función de PDF
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Función PDF en desarrollo')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Tarjetas de resumen
            Row(
              children: [
                _buildCard(context, 'Total Pedidos', totalPedidos.toString(), Colors.blue),
                _buildCard(context, 'En Producción', enProduccion.toString(), Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildCard(context, 'Terminados', terminados.toString(), Colors.green),
                _buildCard(context, 'En Espera', enEspera.toString(), Colors.red),
              ],
            ),
            const SizedBox(height: 24),

            // Últimos pedidos
            const Text(
              'Últimos Pedidos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: orderProvider.orders.length > 5 ? 5 : orderProvider.orders.length,
                itemBuilder: (context, index) {
                  final order = orderProvider.orders[index];
                  return Card(
                    child: ListTile(
                      title: Text('Pedido #${order.id.substring(0, 6)}'),
                      subtitle: Text('Cliente: ${order.clienteId}'),
                      trailing: Text('\$${order.total.toStringAsFixed(2)}'),
                      onTap: () {
                        // Aquí podrías navegar a detalles del pedido
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}