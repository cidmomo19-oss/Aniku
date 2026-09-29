import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../data/providers.dart';
import '../../data/local_db.dart';
import '../player/player_screen.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsAsync = ref.watch(downloadsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unduhan Offline'),
      ),
      body: downloadsAsync.when(
        data: (downloadsList) {
          if (downloadsList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_for_offline_rounded,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada episode yang diunduh.',
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

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: downloadsList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = downloadsList[index];
              final id = item['id'] as int;
              final animeId = item['anime_id'] as int;
              final animeTitle = (item['anime_title'] as String?) ?? 'Anime';
              final epNum = item['episode_number'] as int;
              final filePath = item['file_path'] as String;

              final fileExists = File(filePath).existsSync();

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.surface2,
                      radius: 22,
                      child: const Icon(
                        Icons.movie_rounded,
                        color: AppColors.infoCyan,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAlignment.start,
                        children: [
                          Text(
                            animeTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Episode $epNum ${fileExists ? "• Tersedia offline" : "• File tidak ditemukan"}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: fileExists
                                  ? AppColors.infoCyan
                                  : Colors.redAccent,
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
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Hapus Unduhan'),
                            content: Text(
                                'Hapus file episode $epNum dari penyimpanan?'),
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
                          try {
                            final file = File(filePath);
                            if (await file.exists()) {
                              await file.delete();
                            }
                          } catch (_) {}
                          await LocalDb.instance.deleteDownload(id);
                          ref.invalidate(downloadsProvider);
                        }
                      },
                    ),
                  ],
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
