import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../providers/tiempo_produccion_provider.dart';
import '../models.dart';
import 'temporizador_screen.dart';

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
            _buildTabContent(context, OrderStatus.EnProduccion),
            _buildTabContent(context, OrderStatus.EnEspera),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, OrderStatus status) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final tiempoProvider = Provider.of<TiempoProduccionProvider>(context);
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

                    // AGREGAR ESTA SECCIÓN PARA EL TIEMPO DE PRODUCCIÓN
                    if (status == OrderStatus.EnProduccion)
                      _buildTiempoProduccion(context, tiempoProvider, pedido),

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

  Widget _buildTiempoProduccion(BuildContext context, TiempoProduccionProvider tiempoProvider, Order pedido) {
    final tiempo = tiempoProvider.getTiempoPorOrderId(pedido.id);

    if (tiempo == null) {
      // Si no hay temporizador, mostrar botón para iniciar
      return ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TemporizadorScreen(order: pedido),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        child: const Text('INICIAR TEMPORIZADOR'),
      );
    } else {
      // Si hay temporizador, mostrar el tiempo y botones de control
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tiempo de producción:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  tiempoProvider.getTiempoFormateado(pedido.id),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón de Iniciar/Reanudar
                ElevatedButton(
                  onPressed: tiempoProvider.estaPausado(pedido.id) || !tiempoProvider.estaActivo(pedido.id)
                      ? () => tiempoProvider.reanudarTemporizador(pedido.id)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 30),
                  ),
                  child: Text(tiempoProvider.estaPausado(pedido.id) ? 'REANUDAR' : 'INICIAR'),
                ),

                // Botón de Pausar
                ElevatedButton(
                  onPressed: tiempoProvider.estaActivo(pedido.id)
                      ? () => tiempoProvider.pausarTemporizador(pedido.id)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 30),
                  ),
                  child: const Text('PAUSAR'),
                ),

                // Botón de Terminar
                ElevatedButton(
                  onPressed: tiempoProvider.estaActivo(pedido.id) || tiempoProvider.estaPausado(pedido.id)
                      ? () => tiempoProvider.terminarTemporizador(pedido.id)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 30),
                  ),
                  child: const Text('TERMINAR'),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
}