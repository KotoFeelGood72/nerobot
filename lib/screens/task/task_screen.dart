import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/bar/bottom_nav_bar.dart';
import 'package:nerobot/components/list/task_list.dart';
import 'package:nerobot/components/ui/task_filters.dart';
import 'package:nerobot/components/placeholder/task_empty.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/task_loader.dart';
import 'package:nerobot/utils/subscription_utils.dart';

@RoutePage()
class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  // ---------------- state ----------------
  String? role; // worker | customer
  int tabIndex = 0; // активная вкладка
  bool isLoading = true;
  Object? error;
  List<Map<String, dynamic>> tasks = [];
  final Map<String, String> _orderChats = {}; // order_id -> chat_id
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roleSub;

  // Для поиска:
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Новый флаг: показывать ли поле поиска в AppBar
  bool _isSearching = false;

  // Для фильтров:
  Map<String, dynamic> _activeFilters = {};

  // Для последних заданий:
  List<Map<String, dynamic>> _recentTasks = [];
  bool _isLoadingRecent = false;

  // Для проверки подписки:
  bool _hasActiveSubscription = false;
  bool _isLoadingSubscription = true;

  // ---------- utils ----------
  List<String> get _filters =>
      role == 'worker' ? ['tasks', 'open', 'history'] : ['tasks', 'history'];

  String get _currentFilter => _filters[tabIndex];

  List<Map<String, dynamic>> get _filteredTasks {
    if (searchQuery.isEmpty) return tasks;
    final lower = searchQuery.toLowerCase();
    return tasks.where((t) {
      // смотрим поле "title" из документа заказа
      final title = (t['title'] ?? '').toString().toLowerCase();
      final description = (t['description'] ?? '').toString().toLowerCase();
      return title.contains(lower) || description.contains(lower);
    }).toList();
  }

  /// Подсчитывает количество активных фильтров
  int get _activeFiltersCount {
    int count = 0;
    if (_activeFilters['minPrice'] != null) count++;
    if (_activeFilters['shiftType'] != null) count++;
    if (_activeFilters['sortBy'] != null) count++;
    if (_activeFilters['radiusKm'] != null && _activeFilters['radiusKm'] != 5.0)
      count++;
    return count;
  }

  /// Проверяет, есть ли активные фильтры
  bool get _hasActiveFilters => _activeFiltersCount > 0;

  /// Проверяет активную подписку пользователя
  Future<void> _checkSubscription() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final hasSubscription = await SubscriptionUtils.hasActiveSubscription(
        uid,
      );
      if (mounted) {
        setState(() {
          _hasActiveSubscription = hasSubscription;
          _isLoadingSubscription = false;
        });
      }
    } catch (e) {
      print('Ошибка при проверке подписки: $e');
      if (mounted) {
        setState(() {
          _isLoadingSubscription = false;
        });
      }
    }
  }

  /// Загружает последние созданные задания
  Future<void> _loadRecentTasks() async {
    if (_isLoadingRecent) return;

    setState(() {
      _isLoadingRecent = true;
    });

    try {
      final query = FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'open')
          .where('active', isEqualTo: true)
          .where('deleted', isEqualTo: false)
          .orderBy('created_date', descending: true)
          .limit(5);

      final snapshot = await query.get();
      final recentTasks =
          snapshot.docs.map((doc) {
            return {...doc.data(), 'id': doc.id};
          }).toList();

      setState(() {
        _recentTasks = recentTasks;
      });
    } catch (e) {
      print('Ошибка при загрузке последних заданий: $e');
    } finally {
      setState(() {
        _isLoadingRecent = false;
      });
    }
  }

  // ---------------------------

  @override
  void initState() {
    super.initState();
    _listenRole(); // ← сразу ставим слушателя
    // слушаем изменение текста поиска, чтобы обновлять отображение в реальном времени
    // слушаем изменение текста поиска, чтобы фильтрация работала в реальном времени
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.trim();
      });
    });

    // Проверяем подписку и загружаем последние задания
    _checkSubscription();
    _loadRecentTasks();
  }

  @override
  void dispose() {
    _roleSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<String> _getOrCreateChat(String orderId) async {
    // 1. кеш
    if (_orderChats.containsKey(orderId)) return _orderChats[orderId]!;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final chatsColl = FirebaseFirestore.instance.collection('chats');

    // 2. ищем готовый чат
    final qSnap =
        await chatsColl
            .where('order_id', isEqualTo: orderId)
            .where('participants', arrayContains: uid)
            .limit(1)
            .get();

    if (qSnap.docs.isNotEmpty) {
      final chatId = qSnap.docs.first.id;
      _orderChats[orderId] = chatId;
      return chatId;
    }

    // 3. чата нет → создаём
    final now = DateTime.now().millisecondsSinceEpoch;
    final newDoc = await chatsColl.add({
      'order_id': orderId,
      'created_date': now,
      'participants': [uid], // автор отклика; второй участник добавится позже
      'messages': [],
    });

    _orderChats[orderId] = newDoc.id;
    return newDoc.id;
  }

  // ================= ROLE LISTENER =================
  void _listenRole() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _roleSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snap) async {
          final newRole = snap.data()?['type'] ?? 'worker';
          if (newRole != role) {
            // роль поменялась → обновляем стейт и заново грузим список
            setState(() {
              role = newRole;
              tabIndex = 0; // всегда начинаем с первой вкладки
              isLoading = true;
              searchQuery = '';
              _searchController.clear();
            });
            await _loadTasks(); // подтягиваем задачи под новую роль
            _checkSubscription(); // проверяем подписку для новой роли
          }
        });
  }
  // =================================================

  Future<void> _loadTasks({
    DateTime? startDate,
    DateTime? endDate,
    double? minPrice,
    double? maxPrice,
    double? radiusKm,
    GeoPoint? userLocation,
  }) async {
    print('=== ВЫЗОВ _loadTasks ===');
    print('minPrice: $minPrice');
    print('maxPrice: $maxPrice');
    print('radiusKm: $radiusKm');
    print('userLocation: $userLocation');
    if (userLocation != null) {
      print(
        'Координаты в _loadTasks: ${userLocation.latitude}, ${userLocation.longitude}',
      );
    }

    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Если параметры не переданы, используем сохраненные фильтры
      final effectiveMinPrice = minPrice ?? _activeFilters['minPrice'];
      final effectiveRadiusKm = radiusKm ?? _activeFilters['radiusKm'];
      final effectiveUserLocation =
          userLocation ?? _activeFilters['userLocation'];

      final data = await loadTasks(
        role: role!,
        currentFilter: _currentFilter,
        startDate: startDate,
        endDate: endDate,
        minPrice: effectiveMinPrice,
        maxPrice: maxPrice,
        radiusKm: effectiveRadiusKm,
        userLocation: effectiveUserLocation,
      );

      print('Получено задач: ${data.length}');
      setState(() => tasks = data);

      // Обновляем последние задания если мы на вкладке "Новые"
      if (role == 'worker' && tabIndex == 0) {
        _loadRecentTasks();
      }
    } catch (e) {
      print('Ошибка в _loadTasks: $e');
      setState(() => error = e);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final titles =
        role == 'worker'
            ? ['Новые', 'Открытые', 'История']
            : ['Открытые', 'История'];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        // Если в режиме поиска, показываем TextField вместо заголовка
        title:
            _isSearching
                ? SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Поиск...',
                      filled: true,
                      fillColor: AppColors.ulight,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        searchQuery = val.trim();
                      });
                    },
                  ),
                )
                : Text(
                  'Задания',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        centerTitle: true,
        actions: [
          // Если не в режиме поиска, показываем иконку поиска
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                  // Очистим предыдущий ввод
                  searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
          // Если в режиме поиска, показываем иконку закрытия
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
          // Существующая кнопка "добавить" для customer
          if (!_isSearching && role != 'worker')
            IconButton(
              icon: const Icon(Icons.add, color: Colors.black),
              onPressed:
                  () => AutoRouter.of(context).push(NewTaskCreateRoute()),
            ),
        ],
        // Если не в режиме поиска, отображаем табы; иначе прячем таббар
        bottom:
            !_isSearching
                ? PreferredSize(
                  preferredSize: const Size.fromHeight(50),
                  child: _buildTabs(titles),
                )
                : null,
      ),

      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Показываем заглушку для исполнителей без подписки
              if (role == 'worker' &&
                  !_isLoadingSubscription &&
                  !_hasActiveSubscription)
                Expanded(child: TaskEmpty())
              else ...[
                // Показываем последние задания только на вкладке "Новые" для исполнителей
                if (role == 'worker' && tabIndex == 0) _buildRecentTasks(),

                TaskFilters(
                  activeFiltersCount: _activeFiltersCount,
                  onApply: (params) async {
                    print('=== ПОЛУЧЕНЫ ПАРАМЕТРЫ ФИЛЬТРОВ ===');
                    print('Все параметры: $params');
                    print('minPrice: ${params['minPrice']}');
                    print('radiusKm: ${params['radiusKm']}');
                    print('userLocation: ${params['userLocation']}');

                    // Сохраняем активные фильтры
                    setState(() {
                      _activeFilters = Map.from(params);
                    });

                    GeoPoint? geoPoint;
                    if (params['userLocation'] != null) {
                      geoPoint = GeoPoint(
                        params['userLocation'].latitude,
                        params['userLocation'].longitude,
                      );
                      print(
                        'Создан GeoPoint: ${geoPoint.latitude}, ${geoPoint.longitude}',
                      );
                    } else {
                      print('⚠️ userLocation равен null, GeoPoint не создан');
                    }

                    await _loadTasks(
                      minPrice: params['minPrice'],
                      radiusKm: params['radiusKm'],
                      userLocation: geoPoint,
                    );
                  },
                ),

                Expanded(
                  child: TaskList(
                    tasks: _filteredTasks,
                    isLoading: isLoading,
                    error: error,
                    onTaskTap: _onTaskTap,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),

      bottomNavigationBar: const BottomNavBar(),
    );
  }

  Widget _buildTabs(List<String> titles) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.ulight,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: List.generate(titles.length, (i) {
          final active = tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  tabIndex = i;
                  searchQuery = '';
                  _searchController.clear();
                });
                _loadTasks();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    titles[i],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: active ? AppColors.violet : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    ),
  );

  /// Виджет для отображения последних заданий
  Widget _buildRecentTasks() {
    if (_isLoadingRecent) {
      return Container(
        height: 120,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_recentTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Последние задания',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recentTasks.length,
            itemBuilder: (context, index) {
              final task = _recentTasks[index];
              return _buildRecentTaskCard(task);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Виджет карточки последнего задания
  Widget _buildRecentTaskCard(Map<String, dynamic> task) {
    final title = task['title'] ?? 'Без названия';
    final price = task['price'] ?? 0;
    final address = task['address'] ?? 'Адрес не указан';
    final createdDate = task['created_date'] as int?;

    String timeAgo = 'Недавно';
    if (createdDate != null) {
      final now = DateTime.now();
      final created = DateTime.fromMillisecondsSinceEpoch(createdDate);
      final difference = now.difference(created);

      if (difference.inMinutes < 60) {
        timeAgo = '${difference.inMinutes} мин назад';
      } else if (difference.inHours < 24) {
        timeAgo = '${difference.inHours} ч назад';
      } else {
        timeAgo = '${difference.inDays} дн назад';
      }
    }

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _onTaskTap(task),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$price ₽',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.violet,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTaskTap(Map<String, dynamic> task) async {
    final orderId = task['id'].toString();

    if (role == 'worker' && _currentFilter == 'open' ||
        _currentFilter == 'history') {
      final chatId = await _getOrCreateChat(orderId);
      if (!mounted) return;
      AutoRouter.of(context).push(ChatsRoute(chatsId: chatId, taskId: orderId));
      return;
    }

    if (role == 'worker') {
      AutoRouter.of(context).push(TaskDetailRoute(taskId: orderId));
      return;
    }

    // ------- ДОБАВЛЕНО: customer → если есть исполнители, открыть экран исполнителей --------
    final List workers = (task['workers'] ?? []) as List;
    if (role == 'customer' && workers.isNotEmpty) {
      AutoRouter.of(context).replace(TaskExecutorsRoute(taskId: orderId));
      return;
    }

    // ------- иначе: открываем экран откликов --------
    AutoRouter.of(context).replace(TaskResponseRoute(taskId: orderId));
  }
}
