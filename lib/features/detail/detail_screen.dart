import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/providers.dart';
import '../../data/local_db.dart';
import '../../data/models/anime_detail.dart';
import '../../data/models/catalog_entry.dart';
import '../../widgets/shimmer_box.dart';
import '../player/player_screen.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final int animeId; // AniList ID

  const DetailScreen({super.key, required this.animeId});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    final status = await LocalDb.instance.isBookmarked(widget.animeId);
    if (mounted) {
      setState(() {
        _isBookmarked = status;
      });
    }
  }

  Future<void> _toggleBookmark(AnimeDetail detail) async {
    await LocalDb.instance.toggleBookmark(
      widget.animeId,
      jsonEncode(detail.toJson()),
    );
    await _checkBookmarkStatus();
    ref.invalidate(bookmarksProvider);
  }

  @override
  Widget build(BuildContext context) {
    final batchAsync = ref.watch(animeBatchProvider);
    final catalogAsync = ref.watch(catalogProvider);

    return Scaffold(
      body: batchAsync.when(
        data: (batchMap) {
          final detail = batchMap[widget.animeId];
          if (detail == null) {
            return const Center(
              child: Text(
                'Data anime tidak ditemukan.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          final catalogItem = catalogAsync.value?.firstWhere(
            (item) => item.anilistId == widget.animeId,
            orElse: () => CatalogItem(
              id: widget.animeId,
              anilist_id: widget.animeId,
              addedDate: '',
              episodes: [],
            ),
          );

          return CustomScrollView(
            slivers: [
              // Header SliverAppBar with banner and back button
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (detail.bannerImage.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: detail.bannerImage,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.surface1),
                        )
                      else if (detail.coverImage.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: detail.coverImage,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.surface1),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              AppColors.bgBase.withOpacity(0.95),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: _isBookmarked
                          ? AppColors.accentStart
                          : AppColors.textPrimary,
                      size: 28,
                    ),
                    onPressed: () => _toggleBookmark(detail),
                  ),
                ],
              ),

              // Content List
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      // Poster + Main Info Header
                      Row(
                        crossAxisAlignment: CrossAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: detail.coverImage,
                              width: 110,
                              height: 160,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const ShimmerBox(
                                width: 110,
                                height: 160,
                                borderRadius: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAlignment.start,
                              children: [
                                Text(
                                  detail.displayTitle,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (detail.titleNative.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    detail.titleNative,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: AppColors.gold,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      detail.averageScore > 0
                                          ? (detail.averageScore / 10)
                                              .toStringAsFixed(1)
                                          : 'N/A',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface2,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        detail.status,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          color: AppColors.infoCyan,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (detail.studio.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Studio: ${detail.studio}',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // "Tonton Sekarang" CTA Button
                      if (catalogItem != null && catalogItem.episodes.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.accentStart.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(
                                Icons.play_circle_fill_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                              label: const Text(
                                'Tonton Sekarang',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PlayerScreen(
                                      animeId: widget.animeId,
                                      episodeNumber: catalogItem
                                          .episodes.first.episodeNumber,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Genres
                      if (detail.genres.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: detail.genres.map((genre) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surface2,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                genre,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Synopsis
                      const Text(
                        'Sinopsis',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        detail.description.isNotEmpty
                            ? detail.description.replaceAll(RegExp(r'<[^>]*>'), '')
                            : 'Tidak ada sinopsis tersedia.',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Characters Carousel
                      if (detail.characters.isNotEmpty) ...[
                        const Text(
                          'Karakter Utama',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 130,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: detail.characters.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final char = detail.characters[index];
                              return SizedBox(
                                width: 80,
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(40),
                                      child: CachedNetworkImage(
                                        imageUrl: char.imageUrl,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) =>
                                            Container(
                                          color: AppColors.surface2,
                                          child: const Icon(
                                              Icons.person_rounded),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      char.name,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Episodes Section
                      const Text(
                        'Daftar Episode',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (catalogItem == null || catalogItem.episodes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Belum ada episode yang tersedia.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: catalogItem.episodes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final ep = catalogItem.episodes[index];
                            final isDirect = ep.videoType == 'direct';

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PlayerScreen(
                                      animeId: widget.animeId,
                                      episodeNumber: ep.episodeNumber,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface1,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.surface2,
                                      radius: 20,
                                      child: Text(
                                        '${ep.episodeNumber}',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAlignment.start,
                                        children: [
                                          Text(
                                            'Episode ${ep.episodeNumber}',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Sumber: ${ep.sourceChannel}',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDirect
                                            ? AppColors.infoCyan.withOpacity(0.15)
                                            : Colors.redAccent.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isDirect ? 'Direct' : 'YouTube',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDirect
                                              ? AppColors.infoCyan
                                              : Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.play_circle_fill_rounded,
                                      color: AppColors.accentStart,
                                      size: 28,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.accentStart),
          ),
        ),
        error: (err, _) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Text(
              'Gagal memuat detail: $err',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
