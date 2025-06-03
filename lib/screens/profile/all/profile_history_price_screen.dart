import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/info_row.dart';
import 'package:nerobot/constants/app_colors.dart';

@RoutePage()
class ProfileHistoryPriceScreen extends StatelessWidget {
  const ProfileHistoryPriceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Статичные данные истории платежей
    final List<Map<String, String>> paymentHistory = [
      {'price': '299', 'create_date': '2025-05-01'},
      {'price': '299', 'create_date': '2025-02-01'},
      {'price': '299', 'create_date': '2024-11-01'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('История платежей')),
      body: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(width: 1, color: AppColors.border)),
        ),
        padding: const EdgeInsets.all(16),
        child:
            paymentHistory.isEmpty
                ? const Center(
                  child: Text(
                    'История платежей отсутствует',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                : ListView.builder(
                  itemCount: paymentHistory.length,
                  itemBuilder: (context, index) {
                    final item = paymentHistory[index];
                    return InfoRow(
                      label: '${item['price']} ₽',
                      value: item['create_date'] ?? '',
                      hasBottomBorder: true,
                    );
                  },
                ),
      ),
    );
  }
}
