import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'modelotrans.dart';
import 'providertrans.dart';
import '../categorias/modelocategoria.dart';
import '../categorias/categoriaprovider.dart';

class FormScreenTrans extends StatefulWidget {
  final String profileId;
  const FormScreenTrans({super.key, required this.profileId});

  @override
  State<FormScreenTrans> createState() => _FormScreenTransState();
}

class _FormScreenTransState extends State<FormScreenTrans> {
  final _formKey = GlobalKey<FormState>();
  double _monto = 0.0;
  String? _descripcion;
  TipoCategoria?    _tipoSeleccionado;
  ModeloCategoria?  _categoriaSeleccionada;

  @override
  void initState() {
    super.initState();
    // Carga el catálogo si aún no está disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriaProvider>().inicializarCatalogo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final proveedorCat = context.watch<CategoriaProvider>();
    final categoriasFiltradas = _tipoSeleccionado != null
        ? proveedorCat.categoriasPorTipo(_tipoSeleccionado!.id)
        : <ModeloCategoria>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Movimiento')),
      body: proveedorCat.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              //Lista 1: Tipo (las 6 categorias)
              DropdownButtonFormField<TipoCategoria>(
                decoration: const InputDecoration(
                  labelText: 'Tipo de movimiento',
                  border: OutlineInputBorder(),
                ),
                value: _tipoSeleccionado,
                items: proveedorCat.tipos
                    .map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.nombre),
                ))
                    .toList(),
                onChanged: (val) => setState(() {
                  _tipoSeleccionado     = val;
                  _categoriaSeleccionada = null; // reinicia la 2da lista
                }),
                validator: (val) =>
                val == null ? 'Selecciona un tipo' : null,
              ),
              const SizedBox(height: 16),
              //Lista 2: Categoría (filtrada por tipo elegido)
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
                validator: (val) =>
                val == null ? 'Selecciona una categoría' : null,
              ),
              const SizedBox(height: 16),
              //Campo de importe
              TextFormField(
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Importe (MXN)',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return 'Escribe una cantidad';
                  if (double.tryParse(val) == null)
                    return 'Debe ser un número válido';
                  if (double.parse(val) <= 0)
                    return 'El importe debe ser mayor a cero';
                  return null;
                },
                onSaved: (val) => _monto = double.parse(val!),
              ),
              const SizedBox(height: 16),
              // Descripción opcional
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
                onSaved: (val) => _descripcion =
                (val?.trim().isEmpty ?? true) ? null : val!.trim(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _enviar,
                child: const Text('Guardar Registro'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final nuevaTransaccion = ModeloTrans(
      profileId:   widget.profileId,
      categoriaId: _categoriaSeleccionada!.id,
      monto:       _monto,
      fecha:       DateTime.now(),
      descripcion: _descripcion,
    );

    final exito = await context
        .read<ProviderTrans>()
        .guardarTransaccion(nuevaTransaccion);

    if (exito && mounted) Navigator.pop(context);
  }
}