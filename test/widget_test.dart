import 'package:application/app.dart';
import 'package:application/data/app_settings.dart';
import 'package:application/data/auth_session.dart';
import 'package:application/data/task_repository.dart';
import 'package:application/data/classification_repository.dart';
import 'package:domain_template_client/auth_client.dart';
import 'package:domain_template_client/task_client.dart';
import 'package:domain_template_client/tag_client.dart';
import 'package:domain_template_client/nomenclature_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('redirects anonymous users to login and authenticates', (
    tester,
  ) async {
    final settings = AppSettings();
    final session = AuthSession(
      settings,
      storage: _MemoryTokenStorage(),
      gatewayFactory: (_, _) => _FakeAuthGateway(),
    );
    await tester.pumpWidget(
      TaskApp(
        settings: settings,
        authSession: session,
        repository: _FakeRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'admin',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Tasks'), findsWidgets);
    expect(find.text('CUSTOMER'), findsOneWidget);
  });

  testWidgets('lists templates and opens the details page', (tester) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(_authenticatedApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('CUSTOMER'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);

    await tester.tap(find.text('Customer'));
    await tester.pumpAndSettle();

    expect(find.text('Task details'), findsOneWidget);
    expect(find.text('Customer master data'), findsOneWidget);
  });

  testWidgets('creates a template from its dedicated page', (tester) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(_authenticatedApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Create'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Code'), 'ORDER');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Label'),
      'Order',
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create'));
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(repository.createdRequest?.code, 'ORDER');
    expect(find.text('Task details'), findsOneWidget);
    expect(find.text('Order'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(repository.findAllCalls, 2);
    expect(find.text('ORDER'), findsOneWidget);
  });

  testWidgets('requires confirmation before deleting', (tester) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(_authenticatedApp(repository));
    await tester.pumpAndSettle();

    final deleteButton = find.byTooltip('Delete CUSTOMER');
    await tester.ensureVisible(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(find.text('Delete Task?'), findsOneWidget);
    expect(repository.deletedIds, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repository.deletedIds, [1]);
    expect(find.text('CUSTOMER'), findsNothing);
  });

  testWidgets('desktop navigation supports deletion and signing out', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final repository = _FakeRepository();
    await tester.pumpWidget(_authenticatedApp(repository));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);
    await tester.tap(find.byTooltip('Delete CUSTOMER'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(repository.deletedIds, isEmpty);

    await tester.tap(find.byIcon(Icons.sell_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Work'), findsOneWidget);
    await tester.tap(find.byTooltip('Sign out admin'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);
    expect(find.byType(NavigationRail), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides write actions from non-admin users', (tester) async {
    await tester.pumpWidget(
      _authenticatedApp(_FakeRepository(), user: _reader),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FloatingActionButton, 'Create'), findsNothing);
    expect(find.byTooltip('Delete CUSTOMER'), findsNothing);
    expect(find.text('CUSTOMER'), findsOneWidget);
  });

  testWidgets('task form saves scheduling fields and relationship selectors', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(_authenticatedApp(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Create'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Code'),
      'MOBILE',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Label'),
      'Build app',
    );
    final status = find.byType(DropdownButtonFormField<TaskStatus>);
    await tester.ensureVisible(status);
    await tester.tap(status);
    await tester.pumpAndSettle();
    await tester.tap(find.text('IN_PROGRESS').last);
    await tester.pumpAndSettle();
    final priority = find.byType(DropdownButtonFormField<TaskPriority>);
    await tester.ensureVisible(priority);
    await tester.tap(priority);
    await tester.pumpAndSettle();
    await tester.tap(find.text('HIGH').last);
    await tester.pumpAndSettle();
    final due = find.widgetWithText(TextFormField, 'Due date');
    await tester.ensureVisible(due);
    await tester.enterText(due, '2026-11-05');
    final assigned = find.widgetWithText(TextFormField, 'Assigned to');
    await tester.ensureVisible(assigned);
    await tester.enterText(assigned, 'alice');
    final category = find.byType(DropdownButtonFormField<int>);
    await tester.ensureVisible(category);
    await tester.tap(category);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Projects / Mobile').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Work'));
    await tester.tap(find.widgetWithText(FilterChip, 'Work'));
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create'));
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();
    final request = repository.createdRequest!;
    expect(request.status, TaskStatus.inProgress);
    expect(request.priority, TaskPriority.high);
    expect(request.dueDate, DateTime(2026, 11, 5));
    expect(request.assignedTo, 'alice');
    expect(request.tagIds, [10]);
    expect(request.nomenclatureId, 21);
    expect(find.text('Task details'), findsOneWidget);
  });

  testWidgets('rejects invalid calendar dates before submitting', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(_authenticatedApp(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Create'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Code'), 'BAD');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Label'),
      'Bad date',
    );
    final due = find.widgetWithText(TextFormField, 'Due date');
    await tester.ensureVisible(due);
    await tester.enterText(due, '2026-02-30');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();
    expect(repository.createdRequest, isNull);
    await tester.ensureVisible(due);
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid date (YYYY-MM-DD).'), findsOneWidget);
  });

  testWidgets('manages tags and displays hierarchical nomenclature paths', (
    tester,
  ) async {
    await tester.pumpWidget(_authenticatedApp(_FakeRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.sell_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Work'), findsOneWidget);
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Create'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Code'), 'HOME');
    await tester.enterText(find.widgetWithText(TextFormField, 'Label'), 'Home');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.account_tree_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Projects / Mobile'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit ROOT'));
    await tester.pumpAndSettle();
    final parentSelector = tester.widget<DropdownButtonFormField<int>>(
      find.byType(DropdownButtonFormField<int>),
    );
    expect(parentSelector.initialValue, isNull);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    expect(find.text('None (root)'), findsWidgets);
  });
}

