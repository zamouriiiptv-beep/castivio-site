import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_localizations.dart';
import '../../core/constants.dart';
import '../../data/models/playlist.dart';
import '../providers/locale_provider.dart';
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
      backgroundColor: const Color(0xFF0A0A14),
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

// ── Main layout ───────────────────────────────────────────────────────────────────
class _HomeLayout extends ConsumerStatefulWidget {
  final Playlist?      playlist;
  final List<Playlist> playlists;
  const _HomeLayout({required this.playlist, required this.playlists});

  @override
  ConsumerState<_HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends ConsumerState<_HomeLayout> {
  bool _prefetching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startPrefetchIfNeeded());
  }

  @override
  void didUpdateWidget(_HomeLayout old) {
    super.didUpdateWidget(old);
    if (old.playlist?.id != widget.playlist?.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startPrefetchIfNeeded());
    }
  }

  Future<void> _startPrefetchIfNeeded() async {
    final p = widget.playlist;
    if (p == null || p.playlistType != PlaylistType.xtream) return;
    final storage = ref.read(storageServiceProvider);
    final id = p.id;
    final noneLoaded = !storage.isTypeLoaded(id, 'live') &&
        !storage.isTypeLoaded(id, 'vod') &&
        !storage.isTypeLoaded(id, 'series');
    if (!noneLoaded || _prefetching) return;

    if (!mounted) return;
    setState(() => _prefetching = true);
    final repo = ref.read(playlistRepositoryProvider);
    try {
      await repo.loadXtreamLive(p).catchError((_) {});
      if (!mounted) return;
      await repo.loadXtreamVod(p).catchError((_) {});
      if (!mounted) return;
      await repo.loadXtreamSeries(p).catchError((_) {});
      if (mounted) ref.read(playlistRefreshProvider.notifier).state++;
    } finally {
      if (mounted) setState(() => _prefetching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveCount   = ref.watch(liveCountProvider);
    final movieCount  = ref.watch(movieCountProvider);
    final seriesCount = ref.watch(seriesCountProvider);
    final tr          = AppLocalizations.of(ref.watch(localeProvider));

    final playlist = widget.playlist;
    final playlists = widget.playlists;

    final isXtream = playlist?.playlistType == PlaylistType.xtream;
    final storage  = ref.read(storageServiceProvider);
    final id       = playlist?.id ?? '';

    String liveSub   = isXtream && !storage.isTypeLoaded(id, 'live')
        ? (_prefetching ? tr.loading : tr.tapToLoad) : '$liveCount ${tr.channels}';
    String movieSub  = isXtream && !storage.isTypeLoaded(id, 'vod')
        ? (_prefetching ? tr.loading : tr.tapToLoad) : '$movieCount ${tr.films}';
    String seriesSub = isXtream && !storage.isTypeLoaded(id, 'series')
        ? (_prefetching ? tr.loading : tr.tapToLoad) : '$seriesCount ${tr.shows}';

    return Column(
      children: [
        _TopBar(playlist: playlist, playlists: playlists),
        // ── 2×2 section grid ─────────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _SectionCard(
                        icon:     Icons.live_tv_rounded,
                        label:    tr.liveTV,
                        subtitle: liveSub,
                        color:    const Color(0xFF6C3AED),
                        onTap: () {
                          ref.read(activeCategoryProvider.notifier).state = null;
                          ref.read(searchQueryProvider.notifier).state    = '';
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const LiveTvScreen()));
                        },
                      ),
                      const SizedBox(width: 10),
                      _SectionCard(
                        icon:     Icons.movie_creation_rounded,
                        label:    tr.movies,
                        subtitle: movieSub,
                        color:    const Color(0xFFDB2777),
                        onTap: () {
                          ref.read(activeCategoryProvider.notifier).state = null;
                          ref.read(searchQueryProvider.notifier).state    = '';
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const MoviesScreen()));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    children: [
                      _SectionCard(
                        icon:     Icons.video_library_rounded,
                        label:    tr.series,
                        subtitle: seriesSub,
                        color:    const Color(0xFF059669),
                        onTap: () {
                          ref.read(activeCategoryProvider.notifier).state = null;
                          ref.read(searchQueryProvider.notifier).state    = '';
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const SeriesScreen()));
                        },
                      ),
                      const SizedBox(width: 10),
                      _SectionCard(
                        icon:     Icons.radio_rounded,
                        label:    tr.radios,
                        subtitle: tr.radioStations,
                        color:    const Color(0xFFF59E0B),
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
              ],
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
    final tr = AppLocalizations.of(ref.watch(localeProvider));
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D1A),
        border: Border(bottom: BorderSide(color: Color(0xFF1E1E32))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Logo
          Image.asset(
            'assets/images/logo.png',
            width: 28, height: 28,
            errorBuilder: (_, __, ___) => Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: kPrimeGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 17),
            ),
          ),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (b) => kPrimeGradient.createShader(b),
            child: const Text('Prime',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                )),
          ),
          const Text(' Player',
              style: TextStyle(
                color: Color(0xFFCCCCDD),
                fontSize: 16,
                fontWeight: FontWeight.w300,
              )),
          // Playlist picker
          if (playlist != null) ...[
            const SizedBox(width: 16),
            Container(width: 1, height: 18, color: const Color(0xFF2A2A40)),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => _PlaylistPickerDialog(playlists: playlists),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.folder_rounded,
                    color: Color(0xFF8888AA), size: 13),
                const SizedBox(width: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    playlist!.name,
                    style: const TextStyle(
                      color: Color(0xFFAAAACC),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded,
                    color: Color(0xFF8888AA), size: 16),
              ]),
            ),
          ],
          const Spacer(),
          // Active badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2010),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF1A4020)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text('Active',
                  style: TextStyle(
                    color: Color(0xFF4ADE80),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  )),
            ]),
          ),
          const SizedBox(width: 10),
          // Device info
          GestureDetector(
            onTap: () => _showInfoDialog(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0A0A),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF3A1A1A)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.perm_device_info_rounded,
                    color: Color(0xFFFF6B6B), size: 13),
                const SizedBox(width: 5),
                Text(tr.deviceInfo,
                    style: const TextStyle(
                      color: Color(0xFFFF8888),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    )),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, WidgetRef ref) {
    final storage = ref.read(storageServiceProvider);
    showDialog(
      context: context,
      builder: (_) => _InfoDialog(
        playlist:   playlist,
        macAddress: storage.macAddress,
        deviceKey:  storage.deviceKey,
      ),
    );
  }
}

