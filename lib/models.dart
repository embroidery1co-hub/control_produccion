// Enum para tipos de items
enum ItemTipo { Bordado, Estampado, Serigrafia }
enum ItemTamano { Pequeno, Mediano, Grande }
enum OrderStatus { EnEspera, EnProduccion, Pausado, Terminado, Entregado }

class OrderItem {
  final String id;
  final ItemTipo tipo;
  final ItemTamano tamano;
  final String ubicacion;
  final int cantidad;
  final double precio;
  final int tiempoEstimadoMin;

  OrderItem({
    required this.id,
    required this.tipo,
    required this.tamano,
    required this.ubicacion,
    required this.cantidad,
    required this.precio,
    required this.tiempoEstimadoMin,
  });

  // NUEVO: Getter para calcular subtotal
  double get subtotal => precio * cantidad;

  // NUEVO: Getter para calcular tiempo total
  int get totalTiempo => tiempoEstimadoMin * cantidad;
}

class Order {
  final String id;
  final String clienteId;
  final DateTime fechaRecepcion;
  final DateTime fechaEntregaEstim;
  List<OrderItem> items;
  OrderStatus status;

  Order({
    required this.id,
    required this.clienteId,
    required this.fechaRecepcion,
    required this.fechaEntregaEstim,
    required this.items,
    this.status = OrderStatus.EnEspera,
  });

  // NUEVO: Getter para calcular total del pedido
  double get total => items.fold(0, (sum, item) => sum + (item.precio * item.cantidad));

  // NUEVO: Alias para total (para compatibilidad con tu código)
  double get totalPrecio => total;

  // NUEVO: Getter para calcular tiempo total estimado
  int get totalTiempoEstimado => items.fold(0, (sum, item) => sum + item.tiempoEstimadoMin);
}