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
    final storage    = ref.read(storageServiceProvider);
    final deviceId   = storage.deviceId;
    final macAddress = storage.macAddress;
    final deviceKey  = storage.deviceKey;

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

          // ── External Sources section ─────────────────────────────────────
          _SectionHeader('المصادر الخارجية'),

          _TmdbApiKeyTile(),

          const SizedBox(height: 20),

          // ── Device section ───────────────────────────────────────────────
          _SectionHeader('Device'),

          // MAC address — highlighted for IPTV portal registration
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1040), Color(0xFF0F1E40)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
            ),
            child: ListTile(
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
                child: const Icon(Icons.router_rounded,
                    color: Colors.white, size: 18),
              ),
              title: const Text('MAC Address',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  )),
              subtitle: Text(macAddress,
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    fontFamily: 'monospace',
                  )),
              trailing: IconButton(
                icon: const Icon(Icons.copy_rounded,
                    color: AppColors.primaryLight, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: macAddress));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('MAC Address copied!'),
                      duration: Duration(seconds: 2),
                      backgroundColor: AppColors.surface,
                    ),
                  );
                },
              ),
            ),
          ),

          _SettingsTile(
            icon:      Icons.vpn_key_rounded,
            iconColor: AppColors.warning,
            title:     'Device Key',
            subtitle:  deviceKey,
            trailing:  IconButton(
              icon: const Icon(Icons.copy_rounded,
                  color: AppColors.textMuted, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: deviceKey));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Device Key copied'),
                    duration: Duration(seconds: 2),
                    backgroundColor: AppColors.surface,
                  ),
                );
              },
            ),
          ),

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

// ── TMDB API Key tile ─────────────────────────────────────────────────────────
class _TmdbApiKeyTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_TmdbApiKeyTile> createState() => _TmdbApiKeyTileState();
}

class _TmdbApiKeyTileState extends ConsumerState<_TmdbApiKeyTile> {
  late final TextEditingController _ctrl;
  bool _obscure = true;
  bool _saved   = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: ref.read(storageServiceProvider).tmdbApiKey);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(storageServiceProvider).setTmdbApiKey(_ctrl.text);
    if (mounted) {
      setState(() => _saved = true);
      Future.delayed(const Duration(seconds: 2),
          () { if (mounted) setState(() => _saved = false); });
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF01D277).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('T', style: TextStyle(
                    color: Color(0xFF01D277),
                    fontSize: 18, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TMDB API Key',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('لعرض تقييمات وقصص الأفلام تلقائياً',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller:  _ctrl,
                obscureText: _obscure,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText:       'أدخل TMDB API Key هنا',
                  hintStyle:      const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                  filled:         true,
                  fillColor:      AppColors.surfaceLight,
                  border:         OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:   const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder:  OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:   const BorderSide(color: AppColors.border),
                  ),
                  isDense:        true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 10),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off_rounded
                                 : Icons.visibility_rounded,
                        size: 16, color: AppColors.textMuted),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _saved
                    ? const Color(0xFF27AE60)
                    : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(_saved ? '✓ تم' : 'حفظ',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {}, // could open browser to TMDB
            child: const Text(
              'احصل على مفتاح مجاني من themoviedb.org ← إعدادات ← API',
              style: TextStyle(
                  color: Color(0xFF01D277),
                  fontSize: 10,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF01D277)),
            ),
          ),
        ]),
      );
}
