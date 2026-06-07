class TipoCategoria {
  final int id;
  final String nombre;
  final bool esIngreso; // true = suma al disponible
  final int orden;

  // Constantes para no confundir números en el código
  static const int idIngresos    = 1;
  static const int idGastos      = 2;
  static const int idFacturas    = 3;
  static const int idAhorros     = 4;
  static const int idInversiones = 5;
  static const int idDeudas      = 6;

  TipoCategoria({
    required this.id,
    required this.nombre,
    required this.esIngreso,
    required this.orden,
  });

  factory TipoCategoria.fromJson(Map<String, dynamic> json) {
    return TipoCategoria(
      id:        json['id'] as int,
      nombre:    json['nombre'] as String,
      esIngreso: json['es_ingreso'] as bool,
      orden:     json['orden'] as int,
    );
  }
}

//Categorías dentro de cada tipo
class ModeloCategoria {
  final int id;
  final int tipoId;
  final String nombre;
  final TipoCategoria? tipo;

  ModeloCategoria({
    required this.id,
    required this.tipoId,
    required this.nombre,
    this.tipo,
  });

  bool get esIngreso => tipo?.esIngreso ?? false;

  factory ModeloCategoria.fromJson(Map<String, dynamic> json) {
    return ModeloCategoria(
      id:     json['id'] as int,
      tipoId: json['tipo_id'] as int,
      nombre: json['nombre'] as String,
      tipo:   json['tipos_categoria'] != null
          ? TipoCategoria.fromJson(json['tipos_categoria'])
          : null,
    );
  }
}