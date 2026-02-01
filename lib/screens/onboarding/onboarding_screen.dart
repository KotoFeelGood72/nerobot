import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';

@RoutePage()
class OnboardingScreen extends StatefulWidget {
  final String role; // 'customer' или 'worker'

  const OnboardingScreen({super.key, required this.role});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final List<OnboardingSlide> _slides;

  @override
  void initState() {
    super.initState();
    _initializeSlides();
  }

  void _initializeSlides() {
    if (widget.role == 'customer') {
      _slides = [
        OnboardingSlide(
          image: 'assets/images/slide-1.png',
          title: 'Проверенные специалисты',
          description:
              'Исполнители допускаются к работе после тестирования и проверки аккаунта',
        ),
        OnboardingSlide(
          image: 'assets/images/slide-2.png',
          title: 'Быстрый поиск исполнителей',
          description: 'За 2 минуты найдём исполнителя в вашем городе',
        ),
        OnboardingSlide(
          image: 'assets/images/slide-3.png',
          title: 'Поиск сотрудника',
          description:
              'Разместите вакансию на Разнорабочий.ру, и её увидят тысячи соискателей',
        ),
      ];
    } else {
      _slides = [
        OnboardingSlide(
          image: 'assets/images/slide-1.png',
          title: 'Найдите работу',
          description: 'Тысячи заказов ждут исполнителей в вашем городе',
        ),
        OnboardingSlide(
          image: 'assets/images/slide-2.png',
          title: 'Быстрый отклик',
          description: 'Откликайтесь на заказы и получайте работу за 2 минуты',
        ),
        OnboardingSlide(
          image: 'assets/images/slide-3.png',
          title: 'Зарабатывайте',
          description:
              'Выполняйте заказы и получайте оплату за качественную работу',
        ),
      ];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToAuth();
    }
  }

  void _navigateToAuth() {
    AutoRouter.of(context).replace(AuthRoute(role: widget.role));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Заголовок
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                  Expanded(
                    child: Text(
                      widget.role == 'customer'
                          ? 'Вы – заказчик'
                          : 'Вы – исполнитель',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Для баланса
                ],
              ),
            ),

            // Слайдер
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _buildSlide(_slides[index]);
                },
              ),
            ),

            // Индикаторы страниц
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentPage == index
                              ? AppColors.violet
                              : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),

            // Кнопки
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Btn(
                    text:
                        _currentPage == _slides.length - 1
                            ? 'Войти в аккаунт'
                            : 'Далее',
                    theme: 'violet',
                    onPressed: _nextPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(OnboardingSlide slide) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Изображение
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.yellow.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(slide.image, fit: BoxFit.cover),
            ),
          ),

          const SizedBox(height: 32),

          // Заголовок
          Text(
            slide.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Описание
          Text(
            slide.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingSlide {
  final String image;
  final String title;
  final String description;

  OnboardingSlide({
    required this.image,
    required this.title,
    required this.description,
  });
}