// ── Section card ───────────────────────────────────────────────────────────────────
class _SectionCard extends StatefulWidget {
  final IconData     icon;
  final String       label;
  final String       subtitle;
  final Color        color;
  final VoidCallback onTap;

  const _SectionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp:   (_) => setState(() => _pressed = false),
        onTapCancel:() => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: _pressed
                ? const Color(0xFF18182A)
                : const Color(0xFF111120),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _pressed
                  ? widget.color.withOpacity(0.5)
                  : const Color(0xFF1E1E32),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container
              Container(
                width: 58, height: 58,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(widget.icon, color: widget.color, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Color(0xFFEEEEFF),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: TextStyle(
                  color: widget.color.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom toolbar ────────────────────────────────────────────────────────────────
class _BottomBar extends ConsumerWidget {
  final Playlist?      playlist;
  final List<Playlist> playlists;
  const _BottomBar({required this.playlist, required this.playlists});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(playlistLoadingProvider);
    final tr = AppLocalizations.of(ref.watch(localeProvider));

    return Container(
      height: 42,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D1A),
        border: Border(top: BorderSide(color: Color(0xFF1E1E32))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          if (isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF7C3AED)),
                ),
                const SizedBox(width: 6),
                Text('${tr.refresh}…',
                    style: const TextStyle(
                      color: Color(0xFF7C3AED), fontSize: 11,
                      fontWeight: FontWeight.w600)),
              ]),
            )
          else
            _ToolBtn(
              icon:  Icons.refresh_rounded,
              label: tr.refresh,
              onTap: () async {
                if (playlist != null) {
                  ref.read(playlistLoadingProvider.notifier).state = true;
                  try {
                    await ref.read(playlistRepositoryProvider).refreshPlaylist(playlist!);
                  } catch (_) {}
                  ref.read(playlistLoadingProvider.notifier).state = false;
                }
                ref.read(playlistRefreshProvider.notifier).state++;
              },
            ),
          _vDivider(),
          _ToolBtn(
            icon:  Icons.swap_horiz_rounded,
            label: tr.change,
            onTap: () => showDialog(
              context: context,
              builder: (_) => _PlaylistPickerDialog(playlists: playlists),
            ),
          ),
          _vDivider(),
          _ToolBtn(
            icon:  Icons.language_rounded,
            label: tr.language,
            onTap: () => showDialog(
              context: context,
              builder: (_) => const _LanguageDialog(),
            ),
          ),
          _vDivider(),
          _ToolBtn(
            icon:     Icons.add_circle_rounded,
            label:    tr.addPlaylist,
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
            label: tr.settings,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          _vDivider(),
          _ToolBtn(
            icon:  Icons.help_outline_rounded,
            label: tr.about,
            onTap: () {
              final storage = ref.read(storageServiceProvider);
              showDialog(
                context: context,
                builder: (_) => _InfoDialog(
                  playlist:   playlist,
                  macAddress: storage.macAddress,
                  deviceKey:  storage.deviceKey,
                ),
              );
            },
          ),
          const Spacer(),
          Text(AppStrings.website,
              style: TextStyle(
                color: Colors.orange.shade600.withOpacity(0.6),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1, height: 18,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        color: const Color(0xFF1E1E32),
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
              color: gradient ? Colors.white : const Color(0xFF8888AA),
              size: 14),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                color: gradient ? Colors.white : const Color(0xFF8888AA),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              )),
        ]),
      ),
    );
  }
}

