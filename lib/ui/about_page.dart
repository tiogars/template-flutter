import 'package:flutter/material.dart';

import '../data/system_info_service.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({this.service = const SystemInfoService(), super.key});

  final SystemInfoService service;

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late final Future<SystemInfo> _systemInfo = widget.service.load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: FutureBuilder<SystemInfo>(
        future: _systemInfo,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final info = snapshot.requireData;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Icon(
                    Icons.layers_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Task Manager',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 32),
                  _InfoTile(
                    label: 'Application',
                    value: info.applicationVersion,
                  ),
                  _InfoTile(label: 'Flutter SDK', value: info.flutterVersion),
                  _InfoTile(label: 'Dart SDK', value: info.dartVersion),
                  _InfoTile(label: 'Platform', value: info.operatingSystem),
                  _InfoTile(
                    label: 'OS / browser version',
                    value: info.operatingSystemVersion,
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Flexible(
        child: SelectableText(value, textAlign: TextAlign.end),
      ),
    );
  }
}
