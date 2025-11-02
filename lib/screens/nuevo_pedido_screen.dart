import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers/order_provider.dart';
import '../providers/precio_provider.dart';

class NuevoPedidoScreen extends StatefulWidget {
  const NuevoPedidoScreen({super.key});

  @override
  State<NuevoPedidoScreen> createState() => _NuevoPedidoScreenState();
}

class _NuevoPedidoScreenState extends State<NuevoPedidoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clienteController = TextEditingController();
  final _fechaEntregaController = TextEditingController();

  // Variables para el item actual
  ItemTipo _tipoSeleccionado = ItemTipo.Bordado;
  ItemTamano _tamanoSeleccionado = ItemTamano.Mediano;
  final _ubicacionController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');

  List<OrderItem> _items = [];
  double _precioCalculado = 0.0;
  int _tiempoEstimado = 0;

  @override
  void dispose() {
    _clienteController.dispose();
    _fechaEntregaController.dispose();
    _ubicacionController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  void _calcularPrecioYTiempo() {
    final precioProvider = Provider.of<PrecioProvider>(context, listen: false);

    // Crear una variable de producto para buscar el precio
    final variable = VariableProducto(
      tipo: _tipoSeleccionado == ItemTipo.Bordado ? TipoBordado.Pecho : TipoBordado.Personalizado,
      calidad: CalidadBordado.Simple,
      cantidad: int.tryParse(_cantidadController.text) ?? 1,
      clienteProporcionaPrenda: false,
    );

    final precio = precioProvider.buscarPrecio(variable);
    if (precio != null) {
      setState(() {
        _precioCalculado = precio.calcularPrecioTotal(int.tryParse(_cantidadController.text) ?? 1);
      });
    }

    // Calcular tiempo estimado según el tipo y tamaño
    int tiempoBase = 0;
    switch (_tipoSeleccionado) {
      case ItemTipo.Bordado:
        tiempoBase = 15;
        break;
      case ItemTipo.Estampado:
        tiempoBase = 10;
        break;
      case ItemTipo.Serigrafia:
        tiempoBase = 20;
        break;
    }

    switch (_tamanoSeleccionado) {
      case ItemTamano.Pequenyo:
        tiempoBase = (tiempoBase * 0.8).round();
        break;
      case ItemTamano.Mediano:
      // Mantener el tiempo base
        break;
      case ItemTamano.Grande:
        tiempoBase = (tiempoBase * 1.5).round();
        break;
    }

    setState(() {
      _tiempoEstimado = tiempoBase;
    });
  }

  void _agregarItem() {
    if (_formKey.currentState!.validate()) {
      final cantidad = int.tryParse(_cantidadController.text) ?? 1;

      final nuevoItem = OrderItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tipo: _tipoSeleccionado,
        tamano: _tamanoSeleccionado,
        ubicacion: _ubicacionController.text,
        cantidad: cantidad,
        precio: _precioCalculado / cantidad, // Precio unitario
        tiempoEstimadoMin: _tiempoEstimado,
      );

      setState(() {
        _items.add(nuevoItem);
        // Limpiar formulario para el siguiente item
        _ubicacionController.clear();
        _cantidadController.text = '1';
        _precioCalculado = 0.0;
        _tiempoEstimado = 0;
      });
    }
  }

  void _guardarPedido() {
    if (_clienteController.text.isEmpty || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes ingresar un cliente y al menos un item')),
      );
      return;
    }

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    final nuevoPedido = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      clienteId: _clienteController.text,
      fechaRecepcion: DateTime.now(),
      fechaEntregaEstim: DateTime.parse(_fechaEntregaController.text),
      items: _items,
    );

    orderProvider.addOrder(nuevoPedido);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pedido creado exitosamente')),
    );
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _fechaEntregaController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Pedido'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Datos del cliente
              TextFormField(
                controller: _clienteController,
                decoration: const InputDecoration(
                  labelText: 'Cliente',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el nombre del cliente';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fecha de entrega estimada
              TextFormField(
                controller: _fechaEntregaController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de Entrega Estimada',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _seleccionarFecha,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor selecciona una fecha de entrega';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Detalles del item
              const Text(
                'Agregar Item',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Tipo de item
              DropdownButtonFormField<ItemTipo>(
                value: _tipoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: ItemTipo.values.map((ItemTipo tipo) {
                  return DropdownMenuItem<ItemTipo>(
                    value: tipo,
                    child: Text(tipo.name),
                  );
                }).toList(),
                onChanged: (ItemTipo? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _tipoSeleccionado = newValue;
                    });
                    _calcularPrecioYTiempo();
                  }
                },
              ),
              const SizedBox(height: 16),

              // Tamaño del item
              DropdownButtonFormField<ItemTamano>(
                value: _tamanoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tamaño',
                  border: OutlineInputBorder(),
                ),
                items: ItemTamano.values.map((ItemTamano tamano) {
                  return DropdownMenuItem<ItemTamano>(
                    value: tamano,
                    child: Text(tamano.name),
                  );
                }).toList(),
                onChanged: (ItemTamano? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _tamanoSeleccionado = newValue;
                    });
                    _calcularPrecioYTiempo();
                  }
                },
              ),
              const SizedBox(height: 16),

              // Ubicación
              TextFormField(
                controller: _ubicacionController,
                decoration: const InputDecoration(
                  labelText: 'Ubicación (ej: Pecho, Espalda)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa la ubicación';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Cantidad
              TextFormField(
                controller: _cantidadController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _calcularPrecioYTiempo();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa la cantidad';
                  }
                  final cantidad = int.tryParse(value);
                  if (cantidad == null || cantidad <= 0) {
                    return 'Por favor ingresa una cantidad válida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Precio y tiempo calculados
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Precio: \$${_precioCalculado.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Tiempo: $_tiempoEstimado min',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Botón para agregar item
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _agregarItem,
                  child: const Text('Agregar Item'),
                ),
              ),
              const SizedBox(height: 24),

              // Lista de items agregados
              const Text(
                'Items Agregados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              _items.isEmpty
                  ? const Center(child: Text('No hay items agregados'))
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    child: ListTile(
                      title: Text('${item.tipo.name} - ${item.tamano.name}'),
                      subtitle: Text('${item.ubicacion} x${item.cantidad}'),
                      trailing: Text('\$${item.subtotal.toStringAsFixed(2)}'),
                      onLongPress: () {
                        setState(() {
                          _items.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Total del pedido
              if (_items.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Total: \$${_items.fold(0.0, (sum, item) => sum + item.subtotal).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // Botón para guardar pedido
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardarPedido,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Guardar Pedido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}