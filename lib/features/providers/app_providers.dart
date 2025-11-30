import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../health_records/health_entry.dart';
import '../../db/health_database.dart';

class AuthService {
  static final Map<String, String> _users = {};

  static Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return _users[email] == password;
  }

  static Future<bool> register(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (_users.containsKey(email)) return false;
    _users[email] = password;
    return true;
  }

  static Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}

final healthEntryProvider =
    StateNotifierProvider<HealthEntryNotifier, List<HealthEntry>>(
  (ref) => HealthEntryNotifier(),
);

class HealthEntryNotifier extends StateNotifier<List<HealthEntry>> {
  HealthEntryNotifier() : super([]) {
    _loadAll();
  }

  Future<void> _loadAll() async {
    final entries = await HealthDatabase.instance.readAll();
    state = entries;
  }

  Future<void> create(HealthEntry entry) async {
    final newEntry = await HealthDatabase.instance.create(entry);
    state = [...state, newEntry];
  }

  Future<void> update(HealthEntry entry) async {
    await HealthDatabase.instance.update(entry);
    state = [
      for (final e in state)
        if (e.id == entry.id) entry else e,
    ];
  }

  Future<void> delete(int id) async {
    await HealthDatabase.instance.delete(id);
    state = state.where((e) => e.id != id).toList();
  }

  Future<void> refresh() async {
    final entries = await HealthDatabase.instance.readAll();
    state = entries;
  }
}