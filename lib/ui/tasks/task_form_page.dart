import 'package:domain_template_client/task_client.dart';
import 'package:domain_template_client/tag_client.dart';
import 'package:domain_template_client/nomenclature_client.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/task_repository.dart';
import '../../data/classification_repository.dart';

class TaskFormPage extends StatefulWidget {
  const TaskFormPage.create({
    required this.repository,
    required this.classifications,
    super.key,
  }) : id = null;

  const TaskFormPage.edit({
    required this.id,
    required this.repository,
    required this.classifications,
    super.key,
  });

  final int? id;
  final TaskRepository repository;
  final ClassificationRepository classifications;

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _labelController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _assignedToController = TextEditingController();
  TaskStatus _status = TaskStatus.todo;
  TaskPriority _priority = TaskPriority.normal;
  Set<int> _tagIds = {};
  int? _nomenclatureId;
  List<Tag> _tags = [];
  List<Nomenclature> _nomenclatures = [];
  bool _loadFailed = false;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.id != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
      _error = null;
    });
    try {
      if (_isEditing) {
        final task = await widget.repository.findById(widget.id!);
        if (!mounted) return;
        _codeController.text = task.code;
        _labelController.text = task.label;
        _descriptionController.text = task.description ?? '';
        _status = task.status;
        _priority = task.priority;
        _dueDateController.text = taskDateToJson(task.dueDate) ?? '';
        _assignedToController.text = task.assignedTo ?? '';
        _tagIds = task.tagIds.toSet();
        _nomenclatureId = task.nomenclatureId;
      }
      final tags = await widget.classifications.tags();
      final nomenclatures = await widget.classifications.nomenclatures();
      if (!mounted) return;
      _tags = tags;
      _nomenclatures = nomenclatures;
    } catch (error) {
      _loadFailed = true;
      _error = error.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final description = _descriptionController.text.trim();
      final assignedTo = _assignedToController.text.trim();
      final dueDate = _dueDateController.text.trim();
      final Task saved;
      if (_isEditing) {
        saved = await widget.repository.update(
          widget.id!,
          UpdateTaskRequest(
            label: _labelController.text.trim(),
            description: description.isEmpty ? null : description,
            status: _status,
            priority: _priority,
            dueDate: dueDate.isEmpty ? null : DateTime.parse(dueDate),
            assignedTo: assignedTo.isEmpty ? null : assignedTo,
            tagIds: _tagIds.toList(),
            nomenclatureId: _nomenclatureId,
          ),
        );
      } else {
        saved = await widget.repository.create(
          CreateTaskRequest(
            code: _codeController.text.trim(),
            label: _labelController.text.trim(),
            description: description.isEmpty ? null : description,
            status: _status,
            priority: _priority,
            dueDate: dueDate.isEmpty ? null : DateTime.parse(dueDate),
            assignedTo: assignedTo.isEmpty ? null : assignedTo,
            tagIds: _tagIds.toList(),
            nomenclatureId: _nomenclatureId,
          ),
        );
      }
      if (mounted) context.go('/tasks/${saved.id}');
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _labelController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    _assignedToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null) ...[
                          MaterialBanner(
                            content: Text(_error!),
                            actions: [
                              if (_loadFailed)
                                TextButton(
                                  onPressed: _load,
                                  child: const Text('Retry'),
                                ),
                              TextButton(
                                onPressed: () => setState(() => _error = null),
                                child: const Text('Dismiss'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                        TextFormField(
                          controller: _codeController,
                          enabled: !_isEditing && !_saving,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Code',
                            prefixIcon: Icon(Icons.key_outlined),
                            helperText:
                                'The code cannot be changed after creation.',
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _labelController,
                          enabled: !_saving,
                          decoration: const InputDecoration(
                            labelText: 'Label',
                            prefixIcon: Icon(Icons.label_outline),
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _descriptionController,
                          enabled: !_saving,
                          minLines: 4,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                        ),
                        const SizedBox(height: 32),
                        DropdownButtonFormField<TaskStatus>(
                          initialValue: _status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                          ),
                          items: TaskStatus.values
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(taskStatusToJson(status)),
                                ),
                              )
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => _status = value!),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<TaskPriority>(
                          initialValue: _priority,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                          ),
                          items: TaskPriority.values
                              .map(
                                (priority) => DropdownMenuItem(
                                  value: priority,
                                  child: Text(taskPriorityToJson(priority)),
                                ),
                              )
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => _priority = value!),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _dueDateController,
                          enabled: !_saving,
                          decoration: const InputDecoration(
                            labelText: 'Due date',
                            hintText: 'YYYY-MM-DD',
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return null;
                            final date = DateTime.tryParse(text);
                            if (!RegExp(
                                  r'^\d{4}-\d{2}-\d{2}$',
                                ).hasMatch(text) ||
                                date == null ||
                                taskDateToJson(date) != text) {
                              return 'Enter a valid date (YYYY-MM-DD).';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _assignedToController,
                          enabled: !_saving,
                          decoration: const InputDecoration(
                            labelText: 'Assigned to',
                          ),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<int>(
                          initialValue: _nomenclatureId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Nomenclature',
                          ),
                          items: [
                            const DropdownMenuItem<int>(child: Text('None')),
                            for (final item in _nomenclatures)
                              DropdownMenuItem(
                                value: item.id,
                                child: Text(
                                  nomenclaturePath(item, _nomenclatures),
                                ),
                              ),
                          ],
                          onChanged: _saving
                              ? null
                              : (value) =>
                                    setState(() => _nomenclatureId = value),
                        ),
                        const SizedBox(height: 20),
                        const Text('Tags'),
                        if (_tags.isEmpty) const Text('No tags available.'),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final tag in _tags)
                              FilterChip(
                                label: Text(tag.label),
                                selected: _tagIds.contains(tag.id),
                                onSelected: _saving
                                    ? null
                                    : (selected) => setState(() {
                                        if (selected) {
                                          _tagIds.add(tag.id);
                                        } else {
                                          _tagIds.remove(tag.id);
                                        }
                                      }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _saving ? null : () => context.pop(),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: _saving || _loadFailed ? null : _save,
                              icon: _saving
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(_isEditing ? 'Save' : 'Create'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;
}
