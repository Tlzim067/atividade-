import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/transaction_viewmodel.dart';
import '../viewmodels/crypto_viewmodel.dart';
import 'transaction_history_view.dart';
import 'financial_insights_view.dart';

class DashboardView extends ConsumerStatefulWidget {
  final int userId;
  const DashboardView({Key? key, required this.userId}) : super(key: key);

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView>
    with TickerProviderStateMixin {
  double _savingsGoal = 0.0;
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  late PageController _marketPageCtrl;
  int _marketPage = 0;

  static const Color _primary = Color(0xFF1B3A5C);
  static const Color _accent  = Color(0xFF2D7DD2);
  static const Color _success = Color(0xFF2ECC71);
  static const Color _danger  = Color(0xFFE74C3C);
  static const Color _bg      = Color(0xFFF4F6F9);
  static const Color _cardBg  = Colors.white;

  @override
  void initState() {
    super.initState();
    _fadeCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
    _slideCtrl.forward();

    _marketPageCtrl = PageController();

    // Auto-avança o carousel a cada 4 segundos
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return false;
      final next = (_marketPage + 1) % 3;
      _marketPageCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      return true;
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _marketPageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txState    = ref.watch(transactionProvider(widget.userId));
    final cryptoAsync = ref.watch(cryptoViewModelProvider);
    final recentTx   = txState.transactions.take(5).toList();
    final totalSaved = txState.transactions.where((t) => t.category == 'Poupança').fold(0.0, (sum, t) => t.type == 'Entrada' ? sum + t.amount : sum - t.amount);
    final availableBalance = txState.transactions.where((t) => t.type == 'Entrada' && t.category != 'Poupança').fold(0.0, (sum, t) => sum + t.amount) - txState.transactions.where((t) => t.type == 'Saída' && t.category != 'Poupança').fold(0.0, (sum, t) => sum + t.amount) + txState.transactions.where((t) => t.type == 'Saída' && t.category == 'Poupança').fold(0.0, (sum, t) => sum + t.amount);
    final normalIncome = txState.transactions.where((t) => t.type == 'Entrada' && t.category != 'Poupança').fold(0.0, (sum, t) => sum + t.amount);
    final normalExpense = txState.transactions.where((t) => t.type == 'Saída' && t.category != 'Poupança').fold(0.0, (sum, t) => sum + t.amount);
    final savingsWithdraw = txState.transactions.where((t) => t.type == 'Saída' && t.category == 'Poupança').fold(0.0, (sum, t) => sum + t.amount);
    final savingsRate = txState.totalIncome == 0
        ? 0.0
        : ((txState.totalIncome - txState.totalExpense) / txState.totalIncome).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.account_balance, color: Colors.white70, size: 20),
            SizedBox(width: 8),
            Text('CapitalFlow Pro',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          // Insights — azul vibrante
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                elevation: 0,
              ),
              icon: const Icon(Icons.analytics_outlined, size: 16),
              label: const Text('Insights', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => FinancialInsightsView(userId: widget.userId))),
            ),
          ),
          // Histórico — verde
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                elevation: 0,
              ),
              icon: const Icon(Icons.list_alt_rounded, size: 16),
              label: const Text('Histórico', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => TransactionHistoryView(userId: widget.userId))),
            ),
          ),
          // Sair — vermelho
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                elevation: 0,
              ),
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Sair', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
            ),
          ),
        ],
      ),
      body: txState.isLoading
          ? _buildSkeleton()
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopCards(txState),
                      const SizedBox(height: 20),
                      _buildSavingsCard(savingsRate, totalSaved),
                      const SizedBox(height: 20),
                      _buildBarChart(txState),
                      const SizedBox(height: 20),
                      _buildMarketCarousel(cryptoAsync),
                      const SizedBox(height: 20),
                      _buildRecentTransactions(recentTx),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text('Novo Lançamento', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddTransactionModal(context, ref),
      ),
    );
  }

  // ── TOP CARDS ──────────────────────────────────────────────────────────────
  Widget _buildTopCards(TransactionState txState) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B3A5C), Color(0xFF2D5F8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SALDO DISPONÍVEL',
                  style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('R\$ ${_fmt(txState.balance)}',
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildMiniCard('Receitas', 'R\$ ${_fmt(txState.totalIncome)}', Icons.arrow_upward_rounded, _success)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMiniCard('Despesas', 'R\$ ${_fmt(txState.totalExpense)}', Icons.arrow_downward_rounded, _danger)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Transações', '${txState.transactions.length}', Icons.receipt_long_rounded, _accent)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Categorias', '${txState.transactions.map((t) => t.category).toSet().length}', Icons.category_rounded, const Color(0xFF8E44AD))),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
        ],
      ),
    );
  }

  // ── POUPANÇA ───────────────────────────────────────────────────────────────
  Widget _buildSavingsCard(double rate, double totalSaved) {
    final pct = rate * 100;
    final color = pct >= 20 ? _success : pct >= 10 ? Colors.orange : _danger;
    final label = pct >= 20 ? 'Excelente! Você está poupando bem.' : pct >= 10 ? 'Regular. Tente chegar a 20%.' : 'Atenção! Despesas muito altas.';

    return _sectionCard(
      title: 'Poupanca', icon: Icons.savings_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
              Text('${pct.toStringAsFixed(1)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: rate, minHeight: 10, backgroundColor: Colors.grey[200], color: color),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total guardado em Poupanca:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('R\$ ${totalSaved.toStringAsFixed(2)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green[700])),
            ],
          ),
        ],
      ),
    );
  }

  // ── GRÁFICO DE BARRAS ──────────────────────────────────────────────────────
  Widget _buildBarChart(TransactionState txState) {
    final max = [txState.totalIncome, txState.totalExpense].reduce((a, b) => a > b ? a : b);
    return _sectionCard(
      title: 'Receitas vs Despesas', icon: Icons.bar_chart_rounded,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildBar('Receitas', txState.totalIncome, max, _success),
          _buildBar('Despesas', txState.totalExpense, max, _danger),
          _buildBar('Saldo', txState.balance.clamp(0, double.infinity), max, _accent),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double value, double max, Color color) {
    final height = max == 0 ? 0.0 : (value / max) * 120;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('R\$ ${_fmt(value)}', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          width: 64, height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  // ── CAROUSEL DE COTAÇÕES ───────────────────────────────────────────────────
  Widget _buildMarketCarousel(AsyncValue cryptoAsync) {
    return _sectionCard(
      title: 'Mercado em Tempo Real', icon: Icons.show_chart_rounded,
      child: cryptoAsync.when(
        loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2))),
        error: (_, __) => Row(children: [
          Icon(Icons.cloud_off_rounded, color: Colors.red[300]),
          const SizedBox(width: 8),
          const Expanded(child: Text('Cotações indisponíveis.', style: TextStyle(color: Colors.grey))),
        ]),
        data: (currencies) => Column(
          children: [
            SizedBox(
              height: 90,
              child: PageView.builder(
                controller: _marketPageCtrl,
                itemCount: currencies.length,
                onPageChanged: (i) => setState(() => _marketPage = i),
                itemBuilder: (context, i) {
                  final coin = currencies[i];
                  final isPos = !coin.pctChange.startsWith('-');
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primary, _accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(coin.name, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('R\$ ${coin.buy}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isPos ? _success.withOpacity(0.2) : _danger.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(isPos ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: isPos ? _success : _danger, size: 16),
                              Text('${isPos ? '+' : ''}${coin.pctChange}%', style: TextStyle(color: isPos ? _success : _danger, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(currencies.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _marketPage == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _marketPage == i ? _accent : Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  // ── TRANSAÇÕES RECENTES ────────────────────────────────────────────────────
  Widget _buildRecentTransactions(List recentTx) {
    return _sectionCard(
      title: 'Lançamentos Recentes', icon: Icons.receipt_rounded,
      trailing: TextButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TransactionHistoryView(userId: widget.userId))),
        child: const Text('Ver todos', style: TextStyle(fontSize: 12, color: _accent)),
      ),
      child: recentTx.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Nenhum lançamento ainda.', style: TextStyle(color: Colors.grey))),
            )
          : Column(
              children: recentTx.map<Widget>((tx) {
                final isIncome = tx.type == 'Entrada';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: isIncome ? _success.withOpacity(0.1) : _danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: isIncome ? _success : _danger, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                            Text(tx.category, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${isIncome ? '+' : '-'} R\$ ${_fmt(tx.amount)}',
                              style: TextStyle(color: isIncome ? _success : _danger, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(tx.date, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ── SKELETON ───────────────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(4, (i) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: i == 0 ? 180 : 100,
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
        )),
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────
  Widget _sectionCard({required String title, required IconData icon, required Widget child, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: _primary, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _primary)),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  // ── MODAL ──────────────────────────────────────────────────────────────────
  void _showAddTransactionModal(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    String title = '';
    double amount = 0.0;
    String type = 'Entrada';
    String category = 'Moradia';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 28, left: 24, right: 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text(type == 'Entrada' ? ' Registrar Entrada' : ' Registrar Saída',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Descrição', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.edit_note_rounded)),
                  validator: (v) => v == null || v.isEmpty ? 'Insira uma descrição' : null,
                  onSaved: (v) => title = v!,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Valor (R\$)', hintText: '0,00', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.attach_money_rounded)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Digite um valor';
                    if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Valor inválido';
                    return null;
                  },
                  onSaved: (v) => amount = double.parse(v!.replaceAll(',', '.')),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: InputDecoration(labelText: 'Tipo', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.swap_horiz_rounded)),
                  items: const [
                    DropdownMenuItem(value: 'Entrada', child: Text('Entrada (Receita)')),
                    DropdownMenuItem(value: 'Saída', child: Text('Saída (Despesa)')),
                  ],
                  onChanged: (v) => setModalState(() => type = v!),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(labelText: 'Categoria', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.label_rounded)),
                  items: const [
                    DropdownMenuItem(value: 'Moradia', child: Text(' Moradia')),
                    DropdownMenuItem(value: 'Alimentação', child: Text(' Alimentação')),
                    DropdownMenuItem(value: 'Transporte', child: Text(' Transporte')),
                    DropdownMenuItem(value: 'Salário', child: Text(' Salário')),
                    DropdownMenuItem(value: 'Saúde', child: Text(' Saúde')),
                    DropdownMenuItem(value: 'Lazer', child: Text(' Lazer')),
                    DropdownMenuItem(value: 'Outros', child: Text(' Outros')),
                    DropdownMenuItem(value: 'Poupança', child: Text(' Poupança')),
                  ],
                  onChanged: (v) => category = v!,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: type == 'Entrada' ? _success : _danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      ref.read(transactionProvider(widget.userId).notifier).addTransaction(title, amount, type, category);
                      Navigator.pop(context);
                    }
                  },
                  child: Text(type == 'Entrada' ? 'Confirmar Entrada' : 'Confirmar Saída',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
