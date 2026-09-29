import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDb {
  static final LocalDb instance = LocalDb._init();
  static Database? _database;

  LocalDb._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('anikuplay.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bookmarks (
        anime_id INTEGER PRIMARY KEY,
        cached_json TEXT,
        created_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE watch_history (
        anime_id INTEGER PRIMARY KEY,
        episode_number INTEGER,
        position_ms INTEGER,
        duration_ms INTEGER,
        updated_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE anilist_cache (
        anilist_id INTEGER PRIMARY KEY,
        json TEXT,
        fetched_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE downloads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        anime_id INTEGER,
        anime_title TEXT,
        episode_number INTEGER,
        file_path TEXT,
        downloaded_at INTEGER
      )
    ''');
  }

  // --- BOOKMARKS DAO ---
  Future<void> toggleBookmark(int animeId, String cachedJson) async {
    final db = await instance.database;
    final existing = await db.query(
      'bookmarks',
      where: 'anime_id = ?',
      whereArgs: [animeId],
    );

    if (existing.isNotEmpty) {
      await db.delete(
        'bookmarks',
        where: 'anime_id = ?',
        whereArgs: [animeId],
      );
    } else {
      await db.insert(
        'bookmarks',
        {
          'anime_id': animeId,
          'cached_json': cachedJson,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<bool> isBookmarked(int animeId) async {
    final db = await instance.database;
    final res = await db.query(
      'bookmarks',
      where: 'anime_id = ?',
      whereArgs: [animeId],
    );
    return res.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getBookmarks() async {
    final db = await instance.database;
    return await db.query('bookmarks', orderBy: 'created_at DESC');
  }

  // --- WATCH HISTORY DAO ---
  Future<void> saveWatchHistory({
    required int animeId,
    required int episodeNumber,
    required int positionMs,
    required int durationMs,
  }) async {
    final db = await instance.database;
    await db.insert(
      'watch_history',
      {
        'anime_id': animeId,
        'episode_number': episodeNumber,
        'position_ms': positionMs,
        'duration_ms': durationMs,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getWatchHistory() async {
    final db = await instance.database;
    return await db.query('watch_history', orderBy: 'updated_at DESC');
  }

  Future<Map<String, dynamic>?> getHistoryForAnime(int animeId) async {
    final db = await instance.database;
    final res = await db.query(
      'watch_history',
      where: 'anime_id = ?',
      whereArgs: [animeId],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<void> deleteHistoryItem(int animeId) async {
    final db = await instance.database;
    await db.delete(
      'watch_history',
      where: 'anime_id = ?',
      whereArgs: [animeId],
    );
  }

  Future<void> clearWatchHistory() async {
    final db = await instance.database;
    await db.delete('watch_history');
  }

  // --- ANILIST CACHE DAO ---
  Future<void> saveAniListCache(int anilistId, String jsonStr) async {
    final db = await instance.database;
    await db.insert(
      'anilist_cache',
      {
        'anilist_id': anilistId,
        'json': jsonStr,
        'fetched_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getAniListCache(int anilistId) async {
    final db = await instance.database;
    final res = await db.query(
      'anilist_cache',
      where: 'anilist_id = ?',
      whereArgs: [anilistId],
    );
    if (res.isNotEmpty) {
      return res.first['json'] as String?;
    }
    return null;
  }

  // --- DOWNLOADS DAO ---
  Future<int> addDownload({
    required int animeId,
    required String animeTitle,
    required int episodeNumber,
    required String filePath,
  }) async {
    final db = await instance.database;
    return await db.insert('downloads', {
      'anime_id': animeId,
      'anime_title': animeTitle,
      'episode_number': episodeNumber,
      'file_path': filePath,
      'downloaded_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getDownloads() async {
    final db = await instance.database;
    return await db.query('downloads', orderBy: 'downloaded_at DESC');
  }

  Future<Map<String, dynamic>?> getDownloadForEpisode(
      int animeId, int episodeNumber) async {
    final db = await instance.database;
    final res = await db.query(
      'downloads',
      where: 'anime_id = ? AND episode_number = ?',
      whereArgs: [animeId, episodeNumber],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<void> deleteDownload(int id) async {
    final db = await instance.database;
    await db.delete('downloads', where: 'id = ?', whereArgs: [id]);
  }
}
