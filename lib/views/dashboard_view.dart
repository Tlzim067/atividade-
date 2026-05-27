import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/transaction_viewmodel.dart';
import '../viewmodels/crypto_viewmodel.dart'; // Import do novo ViewModel da API
import 'transaction_history_view.dart';
import 'financial_insights_view.dart';

class DashboardView extends ConsumerWidget {
  final int userId;
  const DashboardView({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionProvider(userId));
    // Escuta o estado da API de Cotações
    final cryptoAsync = ref.watch(cryptoViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard CapitalFlow'),
        backgroundColor: Colors.green[50],
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Colors.green),
            tooltip: 'Visão de Insights',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => FinancialInsightsView(userId: userId))),
          ),
          IconButton(
            icon: const Icon(Icons.list_alt_rounded, color: Colors.green),
            tooltip: 'Histórico',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => TransactionHistoryView(userId: userId))),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
          ),
        ],
      ),
      body: txState.isLoading
          ? _buildSkeletonLoading()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- CARD DE SALDO CONSOLIDADO ---
                  Card(
                    elevation: 4,
                    color: Colors.green[700],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Text('SALDO ATUAL CONSOLIDADO',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  letterSpacing: 1.2)),
                          const SizedBox(height: 6),
                          Text(
                            'R\$ ${txState.balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 34,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildAmountRow('Receitas', txState.totalIncome,
                                  Colors.green[200]!),
                              _buildAmountRow('Despesas', txState.totalExpense,
                                  Colors.red[200]!),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- SEÇÃO DA API REAL (MERCADO FINANCEIRO) ---
                  const Row(
                    children: [
                      Icon(Icons.bar_chart_rounded, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Mercado em Tempo Real',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Consumo reativo do FutureProvider da API (Cobre UX Superior)
                  cryptoAsync.when(
                    // 1. Estado de Carregamento da API
                    loading: () => Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(
                            child: CircularProgressIndicator(color: Colors.green)),
                      ),
                    ),
                    // 2. Estado de Erro de Conexão/Rede
                    error: (err, stack) => Card(
                      elevation: 2,
                      color: Colors.red[50],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_off_rounded, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Não foi possível carregar as cotações mundiais. Verifique sua conexão.',
                                style: TextStyle(color: Colors.red[900], fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 3. Estado de Sucesso (Dados vindos da internet)
                    data: (currencies) => Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: currencies.map((coin) {
                            final isPositive = !coin.pctChange.startsWith('-');
                            return Column(
                              children: [
                                Text(coin.name.split('/')[0],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54)),
                                const SizedBox(height: 6),
                                Text('R\$ ${coin.buy}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      isPositive
                                          ? Icons.arrow_drop_up_rounded
                                          : Icons.arrow_drop_down_rounded,
                                      color: isPositive
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    Text(
                                      '${isPositive ? '+' : ''}${coin.pctChange}%',
                                      style: TextStyle(
                                          color: isPositive
                                              ? Colors.green
                                              : Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- LISTA ESTÁTICA DE DICAS (EDUCACIONAL) ---
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Dicas de Saúde Financeira',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: const [
                        Card(
                          child: ListTile(
                            leading: Icon(Icons.savings_rounded, color: Colors.orange),
                            title: Text('A Regra de Ouro dos 50/30/20'),
                            subtitle: Text(
                                'Separe 50% para necessidades básicas, 30% para desejos pessoais e guarde 20% para o futuro.'),
                          ),
                        ),
                        Card(
                          child: ListTile(
                            leading: Icon(Icons.shield_rounded, color: Colors.blue),
                            title: Text('Reserva de Emergência'),
                            subtitle: Text(
                                'Tente manter o equivalente a 6 meses do seu custo de vida guardado em um local de resgate rápido.'),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Lançar Movimentação'),
        onPressed: () => _showAddTransactionModal(context, ref),
      ),
    );
  }

  Widget _buildAmountRow(String label, double val, Color textCol) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        Text('R\$ ${val.toStringAsFixed(2)}',
            style: TextStyle(
                color: textCol, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
              color: Colors.grey[300], borderRadius: BorderRadius.circular(16)),
          child: const Center(
              child: CircularProgressIndicator(color: Colors.green)),
        ),
      ),
    );
  }

  void _showAddTransactionModal(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    String title = '';
    double amount = 0.0;
    String type = 'Entrada';
    String category = 'Moradia';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Novo Lançamento Real',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                    labelText: 'Descrição/Título', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty
                    ? 'Insira um título descritivo'
                    : null,
                onSaved: (v) => title = v!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                    labelText: 'Valor Monetário (R\$)',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || double.tryParse(v) == null
                    ? 'Digite um valor numérico válido'
                    : null,
                onSaved: (v) => amount = double.parse(v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(
                    labelText: 'Natureza da Operação',
                    border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(
                      value: 'Entrada', child: Text('Entrada (Receitas)')),
                  DropdownMenuItem(
                      value: 'Saída', child: Text('Saída (Despesas)')),
                ],
                onChanged: (v) => type = v!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(
                    labelText: 'Categoria', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Moradia', child: Text('Moradia')),
                  DropdownMenuItem(
                      value: 'Alimentação', child: Text('Alimentação')),
                  DropdownMenuItem(
                      value: 'Transporte', child: Text('Transporte')),
                  DropdownMenuItem(value: 'Salário', child: Text('Salário')),
                  DropdownMenuItem(value: 'Outros', child: Text('Outros')),
                ],
                onChanged: (v) => category = v!,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    ref
                        .read(transactionProvider(userId).notifier)
                        .addTransaction(title, amount, type, category);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Confirmar Lançamento'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}