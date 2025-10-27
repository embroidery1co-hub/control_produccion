import 'package:flutter/material.dart';
import '../models.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  List<String> _clientes = ["Juan Pérez", "María García", "Carlos López"];

  List<Order> get orders => [..._orders];
  List<String> get clientes => [..._clientes];

  List<Order> getOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }

  void addOrder(Order order) {
    _orders.add(order);
    notifyListeners();
  }

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    if (orderIndex >= 0) {
      _orders[orderIndex].status = newStatus;
      notifyListeners();
    }
  }

  // NUEVO: Método para actualizar un pedido completo
  void updateOrder(Order updatedOrder) {
    final orderIndex = _orders.indexWhere((order) => order.id == updatedOrder.id);
    if (orderIndex >= 0) {
      _orders[orderIndex] = updatedOrder;
      notifyListeners();
    }
  }

  void addCliente(String nombre) {
    if (!_clientes.contains(nombre)) {
      _clientes.add(nombre);
      notifyListeners();
    }
  }
}