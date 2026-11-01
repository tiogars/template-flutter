import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/app_settings.dart';
import 'data/auth_session.dart';
import 'data/task_repository.dart';
import 'data/classification_repository.dart';
import 'ui/about_page.dart';
import 'ui/app_shell.dart';
import 'ui/tasks/task_detail_page.dart';
import 'ui/tasks/task_form_page.dart';
import 'ui/tasks/task_list_page.dart';
import 'ui/classifications_page.dart';
import 'ui/login_page.dart';
import 'ui/settings_page.dart';

class TaskApp extends StatefulWidget {
  const TaskApp({
    required this.settings,
    required this.authSession,
    required this.repository,
    this.classifications,
    super.key,
  });

  final AppSettings settings;
  final AuthSession authSession;
  final TaskRepository repository;
  final ClassificationRepository? classifications;

  @override
  State<TaskApp> createState() => _TaskAppState();
}

class _TaskAppState extends State<TaskApp> {
  late final ClassificationRepository _classifications =
      widget.classifications ??
      ApiClassificationRepository(
        widget.settings,
        () => widget.authSession.accessToken,
        widget.authSession.logout,
      );
  late final GoRouter _router = GoRouter(
    initialLocation: '/tasks',
    refreshListenable: widget.authSession,
    redirect: (context, state) {
      final path = state.uri.path;
      final isPublic =
          path == '/login' || path == '/settings' || path == '/about';
      if (!widget.authSession.isAuthenticated && !isPublic) return '/login';
      if (widget.authSession.isAuthenticated && path == '/login') {
        return '/tasks';
      }
      final requiresAdmin = path == '/tasks/new' || path.endsWith('/edit');
      if (requiresAdmin && !widget.authSession.isAdmin) return '/tasks';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(authSession: widget.authSession),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          location: state.uri.path,
          authSession: widget.authSession,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/tasks',
            builder: (context, state) => TaskListPage(
              repository: widget.repository,
              canManage: widget.authSession.isAdmin,
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => TaskFormPage.create(
                  repository: widget.repository,
                  classifications: _classifications,
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => TaskDetailPage(
                  id: int.parse(state.pathParameters['id']!),
                  repository: widget.repository,
                  classifications: _classifications,
                  canEdit: widget.authSession.isAdmin,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => TaskFormPage.edit(
                      id: int.parse(state.pathParameters['id']!),
                      repository: widget.repository,
                      classifications: _classifications,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/tags',
            builder: (context, state) => ClassificationsPage(
              repository: _classifications,
              hierarchical: false,
              canManage: widget.authSession.isAdmin,
            ),
          ),
          GoRoute(
            path: '/nomenclatures',
            builder: (context, state) => ClassificationsPage(
              repository: _classifications,
              hierarchical: true,
              canManage: widget.authSession.isAdmin,
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => SettingsPage(
              settings: widget.settings,
              onApiChanged: widget.authSession.logout,
            ),
          ),
          GoRoute(
            path: '/about',
            builder: (context, state) => const AboutPage(),
          ),
        ],
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF006D77),
      brightness: Brightness.light,
    );
    return MaterialApp.router(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF7F9F8),
        appBarTheme: const AppBarTheme(centerTitle: false),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
