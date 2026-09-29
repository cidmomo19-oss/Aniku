import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/providers.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/shimmer_box.dart';
import '../detail/detail_screen.dart';
import '../player/player_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(catalogProvider);
    final animeBatchAsync = ref.watch(animeBatchProvider);
    final historyAsync = ref.watch(watchHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'AnikuPlay',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded,
                color: AppColors.textPrimary),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon:
                const Icon(Icons.info_outline_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pushNamed(context, '/about'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accentStart,
        backgroundColor: AppColors.surface1,
        onRefresh: () async {
          ref.invalidate(catalogProvider);
          ref.invalidate(animeBatchProvider);
          ref.invalidate(watchHistoryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Continue Watching Section
            historyAsync.when(
              data: (historyList) {
                if (historyList.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lanjutkan Menonton',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 130,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: historyList.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final item = historyList[index];
                          final animeId = item['anime_id'] as int;
                          final epNum = item['episode_number'] as int;
                          final posMs = (item['position_ms'] as int?) ?? 0;
                          final durMs = (item['duration_ms'] as int?) ?? 1;
                          final progress = (posMs / (durMs <= 0 ? 1 : durMs))
                              .clamp(0.0, 1.0);

                          final detailMap =
                              ref.watch(animeBatchProvider).value ?? {};
                          final detail = detailMap[animeId];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlayerScreen(
                                    animeId: animeId,
                                    episodeNumber: epNum,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 220,
                              decoration: BoxDecoration(
                                color: AppColors.surface1,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                children: [
                                  if (detail != null &&
                                      detail.bannerImage.isNotEmpty)
                                    CachedNetworkImage(
                                      imageUrl: detail.bannerImage,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  else if (detail != null &&
                                      detail.coverImage.isNotEmpty)
                                    CachedNetworkImage(
                                      imageUrl: detail.coverImage,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.85),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 12,
                                    left: 12,
                                    right: 12,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          detail?.displayTitle ?? 'Anime #$animeId',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Episode $epNum',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            minHeight: 4,
                                            backgroundColor: Colors.white24,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                    Color>(
                                              AppColors.accentStart,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Center(
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black45,
                                      radius: 20,
                                      child: Icon(
                                        Icons.play_arrow_rounded,
                                        color: AppColors.textPrimary,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Catalog Section Header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Katalog Anime',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Catalog Grid Body
            catalogAsync.when(
              data: (catalogItems) {
                return animeBatchAsync.when(
                  data: (batchMap) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: catalogItems.length,
                      itemBuilder: (context, index) {
                        final item = catalogItems[index];
                        final detail = batchMap[item.anilistId];

                        if (detail == null) {
                          return const ShimmerBox(
                            width: double.infinity,
                            height: double.infinity,
                            borderRadius: 16,
                          );
                        }

                        return AnimeCard(
                          detail: detail,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(
                                  animeId: item.anilistId,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                  loading: () => _buildShimmerGrid(),
                  error: (_, __) => _buildShimmerGrid(),
                );
              },
              loading: () => _buildShimmerGrid(),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'Gagal memuat katalog: $err',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => const ShimmerBox(
        width: double.infinity,
        height: double.infinity,
        borderRadius: 16,
      ),
    );
  }
}
