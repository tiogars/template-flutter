import 'package:flutter/material.dart';
import 'package:domain_template_client/nomenclature_client.dart';
import 'package:domain_template_client/resource_client.dart';
import 'package:domain_template_client/tag_client.dart';

import '../data/classification_repository.dart';

class ClassificationsPage extends StatefulWidget {
  const ClassificationsPage({
    required this.repository,
    required this.hierarchical,
    required this.canManage,
    super.key,
  });

  final ClassificationRepository repository;
  final bool hierarchical;
  final bool canManage;

  @override
  State<ClassificationsPage> createState() => _ClassificationsPageState();
}

class _ClassificationsPageState extends State<ClassificationsPage> {
  List<Category> _items = [];
  bool _loading = true;
  String? _error;
  String get _title => widget.hierarchical ? 'Nomenclatures' : 'Tags';
  List<Nomenclature> get _nodes => _items.cast<Nomenclature>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = widget.hierarchical
          ? await widget.repository.nomenclatures()
          : await widget.repository.tags();
      if (!mounted) return;
      _items = List<Category>.of(items);
      _items.sort((a, b) => _label(a).compareTo(_label(b)));
    } catch (error) {
      if (mounted) _error = error.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _label(Category item) => item is Nomenclature
      ? nomenclaturePath(item, _nodes) : item.label;

  bool _validParent(Nomenclature node, Category? editing) {
    final visited = <int>{};
    Nomenclature? current = node;
    while (current != null && visited.add(current.id)) {
      if (current.id == editing?.id) return false;
      final parents = _nodes.where((item) => item.id == current!.parentId);
      current = parents.isEmpty ? null : parents.first;
    }
    return true;
  }

  Future<void> _edit([Category? item]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _CategoryEditor(
        item: item,
        hierarchical: widget.hierarchical,
        parents: widget.hierarchical
            ? _nodes.where((node) => _validParent(node, item)).toList()
            : const [],
        allNodes: widget.hierarchical ? _nodes : const [],
        repository: widget.repository,
      ),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _delete(Category item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${item.label}?'),
        content: const Text(
          'Referenced categories cannot be deleted. This action is permanent.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      if (widget.hierarchical) {
        await widget.repository.deleteNomenclature(item.id);
      } else {
        await widget.repository.deleteTag(item.id);
      }
      if (mounted) await _load();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_title), actions: [
      IconButton(onPressed: _load, tooltip: 'Refresh', icon: const Icon(Icons.refresh)),
    ]),
    floatingActionButton: widget.canManage && !_loading
        ? FloatingActionButton.extended(
            onPressed: () => _edit(), icon: const Icon(Icons.add),
            label: const Text('Create'),
          )
        : null,
    body: _loading ? const Center(child: CircularProgressIndicator()) : Column(
      children: [
        if (_error != null)
          MaterialBanner(content: Text(_error!), actions: [
            TextButton(onPressed: _load, child: const Text('Retry')),
          ]),
        Expanded(child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              if (_items.isEmpty) Text('No ${_title.toLowerCase()} yet.'),
              for (final item in _items)
                Card(child: ListTile(
                  title: Text(_label(item)),
                  subtitle: Text('${item.code}\n${item.description ?? 'No description'}'),
                  isThreeLine: true,
                  trailing: widget.canManage ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(onPressed: () => _edit(item),
                        tooltip: 'Edit ${item.code}', icon: const Icon(Icons.edit_outlined)),
                      IconButton(onPressed: () => _delete(item),
                        tooltip: 'Delete ${item.code}', icon: const Icon(Icons.delete_outline)),
                    ],
                  ) : null,
                )),
            ],
          ),
        )),
      ],
    ),
  );
}

class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({
    required this.item,
    required this.hierarchical,
    required this.parents,
    required this.allNodes,
    required this.repository,
  });
  final Category? item;
  final bool hierarchical;
  final List<Nomenclature> parents;
  final List<Nomenclature> allNodes;
  final ClassificationRepository repository;

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  final _form = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.item?.code);
  late final _label = TextEditingController(text: widget.item?.label);
  late final _description = TextEditingController(text: widget.item?.description);
  late int? _parentId = widget.item is Nomenclature
      ? (widget.item! as Nomenclature).parentId : null;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose(); _label.dispose(); _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    final description = _description.text.trim();
    try {
      if (widget.hierarchical) {
        if (widget.item == null) {
          await widget.repository.createNomenclature(CreateNomenclatureRequest(
            code: _code.text.trim(), label: _label.text.trim(),
            description: description.isEmpty ? null : description, parentId: _parentId,
          ));
        } else {
          await widget.repository.updateNomenclature(widget.item!.id,
            UpdateNomenclatureRequest(label: _label.text.trim(),
              description: description.isEmpty ? null : description, parentId: _parentId));
        }
      } else if (widget.item == null) {
        await widget.repository.createTag(CreateTagRequest(
          code: _code.text.trim(), label: _label.text.trim(),
          description: description.isEmpty ? null : description,
        ));
      } else {
        await widget.repository.updateTag(widget.item!.id, UpdateTagRequest(
          label: _label.text.trim(), description: description.isEmpty ? null : description,
        ));
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'This field is required.' : null;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('${widget.item == null ? 'Create' : 'Edit'} ${widget.hierarchical ? 'nomenclature' : 'tag'}'),
    content: SizedBox(width: 520, child: SingleChildScrollView(child: Form(
      key: _form,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        TextFormField(controller: _code, enabled: widget.item == null && !_saving,
          decoration: const InputDecoration(labelText: 'Code'), validator: _required),
        const SizedBox(height: 16),
        TextFormField(controller: _label, enabled: !_saving,
          decoration: const InputDecoration(labelText: 'Label'), validator: _required),
        const SizedBox(height: 16),
        TextFormField(controller: _description, enabled: !_saving,
          decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
        if (widget.hierarchical) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _parentId, isExpanded: true,
            decoration: const InputDecoration(labelText: 'Parent'),
            items: [
              const DropdownMenuItem<int>(child: Text('None (root)')),
              for (final parent in widget.parents)
                DropdownMenuItem(value: parent.id,
                  child: Text(nomenclaturePath(parent, widget.allNodes))),
            ],
            onChanged: _saving ? null : (value) => setState(() => _parentId = value),
          ),
        ],
      ]),
    ))),
    actions: [
      TextButton(onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel')),
      FilledButton(onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Saving…' : 'Save')),
    ],
  );
}
