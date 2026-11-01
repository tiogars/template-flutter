import 'package:domain_template_client/task_client.dart';
import 'package:domain_template_client/tag_client.dart';
import 'package:domain_template_client/nomenclature_client.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/task_repository.dart';
import '../../data/classification_repository.dart';

class TaskDetailPage extends StatelessWidget {
  const TaskDetailPage({
    required this.id,
    required this.repository,
    required this.classifications,
    required this.canEdit,
    super.key,
  });

  final int id;
  final TaskRepository repository;
  final ClassificationRepository classifications;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Task details'),
        actions: canEdit
            ? [
                IconButton(
                  onPressed: () => context.go('/tasks/$id/edit'),
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                ),
              ]
            : null,
      ),
      body: FutureBuilder<Task>(
        future: repository.findById(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final template = snapshot.requireData;
          final formatter = DateFormat.yMMMd().add_Hm();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    template.label,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    template.code,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 32),
                  _DetailRow(
                    icon: Icons.notes_outlined,
                    label: 'Description',
                    value: template.description ?? 'No description',
                  ),
                  _DetailRow(
                    icon: Icons.checklist,
                    label: 'Status',
                    value: taskStatusToJson(template.status),
                  ),
                  _DetailRow(
                    icon: Icons.flag_outlined,
                    label: 'Priority',
                    value: taskPriorityToJson(template.priority),
                  ),
                  _DetailRow(
                    icon: Icons.event_outlined,
                    label: 'Due date',
                    value: taskDateToJson(template.dueDate) ?? 'None',
                  ),
                  _DetailRow(
                    icon: Icons.person_outline,
                    label: 'Assigned to',
                    value: template.assignedTo ?? 'None',
                  ),
                  FutureBuilder<List<Tag>>(
                    future: classifications.tags(),
                    builder: (context, tags) => _DetailRow(
                      icon: Icons.sell_outlined,
                      label: 'Tags',
                      value: template.tagIds.isEmpty ? 'None' :
                          template.tagIds.map((id) {
                            final matches = tags.data?.where((tag) => tag.id == id);
                            return matches != null && matches.isNotEmpty
                                ? matches.first.label : '#$id';
                          }).join(', '),
                    ),
                  ),
                  FutureBuilder<List<Nomenclature>>(
                    future: classifications.nomenclatures(),
                    builder: (context, values) {
                      final matches = values.data?.where(
                        (item) => item.id == template.nomenclatureId,
                      );
                      return _DetailRow(
                        icon: Icons.account_tree_outlined,
                        label: 'Nomenclature',
                        value: template.nomenclatureId == null ? 'None' :
                            matches != null && matches.isNotEmpty
                                ? nomenclaturePath(matches.first, values.data!)
                                : '#${template.nomenclatureId}',
                      );
                    },
                  ),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Created',
                    value: formatter.format(template.createdDate.toLocal()),
                  ),
                  _DetailRow(
                    icon: Icons.person_outline,
                    label: 'Created by',
                    value: template.createdBy ?? '-',
                  ),
                  _DetailRow(
                    icon: Icons.person_outline,
                    label: 'Last modified by',
                    value: template.lastModifiedBy ?? '-',
                  ),
                  _DetailRow(
                    icon: Icons.update_outlined,
                    label: 'Last modified',
                    value: formatter.format(
                      template.lastModifiedDate.toLocal(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                SelectableText(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
