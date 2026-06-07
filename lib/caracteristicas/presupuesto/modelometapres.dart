
class ModeloMetaPresupuesto {
  final int? id;
  final String profileId;
  final int categoriaId;
  final int tipoId;//Para saber a qué parte pertenece sin mas JOINs
  final double montoEsperado;
  final DateTime mesPeriodo;
  final String? nombreCategoria;

  ModeloMetaPresupuesto({
    this.id,
    required this.profileId,
    required this.categoriaId,
    required this.tipoId,
    required this.montoEsperado,
    required this.mesPeriodo,
    this.nombreCategoria,
  });

  factory ModeloMetaPresupuesto.fromJson(Map<String, dynamic> json) {
    //JOIN trae categorias y tipos_categoria
    final catJson = json['categorias'];
    int tipoId = 0;
    String? nomCat;
    if (catJson != null) {
      tipoId = catJson['tipo_id'] as int? ?? 0;
      nomCat = catJson['nombre'] as String?;
    }
    return ModeloMetaPresupuesto(
      id:              json['id'] as int?,
      profileId:       json['profile_id'] as String,
      categoriaId:     json['categoria_id'] as int,
      tipoId:          tipoId,
      montoEsperado:   (json['monto_esperado'] as num).toDouble(),
      mesPeriodo:      DateTime.parse(json['mes_periodo'] as String).toLocal(),
      nombreCategoria: nomCat,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'profile_id':     profileId,
      'categoria_id':   categoriaId,
      'monto_esperado': montoEsperado,
      'mes_periodo':
      "${mesPeriodo.year}-${mesPeriodo.month.toString().padLeft(2, '0')}-01",
    };
  }
}