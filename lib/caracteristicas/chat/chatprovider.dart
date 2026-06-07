// Provider que gestiona el estado completo del chatbot:
//   • Lista de mensajes del hilo (historial visible en la UI)
//   • Estado de carga
//   • Errores
//   • Contexto financiero inyectado desde el Dashboard

import 'package:flutter/material.dart';
import 'chatservice.dart';

// ── Estado de cada burbuja ────────────────────────────────────────────────────

/// Quién envió el mensaje.
enum RolMensaje { usuario, asistente, error }

/// Modelo burbuja
class BurbujaChat {
  final String texto;
  final RolMensaje rol;
  final DateTime timestamp;

  const BurbujaChat({
    required this.texto,
    required this.rol,
    required this.timestamp,
  });
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Gestiona el estado del chatbot. Regístralo en MultiProvider (ver main.dart).
///
/// Uso básico:
///   context.read<ChatProvider>().configurarContexto(ctx);
///   await context.read<ChatProvider>().enviarMensaje('¿Cómo reduzco mis gastos?');
class ChatProvider with ChangeNotifier {
  final ChatService _servicio = ChatService.instancia;

  // ── Estado público ────────────────────────────────────────────────────────

  /// Burbujas visibles en la pantalla (combinación de mensajes usuario + IA).
  final List<BurbujaChat> burbujas = [];

  /// true mientras espera respuesta de la IA.
  bool estaCargando = false;

  /// Mensaje de error actual (null si no hay error).
  String? mensajeError;

  // ── Estado privado ────────────────────────────────────────────────────────

  /// Historial en el formato que espera el servicio (para enviar a la API).
  final List<MensajeChat> _historial = [];

  /// Contexto financiero actual del usuario; puede actualizarse en cualquier momento.
  ContextoFinanciero? _contextoFinanciero;

  // ── API pública ───────────────────────────────────────────────────────────

  /// Inyecta o actualiza el contexto financiero del usuario.
  /// Llamar desde DashboardScreen cuando los datos de transacciones/presupuesto estén listos.
  void configurarContexto(ContextoFinanciero contexto) {
    _contextoFinanciero = contexto;
    // No necesitamos notifyListeners aquí; el contexto se usa en el próximo envío.
  }

  /// Envía el [texto] del usuario, actualiza la UI y obtiene la respuesta de la IA.
  Future<void> enviarMensaje(String texto) async {
    final textoLimpio = texto.trim();
    if (textoLimpio.isEmpty || estaCargando) return;

    // 1. Agregar burbuja del usuario
    _agregarBurbuja(textoLimpio, RolMensaje.usuario);
    _historial.add(MensajeChat(
      rol: 'user',
      contenido: textoLimpio,
      timestamp: DateTime.now(),
    ));

    // 2. Activar indicador de carga
    estaCargando = true;
    mensajeError = null;
    notifyListeners();

    try {
      // 3. Llamar al servicio (historial sin el último mensaje — ya lo incluye el servicio)
      final respuesta = await _servicio.enviarMensaje(
        mensaje: textoLimpio,
        historial: List.unmodifiable(_historial.sublist(
          0,
          _historial.length - 1, // excluimos el último porque ya lo pasamos en 'mensaje'
        )),
        contextoFinanciero: _contextoFinanciero,
      );

      // 4. Agregar respuesta al historial y UI
      _agregarBurbuja(respuesta, RolMensaje.asistente);
      _historial.add(MensajeChat(
        rol: 'assistant',
        contenido: respuesta,
        timestamp: DateTime.now(),
      ));

      // Limitar el historial para evitar contextos demasiado largos (últimos 20 mensajes)
      if (_historial.length > 20) {
        _historial.removeRange(0, _historial.length - 20);
      }
    } on ChatException catch (e) {
      mensajeError = e.mensaje;
      _agregarBurbuja('⚠️ ${e.mensaje}', RolMensaje.error);
    } catch (_) {
      const msg = 'Ocurrió un error inesperado. Intenta de nuevo.';
      mensajeError = msg;
      _agregarBurbuja('⚠️ $msg', RolMensaje.error);
    } finally {
      estaCargando = false;
      notifyListeners();
    }
  }

  /// Limpia el hilo de conversación (útil al cerrar sesión o reiniciar el chat).
  void limpiarConversacion() {
    burbujas.clear();
    _historial.clear();
    estaCargando = false;
    mensajeError = null;
    notifyListeners();
  }

  // ── Helpers privados ──────────────────────────────────────────────────────

  void _agregarBurbuja(String texto, RolMensaje rol) {
    burbujas.add(BurbujaChat(
      texto: texto,
      rol: rol,
      timestamp: DateTime.now(),
    ));
    // No llamamos notifyListeners aquí para hacer una sola notificación en el finally.
  }
}
