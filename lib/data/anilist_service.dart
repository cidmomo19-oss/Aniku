import 'dart:convert';
import 'package:dio/dio.dart';
import 'local_db.dart';
import 'models/anime_detail.dart';

class AniListService {
  final Dio _dio;
  static const String endpoint = 'https://graphql.anilist.co';

  AniListService({Dio? dio}) : _dio = dio ?? Dio();

  static const String _batchQuery = r'''
query ($ids: [Int]) {
  Page(perPage: 50) {
    media(id_in: $ids, type: ANIME) {
      id
      title { romaji english native }
      description(asHtml: false)
      coverImage { large extraLarge color }
      bannerImage
      genres
      averageScore
      status
      season
      seasonYear
      episodes
      studios(isMain: true) { nodes { name } }
      characters(sort: ROLE, perPage: 10) {
        nodes { name { full } image { medium } }
      }
      staff(sort: RELEVANCE, perPage: 6) {
        nodes { name { full } primaryOccupations }
      }
    }
  }
}
''';

  Future<Map<int, AnimeDetail>> fetchAnimeBatch(List<int> anilistIds) async {
    final result = <int, AnimeDetail>{};
    if (anilistIds.isEmpty) return result;

    // First try fetching from online API
    try {
      final response = await _dio.post(
        endpoint,
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: jsonEncode({
          'query': _batchQuery,
          'variables': {'ids': anilistIds},
        }),
      );

      if (response.statusCode == 200 && response.data != null) {
        final dataMap = response.data is String
            ? jsonDecode(response.data as String)
            : response.data;
        final mediaList =
            (dataMap['data']?['Page']?['media'] as List<dynamic>?) ?? [];

        for (final media in mediaList) {
          final detail = AnimeDetail.fromJson(media as Map<String, dynamic>);
          result[detail.anilistId] = detail;
          // Save to local sqflite cache
          await LocalDb.instance.saveAniListCache(
            detail.anilistId,
            jsonEncode(detail.toJson()),
          );
        }
      }
    } catch (_) {
      // Ignore online error, fallback to cache
    }

    // Fill missing IDs from local sqflite cache
    for (final id in anilistIds) {
      if (!result.containsKey(id)) {
        final cachedJson = await LocalDb.instance.getAniListCache(id);
        if (cachedJson != null) {
          try {
            final Map<String, dynamic> decoded = jsonDecode(cachedJson);
            result[id] = AnimeDetail.fromJson(decoded);
          } catch (_) {}
        }
      }
    }

    return result;
  }
}
