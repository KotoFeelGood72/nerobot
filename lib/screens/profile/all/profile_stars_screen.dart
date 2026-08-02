import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nerobot/components/ui/info_row.dart';
import 'package:nerobot/constants/app_colors.dart';

@RoutePage()
class ProfileStarsScreen extends StatefulWidget {
  const ProfileStarsScreen({super.key});

  @override
  State<ProfileStarsScreen> createState() => _ProfileStarsScreenState();
}

class _ProfileStarsScreenState extends State<ProfileStarsScreen> {
  bool _loading = true;
  String? _error;

  String _ratingLabel = '—';
  int _tasksCompleted = 0;
  int _totalEarnings = 0;
  List<_ReviewVm> _reviews = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _loading = false;
        _error = 'Нужно войти в аккаунт';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userSnap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userSnap.data() ?? {};

      // Завершённые заказы, где пользователь — исполнитель
      final ordersSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('workers', arrayContains: uid)
          .get();

      final doneStatuses = {'success', 'done'};
      var completed = 0;
      var earnings = 0;

      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        final status = data['status']?.toString();
        if (!doneStatuses.contains(status)) continue;
        completed++;
        final price = data['price'];
        if (price is num) {
          earnings += price.round();
        } else {
          earnings += int.tryParse(price?.toString() ?? '') ?? 0;
        }
      }

      // Отзывы об этом пользователе
      final reviewsSnap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('to_user', isEqualTo: uid)
          .get();

      final reviews = reviewsSnap.docs.map((doc) {
        final d = doc.data();
        return _ReviewVm.fromMap(d);
      }).toList()
        ..sort((a, b) => b.createdMs.compareTo(a.createdMs));

      // Рейтинг: среднее по отзывам, иначе поле users.rating
      String ratingLabel = '—';
      if (reviews.isNotEmpty) {
        final withScore = reviews.where((r) => r.score != null).toList();
        if (withScore.isNotEmpty) {
          final avg =
              withScore.map((r) => r.score!).reduce((a, b) => a + b) /
                  withScore.length;
          ratingLabel = avg.toStringAsFixed(1);
        } else {
          final positive = reviews.where((r) => r.isPositive).length;
          ratingLabel =
              (positive / reviews.length * 5).toStringAsFixed(1);
        }
      } else {
        final raw = userData['rating'];
        if (raw is num && raw > 0) {
          ratingLabel = raw.toStringAsFixed(1);
        } else if (raw != null &&
            raw.toString().isNotEmpty &&
            raw.toString() != '0') {
          ratingLabel = raw.toString();
        }
      }

      // Фоллбек на поля профиля, если заказы ещё не размечены workers
      if (completed == 0) {
        final stored = userData['completed_tasks'];
        if (stored is num) completed = stored.round();
      }
      if (earnings == 0) {
        final stored = userData['total_earnings'];
        if (stored is num) earnings = stored.round();
      }

      if (!mounted) return;
      setState(() {
        _ratingLabel = ratingLabel;
        _tasksCompleted = completed;
        _totalEarnings = earnings;
        _reviews = reviews;
        _loading = false;
      });
    } catch (e) {
      debugPrint('ProfileStars load error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить данные';
      });
    }
  }

  String _formatMoney(int value) {
    final fmt = NumberFormat.decimalPattern('ru');
    return '${fmt.format(value)} ₽';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Рейтинг')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _load, child: const Text('Повторить')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InfoRow(label: 'Рейтинг', value: _ratingLabel),
                        InfoRow(
                          label: 'Выполнено',
                          value: '$_tasksCompleted заданий',
                          hasBottomBorder: true,
                          hasTopBorder: true,
                        ),
                        InfoRow(
                          label: 'Заработано',
                          value: _formatMoney(_totalEarnings),
                          hasBottomBorder: true,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Отзывы',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_reviews.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text(
                              'Пока нет отзывов',
                              style: TextStyle(color: AppColors.gray),
                            ),
                          )
                        else
                          ..._reviews.map(
                            (review) => ReviewCard(
                              username: review.username,
                              date: review.dateLabel,
                              comment: review.comment,
                              isPositive: review.isPositive,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _ReviewVm {
  final String username;
  final String comment;
  final bool isPositive;
  final double? score;
  final int createdMs;
  final String dateLabel;

  const _ReviewVm({
    required this.username,
    required this.comment,
    required this.isPositive,
    required this.createdMs,
    required this.dateLabel,
    this.score,
  });

  factory _ReviewVm.fromMap(Map<String, dynamic> d) {
    final createdRaw = d['created_date'] ?? d['createdAt'] ?? d['date'];
    int createdMs = 0;
    if (createdRaw is Timestamp) {
      createdMs = createdRaw.millisecondsSinceEpoch;
    } else if (createdRaw is num) {
      createdMs = createdRaw.toInt();
    } else if (createdRaw is String) {
      createdMs = DateTime.tryParse(createdRaw)?.millisecondsSinceEpoch ?? 0;
    }

    final scoreRaw = d['rating'] ?? d['score'];
    double? score;
    if (scoreRaw is num) score = scoreRaw.toDouble();

    final isPositive = d['isPositive'] is bool
        ? d['isPositive'] as bool
        : (score == null ? true : score >= 4);

    final username = (d['from_name'] ??
            d['username'] ??
            d['authorName'] ??
            'Пользователь')
        .toString();

    final comment =
        (d['text'] ?? d['comment'] ?? d['message'] ?? '').toString();

    final dateLabel = createdMs > 0
        ? DateFormat('dd.MM.yyyy').format(
            DateTime.fromMillisecondsSinceEpoch(createdMs).toLocal(),
          )
        : (d['date']?.toString() ?? '');

    return _ReviewVm(
      username: username,
      comment: comment,
      isPositive: isPositive,
      score: score,
      createdMs: createdMs,
      dateLabel: dateLabel,
    );
  }
}

class ReviewCard extends StatelessWidget {
  final String username;
  final String date;
  final String comment;
  final bool isPositive;

  const ReviewCard({
    super.key,
    required this.username,
    required this.date,
    required this.comment,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.yellow,
                  radius: 20,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(date, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isPositive ? Icons.add : Icons.remove,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(comment, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
