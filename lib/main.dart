import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/order_provider.dart';
import 'providers/tiempo_produccion_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pedidos_screen.dart';
import 'screens/produccion_screen.dart';
import 'screens/inventario_screen.dart';
import 'screens/pdf_demo.dart';
import 'providers/producto_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => TiempoProduccionProvider()),
        ChangeNotifierProvider(create: (_) => ProductoProvider()),
      ],
      child: const ControlProduccionApp(),
    ),
  );
}

class ControlProduccionApp extends StatelessWidget {
  const ControlProduccionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Control de Producción',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    PedidosScreen(),
    ProduccionScreen(),
    InventarioScreen(),
  ];

  final List<String> _titles = const [
    "Dashboard",
    "Pedidos",
    "Producción",
    "Inventario",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.precision_manufacturing), label: 'Producción'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Inventario'),
        ],
      ),
    );
  }
}