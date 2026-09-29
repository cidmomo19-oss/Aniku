import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../data/providers.dart';
import '../../data/models/anime_detail.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/shimmer_box.dart';
import '../detail/detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedGenre;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogProvider);
    final batchAsync = ref.watch(animeBatchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Anime'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Search Input Box
            TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _query = val.trim().toLowerCase();
                });
              },
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Cari judul anime...',
                hintStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface1,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Genre Chips Filter & Results Body
            Expanded(
              child: catalogAsync.when(
                data: (catalogItems) {
                  return batchAsync.when(
                    data: (batchMap) {
                      final detailsList = catalogItems
                          .map((item) => batchMap[item.anilistId])
                          .whereType<AnimeDetail>()
                          .toList();

                      // Collect all available genres
                      final allGenres = <String>{};
                      for (final d in detailsList) {
                        allGenres.addAll(d.genres);
                      }

                      // Filter results
                      final filtered = detailsList.where((d) {
                        final matchesQuery = _query.isEmpty ||
                            d.titleRomaji.toLowerCase().contains(_query) ||
                            d.titleEnglish.toLowerCase().contains(_query) ||
                            d.titleNative.toLowerCase().contains(_query);

                        final matchesGenre = _selectedGenre == null ||
                            d.genres.contains(_selectedGenre);

                        return matchesQuery && matchesGenre;
                      }).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (allGenres.isNotEmpty)
                            SizedBox(
                              height: 36,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  ChoiceChip(
                                    label: const Text('Semua'),
                                    selected: _selectedGenre == null,
                                    selectedColor: AppColors.accentStart,
                                    backgroundColor: AppColors.surface2,
                                    labelStyle: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _selectedGenre == null
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _selectedGenre = null;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ...allGenres.map((genre) {
                                    final isSelected =
                                        _selectedGenre == genre;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(genre),
                                        selected: isSelected,
                                        selectedColor: AppColors.accentStart,
                                        backgroundColor: AppColors.surface2,
                                        labelStyle: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                        ),
                                        onSelected: (selected) {
                                          setState(() {
                                            _selectedGenre =
                                                selected ? genre : null;
                                          });
                                        },
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),

                          Expanded(
                            child: filtered.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.search_off_rounded,
                                          size: 64,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Tidak ada anime yang cocok',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : GridView.builder(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.62,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 16,
                                    ),
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      final detail = filtered[index];
                                      return AnimeCard(
                                        detail: detail,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => DetailScreen(
                                                animeId: detail.anilistId,
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                    loading: () => _buildShimmerGrid(),
                    error: (_, __) => _buildShimmerGrid(),
                  );
                },
                loading: () => _buildShimmerGrid(),
                error: (err, _) => Center(
                  child: Text(
                    'Error: $err',
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
