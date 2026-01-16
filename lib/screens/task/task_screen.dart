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
  String? role;
  int tabIndex = 0;

  bool isLoading = true;
  Object? error;

  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> _recentTasks = [];

  bool _isLoadingRecent = false;
  bool _hasActiveSubscription = false;
  bool _isLoadingSubscription = true;

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
    if (_activeFilters['radiusKm'] != null) c++;
    return c;
  }

  @override
  void initState() {
    super.initState();
    _listenRole();
    _searchController.addListener(() {
      setState(() => searchQuery = _searchController.text.trim());
    });
    _checkSubscription();
  }

  @override
  void dispose() {
    _roleSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------- SUBSCRIPTION ----------------

  Future<void> _checkSubscription() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final active = await SubscriptionUtils.getActiveSubscription(uid);
    if (!mounted) return;

    setState(() {
      _hasActiveSubscription = active != null;
      _isLoadingSubscription = false;
    });
  }

  // ---------------- ROLE ----------------

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
        setState(() {
          role = newRole;
          tabIndex = 0;
          isLoading = true;
          searchQuery = '';
          _searchController.clear();
        });
        await _loadTasks();
        if (role == 'worker') {
          await _loadRecentTasks();
        }
      }
    });
  }

  // ---------------- LOAD TASKS ----------------

  Future<void> _loadTasks() async {
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
      );

      setState(() => tasks = data);

      if (role == 'worker' && tabIndex == 0) {
        _loadRecentTasks();
      }
    } catch (e) {
      setState(() => error = e);
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

      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final city = userSnap.data()?['city'];

      Query query = FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'open')
          .where('active', isEqualTo: true)
          .where('deleted', isEqualTo: false);

      if (city != null && city.toString().isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      final snap = await query
          .orderBy('created_date', descending: true)
          .limit(5)
          .get();

      setState(() {
        _recentTasks =
            snap.docs.map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id}).toList();
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
        role == 'worker' ? ['Новые', 'Открытые', 'История'] : ['Открытые', 'История'];

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Поиск'),
              )
            : const Text('Задания'),
        actions: [
          IconButton(
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
          preferredSize: const Size.fromHeight(48),
          child: _buildTabs(titles),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (role == 'worker' &&
                  !_isLoadingSubscription &&
                  !_hasActiveSubscription)
                const Expanded(child: TaskEmpty())
              else ...[
                if (role == 'worker' && tabIndex == 0) _buildRecentTasks(),
                TaskFilters(
                  activeFiltersCount: _activeFiltersCount,
                  onApply: (params) async {
                    setState(() => _activeFilters = params);
                    await _loadTasks();
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

  Widget _buildTabs(List<String> titles) => Row(
        children: List.generate(titles.length, (i) {
          final active = tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => tabIndex = i);
                _loadTasks();
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                color: active ? Colors.white : Colors.grey[200],
                child: Center(child: Text(titles[i])),
              ),
            ),
          );
        }),
      );

  Widget _buildRecentTasks() {
    if (_recentTasks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Последние задания',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recentTasks.length,
            itemBuilder: (_, i) =>
                GestureDetector(
                  onTap: () => _onTaskTap(_recentTasks[i]),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_recentTasks[i]['title'] ?? ''),
                    ),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  // ---------------- CHAT ----------------

  Future<String> _getOrCreateChat(String orderId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final q = await FirebaseFirestore.instance
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
