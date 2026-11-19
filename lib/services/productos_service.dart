
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductosService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==========================================
  // OBTENER PRODUCTOS DEL USUARIO
  // ==========================================

  Future<List<Map<String, dynamic>>> obtenerProductos() async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      throw Exception('No hay un usuario autenticado');
    }

    final respuesta = await _supabase
        .from('productos')
        .select()
        .eq('user_id', usuario.id)
        .order('nombre');

    return List<Map<String, dynamic>>.from(respuesta);
  }

  // ==========================================
  // REGISTRAR PRODUCTO
  // ==========================================

  Future<void> registrarProducto({
    required String codigoBarras,
    required String nombre,
    required String categoria,
    required double precioCompra,
    required double precioVenta,
    required int stock,
    required int stockMinimo,
    String? descripcion,
  }) async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      throw Exception('No hay un usuario autenticado');
    }

    await _supabase.from('productos').insert({
      'user_id': usuario.id,
      'codigo_barras': codigoBarras.trim(),
      'nombre': nombre.trim(),
      'categoria': categoria.trim(),
      'precio_compra': precioCompra,
      'precio_venta': precioVenta,
      'stock': stock,
      'stock_minimo': stockMinimo,
      'descripcion': descripcion?.trim(),
    });
  }

  // ==========================================
  // ACTUALIZAR PRODUCTO
  // ==========================================

  Future<void> actualizarProducto({
    required String id,
    required String codigoBarras,
    required String nombre,
    required String categoria,
    required double precioCompra,
    required double precioVenta,
    required int stock,
    required int stockMinimo,
    String? descripcion,
  }) async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      throw Exception('No hay un usuario autenticado');
    }

    await _supabase
        .from('productos')
        .update({
          'codigo_barras': codigoBarras.trim(),
          'nombre': nombre.trim(),
          'categoria': categoria.trim(),
          'precio_compra': precioCompra,
          'precio_venta': precioVenta,
          'stock': stock,
          'stock_minimo': stockMinimo,
          'descripcion': descripcion?.trim(),
        })
        .eq('id', id)
        .eq('user_id', usuario.id);
  }

  // ==========================================
  // ELIMINAR PRODUCTO
  // ==========================================

  Future<void> eliminarProducto(String id) async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      throw Exception('No hay un usuario autenticado');
    }

    await _supabase
        .from('productos')
        .delete()
        .eq('id', id)
        .eq('user_id', usuario.id);
  }

  // ==========================================
  // BUSCAR PRODUCTOS
  // ==========================================

  Future<List<Map<String, dynamic>>> buscarProductos(
    String texto,
  ) async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      throw Exception('No hay un usuario autenticado');
    }

    final busqueda = texto.trim();

    final respuesta = await _supabase
        .from('productos')
        .select()
        .eq('user_id', usuario.id)
        .or(
          'nombre.ilike.%$busqueda%,codigo_barras.ilike.%$busqueda%',
        )
        .order('nombre');

    return List<Map<String, dynamic>>.from(respuesta);
  }
}
