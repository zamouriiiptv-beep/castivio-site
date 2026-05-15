import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../data/models/playlist.dart';
import '../providers/playlist_provider.dart';
import '../widgets/content_screen_layout.dart';

class LiveTvScreen extends ConsumerStatefulWidget {
  const LiveTvScreen({super.key});

  @override
  ConsumerState<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends ConsumerState<LiveTvScreen> {
  final _searchCtrl = TextEditingController();
  bool    _searching    = false;
  bool    _lazyLoading  = false;
  String? _lazyError;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _loadIfNeeded() async {
    final id = ref.read(activePlaylistIdProvider);
    if (id == null) return;
    final storage = ref.read(storageServiceProvider);
    if (storage.isTypeLoaded(id, 'live')) return;

    final playlist = ref.read(playlistRepositoryProvider)
        .getSavedPlaylists()
        .cast<Playlist?>()
        .firstWhere((p) => p?.id == id, orElse: () => null);
    if (playlist == null || playlist.playlistType != PlaylistType.xtream) return;

    setState(() { _lazyLoading = true; _lazyError = null; });
    try {
      await ref.read(playlistRepositoryProvider).loadXtreamLive(playlist);
      if (mounted) ref.read(playlistRefreshProvider.notifier).state++;
    } catch (e) {
      if (mounted) setState(() => _lazyError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _lazyLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lazyLoading) return _buildLoading(context);
    if (_lazyError != null) return _buildError(context);

    final categories     = ref.watch(liveCategoriesProvider);
    final activeCategory = ref.watch(activeCategoryProvider) ?? 'All';
    final channels       = ref.watch(filteredLiveChannelsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            ContentTopBar(
              section:    'LIVE TV',
              subSection: '${channels.length} channels',
              onBack:     () => Navigator.pop(context),
            ),
            Expanded(
              child: Row(
                children: [
                  IconSidebar(
                    onBack: () => Navigator.pop(context),
                    onSearch: () {
                      setState(() {
                        _searching = !_searching;
                        if (!_searching) {
                          _searchCtrl.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        }
                      });
                    },
                    isSearching: _searching,
                  ),
                  CategoriesPanel(
                    categories:     categories,
                    activeCategory: activeCategory,
                    onSelect: (cat) {
                      ref.read(activeCategoryProvider.notifier).state =
                          cat == 'All' ? null : cat;
                    },
                  ),
                  Container(width: 1, color: AppColors.border),
                  ChannelsListPanel(
                    channels:    channels,
                    isSearching: _searching,
                    searchCtrl:  _searchCtrl,
                    onSearch: (q) =>
                        ref.read(searchQueryProvider.notifier).state = q,
                  ),
                  Container(width: 1, color: AppColors.border),
                  const VideoPlayerPanel(
                    idleIcon:  Icons.live_tv_rounded,
                    idleLabel: 'Select a channel',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(child: Column(children: [
          ContentTopBar(section: 'LIVE TV', subSection: 'Loading…', onBack: () => Navigator.pop(context)),
          Expanded(child: _SectionLoader(icon: Icons.live_tv_rounded, label: 'Loading live channels…')),
        ])),
      );

  Widget _buildError(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(child: Column(children: [
          ContentTopBar(section: 'LIVE TV', subSection: 'Error', onBack: () => Navigator.pop(context)),
          Expanded(child: _SectionError(error: _lazyError!, onRetry: () => _loadIfNeeded())),
        ])),
      );
}

// ── Shared loading / error widgets ────────────────────────────────────────────

class _SectionLoader extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _SectionLoader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 56, height: 56,
            child: Stack(alignment: Alignment.center, children: [
              const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
              Icon(icon, color: AppColors.primary, size: 24),
            ]),
          ),
          const SizedBox(height: 18),
          Text(label,
              style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('This may take a moment for large servers',
              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 12)),
        ]),
      );
}

class _SectionError extends StatelessWidget {
  final String        error;
  final VoidCallback  onRetry;
  const _SectionError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 14),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error, fontSize: 13)),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  gradient: kPrimeGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Retry',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      );
}
