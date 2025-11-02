import 'package:flutter/material.dart';
import '../models.dart';
import '../database/database_helper.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  List<String> _clientes = ["Juan Pérez", "María García", "Carlos López"];

  final DatabaseHelper _dbHelper = DatabaseHelper();

  OrderProvider() {
    _cargarPedidos();
  }

  // Getters
  List<Order> get orders => [..._orders];
  List<String> get clientes => [..._clientes];

  // Cargar pedidos desde la base de datos
  Future<void> _cargarPedidos() async {
    _orders = await _dbHelper.obtenerTodosLosPedidos();
    notifyListeners();
  }

  // Obtener pedidos por estado
  List<Order> getOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }

  // Agregar nuevo pedido
  Future<void> addOrder(Order order) async {
    // Guardar en la base de datos
    await _dbHelper.insertarPedido(order);

    // Agregar a la lista local
    _orders.add(order);
    notifyListeners();
  }

  // Actualizar estado de pedido
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    // Actualizar en la base de datos
    await _dbHelper.actualizarEstadoPedido(orderId, newStatus);

    // Actualizar en la lista local
    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    if (orderIndex >= 0) {
      _orders[orderIndex].status = newStatus;
      notifyListeners();
    }
  }

  // Actualizar un pedido completo
  Future<void> updateOrder(Order updatedOrder) async {
    // Actualizar en la base de datos
    await _dbHelper.actualizarPedido(updatedOrder);

    // Actualizar en la lista local
    final orderIndex = _orders.indexWhere((order) => order.id == updatedOrder.id);
    if (orderIndex >= 0) {
      _orders[orderIndex] = updatedOrder;
      notifyListeners();
    }
  }

  // Agregar nuevo cliente
  void addCliente(String nombre) {
    if (!_clientes.contains(nombre)) {
      _clientes.add(nombre);
      notifyListeners();
    }
  }
}