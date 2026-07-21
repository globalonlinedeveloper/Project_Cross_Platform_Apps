import 'package:flutter/material.dart';

import '../../core/app_config.dart';

/// Settings — carries the chassis-mandated support contact (E1) and the
/// in-app account-deletion entry (G2). The Worker-side delete route is wired
/// by the services template (see services/{{app_id.snakeCase()}}-api).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: <Widget>[
          const ListTile(
            leading: Icon(Icons.mail_outline),
            title: Text('Contact support'),
            subtitle: Text(AppConfig.supportEmail),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete account'),
            subtitle: const Text('Permanently delete your account and data'),
            onTap: () => _confirmDelete(context),
          ),
          const AboutListTile(
            applicationName: AppConfig.appName,
            applicationLegalese: '© Nikatru',
            child: Text('About'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account and all its data. '
          'This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
