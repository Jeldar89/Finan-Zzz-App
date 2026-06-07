import '../categorias/modelocategoria.dart';

// CAMBIO PRINCIPAL vs versión anterior:
// - Se elimina el campo 'tipo' (income/expense) — ahora se deriva de la categoría
// - Se usa categoria_id en lugar de subcategory_id
// - Se renombra 'subcategoriaId' → 'categoriaId' (la tabla tiene un nivel menos)
class ModeloTrans {
  final int? id;
  final int? tipoId;
  final String profileId;
  final int categoriaId;
  final double monto;
  final DateTime fecha;
  final String? descripcion;
  final String? nombreCategoria;
  final bool? esIngreso;

  ModeloTrans({
    this.id,
    this.tipoId,
    required this.profileId,
    required this.categoriaId,
    required this.monto,
    required this.fecha,
    this.descripcion,
    this.nombreCategoria,
    this.esIngreso,
  });

  factory ModeloTrans.fromJson(Map<String, dynamic> json) {
    final catJson = json['categorias'];
    bool? ingreso;
    String? nomCat;
    int? tipoId;
    if (catJson != null) {
      nomCat  = catJson['nombre'] as String?;
      final tipoJson = catJson['tipos_categoria'];
      if (tipoJson != null) {
        ingreso = tipoJson['es_ingreso'] as bool?;
        tipoId = tipoJson['id'] as int?;
      }
    }

    return ModeloTrans(
      id:             json['id'] as int?,
      profileId:      json['profile_id'] as String,
      categoriaId:    json['categoria_id'] as int,
      monto:          (json['monto'] as num).toDouble(),
      fecha:          DateTime.parse(json['fecha'] as String).toLocal(),
      descripcion:    json['descripcion'] as String?,
      nombreCategoria: nomCat,
      esIngreso:      ingreso,
      tipoId:          tipoId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_id':   profileId,
      'categoria_id': categoriaId,
      'monto':        monto,
      'fecha':        fecha.toIso8601String().split('T')[0], // Solo YYYY-MM-DD
      if (descripcion != null) 'descripcion': descripcion,
    };
  }
}