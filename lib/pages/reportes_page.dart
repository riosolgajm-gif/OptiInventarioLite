
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  static const Color azul = Color(0xFF1765BD);

  final SupabaseClient _supabase = Supabase.instance.client;

  bool cargando = true;
  String? error;

  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> movimientos = [];

  int totalProductos = 0;
  int totalExistencias = 0;
  int totalEntradas = 0;
  int totalSalidas = 0;

  double valorCosto = 0;
  double valorVenta = 0;

  List<Map<String, dynamic>> productosBajoMinimo = [];

  @override
  void initState() {
    super.initState();
    cargarReportes();
  }

  // ==========================================
  // CONVERSION SEGURA DE NUMEROS
  // ==========================================

  double numero(dynamic valor) {
    if (valor == null) return 0;

    if (valor is num) {
      return valor.toDouble();
    }

    return double.tryParse(valor.toString()) ?? 0;
  }

  String dinero(double valor) {
    return '\$${valor.toStringAsFixed(2)}';
  }

  // ==========================================
  // CARGAR INFORMACION DE SUPABASE
  // ==========================================

  Future<void> cargarReportes() async {
    if (!mounted) return;

    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final usuario = _supabase.auth.currentUser;

      if (usuario == null) {
        throw Exception('No hay un usuario autenticado');
      }

      // CONSULTAR PRODUCTOS

      final respuestaProductos = await _supabase
          .from('productos')
          .select(
            'id, nombre, categoria, precio_compra, '
            'precio_venta, stock, stock_minimo',
          )
          .eq('user_id', usuario.id);

      final listaProductos =
          List<Map<String, dynamic>>.from(respuestaProductos);

      // CONSULTAR MOVIMIENTOS

      final respuestaMovimientos = await _supabase
          .from('movimientos')
          .select(
            'id, producto_id, tipo, cantidad, fecha, observacion',
          )
          .eq('user_id', usuario.id);

      final listaMovimientos =
          List<Map<String, dynamic>>.from(respuestaMovimientos);

      // CALCULAR INDICADORES

      int existencias = 0;
      int entradas = 0;
      int salidas = 0;

      double costo = 0;
      double venta = 0;

      for (final producto in listaProductos) {
        final stock = numero(producto['stock']);

        final precioCompra = numero(producto['precio_compra']);
        final precioVenta = numero(producto['precio_venta']);

        existencias += stock.toInt();

        costo += stock * precioCompra;
        venta += stock * precioVenta;
      }

      for (final movimiento in listaMovimientos) {
        final cantidad = numero(movimiento['cantidad']).toInt();

        if (movimiento['tipo'] == 'ENTRADA') {
          entradas += cantidad;
        } else if (movimiento['tipo'] == 'SALIDA') {
          salidas += cantidad;
        }
      }

      // PRODUCTOS CON STOCK MINIMO

      final alertas = listaProductos.where((producto) {
        final stock = numero(producto['stock']);
        final minimo = numero(producto['stock_minimo']);

        return stock <= minimo;
      }).toList();

      // ORDENAR MOVIMIENTOS POR FECHA

      listaMovimientos.sort((a, b) {
        final fechaA =
            DateTime.tryParse(a['fecha']?.toString() ?? '') ??
                DateTime(2000);

        final fechaB =
            DateTime.tryParse(b['fecha']?.toString() ?? '') ??
                DateTime(2000);

        return fechaB.compareTo(fechaA);
      });

      if (!mounted) return;

      setState(() {
        productos = listaProductos;
        movimientos = listaMovimientos;

        totalProductos = listaProductos.length;
        totalExistencias = existencias;
        totalEntradas = entradas;
        totalSalidas = salidas;

        valorCosto = costo;
        valorVenta = venta;

        productosBajoMinimo = alertas;

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
  // TARJETA DE INDICADORES
  // ==========================================

  Widget tarjeta({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
  }) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              color: color,
              size: 30,
            ),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              valor,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SECCION DE VALORIZACION
  // ==========================================

  Widget seccionValorizacion() {
    return Card(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Valorización del inventario',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            filaValor(
              'Valor total al costo',
              dinero(valorCosto),
              azul,
            ),
            const Divider(height: 25),
            filaValor(
              'Valor total a precio de venta',
              dinero(valorVenta),
              Colors.green,
            ),
            const Divider(height: 25),
            filaValor(
              'Margen potencial',
              dinero(valorVenta - valorCosto),
              Colors.deepPurple,
            ),
          ],
        ),
      ),
    );
  }

  Widget filaValor(
    String titulo,
    String valor,
    Color color,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // PRODUCTOS CON STOCK BAJO
  // ==========================================

  Widget seccionStockBajo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Productos con stock mínimo',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (productosBajoMinimo.isEmpty)
          Card(
            color: Colors.green.shade50,
            child: const ListTile(
              leading: Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              title: Text(
                'Inventario en buen estado',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'No hay productos por debajo del mínimo.',
              ),
            ),
          )
        else
          ...productosBajoMinimo.map((producto) {
            return Card(
              color: Colors.orange.shade50,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.deepOrange,
                  size: 30,
                ),
                title: Text(
                  producto['nombre'].toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Stock: ${numero(producto['stock']).toInt()}'
                  ' | Mínimo: ${numero(producto['stock_minimo']).toInt()}',
                ),
              ),
            );
          }),
      ],
    );
  }

  // ==========================================
  // DETALLE DE PRODUCTOS
  // ==========================================

  Widget seccionProductos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detalle del inventario',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (productos.isEmpty)
          const Text('No hay productos registrados.')
        else
          ...productos.map((producto) {
            final stock = numero(producto['stock']);
            final precioCompra = numero(producto['precio_compra']);
            final precioVenta = numero(producto['precio_venta']);

            return Card(
              color: Colors.white,
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto['nombre'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Categoría: ${producto['categoria'] ?? 'General'}',
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Stock: ${stock.toInt()} unidades',
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Compra: ${dinero(precioCompra)}'
                      '   Venta: ${dinero(precioVenta)}',
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Valor en inventario: ${dinero(stock * precioCompra)}',
                      style: const TextStyle(
                        color: azul,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ==========================================
  // HISTORIAL DE MOVIMIENTOS
  // ==========================================

  Widget seccionMovimientos() {
    final mapaProductos = {
      for (final producto in productos)
        producto['id'].toString(): producto['nombre'].toString(),
    };

    final recientes = movimientos.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Últimos movimientos',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (recientes.isEmpty)
          const Text('No hay movimientos registrados.')
        else
          ...recientes.map((movimiento) {
            final tipo = movimiento['tipo'].toString();

            final esEntrada = tipo == 'ENTRADA';

            final cantidad =
                numero(movimiento['cantidad']).toInt();

            final productoId =
                movimiento['producto_id'].toString();

            final nombreProducto =
                mapaProductos[productoId] ?? 'Producto';

            final fecha = DateTime.tryParse(
              movimiento['fecha']?.toString() ?? '',
            );

            final fechaTexto = fecha == null
                ? 'Fecha no disponible'
                : '${fecha.toLocal().day.toString().padLeft(2, '0')}/'
                  '${fecha.toLocal().month.toString().padLeft(2, '0')}/'
                  '${fecha.toLocal().year} '
                  '${fecha.toLocal().hour.toString().padLeft(2, '0')}:'
                  '${fecha.toLocal().minute.toString().padLeft(2, '0')}';

            return Card(
              color: Colors.white,
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  esEntrada
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: esEntrada ? Colors.green : Colors.red,
                  size: 30,
                ),
                title: Text(
                  nombreProducto,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '$tipo • $fechaTexto',
                ),
                trailing: Text(
                  '${esEntrada ? '+' : '-'}$cantidad',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: esEntrada ? Colors.green : Colors.red,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  // ==========================================
  // PANTALLA PRINCIPAL
  // ==========================================

  Widget mostrarReporte() {
    final ancho = MediaQuery.of(context).size.width;

    return RefreshIndicator(
      onRefresh: cargarReportes,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Resumen de reportes',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: azul,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Información general de tu inventario',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),

          // INDICADORES

          GridView.count(
            crossAxisCount: ancho > 900 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: ancho > 900 ? 1.6 : 1.35,
            children: [
              tarjeta(
                titulo: 'Productos',
                valor: totalProductos.toString(),
                icono: Icons.inventory_2,
                color: azul,
              ),
              tarjeta(
                titulo: 'Existencias',
                valor: totalExistencias.toString(),
                icono: Icons.warehouse,
                color: azul,
              ),
              tarjeta(
                titulo: 'Entradas',
                valor: totalEntradas.toString(),
                icono: Icons.trending_up,
                color: Colors.green,
              ),
              tarjeta(
                titulo: 'Salidas',
                valor: totalSalidas.toString(),
                icono: Icons.trending_down,
                color: Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 28),

          seccionValorizacion(),

          const SizedBox(height: 28),

          seccionStockBajo(),

          const SizedBox(height: 28),

          seccionProductos(),

          const SizedBox(height: 28),

          seccionMovimientos(),

          const SizedBox(height: 20),

          Center(
            child: TextButton.icon(
              onPressed: cargarReportes,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar reportes'),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // INTERFAZ
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FD),
      appBar: AppBar(
        backgroundColor: azul,
        foregroundColor: Colors.white,
        title: const Text(
          'Reportes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: cargarReportes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(
                color: azul,
              ),
            )
          : error != null
              ? Center(
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
                        const Text(
                          'No se pudieron cargar los reportes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton.icon(
                          onPressed: cargarReportes,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : mostrarReporte(),
    );
  }
}
