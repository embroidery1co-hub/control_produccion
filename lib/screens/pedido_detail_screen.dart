import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers/order_provider.dart';
import '../providers/tiempo_produccion_provider.dart';

class PedidoDetailScreen extends StatelessWidget {
  final Order order;

  const PedidoDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final tiempoProvider = Provider.of<TiempoProduccionProvider>(context);
    final tiempo = tiempoProvider.getTiempoPorOrderId(order.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${order.id.substring(0, 6)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar Pedido',
            onPressed: () {
              // Navegar a la pantalla de edición
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidad de edición próximamente')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información general del pedido
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cliente: ${order.clienteId}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Chip(
                          label: Text(order.status.name),
                          backgroundColor: _getEstadoColor(order.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fecha de Recepción: ${order.fechaRecepcion.toString().split(' ')[0]}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fecha de Entrega Estimada: ${order.fechaEntregaEstim.toString().split(' ')[0]}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tiempo de producción (si está en producción)
            if (order.status == OrderStatus.EnProduccion || order.status == OrderStatus.Pausado)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tiempo de Producción',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tiempo Transcurrido:'),
                          Text(
                            tiempo?.tiempoTranscurridoFormateado ?? '00:00:00',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (tiempoProvider.estaPausado(order.id) || !tiempoProvider.estaActivo(order.id))
                            ElevatedButton(
                              onPressed: () => tiempoProvider.reanudarTemporizador(order.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Reanudar'),
                            ),
                          if (tiempoProvider.estaActivo(order.id))
                            ElevatedButton(
                              onPressed: () => tiempoProvider.pausarTemporizador(order.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Pausar'),
                            ),
                          ElevatedButton(
                            onPressed: () => tiempoProvider.terminarTemporizador(order.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Terminar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Lista de items
            const Text(
              'Items del Pedido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Card(
                  child: ListTile(
                    title: Text('${item.tipo.name} - ${item.tamano.name}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ubicación: ${item.ubicacion}'),
                        Text('Cantidad: ${item.cantidad}'),
                        Text('Tiempo estimado: ${item.tiempoEstimadoMin} min'),
                      ],
                    ),
                    trailing: Text('\$${item.subtotal.toStringAsFixed(2)}'),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Total del pedido
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total del Pedido',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (order.status == OrderStatus.EnEspera)
                  ElevatedButton(
                    onPressed: () {
                      Provider.of<OrderProvider>(context, listen: false)
                          .updateOrderStatus(order.id, OrderStatus.EnProduccion);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Iniciar Producción'),
                  ),
                if (order.status == OrderStatus.EnProduccion)
                  ElevatedButton(
                    onPressed: () {
                      Provider.of<OrderProvider>(context, listen: false)
                          .updateOrderStatus(order.id, OrderStatus.Terminado);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Marcar como Terminado'),
                  ),
                if (order.status == OrderStatus.Terminado)
                  ElevatedButton(
                    onPressed: () {
                      Provider.of<OrderProvider>(context, listen: false)
                          .updateOrderStatus(order.id, OrderStatus.Entregado);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Marcar como Entregado'),
                  ),
              ],
            ),
          ],
        ),
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