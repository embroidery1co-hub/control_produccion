import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers/order_provider.dart';

class NuevoPedidoScreen extends StatefulWidget {
  const NuevoPedidoScreen({super.key});

  @override
  State<NuevoPedidoScreen> createState() => _NuevoPedidoScreenState();
}
class _NuevoPedidoScreenState extends State<NuevoPedidoScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _clienteSeleccionado;
  final TextEditingController _nuevoClienteCtrl = TextEditingController();

  final List<OrderItem> _items = [];

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final clientesExistentes = orderProvider.clientes; // <- deberás agregarlos en el provider

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Pedido'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // --- CLIENTE ---
              const Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _clienteSeleccionado,
                hint: const Text('Selecciona un cliente'),
                items: clientesExistentes
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => _clienteSeleccionado = value),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nuevoClienteCtrl,
                decoration: const InputDecoration(
                  labelText: 'O crear nuevo cliente',
                  prefixIcon: Icon(Icons.person_add),
                ),
              ),
              const Divider(height: 32),

              // --- ITEMS ---
              const Text('Productos del Pedido', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._items.map((item) => ListTile(
                title: Text('${item.tipo.name} - ${item.tamano.name}'),
                subtitle: Text('Cant: ${item.cantidad}  Precio: \$${item.precio}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _items.remove(item)),
                ),
              )),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _agregarItem,
                icon: const Icon(Icons.add),
                label: const Text('Agregar producto'),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // CORREGIDO: Verificar si _clienteSeleccionado es nulo antes de usar isEmpty
                    final clienteFinal = (_clienteSeleccionado != null && _clienteSeleccionado!.isNotEmpty)
                        ? _clienteSeleccionado!
                        : _nuevoClienteCtrl.text.trim();

                    // CORREGIDO: Verificar que clienteFinal no esté vacío
                    if (clienteFinal.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Debe ingresar un cliente')),
                      );
                      return;
                    }

                    final nuevoPedido = Order(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      clienteId: clienteFinal, // Ahora es un String no nulo
                      fechaRecepcion: DateTime.now(),
                      fechaEntregaEstim: DateTime.now().add(const Duration(days: 3)),
                      items: _items,
                    );

                    orderProvider.addOrder(nuevoPedido);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Guardar Pedido'),
              ),
            ],
          ),
        ),
      ),
    );
  }



  // -----------------------------------
  // LÍNEA 110
  void _agregarItem() async {
    final nuevo = await showDialog<OrderItem>(
      context: context,
      builder: (context) => _DialogAgregarItem(),
    );
    if (nuevo != null) {
      setState(() => _items.add(nuevo));
    }
  }
}








// -----------------------------------
// LÍNEA 130
class _DialogAgregarItem extends StatefulWidget {
  @override
  State<_DialogAgregarItem> createState() => _DialogAgregarItemState();
}

class _DialogAgregarItemState extends State<_DialogAgregarItem> {
  ItemTipo _tipo = ItemTipo.Bordado;
  ItemTamano _tamano = ItemTamano.Mediano;
  final TextEditingController _ubicacionCtrl = TextEditingController();
  final TextEditingController _cantidadCtrl = TextEditingController();
  final TextEditingController _precioCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Producto'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButtonFormField<ItemTipo>(
              value: _tipo,
              items: ItemTipo.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (v) => setState(() => _tipo = v!),
            ),
            DropdownButtonFormField<ItemTamano>(
              value: _tamano,
              items: ItemTamano.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (v) => setState(() => _tamano = v!),
            ),
            TextField(controller: _ubicacionCtrl, decoration: const InputDecoration(labelText: 'Ubicación')),
            TextField(controller: _cantidadCtrl, decoration: const InputDecoration(labelText: 'Cantidad'), keyboardType: TextInputType.number),
            TextField(controller: _precioCtrl, decoration: const InputDecoration(labelText: 'Precio'), keyboardType: TextInputType.number),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              OrderItem(
                id: DateTime.now().toString(),
                tipo: _tipo,
                tamano: _tamano,
                ubicacion: _ubicacionCtrl.text,
                cantidad: int.tryParse(_cantidadCtrl.text) ?? 1,
                precio: double.tryParse(_precioCtrl.text) ?? 0.0,
                tiempoEstimadoMin: 10,
              ),
            );
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}