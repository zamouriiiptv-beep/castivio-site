import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../providers/playlist_provider.dart';
import 'channel_list_screen.dart';

class AddPlaylistScreen extends ConsumerStatefulWidget {
  const AddPlaylistScreen({super.key});

  @override
  ConsumerState<AddPlaylistScreen> createState() => _AddPlaylistScreenState();
}

class _AddPlaylistScreenState extends ConsumerState<AddPlaylistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _loading = false;
  String? _error;

  // M3U
  final _nameM3u = TextEditingController();
  final _urlM3u  = TextEditingController();

  // Xtream
  final _nameXt   = TextEditingController();
  final _hostXt   = TextEditingController();
  final _userXt   = TextEditingController();
  final _passXt   = TextEditingController();
  bool  _passVisible = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _nameM3u.dispose(); _urlM3u.dispose();
    _nameXt.dispose(); _hostXt.dispose();
    _userXt.dispose(); _passXt.dispose();
    super.dispose();
  }

  Future<void> _addM3u() async {
    if (_urlM3u.text.trim().isEmpty) {
      setState(() => _error = 'Please enter the M3U URL');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(playlistRepositoryProvider).addM3uPlaylist(
        name: _nameM3u.text.trim().isEmpty ? 'My Playlist' : _nameM3u.text.trim(),
        url:  _urlM3u.text.trim(),
      );
      _goToChannels();
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _addXtream() async {
    if (_hostXt.text.trim().isEmpty ||
        _userXt.text.trim().isEmpty ||
        _passXt.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in all Xtream Codes fields');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(playlistRepositoryProvider).addXtreamPlaylist(
        name:     _nameXt.text.trim().isEmpty ? 'My Xtream' : _nameXt.text.trim(),
        host:     _hostXt.text.trim(),
        username: _userXt.text.trim(),
        password: _passXt.text.trim(),
      );
      _goToChannels();
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _goToChannels() {
    final playlists = ref.read(playlistRepositoryProvider).getSavedPlaylists();
    if (playlists.isNotEmpty) {
      final last = playlists.last;
      ref.read(activePlaylistIdProvider.notifier).state = last.id;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ChannelListScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Add Playlist'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: 'M3U URL'),
            Tab(text: 'Xtream Codes'),
          ],
        ),
      ),
      body: _loading
          ? _LoadingView()
          : TabBarView(
              controller: _tab,
              children: [
                _M3uTab(
                  nameCtrl: _nameM3u,
                  urlCtrl:  _urlM3u,
                  error:    _error,
                  onAdd:    _addM3u,
                ),
                _XtreamTab(
                  nameCtrl:    _nameXt,
                  hostCtrl:    _hostXt,
                  userCtrl:    _userXt,
                  passCtrl:    _passXt,
                  passVisible: _passVisible,
                  onTogglePass: () => setState(() => _passVisible = !_passVisible),
                  error:       _error,
                  onAdd:       _addXtream,
                ),
              ],
            ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 52, height: 52,
            child: CircularProgressIndicator(
              strokeWidth: 3, color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Loading channels…',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Parsing your playlist in the background',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7), fontSize: 13)),
        ],
      ),
    );
  }
}

class _M3uTab extends StatelessWidget {
  final TextEditingController nameCtrl, urlCtrl;
  final String? error;
  final VoidCallback onAdd;

  const _M3uTab({
    required this.nameCtrl,
    required this.urlCtrl,
    required this.error,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _field(nameCtrl, 'Playlist Name', 'My Playlist', Icons.label_outline),
          const SizedBox(height: 16),
          _field(urlCtrl, 'M3U URL', 'http://example.com/list.m3u',
              Icons.link_rounded, keyboard: TextInputType.url),
          if (error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(error!),
          ],
          const SizedBox(height: 28),
          _PrimaryButton(label: 'Load Playlist', onTap: onAdd),
        ],
      ),
    );
  }
}

class _XtreamTab extends StatelessWidget {
  final TextEditingController nameCtrl, hostCtrl, userCtrl, passCtrl;
  final bool passVisible;
  final VoidCallback onTogglePass;
  final String? error;
  final VoidCallback onAdd;

  const _XtreamTab({
    required this.nameCtrl, required this.hostCtrl,
    required this.userCtrl, required this.passCtrl,
    required this.passVisible, required this.onTogglePass,
    required this.error, required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _field(nameCtrl, 'Playlist Name', 'My Xtream', Icons.label_outline),
          const SizedBox(height: 16),
          _field(hostCtrl, 'Server URL', 'http://server.com:8080',
              Icons.dns_rounded, keyboard: TextInputType.url),
          const SizedBox(height: 16),
          _field(userCtrl, 'Username', 'username', Icons.person_outline_rounded),
          const SizedBox(height: 16),
          TextField(
            controller: passCtrl,
            obscureText: !passVisible,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded,
                  color: AppColors.textSecondary),
              suffixIcon: IconButton(
                icon: Icon(
                  passVisible
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppColors.textSecondary,
                ),
                onPressed: onTogglePass,
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(error!),
          ],
          const SizedBox(height: 28),
          _PrimaryButton(label: 'Connect', onTap: onAdd),
        ],
      ),
    );
  }
}

Widget _field(
  TextEditingController ctrl,
  String label,
  String hint,
  IconData icon, {
  TextInputType keyboard = TextInputType.text,
}) {
  return TextField(
    controller: ctrl,
    keyboardType: keyboard,
    style: const TextStyle(color: AppColors.textPrimary),
    decoration: InputDecoration(
      labelText: label,
      hintText:  hint,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                  color: AppColors.error, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
