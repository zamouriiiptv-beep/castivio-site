import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../providers/playlist_provider.dart';
import 'home_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader('App'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Version',
            subtitle: '1.0.0',
          ),
          _SettingsTile(
            icon: Icons.language_rounded,
            title: 'Website',
            subtitle: AppStrings.website,
          ),
          const SizedBox(height: 24),
          _SectionHeader('Playlists'),
          _SettingsTile(
            icon: Icons.playlist_remove_rounded,
            title: 'Manage Playlists',
            subtitle: 'Add or remove playlists',
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader('Support'),
          _SettingsTile(
            icon: Icons.support_agent_rounded,
            title: 'WhatsApp Support',
            subtitle: AppStrings.whatsApp,
            onTap: () {},
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              '© ${AppStrings.appName} – ${AppStrings.website}',
              style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.primary.withOpacity(0.15),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            )),
        subtitle: Text(subtitle,
            style: const TextStyle(
              color: AppColors.textMuted, fontSize: 12)),
        trailing: onTap != null
            ? const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20)
            : null,
      ),
    );
  }
}
