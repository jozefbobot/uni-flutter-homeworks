import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TodoPriority { low, normal, high }

/// Nemenný model úlohy. Zmeny vykonáva iba TodoProvider.
class MyTodo {
  const MyTodo({
    required this.id,
    required this.name,
    required this.priority,
    this.completed = false,
  });

  final int id;
  final String name;
  final TodoPriority priority;
  final bool completed;

  MyTodo copyWith({bool? completed}) => MyTodo(
    id: id,
    name: name,
    priority: priority,
    completed: completed ?? this.completed,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'priority': priority.name,
    'completed': completed,
  };

  factory MyTodo.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final priorityName = json['priority'];
    final completed = json['completed'];

    if (id is! int ||
        name is! String ||
        name.trim().isEmpty ||
        priorityName is! String ||
        completed is! bool) {
      throw const FormatException('Invalid saved task.');
    }

    return MyTodo(
      id: id,
      name: name,
      priority: TodoPriority.values.firstWhere(
        (priority) => priority.name == priorityName,
        orElse: () => throw const FormatException('Invalid saved priority.'),
      ),
      completed: completed,
    );
  }
}

/// Centrálne uchováva úlohy, zvolenú prioritu a logiku lokálneho ukladania.
class TodoProvider extends ChangeNotifier {
  TodoProvider({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const storageKey = 'homework_07_todos';

  final SharedPreferencesAsync _preferences;
  final List<MyTodo> _todos = [];
  TodoPriority _priority = TodoPriority.normal;
  bool _isLoading = true;
  bool _loadInProgress = false;
  bool _hasLoadError = false;
  bool _disposed = false;
  int _pendingWrites = 0;
  int _lastId = 0;
  String? _errorMessage;
  Future<void> _writeQueue = Future<void>.value();

  List<MyTodo> get todos => List.unmodifiable(_todos);
  TodoPriority get priority => _priority;
  bool get isLoading => _isLoading;
  bool get hasLoadError => _hasLoadError;
  bool get isSaving => _pendingWrites > 0;
  String? get errorMessage => _errorMessage;

  bool get _canEdit => !_isLoading && !_hasLoadError;

  Future<void> loadTodos() async {
    if (_loadInProgress || isSaving) return;

    _loadInProgress = true;
    _isLoading = true;
    _hasLoadError = false;
    _errorMessage = null;
    _notify();

    try {
      final saved = await _preferences.getString(storageKey);
      final loaded = <MyTodo>[];

      if (saved != null) {
        final decoded = jsonDecode(saved);
        if (decoded is! List) {
          throw const FormatException('Saved tasks must be a list.');
        }
        final ids = <int>{};
        for (final value in decoded) {
          if (value is! Map<String, dynamic>) {
            throw const FormatException('Invalid saved task.');
          }
          final todo = MyTodo.fromJson(value);
          if (!ids.add(todo.id)) {
            throw const FormatException('Duplicate saved task ID.');
          }
          loaded.add(todo);
        }
      }

      _todos
        ..clear()
        ..addAll(loaded);
      for (final todo in loaded) {
        if (todo.id > _lastId) _lastId = todo.id;
      }
    } catch (_) {
      // Pri chybe neprepíšeme pôvodné uložené dáta prázdnym zoznamom.
      _hasLoadError = true;
      _errorMessage = 'Could not load saved tasks. Please try again.';
    } finally {
      _loadInProgress = false;
      _isLoading = false;
      _notify();
    }
  }

  void setPriority(TodoPriority priority) {
    if (!_canEdit || _priority == priority) return;
    _priority = priority;
    _notify();
  }

  Future<bool> addTodo(String name) async {
    final trimmedName = name.trim();
    if (!_canEdit || trimmedName.isEmpty) return false;

    final now = DateTime.now().microsecondsSinceEpoch;
    _lastId = now > _lastId ? now : _lastId + 1;
    _todos.add(MyTodo(id: _lastId, name: trimmedName, priority: _priority));
    _priority = TodoPriority.normal;
    await _saveTodos();
    return true;
  }

  Future<void> toggleTodoStatus(int index, bool completed) async {
    if (!_canEdit || _todos[index].completed == completed) return;
    _todos[index] = _todos[index].copyWith(completed: completed);
    await _saveTodos();
  }

  Future<void> removeTodo(int index) async {
    if (!_canEdit) return;
    _todos.removeAt(index);
    await _saveTodos();
  }

  Future<void> _saveTodos() {
    // Každá zmena uloží vlastnú snímku. Zápisy prebehnú v rovnakom poradí.
    final saved = jsonEncode(_todos.map((todo) => todo.toJson()).toList());
    _pendingWrites++;
    _errorMessage = null;
    _notify();

    _writeQueue = _writeQueue.then((_) async {
      try {
        await _preferences.setString(storageKey, saved);
        _errorMessage = null;
      } catch (_) {
        _errorMessage = 'Could not save tasks. Changes are only in memory.';
      } finally {
        _pendingWrites--;
        _notify();
      }
    });
    return _writeQueue;
  }

  void clearError() {
    if (_errorMessage == null || _hasLoadError) return;
    _errorMessage = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}