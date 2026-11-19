
import 'package:flutter/material.dart';
import '../services/productos_service.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  static const Color azul = Color(0xFF1765BD);

  final ProductosService _service = ProductosService();
  final TextEditingController _buscarController = TextEditingController();

  List<Map<String, dynamic>> productos = [];
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarProductos();
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  // ==========================================
  // CARGAR PRODUCTOS
  // ==========================================

  Future<void> cargarProductos({String texto = ''}) async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final resultado = texto.trim().isEmpty
          ? await _service.obtenerProductos()
          : await _service.buscarProductos(texto);

      if (!mounted) return;

      setState(() {
        productos = resultado;
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
  // FORMULARIO DE PRODUCTO
  // ==========================================

  Future<void> mostrarFormulario({
    Map<String, dynamic>? producto,
  }) async {
    final formKey = GlobalKey<FormState>();

    final codigoController = TextEditingController(
      text: producto?['codigo_barras']?.toString() ?? '',
    );
    final nombreController = TextEditingController(
      text: producto?['nombre']?.toString() ?? '',
    );
    final categoriaController = TextEditingController(
      text: producto?['categoria']?.toString() ?? 'General',
    );
    final compraController = TextEditingController(
      text: producto?['precio_compra']?.toString() ?? '0',
    );
    final ventaController = TextEditingController(
      text: producto?['precio_venta']?.toString() ?? '0',
    );
    final stockController = TextEditingController(
      text: producto?['stock']?.toString() ?? '0',
    );
    final minimoController = TextEditingController(
      text: producto?['stock_minimo']?.toString() ?? '0',
    );
    final descripcionController = TextEditingController(
      text: producto?['descripcion']?.toString() ?? '',
    );

    bool guardando = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (contextDialog, actualizarDialog) {
            return AlertDialog(
              title: Text(
                producto == null ? 'Nuevo producto' : 'Editar producto',
                style: const TextStyle(
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
                      children: [
                        _campo(
                          codigoController,
                          'Código de barras',
                          Icons.qr_code,
                        ),
                        _campo(
                          nombreController,
                          'Nombre del producto',
                          Icons.inventory_2,
                        ),
                        _campo(
                          categoriaController,
                          'Categoría',
                          Icons.category,
                        ),
                        _campo(
                          compraController,
                          'Precio de compra',
                          Icons.attach_money,
                          numero: true,
                        ),
                        _campo(
                          ventaController,
                          'Precio de venta',
                          Icons.sell,
                          numero: true,
                        ),
                        _campo(
                          stockController,
                          'Stock actual',
                          Icons.warehouse,
                          numero: true,
                          entero: true,
                        ),
                        _campo(
                          minimoController,
                          'Stock mínimo',
                          Icons.warning_amber,
                          numero: true,
                          entero: true,
                        ),
                        TextFormField(
                          controller: descripcionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Descripción (opcional)',
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azul,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: guardando
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          actualizarDialog(() => guardando = true);

                          try {
                            if (producto == null) {
                              await _service.registrarProducto(
                                codigoBarras: codigoController.text,
                                nombre: nombreController.text,
                                categoria: categoriaController.text,
                                precioCompra: double.parse(
                                  compraController.text.replaceAll(',', '.'),
                                ),
                                precioVenta: double.parse(
                                  ventaController.text.replaceAll(',', '.'),
                                ),
                                stock: int.parse(stockController.text),
                                stockMinimo: int.parse(minimoController.text),
                                descripcion: descripcionController.text,
                              );
                            } else {
                              await _service.actualizarProducto(
                                id: producto['id'].toString(),
                                codigoBarras: codigoController.text,
                                nombre: nombreController.text,
                                categoria: categoriaController.text,
                                precioCompra: double.parse(
                                  compraController.text.replaceAll(',', '.'),
                                ),
                                precioVenta: double.parse(
                                  ventaController.text.replaceAll(',', '.'),
                                ),
                                stock: int.parse(stockController.text),
                                stockMinimo: int.parse(minimoController.text),
                                descripcion: descripcionController.text,
                              );
                            }

                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);

                            await cargarProductos(
                              texto: _buscarController.text,
                            );

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  producto == null
                                      ? 'Producto registrado correctamente'
                                      : 'Producto actualizado correctamente',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            if (!dialogContext.mounted) return;

                            actualizarDialog(() => guardando = false);

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(producto == null ? 'Guardar' : 'Actualizar'),
                ),
              ],
            );
          },
        );
      },
    );

    codigoController.dispose();
    nombreController.dispose();
    categoriaController.dispose();
    compraController.dispose();
    ventaController.dispose();
    stockController.dispose();
    minimoController.dispose();
    descripcionController.dispose();
  }

  // ==========================================
  // CAMPOS DEL FORMULARIO
  // ==========================================

  Widget _campo(
    TextEditingController controller,
    String etiqueta,
    IconData icono, {
    bool numero = false,
    bool entero = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: numero
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: etiqueta,
          prefixIcon: Icon(icono),
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Este campo es obligatorio';
          }

          if (numero) {
            final valor = double.tryParse(
              value.trim().replaceAll(',', '.'),
            );

            if (valor == null || !valor.isFinite || valor < 0) {
              return 'Ingresa un número válido';
            }

            if (entero && !RegExp(r'^\d+$').hasMatch(value.trim())) {
              return 'Ingresa un número entero';
            }
          }

          return null;
        },
      ),
    );
  }

  // ==========================================
  // ELIMINAR PRODUCTO
  // ==========================================

  Future<void> eliminarProducto(Map<String, dynamic> producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Deseas eliminar "${producto['nombre']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _service.eliminarProducto(producto['id'].toString());

      if (!mounted) return;

      await cargarProductos(texto: _buscarController.text);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto eliminado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          'Productos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: azul,
        foregroundColor: Colors.white,
        onPressed: () => mostrarFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _buscarController,
              onChanged: (texto) => cargarProductos(texto: texto),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o código de barras',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _buscarController.clear();
                    cargarProductos();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _contenidoProductos(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LISTADO DE PRODUCTOS
  // ==========================================

  Widget _contenidoProductos() {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 45),
              const SizedBox(height: 12),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => cargarProductos(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (productos.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => cargarProductos(texto: _buscarController.text),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Icon(
              Icons.inventory_2_outlined,
              size: 75,
              color: Colors.grey,
            ),
            SizedBox(height: 15),
            Center(
              child: Text(
                'No hay productos registrados',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.grey,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text('Utiliza el botón Nuevo producto'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => cargarProductos(texto: _buscarController.text),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        itemCount: productos.length,
        itemBuilder: (context, index) {
          final producto = productos[index];

          final int stock = (producto['stock'] as num).toInt();
          final int minimo = (producto['stock_minimo'] as num).toInt();
          final bool stockBajo = stock <= minimo;

          return Card(
            color: Colors.white,
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFE8F1FC),
                        child: const Icon(
                          Icons.inventory_2,
                          color: azul,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              producto['nombre']?.toString() ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              producto['categoria']?.toString() ?? '',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (opcion) {
                          if (opcion == 'editar') {
                            mostrarFormulario(producto: producto);
                          } else if (opcion == 'eliminar') {
                            eliminarProducto(producto);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'editar',
                            child: Text('Editar'),
                          ),
                          PopupMenuItem(
                            value: 'eliminar',
                            child: Text('Eliminar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    'Código: ${producto['codigo_barras']}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    children: [
                      Text(
                        'Compra: \$${producto['precio_compra']}',
                      ),
                      Text(
                        'Venta: \$${producto['precio_venta']}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Stock: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$stock unidades',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: stockBajo ? Colors.red : Colors.green,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Mínimo: $minimo',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  if (stockBajo) ...[
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Colors.red,
                          size: 18,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Stock bajo',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if ((producto['descripcion'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      producto['descripcion'].toString(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
