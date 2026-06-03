import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/transaction_viewmodel.dart';
import '../data/models/transaction_model.dart';

class FinancialInsightsView extends ConsumerWidget {
  final int userId;
  const FinancialInsightsView({Key? key, required this.userId}) : super(key: key);

  static const Color _primary = Color(0xFF1B3A5C);
  static const Color _success = Color(0xFF2ECC71);
  static const Color _danger  = Color(0xFFE74C3C);
  static const Color _accent  = Color(0xFF2D7DD2);
  static const Color _bg      = Color(0xFFF4F6F9);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionProvider(userId));
    final txList  = txState.transactions;

    final savingsRate = txState.totalIncome == 0
        ? 0.0
        : ((txState.totalIncome - txState.totalExpense) / txState.totalIncome)
            .clamp(0.0, 1.0);

    // Agrupa por categoria
    final Map<String, double> byCategory = {};
    for (final tx in txList) {
      if (tx.type == 'Saída') {
        byCategory[tx.category] =
            (byCategory[tx.category] ?? 0) + tx.amount;
      }
    }

    // Ordena transações por data para gráfico de evolução
    final sorted = [...txList]
      ..sort((a, b) => a.date.compareTo(b.date));

    // Dicas personalizadas
    final tips = _generateTips(txState.totalIncome, txState.totalExpense,
        savingsRate, byCategory);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        title: const Text('Análise Estratégica',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: txState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- SAÚDE DO CAIXA ---
                  _buildSectionCard(
                    title: 'Saúde Financeira Geral',
                    icon: Icons.monitor_heart_rounded,
                    child: _buildHealthSection(savingsRate, txState),
                  ),
                  const SizedBox(height: 16),

                  // --- MÉTRICAS ---
                  _buildSectionCard(
                    title: 'Métricas do Período',
                    icon: Icons.analytics_rounded,
                    child: _buildMetrics(txState, txList),
                  ),
                  const SizedBox(height: 16),

                  // --- GRÁFICO DE PIZZA POR CATEGORIA ---
                  if (byCategory.isNotEmpty)
                    _buildSectionCard(
                      title: 'Despesas por Categoria',
                      icon: Icons.pie_chart_rounded,
                      child: _buildCategoryChart(byCategory),
                    ),
                  if (byCategory.isNotEmpty) const SizedBox(height: 16),

                  // --- EVOLUÇÃO DO SALDO ---
                  if (sorted.length >= 2)
                    _buildSectionCard(
                      title: 'Evolução do Saldo',
                      icon: Icons.show_chart_rounded,
                      child: _buildBalanceEvolution(sorted),
                    ),
                  if (sorted.length >= 2) const SizedBox(height: 16),

                  // --- DICAS PERSONALIZADAS ---
                  _buildSectionCard(
                    title: 'Dicas Personalizadas',
                    icon: Icons.lightbulb_rounded,
                    child: _buildTips(tips),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ── SAÚDE ──────────────────────────────────────────────────────────────────
  Widget _buildHealthSection(double rate, TransactionState s) {
    final pct = rate * 100;
    final color = pct >= 20 ? _success : pct >= 5 ? Colors.orange : _danger;
    final label = pct >= 20
        ? 'Excelente — você está poupando bem!'
        : pct >= 5
            ? 'Regular — tente reduzir despesas.'
            : 'Crítico — despesas superam receitas!';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: rate,
            minHeight: 12,
            backgroundColor: Colors.grey[200],
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('0%', style: TextStyle(color: Colors.grey, fontSize: 11)),
            Text('${pct.toStringAsFixed(1)}% poupado',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const Text('100%',
                style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  // ── MÉTRICAS ───────────────────────────────────────────────────────────────
  Widget _buildMetrics(TransactionState s, List<TransactionModel> list) {
    final avgExpense = list.where((t) => t.type == 'Saída').isEmpty
        ? 0.0
        : s.totalExpense /
            list.where((t) => t.type == 'Saída').length;
    final avgIncome = list.where((t) => t.type == 'Entrada').isEmpty
        ? 0.0
        : s.totalIncome /
            list.where((t) => t.type == 'Entrada').length;

    return Column(
      children: [
        _metricRow('Total Receitas', 'R\$ ${_fmt(s.totalIncome)}',
            Icons.arrow_upward_rounded, _success),
        _metricRow('Total Despesas', 'R\$ ${_fmt(s.totalExpense)}',
            Icons.arrow_downward_rounded, _danger),
        _metricRow('Saldo Líquido', 'R\$ ${_fmt(s.balance)}',
            Icons.account_balance_wallet_rounded, _accent),
        _metricRow('Ticket Médio Entrada', 'R\$ ${_fmt(avgIncome)}',
            Icons.trending_up_rounded, Colors.teal),
        _metricRow('Ticket Médio Saída', 'R\$ ${_fmt(avgExpense)}',
            Icons.trending_down_rounded, Colors.orange),
        _metricRow('Total de Lançamentos', '${list.length}',
            Icons.receipt_rounded, _primary),
      ],
    );
  }

  Widget _metricRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: Colors.grey))),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  // ── PIZZA POR CATEGORIA ────────────────────────────────────────────────────
  Widget _buildCategoryChart(Map<String, double> byCategory) {
    final total = byCategory.values.fold(0.0, (a, b) => a + b);
    final colors = [
      _danger, _accent, Colors.orange, Colors.purple,
      Colors.teal, Colors.pink, Colors.brown,
    ];
    final entries = byCategory.entries.toList();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: CustomPaint(
            painter: _PieChartPainter(entries, colors, total),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: entries.asMap().entries.map((e) {
            final pct = (e.value.value / total * 100).toStringAsFixed(1);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: colors[e.key % colors.length],
                        shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('${e.value.key} $pct%',
                    style: const TextStyle(fontSize: 11)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── EVOLUÇÃO DO SALDO ──────────────────────────────────────────────────────
  Widget _buildBalanceEvolution(List<TransactionModel> sorted) {
    double running = 0;
    final points = sorted.map((tx) {
      running += tx.type == 'Entrada' ? tx.amount : -tx.amount;
      return running;
    }).toList();

    return SizedBox(
      height: 160,
      child: CustomPaint(
        painter: _LineChartPainter(points, _accent),
        child: const SizedBox.expand(),
      ),
    );
  }

  // ── DICAS PERSONALIZADAS ───────────────────────────────────────────────────
  Widget _buildTips(List<Map<String, dynamic>> tips) {
    return Column(
      children: tips.map((tip) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (tip['color'] as Color).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: (tip['color'] as Color).withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(tip['icon'] as IconData,
                  color: tip['color'] as Color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(tip['text'] as String,
                    style: const TextStyle(fontSize: 13, height: 1.4)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _generateTips(double income, double expense,
      double rate, Map<String, double> byCategory) {
    final tips = <Map<String, dynamic>>[];

    if (rate < 0.05) {
      tips.add({
        'icon': Icons.warning_rounded,
        'color': _danger,
        'text':
            'Suas despesas estão consumindo quase toda sua renda. Revise os gastos com urgência.',
      });
    } else if (rate < 0.20) {
      tips.add({
        'icon': Icons.savings_rounded,
        'color': Colors.orange,
        'text':
            'Você está poupando menos de 20%. Tente cortar gastos não essenciais para atingir a meta ideal.',
      });
    } else {
      tips.add({
        'icon': Icons.check_circle_rounded,
        'color': _success,
        'text':
            'Parabéns! Você está poupando ${(rate * 100).toStringAsFixed(0)}% da sua renda. Continue assim!',
      });
    }

    if (byCategory.containsKey('Alimentação') &&
        income > 0 &&
        (byCategory['Alimentação']! / income) > 0.30) {
      tips.add({
        'icon': Icons.restaurant_rounded,
        'color': Colors.orange,
        'text':
            'Gastos com Alimentação representam mais de 30% da sua renda. Considere cozinhar mais em casa.',
      });
    }

    if (byCategory.containsKey('Lazer') &&
        income > 0 &&
        (byCategory['Lazer']! / income) > 0.15) {
      tips.add({
        'icon': Icons.celebration_rounded,
        'color': Colors.purple,
        'text':
            'Lazer acima de 15% da renda. Divertir-se é importante, mas mantenha o equilíbrio.',
      });
    }

    tips.add({
      'icon': Icons.shield_rounded,
      'color': _accent,
      'text':
          'Mantenha uma reserva de emergência equivalente a 6 meses de despesas (R\$ ${_fmt(expense * 6)}).',
    });

    return tips;
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────
  Widget _buildSectionCard(
      {required String title,
      required IconData icon,
      required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: _primary, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _primary)),
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v.toStringAsFixed(2).replaceAll('.', ',');
}

// ── CUSTOM PAINTERS ────────────────────────────────────────────────────────

class _PieChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> entries;
  final List<Color> colors;
  final double total;

  _PieChartPainter(this.entries, this.colors, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.height / 2 - 10;
    double startAngle = -3.14159 / 2;

    for (int i = 0; i < entries.length; i++) {
      final sweep = (entries[i].value / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        paint,
      );
      // Borda branca entre fatias
      final border = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        border,
      );
      startAngle += sweep;
    }

    // Buraco central (donut)
    canvas.drawCircle(
        center,
        radius * 0.52,
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LineChartPainter extends CustomPainter {
  final List<double> points;
  final Color color;

  _LineChartPainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final minY = points.reduce((a, b) => a < b ? a : b);
    final maxY = points.reduce((a, b) => a > b ? a : b);
    final rangeY = (maxY - minY).abs() < 0.01 ? 1.0 : maxY - minY;

    double x(int i) => i / (points.length - 1) * size.width;
    double y(double v) =>
        size.height - ((v - minY) / rangeY * (size.height - 32)) - 16;

    // Área preenchida
    final fillPath = Path()..moveTo(x(0), size.height);
    for (int i = 0; i < points.length; i++) {
      fillPath.lineTo(x(i), y(points[i]));
    }
    fillPath.lineTo(x(points.length - 1), size.height);
    fillPath.close();
    canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    // Linha
    final linePath = Path()..moveTo(x(0), y(points[0]));
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(x(i), y(points[i]));
    }
    canvas.drawPath(
        linePath,
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    // Pontos
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(Offset(x(i), y(points[i])), 4,
          Paint()..color = color);
      canvas.drawCircle(Offset(x(i), y(points[i])), 2,
          Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
