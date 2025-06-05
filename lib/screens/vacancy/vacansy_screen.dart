import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/constants/app_colors.dart';

@RoutePage()
class VacansyScreen extends StatefulWidget {
  const VacansyScreen({super.key});

  @override
  State<VacansyScreen> createState() => _VacansyScreenState();
}

class _VacansyScreenState extends State<VacansyScreen> {
  String activeFilter =
      'all'; // можно сделать фильтрацию по "remote", "office", "parttime" и т.д.
  bool isLoading = true;
  Object? error;
  List<Map<String, dynamic>> vacancies = [];

  @override
  void initState() {
    super.initState();
    _loadVacancies();
  }

  Future<void> _loadVacancies() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final q = FirebaseFirestore.instance.collection('vacancies');

      final snap = await q.get();
      final data =
          snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      setState(() => vacancies = data);
    } catch (e) {
      setState(() => error = e);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вакансии'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadVacancies,
        child: Column(
          children: [
            _buildFilterBar(),
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (error != null)
              Expanded(child: Center(child: Text('Ошибка: $error')))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: vacancies.length,
                  itemBuilder: (context, index) {
                    final v = vacancies[index];
                    return ListTile(
                      title: Text(v['title'] ?? 'Без названия'),
                      subtitle: Text(v['description'] ?? ''),
                      onTap: () {
                        // по клику можешь перейти на экран деталей
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = ['all', 'remote', 'office'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children:
            filters.map((f) {
              final selected = f == activeFilter;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => activeFilter = f);
                    _loadVacancies(); // фильтрацию реализуешь по желанию
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.violet : AppColors.ulight,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        f == 'all' ? 'Все' : f,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
