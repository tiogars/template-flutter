import 'package:flutter/material.dart';

import '../data/app_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.settings,
    required this.onApiChanged,
    super.key,
  });

  final AppSettings settings;
  final Future<void> Function() onApiChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.settings.apiBaseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.settings.setApiBaseUrl(_urlController.text);
      await widget.onApiChanged();
      if (!mounted) return;
      _urlController.text = widget.settings.apiBaseUrl;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('API settings saved.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'API connection',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the server used for all Task, Tag and Nomenclature requests.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _urlController,
                  enabled: !_saving,
                  keyboardType: TextInputType.url,
                  autofillHints: const [AutofillHints.url],
                  decoration: const InputDecoration(
                    labelText: 'API base URL',
                    hintText: AppSettings.defaultApiBaseUrl,
                    prefixIcon: Icon(Icons.dns_outlined),
                  ),
                  validator: (value) {
                    final uri = Uri.tryParse(value?.trim() ?? '');
                    if (uri == null ||
                        !uri.hasAuthority ||
                        (uri.scheme != 'http' && uri.scheme != 'https')) {
                      return 'Enter a valid HTTP or HTTPS URL.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
