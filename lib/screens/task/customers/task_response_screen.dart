import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:nerobot/components/placeholder/customers_none_tasks.dart';
import 'package:nerobot/router/app_router.gr.dart';

@RoutePage()
class TaskResponseScreen extends StatelessWidget {
  final String taskId;

  const TaskResponseScreen({super.key, required this.taskId});

  Future<List<Map<String, dynamic>>> _fetchResponses() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('responses')
            .where('order', isEqualTo: taskId)
            .get();

    final usersRef = FirebaseFirestore.instance.collection('users');

    final responsesWithUserData = await Future.wait(
      snapshot.docs.map((doc) async {
        final data = doc.data();
        final userId = data['respondent'];

        DocumentSnapshot userDoc = await usersRef.doc(userId).get();
        final userData = userDoc.data() as Map<String, dynamic>? ?? {};

        return {
          'photo': userData['image_url'] ?? '',
          'firstName': userData['name']?.split(' ')?.first ?? 'Без имени',
          'lastName': userData['name']?.split(' ')?.last ?? '',
          'created_at': _formatDate(data['created_time']),
          'rating': data['respondent_rating'] ?? 0,
          'text': data['cover_letter'] ?? '',
          'roomUUID': doc.id,
        };
      }),
    );

    return responsesWithUserData;
  }

  String _formatDate(dynamic timestamp) {
    try {
      final millis =
          timestamp is int ? timestamp : int.tryParse(timestamp.toString());
      if (millis == null) return '';
      final date = DateTime.fromMillisecondsSinceEpoch(millis);
      return '${date.day}.${date.month}.${date.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отклики', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          GestureDetector(
            onTap:
                () => AutoRouter.of(
                  context,
                ).push(TaskDetailCustomerRoute(taskId: taskId)),
            child: Container(
              padding: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.info_outline_rounded, size: 28),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchResponses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const CustomersNoneTasks(
              title: "Еще никто не откликнулся",
              text:
                  "Как только кто-то проявит интерес к вашему заданию, "
                  "они появятся здесь. Следите за уведомлениями!",
              btn: false,
            );
          }

          final responses = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: responses.length,
            itemBuilder: (context, index) {
              final response = responses[index];
              return GestureDetector(
                onTap:
                    () => AutoRouter.of(context).push(
                      ChatsRoute(chatsId: response['roomUUID'], taskId: taskId),
                    ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundImage:
                            response['photo'].isNotEmpty
                                ? NetworkImage(response['photo'])
                                : const AssetImage('assets/images/splash.png')
                                    as ImageProvider,
                        radius: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${response['firstName']} ${response['lastName']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  response['created_at'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  response['rating'].toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              response['text'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
