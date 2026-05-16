class Season {
  final int     number;
  final String  name;
  final String? cover;
  final String? overview;

  const Season({
    required this.number,
    required this.name,
    this.cover,
    this.overview,
  });
}

class Episode {
  final String  id;
  final int     seasonNumber;
  final int     episodeNumber;
  final String  title;
  final String  containerExtension;
  final String? plot;
  final String? cover;
  final int?    durationSeconds;

  const Episode({
    required this.id,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    required this.containerExtension,
    this.plot,
    this.cover,
    this.durationSeconds,
  });

  String streamUrl({
    required String host,
    required String username,
    required String password,
  }) => '$host/series/$username/$password/$id.$containerExtension';
}

class SeriesInfo {
  final String         seriesId;
  final String         name;
  final String?        cover;
  final String?        plot;
  final String?        cast;
  final String?        director;
  final String?        genre;
  final String?        releaseDate;
  final String?        rating;
  final List<Season>   seasons;
  final List<Episode>  episodes;

  const SeriesInfo({
    required this.seriesId,
    required this.name,
    this.cover,
    this.plot,
    this.cast,
    this.director,
    this.genre,
    this.releaseDate,
    this.rating,
    required this.seasons,
    required this.episodes,
  });

  List<Episode> episodesForSeason(int seasonNumber) =>
      episodes.where((e) => e.seasonNumber == seasonNumber).toList()
        ..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
}
