import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'modelometapres.dart';
import 'metapresprovider.dart';
import '../categorias/categoriaprovider.dart';
import '../categorias/modelocategoria.dart';

class FormScreenMetas extends StatefulWidget {
  final String profileId;
  const FormScreenMetas({super.key, required this.profileId});

  @override
  State<FormScreenMetas> createState() => _FormScreenMetasState();
}

class _FormScreenMetasState extends State<FormScreenMetas> {
  final _formKey = GlobalKey<FormState>();

  TipoCategoria? _tipoSeleccionado;
  ModeloCategoria? _categoriaSeleccionada;
  double _montoEsperado = 0.0;
  DateTime _mesPeriodo = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriaProvider>().inicializarCatalogo();
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')),
      );
      return;
    }

    final meta = ModeloMetaPresupuesto(
      profileId: widget.profileId,
      categoriaId: _categoriaSeleccionada!.id,
      tipoId: _categoriaSeleccionada!.tipoId,
      montoEsperado: _montoEsperado,
      mesPeriodo: _mesPeriodo,
    );

    final exito = await context.read<ProviderMetaPres>().guardarMeta(meta);

    if (mounted) {
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meta guardada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _tipoSeleccionado = null;
          _categoriaSeleccionada = null;
          _montoEsperado = 0.0;
          _formKey.currentState?.reset();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar la meta'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provCat = context.watch<CategoriaProvider>();
    final provMetas = context.watch<ProviderMetaPres>();
    final formatoMes = DateFormat('MM/yyyy');

    final categoriasFiltradas = _tipoSeleccionado != null
        ? provCat.categoriasPorTipo(_tipoSeleccionado!.id)
        : <ModeloCategoria>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Metas de Presupuesto')),
      body: provCat.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          //Selector de mes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Mes: ${formatoMes.format(_mesPeriodo)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _seleccionarMes,
                    child: const Text('Cambiar'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          //Formulario nueva meta
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nueva meta',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TipoCategoria>(
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(),
                      ),
                      value: _tipoSeleccionado,
                      items: provCat.tipos
                          .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.nombre),
                      ))
                          .toList(),
                      onChanged: (val) => setState(() {
                        _tipoSeleccionado = val;
                        _categoriaSeleccionada = null;
                      }),
                      validator: (v) =>
                      v == null ? 'Selecciona un tipo' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ModeloCategoria>(
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                      ),
                      value: _categoriaSeleccionada,
                      items: categoriasFiltradas
                          .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.nombre),
                      ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _categoriaSeleccionada = val),
                      validator: (v) =>
                      v == null ? 'Selecciona una categoría' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monto esperado (MXN)',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return 'Escribe un monto';
                        if (double.tryParse(val) == null)
                          return 'Debe ser un número';
                        if (double.parse(val) <= 0)
                          return 'Debe ser mayor a cero';
                        return null;
                      },
                      onSaved: (val) =>
                      _montoEsperado = double.parse(val!),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: provMetas.isLoading
                          ? const Center(
                          child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                        onPressed: _guardar,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar meta'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          //Lista metas actuales
          const Text('Metas del mes',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (provMetas.metas.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No hay metas para este mes.\nAgrega una arriba.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...provMetas.metas
                .where((m) =>
            m.mesPeriodo.year == _mesPeriodo.year &&
                m.mesPeriodo.month == _mesPeriodo.month)
                .map(
                  (m) => Card(
                child: ListTile(
                  leading: const Icon(Icons.flag_outlined,
                      color: Colors.blue),
                  title: Text(m.nombreCategoria ?? 'Sin nombre'),
                  trailing: Text(
                    '\$${m.montoEsperado.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _seleccionarMes() async {
    final ahora = DateTime.now();
    final seleccionado = await showDatePicker(
      context: context,
      initialDate: _mesPeriodo,
      firstDate: DateTime(ahora.year - 2),
      lastDate: DateTime(ahora.year + 1),
      helpText: 'Selecciona el mes',
      fieldLabelText: 'Mes',
    );
    if (seleccionado != null) {
      setState(() {
        _mesPeriodo = DateTime(seleccionado.year, seleccionado.month);
      });
    }
  }
}