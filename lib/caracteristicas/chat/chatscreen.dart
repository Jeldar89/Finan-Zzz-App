// NO llama a ApiService ni usa lógica HTTP directamente.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chatprovider.dart';
import 'chatservice.dart';
import '../transaccion/providertrans.dart';
import '../presupuesto/metapresprovider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controladorTexto = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Inyecta el contexto al entrar a la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) => _inyectarContexto());
  }


  /// (ProviderTrans y ProviderMetaPres) entrega al ChatProvider.
  void _inyectarContexto() {
    final provTrans = context.read<ProviderTrans>();
    final provMetas = context.read<ProviderMetaPres>();

    // Balance del mes
    double ingresos = 0;
    double egresos = 0;
    for (final tx in provTrans.transacciones) {
      if (tx.esIngreso == true) {
        ingresos += tx.monto;
      } else {
        egresos += tx.monto;
      }
    }

    final transResumen = provTrans.transacciones
        .take(10)
        .map((tx) => TransaccionResumen(
              categoria: tx.nombreCategoria ?? 'Sin categoría',
              monto: tx.monto,
              esIngreso: tx.esIngreso ?? false,
              fecha: tx.fecha.toIso8601String().split('T')[0],
            ))
        .toList();

    final presResumen = provMetas.metas
        .map((m) => PresupuestoResumen(
              categoria: m.nombreCategoria ?? 'Sin categoría',
              montoEsperado: m.montoEsperado,
            ))
        .toList();

    context.read<ChatProvider>().configurarContexto(
          ContextoFinanciero(
            balanceActual: ingresos - egresos,
            moneda: 'MXN',
            ultimasTransacciones: transResumen,
            presupuestosMensuales: presResumen,
          ),
        );
  }

  /// Envía un mensaje y hace scroll al final de lista.
  Future<void> _enviar() async {
    final texto = controladorTexto.text.trim();
    if (texto.isEmpty) return;
    controladorTexto.clear();
    await context.read<ChatProvider>().enviarMensaje(texto);
    _desplazarAlFinal();
  }

  void _desplazarAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    controladorTexto.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asesor Financiero IA'),
        actions: [
          // Botón para reiniciar la conversación
          IconButton(
            tooltip: 'Nueva conversación',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ChatProvider>().limpiarConversacion(),
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ── Lista de mensajes ──────────────────────────────────────────
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (_, proveedor, __) {
                  if (proveedor.burbujas.isEmpty) {
                    return const _PantallaVacia();
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    itemCount: proveedor.burbujas.length,
                    itemBuilder: (_, indice) {
                      final burbuja = proveedor.burbujas[indice];
                      return _BurbujaWidget(burbuja: burbuja);
                    },
                  );
                },
              ),
            ),

            //Indicador de carga
            Consumer<ChatProvider>(
              builder: (_, prov, __) => prov.estaCargando
                  ? const LinearProgressIndicator(minHeight: 2)
                  : const SizedBox.shrink(),
            ),

            //Campo de entrada
            _BarraEntrada(
              controlador: controladorTexto,
              onEnviar: _enviar,
            ),
          ],
        ),
      ),
    );
  }
}

//Widgets auxiliares

/// Pantalla vacía con mensaje de bienvenida.
class _PantallaVacia extends StatelessWidget {
  const _PantallaVacia();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '¡Hola! Soy tu asesor financiero IA.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Pregúntame sobre tus finanzas, presupuestos o cómo ahorrar más.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Burbuja individual del chat.
class _BurbujaWidget extends StatelessWidget {
  final BurbujaChat burbuja;
  const _BurbujaWidget({required this.burbuja});

  @override
  Widget build(BuildContext context) {
    final esUsuario = burbuja.rol == RolMensaje.usuario;
    final esError = burbuja.rol == RolMensaje.error;

    final colorFondo = esError
        ? Colors.red.shade50
        : esUsuario
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.grey.shade100;

    final colorTexto = esError
        ? Colors.red.shade900
        : esUsuario
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Colors.black87;

    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(esUsuario ? 16 : 4),
            bottomRight: Radius.circular(esUsuario ? 4 : 16),
          ),
        ),
        child: Text(
          burbuja.texto,
          style: TextStyle(color: colorTexto, height: 1.4),
        ),
      ),
    );
  }
}

/// Barra de entrada de texto y botón de enviar.
class _BarraEntrada extends StatelessWidget {
  final TextEditingController controlador;
  final VoidCallback onEnviar;

  const _BarraEntrada({
    required this.controlador,
    required this.onEnviar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: const Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controlador,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onEnviar(),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Ej. ¿Dónde invertir \$500?',
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Consumer<ChatProvider>(
            builder: (_, prov, __) => IconButton(
              onPressed: prov.estaCargando ? null : onEnviar,
              icon: Icon(
                Icons.send_rounded,
                color: prov.estaCargando
                    ? Colors.grey
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
