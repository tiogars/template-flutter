import 'dart:async';

import 'package:domain_template_client/task_client.dart';
import 'package:flutter/foundation.dart';

import '../../data/task_repository.dart';

class TasksViewModel extends ChangeNotifier {
  TasksViewModel(this._repository) {
    _repository.addListener(_reload);
  }

  final TaskRepository _repository;
  List<Task> _templates = const [];
  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => List.unmodifiable(_templates);
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _reload() => unawaited(load());

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _templates = await _repository.findAll();
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> delete(Task template) async {
    try {
      await _repository.delete(template.id);
      return true;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _repository.removeListener(_reload);
    super.dispose();
  }
}
