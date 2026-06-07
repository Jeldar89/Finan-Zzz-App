import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'autenprovider.dart';
import 'package:finanzas/caracteristicas/dashboard/dashboardscreen.dart';

class AutenScreen extends StatefulWidget {
  const AutenScreen({super.key});

  @override
  State<AutenScreen> createState() => _AutenScreenState();
}

class _AutenScreenState extends State<AutenScreen> {
  final _emailController      = TextEditingController();
  final _contrasenaController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _intentarLogin() async {
    final exito = await context.read<Autenprovider>().iniciarSesion(
      _emailController.text.trim(),
      _contrasenaController.text,
    );

    if (exito && mounted) {
      // ── Obtenemos el profileId del usuario que acaba de autenticarse ──────
      // Supabase guarda el id del usuario en auth.currentUser.
      // Es el mismo UUID que usamos como profile_id en todas las tablas.
      final profileId =
          Supabase.instance.client.auth.currentUser?.id ?? '';

      // Reemplazamos la pila de navegación completa para que el botón
      // "atrás" no regrese a la pantalla de login.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(profileId: profileId),
        ),
      );
    }
  }

  Future<void> _intentarRegistro() async {
    final exito = await context.read<Autenprovider>().registrarse(
      _emailController.text.trim(),
      _contrasenaController.text,
    );

    if (exito && mounted) {
      final profileId =
          Supabase.instance.client.auth.currentUser?.id ?? '';
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(profileId: profileId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final proveedorAuten = context.watch<Autenprovider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Finanzas',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration:
              const InputDecoration(labelText: 'Correo electrónico'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contrasenaController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
              onSubmitted: (_) => _intentarLogin(),
            ),
            const SizedBox(height: 24),
            if (proveedorAuten.mensajeError != null)
              Text(
                proveedorAuten.mensajeError!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            proveedorAuten.isLoading
                ? const CircularProgressIndicator()
                : Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _intentarLogin,
                    child: const Text('Entrar'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _intentarRegistro,
                    child: const Text('Crear cuenta nueva'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}