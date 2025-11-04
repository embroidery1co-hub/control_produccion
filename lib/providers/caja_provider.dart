import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear fechas
import '../models.dart';
import '../database/database_helper.dart'; // Asumimos que lo tienes

class CajaProvider with ChangeNotifier {
  CajaDiaria? _cajaHoy;
  List<MovimientoCaja> _movimientosHoy = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  CajaDiaria? get cajaHoy => _cajaHoy;
  List<MovimientoCaja> get movimientosHoy => [..._movimientosHoy];

  // Cargar o crear la caja del día actual
  Future<void> cargarOCrearCajaDelDia() async {
    final hoy = DateTime.now();
    final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDelDia = inicioDelDia.add(const Duration(days: 1));

    // Intentar obtener la caja de hoy de la base de datos
    _cajaHoy = await _dbHelper.obtenerCajaPorFecha(inicioDelDia);

    if (_cajaHoy == null) {
      // Si no existe, crear una nueva caja abierta
      _cajaHoy = CajaDiaria(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fecha: inicioDelDia,
        saldoInicial: 0.0, // Por defecto, se puede configurar
      );
      await _dbHelper.insertarCaja(_cajaHoy!);
    }

    // Cargar los movimientos de hoy
    _movimientosHoy = await _dbHelper.obtenerMovimientosPorCajaId(_cajaHoy!.id);

    notifyListeners();
  }

  // Abrir la caja por primera vez en el día
  Future<void> abrirCaja(double saldoInicial) async {
    if (_cajaHoy != null && !_cajaHoy!.estaCerrada) {
      _cajaHoy!.saldoInicial = saldoInicial;
      await _dbHelper.actualizarCaja(_cajaHoy!);
      notifyListeners();
    }
  }

  // Registrar un movimiento genérico (entrada o salida)
  Future<void> registrarMovimiento({
    required String concepto,
    required double monto,
    required TipoMovimiento tipo,
    String? referenciaId,
  }) async {
    if (_cajaHoy == null || _cajaHoy!.estaCerrada) return;

    final movimiento = MovimientoCaja(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cajaDiariaId: _cajaHoy!.id,
      fechaHora: DateTime.now(),
      concepto: concepto,
      monto: monto,
      tipo: tipo,
      referenciaId: referenciaId,
    );

    await _dbHelper.insertarMovimiento(movimiento);
    _movimientosHoy.add(movimiento);

    // Actualizar totales en la caja
    if (tipo == TipoMovimiento.Entrada) {
      _cajaHoy!.totalEntradas += monto;
    } else if (tipo == TipoMovimiento.Salida) {
      _cajaHoy!.totalSalidas += monto;
    }

    await _dbHelper.actualizarCaja(_cajaHoy!);
    notifyListeners();
  }

  // Registrar el pago de un pedido (un tipo especial de movimiento)
  Future<void> registrarPagoPedido(Order pedido) async {
    if (_cajaHoy == null || _cajaHoy!.estaCerrada) return;

    await registrarMovimiento(
      concepto: 'Venta: Pedido #${pedido.id.substring(0, 6)}',
      monto: pedido.total,
      tipo: TipoMovimiento.Venta,
      referenciaId: pedido.id,
    );

    // Actualizar el total de ventas en la caja
    _cajaHoy!.totalVentas += pedido.total;
    await _dbHelper.actualizarCaja(_cajaHoy!);
    notifyListeners();
  }

  // Cerrar la caja al final del día
  Future<void> cerrarCaja() async {
    if (_cajaHoy == null || _cajaHoy!.estaCerrada) return;

    _cajaHoy!.estaCerrada = true;
    _cajaHoy!.saldoFinal = _cajaHoy!.saldoCalculado;
    await _dbHelper.actualizarCaja(_cajaHoy!);
    notifyListeners();
  }
}