import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../transaccion/modelotrans.dart';

class GraficaPastelWidget extends StatelessWidget {
  final List<ModeloTrans> transacciones;
  const GraficaPastelWidget({super.key, required this.transacciones});

  static const List<Color> _colores = [
    Color(0xFF6C63FF), Color(0xFF48C774), Color(0xFFFF6B6B),
    Color(0xFFFFDD57), Color(0xFF3298DC), Color(0xFFFF8A5B),
    Color(0xFF9B59B6), Color(0xFF1ABC9C), Color(0xFFE67E22),
    Color(0xFF2ECC71),
  ];

  @override
  Widget build(BuildContext context) {
    final Map<String, double> gastosAgrupados = {};

    for (final tx in transacciones) {
      if (tx.esIngreso == true) continue; // saltamos ingresos
      final nombre = tx.nombreCategoria ?? 'Sin categoría';
      gastosAgrupados[nombre] = (gastosAgrupados[nombre] ?? 0) + tx.monto;
    }

    if (gastosAgrupados.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Sin egresos registrados este mes')),
      );
    }

    //Color diferente por sección
    int colorIndice = 0;
    final List<PieChartSectionData> secciones =
    gastosAgrupados.entries.map((entrada) {
      final color = _colores[colorIndice % _colores.length];
      colorIndice++;
      return PieChartSectionData(
        value: entrada.value,
        title: '\$${entrada.value.toStringAsFixed(0)}',
        radius: 60,
        titleStyle: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        color: color,
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sections: secciones,
              sectionsSpace: 2,
              centerSpaceRadius: 50,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Leyenda
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: gastosAgrupados.entries.toList().asMap().entries.map((e) {
            final color = _colores[e.key % _colores.length];
            return Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(e.value.key, style: const TextStyle(fontSize: 11)),
            ]);
          }).toList(),
        ),
      ],
    );
  }
}