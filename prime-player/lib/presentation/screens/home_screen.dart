import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../data/models/playlist.dart';
import '../providers/playlist_provider.dart';
import 'add_playlist_screen.dart';
import 'live_tv_screen.dart';
import 'movies_screen.dart';
import 'radios_screen.dart';
import 'series_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlists = ref.watch(playlistsProvider);
    final activeId  = ref.watch(activePlaylistIdProvider);

    if (activeId == null && playlists.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final id = playlists.first.id;
        ref.read(activePlaylistIdProvider.notifier).state = id;
        ref.read(storageServiceProvider).setActivePlaylistId(id);
      });
    }

    final activePlaylist = playlists.isEmpty
        ? null
        : playlists.firstWhere((p) => p.id == activeId,
            orElse: () => playlists.first);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: playlists.isEmpty
            ? _EmptyState(
                onAdd: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AddPlaylistScreen()));
                  ref.read(playlistRefreshProvider.notifier).state++;
                },
              )
            : _HomeLayout(playlist: activePlaylist, playlists: playlists),
      ),
    );
  }
}

// ── Main layout ───────────────────────────────────────────────────────────────
class _HomeLayout extends ConsumerWidget {
  final Playlist?      playlist;
  final List<Playlist> playlists;
  const _HomeLayout({required this.playlist, required this.playlists});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveCount   = ref.watch(liveChannelsProvider).length;
    final movieCount  = ref.watch(movieChannelsProvider).length;
    final seriesCount = ref.watch(seriesChannelsProvider).length;
    final radioCount  = ref.watch(radioChannelsProvider).length;

    return Column(
      children: [
        _TopBar(playlist: playlist, playlists: playlists),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  _ContentTile(
                    icon:     Icons.live_tv_rounded,
                    label:    'Live TV',
                    subtitle: '$liveCount channels',
                    colors:   const [Color(0xFF7C3AED), Color(0xFF2563EB)],
                    onTap: () {
                      ref.read(activeCategoryProvider.notifier).state = null;
                      ref.read(searchQueryProvider.notifier).state    = '';
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const LiveTvScreen()));
                    },
                  ),
                  const SizedBox(width: 14),
                  _ContentTile(
                    icon:     Icons.movie_creation_rounded,
                    label:    'Movies',
                    subtitle: '$movieCount films',
                    colors:   const [Color(0xFFDB2777), Color(0xFFEF4444)],
                    onTap: () {
                      ref.read(activeCategoryProvider.notifier).state = null;
                      ref.read(searchQueryProvider.notifier).state    = '';
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const MoviesScreen()));
                    },
                  ),
                  const SizedBox(width: 14),
                  _ContentTile(
                    icon:     Icons.video_library_rounded,
                    label:    'Series',
                    subtitle: '$seriesCount shows',
                    colors:   const [Color(0xFF059669), Color(0xFF0891B2)],
                    onTap: () {
                      ref.read(activeCategoryProvider.notifier).state = null;
                      ref.read(searchQueryProvider.notifier).state    = '';
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SeriesScreen()));
                    },
                  ),
                  const SizedBox(width: 14),
                  _ContentTile(
                    icon:     Icons.radio_rounded,
                    label:    'Radios',
                    subtitle: '$radioCount stations',
                    colors:   const [Color(0xFFF59E0B), Color(0xFFEA580C)],
                    onTap: () {
                      ref.read(activeCategoryProvider.notifier).state = null;
                      ref.read(searchQueryProvider.notifier).state    = '';
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const RadiosScreen()));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        _BottomBar(playlist: playlist, playlists: playlists),
      ],
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
class _TopBar extends ConsumerWidget {
  final Playlist?      playlist;
  final List<Playlist> playlists;
  const _TopBar({required this.playlist, required this.playlists});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Logo
          Image.asset(
            'assets/images/logo.png',
            width: 30, height: 30,
            errorBuilder: (_, __, ___) => Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                gradient: kPrimeGradient,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (b) => kPrimeGradient.createShader(b),
            child: const Text('Prime',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                )),
          ),
          const Text(' Player',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w300,
              )),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text('v1.0',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                )),
          ),
          if (playlist != null) ...[
            const SizedBox(width: 14),
            const Icon(Icons.folder_rounded, color: AppColors.textMuted, size: 13),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _showPlaylistPicker(context, ref),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Text(
                      playlist!.name,
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down_rounded,
                      color: AppColors.primaryLight, size: 16),
                ],
              ),
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: () => _showInfoDialog(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFC0392B),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.perm_device_info_rounded, color: Colors.white, size: 13),
                SizedBox(width: 5),
                Text('Device Info',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    )),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlaylistPicker(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _PlaylistPickerDialog(playlists: playlists),
    );
  }

  void _showInfoDialog(BuildContext context, WidgetRef ref) {
    final mac = ref.read(storageServiceProvider).macAddress;
    showDialog(
      context: context,
      builder: (_) => _InfoDialog(playlist: playlist, macAddress: mac),
    );
  }
}

