import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../data/services/m3u_parser.dart';
import '../providers/playlist_provider.dart';
import 'home_screen.dart';

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
  bool _showDiag = false;   // show/hide diagnostic panel
  bool _isXtreamUrl = false; // detected Xtream Codes URL in M3U field

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
    _urlM3u.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    _tab.dispose();
    _nameM3u.dispose(); _urlM3u.dispose();
    _nameXt.dispose(); _hostXt.dispose();
    _userXt.dispose(); _passXt.dispose();
    super.dispose();
  }

  void _onUrlChanged() {
    final creds = M3uParser.extractXtreamCredentials(_urlM3u.text);
    setState(() => _isXtreamUrl = creds != null);
  }

  /// Auto-fill Xtream Codes tab from the M3U URL and switch to it.
  void _switchToXtream() {
    final creds = M3uParser.extractXtreamCredentials(_urlM3u.text);
    if (creds == null) return;
    _hostXt.text = creds['host']!;
    _userXt.text = creds['username']!;
    _passXt.text = creds['password']!;
    if (_nameXt.text.isEmpty && _nameM3u.text.isNotEmpty) {
      _nameXt.text = _nameM3u.text;
    }
    setState(() { _error = null; _showDiag = false; });
    _tab.animateTo(1);
  }

  Future<void> _addM3u() async {
    final url = _urlM3u.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Please enter the M3U URL');
      return;
    }
    setState(() { _loading = true; _error = null; _showDiag = false; });
    try {
      await ref.read(playlistRepositoryProvider).addM3uPlaylist(
        name: _nameM3u.text.trim().isEmpty ? 'My Playlist' : _nameM3u.text.trim(),
        url:  url,
      );
      _goToChannels();
    } catch (e) {
      setState(() {
        _loading  = false;
        _error    = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _addXtream() async {
    if (_hostXt.text.trim().isEmpty ||
        _userXt.text.trim().isEmpty ||
        _passXt.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in all Xtream Codes fields');
      return;
    }
    setState(() { _loading = true; _error = null; _showDiag = false; });
    try {
      await ref.read(playlistRepositoryProvider).addXtreamPlaylist(
        name:     _nameXt.text.trim().isEmpty ? 'My Xtream' : _nameXt.text.trim(),
        host:     _hostXt.text.trim(),
        username: _userXt.text.trim(),
        password: _passXt.text.trim(),
      );
      _goToChannels();
    } catch (e) {
      setState(() {
        _loading = false;
        _error   = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _goToChannels() {
    final playlists = ref.read(playlistRepositoryProvider).getSavedPlaylists();
    if (playlists.isNotEmpty) {
      final last = playlists.last;
      ref.read(activePlaylistIdProvider.notifier).state = last.id;
      ref.read(storageServiceProvider).setActivePlaylistId(last.id);
    }
    ref.read(playlistRefreshProvider.notifier).state++;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
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
          ? const _LoadingView()
          : TabBarView(
              controller: _tab,
              children: [
                _M3uTab(
                  nameCtrl:    _nameM3u,
                  urlCtrl:     _urlM3u,
                  error:       _error,
                  isXtreamUrl: _isXtreamUrl,
                  showDiag:    _showDiag,
                  onAdd:       _addM3u,
                  onSwitchToXtream: _isXtreamUrl ? _switchToXtream : null,
                  onToggleDiag: M3uParser.lastDiagnostics.isNotEmpty
                      ? () => setState(() => _showDiag = !_showDiag)
                      : null,
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

// ─────────────────────────────────────────────────────────────────────────────
class _LoadingView extends StatefulWidget {
  const _LoadingView();

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView> {
  static const _steps = [
    ('Connecting to server…',       Icons.wifi_rounded),
    ('Authenticating…',             Icons.lock_open_rounded),
    ('Loading live channels…',      Icons.live_tv_rounded),
    ('Loading movies…',             Icons.movie_rounded),
    ('Loading series…',             Icons.video_library_rounded),
    ('Saving to device…',           Icons.save_rounded),
    ('Almost done…',                Icons.check_circle_outline_rounded),
  ];

  int    _step  = 0;
  int    _dots  = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      setState(() {
        _dots = (_dots + 1) % 4;
        if (_dots == 0) _step = (_step + 1) % _steps.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (label, icon) = _steps[_step];
    final dotStr = '.' * (_dots + 1);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64, height: 64,
              child: Stack(alignment: Alignment.center, children: [
                const CircularProgressIndicator(
                  strokeWidth: 3, color: AppColors.primary,
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(icon,
                      key: ValueKey(_step),
                      color: AppColors.primary, size: 26),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                '$label$dotStr',
                key: ValueKey('$_step-$_dots'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Large playlists may take up to a minute',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _M3uTab extends StatelessWidget {
  final TextEditingController nameCtrl, urlCtrl;
  final String? error;
  final bool isXtreamUrl;
  final bool showDiag;
  final VoidCallback onAdd;
  final VoidCallback? onSwitchToXtream;
  final VoidCallback? onToggleDiag;

  const _M3uTab({
    required this.nameCtrl,
    required this.urlCtrl,
    required this.error,
    required this.isXtreamUrl,
    required this.showDiag,
    required this.onAdd,
    this.onSwitchToXtream,
    this.onToggleDiag,
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
          _field(urlCtrl, 'M3U URL', 'http://server:port/get.php?username=…',
              Icons.link_rounded, keyboard: TextInputType.url),

          // Xtream Codes detection banner
          if (isXtreamUrl) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.35)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Xtream Codes URL detected.\n'
                    'If M3U fails, try the Xtream Codes tab for better reliability.',
                    style: TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
                ),
              ]),
            ),
          ],

          if (error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(
              message: error!,
              onSwitchToXtream: onSwitchToXtream,
              onToggleDiag: onToggleDiag,
              showDiag: showDiag,
            ),
          ],

          // Diagnostic panel
          if (showDiag && M3uParser.lastDiagnostics.isNotEmpty) ...[
            const SizedBox(height: 8),
            _DiagPanel(diagnostics: M3uParser.lastDiagnostics),
          ],

          const SizedBox(height: 28),
          _PrimaryButton(label: 'Load Playlist', onTap: onAdd),

          if (onSwitchToXtream != null) ...[
            const SizedBox(height: 12),
            _SecondaryButton(
              label: 'Try Xtream Codes Instead',
              icon: Icons.swap_horiz_rounded,
              onTap: onSwitchToXtream!,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
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
            _ErrorBanner(message: error!),
          ],
          const SizedBox(height: 28),
          _PrimaryButton(label: 'Connect', onTap: onAdd),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onSwitchToXtream;
  final VoidCallback? onToggleDiag;
  final bool showDiag;

  const _ErrorBanner({
    required this.message,
    this.onSwitchToXtream,
    this.onToggleDiag,
    this.showDiag = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
          if (onSwitchToXtream != null || onToggleDiag != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              if (onSwitchToXtream != null)
                GestureDetector(
                  onTap: onSwitchToXtream,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: const Text('Try Xtream Codes',
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                ),
              if (onToggleDiag != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onToggleDiag,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      showDiag ? 'Hide Diagnostics' : 'Show Diagnostics',
                      style: const TextStyle(
                        color: Colors.white54, fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ]),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _DiagPanel extends StatelessWidget {
  final List<M3uDiagnostic> diagnostics;
  const _DiagPanel({required this.diagnostics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Network Diagnostics',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              )),
          const SizedBox(height: 8),
          ...diagnostics.asMap().entries.map((e) {
            final i = e.key;
            final d = e.value;
            final ok = d.error == null;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ok
                    ? Colors.green.withOpacity(0.08)
                    : Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ok ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: ok ? Colors.green : Colors.red, size: 14),
                    const SizedBox(width: 6),
                    Text('Attempt ${i + 1}',
                        style: const TextStyle(
                          color: Colors.white70, fontSize: 11,
                          fontWeight: FontWeight.w700,
                        )),
                    if (d.statusCode != null) ...[
                      const SizedBox(width: 8),
                      _badge('HTTP ${d.statusCode}',
                          d.statusCode == 200 ? Colors.green : Colors.orange),
                    ],
                    if (d.bodyBytes > 0) ...[
                      const SizedBox(width: 4),
                      _badge('${d.bodyBytes}B', Colors.blue),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  _diagRow('UA', d.userAgent.split('/').first),
                  if (d.contentLength != null)
                    _diagRow('Content-Length', '${d.contentLength}'),
                  if (d.contentType != null)
                    _diagRow('Content-Type', d.contentType!),
                  if (d.error != null)
                    _diagRow('Error', d.error!, color: Colors.redAccent),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(text,
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
      );

  Widget _diagRow(String key, String value, {Color? color}) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 90,
            child: Text('$key:',
                style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                  color: color ?? Colors.white54,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
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
              blurRadius: 16, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                color: Colors.white, fontSize: 16,
                fontWeight: FontWeight.w800, letterSpacing: 0.5,
              )),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SecondaryButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.surfaceLight,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: AppColors.primaryLight, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                color: AppColors.primaryLight, fontSize: 14,
                fontWeight: FontWeight.w700,
              )),
        ]),
      ),
    );
  }
}
