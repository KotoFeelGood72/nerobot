import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:nerobot/components/bar/bottom_nav_bar.dart';
import 'package:nerobot/components/list/task_list.dart';
import 'package:nerobot/components/ui/pill_tabs.dart';
import 'package:nerobot/components/ui/task_filters.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/formatRuDate.dart';
import 'package:nerobot/utils/task_loader.dart';
import 'package:nerobot/utils/push_token_manager.dart';

@RoutePage()
class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  String? role;
  int tabIndex = 0;

  bool isLoading = true;
  Object? error;

  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> _recentTasks = [];

  bool _isLoadingRecent = false;

  final Map<String, String> _orderChats = {};
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roleSub;

  String searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic> _activeFilters = {};

  List<String> get _filters =>
      role == 'worker' ? ['tasks', 'open', 'history'] : ['tasks', 'history'];

  String get _currentFilter => _filters[tabIndex];

  List<Map<String, dynamic>> get _filteredTasks {
    if (searchQuery.isEmpty) return tasks;
    final q = searchQuery.toLowerCase();
    return tasks.where((t) {
      final title = (t['title'] ?? '').toString().toLowerCase();
      final desc = (t['description'] ?? '').toString().toLowerCase();
      return title.contains(q) || desc.contains(q);
    }).toList();
  }

  int get _activeFiltersCount {
    int c = 0;
    if (_activeFilters['minPrice'] != null) c++;
    if (_activeFilters['shiftType'] != null) c++;
    if (_activeFilters['sortBy'] != null) c++;
    final radius = _activeFilters['radiusKm'];
    // Дефолтный радиус в счётчик не включаем
    if (radius is num && radius.toDouble() != defaultSearchRadiusKm) c++;
    return c;
  }

  @override
  void initState() {
    super.initState();
    PushTokenManager.touchLastActive();
    _listenRole();
    _searchController.addListener(() {
      setState(() => searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _roleSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------- ROLE ----------------

  void _listenRole() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        role = 'worker';
        isLoading = false;
      });
      return;
    }

    _roleSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snap) async {
          if (!mounted) return;
          final rawRole = snap.data()?['type'] as String? ?? 'worker';
          final newRole = rawRole == 'customer' ? 'customer' : 'worker';
          final isFirstLoad = role == null;
          final roleChanged = newRole != role;
          if (isFirstLoad || roleChanged) {
            setState(() {
              role = newRole;
              tabIndex = 0;
              isLoading = true;
              if (roleChanged && !isFirstLoad) {
                searchQuery = '';
                _searchController.clear();
                _activeFilters = {};
              }
            });
            await _loadTasks();
            if (!mounted) return;
            if (role == 'worker') {
              await _loadRecentTasks();
            }
          }
        });
  }

  // ---------------- LOAD TASKS ----------------

  Future<void> _loadTasks() async {
    if (role == null) return;

    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final data = await loadTasks(
        role: role!,
        currentFilter: _currentFilter,
        minPrice: _activeFilters['minPrice'],
        radiusKm: _activeFilters['radiusKm'],
        userLocation: _activeFilters['userLocation'],
        paymentFor: _activeFilters['shiftType'],
        sortBy: _activeFilters['sortBy'],
      );

      debugPrint(
        '✅ loadTasks role=$role filter=$_currentFilter count=${data.length}',
      );

      if (!mounted) return;
      setState(() => tasks = data);

      if (role == 'worker' && tabIndex == 0) {
        _loadRecentTasks();
      }
    } catch (e, st) {
      debugPrint('❌ loadTasks error: $e\n$st');
      if (!mounted) return;
      setState(() {
        error = e;
        tasks = [];
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ---------------- RECENT TASKS (FIXED CITY FILTER) ----------------

  Future<void> _loadRecentTasks() async {
    if (_isLoadingRecent) return;

    setState(() => _isLoadingRecent = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final userSnap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final userData = userSnap.data();

      // Получаем координаты города пользователя
      LatLng? userCityCoords;
      if (userData != null) {
        final cityLat = userData['city_lat'];
        final cityLng = userData['city_lng'];

        if (cityLat != null && cityLng != null) {
          userCityCoords = LatLng(
            (cityLat is num)
                ? cityLat.toDouble()
                : double.tryParse(cityLat.toString()) ?? 0.0,
            (cityLng is num)
                ? cityLng.toDouble()
                : double.tryParse(cityLng.toString()) ?? 0.0,
          );
        }
      }

      // Простой запрос без composite-индекса
      final snap =
          await FirebaseFirestore.instance
              .collection('orders')
              .where('status', isEqualTo: 'open')
              .get();

      bool uidInList(dynamic list) {
        if (list is! List) return false;
        return list.any((e) => e?.toString() == uid);
      }

      var tasks = snap.docs
          .map((d) => {...d.data(), 'id': d.id})
          .where((task) {
            if (task['deleted'] == true) return false;
            if (task['active'] == false) return false;
            // Уже откликнулись — не показываем в «Последние»
            if (uidInList(task['responses']) || uidInList(task['workers'])) {
              return false;
            }
            return true;
          })
          .toList();

      // Фильтрация по координатам города
      if (userCityCoords != null) {
        final distance = Distance();
        const cityRadiusMeters = 50000.0;

        tasks = tasks.where((task) {
          final taskLat = task['lat'];
          final taskLng = task['lng'];
          if (taskLat == null || taskLng == null) return false;

          final taskCoords = LatLng(
            (taskLat is num)
                ? taskLat.toDouble()
                : double.tryParse(taskLat.toString()) ?? 0.0,
            (taskLng is num)
                ? taskLng.toDouble()
                : double.tryParse(taskLng.toString()) ?? 0.0,
          );

          final distanceMeters = distance.as(
            LengthUnit.Meter,
            userCityCoords!,
            taskCoords,
          );
          return distanceMeters <= cityRadiusMeters;
        }).toList();
      }

      tasks.sort((a, b) {
        final ad = (a['created_date'] is num)
            ? (a['created_date'] as num).toInt()
            : 0;
        final bd = (b['created_date'] is num)
            ? (b['created_date'] as num).toInt()
            : 0;
        return bd.compareTo(ad);
      });

      setState(() {
        _recentTasks = tasks.take(5).toList();
      });
    } catch (e) {
      debugPrint('Recent tasks error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRecent = false);
    }
  }

  // ---------------- UI ----------------

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
        toolbarHeight: 44,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Поиск',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                )
                : const Text('Задания'),
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                searchQuery = '';
                _searchController.clear();
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: PillTabs(
              titles: titles,
              selectedIndex: tabIndex,
              onChanged: (i) {
                setState(() => tabIndex = i);
                _loadTasks();
              },
            ),
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          clipBehavior: Clip.none,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (role == 'worker' && tabIndex == 0) _buildRecentTasks(),
                    if (role == 'worker') ...[
                      TaskFilters(
                        activeFiltersCount: _activeFiltersCount,
                        initialRadiusKm:
                            (_activeFilters['radiusKm'] as num?)?.toDouble() ??
                            defaultSearchRadiusKm,
                        onApply: (params) async {
                          setState(() => _activeFilters = params);
                          await _loadTasks();
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
            TaskList(
              tasks: _filteredTasks,
              isLoading: isLoading,
              error: error,
              onTaskTap: _onTaskTap,
              asSliver: true,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(showCreateButton: role != 'worker'),
    );
  }

  Widget _buildRecentTasks() {
    if (_recentTasks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Последние задания',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            itemCount: _recentTasks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final task = _recentTasks[i];
              final createdMs = task['created_date'];
              final created = createdMs is int
                  ? DateTime.fromMillisecondsSinceEpoch(createdMs).toLocal()
                  : null;
              final price = task['price'];

              return GestureDetector(
                onTap: () => _onTaskTap(task),
                child: Container(
                  width: 168,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        task['title']?.toString() ?? 'Без названия',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              created != null ? formatRuDate(created) : '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            price != null ? '$price ₽' : '—',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.violet,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ---------------- CHAT ----------------

  Future<String> _getOrCreateChat(String orderId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final q =
        await FirebaseFirestore.instance
            .collection('chats')
            .where('order_id', isEqualTo: orderId)
            .where('participants', arrayContains: uid)
            .limit(1)
            .get();

    if (q.docs.isNotEmpty) return q.docs.first.id;

    final doc = await FirebaseFirestore.instance.collection('chats').add({
      'order_id': orderId,
      'participants': [uid],
      'created_date': DateTime.now().millisecondsSinceEpoch,
    });

    return doc.id;
  }

  void _onTaskTap(Map<String, dynamic> task) async {
    final orderId = task['id'];
    if (role == 'worker') {
      AutoRouter.of(context).push(TaskDetailRoute(taskId: orderId));
    } else {
      AutoRouter.of(context).push(TaskResponseRoute(taskId: orderId));
    }
  }
}
