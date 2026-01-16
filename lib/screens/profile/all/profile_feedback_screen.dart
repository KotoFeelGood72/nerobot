import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Divider.dart';
import 'package:nerobot/components/ui/Icons.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';

@RoutePage()
class ProfileFeedbackScreen extends StatefulWidget {
  const ProfileFeedbackScreen({super.key});

  @override
  State<ProfileFeedbackScreen> createState() => _ProfileFeedbackScreenState();
}

class _ProfileFeedbackScreenState extends State<ProfileFeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final List<File> _attachedFiles = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSendButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _feedbackController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _feedbackController.removeListener(_onTextChanged);
    _feedbackController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isSendButtonEnabled = _feedbackController.text.isNotEmpty;
    });
  }

  void _pickFile() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _attachedFiles.add(File(pickedFile.path));
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  Future<void> _sendFeedback() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || _feedbackController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пожалуйста, введите текст сообщения")),
      );
      return;
    }

    try {
      // Загружаем файлы и получаем ссылки
      List<String> fileUrls = [];
      for (var file in _attachedFiles) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('feedback_files')
            .child(
              '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}',
            );
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        fileUrls.add(url);
      }

      // Сохраняем отзыв в Firestore
      await FirebaseFirestore.instance.collection('feedbacks').add({
        'userId': userId,
        'text': _feedbackController.text,
        'attachments': fileUrls,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Обратная связь отправлена")),
      );

      _feedbackController.clear();
      setState(() {
        _attachedFiles.clear();
      });

      AutoRouter.of(context).replace(ProfileHelpRoute());
    } catch (e) {
      debugPrint("Ошибка: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ошибка при отправке обратной связи")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Обратная связь')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _feedbackController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      maxLength: 300,
                      decoration: const InputDecoration(
                        hintText:
                            "Опишите ваше обращение максимально подробно и понятно...",
                        hintStyle: TextStyle(color: AppColors.light),
                        border: InputBorder.none,
                        counterText: '',
                      ),
                    ),
                  ),
                  const Square(),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _attachedFiles.asMap().entries.map((entry) {
                          return Stack(
                            children: [
                              ClipOval(
                                child: Image.file(
                                  entry.value,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _removeFile(entry.key),
                                  child: const CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.red,
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickFile,
                        child: const IconWidget(
                          iconName: 'clip',
                          color: AppColors.violet,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Btn(
                          text: 'Отправить',
                          theme: 'violet',
                          onPressed:
                              _isSendButtonEnabled ? _sendFeedback : null,
                        ),
                      ),
                    ],
                  ),
                  const Square(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
