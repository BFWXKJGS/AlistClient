// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alist_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

// ignore: avoid_classes_with_only_static_members
class $FloorAlistDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AlistDatabaseBuilder databaseBuilder(String name) =>
      _$AlistDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AlistDatabaseBuilder inMemoryDatabaseBuilder() =>
      _$AlistDatabaseBuilder(null);
}

class _$AlistDatabaseBuilder {
  _$AlistDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  /// Adds migrations to the builder.
  _$AlistDatabaseBuilder addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  /// Adds a database [Callback] to the builder.
  _$AlistDatabaseBuilder addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  /// Creates the database and initializes it.
  Future<AlistDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AlistDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AlistDatabase extends AlistDatabase {
  _$AlistDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  VideoViewingRecordDao? _recordDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `video_viewing_record` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `server_url` TEXT NOT NULL, `user_id` TEXT NOT NULL, `video_sign` TEXT NOT NULL, `path` TEXT NOT NULL, `video_duration` INTEGER NOT NULL, `video_current_position` INTEGER NOT NULL)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  VideoViewingRecordDao get recordDao {
    return _recordDaoInstance ??=
        _$VideoViewingRecordDao(database, changeListener);
  }
}

class _$VideoViewingRecordDao extends VideoViewingRecordDao {
  _$VideoViewingRecordDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _videoViewingRecordInsertionAdapter = InsertionAdapter(
            database,
            'video_viewing_record',
            (VideoViewingRecord item) => <String, Object?>{
                  'id': item.id,
                  'server_url': item.serverUrl,
                  'user_id': item.userId,
                  'video_sign': item.videoSign,
                  'path': item.path,
                  'video_duration': item.videoDuration,
                  'video_current_position': item.videoCurrentPosition
                }),
        _videoViewingRecordUpdateAdapter = UpdateAdapter(
            database,
            'video_viewing_record',
            ['id'],
            (VideoViewingRecord item) => <String, Object?>{
                  'id': item.id,
                  'server_url': item.serverUrl,
                  'user_id': item.userId,
                  'video_sign': item.videoSign,
                  'path': item.path,
                  'video_duration': item.videoDuration,
                  'video_current_position': item.videoCurrentPosition
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<VideoViewingRecord>
      _videoViewingRecordInsertionAdapter;

  final UpdateAdapter<VideoViewingRecord> _videoViewingRecordUpdateAdapter;

  @override
  Future<VideoViewingRecord?> findRecordBySign(
    String serverUrl,
    String userId,
    String sign,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM video_viewing_record WHERE server_url = ?1 AND user_id=?2 AND video_sign=?3 LIMIT 1',
        mapper: (Map<String, Object?> row) => VideoViewingRecord(id: row['id'] as int?, serverUrl: row['server_url'] as String, userId: row['user_id'] as String, videoSign: row['video_sign'] as String, path: row['path'] as String, videoDuration: row['video_duration'] as int, videoCurrentPosition: row['video_current_position'] as int),
        arguments: [serverUrl, userId, sign]);
  }

  @override
  Future<VideoViewingRecord?> findRecordByPath(
    String serverUrl,
    String userId,
    String path,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM video_viewing_record WHERE server_url = ?1 AND user_id=?2 AND path=?3 LIMIT 1',
        mapper: (Map<String, Object?> row) => VideoViewingRecord(id: row['id'] as int?, serverUrl: row['server_url'] as String, userId: row['user_id'] as String, videoSign: row['video_sign'] as String, path: row['path'] as String, videoDuration: row['video_duration'] as int, videoCurrentPosition: row['video_current_position'] as int),
        arguments: [serverUrl, userId, path]);
  }

  @override
  Future<int> insertRecord(VideoViewingRecord record) {
    return _videoViewingRecordInsertionAdapter.insertAndReturnId(
        record, OnConflictStrategy.abort);
  }

  @override
  Future<int> updateRecord(VideoViewingRecord record) {
    return _videoViewingRecordUpdateAdapter.updateAndReturnChangedRows(
        record, OnConflictStrategy.abort);
  }
}
