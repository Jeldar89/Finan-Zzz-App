import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:finanzas/caracteristicas/autenticacion/autenprovider.dart';
import 'package:finanzas/caracteristicas/autenticacion/autenscreen.dart';
import 'package:finanzas/caracteristicas/categorias/categoriaprovider.dart';
import 'package:finanzas/caracteristicas/dashboard/dashboardprovider.dart';
import 'package:finanzas/caracteristicas/presupuesto/metapresprovider.dart';
import 'package:finanzas/caracteristicas/transaccion/providertrans.dart';

import 'caracteristicas/chat/chatprovider.dart';
const String supabaseUrl = 'https://ovkseukgiopezbndpflq.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im92a3NldWtnaW9wZXpibmRwZmxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MzcyODcsImV4cCI6MjA5NTQxMzI4N30.ifSH2oUBxeQ56SSEE84gM4_StlbPMiH62UVHLXrQUAM';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  await initializeDateFormatting('es', null);

  runApp(const AppPrincipal());
}

class AppPrincipal extends StatelessWidget {
  const AppPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Autenprovider()),
        ChangeNotifierProvider(create: (_) => ProviderTrans()),
        ChangeNotifierProvider(create: (_) => ProviderMetaPres()),
        ChangeNotifierProvider(create: (_) => CategoriaProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'Finanzas',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          useMaterial3: true,
        ),
        home: const AutenScreen(),
      ),
    );
  }
}