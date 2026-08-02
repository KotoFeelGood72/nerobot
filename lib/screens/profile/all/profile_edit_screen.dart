import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Inputs.dart';
import 'package:nerobot/components/ui/app_form_field.dart';
import 'package:nerobot/components/ui/user_avatar.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/clean_phone.dart';
import 'package:nerobot/utils/city_coordinates.dart';

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
  String selectedCity = 'Москва'; // По умолчанию Москва
  bool isLoading = true; // первичная загрузка
  bool _inProcess = false; // лоадер на любые операции

  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  // Список городов для выбора
  final List<String> cities = [
    'Москва',
    'Санкт-Петербург',
    'Новосибирск',
    'Екатеринбург',
    'Казань',
    'Нижний Новгород',
    'Челябинск',
    'Самара',
    'Уфа',
    'Ростов-на-Дону',
    'Краснодар',
    'Пермь',
    'Воронеж',
    'Волгоград',
    'Красноярск',
    'Саратов',
    'Тюмень',
    'Тольятти',
    'Ижевск',
    'Барнаул',
    'Ульяновск',
    'Иркутск',
    'Хабаровск',
    'Ярославль',
    'Владивосток',
    'Махачкала',
    'Томск',
    'Оренбург',
    'Кемерово',
    'Новокузнецк',
    'Рязань',
    'Астрахань',
    'Набережные Челны',
    'Пенза',
    'Липецк',
    'Киров',
    'Чебоксары',
    'Тула',
    'Калининград',
    'Курск',
    'Улан-Удэ',
    'Ставрополь',
    'Сочи',
    'Иваново',
    'Брянск',
    'Белгород',
    'Архангельск',
    'Владимир',
    'Севастополь',
    'Чита',
    'Грозный',
    'Калининград',
    'Смоленск',
    'Вологда',
    'Курган',
    'Орёл',
    'Череповец',
    'Владикавказ',
    'Мурманск',
    'Сургут',
    'Волжский',
    'Саранск',
    'Стерлитамак',
    'Грозный',
    'Якутск',
    'Кострома',
    'Петрозаводск',
    'Нижневартовск',
    'Йошкар-Ола',
    'Новороссийск',
    'Сыктывкар',
    'Нижнекамск',
    'Шахты',
    'Дзержинск',
    'Орск',
    'Энгельс',
    'Бийск',
    'Прокопьевск',
    'Рыбинск',
    'Балаково',
    'Ухта',
    'Королёв',
    'Сызрань',
    'Мытищи',
    'Люберцы',
    'Волгодонск',
    'Новочеркасск',
    'Абакан',
    'Находка',
    'Уссурийск',
    'Березники',
    'Салават',
    'Электросталь',
    'Миасс',
    'Первоуральск',
    'Рубцовск',
    'Альметьевск',
    'Ковров',
    'Коломна',
    'Майкоп',
    'Пятигорск',
    'Одинцово',
    'Копейск',
    'Хасавюрт',
    'Новомосковск',
    'Кисловодск',
    'Серпухов',
    'Первоуральск',
    'Нефтеюганск',
    'Новошахтинск',
    'Щёлково',
    'Дербент',
    'Орехово-Зуево',
    'Нефтекамск',
    'Черкесск',
    'Батайск',
    'Раменское',
    'Домодедово',
    'Сергиев Посад',
    'Армавир',
    'Ухта',
    'Ленинск-Кузнецкий',
    'Междуреченск',
    'Киселёвск',
    'Анжеро-Судженск',
    'Юрга',
    'Белово',
    'Прокопьевск',
    'Осинники',
    'Мыски',
    'Мариинск',
    'Таштагол',
    'Топки',
    'Полысаево',
    'Гурьевск',
    'Салаир',
    'Тайга',
    'Берёзовский',
    'Калтан',
    'Кемерово',
    'Новокузнецк',
    'Прокопьевск',
    'Ленинск-Кузнецкий',
    'Киселёвск',
    'Междуреченск',
    'Юрга',
    'Белово',
    'Анжеро-Судженск',
    'Осинники',
    'Мыски',
    'Мариинск',
    'Таштагол',
    'Топки',
    'Полысаево',
    'Гурьевск',
    'Салаир',
    'Тайга',
    'Берёзовский',
    'Калтан',
  ];

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
        selectedCity = data['city'] ?? 'Москва';
        photoUrl = data['image_url'];
        isLoading = false;
      });
    }
  }

  Future<void> _updateUserProfile() async {
    setState(() => _inProcess = true);

    try {
      final cleanedPhone = CleanPhone.cleanPhoneNumber(phoneController.text);
      
      // Получаем координаты города
      final cityCoords = CityCoordinates.getCityCoordinates(selectedCity);
      
      final updateData = <String, dynamic>{
        'firstName': firstNameController.text,
        'lastName': lastNameController.text,
        'phone': cleanedPhone,
        'city': selectedCity,
        'about': aboutMySelfController.text,
        'image_url': photoUrl ?? '',
      };
      
      // Добавляем координаты города, если они найдены
      if (cityCoords != null) {
        updateData['city_lat'] = cityCoords.latitude;
        updateData['city_lng'] = cityCoords.longitude;
      }

      await FirebaseFirestore.instance.collection('users').doc(userId).update(updateData);

      if (mounted) AutoRouter.of(context).replaceAll([TaskRoute()]);
    } finally {
      if (mounted) setState(() => _inProcess = false);
    }
  }

  Future<void> _deletePhoto() async {
    final uid = userId;
    final previousUrl = photoUrl;
    setState(() => photoUrl = null);

    if (uid == null) return;
    try {
      await FirebaseStorage.instance.ref('user_photos/$uid.jpg').delete();
    } on FirebaseException catch (e) {
      // Уже нет файла — не ошибка для UI
      if (e.code != 'object-not-found') {
        debugPrint('delete photo: ${e.code} ${e.message}');
      }
    } catch (e) {
      debugPrint('delete photo: $e');
    }
    debugPrint('photo cleared (was: $previousUrl)');
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (image == null || userId == null) return;

    setState(() => _inProcess = true);

    try {
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Пустой файл изображения');
      }

      final contentType = image.mimeType?.startsWith('image/') == true
          ? image.mimeType!
          : 'image/jpeg';

      final ref = FirebaseStorage.instance.ref('user_photos/${userId!}.jpg');
      await ref.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
      final downloadUrl = await ref.getDownloadURL();
      if (mounted) setState(() => photoUrl = downloadUrl);
    } on FirebaseException catch (e) {
      debugPrint('❌ upload photo: ${e.code} ${e.message}');
      if (!mounted) return;
      final message = switch (e.code) {
        'unauthorized' || 'permission-denied' =>
          'Нет доступа к Storage. Проверьте правила Firebase Storage.',
        'object-not-found' =>
          'Firebase Storage не настроен. Откройте консоль Firebase → Storage → Get Started.',
        _ => 'Не удалось загрузить фото: ${e.message ?? e.code}',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      debugPrint('❌ upload photo: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось загрузить фото: $e')),
      );
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: ListView(
                children: [
                SizedBox(
                  width: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      UserAvatar(imageUrl: photoUrl, radius: 50),
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
                _buildCityDropdown(),
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
                  theme: 'primary',
                ),
              ],
            ),
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

  Widget _buildCityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'Город',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        AppDropdown<String>(
          value: selectedCity,
          iconColor: AppColors.black,
          items: cities
              .map(
                (city) => DropdownMenuItem<String>(
                  value: city,
                  child: Text(city),
                ),
              )
              .toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() => selectedCity = newValue);
            }
          },
        ),
      ],
    );
  }
}
