import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'catalog_service.dart';
import 'anilist_service.dart';
import 'local_db.dart';
import 'models/catalog_entry.dart';
import 'models/anime_detail.dart';

final catalogServiceProvider = Provider<CatalogService>((ref) {
  return CatalogService();
});

final aniListServiceProvider = Provider<AniListService>((ref) {
  return AniListService();
});

final catalogProvider = FutureProvider<List<CatalogItem>>((ref) async {
  final service = ref.watch(catalogServiceProvider);
  return await service.fetchCatalog();
});

final animeBatchProvider =
    FutureProvider<Map<int, AnimeDetail>>((ref) async {
  final catalog = await ref.watch(catalogProvider.future);
  final ids = catalog.map((e) => e.anilistId).toList();
  final service = ref.watch(aniListServiceProvider);
  return await service.fetchAnimeBatch(ids);
});

final watchHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await LocalDb.instance.getWatchHistory();
});

final bookmarksProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await LocalDb.instance.getBookmarks();
});

final downloadsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await LocalDb.instance.getDownloads();
});
