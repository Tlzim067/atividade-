import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/transaction_viewmodel.dart';

class TransactionHistoryView extends ConsumerStatefulWidget {
  final int userId;
  const TransactionHistoryView({Key? key, required this.userId}) : super(key: key);

  @override
  ConsumerState<TransactionHistoryView> createState() => _TransactionHistoryViewState();
}

class _TransactionHistoryViewState extends ConsumerState<TransactionHistoryView> {
  String _selectedFilter = 'Todos';

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionProvider(widget.userId));
    final filteredList = txState.transactions.where((tx) {
      if (_selectedFilter == 'Entradas') return tx.type == 'Entrada';
      if (_selectedFilter == 'Saidas') return tx.type == 'Saída';
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B3A5C),
        title: const Text('Histórico', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Todos', label: Text('Todos')),
                ButtonSegment(value: 'Entradas', label: Text('Entradas')),
                ButtonSegment(value: 'Saidas', label: Text('Saídas')),
              ],
              selected: {_selectedFilter},
              onSelectionChanged: (s) => setState(() => _selectedFilter = s.first),
            ),
          ),
          Expanded(
            child: filteredList.isEmpty
                ? const Center(child: Text('Nenhum registro encontrado.'))
                : ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      final isIncome = item.type == 'Entrada';
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isIncome ? Colors.green[100] : Colors.red[100],
                            child: Icon(
                              isIncome ? Icons.keyboard_double_arrow_up : Icons.keyboard_double_arrow_down,
                              color: isIncome ? Colors.green[800] : Colors.red[800],
                            ),
                          ),
                          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('\${item.category} • \${item.date}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'R\$ ${item.amount.toStringAsFixed(2).replaceAll(".", ",")}',
                                style: TextStyle(color: isIncome ? Colors.green[700] : Colors.red[700], fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                                onPressed: () => ref.read(transactionProvider(widget.userId).notifier).removeTransaction(item.id!),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
