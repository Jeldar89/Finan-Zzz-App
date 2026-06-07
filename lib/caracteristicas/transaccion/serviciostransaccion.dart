import 'package:supabase_flutter/supabase_flutter.dart';
import 'modelotrans.dart';

//Así se obtiene nombre y esIngreso de cada transacción directamente
const String _joinCompleto =
    '*, categorias(id, nombre, tipo_id, tipos_categoria(id, nombre, es_ingreso, orden))';

class ServiciosTrans {
  final SupabaseClient _supabase = Supabase.instance.client;

  //READ deTransacciones de un mes (dashboard)
  Future<List<ModeloTrans>> obtenerPorMes(
      String profileId, DateTime inicio, DateTime fin) async {
    final respuesta = await _supabase
        .from('transacciones')
        .select(_joinCompleto)
        .eq('profile_id', profileId)
        .gte('fecha', inicio.toIso8601String().split('T')[0])
        .lte('fecha', fin.toIso8601String().split('T')[0])
        .order('fecha', ascending: false);

    return (respuesta as List)
        .map((json) => ModeloTrans.fromJson(json))
        .toList();
  }

  //READ de historial completo
  Future<List<ModeloTrans>> obtenerTransaccionesPaginadas({
    required String profileId,
    required int pagina,
    int elementosPorPagina = 20,
  }) async {
    final int desde = pagina * elementosPorPagina;
    final int hasta = desde + elementosPorPagina - 1;

    final respuesta = await _supabase
        .from('transacciones')
        .select(_joinCompleto)
        .eq('profile_id', profileId)
        .order('fecha', ascending: false)
        .range(desde, hasta);

    return (respuesta as List)
        .map((json) => ModeloTrans.fromJson(json))
        .toList();
  }

  //UPSERT
  Future<ModeloTrans> guardarTransaccion(ModeloTrans tx) async {
    final respuesta = await _supabase
        .from('transacciones')
        .upsert(tx.toJson())
        .select(_joinCompleto)
        .single();

    return ModeloTrans.fromJson(respuesta);
  }

  //DELETE
  Future<void> eliminarTransaccion(int id) async {
    await _supabase.from('transacciones').delete().eq('id', id);
  }

  //READ: Todas
  Future<List<ModeloTrans>> obtenerTodasLasTransacciones(
      String profileId) async {
    final respuesta = await _supabase
        .from('transacciones')
        .select(_joinCompleto)
        .eq('profile_id', profileId)
        .order('fecha', ascending: false);

    return (respuesta as List)
        .map((json) => ModeloTrans.fromJson(json))
        .toList();
  }
}
