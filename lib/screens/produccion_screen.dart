import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models.dart';

class ProduccionScreen extends StatelessWidget {
  const ProduccionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Producción'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'En Producción'),
              Tab(text: 'En Espera'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // CORREGIDO: Construir directamente en el build principal
            _buildTabContent(context, OrderStatus.EnProduccion),
            _buildTabContent(context, OrderStatus.EnEspera),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, OrderStatus status) {
    // CORREGIDO: Obtener orderProvider aquí
    final orderProvider = Provider.of<OrderProvider>(context);
    final pedidos = orderProvider.getOrdersByStatus(status);

    if (pedidos.isEmpty) {
      return const Center(child: Text('No hay pedidos en esta categoría'));
    }

    return ListView.builder(
      itemCount: pedidos.length,
      itemBuilder: (context, index) {
        final pedido = pedidos[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            title: Text('Pedido #${pedido.id.substring(0, 6)}'),
            subtitle: Text('Cliente: ${pedido.clienteId}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Items: ${pedido.items.length}'),
                    Text('Total: \$${pedido.total.toStringAsFixed(2)}'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (status == OrderStatus.EnEspera)
                          ElevatedButton(
                            onPressed: () {
                              orderProvider.updateOrderStatus(pedido.id, OrderStatus.EnProduccion);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Pedido movido a producción')),
                              );
                            },
                            child: const Text('Iniciar Producción'),
                          ),
                        if (status == OrderStatus.EnProduccion)
                          ElevatedButton(
                            onPressed: () {
                              orderProvider.updateOrderStatus(pedido.id, OrderStatus.Terminado);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Pedido marcado como terminado')),
                              );
                            },
                            child: const Text('Marcar como Terminado'),
                          ),
                        ElevatedButton(
                          onPressed: () {
                            orderProvider.updateOrderStatus(pedido.id, OrderStatus.Pausado);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pedido pausado')),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          child: const Text('Pausar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}