// ── Playlist picker dialog ────────────────────────────────────────────────────────────────
class _PlaylistPickerDialog extends ConsumerWidget {
  final List<Playlist> playlists;
  const _PlaylistPickerDialog({required this.playlists});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activePlaylistIdProvider);

    return Dialog(
      backgroundColor: const Color(0xFF111120),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                    color: Color(0xFFEEEEFF),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded,
                    color: Color(0xFF8888AA), size: 20),
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
                          color: isActive ? null : const Color(0xFF18182A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive
                                ? Colors.transparent
                                : const Color(0xFF252538),
                          ),
                        ),
                        child: Row(children: [
                          Icon(
                            p.playlistType == PlaylistType.xtream
                                ? Icons.dns_rounded
                                : Icons.playlist_play_rounded,
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF8888AA),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.white
                                          : const Color(0xFFEEEEFF),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    )),
                                Text('${p.channelCount} channels',
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.white70
                                          : const Color(0xFF8888AA),
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

// ── Info dialog ───────────────────────────────────────────────────────────────────
class _InfoDialog extends StatelessWidget {
  final Playlist? playlist;
  final String    macAddress;
  final String    deviceKey;
  const _InfoDialog({this.playlist, required this.macAddress, required this.deviceKey});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111120),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF7C3AED), size: 20),
              const SizedBox(width: 8),
              const Text('About Prime Player',
                  style: TextStyle(
                    color: Color(0xFFEEEEFF),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded,
                    color: Color(0xFF8888AA), size: 20),
              ),
            ]),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1A30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E3050)),
              ),
              child: Row(children: [
                const Icon(Icons.router_rounded,
                    color: Color(0xFF7C3AED), size: 18),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('MAC Address',
                      style: TextStyle(color: Color(0xFF8888AA), fontSize: 10)),
                  Text(macAddress,
                      style: const TextStyle(
                        color: Color(0xFFAABBFF),
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
                        backgroundColor: Color(0xFF111120),
                      ),
                    );
                  },
                  child: const Icon(Icons.copy_rounded,
                      color: Color(0xFF7C3AED), size: 18),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF18182A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF252538)),
              ),
              child: Row(children: [
                const Icon(Icons.vpn_key_rounded,
                    color: Color(0xFF8888AA), size: 16),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Device Key',
                      style: TextStyle(color: Color(0xFF8888AA), fontSize: 10)),
                  Text(deviceKey,
                      style: const TextStyle(
                        color: Color(0xFFEEEEFF),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      )),
                ]),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: deviceKey));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Device Key copied!'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Color(0xFF111120),
                      ),
                    );
                  },
                  child: const Icon(Icons.copy_rounded,
                      color: Color(0xFF8888AA), size: 16),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('primeiptvplus.com'),
                    duration: Duration(seconds: 3),
                    backgroundColor: Color(0xFF111120),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: kPrimeGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.open_in_browser_rounded,
                        color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('primeiptvplus.com',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),
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
  final String                 title;
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
                          color: Color(0xFF8888AA),
                          fontSize: 11,
                        )),
                  ),
                  Expanded(
                    child: Text(item.$2,
                        style: const TextStyle(
                          color: Color(0xFFEEEEFF),
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

// ── Language dialog ───────────────────────────────────────────────────────────────────
class _LanguageDialog extends ConsumerWidget {
  const _LanguageDialog();

  static const _languages = <(String, String)>[
    ('en', 'English'),
    ('ar', 'Arabic (العربية)'),
    ('fr', 'French (Français)'),
    ('es', 'Spanish (Español)'),
    ('de', 'German (Deutsch)'),
    ('tr', 'Turkish (Türkçe)'),
    ('it', 'Italian (Italiano)'),
    ('nl', 'Dutch (Nederlands)'),
    ('pt', 'Portuguese (Português)'),
    ('ru', 'Russian (Русский)'),
    ('zh', 'Chinese (中文)'),
    ('ja', 'Japanese (日本語)'),
    ('ko', 'Korean (한국어)'),
    ('fa', 'Persian (فارسی)'),
    ('pl', 'Polish (Polski)'),
    ('ro', 'Romanian (Română)'),
    ('el', 'Greek (Ελληνικά)'),
    ('uk', 'Ukrainian (Українська)'),
    ('sv', 'Swedish (Svenska)'),
    ('no', 'Norwegian (Norsk)'),
    ('da', 'Danish (Dansk)'),
    ('fi', 'Finnish (Suomi)'),
    ('cs', 'Czech (Čeština)'),
    ('hu', 'Hungarian (Magyar)'),
    ('hr', 'Croatian (Hrvatski)'),
    ('bg', 'Bulgarian (Български)'),
    ('sr', 'Serbian (Srpski)'),
    ('ms', 'Malay (Bahasa Melayu)'),
    ('id', 'Indonesian (Bahasa Indonesia)'),
    ('vi', 'Vietnamese (Tiếng Việt)'),
    ('hi', 'Hindi (हिन्दी)'),
    ('he', 'Hebrew (עברית)'),
    ('ur', 'Urdu (اردو)'),
    ('th', 'Thai (ภาษาไทย)'),
    ('sk', 'Slovak (Slovenčina)'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCode = ref.watch(localeProvider);
    final tr = AppLocalizations.of(currentCode);

    return Dialog(
      backgroundColor: const Color(0xFF111120),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxHeight: 520),
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
              Text(tr.language,
                  style: const TextStyle(
                    color: Color(0xFFEEEEFF),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded,
                    color: Color(0xFF8888AA), size: 20),
              ),
            ]),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _languages.map((entry) {
                    final code     = entry.$1;
                    final label    = entry.$2;
                    final isActive = code == currentCode;
                    return GestureDetector(
                      onTap: () {
                        ref.read(localeProvider.notifier).setLocale(code);
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isActive ? kPrimeGradient : null,
                          color: isActive ? null : const Color(0xFF18182A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive
                                ? Colors.transparent
                                : const Color(0xFF252538),
                          ),
                        ),
                        child: Row(children: [
                          Text(label,
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : const Color(0xFFEEEEFF),
                                fontSize: 13,
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

// ── Empty state ───────────────────────────────────────────────────────────────────
class _EmptyState extends ConsumerWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage   = ref.read(storageServiceProvider);
    final mac       = storage.macAddress;
    final deviceKey = storage.deviceKey;

    return Row(
      children: [
        Expanded(
          child: Container(
            color: const Color(0xFF0A0A14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 80, height: 80,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      gradient: kPrimeGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 46),
                  ),
                ),
                const SizedBox(height: 14),
                ShaderMask(
                  shaderCallback: (b) => kPrimeGradient.createShader(b),
                  child: const Text('Prime Player',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      )),
                ),
                const SizedBox(height: 6),
                const Text(
                  'IPTV · Movies · Series · Radio',
                  style: TextStyle(color: Color(0xFF8888AA), fontSize: 12),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    decoration: BoxDecoration(
                      gradient: kPrimeGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Add Playlist',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Add M3U URL or Xtream Codes to start watching',
                  style: TextStyle(color: Color(0xFF8888AA), fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        Container(width: 1, color: const Color(0xFF1E1E32)),
        Container(
          width: 340,
          color: const Color(0xFF0D0D1A),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    gradient: kPrimeGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.devices_rounded,
                      color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                const Text('Device Info',
                    style: TextStyle(
                      color: Color(0xFFEEEEFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    )),
              ]),
              const SizedBox(height: 6),
              const Text(
                'Use these details on our website\nto add your playlist',
                style: TextStyle(
                    color: Color(0xFF8888AA), fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 20),
              _DeviceInfoBox(
                label:  'MAC Address',
                value:  mac,
                icon:   Icons.router_rounded,
                color:  const Color(0xFF7C3AED),
                onCopy: () => _copy(context, mac, 'MAC Address'),
              ),
              const SizedBox(height: 10),
              _DeviceInfoBox(
                label:  'Device Key',
                value:  deviceKey,
                icon:   Icons.vpn_key_rounded,
                color:  const Color(0xFFF59E0B),
                onCopy: () => _copy(context, deviceKey, 'Device Key'),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _copy(context, 'primeiptvplus.com', ''),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: kPrimeGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.open_in_browser_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text('primeiptvplus.com',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Step(number: '1', text: 'Visit primeiptvplus.com'),
              _Step(number: '2', text: 'Enter your MAC Address & Device Key'),
              _Step(number: '3', text: 'Add your playlist from the portal'),
              _Step(number: '4', text: 'Tap "Add Playlist" and enjoy!'),
            ],
          ),
        ),
      ],
    );
  }

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    if (label.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$label copied!'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF111120),
      ));
    }
  }
}

class _DeviceInfoBox extends StatelessWidget {
  final String     label;
  final String     value;
  final IconData   icon;
  final Color      color;
  final VoidCallback onCopy;
  const _DeviceInfoBox({
    required this.label, required this.value,
    required this.icon,  required this.color, required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF18182A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF8888AA), fontSize: 10)),
            Text(value,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontFamily: 'monospace',
                )),
          ]),
        ),
        GestureDetector(
          onTap: onCopy,
          child: Icon(Icons.copy_rounded, color: color, size: 16),
        ),
      ]),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(
          width: 20, height: 20,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                color: Color(0xFF8888AA), fontSize: 12)),
      ]),
    );
  }
}
