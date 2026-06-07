import 'package:supabase_flutter/supabase_flutter.dart';

class AutenService {
  final SupabaseClient _supabase = Supabase.instance.client;

  //iniciarSesion
  Future<AuthResponse> iniciarSesion(
      String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // registro
  Future<AuthResponse> registrarse(
      String email, String password) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  //cerrarSesion
  Future<void> cerrarSesion() async {
    await _supabase.auth.signOut();
  }

  //usuarioActual
  User? get usuarioActual => _supabase.auth.currentUser;
}