// ── Content tile ──────────────────────────────────────────────────────────────
class _ContentTile extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final String       subtitle;
  final List<Color>  colors;
  final VoidCallback onTap;

  const _ContentTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          // Gradient border outer shell
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors[0].withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.5),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18.5),
            ),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient icon box
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const Spacer(),
                Text(label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(subtitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 13, color: colors[0].withOpacity(0.7)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom toolbar ────────────────────────────────────────────────────────────
class _BottomBar extends ConsumerWidget {
  final Playlist?      playlist;
  final List<Playlist> playlists;
  const _BottomBar({required this.playlist, required this.playlists});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          _ToolBtn(
            icon:  Icons.refresh_rounded,
            label: 'Refresh',
            onTap: () => ref.read(playlistRefreshProvider.notifier).state++,
          ),
          _vDivider(),
          _ToolBtn(
            icon:  Icons.swap_horiz_rounded,
            label: 'Change',
            onTap: () => showDialog(
              context: context,
              builder: (_) => _PlaylistPickerDialog(playlists: playlists),
            ),
          ),
          _vDivider(),
          _ToolBtn(
            icon:  Icons.language_rounded,
            label: 'Language',
            onTap: () => showDialog(
              context: context,
              builder: (_) => const _LanguageDialog(),
            ),
          ),
          _vDivider(),
          _ToolBtn(
            icon:     Icons.add_circle_rounded,
            label:    'Add Playlist',
            gradient: true,
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddPlaylistScreen()));
              ref.read(playlistRefreshProvider.notifier).state++;
            },
          ),
          _vDivider(),
          _ToolBtn(
            icon:  Icons.settings_rounded,
            label: 'Settings',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          _vDivider(),
          _ToolBtn(
            icon:  Icons.help_outline_rounded,
            label: 'About',
            onTap: () => showDialog(
              context: context,
              builder: (_) => _InfoDialog(playlist: playlist),
            ),
          ),
          const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AppStrings.website,
                  style: TextStyle(
                    color: Colors.orange.shade400,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  )),
              Text('© Prime Player 2025',
                  style: TextStyle(
                    color: Colors.orange.shade400.withOpacity(0.65),
                    fontSize: 8,
                  )),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1, height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: AppColors.border,
      );
}

class _ToolBtn extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;
  final bool         gradient;

  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.gradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: gradient
            ? BoxDecoration(
                gradient: kPrimeGradient,
                borderRadius: BorderRadius.circular(6),
              )
            : null,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              color: gradient ? Colors.white : AppColors.textSecondary,
              size: 14),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                color: gradient ? Colors.white : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              )),
        ]),
      ),
    );
  }
}

