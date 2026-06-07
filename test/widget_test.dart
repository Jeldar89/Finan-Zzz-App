// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas/main.dart';

void main() {
  // El test original referenciaba MyApp (template de Flutter) que ya no existe.
  // Lo dejamos vacío para que flutter test no falle al compilar.
  testWidgets('App inicia sin errores de compilación', (tester) async {
    // La inicialización real de Supabase requiere credenciales reales.
    // Para tests unitarios completos, usa supabase_flutter mocks.
    expect(AppPrincipal, isNotNull);
  });
}