import 'package:hive/hive.dart';

part 'channel.g.dart';

@HiveType(typeId: 0)
class Channel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String name;
  @HiveField(2) final String streamUrl;
  @HiveField(3) final String? logoUrl;
  @HiveField(4) final String? groupTitle;
  @HiveField(5) final String? tvgId;
  @HiveField(6) final String? tvgName;
  @HiveField(7) final String? language;
  @HiveField(8) final String? country;
  @HiveField(9) bool isFavorite;

  Channel({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.logoUrl,
    this.groupTitle,
    this.tvgId,
    this.tvgName,
    this.language,
    this.country,
    this.isFavorite = false,
  });

  Channel copyWith({bool? isFavorite}) => Channel(
    id:         id,
    name:       name,
    streamUrl:  streamUrl,
    logoUrl:    logoUrl,
    groupTitle: groupTitle,
    tvgId:      tvgId,
    tvgName:    tvgName,
    language:   language,
    country:    country,
    isFavorite: isFavorite ?? this.isFavorite,
  );
}
