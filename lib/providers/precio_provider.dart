import 'package:flutter/material.dart';
import '../models.dart';

class PrecioProvider with ChangeNotifier {
  List<PrecioVariable> _precios = [];

  List<PrecioVariable> get precios => [..._precios];

  PrecioProvider() {
    _cargarPreciosEjemplo();
  }

  void _cargarPreciosEjemplo() {
    _precios = [
      // Camiseta polo con bordado de pecho simple
      PrecioVariable(
        id: 'camiseta_polo_pecho_simple',
        nombreProducto: 'Camiseta Polo',
        variable: VariableProducto(
          tipo: TipoBordado.Pecho,
          calidad: CalidadBordado.Simple,
          cantidad: 1,
          clienteProporcionaPrenda: false,
        ),
        precioBase: 25000,
        precioAdicionalPorUnidad: 15000,
      ),
      // Camiseta polo con dos bordados adelante
      PrecioVariable(
        id: 'camiseta_polo_dos_adelante',
        nombreProducto: 'Camiseta Polo',
        variable: VariableProducto(
          tipo: TipoBordado.Pecho,
          calidad: CalidadBordado.Doble,
          cantidad: 2,
          clienteProporcionaPrenda: false,
        ),
        precioBase: 35000,
        precioAdicionalPorUnidad: 20000,
      ),
      // Camiseta con bordado grande atrás
      PrecioVariable(
        id: 'camiseta_espalda_grande',
        nombreProducto: 'Camiseta',
        variable: VariableProducto(
          tipo: TipoBordado.Espalda,
          calidad: CalidadBordado.Premium,
          cantidad: 1,
          clienteProporcionaPrenda: false,
        ),
        precioBase: 40000,
        precioAdicionalPorUnidad: 25000,
      ),
      // Cliente trae camiseta para bordar
      PrecioVariable(
        id: 'cliente_proporciona',
        nombreProducto: 'Prenda del Cliente',
        variable: VariableProducto(
          tipo: TipoBordado.Personalizado,
          calidad: CalidadBordado.Simple,
          cantidad: 1,
          clienteProporcionaPrenda: true,
        ),
        precioBase: 15000,
        precioAdicionalPorUnidad: 10000,
      ),
    ];
  }

  // Buscar precio según variables
  PrecioVariable? buscarPrecio(VariableProducto variable) {
    try {
      return _precios.firstWhere(
            (p) => p.variable.id == variable.id,
      );
    } catch (e) {
      return null;
    }
  }

  // Calcular precio para un pedido
  double calcularPrecioPedido(VariableProducto variable, int cantidad) {
    final precio = buscarPrecio(variable);
    if (precio == null) return 0;

    return precio.calcularPrecioTotal(cantidad);
  }

  // Agregar nuevo precio (para cuando importemos desde Excel)
  void agregarPrecio(PrecioVariable precio) {
    _precios.add(precio);
    notifyListeners();
  }
}