Widget _authenticatedApp(TaskRepository repository, {AuthUser user = _admin}) {
  final settings = AppSettings();
  return TaskApp(
    settings: settings,
    authSession: AuthSession(
      settings,
      storage: _MemoryTokenStorage(),
      initialUser: user,
    ),
    repository: repository,
    classifications: _FakeClassifications(),
  );
}

const _admin = AuthUser(
  id: 1,
  username: 'admin',
  enabled: true,
  roles: [AuthRole(id: 1, code: 'ADMIN', label: 'Administrator')],
);

const _reader = AuthUser(
  id: 2,
  username: 'reader',
  enabled: true,
  roles: [AuthRole(id: 2, code: 'USER', label: 'User')],
);

class _MemoryTokenStorage implements TokenStorage {
  String? token;

  @override
  Future<void> clear() async => token = null;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;
}

class _FakeAuthGateway implements AuthGateway {
  @override
  Future<LoginResponse> login(String username, String password) async =>
      LoginResponse(
        token: 'jwt-token',
        tokenType: 'Bearer',
        expiresAt: DateTime.utc(2026, 1, 1),
        user: _admin,
      );

  @override
  Future<AuthUser> me() async => _admin;
}

class _FakeRepository extends ChangeNotifier implements TaskRepository {
  final List<Task> _templates = [
    Task(
      id: 1,
      code: 'CUSTOMER',
      label: 'Customer',
      description: 'Customer master data',
      createdDate: DateTime.utc(2026, 1, 1),
      lastModifiedDate: DateTime.utc(2026, 1, 2),
    ),
  ];

  CreateTaskRequest? createdRequest;
  final List<int> deletedIds = [];
  int findAllCalls = 0;

  @override
  Future<Task> create(CreateTaskRequest request) async {
    createdRequest = request;
    final template = Task(
      id: 2,
      code: request.code,
      label: request.label,
      description: request.description,
      status: request.status,
      priority: request.priority,
      dueDate: request.dueDate,
      assignedTo: request.assignedTo,
      tagIds: request.tagIds,
      nomenclatureId: request.nomenclatureId,
      createdDate: DateTime.utc(2026, 1, 3),
      lastModifiedDate: DateTime.utc(2026, 1, 3),
    );
    _templates.add(template);
    notifyListeners();
    return template;
  }

  @override
  Future<void> delete(int id) async {
    deletedIds.add(id);
    _templates.removeWhere((template) => template.id == id);
    notifyListeners();
  }

  @override
  Future<List<Task>> findAll() async {
    findAllCalls++;
    return List.of(_templates);
  }

  @override
  Future<Task> findById(int id) async =>
      _templates.singleWhere((template) => template.id == id);

  @override
  Future<Task> update(int id, UpdateTaskRequest request) async {
    final current = await findById(id);
    final updated = Task(
      id: current.id,
      code: current.code,
      label: request.label,
      description: request.description,
      status: request.status,
      priority: request.priority,
      dueDate: request.dueDate,
      assignedTo: request.assignedTo,
      tagIds: request.tagIds,
      nomenclatureId: request.nomenclatureId,
      createdDate: current.createdDate,
      lastModifiedDate: DateTime.utc(2026, 1, 4),
    );
    final index = _templates.indexWhere((template) => template.id == id);
    _templates[index] = updated;
    notifyListeners();
    return updated;
  }
}

class _FakeClassifications implements ClassificationRepository {
  final List<Tag> _tags = [
    Tag(
      id: 10,
      code: 'WORK',
      label: 'Work',
      createdDate: DateTime.utc(2026),
      lastModifiedDate: DateTime.utc(2026),
    ),
  ];
  final List<Nomenclature> _nodes = [
    Nomenclature(
      id: 20,
      code: 'ROOT',
      label: 'Projects',
      createdDate: DateTime.utc(2026),
      lastModifiedDate: DateTime.utc(2026),
    ),
    Nomenclature(
      id: 21,
      code: 'CHILD',
      label: 'Mobile',
      parentId: 20,
      createdDate: DateTime.utc(2026),
      lastModifiedDate: DateTime.utc(2026),
    ),
  ];

  @override
  Future<List<Tag>> tags() async => List.of(_tags);
  @override
  Future<List<Nomenclature>> nomenclatures() async => List.of(_nodes);
  @override
  Future<Tag> createTag(CreateTagRequest request) async {
    final tag = Tag(
      id: 11,
      code: request.code,
      label: request.label,
      description: request.description,
      createdDate: DateTime.utc(2026),
      lastModifiedDate: DateTime.utc(2026),
    );
    _tags.add(tag);
    return tag;
  }

  @override
  Future<Tag> updateTag(int id, UpdateTagRequest request) async =>
      throw UnimplementedError();
  @override
  Future<void> deleteTag(int id) async =>
      _tags.removeWhere((tag) => tag.id == id);
  @override
  Future<Nomenclature> createNomenclature(
    CreateNomenclatureRequest request,
  ) async => throw UnimplementedError();
  @override
  Future<Nomenclature> updateNomenclature(
    int id,
    UpdateNomenclatureRequest request,
  ) async => throw UnimplementedError();
  @override
  Future<void> deleteNomenclature(int id) async =>
      _nodes.removeWhere((node) => node.id == id);
}
