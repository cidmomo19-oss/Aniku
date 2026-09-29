import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'local_db.dart';

class DownloadService {
  static final DownloadService instance = DownloadService._init();
  final Dio _dio = Dio();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isNotifInitialized = false;

  DownloadService._init();

  Future<void> _initNotifications() async {
    if (_isNotifInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notificationsPlugin.initialize(initSettings);
      _isNotifInitialized = true;
    } catch (_) {}
  }

  Future<void> _showProgressNotification({
    required int id,
    required String title,
    required int progress,
  }) async {
    await _initNotifications();
    final androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Unduhan Episode',
      channelDescription: 'Notifikasi progress unduhan episode anime',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      onlyAlertOnce: true,
      ongoing: true,
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        'Mengunduh... $progress%',
        NotificationDetails(android: androidDetails),
      );
    } catch (_) {}
  }

  Future<void> _showCompleteNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _initNotifications();
    const androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Unduhan Episode',
      channelDescription: 'Notifikasi progress unduhan episode anime',
      importance: Importance.high,
      priority: Priority.high,
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(android: androidDetails),
      );
    } catch (_) {}
  }

  Future<String?> downloadEpisode({
    required int animeId,
    required String animeTitle,
    required int episodeNumber,
    required String url,
  }) async {
    final notifId = (animeId * 100 + episodeNumber) & 0x7FFFFFFF;

    try {
      Directory? dir = await getExternalStorageDirectory();
      dir ??= await getApplicationDocumentsDirectory();

      final downloadsDir = Directory(p.join(dir.path, 'downloads'));
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final fileName = 'anime_${animeId}_ep_${episodeNumber}.mp4';
      final savePath = p.join(downloadsDir.path, fileName);

      await _showProgressNotification(
        id: notifId,
        title: '$animeTitle - Ep $episodeNumber',
        progress: 0,
      );

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = ((received / total) * 100).toInt();
            _showProgressNotification(
              id: notifId,
              title: '$animeTitle - Ep $episodeNumber',
              progress: progress,
            );
          }
        },
      );

      // Save to Local DB
      await LocalDb.instance.addDownload(
        animeId: animeId,
        animeTitle: animeTitle,
        episodeNumber: episodeNumber,
        filePath: savePath,
      );

      await _showCompleteNotification(
        id: notifId,
        title: 'Unduhan Selesai',
        body: '$animeTitle - Ep $episodeNumber telah tersimpan offline.',
      );

      return savePath;
    } catch (e) {
      await _showCompleteNotification(
        id: notifId,
        title: 'Unduhan Gagal',
        body: 'Gagal mengunduh $animeTitle - Ep $episodeNumber.',
      );
      return null;
    }
  }
}
