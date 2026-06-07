import 'package:flutter/material.dart';
import 'modelometapres.dart';
import 'metapresupuestoservice.dart';

class ProviderMetaPres with ChangeNotifier {
  final MetaPresService _servicio = MetaPresService();
  List<ModeloMetaPresupuesto> _metas = [];
  bool _isLoading = false;

  List<ModeloMetaPresupuesto> get metas     => _metas;
  bool                        get isLoading => _isLoading;

  Future<void> cargarPresupuestoMensual(String profileId, DateTime mes) async {
    _isLoading = true;
    notifyListeners();
    try {
      _metas = await _servicio.obtenerPorMes(profileId, mes);
    } catch (e) {
      debugPrint('Error cargando presupuesto: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> guardarMeta(ModeloMetaPresupuesto meta) async {
    try {
      final guardado = await _servicio.guardarMeta(meta);
      final indice = _metas.indexWhere(
              (m) => m.categoriaId == meta.categoriaId);
      if (indice != -1) {
        _metas[indice] = guardado;
      } else {
        _metas.add(guardado);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error guardando meta: $e');
      return false;
    }
  }
}