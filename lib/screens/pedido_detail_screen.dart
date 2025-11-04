import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers/order_provider.dart';
import '../providers/tiempo_produccion_provider.dart';
import '../providers/producto_provider.dart';
import 'nuevo_pedido_screen.dart'; // Para poder navegar al formulario de edición

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
          // Botón para editar
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar Pedido',
            onPressed: () => _editarPedido(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Tarjeta de Información General ---
            _buildInfoCard(context),
            const SizedBox(height: 16),

            // --- Tarjeta de Tiempo de Producción (si aplica) ---
            if (order.status == OrderStatus.EnProduccion || order.status == OrderStatus.Pausado)
              _buildTiempoCard(context, tiempoProvider, tiempo),
            const SizedBox(height: 16),

            // --- Lista de Items del Pedido ---
            _buildItemsCard(),
            const SizedBox(height: 16),

            // --- Tarjeta de Total ---
            _buildTotalCard(),
            const SizedBox(height: 24),

            // --- Botones de Acción ---
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  // --- Widgets Helper para construir la UI ---

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Pedido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Cliente:', order.clienteId),
            _buildInfoRow('Fecha de Recepción:', order.fechaRecepcion.toString().split(' ')[0]),
            _buildInfoRow('Fecha de Entrega Estimada:', order.fechaEntregaEstim.toString().split(' ')[0]),
            _buildInfoRow(
              'Estado:',
              '',
              widget: Chip(
                label: Text(order.status.name),
                backgroundColor: _getEstadoColor(order.status),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiempoCard(BuildContext context, TiempoProduccionProvider tiempoProvider, TiempoProduccion? tiempo) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tiempo de Producción',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text(tiempoProvider.estaPausado(order.id) ? 'REANUDAR' : 'INICIAR'),
                  ),
                if (tiempoProvider.estaActivo(order.id))
                  ElevatedButton(
                    onPressed: () => tiempoProvider.pausarTemporizador(order.id),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('PAUSAR'),
                  ),
                ElevatedButton(
                  onPressed: () => tiempoProvider.terminarTemporizador(order.id),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('TERMINAR'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items del Pedido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              itemBuilder: (context, index) {
                final item = order.items[index];
                return ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                  title: Text('${item.tipo.nombre} - ${item.tamano.nombre}'),
                  subtitle: Text('${item.ubicacion} x${item.cantidad}'),
                  trailing: Text(
                    '\$${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard() {
    return Card(
      color: Colors.green.shade50,
      child: ListTile(
        title: const Text(
          'Total del Pedido',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: Text(
          '\$${order.total.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
      ),
    );
  }

  // En lib/screens/pedido_detail_screen.dart

  Widget _buildActionButtons(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    return Column(
      children: [
        // Botón para cambiar de estado (solo se muestra si no está archivado/entregado)
        if (order.status != OrderStatus.Archivado && order.status != OrderStatus.Entregado)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _cambiarEstado(context, orderProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_getSiguientePasoTexto(order.status)),
            ),
          ),
        if (order.status != OrderStatus.Archivado && order.status != OrderStatus.Entregado)
          const SizedBox(height: 8),
        // Botón para eliminar (solo se muestra si no está archivado/entregado)
        if (order.status != OrderStatus.Archivado && order.status != OrderStatus.Entregado)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _confirmarArchivo(context, orderProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('ARCHIVAR PEDIDO'),
            ),
          ),
      ],
    );
  }

  // --- Métodos de Lógica ---

  void _editarPedido(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NuevoPedidoScreen(orderParaEditar: order), // Ahora sí funciona
      ),
    );
    // Ya no necesitamos llamar a _cargarPedidos, notifyListeners se encarga de todo.
  }

  // En lib/screens/pedido_detail_screen.dart
  void _cambiarEstado(BuildContext context, OrderProvider orderProvider) {
    OrderStatus nuevoEstado;
    switch (order.status) {
      case OrderStatus.EnEspera:
        nuevoEstado = OrderStatus.EnProduccion;
        break;
      case OrderStatus.EnProduccion:
        nuevoEstado = OrderStatus.Terminado;
        break;
      case OrderStatus.Pausado:
        nuevoEstado = OrderStatus.EnProduccion;
        break;
      case OrderStatus.Terminado:
        nuevoEstado = OrderStatus.Entregado;
        break;
      case OrderStatus.Entregado:
        nuevoEstado = OrderStatus.Archivado; // <-- CAMBIO AQUÍ
        break;
      case OrderStatus.Archivado: // <-- AÑADE ESTE CASE
        return; // Un pedido archivado no puede cambiar de estado
    }

    orderProvider.updateOrderStatus(order.id, nuevoEstado);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pedido movido a: ${nuevoEstado.name}')),
    );
  }

  // En lib/screens/pedido_detail_screen.dart

// Reemplaza el metodo _confirmarEliminacion por este
  void _confirmarArchivo(BuildContext context, OrderProvider orderProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Archivado'),
          content: Text('¿Estás seguro de que quieres archivar el pedido #${order.id.substring(0, 6)}? Ya no aparecerá en la lista principal, pero podrás consultarlo en el historial.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Archivar', style: TextStyle(color: Colors.orange)),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cierra el diálogo
                // Cambiamos el estado a 'Archivado' en lugar de borrar
                orderProvider.updateOrderStatus(order.id, OrderStatus.Archivado);
                Navigator.of(context).pop(); // Vuelve a la lista de pedidos
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pedido archivado correctamente.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // --- Métodos Helper ---

  Widget _buildInfoRow(String label, String value, {Widget? widget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: widget ?? Text(value)),
        ],
      ),
    );
  }

  // En lib/screens/pedido_detail_screen.dart
  Color _getEstadoColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.EnEspera: return Colors.grey.shade400;
      case OrderStatus.EnProduccion: return Colors.blue.shade300;
      case OrderStatus.Pausado: return Colors.orange.shade300;
      case OrderStatus.Terminado: return Colors.green.shade300;
      case OrderStatus.Entregado: return Colors.purple.shade300;
      case OrderStatus.Archivado: return Colors.brown.shade300; // Color para archivado
    }
  }

  // En lib/screens/pedido_detail_screen.dart
  String _getSiguientePasoTexto(OrderStatus status) {
    switch (status) {
      case OrderStatus.EnEspera: return 'INICIAR PRODUCCIÓN';
      case OrderStatus.EnProduccion: return 'MARCAR COMO TERMINADO';
      case OrderStatus.Pausado: return 'REANUDAR PRODUCCIÓN';
      case OrderStatus.Terminado: return 'MARCAR COMO ENTREGADO';
      case OrderStatus.Entregado: return 'ARCHIVAR PEDIDO'; // <-- NUEVO TEXTO
      case OrderStatus.Archivado: return 'YA ARCHIVADO'; // No debería aparecer
    }
  }
}