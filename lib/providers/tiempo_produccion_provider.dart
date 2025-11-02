import 'package:flutter/material.dart';
import '../models.dart';
import '../database/database_helper.dart';

class TiempoProduccionProvider with ChangeNotifier {
  Map<String, TiempoProduccion> _tiempos = {};
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Map<String, TiempoProduccion> get tiempos => Map.from(_tiempos);

  TiempoProduccion? getTiempoPorOrderId(String orderId) {
    return _tiempos[orderId];
  }

  // Cargar los tiempos desde la base de datos al iniciar
  Future<void> cargarTiemposDesdeDB() async {
    // Nota: Para simplificar, no cargamos todos los tiempos al inicio.
    // Los cargaremos bajo demanda cuando se soliciten.
    // Una implementación más robusta podría cargarlos todos aquí.
    notifyListeners();
  }

  // Iniciar un nuevo temporizador para un pedido
  void iniciarTemporizador(String orderId) async {
    print('=== INICIANDO TEMPORIZADOR PARA: $orderId ===');

    if (!_tiempos.containsKey(orderId)) {
      print('Creando nuevo TiempoProduccion para $orderId');
      _tiempos[orderId] = TiempoProduccion(
        id: 'tiempo_$orderId',
        orderId: orderId,
        inicio: DateTime.now(),
      );
      // Guardar en la base de datos
      await _dbHelper.guardarTiempoProduccion(_tiempos[orderId]!);
    }

    print('Llamando al método iniciar() del TiempoProduccion');
    _tiempos[orderId]!.iniciar();

    // Actualizar en la base de datos
    await _dbHelper.actualizarTiempoProduccion(_tiempos[orderId]!);

    depurarEstado(orderId);

    notifyListeners();

    print('Iniciando actualización periódica');
    _iniciarActualizacionPeriodica(orderId);

    print('=== TEMPORIZADOR INICIADO PARA: $orderId ===');
  }

  void _iniciarActualizacionPeriodica(String orderId) {
    Future.delayed(const Duration(seconds: 1), () {
      if (_tiempos[orderId]?.estaActivo ?? false) {
        notifyListeners();
        _iniciarActualizacionPeriodica(orderId);
      }
    });
  }

  void actualizarTiempoTranscurrido(String orderId) {
    notifyListeners();
  }

  // Pausar temporizador
  void pausarTemporizador(String orderId) async {
    final tiempo = _tiempos[orderId];
    if (tiempo != null && tiempo.estaActivo) {
      tiempo.pausar();
      await _dbHelper.actualizarTiempoProduccion(tiempo);
      notifyListeners();
    }
  }

  // Reanudar temporizador
  void reanudarTemporizador(String orderId) async {
    final tiempo = _tiempos[orderId];
    if (tiempo != null && !tiempo.estaActivo && tiempo.fin == null) {
      tiempo.iniciar();
      await _dbHelper.actualizarTiempoProduccion(tiempo);
      notifyListeners();
    }
  }

  // Terminar temporizador
  void terminarTemporizador(String orderId) async {
    final tiempo = _tiempos[orderId];
    if (tiempo != null && tiempo.estaActivo) {
      tiempo.terminar();
      await _dbHelper.actualizarTiempoProduccion(tiempo);
      notifyListeners();
    }
  }

  String getTiempoFormateado(String orderId) {
    final tiempo = _tiempos[orderId];
    if (tiempo == null) return '00:00:00';
    return tiempo.tiempoTranscurridoFormateado;
  }

  bool estaActivo(String orderId) {
    final tiempo = _tiempos[orderId];
    return tiempo?.estaActivo ?? false;
  }

  bool estaPausado(String orderId) {
    final tiempo = _tiempos[orderId];
    return tiempo != null && tiempo.pausa != null && tiempo.fin == null;
  }

  void depurarEstado(String orderId) {
    final tiempo = _tiempos[orderId];
    print('=== DEPURACIÓN TEMPORIZADOR ===');
    print('Order ID: $orderId');
    print('Tiempo existe: ${tiempo != null}');
    if (tiempo != null) {
      print('Está activo: ${tiempo.estaActivo}');
      print('Inicio: ${tiempo.inicio}');
      print('Pausa: ${tiempo.pausa}');
      print('Fin: ${tiempo.fin}');
      print('Tiempo transcurrido: ${tiempo.tiempoTranscurridoFormateado}');
    }
    print('================================');
  }
}