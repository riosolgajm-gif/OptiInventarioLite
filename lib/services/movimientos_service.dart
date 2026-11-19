
import 'package:supabase_flutter/supabase_flutter.dart';

class MovimientosService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==========================================
  // OBTENER PRODUCTOS
  // ==========================================

  Future<List<Map<String, dynamic>>> obtenerProductos() async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      throw Exception('Usuario no autenticado');
    }

    final respuesta = await _supabase
        .from('productos')
        .select('id, nombre, codigo_barras, stock')
        .eq('user_id', usuario.id)
        .order('nombre');

    return List<Map<String, dynamic>>.from(respuesta);
  }

  // ==========================================
  // REGISTRAR MOVIMIENTO
  // ==========================================

  Future<int> registrarMovimiento({
    required String productoId,
    required String tipo,
    required int cantidad,
    String? observacion,
  }) async {
    if (_supabase.auth.currentUser == null) {
      throw Exception('Usuario no autenticado');
    }

    if (cantidad <= 0) {
      throw Exception('La cantidad debe ser mayor que cero');
    }

    final respuesta = await _supabase.rpc(
      'registrar_movimiento',
      params: {
        'p_producto_id': productoId,
        'p_tipo': tipo.toUpperCase(),
        'p_cantidad': cantidad,
        'p_observacion': observacion,
      },
    );

    return (respuesta as num).toInt();
  }

  // ==========================================
  // CONSULTAR HISTORIAL
  // ==========================================

  Future<List<Map<String, dynamic>>> obtenerMovimientos() async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      throw Exception('Usuario no autenticado');
    }

    final respuesta = await _supabase
        .from('movimientos')
        .select('''
          id,
          producto_id,
          tipo,
          cantidad,
          fecha,
          observacion,
          productos(nombre, codigo_barras)
        ''')
        .eq('user_id', usuario.id)
        .order('fecha', ascending: false);

    return List<Map<String, dynamic>>.from(respuesta);
  }
}
