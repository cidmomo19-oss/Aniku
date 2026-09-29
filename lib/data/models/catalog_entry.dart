class CatalogEpisode {
  final int episodeNumber;
  final String videoType; // 'youtube' or 'direct'
  final String? youtubeId;
  final String? videoUrl;
  final String sourceChannel;

  CatalogEpisode({
    required this.episodeNumber,
    required this.videoType,
    this.youtubeId,
    this.videoUrl,
    required this.sourceChannel,
  });

  factory CatalogEpisode.fromJson(Map<String, dynamic> json) {
    return CatalogEpisode(
      episodeNumber: (json['episode_number'] as num).toInt(),
      videoType: json['video_type'] as String,
      youtubeId: json['youtube_id'] as String?,
      videoUrl: json['video_url'] as String?,
      sourceChannel: (json['source_channel'] as String?) ?? 'Official',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'episode_number': episodeNumber,
      'video_type': videoType,
      'youtube_id': youtubeId,
      'video_url': videoUrl,
      'source_channel': sourceChannel,
    };
  }
}

class CatalogItem {
  final int id;
  final int anilistId;
  final String addedDate;
  final List<CatalogEpisode> episodes;

  CatalogItem({
    required this.id,
    required this.anilistId,
    required this.addedDate,
    required this.episodes,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    final episodesList = (json['episodes'] as List<dynamic>?)
            ?.map((e) => CatalogEpisode.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return CatalogItem(
      id: (json['id'] as num).toInt(),
      anilistId: (json['anilist_id'] as num).toInt(),
      addedDate: (json['added_date'] as String?) ?? '',
      episodes: episodesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'anilist_id': anilistId,
      'added_date': addedDate,
      'episodes': episodes.map((e) => e.toJson()).toList(),
    };
  }
}
