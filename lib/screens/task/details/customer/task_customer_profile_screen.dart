import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/Divider.dart';
import 'package:nerobot/components/ui/avatar_img.dart';
import 'package:nerobot/components/ui/info_row.dart';
import 'package:nerobot/constants/app_colors.dart';

@RoutePage()
class TaskCustomerProfileScreen extends StatelessWidget {
  final String profileCustomerId;

  const TaskCustomerProfileScreen({
    super.key,
    @PathParam('profileCustomerId') required this.profileCustomerId,
  });

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchUserProfile() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(profileCustomerId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль заказчика')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _fetchUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Профиль не найден'));
          }

          final data = snapshot.data!.data()!;
          final firstName = data['name']?.split(' ').first ?? 'Без имени';
          final lastName = data['name']?.split(' ').skip(1).join(' ') ?? '';
          final imageUrl = data['image_url'] as String?;
          final rating = (data['rating'] ?? 0).toString();
          final tasksCreated = (data['orders'] as Map?)?.length ?? 0;
          final about = data['about'] as String?;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: AppColors.bg,
              border: Border(
                top: BorderSide(width: 1, color: AppColors.border),
              ),
            ),
            child: Column(
              children: [
                const Square(),
                AvatarImg(
                  firstName: firstName,
                  lastName: lastName,
                  imageUrl: imageUrl ?? 'assets/images/splash.png',
                  isLocalImage: imageUrl == null,
                ),
                const Square(height: 32),
                InfoRow(label: 'Рейтинг', value: rating, hasBottomBorder: true),
                InfoRow(
                  label: 'Создано',
                  value: '$tasksCreated заданий',
                  hasBottomBorder: true,
                ),
                const Square(),
                Text(
                  about?.isNotEmpty == true
                      ? about!
                      : 'Этот заказчик пока не добавил описание.',
                  style: const TextStyle(color: AppColors.gray),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
