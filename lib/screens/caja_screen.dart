import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../providers/caja_provider.dart';
import '../providers/order_provider.dart';

class CajaScreen extends StatefulWidget {
  const CajaScreen({super.key});

  @override
  State<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends State<CajaScreen> {
  @override
  void initState() {
    super.initState();
    // Al iniciar la pantalla, cargar los datos de la caja del día
    final cajaProvider = Provider.of<CajaProvider>(context, listen: false);
    cajaProvider.cargarOCrearCajaDelDia();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CajaProvider>(
      builder: (context, cajaProvider, child) {
        final caja = cajaProvider.cajaHoy;
        final movimientos = cajaProvider.movimientosHoy;

        if (caja == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Caja del ${DateFormat('dd/MM/yyyy').format(caja.fecha)}'),
            centerTitle: true,
            actions: [
              if (!caja.estaCerrada)
                IconButton(
                  icon: const Icon(Icons.point_of_sale),
                  tooltip: 'Cobrar Pedido',
                  onPressed: () => _mostrarDialogoCobrarPedido(context, cajaProvider),
                ),
            ],
          ),
          // CÓDIGO CORREGIDO
          body: Consumer<CajaProvider>(
            builder: (context, cajaProvider, child) {
              // Mueve toda la lógica del cuerpo DENTRO del builder del Consumer
              final caja = cajaProvider.cajaHoy;
              final movimientos = cajaProvider.movimientosHoy;

              if (caja == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Sección de Resumen ---
                    _buildResumenCard(caja), // <-- CORRECTO, 'caja' está disponible
                    const SizedBox(height: 24),

                    // --- Sección de Apertura/Cierre de Caja ---
                    if (!caja.estaCerrada) ...[
                      _buildAperturaCajaCard(context, caja, cajaProvider), // <-- PASAMOS cajaProvider
                      const SizedBox(height: 24),
                    ] else ...[
                      _buildCajaCerradaCard(caja),
                      const SizedBox(height: 24),
                    ],

                    // --- Sección de Movimientos ---
                    _buildMovimientosCard(movimientos, cajaProvider), // <-- PASAMOS cajaProvider
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --- Widgets Helper ---

  Widget _buildResumenCard(CajaDiaria caja) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen de Caja', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildResumenRow('Saldo Inicial:', '\$${caja.saldoInicial.toStringAsFixed(2)}'),
            _buildResumenRow('Total Ventas:', '\$${caja.totalVentas.toStringAsFixed(2)}'),
            _buildResumenRow('Total Entradas:', '\$${caja.totalEntradas.toStringAsFixed(2)}'),
            _buildResumenRow('Total Salidas:', '\$${caja.totalSalidas.toStringAsFixed(2)}'),
            const Divider(thickness: 2),
            _buildResumenRow(
              'Saldo Final (Calculado):',
              '\$${caja.saldoCalculado.toStringAsFixed(2)}',
              isBold: true,
            ),
            if (caja.estaCerrada)
              _buildResumenRow(
                'Saldo Final (Registrado):',
                '\$${caja.saldoFinal.toStringAsFixed(2)}',
                isBold: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAperturaCajaCard(BuildContext context, CajaDiaria caja, CajaProvider cajaProvider) {
    // El resto del código dentro del método se queda igual
    if (caja.saldoInicial == 0) {
      return Card(
        color: Colors.orange.shade50,
        child: ListTile(
          leading: const Icon(Icons.lock_open, color: Colors.orange),
          title: const Text('Caja sin abrir', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Por favor, ingresa el saldo inicial para comenzar el día.'),
          trailing: ElevatedButton(
            onPressed: () => _mostrarDialogoAperturaCaja(context, cajaProvider), // <-- Usa el argumento cajaProvider
            child: const Text('Abrir Caja'),
          ),
        ),
      );
    }
    return Card(
      color: Colors.green.shade50,
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: const Text('Caja Abierta'),
        subtitle: Text('Saldo inicial: \$${caja.saldoInicial.toStringAsFixed(2)}'),
        trailing: ElevatedButton(
          onPressed: () => _mostrarDialogoCierreCaja(context, cajaProvider), // <-- Usa el argumento cajaProvider
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Cerrar Caja'),
        ),
      ),
    );
  }

  Widget _buildCajaCerradaCard(CajaDiaria caja) {
    return Card(
      color: Colors.grey.shade200,
      child: ListTile(
        leading: const Icon(Icons.lock, color: Colors.grey),
        title: const Text('Caja Cerrada'),
        subtitle: Text('Saldo final del día: \$${caja.saldoFinal.toStringAsFixed(2)}'),
      ),
    );
  }

  Widget _buildMovimientosCard(List<MovimientoCaja> movimientos, CajaProvider cajaProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Movimientos del Día', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (!cajaProvider.cajaHoy!.estaCerrada) // <-- Accede a cajaProvider
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                    onPressed: () => _mostrarDialogoMovimiento(context, cajaProvider), // <-- Usa el argumento cajaProvider
                    tooltip: 'Añadir Movimiento',
                  ),
              ],
            ),
            const Divider(),
            if (movimientos.isEmpty)
              const Center(child: Text('No hay movimientos registrados hoy.'))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: movimientos.length,
                itemBuilder: (context, index) {
                  final movimiento = movimientos[index];
                  Color color = Colors.black;
                  IconData icon = Icons.swap_horiz;
                  if (movimiento.tipo == TipoMovimiento.Entrada) {
                    color = Colors.green;
                    icon = Icons.arrow_downward;
                  } else if (movimiento.tipo == TipoMovimiento.Salida) {
                    color = Colors.red;
                    icon = Icons.arrow_upward;
                  } else if (movimiento.tipo == TipoMovimiento.Venta) {
                    color = Colors.blue;
                    icon = Icons.shopping_cart;
                  }
                  return ListTile(
                    leading: Icon(icon, color: color),
                    title: Text(movimiento.concepto),
                    subtitle: Text(DateFormat('HH:mm').format(movimiento.fechaHora)),
                    trailing: Text(
                      '\$${movimiento.monto.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) => const Divider(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  // --- Diálogos ---

  void _mostrarDialogoAperturaCaja(BuildContext context, CajaProvider cajaProvider) {
    final _saldoController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Apertura de Caja'),
          content: TextField(
            controller: _saldoController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Saldo Inicial',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                final saldo = double.tryParse(_saldoController.text) ?? 0.0;
                if (saldo > 0) {
                  cajaProvider.abrirCaja(saldo);
                  Navigator.pop(context);
                }
              },
              child: const Text('Abrir'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoCierreCaja(BuildContext context, CajaProvider cajaProvider) {
    final saldoCalculado = cajaProvider.cajaHoy!.saldoCalculado;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar Caja'),
          content: Text('¿Estás seguro de que quieres cerrar la caja?\n\nEl saldo final será: \$${saldoCalculado.toStringAsFixed(2)}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                cajaProvider.cerrarCaja();
                Navigator.pop(context);
              },
              child: const Text('Cerrar Caja'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoMovimiento(BuildContext context, CajaProvider cajaProvider) {
    final _conceptoController = TextEditingController();
    final _montoController = TextEditingController();
    TipoMovimiento _tipoSeleccionado = TipoMovimiento.Entrada;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Registrar Movimiento'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _conceptoController,
                    decoration: const InputDecoration(labelText: 'Concepto (ej: Pago de servicio)'),
                  ),
                  TextField(
                    controller: _montoController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Monto'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Entrada'),
                          selected: _tipoSeleccionado == TipoMovimiento.Entrada,
                          onSelected: (selected) => setState(() => _tipoSeleccionado = TipoMovimiento.Entrada),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Salida'),
                          selected: _tipoSeleccionado == TipoMovimiento.Salida,
                          onSelected: (selected) => setState(() => _tipoSeleccionado = TipoMovimiento.Salida),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                TextButton(
                  onPressed: () {
                    final concepto = _conceptoController.text;
                    final monto = double.tryParse(_montoController.text) ?? 0.0;
                    if (concepto.isNotEmpty && monto > 0) {
                      cajaProvider.registrarMovimiento(
                        concepto: concepto,
                        monto: monto,
                        tipo: _tipoSeleccionado,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Registrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoCobrarPedido(BuildContext context, CajaProvider cajaProvider) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    // Filtrar pedidos que no han sido pagados (lógica de ejemplo)
    final pedidosPendientes = orderProvider.orders.where((p) => p.status != OrderStatus.Entregado && p.status != OrderStatus.Archivado).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar Pedido a Cobrar'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: pedidosPendientes.length,
              itemBuilder: (context, index) {
                final pedido = pedidosPendientes[index];
                return ListTile(
                  title: Text('Pedido #${pedido.id.substring(0, 6)}'),
                  subtitle: Text('Cliente: ${pedido.clienteId} - Total: \$${pedido.total.toStringAsFixed(2)}'),
                  onTap: () {
                    Navigator.pop(context); // Cierra el diálogo de selección
                    cajaProvider.registrarPagoPedido(pedido); // Registra el pago
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Pago de pedido #${pedido.id.substring(0, 6)} registrado.')),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ],
        );
      },
    );
  }
}