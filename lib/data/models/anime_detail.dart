class AnimeCharacter {
  final String name;
  final String imageUrl;

  AnimeCharacter({
    required this.name,
    required this.imageUrl,
  });

  factory AnimeCharacter.fromJson(Map<String, dynamic> json) {
    final nameMap = json['name'] as Map<String, dynamic>?;
    final imageMap = json['image'] as Map<String, dynamic>?;
    return AnimeCharacter(
      name: (nameMap?['full'] as String?) ?? 'Unknown',
      imageUrl: (imageMap?['medium'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': {'full': name},
        'image': {'medium': imageUrl},
      };
}

class AnimeStaff {
  final String name;
  final String role;

  AnimeStaff({
    required this.name,
    required this.role,
  });

  factory AnimeStaff.fromJson(Map<String, dynamic> json) {
    final nameMap = json['name'] as Map<String, dynamic>?;
    final occupations = (json['primaryOccupations'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    return AnimeStaff(
      name: (nameMap?['full'] as String?) ?? 'Unknown',
      role: occupations.isNotEmpty ? occupations.join(', ') : 'Staff',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': {'full': name},
        'primaryOccupations': [role],
      };
}

class AnimeDetail {
  final int anilistId;
  final String titleRomaji;
  final String titleEnglish;
  final String titleNative;
  final String description;
  final String coverImage;
  final String bannerImage;
  final List<String> genres;
  final double averageScore;
  final String status;
  final String season;
  final int seasonYear;
  final int? totalEpisodes;
  final String studio;
  final List<AnimeCharacter> characters;
  final List<AnimeStaff> staff;

  AnimeDetail({
    required this.anilistId,
    required this.titleRomaji,
    required this.titleEnglish,
    required this.titleNative,
    required this.description,
    required this.coverImage,
    required this.bannerImage,
    required this.genres,
    required this.averageScore,
    required this.status,
    required this.season,
    required this.seasonYear,
    this.totalEpisodes,
    required this.studio,
    required this.characters,
    required this.staff,
  });

  String get displayTitle =>
      titleEnglish.isNotEmpty ? titleEnglish : titleRomaji;

  factory AnimeDetail.fromJson(Map<String, dynamic> json) {
    final titleMap = json['title'] as Map<String, dynamic>?;
    final coverMap = json['coverImage'] as Map<String, dynamic>?;
    final studioNodes = (json['studios'] as Map<String, dynamic>?)?['nodes']
        as List<dynamic>?;
    final charNodes = (json['characters'] as Map<String, dynamic>?)?['nodes']
        as List<dynamic>?;
    final staffNodes = (json['staff'] as Map<String, dynamic>?)?['nodes']
        as List<dynamic>?;

    String studioName = '';
    if (studioNodes != null && studioNodes.isNotEmpty) {
      studioName = (studioNodes.first as Map<String, dynamic>)['name'] ?? '';
    }

    return AnimeDetail(
      anilistId: (json['id'] as num).toInt(),
      titleRomaji: (titleMap?['romaji'] as String?) ?? '',
      titleEnglish: (titleMap?['english'] as String?) ?? '',
      titleNative: (titleMap?['native'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      coverImage: (coverMap?['extraLarge'] as String?) ??
          (coverMap?['large'] as String?) ??
          '',
      bannerImage: (json['bannerImage'] as String?) ?? '',
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      averageScore: ((json['averageScore'] as num?)?.toDouble()) ?? 0.0,
      status: (json['status'] as String?) ?? 'FINISHED',
      season: (json['season'] as String?) ?? '',
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 0,
      totalEpisodes: (json['episodes'] as num?)?.toInt(),
      studio: studioName,
      characters: charNodes
              ?.map((c) => AnimeCharacter.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      staff: staffNodes
              ?.map((s) => AnimeStaff.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': anilistId,
      'title': {
        'romaji': titleRomaji,
        'english': titleEnglish,
        'native': titleNative,
      },
      'description': description,
      'coverImage': {'extraLarge': coverImage},
      'bannerImage': bannerImage,
      'genres': genres,
      'averageScore': averageScore,
      'status': status,
      'season': season,
      'seasonYear': seasonYear,
      'episodes': totalEpisodes,
      'studios': {
        'nodes': studio.isNotEmpty ? [{'name': studio}] : []
      },
      'characters': {'nodes': characters.map((c) => c.toJson()).toList()},
      'staff': {'nodes': staff.map((s) => s.toJson()).toList()},
    };
  }
}
