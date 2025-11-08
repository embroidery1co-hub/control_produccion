import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers/order_provider.dart';
import '../providers/producto_provider.dart';


class NuevoPedidoScreen extends StatefulWidget {
  final Order? orderParaEditar; // <-- Hacerlo opcional (?)

  const NuevoPedidoScreen({super.key,this.orderParaEditar});

  @override
  State<NuevoPedidoScreen> createState() => _NuevoPedidoScreenState();
}

class _NuevoPedidoScreenState extends State<NuevoPedidoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fechaEntregaController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _abonoController = TextEditingController();

  // Variables para el formulario de items
  Producto? _productoSeleccionado;
  final _ubicacionController = TextEditingController();

  final _cantidadController = TextEditingController(text: '1');
  final _precioController = TextEditingController(); // NUEVO: Controller para el precio editable

  String? _clienteSeleccionado; // Seguimos usando un cliente simple
  List<OrderItem> _items = [];

  double _precioUnitarioCalculado = 0.0;
  int _tiempoUnitarioCalculado = 0;
  String _nombreReglaAplicada = 'Precio Estándar';

  bool _isSaving = false;


  // En la clase _NuevoPedidoScreenState dentro de nuevo_pedido_screen.dart

  @override
  void initState() {
    super.initState();

    final order = widget.orderParaEditar; // Acceder al widget para obtener el pedido

    if (order != null) {
      // Si estamos editando, precargamos los datos del pedido
      _clienteSeleccionado = order.clienteId;
      _fechaEntregaController.text = order.fechaEntregaEstim.toString().split(' ')[0];
      _items = List<OrderItem>.from(order.items); // Hacemos una copia de la lista de items
    } else {
      // Si es un pedido nuevo, usamos los valores por defecto
      _fechaEntregaController.text = DateTime.now().add(const Duration(days: 3)).toString().split(' ')[0];
      final productoProvider = Provider.of<ProductoProvider>(context, listen: false);
      if (productoProvider.productos.isNotEmpty) {
        _productoSeleccionado = productoProvider.productos.first;
        _precioController.text = _productoSeleccionado!.precioBase.toString();
      }
    }
    _calcularValores(); // Calcular valores iniciales
  }

  // En lib/screens/nuevo_pedido_screen.dart, dentro de la clase _NuevoPedidoScreenState

  void _calcularValores() {
    if (_productoSeleccionado == null || _clienteSeleccionado == null) return;

    final cantidad = int.tryParse(_cantidadController.text) ?? 1;
    final precioUnitario = double.tryParse(_precioController.text) ?? 0.0;

    setState(() {
      // No necesitamos una lógica compleja aquí, solo usamos el precio del controlador
      // ya que el usuario puede editarlo libremente.
      // El tiempo se toma del producto seleccionado.
      _precioUnitarioCalculado = precioUnitario;
      _tiempoUnitarioCalculado = _productoSeleccionado?.tiempoBaseMinutos ?? 0;
      _nombreReglaAplicada = 'Precio personalizado'; // O cualquier texto que quieras
    });
  }

 //Dialogo para agregar cliente

  void _mostrarDialogoAgregarCliente() {
    final _nuevoClienteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Nuevo Cliente'),
          content: TextField(
            controller: _nuevoClienteController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Nombre del nuevo cliente'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (_nuevoClienteController.text.isNotEmpty) {
                  final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                  orderProvider.addCliente(_nuevoClienteController.text);
                  setState(() {
                    _clienteSeleccionado = _nuevoClienteController.text;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _fechaEntregaController.dispose();
    _ubicacionController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    _abonoController.dispose();
    super.dispose();
  }

  void _agregarItem() {
    if (_formKey.currentState!.validate() && _productoSeleccionado != null &&
        _clienteSeleccionado != null) {
      final cantidad = int.tryParse(_cantidadController.text) ?? 1;
      final precioUnitario = double.tryParse(_precioController.text) ?? 0.0;

      if (precioUnitario <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El precio debe ser mayor que cero.')),
        );
        return;
      }

      final nuevoItem = OrderItem(
        id: DateTime
            .now()
            .millisecondsSinceEpoch
            .toString(),
        tipo: _mapProductoATipo(_productoSeleccionado!),
        tamano: ItemTamano.Mediano,
        ubicacion: _ubicacionController.text,
        observaciones: _observacionesController.text,
        cantidad: cantidad,
        precio: precioUnitario,
        tiempoEstimadoMin: _productoSeleccionado!.tiempoBaseMinutos,
      );

      setState(() {
        _items.add(nuevoItem);
        // Limpiar para el siguiente item, pero mantenemos el producto seleccionado
        _ubicacionController.clear();
        _cantidadController.text = '1';
        _precioController.text = _productoSeleccionado!.precioBase
            .toString(); // Reseteamos al precio base
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, completa todos los campos del item.')),
      );
    }
  }

  ItemTipo _mapProductoATipo(Producto producto) {
    if (producto.id.contains('bordado')) return ItemTipo.Bordado;
    if (producto.id.contains('estampado')) return ItemTipo.Estampado;
    return ItemTipo.Serigrafia;
  }

//GUARDAR O ACTUALIZAR PEDIDOS
   void _guardarPedido() async {
    if (_formKey.currentState!.validate() && _clienteSeleccionado != null && _items.isNotEmpty) {
      setState(() { _isSaving = true; });

      try {
        final orderProvider = Provider<OrderProvider>(context, listen: false);
        final cajaProvider = Provider.of<CajaProvider>(context, listen: false);
        final montoAbono = double.tryParse(_abonoController.text) ?? 0.0;

        // Crear el pedido (la lógica de editar/crear se mantiene igual)
        final nuevoPedido = Order(
          id: widget.orderParaEditar == null ? DateTime.now().millisecondsSinceEpoch.toString() : widget.orderParaEditar!.id,
          clienteId: _clienteSeleccionado!,
          fechaRecepcion: widget.orderParaEditar?.fechaRecepcion ?? DateTime.now(),
          fechaEntregaEstim: DateTime.parse(_fechaEntregaController.text),
          items: _items,
          status: widget.orderParaEditar?.status ?? OrderStatus.EnEspera,
          tiempoProduccion: widget.orderParaEditar?.tiempoProduccion,
        );

        if (widget.orderParaEditar == null) {
          await orderProvider.addOrder(nuevoPedido);
        } else {
          await orderProvider.updateOrder(nuevoPedido);
        }

        // --- NUEVA LÓGICA DE ABONO ---
        if (montoAbono > 0) {
          // Registramos el abono en la caja del día
          await cajaProvider.registrarAbonoPedido(nuevoPedido, montoAbono);
        }

        if (mounted) {
          setState(() { _isSaving = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.orderParaEditar == null ? '¡Pedido creado!' : '¡Pedido actualizado!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        // ... tu manejo de errores existente
      }
    } else {
      // ... tu validación existente
    }
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_fechaEntregaController.text),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _fechaEntregaController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  // NUEVO: Metodo para actualizar el precio en el catálogo maestro
  void _actualizarPrecioEnCatalogo() {
    if (_productoSeleccionado == null) return;

    final nuevoPrecio = double.tryParse(_precioController.text);
    if (nuevoPrecio != null && nuevoPrecio > 0) {
      final productoProvider = Provider.of<ProductoProvider>(
          context, listen: false);
      productoProvider.actualizarPrecioProducto(
          _productoSeleccionado!.id, nuevoPrecio);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Precio base de "${_productoSeleccionado!
            .nombre}" actualizado a \$${nuevoPrecio.toStringAsFixed(2)}!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final clienteProvider = Provider.of<OrderProvider>(context);
    final productoProvider = Provider.of<ProductoProvider>(context);
    final cantidad = int.tryParse(_cantidadController.text) ?? 1;
    final precioUnitario = double.tryParse(_precioController.text) ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Pedido'),
        centerTitle: true,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Sección 1: Datos del Cliente ---
            _buildSectionCard('Datos del Cliente', [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _clienteSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar Cliente',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: clienteProvider.clientes.map((cliente) {
                        return DropdownMenuItem(
                          value: cliente,
                          child: Text(cliente),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _clienteSeleccionado = value;
                        });
                      },
                      validator: (value) => value == null ? 'Selecciona un cliente' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.person_add, color: Colors.indigo),
                    onPressed: _mostrarDialogoAgregarCliente,
                    tooltip: 'Agregar nuevo cliente',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fechaEntregaController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de Entrega',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _seleccionarFecha,
                validator: (value) => value == null || value.isEmpty ? 'Selecciona una fecha' : null,
              ),
              TextFormField(
                controller: _abonoController,
                decoration: const InputDecoration(
                  labelText: 'Abono Inicial (Opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: '0.00',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ]),
            const SizedBox(height: 24),

            // --- Sección 2: Agregar Item ---
            _buildSectionCard('Agregar Item', [
                  DropdownButtonFormField<Producto>(
                    value: _productoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Producto/Servicio',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: productoProvider.productos.map((producto) {
                      return DropdownMenuItem(
                        value: producto,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(producto.nombre, style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Base: \$${producto.precioBase.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _productoSeleccionado = value;
                        _precioController.text = value?.precioBase.toString() ?? '0';
                        _calcularValores();
                      });
                    },
                    validator: (value) => value == null ? 'Selecciona un producto' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ubicacionController,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación (ej: Pecho, Espalda)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.checkroom_outlined),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Ingresa la ubicación' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cantidadController,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.add_shopping_cart),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Ingresa la cantidad';
                            if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Cantidad inválida';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _precioController,
                          decoration: const InputDecoration(
                            labelText: 'Precio Unitario',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                            suffixIcon: Icon(Icons.edit),
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          onChanged: (value) => setState(() {}),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Ingresa el precio';
                            if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Precio inválido';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16), // Espacio antes del campo de observaciones

                 // El campo de observaciones ahora va aquí, ocupando todo el ancho
                  TextFormField(
                    controller: _observacionesController,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones (Opciónal)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Añadir a la lista'),
                      onPressed: _agregarItem,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 24),

              // --- Sección 3: Vista Previa del Pedido ---
              if (_items.isNotEmpty) ...[
                _buildSectionCard('Resumen del Pedido', [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                            Icons.check_circle, color: Colors.green),
                        title: Text('${item.tipo.name}'),
                        subtitle: Text(
                            '${item.ubicacion} x${item.cantidad} @ \$${item
                                .precio.toStringAsFixed(0)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('\$${item.subtotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                  Icons.delete_outline, color: Colors.red),
                              onPressed: () =>
                                  setState(() => _items.removeAt(index)),
                              tooltip: 'Eliminar item',
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const Divider(),
                  ),
                  const SizedBox(height: 16),
                  _buildTotalCard(),
                ]),
                const SizedBox(height: 24),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardarPedido,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('GUARDAR PEDIDO'),
                ),
              ),
            ]),;
  }

  // --- Widgets Helper (sin cambios) ---
  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(padding: const EdgeInsets.all(16.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme
                      .of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...children
                ])));
  }

  Widget _buildResumenCard(String label, String value) {
    return Card(color: Colors.grey.shade100,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(value,
                      style: const TextStyle(fontWeight: FontWeight.bold))
                ])));
  }

  Widget _buildTotalCard() {
    final total = _items.fold(0.0, (sum, item) => sum + item.subtotal);
    return Card(color: Colors.green.shade50,
        elevation: 3,
        child: ListTile(title: const Text(
            'Total del Pedido', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text('\$${total.toStringAsFixed(2)}', style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700))));
  }
}