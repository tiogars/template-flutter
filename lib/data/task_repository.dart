import 'package:domain_template_client/task_client.dart';
import 'package:flutter/foundation.dart';

import 'app_settings.dart';

abstract interface class TaskRepository implements Listenable {
  Future<List<Task>> findAll();
  Future<Task> findById(int id);
  Future<Task> create(CreateTaskRequest request);
  Future<Task> update(int id, UpdateTaskRequest request);
  Future<void> delete(int id);
}

class ApiTaskRepository extends ChangeNotifier
    implements TaskRepository {
  ApiTaskRepository(
    this._settings,
    this._accessTokenProvider,
    this._onUnauthorized,
  );

  final AppSettings _settings;
  final String? Function() _accessTokenProvider;
  final Future<void> Function() _onUnauthorized;

  TaskClient get _client => TaskClient(
    baseUri: Uri.parse(_settings.apiBaseUrl),
    accessTokenProvider: _accessTokenProvider,
  );

  @override
  Future<Task> create(CreateTaskRequest request) async {
    final template = await _run(() => _client.create(request));
    notifyListeners();
    return template;
  }

  @override
  Future<void> delete(int id) async {
    await _run(() => _client.delete(id));
    notifyListeners();
  }

  @override
  Future<List<Task>> findAll() => _run(_client.findAll);

  @override
  Future<Task> findById(int id) => _run(() => _client.findById(id));

  @override
  Future<Task> update(
    int id,
    UpdateTaskRequest request,
  ) async {
    final template = await _run(() => _client.update(id, request));
    notifyListeners();
    return template;
  }

  Future<T> _run<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on TaskException catch (error) {
      if (error.statusCode == 401) await _onUnauthorized();
      rethrow;
    }
  }
}
