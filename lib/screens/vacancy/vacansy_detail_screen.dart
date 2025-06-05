import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/info_row.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class VacansyDetailScreen extends StatefulWidget {
  final String vacansyId;
  const VacansyDetailScreen({super.key, required this.vacansyId});

  @override
  State<VacansyDetailScreen> createState() => _VacansyDetailScreenState();
}

class _VacansyDetailScreenState extends State<VacansyDetailScreen> {
  Map<String, dynamic>? vacansy;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVacansy();
  }

  Future<void> _loadVacansy() async {
    final snap =
        await FirebaseFirestore.instance
            .collection('vacancies')
            .doc(widget.vacansyId)
            .get();

    if (!mounted) return;

    setState(() {
      vacansy = snap.data();
      isLoading = false;
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Не удалось начать звонок')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (vacansy == null) {
      return const Scaffold(body: Center(child: Text('Вакансия не найдена')));
    }

    final String phone = vacansy!['phone'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Вакансия'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.bg,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //------------------ карточка ------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vacansy!['title'] ?? 'Без названия',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    vacansy!['description'] ?? '',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  InfoRow(
                    label: 'Тип',
                    value: vacansy!['type'] ?? 'Не указано',
                    hasTopBorder: true,
                    hasBottomBorder: true,
                  ),
                  InfoRow(
                    label: 'Компания',
                    value: vacansy!['company'] ?? 'Не указано',
                    hasBottomBorder: true,
                  ),
                  InfoRow(
                    label: 'Город',
                    value: vacansy!['location'] ?? 'Не указано',
                    hasBottomBorder: true,
                  ),
                  InfoRow(
                    label: 'Телефон',
                    value: phone.isNotEmpty ? phone : 'Не указан',
                    hasBottomBorder: true,
                  ),
                ],
              ),
            ),

            const Spacer(),

            //------------------ Кнопка Позвонить -------------------
            if (phone.isNotEmpty)
              Btn(
                text: 'Позвонить',
                theme: 'violet',
                onPressed: () => _makePhoneCall(phone),
              )
            else
              Center(
                child: Text(
                  'Номер телефона не указан',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
