import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../data/providers.dart';
import '../../data/models/anime_detail.dart';
import '../../widgets/anime_card.dart';
import '../detail/detail_screen.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Koleksi Favorit'),
      ),
      body: bookmarksAsync.when(
        data: (bookmarksList) {
          if (bookmarksList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada anime favorit yang disimpan.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final bookmarkedDetails = <AnimeDetail>[];
          for (final item in bookmarksList) {
            final jsonStr = item['cached_json'] as String?;
            if (jsonStr != null && jsonStr.isNotEmpty) {
              try {
                final Map<String, dynamic> decoded = jsonDecode(jsonStr);
                bookmarkedDetails.add(AnimeDetail.fromJson(decoded));
              } catch (_) {}
            }
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: bookmarkedDetails.length,
            itemBuilder: (context, index) {
              final detail = bookmarkedDetails[index];
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
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentStart),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
