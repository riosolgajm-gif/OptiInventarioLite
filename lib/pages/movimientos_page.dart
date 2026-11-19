
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/movimientos_service.dart';

class MovimientosPage extends StatefulWidget {
  const MovimientosPage({super.key});

  @override
  State<MovimientosPage> createState() => _MovimientosPageState();
}

class _MovimientosPageState extends State<MovimientosPage> {
  static const Color azul = Color(0xFF1765BD);

  final MovimientosService _service = MovimientosService();

  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> movimientos = [];

  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  // ==========================================
  // CARGAR PRODUCTOS E HISTORIAL
  // ==========================================

  Future<void> cargarDatos() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final listaProductos = await _service.obtenerProductos();
      final listaMovimientos = await _service.obtenerMovimientos();

      if (!mounted) return;

      setState(() {
        productos = listaProductos;
        movimientos = listaMovimientos;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        cargando = false;
      });
    }
  }

  // ==========================================
  // REGISTRAR MOVIMIENTO
  // ==========================================

  Future<void> mostrarFormulario() async {
    if (productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero debes registrar un producto'),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();

    final cantidadController = TextEditingController();
    final observacionController = TextEditingController();

    String productoId = productos.first['id'].toString();
    String tipo = 'ENTRADA';
    bool guardando = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (contextDialog, actualizarDialog) {
            final productoSeleccionado = productos.firstWhere(
              (p) => p['id'].toString() == productoId,
            );

            final int stockActual =
                (productoSeleccionado['stock'] as num).toInt();

            return AlertDialog(
              title: const Text(
                'Nuevo movimiento',
                style: TextStyle(
                  color: azul,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 430,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tipo de movimiento',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                selected: tipo == 'ENTRADA',
                                label: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.trending_up, size: 19),
                                    SizedBox(width: 5),
                                    Text('Entrada'),
                                  ],
                                ),
                                selectedColor: Colors.green.shade100,
                                onSelected: guardando
                                    ? null
                                    : (_) {
                                        actualizarDialog(
                                          () => tipo = 'ENTRADA',
                                        );
                                      },
                              ),
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: ChoiceChip(
                                selected: tipo == 'SALIDA',
                                label: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.trending_down, size: 19),
                                    SizedBox(width: 5),
                                    Text('Salida'),
                                  ],
                                ),
                                selectedColor: Colors.red.shade100,
                                onSelected: guardando
                                    ? null
                                    : (_) {
                                        actualizarDialog(
                                          () => tipo = 'SALIDA',
                                        );
                                      },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        DropdownButtonFormField<String>(
                          initialValue: productoId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Producto',
                            prefixIcon: Icon(Icons.inventory_2),
                            border: OutlineInputBorder(),
                          ),
                          items: productos.map((producto) {
                            return DropdownMenuItem<String>(
                              value: producto['id'].toString(),
                              child: Text(
                                producto['nombre'].toString(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: guardando
                              ? null
                              : (valor) {
                                  if (valor != null) {
                                    actualizarDialog(
                                      () => productoId = valor,
                                    );
                                  }
                                },
                        ),

                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F1FC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warehouse_outlined,
                                color: azul,
                              ),
                              const SizedBox(width: 10),
                              const Text('Stock actual:'),
                              const Spacer(),
                              Text(
                                '$stockActual unidades',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: azul,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: cantidadController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Cantidad',
                            prefixIcon: Icon(Icons.numbers),
                            border: OutlineInputBorder(),
                          ),
                          validator: (valor) {
                            if (valor == null || valor.trim().isEmpty) {
                              return 'Ingresa una cantidad';
                            }

                            final cantidad = int.tryParse(valor);

                            if (cantidad == null || cantidad <= 0) {
                              return 'La cantidad debe ser mayor que cero';
                            }

                            if (tipo == 'SALIDA' &&
                                cantidad > stockActual) {
                              return 'Stock insuficiente. Disponible: $stockActual';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: observacionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Observación (opcional)',
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: guardando
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azul,
                    foregroundColor: Colors.white,
                  ),
                  icon: guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    guardando ? 'Guardando...' : 'Registrar',
                  ),
                  onPressed: guardando
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          actualizarDialog(() {
                            guardando = true;
                          });

                          try {
                            final stockNuevo =
                                await _service.registrarMovimiento(
                              productoId: productoId,
                              tipo: tipo,
                              cantidad: int.parse(
                                cantidadController.text,
                              ),
                              observacion:
                                  observacionController.text.trim(),
                            );

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);

                            await cargarDatos();

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '$tipo registrado correctamente. '
                                  'Stock actualizado: $stockNuevo unidades',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            if (!dialogContext.mounted) return;

                            actualizarDialog(() {
                              guardando = false;
                            });

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );

    cantidadController.dispose();
    observacionController.dispose();
  }

  // ==========================================
  // NOMBRE DEL PRODUCTO EN EL HISTORIAL
  // ==========================================

  String obtenerNombreProducto(Map<String, dynamic> movimiento) {
    final producto = movimiento['productos'];

    if (producto is Map) {
      return producto['nombre']?.toString() ?? 'Producto';
    }

    return 'Producto';
  }

  // ==========================================
  // FORMATO DE FECHA
  // ==========================================

  String formatearFecha(dynamic fecha) {
    if (fecha == null) return '';

    final fechaLocal = DateTime.parse(
      fecha.toString(),
    ).toLocal();

    final dia = fechaLocal.day.toString().padLeft(2, '0');
    final mes = fechaLocal.month.toString().padLeft(2, '0');
    final anio = fechaLocal.year;

    final hora = fechaLocal.hour.toString().padLeft(2, '0');
    final minuto = fechaLocal.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio $hora:$minuto';
  }

  // ==========================================
  // INTERFAZ PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: azul,
        foregroundColor: Colors.white,
        title: const Text(
          'Movimientos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: azul,
        foregroundColor: Colors.white,
        onPressed: mostrarFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo movimiento'),
      ),

      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error != null
              ? _mostrarError()
              : _mostrarContenido(),
    );
  }

  // ==========================================
  // MENSAJE DE ERROR
  // ==========================================

  Widget _mostrarError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 45,
            ),
            const SizedBox(height: 12),
            Text(
              error!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: cargarDatos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CONTENIDO
  // ==========================================

  Widget _mostrarContenido() {
    return RefreshIndicator(
      onRefresh: cargarDatos,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _tarjetaResumen(),

          const SizedBox(height: 24),

          const Text(
            'Historial de movimientos',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (movimientos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 55),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 65,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No hay movimientos registrados',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text('Pulsa Nuevo movimiento para comenzar'),
                ],
              ),
            )
          else
            ...movimientos.map(_tarjetaMovimiento),
        ],
      ),
    );
  }

  // ==========================================
  // RESUMEN
  // ==========================================

  Widget _tarjetaResumen() {
    final entradas = movimientos
        .where((m) => m['tipo'] == 'ENTRADA')
        .fold<int>(
          0,
          (total, m) => total + (m['cantidad'] as num).toInt(),
        );

    final salidas = movimientos
        .where((m) => m['tipo'] == 'SALIDA')
        .fold<int>(
          0,
          (total, m) => total + (m['cantidad'] as num).toInt(),
        );

    return Card(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de movimientos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _resumenItem(
                    'Entradas',
                    entradas,
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),

                Expanded(
                  child: _resumenItem(
                    'Salidas',
                    salidas,
                    Colors.red,
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumenItem(
    String titulo,
    int cantidad,
    Color color,
    IconData icono,
  ) {
    return Column(
      children: [
        Icon(icono, color: color, size: 28),
        const SizedBox(height: 6),
        Text(
          titulo,
          style: const TextStyle(color: Colors.grey),
        ),
        Text(
          '$cantidad unidades',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TARJETA DE MOVIMIENTO
  // ==========================================

  Widget _tarjetaMovimiento(Map<String, dynamic> movimiento) {
    final bool esEntrada = movimiento['tipo'] == 'ENTRADA';

    final Color color = esEntrada ? Colors.green : Colors.red;

    final int cantidad = (movimiento['cantidad'] as num).toInt();

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),

        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            esEntrada ? Icons.trending_up : Icons.trending_down,
            color: color,
          ),
        ),

        title: Text(
          obtenerNombreProducto(movimiento),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),

            Text(
              '${movimiento['tipo']} · ${formatearFecha(movimiento['fecha'])}',
            ),

            if ((movimiento['observacion'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                movimiento['observacion'].toString(),
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),

        trailing: Text(
          '${esEntrada ? '+' : '-'}$cantidad',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
      ),
    );
  }
}
