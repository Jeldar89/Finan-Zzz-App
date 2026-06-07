import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'autenservice.dart';

class Autenprovider with ChangeNotifier {

  final AutenService _servicioAuten = AutenService();
  bool _isLoading = false;
  String? _mensajeError;
  bool get isLoading => _isLoading;
  String? get mensajeError => _mensajeError;

  Future<bool> registrarse(String email, String password) async {
    _isLoading = true;
    _mensajeError = null;
    notifyListeners();
    try {
      await _servicioAuten.registrarse(email, password);
      return true;
    } catch (e) {
      _mensajeError = 'Error al registrar: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // iniciarSesion
  Future<bool> iniciarSesion(String email, String password) async {
    _isLoading = true;
    _mensajeError = null;
    notifyListeners();

    try {
      // _servicioAuten.iniciarSesion
      await _servicioAuten.iniciarSesion(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _mensajeError = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // cerrarSesion al resto de la app (DashboardScreen)
  Future<void> cerrarSesion() async {
    await _servicioAuten.cerrarSesion();
    notifyListeners();
  }
}