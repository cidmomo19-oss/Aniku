import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../data/providers.dart';
import '../../data/models/catalog_entry.dart';
import '../../data/download_service.dart';
import '../../data/local_db.dart';
import 'youtube_player_widget.dart';
import 'direct_player_widget.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final int animeId;
  final int episodeNumber;

  const PlayerScreen({
    super.key,
    required this.animeId,
    required this.episodeNumber,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late int _currentEpisodeNum;
  Map<String, dynamic>? _downloadedRecord;

  @override
  void initState() {
    super.initState();
    _currentEpisodeNum = widget.episodeNumber;
    _checkDownloadStatus();
  }

  Future<void> _checkDownloadStatus() async {
    final record = await LocalDb.instance.getDownloadForEpisode(
      widget.animeId,
      _currentEpisodeNum,
    );
    if (mounted) {
      setState(() {
        _downloadedRecord = record;
      });
    }
  }

  void _navigateToEpisode(int newEp) {
    setState(() {
      _currentEpisodeNum = newEp;
    });
    _checkDownloadStatus();
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogProvider);
    final batchAsync = ref.watch(animeBatchProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Episode $_currentEpisodeNum'),
      ),
      body: catalogAsync.when(
        data: (catalogItems) {
          final catalogItem = catalogItems.firstWhere(
            (item) => item.anilistId == widget.animeId,
            orElse: () => CatalogItem(
              id: widget.animeId,
              anilistId: widget.animeId,
              addedDate: '',
              episodes: [],
            ),
          );

          final episode = catalogItem.episodes.firstWhere(
            (ep) => ep.episodeNumber == _currentEpisodeNum,
            orElse: () => CatalogEpisode(
              episodeNumber: _currentEpisodeNum,
              videoType: 'direct',
              sourceChannel: 'Unknown',
            ),
          );

          final detailMap = batchAsync.value ?? {};
          final detail = detailMap[widget.animeId];
          final animeTitle = detail?.displayTitle ?? 'Anime #${widget.animeId}';
          final epTitle = '$animeTitle - Ep $_currentEpisodeNum';

          final episodeIndex = catalogItem.episodes.indexWhere(
            (ep) => ep.episodeNumber == _currentEpisodeNum,
          );

          final hasPrev = episodeIndex > 0;
          final hasNext = episodeIndex >= 0 &&
              episodeIndex < catalogItem.episodes.length - 1;

          final prevEp = hasPrev
              ? catalogItem.episodes[episodeIndex - 1].episodeNumber
              : null;
          final nextEp = hasNext
              ? catalogItem.episodes[episodeIndex + 1].episodeNumber
              : null;

          // Check if playing from local downloaded file or remote URL
          final localFilePath = _downloadedRecord?['file_path'] as String?;
          final activeVideoUrl = (localFilePath != null &&
                  localFilePath.isNotEmpty)
              ? localFilePath
              : (episode.videoUrl ??
                  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4');

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (episode.videoType == 'youtube')
                  YoutubePlayerWidget(
                    youtubeId: episode.youtubeId ?? 'sENM2wA_FTg',
                    episodeTitle: epTitle,
                    sourceChannel: episode.sourceChannel,
                  )
                else
                  DirectPlayerWidget(
                    key: ValueKey('direct_player_$_currentEpisodeNum'),
                    videoUrl: activeVideoUrl,
                    animeId: widget.animeId,
                    episodeNumber: _currentEpisodeNum,
                    episodeTitle: epTitle,
                    sourceChannel: episode.sourceChannel,
                    onPrevEpisode:
                        hasPrev ? () => _navigateToEpisode(prevEp!) : null,
                    onNextEpisode:
                        hasNext ? () => _navigateToEpisode(nextEp!) : null,
                  ),

                const SizedBox(height: 16),

                // Download Button Action Section (Only for Direct mode)
                if (episode.videoType == 'direct')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        if (_downloadedRecord != null)
                          Chip(
                            avatar: const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.infoCyan,
                              size: 18,
                            ),
                            label: const Text('Tersimpan Offline'),
                            backgroundColor:
                                AppColors.infoCyan.withOpacity(0.15),
                          )
                        else
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surface2,
                              foregroundColor: AppColors.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.download_rounded,
                              color: AppColors.accentStart,
                            ),
                            label: const Text(
                              'Unduh Episode Ini',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () async {
                              final videoUrl = episode.videoUrl;
                              if (videoUrl != null && videoUrl.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Mulai mengunduh Episode $_currentEpisodeNum...',
                                    ),
                                    backgroundColor: AppColors.surface2,
                                  ),
                                );

                                await DownloadService.instance.downloadEpisode(
                                  animeId: widget.animeId,
                                  animeTitle: animeTitle,
                                  episodeNumber: _currentEpisodeNum,
                                  url: videoUrl,
                                );

                                await _checkDownloadStatus();
                                ref.invalidate(downloadsProvider);
                              }
                            },
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Episode List Picker
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Episode',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: catalogItem.episodes.map((ep) {
                          final isCurrent =
                              ep.episodeNumber == _currentEpisodeNum;
                          return ChoiceChip(
                            label: Text('Ep ${ep.episodeNumber}'),
                            selected: isCurrent,
                            selectedColor: AppColors.accentStart,
                            backgroundColor: AppColors.surface1,
                            labelStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: isCurrent
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                _navigateToEpisode(ep.episodeNumber);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
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
