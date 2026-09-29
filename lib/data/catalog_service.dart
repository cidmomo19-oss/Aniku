import 'package:dio/dio.dart';
import 'models/catalog_entry.dart';

class CatalogService {
  final Dio _dio;
  String? catalogGistUrl;

  CatalogService({Dio? dio, this.catalogGistUrl}) : _dio = dio ?? Dio();

  static List<CatalogItem> get fallbackCatalog => [
        CatalogItem(
          id: 1,
          anilist_id: 21519, // Kimi no Na wa
          addedDate: '2026-09-20',
          episodes: [
            CatalogEpisode(
              episodeNumber: 1,
              videoType: 'youtube',
              youtubeId: 'sENM2wA_FTg',
              sourceChannel: 'Toho Animation',
            ),
            CatalogEpisode(
              episodeNumber: 2,
              videoType: 'direct',
              videoUrl:
                  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
              sourceChannel: 'Video Uji (Big Buck Bunny)',
            ),
          ],
        ),
        CatalogItem(
          id: 2,
          anilist_id: 20, // Naruto
          addedDate: '2026-09-21',
          episodes: [
            CatalogEpisode(
              episodeNumber: 1,
              videoType: 'youtube',
              youtubeId: '-G9BqkgZXRA',
              sourceChannel: 'Crunchyroll Collection',
            ),
            CatalogEpisode(
              episodeNumber: 2,
              videoType: 'direct',
              videoUrl:
                  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
              sourceChannel: 'Video Uji (Elephants Dream)',
            ),
          ],
        ),
        CatalogItem(
          id: 3,
          anilist_id: 1, // Cowboy Bebop
          addedDate: '2026-09-22',
          episodes: [
            CatalogEpisode(
              episodeNumber: 1,
              videoType: 'youtube',
              youtubeId: 'gY5nQ73lCwQ',
              sourceChannel: 'Crunchyroll Dubs',
            ),
            CatalogEpisode(
              episodeNumber: 2,
              videoType: 'direct',
              videoUrl:
                  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
              sourceChannel: 'Video Uji (For Bigger Blazes)',
            ),
          ],
        ),
        CatalogItem(
          id: 4,
          anilist_id: 1535, // Death Note
          addedDate: '2026-09-23',
          episodes: [
            CatalogEpisode(
              episodeNumber: 1,
              videoType: 'youtube',
              youtubeId: 'NlJZ-YgAt-c',
              sourceChannel: 'Viz Media',
            ),
            CatalogEpisode(
              episodeNumber: 2,
              videoType: 'direct',
              videoUrl:
                  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
              sourceChannel: 'Video Uji (Tears of Steel)',
            ),
          ],
        ),
      ];

  Future<List<CatalogItem>> fetchCatalog() async {
    if (catalogGistUrl == null || catalogGistUrl!.trim().isEmpty) {
      return fallbackCatalog;
    }

    try {
      final response = await _dio.get(catalogGistUrl!);
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data = response.data is Map<String, dynamic>
            ? response.data
            : Map<String, dynamic>.from(response.data);
        final animeList = (data['anime'] as List<dynamic>?)
                ?.map((e) => CatalogItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        if (animeList.isNotEmpty) {
          return animeList;
        }
      }
    } catch (_) {
      // Return fallback catalog on network or parsing error
    }

    return fallbackCatalog;
  }
}
