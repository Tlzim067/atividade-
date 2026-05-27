import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/transaction_viewmodel.dart';

class FinancialInsightsView extends ConsumerWidget {
  final int userId;
  const FinancialInsightsView({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionProvider(userId));
    
    double healthScore = txState.totalIncome == 0 
        ? 0 
        : ((txState.totalIncome - txState.totalExpense) / txState.totalIncome).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Análise de Insights Estratégicos')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Saúde do Caixa Disponível', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: healthScore,
              minHeight: 16,
              backgroundColor: Colors.red[100],
              color: healthScore > 0.4 ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 24),
            const Text('Métricas de Absorção Contábil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildMetricCard('Aproveitamento de Receita', '${(healthScore * 100).toStringAsFixed(1)}% líquidos', Icons.pie_chart, Colors.teal),
            const SizedBox(height: 12),
            _buildMetricCard('Total Injetado (Mês)', 'R\$ ${txState.totalIncome.toStringAsFixed(2)}', Icons.arrow_upward, Colors.green),
            const SizedBox(height: 12),
            _buildMetricCard('Total Retirado (Mês)', 'R\$ ${txState.totalExpense.toStringAsFixed(2)}', Icons.arrow_downward, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color col) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: col, size: 32),
        title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        trailing: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}