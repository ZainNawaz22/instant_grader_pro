import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Settings'),
            centerTitle: false,
            floating: true,
            snap: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProfileCard(context),
                const SizedBox(height: 24),
                _buildScanSettings(context),
                const SizedBox(height: 24),
                _buildAppSettings(context),
                const SizedBox(height: 24),
                _buildDataSettings(context),
                const SizedBox(height: 24),
                _buildAboutSection(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                LucideIcons.user,
                size: 32,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teacher Profile',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Manage your account settings',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanSettings(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: 'Scan Settings',
      icon: LucideIcons.camera,
      children: [
        _buildSettingsTile(
          context,
          title: 'Auto-Save Scans',
          subtitle: 'Automatically save completed scans',
          trailing: Switch(
            value: true,
            onChanged: (value) {},
          ),
        ),
        _buildSettingsTile(
          context,
          title: 'Scan Quality',
          subtitle: 'High resolution for better accuracy',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showScanQualityDialog(context),
        ),
        _buildSettingsTile(
          context,
          title: 'Auto-Crop',
          subtitle: 'Automatically crop answer sheets',
          trailing: Switch(
            value: false,
            onChanged: (value) {},
          ),
        ),
      ],
    );
  }

  Widget _buildAppSettings(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: 'App Settings',
      icon: LucideIcons.settings,
      children: [
        _buildSettingsTile(
          context,
          title: 'Theme',
          subtitle: 'System default',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showThemeDialog(context),
        ),
        _buildSettingsTile(
          context,
          title: 'Language',
          subtitle: 'English',
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        _buildSettingsTile(
          context,
          title: 'Notifications',
          subtitle: 'Manage notification preferences',
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildDataSettings(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: 'Data & Storage',
      icon: Icons.storage,
      children: [
        _buildSettingsTile(
          context,
          title: 'Export Data',
          subtitle: 'Export all scan results and answer keys',
          trailing: const Icon(LucideIcons.download),
          onTap: () => _showExportDialog(context),
        ),
        _buildSettingsTile(
          context,
          title: 'Import Data',
          subtitle: 'Import previously exported data',
          trailing: const Icon(Icons.upload),
          onTap: () {},
        ),
        _buildSettingsTile(
          context,
          title: 'Clear All Data',
          subtitle: 'Delete all scans and answer keys',
          trailing: Icon(
            Icons.delete,
            color: Theme.of(context).colorScheme.error,
          ),
          onTap: () => _showClearDataDialog(context),
          textColor: Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: 'About',
      icon: Icons.info,
      children: [
        _buildSettingsTile(
          context,
          title: 'Version',
          subtitle: '1.0.0',
          trailing: const SizedBox.shrink(),
        ),
        _buildSettingsTile(
          context,
          title: 'Privacy Policy',
          subtitle: 'View our privacy policy',
          trailing: const Icon(Icons.open_in_new),
          onTap: () {},
        ),
        _buildSettingsTile(
          context,
          title: 'Terms of Service',
          subtitle: 'View terms and conditions',
          trailing: const Icon(Icons.open_in_new),
          onTap: () {},
        ),
        _buildSettingsTile(
          context,
          title: 'Support',
          subtitle: 'Get help and report issues',
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showScanQualityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Quality'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('High'),
              subtitle: const Text('Best accuracy, larger file size'),
              value: 'high',
              groupValue: 'high',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: const Text('Medium'),
              subtitle: const Text('Good balance of quality and size'),
              value: 'medium',
              groupValue: 'high',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: const Text('Low'),
              subtitle: const Text('Faster processing, smaller size'),
              value: 'low',
              groupValue: 'high',
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('System Default'),
              value: 'system',
              groupValue: 'system',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'light',
              groupValue: 'system',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'dark',
              groupValue: 'system',
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Data',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.table_chart,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: const Text('Export to CSV'),
                    subtitle: const Text('Scan results in spreadsheet format'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.description,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    title: const Text('Export to PDF'),
                    subtitle: const Text('Formatted report with all data'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all scan results and answer keys. This action cannot be undone.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All data has been cleared'),
                ),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
} 