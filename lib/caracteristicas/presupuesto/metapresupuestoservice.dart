import 'package:supabase_flutter/supabase_flutter.dart';
import 'modelometapres.dart';

const String _joinMeta =
    '*, categorias(id, nombre, tipo_id, tipos_categoria(id, es_ingreso))';

class MetaPresService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ModeloMetaPresupuesto>> obtenerPorMes(
      String profileId, DateTime mes) async {
    final String cadenaPeriodo =
        "${mes.year}-${mes.month.toString().padLeft(2, '0')}-01";
    final respuesta = await _supabase
        .from('metas_presupuesto')
        .select(_joinMeta)
        .eq('profile_id', profileId)
        .eq('mes_periodo', cadenaPeriodo);
    return (respuesta as List)
        .map((json) => ModeloMetaPresupuesto.fromJson(json))
        .toList();
  }
  Future<ModeloMetaPresupuesto> guardarMeta(
      ModeloMetaPresupuesto meta) async {
    final respuesta = await _supabase
        .from('metas_presupuesto')
        .upsert(meta.toJson(),
        onConflict: 'profile_id,categoria_id,mes_periodo')
        .select(_joinMeta)
        .single();
    return ModeloMetaPresupuesto.fromJson(respuesta);
  }

  Future<List<ModeloMetaPresupuesto>> obtenerTodasLasMetas(
      String profileId) async {
    final respuesta = await _supabase
        .from('metas_presupuesto')
        .select(_joinMeta)
        .eq('profile_id', profileId);
    return (respuesta as List)
        .map((json) => ModeloMetaPresupuesto.fromJson(json))
        .toList();
  }
}
