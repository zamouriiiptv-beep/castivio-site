import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../data/models/channel.dart';
import '../../data/models/playlist.dart';
import '../../data/models/series_info.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import 'player_screen.dart';

class SeriesDetailScreen extends ConsumerStatefulWidget {
  final Channel series;
  const SeriesDetailScreen({super.key, required this.series});

  @override
  ConsumerState<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends ConsumerState<SeriesDetailScreen> {
  SeriesInfo? _info;
  String?     _error;
  bool        _loading = true;
  int         _selectedSeason = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _seriesId =>
      widget.series.id.startsWith('series_')
          ? widget.series.id.substring('series_'.length)
          : widget.series.id;

  Playlist? _activePlaylist() {
    final id = ref.read(activePlaylistIdProvider);
    if (id == null) return null;
    return ref.read(playlistRepositoryProvider)
        .getSavedPlaylists()
        .cast<Playlist?>()
        .firstWhere((p) => p?.id == id, orElse: () => null);
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final playlist = _activePlaylist();
      if (playlist == null || playlist.playlistType != PlaylistType.xtream) {
        throw Exception('Series info is only supported for Xtream playlists');
      }
      final info = await ref.read(playlistRepositoryProvider)
          .getSeriesInfo(playlist, _seriesId);
      if (info == null) throw Exception('Failed to load series info');
      if (!mounted) return;
      setState(() {
        _info = info;
        _selectedSeason = info.seasons.isNotEmpty ? info.seasons.first.number : 1;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _playEpisode(Episode episode) async {
    final playlist = _activePlaylist();
    if (playlist == null) return;
    final url = ref.read(playlistRepositoryProvider)
        .buildEpisodeUrl(playlist, episode);
    final ch = Channel(
      id:        'episode_${episode.id}',
      name:      '${_info?.name ?? widget.series.name} · S${episode.seasonNumber}E${episode.episodeNumber} — ${episode.title}',
      streamUrl: url,
      logoUrl:   episode.cover ?? _info?.cover ?? widget.series.logoUrl,
    );
    ref.read(playerProvider.notifier).openChannel(ch);
    if (!mounted) return;
    Navigator.push(context, PageRouteBuilder(
      pageBuilder:        (_, a, __) => const PlayerScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 200),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Column(children: [
        _topBar(subtitle: 'Loading…'),
        const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.accent))),
      ]);
    }
    if (_error != null) {
      return Column(children: [
        _topBar(subtitle: 'Error'),
        Expanded(child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ]),
        )),
      ]);
    }

    final info     = _info!;
    final episodes = info.episodesForSeason(_selectedSeason);

    return Column(children: [
      _topBar(subtitle: info.seasons.length > 1 ? '${info.seasons.length} seasons' : '${episodes.length} episodes'),
      Expanded(child: Row(children: [
        // ── Left: series details ───────────────────────────────────────────
        SizedBox(
          width: 280,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if ((info.cover ?? widget.series.logoUrl) != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: CachedNetworkImage(
                      imageUrl:    info.cover ?? widget.series.logoUrl!,
                      fit:         BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          Container(color: AppColors.surfaceLight,
                              child: const Icon(Icons.video_library_rounded, color: AppColors.textMuted, size: 48)),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(info.name,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              if (info.genre != null) ...[
                const SizedBox(height: 4),
                Text(info.genre!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
              if (info.rating != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(info.rating!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
              ],
              if (info.plot != null && info.plot!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(info.plot!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
              ],
            ]),
          ),
        ),
        Container(width: 1, color: AppColors.border),

        // ── Right: seasons + episodes ──────────────────────────────────────
        Expanded(child: Column(children: [
          if (info.seasons.length > 1) _seasonTabs(info.seasons),
          Expanded(child: episodes.isEmpty
              ? const Center(child: Text('No episodes', style: TextStyle(color: AppColors.textMuted)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: episodes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (_, i) => _episodeTile(episodes[i]),
                )),
        ])),
      ])),
    ]);
  }

  Widget _topBar({required String subtitle}) => Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_info?.name ?? widget.series.name,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(subtitle,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          )),
        ]),
      );

  Widget _seasonTabs(List<Season> seasons) => Container(
        height: 42,
        color: AppColors.surface,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          itemCount: seasons.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final s = seasons[i];
            final selected = s.number == _selectedSeason;
            return GestureDetector(
              onTap: () => setState(() => _selectedSeason = s.number),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Season ${s.number}',
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            );
          },
        ),
      );

  Widget _episodeTile(Episode e) => InkWell(
        onTap: () => _playEpisode(e),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 110, height: 62,
                child: e.cover != null && e.cover!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: e.cover!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: AppColors.surfaceLight,
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white54)),
                      )
                    : Container(color: AppColors.surfaceLight,
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white54)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${e.episodeNumber}. ${e.title}',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (e.plot != null && e.plot!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(e.plot!,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                if (e.durationSeconds != null && e.durationSeconds! > 0) ...[
                  const SizedBox(height: 4),
                  Text('${(e.durationSeconds! / 60).round()} min',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                ],
              ],
            )),
            const Icon(Icons.play_arrow_rounded, color: AppColors.accent, size: 28),
          ]),
        ),
      );
}
