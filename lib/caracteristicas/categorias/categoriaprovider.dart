import 'package:flutter/material.dart';
import 'modelocategoria.dart';
import 'categoriaservice.dart';

class CategoriaProvider with ChangeNotifier {
  final CategoriaService _servicio = CategoriaService();

  //(DashboardProvider y FormScreenTrans)
  List<TipoCategoria>   _tipos      = [];
  List<ModeloCategoria> _categorias = [];
  bool _isLoading = false;
  List<TipoCategoria>   get tipos      => _tipos;
  List<ModeloCategoria> get categorias => _categorias;
  bool get isLoading => _isLoading;

  //Filtro por tipo para formscreentrans
  List<ModeloCategoria> categoriasPorTipo(int tipoId) =>
      _categorias.where((c) => c.tipoId == tipoId).toList();

  Future<void> inicializarCatalogo() async {
    if (_categorias.isNotEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      //obtenerTipos() y obtenerCategorias() ejecutar en paralelo.
      final resultados = await Future.wait([
        _servicio.obtenerTipos(),
        _servicio.obtenerCategorias(),
      ]);
      _tipos      = resultados[0] as List<TipoCategoria>;
      _categorias = resultados[1] as List<ModeloCategoria>;
    } catch (e) {
      debugPrint('Error inicializando catálogo: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}