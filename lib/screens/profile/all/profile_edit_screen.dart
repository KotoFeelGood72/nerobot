import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Inputs.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/clean_phone.dart';

@RoutePage()
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  /* ------------------------------------------------------------ */
  /*  CONTROLLERS / STATE                                         */
  /* ------------------------------------------------------------ */
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final MaskedTextController phoneController = MaskedTextController(
    mask: '+7 (000) 000-00-00',
  );
  final TextEditingController aboutMySelfController = TextEditingController();

  String? photoUrl;
  bool isLoading = true; // первичная загрузка
  bool _inProcess = false; // лоадер на любые операции

  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  /* ------------------------------------------------------------ */
  /*  INIT                                                        */
  /* ------------------------------------------------------------ */
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /* ------------------------------------------------------------ */
  /*  DATA IO                                                     */
  /* ------------------------------------------------------------ */
  Future<void> _loadUserProfile() async {
    if (userId == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final data = doc.data();

    if (data != null && mounted) {
      setState(() {
        firstNameController.text = data['firstName'] ?? '';
        lastNameController.text = data['lastName'] ?? '';
        phoneController.text = data['phone'] ?? '';
        aboutMySelfController.text = data['about'] ?? '';
        photoUrl = data['image_url'];
        isLoading = false;
      });
    }
  }

  Future<void> _updateUserProfile() async {
    setState(() => _inProcess = true);

    try {
      final cleanedPhone = CleanPhone.cleanPhoneNumber(phoneController.text);

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'firstName': firstNameController.text,
        'lastName': lastNameController.text,
        'phone': cleanedPhone,
        'about': aboutMySelfController.text,
        'image_url': photoUrl ?? '',
      });

      if (mounted) AutoRouter.of(context).replaceAll([TaskRoute()]);
    } finally {
      if (mounted) setState(() => _inProcess = false);
    }
  }

  Future<void> _deletePhoto() async {
    setState(() => photoUrl = null);
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null || userId == null) return;

    setState(() => _inProcess = true);

    try {
      final ref = FirebaseStorage.instance.ref('user_photos/$userId.jpg');
      await ref.putFile(File(image.path));
      final downloadUrl = await ref.getDownloadURL();
      if (mounted) setState(() => photoUrl = downloadUrl);
    } finally {
      if (mounted) setState(() => _inProcess = false);
    }
  }

  /* ------------------------------------------------------------ */
  /*  UI                                                          */
  /* ------------------------------------------------------------ */
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Редактирование')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                SizedBox(
                  width: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _getImageProvider(photoUrl),
                      ),
                      Positioned(
                        top: 0,
                        right: 120,
                        child: GestureDetector(
                          onTap: _deletePhoto,
                          child: const CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 120,
                        child: GestureDetector(
                          onTap: _pickAndUploadPhoto,
                          child: const CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.edit,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Inputs(
                  controller: firstNameController,
                  backgroundColor: AppColors.ulight,
                  textColor: Colors.black,
                  label: 'Имя',
                  required: true,
                ),
                const SizedBox(height: 16),
                Inputs(
                  controller: lastNameController,
                  backgroundColor: AppColors.ulight,
                  textColor: Colors.black,
                  label: 'Фамилия',
                  required: true,
                ),
                const SizedBox(height: 16),
                Inputs(
                  controller: phoneController,
                  backgroundColor: AppColors.ulight,
                  textColor: Colors.black,
                  label: 'Телефон',
                  fieldType: 'phone',
                ),
                const SizedBox(height: 16),
                Inputs(
                  controller: aboutMySelfController,
                  backgroundColor: AppColors.ulight,
                  textColor: Colors.black,
                  label: 'О себе',
                  isMultiline: true,
                ),
                const SizedBox(height: 40),
                Btn(
                  text: 'Подтвердить',
                  onPressed: _updateUserProfile,
                  theme: 'violet',
                ),
              ],
            ),
          ),

          // --- глобальный оверлей-лоадер ---
          if (_inProcess)
            AbsorbPointer(
              absorbing: true,
              child: Container(
                color: Colors.black26,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  ImageProvider _getImageProvider(String? imageUrl) {
    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        Uri.tryParse(imageUrl)?.hasAbsolutePath == true) {
      return NetworkImage(imageUrl);
    }
    return const AssetImage('assets/images/splash.png');
  }
}
