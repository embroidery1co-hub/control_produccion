import 'package:flutter/material.dart';
import '../models.dart';

class ProductoProvider with ChangeNotifier {
  // Aquí irían tus productos cargados desde Excel.
  // Por ahora, los pondremos aquí como datos de ejemplo.
  List<Producto> _productos = [
    Producto(
      id: 'bordado-pecho',
      nombre: 'Bordado en Pecho',
      descripcion: 'Bordado de logo o texto en el área del pecho.',
      precioBase: 25000.0,
      tiempoBaseMinutos: 15,
    ),
    Producto(
      id: 'bordado-espalda',
      nombre: 'Bordado en Espalda',
      descripcion: 'Bordado de logo o texto en el área de la espalda.',
      precioBase: 35000.0,
      tiempoBaseMinutos: 20,
    ),
    Producto(
      id: 'estampado-frontal',
      nombre: 'Estampado Frontal',
      descripcion: 'Estampado de una o varios colores en la parte delantera.',
      precioBase: 18000.0,
      tiempoBaseMinutos: 10,
    ),
    Producto(
      id: 'serigrafia',
      nombre: 'Serigrafía',
      descripcion: 'Impresión de serigrafía para grandes cantidades.',
      precioBase: 12000.0,
      tiempoBaseMinutos: 8,
    ),
  ];

  List<Producto> get productos => [..._productos];

  // Obtener un producto por su ID
  Producto? getProductoById(String id) {
    try {
      return _productos.firstWhere((producto) => producto.id == id);
    } catch (e) {
      return null;
    }
  }

  // --- NUEVO: Método para actualizar el precio de un producto ---
  void actualizarPrecioProducto(String productoId, double nuevoPrecio) {
    final index = _productos.indexWhere((p) => p.id == productoId);
    if (index >= 0) {
      _productos[index].precioBase = nuevoPrecio;
      notifyListeners(); // ¡Importante! Notifica a todos los que escuchan para que se actualicen.
    }
  }
}