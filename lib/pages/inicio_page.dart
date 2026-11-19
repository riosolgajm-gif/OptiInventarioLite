
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_page.dart';
import 'productos_page.dart';
import 'movimientos_page.dart';
import 'reportes_page.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  static const Color azul = Color(0xFF1765BD);
  static const Color fondo = Color(0xFFF5F8FD);

  final SupabaseClient _supabase = Supabase.instance.client;

  bool cargando = true;
  String? error;

  int totalProductos = 0;
  int totalExistencias = 0;
  int totalEntradas = 0;
  int totalSalidas = 0;

  List<Map<String, dynamic>> productosBajoMinimo = [];

  String correoUsuario = '';

  @override
  void initState() {
    super.initState();
    cargarResumen();
  }

  // ==========================================
  // CONVERSION SEGURA DE NUMEROS
  // ==========================================

  int convertirNumero(dynamic valor) {
    if (valor == null) return 0;

    if (valor is num) {
      return valor.toInt();
    }

    return int.tryParse(valor.toString()) ?? 0;
  }

  // ==========================================
  // CONSULTAR DATOS DE SUPABASE
  // ==========================================

  Future<void> cargarResumen() async {
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

      // ========================================
      // CONSULTAR PRODUCTOS
      // ========================================

      final respuestaProductos = await _supabase
          .from('productos')
          .select('id, nombre, stock, stock_minimo')
          .eq('user_id', usuario.id);

      final listaProductos =
          List<Map<String, dynamic>>.from(respuestaProductos);

      // ========================================
      // DETECTAR STOCK MINIMO
      // ========================================

      final alertas = listaProductos.where((producto) {
        final stock = convertirNumero(producto['stock']);
        final minimo = convertirNumero(producto['stock_minimo']);

        return stock <= minimo;
      }).toList();

      // ========================================
      // CONTAR PRODUCTOS
      // ========================================

      final cantidadProductos = listaProductos.length;

      // ========================================
      // SUMAR EXISTENCIAS
      // ========================================

      int existencias = 0;

      for (final producto in listaProductos) {
        existencias += convertirNumero(producto['stock']);
      }

      // ========================================
      // CONSULTAR MOVIMIENTOS
      // ========================================

      final respuestaMovimientos = await _supabase
          .from('movimientos')
          .select('tipo, cantidad')
          .eq('user_id', usuario.id);

      final listaMovimientos =
          List<Map<String, dynamic>>.from(respuestaMovimientos);

      // ========================================
      // CALCULAR ENTRADAS Y SALIDAS
      // ========================================

      int entradas = 0;
      int salidas = 0;

      for (final movimiento in listaMovimientos) {
        final cantidad = convertirNumero(movimiento['cantidad']);

        if (movimiento['tipo'] == 'ENTRADA') {
          entradas += cantidad;
        } else if (movimiento['tipo'] == 'SALIDA') {
          salidas += cantidad;
        }
      }

      if (!mounted) return;

      setState(() {
        totalProductos = cantidadProductos;
        totalExistencias = existencias;
        totalEntradas = entradas;
        totalSalidas = salidas;

        productosBajoMinimo = alertas;

        correoUsuario = usuario.email ?? 'Usuario';

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
  // CERRAR SESION
  // ==========================================

  Future<void> cerrarSesion() async {
    try {
      await _supabase.auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==========================================
  // TARJETAS DEL DASHBOARD
  // ==========================================

  Widget tarjetaResumen({
    required IconData icono,
    required String titulo,
    required int valor,
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
            const SizedBox(height: 5),
            Text(
              valor.toString(),
              style: TextStyle(
                fontSize: 27,
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
  // NAVEGACION ENTRE MODULOS
  // ==========================================

  void navegarModulo(BuildContext context, String titulo) {
    Widget? pagina;

    if (titulo == 'Productos') {
      pagina = const ProductosPage();
    } else if (titulo == 'Movimientos') {
      pagina = const MovimientosPage();
    } else if (titulo == 'Reportes') {
      pagina = const ReportesPage();
    }

    if (pagina == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => pagina!,
      ),
    ).then((_) {
      if (mounted) {
        cargarResumen();
      }
    });
  }

  // ==========================================
  // ACCESOS A LOS MODULOS
  // ==========================================

  Widget acceso({
    required IconData icono,
    required String titulo,
    required String descripcion,
  }) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),

        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8F1FC),
          child: Icon(
            icono,
            color: azul,
          ),
        ),

        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Text(descripcion),

        trailing: const Icon(
          Icons.chevron_right,
        ),

        onTap: () => navegarModulo(context, titulo),
      ),
    );
  }

  // ==========================================
  // ALERTAS DE STOCK MINIMO
  // ==========================================

  Widget mostrarAlertas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 27,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Alertas de stock mínimo',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            CircleAvatar(
              radius: 19,
              backgroundColor: productosBajoMinimo.isEmpty
                  ? Colors.green.shade50
                  : Colors.orange.shade100,
              child: Text(
                productosBajoMinimo.length.toString(),
                style: TextStyle(
                  color: productosBajoMinimo.isEmpty
                      ? Colors.green
                      : Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (productosBajoMinimo.isEmpty)
          Card(
            color: Colors.green.shade50,
            elevation: 1,
            child: const ListTile(
              leading: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 32,
              ),
              title: Text(
                'Todo en orden',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'No hay productos con stock mínimo.',
              ),
            ),
          )
        else
          ...productosBajoMinimo.map((producto) {
            final stock = convertirNumero(producto['stock']);
            final minimo =
                convertirNumero(producto['stock_minimo']);

            return Card(
              color: Colors.orange.shade50,
              elevation: 1,
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
                  'Stock actual: $stock | Mínimo: $minimo',
                ),
              ),
            );
          }),
      ],
    );
  }

  // ==========================================
  // DASHBOARD
  // ==========================================

  Widget mostrarDashboard() {
    final ancho = MediaQuery.of(context).size.width;

    return RefreshIndicator(
      onRefresh: cargarResumen,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // BIENVENIDA

          Text(
            '¡Bienvenido!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: azul,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            correoUsuario,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 25),

          // RESUMEN

          const Text(
            'Resumen de inventario',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: ancho > 900
                ? 4
                : ancho > 550
                    ? 4
                    : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: ancho > 900 ? 1.5 : 1.25,
            children: [
              tarjetaResumen(
                icono: Icons.inventory_2_outlined,
                titulo: 'Productos',
                valor: totalProductos,
                color: azul,
              ),

              tarjetaResumen(
                icono: Icons.warehouse_outlined,
                titulo: 'Existencias',
                valor: totalExistencias,
                color: azul,
              ),

              tarjetaResumen(
                icono: Icons.trending_up,
                titulo: 'Entradas',
                valor: totalEntradas,
                color: Colors.green,
              ),

              tarjetaResumen(
                icono: Icons.trending_down,
                titulo: 'Salidas',
                valor: totalSalidas,
                color: Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ALERTAS

          mostrarAlertas(),

          const SizedBox(height: 28),

          // GESTION DE INVENTARIO

          const Text(
            'Gestión de inventario',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          acceso(
            icono: Icons.inventory_2,
            titulo: 'Productos',
            descripcion: 'Registrar y consultar productos',
          ),

          acceso(
            icono: Icons.swap_horiz,
            titulo: 'Movimientos',
            descripcion: 'Registrar entradas y salidas',
          ),

          acceso(
            icono: Icons.bar_chart,
            titulo: 'Reportes',
            descripcion: 'Consultar información del inventario',
          ),

          const SizedBox(height: 15),

          Center(
            child: TextButton.icon(
              onPressed: cargarResumen,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar información'),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // INTERFAZ PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,

      appBar: AppBar(
        backgroundColor: azul,
        foregroundColor: Colors.white,

        title: const Text(
          'OptiInventario Lite',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: cerrarSesion,
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
                          'No se pudo cargar el inventario',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          error!,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 15),

                        ElevatedButton.icon(
                          onPressed: cargarResumen,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : mostrarDashboard(),
    );
  }
}
