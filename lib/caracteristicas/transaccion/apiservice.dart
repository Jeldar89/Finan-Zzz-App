import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  static String obtenerUrlBase() {
    if (kIsWeb) {
      return "http://localhost:5000";
    } else {
      return "http://172.20.10.2:5000";
    }
  }
  static Future<String> enviarPregunta(String pregunta) async {
    try {
      final respuesta = await http.post(
        Uri.parse("${obtenerUrlBase()}/chat"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "pregunta": pregunta,
        }),
      );
      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body);
        return datos["respuesta"];
      } else {
        return "Error del servidor: ${respuesta.statusCode}";
      }
    } catch (e) {
      return "Error de conexión: $e";
    }
  }
}
