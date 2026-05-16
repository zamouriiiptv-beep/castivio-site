import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_localizations.dart';
import '../../core/constants.dart';
import '../providers/locale_provider.dart';
import '../providers/playlist_provider.dart';
import '../widgets/content_screen_layout.dart';

class RadiosScreen extends ConsumerStatefulWidget {
  const RadiosScreen({super.key});

  @override
  ConsumerState<RadiosScreen> createState() => _RadiosScreenState();
}

class _RadiosScreenState extends ConsumerState<RadiosScreen> {
  final _searchCtrl = TextEditingController();
  bool  _searching  = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories     = ref.watch(radioCategoriesProvider);
    final activeCategory = ref.watch(activeCategoryProvider) ?? 'All';
    final channels       = ref.watch(filteredRadioChannelsProvider);
    final tr             = AppLocalizations.of(ref.watch(localeProvider));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ContentTopBar(
              section:    tr.radios.toUpperCase(),
              subSection: '${channels.length} ${tr.radioStations}',
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
                    idleIcon:  Icons.radio_rounded,
                    idleLabel: 'Select a station',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
