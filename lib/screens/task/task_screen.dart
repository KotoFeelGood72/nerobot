import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/bar/bottom_nav_bar.dart';
import 'package:nerobot/components/list/task_list.dart';
import 'package:nerobot/components/ui/task_filters.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/task_loader.dart';

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
          final newRole = snap.data()?['type'] ?? 'customer';
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
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final data = await loadTasks(
        role: role!,
        currentFilter: _currentFilter,
        startDate: startDate,
        endDate: endDate,
        minPrice: minPrice,
        maxPrice: maxPrice,
        radiusKm: radiusKm,
        userLocation: userLocation,
      );

      setState(() => tasks = data);
    } catch (e) {
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
              TaskFilters(
                onApply: (params) async {
                  print('Получены параметры фильтров: $params');
                  await _loadTasks(
                    minPrice: params['minPrice'],
                    radiusKm: params['radiusKm'],
                    userLocation:
                        params['userLocation'] != null
                            ? GeoPoint(
                              params['userLocation'].latitude,
                              params['userLocation'].longitude,
                            )
                            : null,
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

    // ------- ДОБАВЛЕНО: customer → если есть исполнители, открыть чат --------
    final List workers = (task['workers'] ?? []) as List;
    if (role == 'customer' && workers.isNotEmpty) {
      final chatId = await _getOrCreateChat(orderId);
      if (!mounted) return;
      AutoRouter.of(context).push(ChatsRoute(chatsId: chatId, taskId: orderId));
      return;
    }

    // ------- иначе: открываем экран откликов --------
    AutoRouter.of(context).push(TaskResponseRoute(taskId: orderId));
  }
}
