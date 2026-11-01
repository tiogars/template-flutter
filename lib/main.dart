import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_settings.dart';
import 'data/auth_session.dart';
import 'data/task_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  await settings.load();
  final authSession = AuthSession(settings);
  await authSession.restore();
  runApp(
    TaskApp(
      settings: settings,
      authSession: authSession,
      repository: ApiTaskRepository(
        settings,
        () => authSession.accessToken,
        authSession.logout,
      ),
    ),
  );
}
