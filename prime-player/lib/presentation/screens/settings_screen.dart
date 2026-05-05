import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../providers/playlist_provider.dart';
import 'add_playlist_screen.dart';
import 'home_screen.dart';

// ── Settings providers ────────────────────────────────────────────────────────
final _appLanguageProvider = StateProvider<String>((ref) {
  return ref.read(storageServiceProvider).appLanguage;
});

final _pinEnabledProvider = StateProvider<bool>((ref) {
  return ref.read(storageServiceProvider).pinEnabled;
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang       = ref.watch(_appLanguageProvider);
    final pinEnabled = ref.watch(_pinEnabledProvider);
    final deviceId   = ref.read(storageServiceProvider).deviceId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Settings',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── App section ─────────────────────────────────────────────────
          _SectionHeader('App'),

          _SettingsTile(
            icon:     Icons.language_rounded,
            iconColor: AppColors.primary,
            title:    'Language',
            trailing: _LanguagePicker(
              value: lang,
              onChanged: (l) async {
                ref.read(_appLanguageProvider.notifier).state = l;
                await ref.read(storageServiceProvider).setAppLanguage(l);
              },
            ),
          ),

          _SettingsTile(
            icon:      Icons.lock_rounded,
            iconColor: AppColors.accent,
            title:     'PIN Lock',
            subtitle:  pinEnabled ? 'Enabled' : 'Disabled',
            trailing: Switch(
              value:     pinEnabled,
              onChanged: (v) async {
                ref.read(_pinEnabledProvider.notifier).state = v;
                await ref.read(storageServiceProvider).setPinEnabled(v);
              },
              activeColor: AppColors.primary,
            ),
          ),

          const SizedBox(height: 20),

          // ── Device section ───────────────────────────────────────────────
          _SectionHeader('Device'),

          _SettingsTile(
            icon:      Icons.fingerprint_rounded,
            iconColor: const Color(0xFF06B6D4),
            title:     'Device ID',
            subtitle:  deviceId,
            trailing:  IconButton(
              icon: const Icon(Icons.copy_rounded,
                  color: AppColors.textMuted, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: deviceId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Device ID copied'),
                    duration: Duration(seconds: 2),
                    backgroundColor: AppColors.surface,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // ── Playlists section ────────────────────────────────────────────
          _SectionHeader('Playlists'),

          _SettingsTile(
            icon:      Icons.add_circle_outline_rounded,
            iconColor: AppColors.success,
            title:     'Add Playlist',
            subtitle:  'M3U URL or Xtream Codes',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddPlaylistScreen())),
          ),

          _SettingsTile(
            icon:      Icons.playlist_remove_rounded,
            iconColor: AppColors.error,
            title:     'Manage Playlists',
            subtitle:  'Switch or delete playlists',
            onTap: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            ),
          ),

          const SizedBox(height: 20),

          // ── Support section ──────────────────────────────────────────────
          _SectionHeader('Support'),

          _SettingsTile(
            icon:      Icons.support_agent_rounded,
            iconColor: const Color(0xFF10B981),
            title:     'WhatsApp Support',
            subtitle:  AppStrings.whatsApp,
            onTap: () {},
          ),

          _SettingsTile(
            icon:      Icons.public_rounded,
            iconColor: AppColors.textSecondary,
            title:     'Website',
            subtitle:  AppStrings.website,
          ),

          const SizedBox(height: 20),

          // ── Info section ─────────────────────────────────────────────────
          _SectionHeader('About'),

          _SettingsTile(
            icon:      Icons.info_outline_rounded,
            iconColor: AppColors.textMuted,
            title:     'Version',
            subtitle:  '2.0.0',
          ),

          const SizedBox(height: 32),

          Center(
            child: Text(
              '© ${AppStrings.appName} – ${AppStrings.website}',
              style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Language picker ───────────────────────────────────────────────────────────
class _LanguagePicker extends StatelessWidget {
  final String              value;
  final ValueChanged<String> onChanged;

  const _LanguagePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      dropdownColor: AppColors.surface,
      underline: const SizedBox(),
      style: const TextStyle(
          color: AppColors.textPrimary, fontSize: 13),
      items: const [
        DropdownMenuItem(value: 'en', child: Text('English')),
        DropdownMenuItem(value: 'ar', child: Text('العربية')),
        DropdownMenuItem(value: 'fr', child: Text('Français')),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
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

// ── Settings tile ─────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData     icon;
  final Color        iconColor;
  final String       title;
  final String?      subtitle;
  final VoidCallback? onTap;
  final Widget?      trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
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
          width: 36, height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: iconColor.withOpacity(0.15),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            )),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 20)
                : null),
      ),
    );
  }
}
