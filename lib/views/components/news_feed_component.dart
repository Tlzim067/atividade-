import 'package:flutter/material.dart';

class NewsFeedComponent extends StatelessWidget {
  const NewsFeedComponent({Key? key}) : super(key: key);

  Future<List<String>> fetchFinancialTips() async {
    await Future.delayed(const Duration(seconds: 2)); 
    return [
      "💡 Dica do dia: Monte sua reserva de emergência equivalente a 6 meses de gastos.",
      "📉 Atenção: Evite parcelamentos longos no cartão de crédito este mês.",
      "🚀 Investimentos: Diversificar sua carteira protege seu capital contra oscilações.",
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: fetchFinancialTips(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 150, height: 16, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Container(width: double.infinity, height: 12, color: Colors.grey[300]),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Text("Não foi possível carregar as dicas financeiras.");
        }

        final tips = snapshot.data!;
        return Container(
          height: 85,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: PageView.builder(
            itemCount: tips.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      tips[index],
                      style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}