// ── Playlist picker dialog ────────────────────────────────────────────────────
class _PlaylistPickerDialog extends ConsumerWidget {
  final List<Playlist> playlists;
  const _PlaylistPickerDialog({required this.playlists});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activePlaylistIdProvider);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 340,
        constraints: const BoxConstraints(maxHeight: 480),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              ShaderMask(
                shaderCallback: (b) => kPrimeGradient.createShader(b),
                child: const Icon(Icons.playlist_play_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 8),
              const Text('Select Playlist',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.textMuted, size: 20),
              ),
            ]),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: playlists.map((p) {
                    final isActive = p.id == activeId;
                    return GestureDetector(
                      onTap: () {
                        ref.read(activePlaylistIdProvider.notifier).state = p.id;
                        ref.read(storageServiceProvider).setActivePlaylistId(p.id);
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isActive ? kPrimeGradient : null,
                          color: isActive ? null : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive ? Colors.transparent : AppColors.border,
                          ),
                        ),
                        child: Row(children: [
                          Icon(
                            p.playlistType == PlaylistType.xtream
                                ? Icons.dns_rounded
                                : Icons.playlist_play_rounded,
                            color: isActive ? Colors.white : AppColors.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    style: TextStyle(
                                      color: isActive ? Colors.white : AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    )),
                                Text('${p.channelCount} channels',
                                    style: TextStyle(
                                      color: isActive ? Colors.white70 : AppColors.textMuted,
                                      fontSize: 11,
                                    )),
                              ],
                            ),
                          ),
                          if (isActive)
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 18),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info dialog ───────────────────────────────────────────────────────────────
class _InfoDialog extends StatelessWidget {
  final Playlist? playlist;
  final String    macAddress;
  const _InfoDialog({this.playlist, required this.macAddress});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text('About Prime Player',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.textMuted, size: 20),
              ),
            ]),
            const SizedBox(height: 16),

            // MAC Address banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1040), Color(0xFF0F1E40)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.4)),
              ),
              child: Row(children: [
                const Icon(Icons.router_rounded,
                    color: AppColors.primaryLight, size: 18),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('MAC Address',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 10)),
                  Text(macAddress,
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                      )),
                ]),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: macAddress));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('MAC Address copied!'),
                        duration: Duration(seconds: 2),
                        backgroundColor: AppColors.surface,
                      ),
                    );
                  },
                  child: const Icon(Icons.copy_rounded,
                      color: AppColors.primaryLight, size: 18),
                ),
              ]),
            ),

            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoColumn(title: 'About App', items: [
                    ('App', 'Prime Player'),
                    ('Version', '1.0.0'),
                    ('Developer', 'Prime IPTV'),
                    ('Website', AppStrings.website),
                    ('Support', AppStrings.whatsApp),
                  ]),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _InfoColumn(title: 'Playlist Info', items: [
                    ('Name', playlist?.name ?? '—'),
                    ('Channels', '${playlist?.channelCount ?? 0}'),
                    ('Type', playlist?.playlistType == PlaylistType.xtream
                        ? 'Xtream Codes' : 'M3U URL'),
                    ('Updated', playlist?.lastUpdated != null
                        ? _fmt(playlist!.lastUpdated!) : '—'),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} '
      '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
}

class _InfoColumn extends StatelessWidget {
  final String              title;
  final List<(String, String)> items;
  const _InfoColumn({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: kPrimeGradient,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              )),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(item.$1,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        )),
                  ),
                  Expanded(
                    child: Text(item.$2,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

// ── Language dialog ───────────────────────────────────────────────────────────
class _LanguageDialog extends StatefulWidget {
  const _LanguageDialog();

  @override
  State<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<_LanguageDialog> {
  String _selected = 'English';

  static const _langs = ['English', 'العربية', 'Français', 'Español'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              ShaderMask(
                shaderCallback: (b) => kPrimeGradient.createShader(b),
                child: const Icon(Icons.language_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Text('Language',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.textMuted, size: 20),
              ),
            ]),
            const SizedBox(height: 16),
            ..._langs.map((lang) {
              final isActive = lang == _selected;
              return GestureDetector(
                onTap: () => setState(() => _selected = lang),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isActive ? kPrimeGradient : null,
                    color: isActive ? null : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive ? Colors.transparent : AppColors.border,
                    ),
                  ),
                  child: Row(children: [
                    Text(lang,
                        style: TextStyle(
                          color: isActive ? Colors.white : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                        )),
                    const Spacer(),
                    if (isActive)
                      const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 88, height: 88,
            errorBuilder: (_, __, ___) => Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                gradient: kPrimeGradient,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 50),
            ),
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (b) => kPrimeGradient.createShader(b),
            child: const Text('Prime',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                )),
          ),
          const Text('Player',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 24,
                fontWeight: FontWeight.w300,
              )),
          const SizedBox(height: 6),
          const Text(
            'Add your M3U link or Xtream Codes to start watching',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                gradient: kPrimeGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Add Playlist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
