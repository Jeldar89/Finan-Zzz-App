// Gestiona el historial de conversación y el contexto financiero opcional.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';

/// Representa un mensaje dentro del hilo de conversación.
class MensajeChat {
  final String rol; // "user" | "assistant"
  final String contenido;
  final DateTime timestamp;

  const MensajeChat({
    required this.rol,
    required this.contenido,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'rol': rol,
        'contenido': contenido,
      };
}

/// Datos financieros del usuario como contexto en el prompt.
class ContextoFinanciero {
  final double? balanceActual;
  final String moneda;
  final List<TransaccionResumen> ultimasTransacciones;
  final List<PresupuestoResumen> presupuestosMensuales;

  const ContextoFinanciero({
    this.balanceActual,
    this.moneda = 'MXN',
    this.ultimasTransacciones = const [],
    this.presupuestosMensuales = const [],
  });

  Map<String, dynamic> toJson() => {
        if (balanceActual != null) 'balanceActual': balanceActual,
        'moneda': moneda,
        'ultimasTransacciones':
            ultimasTransacciones.map((t) => t.toJson()).toList(),
        'presupuestosMensuales':
            presupuestosMensuales.map((p) => p.toJson()).toList(),
      };
}

class TransaccionResumen {
  final String categoria;
  final double monto;
  final bool esIngreso;
  final String fecha; // 'YYYY-MM-DD'

  const TransaccionResumen({
    required this.categoria,
    required this.monto,
    required this.esIngreso,
    required this.fecha,
  });

  Map<String, dynamic> toJson() => {
        'categoria': categoria,
        'monto': monto,
        'esIngreso': esIngreso,
        'fecha': fecha,
      };
}

class PresupuestoResumen {
  final String categoria;
  final double montoEsperado;
  final double? montoReal;

  const PresupuestoResumen({
    required this.categoria,
    required this.montoEsperado,
    this.montoReal,
  });

  Map<String, dynamic> toJson() => {
        'categoria': categoria,
        'montoEsperado': montoEsperado,
        if (montoReal != null) 'montoReal': montoReal,
      };
}

class ChatException implements Exception {
  final String mensaje;
  final int? codigoHttp;
  const ChatException(this.mensaje, {this.codigoHttp});

  @override
  String toString() => 'ChatException($codigoHttp): $mensaje';
}


// Servicio singleton para comunicarse con el middleware del chatbot.
class ChatService {
  ChatService._();
  static final ChatService instancia = ChatService._();

  static const bool _usarEdgeFunction = true;


  static const String _urlServidorNode = kIsWeb
      ? 'http://localhost:5000'
      : 'http://172.20.10.2:5000'; //Cambiar IP por la de PC en la red local


  //Devuelve URL del endpoint
  Future<Uri> _obtenerUri() async {
    if (_usarEdgeFunction) {
      return Uri.parse('$supabaseUrl/functions/v1/chat-ia');
    }
    return Uri.parse('$_urlServidorNode/chat');
  }

  //Cabeceras HTTP con autenticación Supabase si aplica.
  Future<Map<String, String>> _obtenerCabeceras() async {
    final cabeceras = <String, String>{
      'Content-Type': 'application/json',
      'apikey': supabaseAnonKey,
    };
    if (_usarEdgeFunction) {
      final sesion = Supabase.instance.client.auth.currentSession;
      cabeceras['Authorization'] = 'Bearer ${sesion?.accessToken ?? supabaseAnonKey}';
    }
    return cabeceras;
  }


  //Envía mensaje al middleware y devuelve el texto de respuesta de la IA.

  Future<String> enviarMensaje({
    required String mensaje,
    List<MensajeChat> historial = const [],
    ContextoFinanciero? contextoFinanciero,
  }) async {
    final uri = await _obtenerUri();
    final cabeceras = await _obtenerCabeceras();

    final cuerpo = jsonEncode({
      'mensaje': mensaje,
      if (historial.isNotEmpty)
        'historial': historial.map((m) => m.toJson()).toList(),
      if (contextoFinanciero != null)
        'contextoFinanciero': contextoFinanciero.toJson(),
    });

    try {
      final respuesta = await http
          .post(uri, headers: cabeceras, body: cuerpo)
          .timeout(const Duration(seconds: 30));
      print('CHAT STATUS: ${respuesta.statusCode}');
      print('CHAT BODY: ${respuesta.body}');

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
        return datos['respuesta'] as String? ?? '';
      }

      // Extrae mensaje de error del servidor
      String mensajeError = 'Error ${respuesta.statusCode}';
      try {
        final err = jsonDecode(respuesta.body) as Map<String, dynamic>;
        mensajeError = err['error'] as String? ?? mensajeError;
      } catch (_) {}

      throw ChatException(mensajeError, codigoHttp: respuesta.statusCode);
    } on ChatException {
      rethrow;
    } catch (e) {
      throw ChatException('Error de conexión. Verifica tu red e inténtalo de nuevo.');
    }
  }
}
