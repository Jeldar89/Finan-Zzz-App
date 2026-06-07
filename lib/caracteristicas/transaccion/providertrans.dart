import 'package:flutter/material.dart';
import 'modelotrans.dart';
import 'serviciostransaccion.dart';

// ChangeNotifier hace que las clases puedan avisar cuando algo cambie
class ProviderTrans with ChangeNotifier {
  final ServiciosTrans _servicio = ServiciosTrans();

  List<ModeloTrans> _trans = [];
  bool _isLoading = false;
  int _paginaActual = 0;
  bool _hayMasDatos = true;

  List<ModeloTrans> get transacciones => _trans;
  bool get isLoading => _isLoading;
  bool get hayMasDatos => _hayMasDatos;

  Future<void> cargarTransaccionesMensuales(
      String profileId, DateTime mes) async {
    _isLoading = true;
    notifyListeners();

    try {
      final inicio = DateTime(mes.year, mes.month, 1);
      final fin = DateTime(mes.year, mes.month + 1, 0, 23, 59, 59);
      _trans = await _servicio.obtenerPorMes(profileId, inicio, fin);
    } catch (e) {
      debugPrint('Error cargando transacciones: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarMasTransacciones(String profileId) async {
    if (!_hayMasDatos || _isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final nuevosElementos =
      await _servicio.obtenerTransaccionesPaginadas(
        profileId: profileId,
        pagina: _paginaActual,
      );

      if (nuevosElementos.isEmpty) {
        _hayMasDatos = false;
      } else {
        _trans.addAll(nuevosElementos);
        _paginaActual++;
      }
    } catch (e) {
      debugPrint('Error en paginación: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> guardarTransaccion(ModeloTrans tx) async {
    try {
      final txGuardado = await _servicio.guardarTransaccion(tx);
      _trans.insert(0, txGuardado);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error guardando: $e');
      return false;
    }
  }
}
