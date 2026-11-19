
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // REGISTRAR USUARIO
  Future<AuthResponse> registrar({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  // INICIAR SESION
  Future<AuthResponse> iniciarSesion({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  // CERRAR SESION
  Future<void> cerrarSesion() async {
    await _supabase.auth.signOut();
  }

  // RECUPERAR CONTRASEÑA
  Future<void> recuperarPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
    );
  }

  // USUARIO ACTUAL
  User? get usuarioActual {
    return _supabase.auth.currentUser;
  }

  // VERIFICAR SESION
  bool get tieneSesion {
    return _supabase.auth.currentSession != null;
  }
}
