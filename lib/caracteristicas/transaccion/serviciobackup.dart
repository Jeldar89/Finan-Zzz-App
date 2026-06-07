import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../transaccion/serviciostransaccion.dart';
import '../presupuesto/metapresupuestoservice.dart';

class ServicioBackup {
  final ServiciosTrans _servicioTrans = ServiciosTrans();
  final MetaPresService _servicioMetas = MetaPresService();

  Future<File> exportarDatosUsuarioAJson(String profileId) async {
    // 1. Recopilar todos los datos del usuario
    final transacciones =
    await _servicioTrans.obtenerTodasLasTransacciones(profileId);
    final metas = await _servicioMetas.obtenerTodasLasMetas(profileId);

    // 2. Crear la estructura del respaldo
    final Map<String, dynamic> datosRespaldo = {
      'timestamp': DateTime.now().toIso8601String(),
      'profile_id': profileId,
      'transactions': transacciones.map((t) => t.toJson()).toList(),
      'budget_goals': metas.map((m) => m.toJson()).toList(),
    };

    // 3. Convertir a String JSON
    final String jsonString = jsonEncode(datosRespaldo);

    // 4. Guardar en el almacenamiento local del dispositivo
    final directorio = await getApplicationDocumentsDirectory();
    final archivo = File(
        '${directorio.path}/finanzas_respaldo_${DateTime.now().millisecondsSinceEpoch}.json');

    return await archivo.writeAsString(jsonString);
  }
}