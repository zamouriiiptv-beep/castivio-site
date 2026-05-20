import 'package:hive/hive.dart';

part 'playlist.g.dart';

enum PlaylistType { m3u, xtream }

@HiveType(typeId: 1)
class Playlist extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) String name;
  @HiveField(2) final String type;         // 'm3u' | 'xtream'

  // M3U fields
  @HiveField(3) final String? m3uUrl;

  // Xtream Codes fields
  @HiveField(4) final String? xtreamHost;
  @HiveField(5) final String? xtreamUsername;
  @HiveField(6) final String? xtreamPassword;

  @HiveField(7) DateTime? lastUpdated;
  @HiveField(8) int channelCount;
  @HiveField(9) DateTime? expiryDate;

  Playlist({
    required this.id,
    required this.name,
    required this.type,
    this.m3uUrl,
    this.xtreamHost,
    this.xtreamUsername,
    this.xtreamPassword,
    this.lastUpdated,
    this.channelCount = 0,
    this.expiryDate,
  });

  PlaylistType get playlistType =>
      type == 'xtream' ? PlaylistType.xtream : PlaylistType.m3u;

  String get displayUrl {
    if (playlistType == PlaylistType.xtream) {
      return xtreamHost ?? '';
    }
    return m3uUrl ?? '';
  }
}
