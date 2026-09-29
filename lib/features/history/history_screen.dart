import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/providers.dart';
import '../../data/local_db.dart';
import '../player/player_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(watchHistoryProvider);
    final batchAsync = ref.watch(animeBatchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Nonton'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Hapus Semua Riwayat',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus Riwayat'),
                  content: const Text(
                      'Apakah Anda yakin ingin menghapus seluruh riwayat menonton?'),
                  actions: [
                    TextButton(
                      child: const Text('Batal'),
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                    TextButton(
                      child: const Text('Hapus',
                          style: TextStyle(color: Colors.redAccent)),
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await LocalDb.instance.clearWatchHistory();
                ref.invalidate(watchHistoryProvider);
              }
            },
          ),
        ],
      ),
      body: historyAsync.when(
        data: (historyList) {
          if (historyList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada riwayat menonton.',
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

          final detailMap = batchAsync.value ?? {};

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: historyList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = historyList[index];
              final animeId = item['anime_id'] as int;
              final epNum = item['episode_number'] as int;
              final posMs = (item['position_ms'] as int?) ?? 0;
              final durMs = (item['duration_ms'] as int?) ?? 1;
              final progress =
                  (posMs / (durMs <= 0 ? 1 : durMs)).clamp(0.0, 1.0);

              final detail = detailMap[animeId];
              final animeTitle =
                  detail?.displayTitle ?? 'Anime #$animeId';

              return Dismissible(
                key: ValueKey('history_$animeId'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                ),
                onDismissed: (_) async {
                  await LocalDb.instance.deleteHistoryItem(animeId);
                  ref.invalidate(watchHistoryProvider);
                },
                child: InkWell(
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
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface1,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: (detail != null &&
                                  detail.coverImage.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: detail.coverImage,
                                  width: 60,
                                  height: 85,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 60,
                                  height: 85,
                                  color: AppColors.surface2,
                                  child: const Icon(
                                      Icons.movie_rounded,
                                      color: AppColors.textSecondary),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                animeTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Lanjut Episode $epNum',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: AppColors.accentStart,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 4,
                                  backgroundColor: AppColors.surface2,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.accentStart,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.play_circle_fill_rounded,
                            color: AppColors.accentStart,
                            size: 32,
                          ),
                          onPressed: () {
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
                        ),
                      ],
                    ),
                  ),
                ),
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
