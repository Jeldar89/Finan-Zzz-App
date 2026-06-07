import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../autenticacion/autenprovider.dart';
import '../categorias/categoriaprovider.dart';
import '../presupuesto/metapresprovider.dart';
import '../transaccion/modelotrans.dart';
import '../transaccion/providertrans.dart';
import '../transaccion/formscreentrans.dart';
import 'dashboardprovider.dart';
import 'graficapastel.dart';
import '../chat/chatscreen.dart';
import '../presupuesto/formscreenmetas.dart';


class DashboardScreen extends StatefulWidget {
  final String profileId;
  const DashboardScreen({super.key, required this.profileId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _indiceTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarDatos());
  }

  Future<void> _cargarDatos() async {
    final mes = DateTime.now();
    //Lanzamos las 3 peticiones en paralelo
    await Future.wait([
      context
          .read<ProviderTrans>()
          .cargarTransaccionesMensuales(widget.profileId, mes),
      context
          .read<ProviderMetaPres>()
          .cargarPresupuestoMensual(widget.profileId, mes),
      context.read<CategoriaProvider>().inicializarCatalogo(),
    ]);

    if (!mounted) return;

    //Recalculamos el dashboard
    context.read<DashboardProvider>().calcularMetricas(
      tipos: context.read<CategoriaProvider>().tipos,
      metas: context.read<ProviderMetaPres>().metas,
      transacciones: context.read<ProviderTrans>().transacciones,
    );
  }

  @override
  Widget build(BuildContext context) {
    final proveedorTrans  = context.watch<ProviderTrans>();
    final proveedorDash   = context.watch<DashboardProvider>();
    final estaCargando    = proveedorTrans.isLoading ||
        context.watch<ProviderMetaPres>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Finanzas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<Autenprovider>().cerrarSesion(),
          ),
        ],
      ),
      body: estaCargando
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
        index: _indiceTab,
        children: [
          _PestanaResumen(
            proveedorDash: proveedorDash,
            transacciones: List.from(proveedorTrans.transacciones),
            profileId: widget.profileId,
          ),
          const ChatScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceTab,
        onDestinationSelected: (i) =>
            setState(() => _indiceTab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Resumen',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Asesor IA',
          ),
        ],
      ),
      // Errores en nueva transacción
      floatingActionButton: _indiceTab == 0
          ? FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                FormScreenTrans(profileId: widget.profileId),
          ),
        ).then((_) => _cargarDatos()), // recarga al volver
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}

class _PestanaResumen extends StatelessWidget {
  final DashboardProvider proveedorDash;
  final List<ModeloTrans> transacciones;
  final String profileId;

  const _PestanaResumen({
    required this.proveedorDash,
    required this.transacciones,
    required this.profileId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _TarjetaKPI(
              titulo: 'Queda por gastar',
              valor:  proveedorDash.quedaPorGastar,
              color:  proveedorDash.quedaPorGastar >= 0
                  ? Colors.green
                  : Colors.red,
            ),
            const SizedBox(width: 12),
            _TarjetaKPI(
              titulo: 'Por presupuesto',
              valor:  proveedorDash.quedaPorPresupuesto,
              color:  Colors.blue,
            ),
          ],
        ),
        const SizedBox(height: 20),

        //Gráfica pastel
        const Text(
          'Distribución de egresos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GraficaPastelWidget(transacciones: transacciones),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Resumen mensual',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton.icon(
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Editar metas'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FormScreenMetas(profileId: profileId),
                  ),
                ).then((_) async {
                  // Recargar presupuesto y recalcular dashboard
                  final ctx = context;
                  await ctx.read<ProviderMetaPres>()
                      .cargarPresupuestoMensual(profileId, DateTime.now());
                  if (ctx.mounted) {
                    ctx.read<DashboardProvider>().calcularMetricas(
                      tipos: ctx.read<CategoriaProvider>().tipos,
                      metas: ctx.read<ProviderMetaPres>().metas,
                      transacciones: ctx.read<ProviderTrans>().transacciones,
                    );
                  }
                }),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Encabezado
        const Row(
          children: [
            Expanded(
                flex: 3,
                child: Text('Tipo',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey))),
            Expanded(
                flex: 2,
                child: Text('Presupuesto',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12, color: Colors.grey))),
            Expanded(
                flex: 2,
                child: Text('Real',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12, color: Colors.grey))),
          ],
        ),
        const Divider(),
        ...proveedorDash.resumenPorTipo
            .map((f) => _FilaResumenWidget(fila: f)),

        if (proveedorDash.topCategorias.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Top categorías',
            style:
            TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...proveedorDash.topCategorias.map(
                (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                      width: 24,
                      child: Text(
                        '${item.posicion}.',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                      )),
                  Expanded(child: Text(item.nombre)),
                  Text(
                    '\$${item.monto.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.porcentaje.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TarjetaKPI extends StatelessWidget {
  final String titulo;
  final double valor;
  final Color  color;
  const _TarjetaKPI(
      {required this.titulo,
        required this.valor,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                '\$${valor.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilaResumenWidget extends StatelessWidget {
  final FilaResumen fila;
  const _FilaResumenWidget({required this.fila});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(fila.tipo,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
              flex: 2,
              child: Text(
                '\$${fila.presupuesto.toStringAsFixed(0)}',
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.grey),
              )),
          Expanded(
              flex: 2,
              child: Text(
                '\$${fila.real.toStringAsFixed(0)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: fila.esIngreso
                      ? Colors.green
                      : (fila.real > fila.presupuesto && fila.presupuesto > 0
                      ? Colors.red
                      : null),
                ),
              )),
        ],
      ),
    );
  }
}