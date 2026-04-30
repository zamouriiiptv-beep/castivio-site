// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

part of 'channel.dart';

class ChannelAdapter extends TypeAdapter<Channel> {
  @override
  final int typeId = 0;

  @override
  Channel read(BinaryReader reader) {
    final fields = reader.readMap();
    return Channel(
      id:         fields[0] as String,
      name:       fields[1] as String,
      streamUrl:  fields[2] as String,
      logoUrl:    fields[3] as String?,
      groupTitle: fields[4] as String?,
      tvgId:      fields[5] as String?,
      tvgName:    fields[6] as String?,
      language:   fields[7] as String?,
      country:    fields[8] as String?,
      isFavorite: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Channel obj) {
    writer.writeMap({
      0: obj.id,
      1: obj.name,
      2: obj.streamUrl,
      3: obj.logoUrl,
      4: obj.groupTitle,
      5: obj.tvgId,
      6: obj.tvgName,
      7: obj.language,
      8: obj.country,
      9: obj.isFavorite,
    });
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
