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

  @override
  void dispose() {
    _fechaEntregaController.dispose();
    _ubicacionController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
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

  void _guardarPedido() async {
    if (_formKey.currentState!.validate() && _clienteSeleccionado != null &&
        _items.isNotEmpty) {
      setState(() => _isSaving = true);

      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final nuevoPedido = Order(
        id: DateTime
            .now()
            .millisecondsSinceEpoch
            .toString(),
        clienteId: _clienteSeleccionado!,
        fechaRecepcion: DateTime.now(),
        fechaEntregaEstim: DateTime.parse(_fechaEntregaController.text),
        items: _items,
      );

      await orderProvider.addOrder(nuevoPedido);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Pedido creado exitosamente!')),
        );
        Navigator.pop(context);
      }
    } else {
      String mensajeError = '';
      if (_clienteSeleccionado == null)
        mensajeError = 'Debes seleccionar un cliente. ';
      if (_items.isEmpty)
        mensajeError += 'Debes añadir al menos un item al pedido.';
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeError)));
    }
  }

  // En lib/screens/nuevo_pedido_screen.dart
// Dentro de la clase _NuevoPedidoScreenState

  void _crearPedidoDirecto() {
    // 1. Validar que los datos básicos estén completos
    if (_formKey.currentState!.validate() && _productoSeleccionado != null && _clienteSeleccionado != null) {

      // 2. Obtener los valores de los controllers
      final cantidad = int.tryParse(_cantidadController.text) ?? 1;
      final precioUnitario = double.tryParse(_precioController.text) ?? 0.0;

      // 3. Validar que el precio sea válido
      if (precioUnitario <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El precio debe ser mayor que cero.')),
        );
        return;
      }

      // 4. Crear el OrderItem directamente
      final itemDirecto = OrderItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tipo: _mapProductoATipo(_productoSeleccionado!),
        tamano: ItemTamano.Mediano, // Puedes añadir un selector de tamaño aquí si quieres
        ubicacion: _ubicacionController.text,
        observaciones: _observacionesController.text,
        cantidad: cantidad,
        precio: precioUnitario,
        tiempoEstimadoMin: _productoSeleccionado!.tiempoBaseMinutos,
      );

      // 5. Crear el objeto Order con el item dentro
      final pedidoDirecto = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        clienteId: _clienteSeleccionado!,
        fechaRecepcion: DateTime.now(),
        fechaEntregaEstim: DateTime.parse(_fechaEntregaController.text),
        items: [itemDirecto], // La lista de items solo tiene un elemento
      );

      // 6. Guardar el pedido usando el Provider
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.addOrder(pedidoDirecto);

      // 7. Mostrar un mensaje de éxito y cerrar la pantalla
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Pedido de una sola prenda creado exitosamente!')),
      );
      Navigator.pop(context);
    } else {
      // 8. Si la validación falla, mostrar un mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un cliente y un producto para crear el pedido directamente.')),
      );
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
    final clienteProvider = Provider.of<OrderProvider>(
        context); // Usamos OrderProvider para la lista de clientes de ejemplo
    final productoProvider = Provider.of<ProductoProvider>(context);
    final cantidad = int.tryParse(_cantidadController.text) ?? 1;
    final precioUnitario = double.tryParse(_precioController.text) ?? 0.0;

    return Scaffold(
      appBar: AppBar(
          title: const Text('Crear Nuevo Pedido'), centerTitle: true),
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
                // CÓDIGO CORREGIDO
                DropdownButtonFormField<String>(
                  value: _clienteSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar Cliente',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: clienteProvider.clientes.map((
                      nombreCliente) { // <-- El parámetro es el nombre del cliente (un String)
                    return DropdownMenuItem(
                      value: nombreCliente,
                      // <-- El valor es el String completo
                      child: Text(nombreCliente), // <-- Mostramos el String
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _clienteSeleccionado = value;
                    });
                  },
                  validator: (value) =>
                  value == null
                      ? 'Selecciona un cliente'
                      : null,
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
                  validator: (value) =>
                  value == null || value.isEmpty
                      ? 'Selecciona una fecha'
                      : null,
                ),
              ]),
              const SizedBox(height: 24),

              // AQUÍ ES DONDE VA EL BOTÓN
              ElevatedButton.icon(
                icon: const Icon(Icons.fast_forward),
                label: const Text('Crear Pedido Directamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
                onPressed: _crearPedidoDirecto, // Este método lo crearemos a continuación
              ),
              const SizedBox(height: 24), // Espacio antes de la siguiente sección

              // --- Sección 2: Agregar Items ---
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
                          Text(producto.nombre,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Base: \$${producto.precioBase.toStringAsFixed(
                              0)}', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _productoSeleccionado = value;
                      // Al cambiar el producto, actualizamos el campo de precio con su precio base
                      _precioController.text = value?.precioBase.toString() ??
                          '0';
                    });
                  },
                  validator: (value) =>
                  value == null
                      ? 'Selecciona un producto'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ubicacionController,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación (ej: Pecho, Espalda)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.accessibility), // Icon de prenda/mannequin
                  ),
                  validator: (value) {
                    return null;
                  },
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
                          if (value == null || value.isEmpty)
                            return 'Ingresa la cantidad';
                          if (int.tryParse(value) == null || int.parse(value) <= 0)
                            return 'Cantidad inválida';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Campo de observaciones (CORREGIDO)
                    Expanded(
                      child: TextFormField( // <-- CAMBIA A TextFormField
                        controller: _observacionesController,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones (Opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Campo de precio editable (CORREGIDO)
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
                          if (value == null || value.isEmpty)
                            return 'Ingresa el precio';
                          if (double.tryParse(value) == null || double.parse(value) <= 0)
                            return 'Precio inválido';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildResumenCard('Precio Total Item',
                    '\$${(precioUnitario * cantidad).toStringAsFixed(0)}'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Añadir a la lista'),
                    onPressed: _agregarItem,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                // NUEVO: Botón para actualizar el precio en el catálogo
                OutlinedButton.icon(
                  icon: const Icon(Icons.update, color: Colors.orange),
                  label: const Text('Actualizar Precio Base en el Catálogo',
                      style: TextStyle(color: Colors.orange)),
                  onPressed: _actualizarPrecioEnCatalogo,
                ),
              ]),
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
            ],
          ),
        ),
      ),
    );
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