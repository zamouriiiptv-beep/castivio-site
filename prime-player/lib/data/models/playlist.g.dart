// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

part of 'playlist.dart';

class PlaylistAdapter extends TypeAdapter<Playlist> {
  @override
  final int typeId = 1;

  @override
  Playlist read(BinaryReader reader) {
    final fields = reader.readMap();
    return Playlist(
      id:               fields[0] as String,
      name:             fields[1] as String,
      type:             fields[2] as String,
      m3uUrl:           fields[3] as String?,
      xtreamHost:       fields[4] as String?,
      xtreamUsername:   fields[5] as String?,
      xtreamPassword:   fields[6] as String?,
      lastUpdated:      fields[7] as DateTime?,
      channelCount:     fields[8] as int? ?? 0,
      expiryDate:       fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Playlist obj) {
    writer.writeMap({
      0: obj.id,
      1: obj.name,
      2: obj.type,
      3: obj.m3uUrl,
      4: obj.xtreamHost,
      5: obj.xtreamUsername,
      6: obj.xtreamPassword,
      7: obj.lastUpdated,
      8: obj.channelCount,
      9: obj.expiryDate,
    });
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
