import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/models/payment.dart';
import 'package:nerobot/models/subscription.dart';
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/modal_utils.dart';

import 'package:nerobot/utils/subscription_utils.dart';

@RoutePage()
class ProfileSubscriptionScreen extends StatefulWidget {
  const ProfileSubscriptionScreen({super.key});

  @override
  State<ProfileSubscriptionScreen> createState() =>
      _ProfileSubscriptionScreenState();
}

class _ProfileSubscriptionScreenState extends State<ProfileSubscriptionScreen> {
  int _selectedSubscriptionIndex = 0;
  int _selectedPaymentMethodIndex = 0;
  Subscription? currentSubscription;
  bool isLoading = true;

  final List<Map<String, dynamic>> staticPlans = const [
    {'period': 1, 'price': 299},
    {'period': 3, 'price': 699},
    {'period': 12, 'price': 1999},
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentSubscription();
  }

  Future<void> _loadCurrentSubscription() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final subscription = await SubscriptionUtils.getActiveSubscription(
        user.uid,
      );

      if (mounted) {
        setState(() {
          currentSubscription = subscription;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка при загрузке подписки: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _getSubscriptionStatusText() {
    if (currentSubscription == null) {
      return 'Нет активной подписки';
    }
    if (currentSubscription!.status == 'cancelled') {
      return 'Подписка отменена';
    }
    if (!currentSubscription!.isActive) {
      return 'Подписка истекла';
    }
    return currentSubscription!.remainingTimeText;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Подписка'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCurrentSubscription,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoRow('Истечёт через', _getSubscriptionStatusText()),
              const SizedBox(height: 16),
              Btn(
                theme: 'white',
                text: 'История платежей',
                onPressed:
                    () =>
                        AutoRouter.of(context).push(ProfileHistoryPriceRoute()),
              ),
              const SizedBox(height: 24),
              const Text(
                'Выберите подписку',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:
                    staticPlans.asMap().entries.map((entry) {
                      final index = entry.key;
                      final plan = entry.value;
                      return Flexible(
                        child: _buildSubscriptionOption(
                          index,
                          plan['period'].toString(),
                          '${plan['period']} ${_getPeriodText(plan['period'])}',
                          '${plan['price']} ₽',
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Выберите способ оплаты',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildPaymentMethodOption(0, 'МИР/Visa/Mastercard'),
              Divider(height: .5, color: AppColors.light.withOpacity(0.4)),
              _buildPaymentMethodOption(1, 'СБП'),
              const SizedBox(height: 24),
              Btn(
                text: 'Оплатить',
                theme: 'violet',
                onPressed: _processPayment,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _showCancelSubscriptionBottomSheet(context),
                child: const Text(
                  'Отменить подписку',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: _loadCurrentSubscription,
                child: const Text(
                  'Обновить данные',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(width: 1, color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildSubscriptionOption(
    int index,
    String duration,
    String period,
    String price,
  ) {
    bool isSelected = _selectedSubscriptionIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSubscriptionIndex = index;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      offset: const Offset(0, 1),
                      blurRadius: 0,
                    ),
                  ]
                  : [],
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isSelected ? AppColors.violet : AppColors.yellow,
              ),
              child: Text(
                duration,
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
            ),
            Text(period),
            Text(price, style: const TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(int index, String method) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(method),
      trailing: Radio<int>(
        value: index,
        groupValue: _selectedPaymentMethodIndex,
        onChanged: (value) {
          setState(() {
            _selectedPaymentMethodIndex = value!;
          });
        },
        activeColor: AppColors.violet,
      ),
      onTap: () {
        setState(() {
          _selectedPaymentMethodIndex = index;
        });
      },
    );
  }

  void _showCancelSubscriptionBottomSheet(BuildContext context) {
    showCustomModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Отменить подписку?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              const SizedBox(height: 8),
              const Text(
                'После отмены подписка будет деактивирована. Вы сможете оформить новую подписку в любое время.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Btn(
                text: 'Оставить подписку',
                theme: 'violet',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 8),
              Btn(
                text: 'Да, отменить подписку',
                theme: 'white',
                textColor: AppColors.red,
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _cancelSubscription();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getPeriodText(int period) {
    switch (period) {
      case 1:
        return 'месяц';
      case 3:
        return 'месяца';
      case 12:
        return 'месяцев';
      default:
        return '';
    }
  }

  String _getPaymentMethodText(int index) {
    switch (index) {
      case 0:
        return 'card';
      case 1:
        return 'sbp';
      default:
        return 'other';
    }
  }

  String _getSubscriptionTypeText(int period) {
    switch (period) {
      case 1:
        return 'monthly';
      case 3:
        return 'quarterly';
      case 12:
        return 'yearly';
      default:
        return 'custom';
    }
  }

  Future<void> _processPayment() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пользователь не авторизован')),
        );
        return;
      }

      final plan = staticPlans[_selectedSubscriptionIndex];
      final amount = plan['price'].toDouble();
      final period = plan['period'] as int;
      final paymentMethod = _getPaymentMethodText(_selectedPaymentMethodIndex);
      final subscriptionType = _getSubscriptionTypeText(period);

      // Создаем платеж в Firestore
      final payment = Payment(
        id: '', // будет установлен Firestore
        userId: user.uid,
        amount: amount,
        status: 'pending',
        paymentMethod: paymentMethod,
        description: 'Подписка на ${period} ${_getPeriodText(period)}',
        createdAt: DateTime.now(),
        subscriptionType: subscriptionType,
        subscriptionPeriod: period,
        transactionId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Сохраняем платеж в Firestore
      final paymentDocRef = await FirebaseFirestore.instance
          .collection('payments')
          .add(payment.toFirestore());

      // Создаем подписку
      final now = DateTime.now();
      final endDate = now.add(Duration(days: period * 30)); // примерный расчет

      final subscription = Subscription(
        id: '',
        userId: user.uid,
        type: subscriptionType,
        period: period,
        startDate: now,
        endDate: endDate,
        status: 'active',
        amount: amount,
        paymentId: paymentDocRef.id,
      );

      await SubscriptionUtils.createSubscription(subscription);

      // Показываем успешное сообщение
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Подписка на ${period} ${_getPeriodText(period)} активирована',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Возвращаемся к профилю с обновленными данными
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при создании платежа: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelSubscription() async {
    try {
      if (currentSubscription == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Нет активной подписки для отмены'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      print('DEBUG: Отменяем подписку с ID: ${currentSubscription!.id}');

      // Обновляем статус подписки на 'cancelled'
      await SubscriptionUtils.updateSubscriptionStatus(
        currentSubscription!.id,
        'cancelled',
      );

      print('DEBUG: Статус подписки обновлен на cancelled');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Подписка успешно отменена'),
            backgroundColor: Colors.green,
          ),
        );

        // Возвращаемся к профилю с обновленными данными
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при отмене подписки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
