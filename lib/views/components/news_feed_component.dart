import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NewsFeedComponent extends StatelessWidget {
  const NewsFeedComponent({Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> fetchMarketData() async {
    final List<Map<String, dynamic>> cards = [];

    try {
      final cryptoUrl = Uri.parse(
        'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,solana&vs_currencies=brl&include_24hr_change=true'
      );
      final cryptoRes = await http.get(cryptoUrl, headers: {
        'Accept': 'application/json',
        'Access-Control-Allow-Origin': '*',
      }).timeout(const Duration(seconds: 10));

      if (cryptoRes.statusCode == 200) {
        final data = json.decode(cryptoRes.body) as Map<String, dynamic>;
        final assets = {
          'bitcoin':  'Bitcoin (BTC)',
          'ethereum': 'Ethereum (ETH)',
          'solana':   'Solana (SOL)',
        };
        assets.forEach((id, label) {
          if (data.containsKey(id)) {
            final price = (data[id]['brl'] as num).toDouble();
            final change = (data[id]['brl_24h_change'] as num).toDouble();
            cards.add({
              'title': label,
              'value': 'R\$ ${price >= 1000 ? price.toStringAsFixed(0) : price.toStringAsFixed(2)}',
              'change': '${change >= 0 ? "alta" : "baixa"} ${change.abs().toStringAsFixed(2)}%',
              'up': change >= 0,
              'type': 'crypto',
            });
          }
        });
      }
    } catch (_) {}

    try {
      final fxUrl = Uri.parse('https://open.er-api.com/v6/latest/USD');
      final fxRes = await http.get(fxUrl, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (fxRes.statusCode == 200) {
        final data = json.decode(fxRes.body);
        final rates = data['rates'] as Map<String, dynamic>;
        final brl = (rates['BRL'] as num).toDouble();
        final eur = (rates['EUR'] as num).toDouble();
        cards.addAll([
          {'title': 'Dolar (USD)', 'value': 'R\$ ${brl.toStringAsFixed(2)}', 'change': 'cotacao atual', 'up': true, 'type': 'fx'},
          {'title': 'Euro (EUR)',  'value': 'R\$ ${(brl / eur).toStringAsFixed(2)}', 'change': 'cotacao atual', 'up': true, 'type': 'fx'},
        ]);
      }
    } catch (_) {}

    if (cards.isEmpty) {
      cards.addAll([
        {'title': 'Reserve 6 meses de gastos', 'value': '', 'change': 'dica financeira', 'up': true, 'type': 'tip'},
        {'title': 'Diversifique seus investimentos', 'value': '', 'change': 'dica financeira', 'up': true, 'type': 'tip'},
        {'title': 'Acompanhe o IPCA todo mes', 'value': '', 'change': 'dica financeira', 'up': true, 'type': 'tip'},
      ]);
    }

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchMarketData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            height: 90,
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final items = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.show_chart, size: 15, color: Colors.blueGrey[600]),
              const SizedBox(width: 6),
              Text('Mercado ao Vivo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.blueGrey[700])),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(8)),
                child: Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green[800])),
              ),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: PageView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isUp = item['up'] as bool;
                  final isCrypto = item['type'] == 'crypto';
                  final isTip = item['type'] == 'tip';
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    color: isTip ? Colors.blue[50] : (isCrypto ? (isUp ? Colors.green[50] : Colors.red[50]) : Colors.indigo[50]),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: isTip
                          ? Center(child: Text(item['title'] as String,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue[800]),
                              textAlign: TextAlign.center))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item['title'] as String,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(item['value'] as String,
                                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                                            color: isCrypto ? (isUp ? Colors.green[700] : Colors.red[700]) : Colors.indigo[700])),
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isCrypto ? (isUp ? Colors.green[100] : Colors.red[100]) : Colors.indigo[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(item['change'] as String,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                              color: isCrypto ? (isUp ? Colors.green[800] : Colors.red[800]) : Colors.indigo[800])),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
