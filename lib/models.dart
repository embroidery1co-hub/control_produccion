import 'package:flutter/foundation.dart';

// Enum para tipos de items
enum ItemTipo { Bordado, Estampado, Serigrafia }

// Enum para tamaños
enum ItemTamano { Pequenyo, Mediano, Grande }

// Enum para estados de pedido
enum OrderStatus { EnEspera, EnProduccion, Pausado, Terminado, Entregado }

// Enum para tipos de bordado
enum TipoBordado {
  Pecho,
  Espalda,
  Manga,
  Completo,
  Personalizado
}

// Enum para calidad de bordado
enum CalidadBordado {
  Simple,
  Doble,
  Premium
}

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

  // Getter para calcular subtotal
  double get subtotal => precio * cantidad;

  // Getter para calcular tiempo total
  int get totalTiempo => tiempoEstimadoMin * cantidad;
}

class Order {
  final String id;
  final String clienteId;
  final DateTime fechaRecepcion;
  final DateTime fechaEntregaEstim;
  List<OrderItem> items;
  OrderStatus status;
  TiempoProduccion? tiempoProduccion;

  Order({
    required this.id,
    required this.clienteId,
    required this.fechaRecepcion,
    required this.fechaEntregaEstim,
    required this.items,
    this.status = OrderStatus.EnEspera,
    this.tiempoProduccion,
  });

  // Calcular total del pedido
  double get total => items.fold(0, (sum, item) => sum + (item.precio * item.cantidad));

  // Alias para total (para compatibilidad con tu código)
  double get totalPrecio => total;

  // Getter para calcular tiempo total estimado
  int get totalTiempoEstimado => items.fold(0, (sum, item) => sum + item.tiempoEstimadoMin);
}

class VariableProducto {
  final TipoBordado tipo;
  final CalidadBordado calidad;
  final int cantidad;
  final bool clienteProporcionaPrenda;

  VariableProducto({
    required this.tipo,
    required this.calidad,
    required this.cantidad,
    required this.clienteProporcionaPrenda,
  });

  // Para identificar combinaciones únicas
  String get id => '${tipo.name}_${calidad.name}_${cantidad}_${clienteProporcionaPrenda}';
}

class PrecioVariable {
  final String id;
  final String nombreProducto;
  final VariableProducto variable;
  final double precioBase;
  final double precioAdicionalPorUnidad;

  PrecioVariable({
    required this.id,
    required this.nombreProducto,
    required this.variable,
    required this.precioBase,
    required this.precioAdicionalPorUnidad,
  });

  double calcularPrecioTotal(int cantidad) {
    return precioBase + (precioAdicionalPorUnidad * (cantidad - 1));
  }
}

class TiempoProduccion {
  final String id;
  final String orderId;
  final DateTime inicio;
  DateTime? pausa;
  DateTime? fin;
  int duracionPausas; // en segundos
  bool estaActivo;

  TiempoProduccion({
    required this.id,
    required this.orderId,
    required this.inicio,
    this.pausa,
    this.fin,
    this.duracionPausas = 0,
    this.estaActivo = false,
  });

  // Obtener tiempo transcurrido total (incluyendo pausas)
  Duration get tiempoTranscurrido {
    final ahora = DateTime.now();
    final finReal = fin ?? (estaActivo ? ahora : pausa ?? inicio);
    final tiempoBase = finReal.difference(inicio);
    return tiempoBase + Duration(seconds: duracionPausas);
  }

  // Obtener tiempo transcurrido formateado
  String get tiempoTranscurridoFormateado {
    final duracion = tiempoTranscurrido;
    final horas = duracion.inHours;
    final minutos = duracion.inMinutes % 60;
    final segundos = duracion.inSeconds % 60;

    return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  // Iniciar el temporizador
  void iniciar() {
    estaActivo = true;
    if (pausa != null && fin == null) {
      duracionPausas += DateTime.now().difference(pausa!).inSeconds;
    }
  }

  // Pausar el temporizador
  void pausar() {
    estaActivo = false;
    pausa = DateTime.now();
  }

  // Terminar el temporizador
  void terminar() {
    estaActivo = false;
    fin = DateTime.now();
  }
}