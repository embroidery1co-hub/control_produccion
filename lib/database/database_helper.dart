import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'control_produccion.db');
    return await openDatabase(
      path,
      version: 1, // Incrementa este número si cambias el esquema de la BD
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    // Formato de fecha para SQLite: YYYY-MM-DD HH:MM:SS
    final dateFormat =
    DateFormat('yyyy-MM-dd HH:mm:ss');

    // Tabla para los Pedidos
    await db.execute('''
      CREATE TABLE caja_diaria(
      id TEXT PRIMARY KEY,
      fecha TEXT NOT NULL,
      saldoInicial REAL NOT NULL,
      saldoFinal REAL NOT NULL DEFAULT 0.0,
      totalVentas REAL NOT NULL DEFAULT 0.0,
      totalEntradas REAL NOT NULL DEFAULT 0.0,
      totalSalidas REAL NOT NULL DEFAULT 0.0,
      estaCerrada INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Tabla para los Items de cada Pedido
    await db.execute('''
      CREATE TABLE movimientos_caja(
      id TEXT PRIMARY KEY,
      cajaDiariaId TEXT NOT NULL,
      fechaHora TEXT NOT NULL,
      concepto TEXT NOT NULL,
      monto REAL NOT NULL,
      tipo TEXT NOT NULL,
      referenciaId TEXT,
      FOREIGN KEY (cajaDiariaId) REFERENCES caja_diaria (id) ON DELETE CASCADE
      )
    ''');

    // Tabla para los Tiempos de Producción
    await db.execute('''
      CREATE TABLE tiempos_produccion(
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL UNIQUE,
        inicio TEXT NOT NULL,
        pausa TEXT,
        fin TEXT,
        duracion_pausas INTEGER NOT NULL DEFAULT 0,
        esta_activo INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- Métodos para Pedidos (CRUD) ---

  Future<void> insertarPedido(Order order) async {
    final db = await database;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    // Insertar el pedido principal
    await db.insert(
      'orders',
      {
        'id': order.id,
        'cliente_id': order.clienteId,
        'fecha_recepcion': dateFormat.format(order.fechaRecepcion),
        'fecha_entrega_estim': dateFormat.format(order.fechaEntregaEstim),
        'status': order.status.name,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Insertar cada item del pedido
    for (var item in order.items) {
      await db.insert(
        'order_items',
        {
          'id': item.id,
          'order_id': order.id,
          'tipo': item.tipo.name,
          'tamano': item.tamano.name,
          'ubicacion': item.ubicacion,
          'cantidad': item.cantidad,
          'precio': item.precio,
          'tiempo_estimado_min': item.tiempoEstimadoMin,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Order>> obtenerTodosLosPedidos() async {
    final db = await database;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    final List<Map<String, dynamic>> orderMaps = await db.query('orders');

    if (orderMaps.isEmpty) {
      return [];
    }

    List<Order> orders = [];
    for (var orderMap in orderMaps) {
      // Obtener los items para este pedido
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderMap['id']],
      );

      List<OrderItem> items = itemMaps.map((itemMap) => OrderItem(
        id: itemMap['id'],
        tipo: ItemTipo.values.byName(itemMap['tipo']),
        tamano: ItemTamano.values.byName(itemMap['tamano']),
        ubicacion: itemMap['ubicacion'],
        cantidad: itemMap['cantidad'],
        precio: itemMap['precio'],
        tiempoEstimadoMin: itemMap['tiempo_estimado_min'],
      )).toList();

      // Obtener el tiempo de producción si existe
      TiempoProduccion? tiempoProduccion;
      final List<Map<String, dynamic>> tiempoMaps = await db.query(
        'tiempos_produccion',
        where: 'order_id = ?',
        whereArgs: [orderMap['id']],
      );
      if (tiempoMaps.isNotEmpty) {
        final tMap = tiempoMaps.first;
        tiempoProduccion = TiempoProduccion(
          id: tMap['id'],
          orderId: tMap['order_id'],
          inicio: dateFormat.parse(tMap['inicio']),
          pausa: tMap['pausa'] != null ? dateFormat.parse(tMap['pausa']) : null,
          fin: tMap['fin'] != null ? dateFormat.parse(tMap['fin']) : null,
          duracionPausas: tMap['duracion_pausas'],
          estaActivo: tMap['esta_activo'] == 1,
        );
      }

      orders.add(Order(
        id: orderMap['id'],
        clienteId: orderMap['cliente_id'],
        fechaRecepcion: dateFormat.parse(orderMap['fecha_recepcion']),
        fechaEntregaEstim: dateFormat.parse(orderMap['fecha_entrega_estim']),
        items: items,
        status: OrderStatus.values.byName(orderMap['status']),
        tiempoProduccion: tiempoProduccion,
      ));
    }

    // Ordenar pedidos por fecha de recepción, del más reciente al más antiguo
    orders.sort((a, b) => b.fechaRecepcion.compareTo(a.fechaRecepcion));

    return orders;
  }

  Future<void> actualizarEstadoPedido(String orderId, OrderStatus newStatus) async {
    final db = await database;
    await db.update(
      'orders',
      {'status': newStatus.name},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<void> actualizarPedido(Order order) async {
    final db = await database;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    // Actualizar datos del pedido
    await db.update(
      'orders',
      {
        'cliente_id': order.clienteId,
        'fecha_entrega_estim': dateFormat.format(order.fechaEntregaEstim),
        'status': order.status.name,
      },
      where: 'id = ?',
      whereArgs: [order.id],
    );

    // Eliminar items antiguos para reemplazarlos con los nuevos
    await db.delete(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [order.id],
    );

    // Insertar los items actualizados
    for (var item in order.items) {
      await db.insert(
        'order_items',
        {
          'id': item.id,
          'order_id': order.id,
          'tipo': item.tipo.name,
          'tamano': item.tamano.name,
          'ubicacion': item.ubicacion,
          'cantidad': item.cantidad,
          'precio': item.precio,
          'tiempo_estimado_min': item.tiempoEstimadoMin,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // --- Métodos para Tiempos de Producción ---

  Future<void> guardarTiempoProduccion(TiempoProduccion tiempo) async {
    final db = await database;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    await db.insert(
      'tiempos_produccion',
      {
        'id': tiempo.id,
        'order_id': tiempo.orderId,
        'inicio': dateFormat.format(tiempo.inicio),
        'pausa': tiempo.pausa != null ? dateFormat.format(tiempo.pausa!) : null,
        'fin': tiempo.fin != null ? dateFormat.format(tiempo.fin!) : null,
        'duracion_pausas': tiempo.duracionPausas,
        'esta_activo': tiempo.estaActivo ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> actualizarTiempoProduccion(TiempoProduccion tiempo) async {
    final db = await database;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    await db.update(
      'tiempos_produccion',
      {
        'pausa': tiempo.pausa != null ? dateFormat.format(tiempo.pausa!) : null,
        'fin': tiempo.fin != null ? dateFormat.format(tiempo.fin!) : null,
        'duracion_pausas': tiempo.duracionPausas,
        'esta_activo': tiempo.estaActivo ? 1 : 0,
      },
      where: 'order_id = ?',
      whereArgs: [tiempo.orderId],
    );
  }
  // --- MÉTODOS PARA LA CAJA ---

// Obtener la caja de una fecha específica
  Future<CajaDiaria?> obtenerCajaPorFecha(DateTime fecha) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'caja_diaria',
      where: 'fecha = ?',
      whereArgs: [fecha.toIso8601String()],
    );
    if (maps.isNotEmpty) {
      return CajaDiaria.fromMap(maps.first);
    }
    return null;
  }

// Insertar una nueva caja
  Future<void> insertarCaja(CajaDiaria caja) async {
    final db = await database;
    await db.insert(
      'caja_diaria',
      caja.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

// Actualizar una caja existente
  Future<void> actualizarCaja(CajaDiaria caja) async {
    final db = await database;
    await db.update(
      'caja_diaria',
      caja.toMap(),
      where: 'id = ?',
      whereArgs: [caja.id],
    );
  }

// Obtener movimientos de una caja por su ID
  Future<List<MovimientoCaja>> obtenerMovimientosPorCajaId(String cajaId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'movimientos_caja',
      where: 'cajaDiariaId = ?',
      whereArgs: [cajaId],
      orderBy: 'fechaHora DESC',
    );
    return List.generate(maps.length, (i) {
      return MovimientoCaja.fromMap(maps[i]);
    });
  }

// Insertar un nuevo movimiento
  Future<void> insertarMovimiento(MovimientoCaja movimiento) async {
    final db = await database;
    await db.insert(
      'movimientos_caja',
      movimiento.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}