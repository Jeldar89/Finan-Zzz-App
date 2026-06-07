import 'package:supabase_flutter/supabase_flutter.dart';
import 'modelocategoria.dart';

class CategoriaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Trae los 6 tipos con sus categorías anidadas
  Future<List<TipoCategoria>> obtenerTipos() async {
    final respuesta = await _supabase
        .from('tipos_categoria')
        .select()
        .order('orden');

    return (respuesta as List)
        .map((json) => TipoCategoria.fromJson(json))
        .toList();
  }

  // Trae todas las categorías con su tipo incluido (para formulario de transacción)
  Future<List<ModeloCategoria>> obtenerCategorias() async {
    final respuesta = await _supabase
        .from('categorias')
        .select('*, tipos_categoria(id, nombre, es_ingreso, orden)')
        .order('nombre');

    return (respuesta as List)
        .map((json) => ModeloCategoria.fromJson(json))
        .toList();
  }

  // Trae categorías filtradas por tipo
  Future<List<ModeloCategoria>> obtenerCategoriasPorTipo(int tipoId) async {
    final respuesta = await _supabase
        .from('categorias')
        .select('*, tipos_categoria(id, nombre, es_ingreso, orden)')
        .eq('tipo_id', tipoId)
        .order('nombre');

    return (respuesta as List)
        .map((json) => ModeloCategoria.fromJson(json))
        .toList();
  }
}
