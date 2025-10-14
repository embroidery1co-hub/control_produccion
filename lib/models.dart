// lib/models.dart
//import 'package:flutter/foundation.dart';

enum ItemTipo { Bordado, Estampado, Dotacion }
enum ItemTamano { Pequeno, Mediano, Grande, Especial }
enum OrderEstado { EnEspera, EnProduccion, Pausado, Terminado, Entregado }

class Customer {
  final String id;
  final String nombre;
  final String telefono;
  Customer({required this.id, required this.nombre, required this.telefono});
}

class OrderItem {
  final String id;
  final ItemTipo tipo;
  final ItemTamano? tamano;
  final String ubicacion;
  final int cantidad;
  final double precio;
  final int tiempoEstimadoMin; // minutos por unidad
  final String observaciones;

  OrderItem({
    required this.id,
    required this.tipo,
    this.tamano,
    required this.ubicacion,
    required this.cantidad,
    required this.precio,
    required this.tiempoEstimadoMin,
    this.observaciones = '',
  });

  double get subtotal => cantidad * precio;
  int get totalTiempo => tiempoEstimadoMin * cantidad;
}

class Order {
  final String id;
  final String clienteId;
  final DateTime fechaRecepcion;
  DateTime fechaEntregaEstim;
  OrderEstado estado;
  List<OrderItem> items;
  String? asignado; // nombre operario o máquina
  int accumulatedMinutes = 0; // tiempo registrado en producción

  Order({
    required this.id,
    required this.clienteId,
    required this.fechaRecepcion,
    required this.fechaEntregaEstim,
    this.estado = OrderEstado.EnEspera,
    required this.items,
    this.asignado,
    this.accumulatedMinutes = 0,
  });

  int get totalTiempoEstimado =>
      items.fold(0, (s, it) => s + it.totalTiempo);
  double get totalPrecio => items.fold(0.0, (s, it) => s + it.subtotal);
}
