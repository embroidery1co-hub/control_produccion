import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers/tiempo_produccion_provider.dart';

class TemporizadorScreen extends StatefulWidget {
  final Order order;

  const TemporizadorScreen({super.key, required this.order});

  @override
  State<TemporizadorScreen> createState() => _TemporizadorScreenState();
}

class _TemporizadorScreenState extends State<TemporizadorScreen> {
  Timer? _timer;
  String _tiempoFormateado = '00:00:00';

  @override
  void initState() {
    super.initState();
    final tiempoProvider = Provider.of<TiempoProduccionProvider>(context, listen: false);

    // Iniciar el temporizador si no existe
    if (tiempoProvider.getTiempoPorOrderId(widget.order.id) == null) {
      tiempoProvider.iniciarTemporizador(widget.order.id);
    }

    // Configurar el timer para actualizar la UI cada segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final tiempoProvider = Provider.of<TiempoProduccionProvider>(context, listen: false);
      setState(() {
        _tiempoFormateado = tiempoProvider.getTiempoFormateado(widget.order.id);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiempoProvider = Provider.of<TiempoProduccionProvider>(context);
    final estaActivo = tiempoProvider.estaActivo(widget.order.id);
    final estaPausado = tiempoProvider.estaPausado(widget.order.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Temporizador - Pedido #${widget.order.id.substring(0, 6)}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Información del pedido
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Cliente: ${widget.order.clienteId}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Items: ${widget.order.items.length}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Display del tiempo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: Text(
                _tiempoFormateado,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Botones de control
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón de Iniciar/Reanudar
                ElevatedButton(
                  onPressed: estaPausado || !estaActivo
                      ? () {
                    tiempoProvider.reanudarTemporizador(widget.order.id);
                    setState(() {});
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Text(estaPausado ? 'REANUDAR' : 'INICIAR'),
                ),

                // Botón de Pausar
                ElevatedButton(
                  onPressed: estaActivo
                      ? () {
                    tiempoProvider.pausarTemporizador(widget.order.id);
                    setState(() {});
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('PAUSAR'),
                ),

                // Botón de Terminar
                ElevatedButton(
                  onPressed: estaActivo || estaPausado
                      ? () {
                    tiempoProvider.terminarTemporizador(widget.order.id);
                    Navigator.pop(context);
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('TERMINAR'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Botón para volver
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('VOLVER'),
            ),
          ],
        ),
      ),
    );
  }
}