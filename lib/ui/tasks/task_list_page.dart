import 'package:domain_template_client/task_client.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/task_repository.dart';
import 'tasks_view_model.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({
    required this.repository,
    required this.canManage,
    super.key,
  });

  final TaskRepository repository;
  final bool canManage;

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  late final TasksViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TasksViewModel(widget.repository)..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(Task template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task?'),
        content: Text(
          '${template.label} (${template.code}) will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await _viewModel.delete(template);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(deleted ? 'Task deleted.' : 'Deletion failed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            onPressed: _viewModel.load,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: widget.canManage
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/tasks/new'),
              icon: const Icon(Icons.add),
              label: const Text('Create'),
            )
          : null,
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.tasks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_viewModel.error != null && _viewModel.tasks.isEmpty) {
            return _ErrorState(
              message: _viewModel.error!,
              onRetry: _viewModel.load,
            );
          }
          if (_viewModel.tasks.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: _viewModel.load,
            child: LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth >= 760
                  ? _TaskTable(
                      templates: _viewModel.tasks,
                      canManage: widget.canManage,
                      onDelete: _confirmDelete,
                    )
                  : _TaskList(
                      templates: _viewModel.tasks,
                      canManage: widget.canManage,
                      onDelete: _confirmDelete,
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.templates,
    required this.canManage,
    required this.onDelete,
  });

  final List<Task> templates;
  final bool canManage;
  final ValueChanged<Task> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: templates.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final template = templates[index];
        return Card(
          child: ListTile(
            onTap: () => context.go('/tasks/${template.id}'),
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            leading: CircleAvatar(child: Text(template.code.characters.first)),
            title: Text(template.label),
            subtitle: Text(
              '${template.code} · ${taskStatusToJson(template.status)} · ${taskPriorityToJson(template.priority)}\n${template.description ?? 'No description'}',
            ),
            isThreeLine: true,
            trailing: canManage
                ? PopupMenuButton<String>(
                    tooltip: 'Actions',
                    onSelected: (action) {
                      if (action == 'edit') {
                        context.go('/tasks/${template.id}/edit');
                      } else {
                        onDelete(template);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  )
                : const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

class _TaskTable extends StatelessWidget {
  const _TaskTable({
    required this.templates,
    required this.canManage,
    required this.onDelete,
  });

  final List<Task> templates;
  final bool canManage;
  final ValueChanged<Task> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            columns: [
              const DataColumn(label: Text('Code')),
              const DataColumn(label: Text('Label')),
              const DataColumn(label: Text('Description')),
              if (canManage) const DataColumn(label: Text('Actions')),
            ],
            rows: templates
                .map(
                  (template) => DataRow(
                    onSelectChanged: (_) => context.go('/tasks/${template.id}'),
                    cells: [
                      DataCell(Text(template.code)),
                      DataCell(Text(template.label)),
                      DataCell(Text(template.description ?? '-')),
                      if (canManage)
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () =>
                                    context.go('/tasks/${template.id}/edit'),
                                tooltip: 'Edit ${template.code}',
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                onPressed: () => onDelete(template),
                                tooltip: 'Delete ${template.code}',
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 56),
          SizedBox(height: 16),
          Text('No Tasks yet'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
