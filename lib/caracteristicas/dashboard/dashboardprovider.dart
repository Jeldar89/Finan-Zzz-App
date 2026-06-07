import 'package:flutter/material.dart';
import '../categorias/modelocategoria.dart';
import '../presupuesto/modelometapres.dart';
import '../transaccion/modelotrans.dart';

//Resumen del Presupuesto Mensual
class FilaResumen {
  final String tipo;
  final bool   esIngreso;
  final int    orden;
  double presupuesto;
  double real;

  FilaResumen({
    required this.tipo,
    required this.esIngreso,
    required this.orden,
    this.presupuesto = 0,
    this.real        = 0,
  });

  double get diferencia => presupuesto - real;
}

//ranking de categorías
class ItemRanking {
  final int    posicion;
  final String nombre;
  final double monto;
  final double porcentaje;
  ItemRanking({
    required this.posicion,
    required this.nombre,
    required this.monto,
    required this.porcentaje,
  });
}

class DashboardProvider with ChangeNotifier {
  List<FilaResumen> resumenPorTipo = [];
  List<ItemRanking> topCategorias  = [];

  double quedaPorPresupuesto = 0;
  double quedaPorGastar      = 0;
  double deudaPagada         = 0;
  double saldoTransferido    = 0;

  void calcularMetricas({
    required List<TipoCategoria>         tipos,
    required List<ModeloMetaPresupuesto> metas,
    required List<ModeloTrans>           transacciones,
    double saldoArrastrado = 0,
  }) {
    saldoTransferido = saldoArrastrado;

    // Inicializa filas con los 6 tipos de categorias
    resumenPorTipo = tipos
        .map((t) => FilaResumen(
      tipo:      t.nombre,
      esIngreso: t.esIngreso,
      orden:     t.orden,
    ))
        .toList()
      ..sort((a, b) => a.orden.compareTo(b.orden));

    final mapaFilas = <int, FilaResumen>{
      for (final t in tipos)
        t.id: resumenPorTipo.firstWhere((f) => f.tipo == t.nombre)
    };

    // Suma presupuestos
    for (final meta in metas) {
      mapaFilas[meta.tipoId]?.presupuesto += meta.montoEsperado;
    }

    // Suma reales y construye mapa para rankings
    final Map<String, double> realPorCategoria = {};
    for (final tx in transacciones) {
      if (tx.esIngreso == true) {
        mapaFilas[TipoCategoria.idIngresos]?.real += tx.monto;
      } else {
        final nom = tx.nombreCategoria ?? 'Sin categoría';
        realPorCategoria[nom] = (realPorCategoria[nom] ?? 0) + tx.monto;
        if (tx.tipoId != null) {
          mapaFilas[tx.tipoId]?.real += tx.monto;
        }
      }
    }

    // KPIs
    double ingresosEsp = 0, ingresosReal = 0;
    double egresosEsp  = 0, egresosReal  = 0;
    for (final f in resumenPorTipo) {
      if (f.esIngreso) {
        ingresosEsp  += f.presupuesto;
        ingresosReal += f.real;
      } else {
        egresosEsp  += f.presupuesto;
        egresosReal += f.real;
      }
    }
    // Compensamos los egresos reales que acumulamos por categoría
    final totalEgresosReal =
    realPorCategoria.values.fold(0.0, (s, v) => s + v);
    egresosReal = totalEgresosReal;

    quedaPorPresupuesto = ingresosEsp  + saldoTransferido - egresosEsp;
    quedaPorGastar      = ingresosReal + saldoTransferido - egresosReal;
    deudaPagada         = mapaFilas[TipoCategoria.idDeudas]?.real ?? 0;

    // Ranking
    final total = ingresosReal + egresosReal;
    final lista = realPorCategoria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    topCategorias = lista.take(20).toList().asMap().entries.map((e) {
      return ItemRanking(
        posicion:   e.key + 1,
        nombre:     e.value.key,
        monto:      e.value.value,
        porcentaje: total > 0 ? (e.value.value / total * 100) : 0,
      );
    }).toList();

    notifyListeners();
  }
}