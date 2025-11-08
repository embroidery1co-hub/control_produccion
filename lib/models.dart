import 'package:flutter/foundation.dart';

// Enum para tipos de items
enum ItemTipo { Bordado, Estampado, Serigrafia }
extension ItemTipoExtension on ItemTipo {
  String get nombre {
    switch (this) {
      case ItemTipo.Bordado: return 'Bordado';
      case ItemTipo.Estampado: return 'Estampado';
      case ItemTipo.Serigrafia: return 'Serigrafía';
    }
  }
}

// Enum para tamaños
enum ItemTamano { Pequenyo, Mediano, Grande }
extension ItemTamanoExtension on ItemTamano {
  String get nombre {
    switch (this) {
      case ItemTamano.Pequenyo: return 'Pequeño';
      case ItemTamano.Mediano: return 'Mediano';
      case ItemTamano.Grande: return 'Grande';
    }
  }
}

// Enum para estados de pedido
enum OrderStatus {
  EnEspera,
  EnProduccion,
  Pausado,
  Terminado,
  Entregado,
  Archivado // <-- NUEVO ESTADO
}

// --- MODELOS PARA EL MÓDULO DE CAJA ---

class CajaDiaria {
  final String id;
  final DateTime fecha;
  double saldoInicial;
  double saldoFinal;
  double totalVentas; // Suma de los pedidos pagados en el día
  double totalEntradas;
  double totalSalidas;
  bool estaCerrada;

  CajaDiaria({
    required this.id,
    required this.fecha,
    required this.saldoInicial,
    this.saldoFinal = 0.0,
    this.totalVentas = 0.0,
    this.totalEntradas = 0.0,
    this.totalSalidas = 0.0,
    this.estaCerrada = false,
  });

  // AÑADE ESTE MÉTODO
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'saldoInicial': saldoInicial,
      'saldoFinal': saldoFinal,
      'totalVentas': totalVentas,
      'totalEntradas': totalEntradas,
      'totalSalidas': totalSalidas,
      'estaCerrada': estaCerrada ? 1 : 0,
    };
  }

  // AÑADE ESTE CONSTRUCTOR FACTORY
  factory CajaDiaria.fromMap(Map<String, dynamic> map) {
    return CajaDiaria(
      id: map['id'],
      fecha: DateTime.parse(map['fecha']),
      saldoInicial: map['saldoInicial'],
      saldoFinal: map['saldoFinal'],
      totalVentas: map['totalVentas'],
      totalEntradas: map['totalEntradas'],
      totalSalidas: map['totalSalidas'],
      estaCerrada: map['estaCerrada'] == 1,
    );
  }

  // Getter para calcular el saldo final teórico
  double get saldoCalculado => saldoInicial + totalVentas + totalEntradas - totalSalidas;
}

class MovimientoCaja {
  final String id;
  final String cajaDiariaId;
  final DateTime fechaHora;
  final String concepto;
  final double monto;
  final TipoMovimiento tipo;
  final String? referenciaId; // ID del pedido, si el movimiento es una venta

  MovimientoCaja({
    required this.id,
    required this.cajaDiariaId,
    required this.fechaHora,
    required this.concepto,
    required this.monto,
    required this.tipo,
    this.referenciaId,
  });

  // AÑADE ESTE MÉTODO
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cajaDiariaId': cajaDiariaId,
      'fechaHora': fechaHora.toIso8601String(),
      'concepto': concepto,
      'monto': monto,
      'tipo': tipo.name,
      'referenciaId': referenciaId,
    };
  }

  // AÑADE ESTE CONSTRUCTOR FACTORY
  factory MovimientoCaja.fromMap(Map<String, dynamic> map) {
    return MovimientoCaja(
      id: map['id'],
      cajaDiariaId: map['cajaDiariaId'],
      fechaHora: DateTime.parse(map['fechaHora']),
      concepto: map['concepto'],
      monto: map['monto'],
      tipo: TipoMovimiento.values.byName(map['tipo']),
      referenciaId: map['referenciaId'],
    );
  }
}

enum TipoMovimiento { Entrada, Salida, Venta }

// --- MODELOS PRINCIPALES ---

class OrderItem {
  final String id;
  final ItemTipo tipo;
  final ItemTamano tamano;
  final String ubicacion;
  final String observaciones;
  final int cantidad;
  final double precio;
  final int tiempoEstimadoMin;

  OrderItem({
    required this.id,
    required this.tipo,
    required this.tamano,
    required this.ubicacion,
    this.observaciones = '',
    required this.cantidad,
    required this.precio,
    required this.tiempoEstimadoMin,
  });

  // Getter para calcular subtotal
  double get subtotal => precio * cantidad;
}

class Order {
  final String id;
  final String clienteId;
  final DateTime fechaRecepcion;
  final DateTime fechaEntregaEstim;
  List<OrderItem> items;
  OrderStatus status;
  TiempoProduccion? tiempoProduccion;
  final double totalPagado;

  Order({
    required this.id,
    required this.clienteId,
    required this.fechaRecepcion,
    required this.fechaEntregaEstim,
    required this.items,
    this.status = OrderStatus.EnEspera,
    this.tiempoProduccion,
    this.totalPagado = 0.0,
  });

  // Calcular total del pedido
  double get total => items.fold(0, (sum, item) => sum + item.subtotal);

  // Alias para total (para compatibilidad con tu código)
  double get totalPrecio => total;

  // Getter para calcular tiempo total estimado
  int get totalTiempoEstimado => items.fold(0, (sum, item) => sum + item.tiempoEstimadoMin);

  // <-- NUEVO GETTER PARA CALCULAR EL SALDO
  double get saldoPendiente => total - totalPagado;

}

// --- NUEVO MODELO PARA EL CATÁLOGO ---

class Producto {
  final String id;
  final String nombre;
  final String descripcion;
  double precioBase; // Mutable para poder editarlo
  final int tiempoBaseMinutos;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precioBase,
    required this.tiempoBaseMinutos,
  });
}

// --- MODELO PARA CLIENTES (Opcional, pero bueno para tener) ---

class Cliente {
  final String id;
  final String nombre;
  final String telefono;
  final String email;

  Cliente({
    required this.id,
    required this.nombre,
    this.telefono = '',
    this.email = '',
  });
}

// --- MODELO PARA TIEMPO DE PRODUCCIÓN (Sin cambios) ---

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