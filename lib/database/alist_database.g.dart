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

  VideoViewingRecordDao? _videoViewingRecordDaoInstance;

  FileDownloadRecordRecordDao? _downloadRecordRecordDaoInstance;

  FilePasswordDao? _filePasswordDaoInstance;

  ServerDao? _serverDaoInstance;

  FileViewingRecordDao? _fileViewingRecordDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 5,
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
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `file_download_record` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `server_url` TEXT NOT NULL, `user_id` TEXT NOT NULL, `remote_path` TEXT NOT NULL, `sign` TEXT NOT NULL, `name` TEXT NOT NULL, `local_path` TEXT NOT NULL, `create_time` INTEGER NOT NULL, `thumbnail` TEXT, `request_headers` TEXT, `limit_frequency` INTEGER)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `file_password` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `server_url` TEXT NOT NULL, `user_id` TEXT NOT NULL, `remote_path` TEXT NOT NULL, `password` TEXT NOT NULL, `create_time` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `server` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` TEXT NOT NULL, `server_url` TEXT NOT NULL, `user_id` TEXT NOT NULL, `password` TEXT NOT NULL, `token` TEXT NOT NULL, `guest` INTEGER NOT NULL, `ignore_ssl_error` INTEGER NOT NULL, `create_time` INTEGER NOT NULL, `update_time` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `file_viewing_record` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `server_url` TEXT NOT NULL, `user_id` TEXT NOT NULL, `remote_path` TEXT NOT NULL, `name` TEXT NOT NULL, `size` INTEGER NOT NULL, `sign` TEXT, `thumb` TEXT, `modified` INTEGER NOT NULL, `provider` TEXT NOT NULL, `create_time` INTEGER NOT NULL, `path` TEXT NOT NULL)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  VideoViewingRecordDao get videoViewingRecordDao {
    return _videoViewingRecordDaoInstance ??=
        _$VideoViewingRecordDao(database, changeListener);
  }

  @override
  FileDownloadRecordRecordDao get downloadRecordRecordDao {
    return _downloadRecordRecordDaoInstance ??=
        _$FileDownloadRecordRecordDao(database, changeListener);
  }

  @override
  FilePasswordDao get filePasswordDao {
    return _filePasswordDaoInstance ??=
        _$FilePasswordDao(database, changeListener);
  }

  @override
  ServerDao get serverDao {
    return _serverDaoInstance ??= _$ServerDao(database, changeListener);
  }

  @override
  FileViewingRecordDao get fileViewingRecordDao {
    return _fileViewingRecordDaoInstance ??=
        _$FileViewingRecordDao(database, changeListener);
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
                }),
        _videoViewingRecordDeletionAdapter = DeletionAdapter(
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

  final DeletionAdapter<VideoViewingRecord> _videoViewingRecordDeletionAdapter;

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

  @override
  Future<void> deleteRecord(VideoViewingRecord record) async {
    await _videoViewingRecordDeletionAdapter.delete(record);
  }
}

class _$FileDownloadRecordRecordDao extends FileDownloadRecordRecordDao {
  _$FileDownloadRecordRecordDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _fileDownloadRecordInsertionAdapter = InsertionAdapter(
            database,
            'file_download_record',
            (FileDownloadRecord item) => <String, Object?>{
                  'id': item.id,
                  'server_url': item.serverUrl,
                  'user_id': item.userId,
                  'remote_path': item.remotePath,
                  'sign': item.sign,
                  'name': item.name,
                  'local_path': item.localPath,
                  'create_time': item.createTime,
                  'thumbnail': item.thumbnail,
                  'request_headers': item.requestHeaders,
                  'limit_frequency': item.limitFrequency
                }),
        _fileDownloadRecordUpdateAdapter = UpdateAdapter(
            database,
            'file_download_record',
            ['id'],
            (FileDownloadRecord item) => <String, Object?>{
                  'id': item.id,
                  'server_url': item.serverUrl,
                  'user_id': item.userId,
                  'remote_path': item.remotePath,
                  'sign': item.sign,
                  'name': item.name,
                  'local_path': item.localPath,
                  'create_time': item.createTime,
                  'thumbnail': item.thumbnail,
                  'request_headers': item.requestHeaders,
                  'limit_frequency': item.limitFrequency
                }),
        _fileDownloadRecordDeletionAdapter = DeletionAdapter(
            database,
            'file_download_record',
            ['id'],
            (FileDownloadRecord item) => <String, Object?>{
                  'id': item.id,
                  'server_url': item.serverUrl,
                  'user_id': item.userId,
                  'remote_path': item.remotePath,
                  'sign': item.sign,
                  'name': item.name,
                  'local_path': item.localPath,
                  'create_time': item.createTime,
                  'thumbnail': item.thumbnail,
                  'request_headers': item.requestHeaders,
                  'limit_frequency': item.limitFrequency
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<FileDownloadRecord>
      _fileDownloadRecordInsertionAdapter;

  final UpdateAdapter<FileDownloadRecord> _fileDownloadRecordUpdateAdapter;

  final DeletionAdapter<FileDownloadRecord> _fileDownloadRecordDeletionAdapter;

  @override
  Future<int?> deleteById(int id) async {
    return _queryAdapter.query('DELETE FROM file_download_record WHERE id = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [id]);
  }

  @override
  Future<FileDownloadRecord?> findRecordBySign(
    String serverUrl,
    String userId,
    String sign,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM file_download_record WHERE server_url = ?1 AND user_id=?2 AND sign=?3 LIMIT 1',
        mapper: (Map<String, Object?> row) => FileDownloadRecord(id: row['id'] as int?, serverUrl: row['server_url'] as String, userId: row['user_id'] as String, remotePath: row['remote_path'] as String, sign: row['sign'] as String, name: row['name'] as String, localPath: row['local_path'] as String, createTime: row['create_time'] as int, thumbnail: row['thumbnail'] as String?, requestHeaders: row['request_headers'] as String?, limitFrequency: row['limit_frequency'] as int?),
        arguments: [serverUrl, userId, sign]);
  }

  @override
  Future<FileDownloadRecord?> findRecordByRemotePath(
    String serverUrl,
    String userId,
    String remotePath,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM file_download_record WHERE server_url = ?1 AND user_id=?2 AND remote_path=?3 LIMIT 1',
        mapper: (Map<String, Object?> row) => FileDownloadRecord(id: row['id'] as int?, serverUrl: row['server_url'] as String, userId: row['user_id'] as String, remotePath: row['remote_path'] as String, sign: row['sign'] as String, name: row['name'] as String, localPath: row['local_path'] as String, createTime: row['create_time'] as int, thumbnail: row['thumbnail'] as String?, requestHeaders: row['request_headers'] as String?, limitFrequency: row['limit_frequency'] as int?),
        arguments: [serverUrl, userId, remotePath]);
  }

  @override
  Future<List<FileDownloadRecord>?> findAll(
    String serverUrl,
    String userId,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM file_download_record WHERE server_url = ?1 AND user_id=?2 ORDER BY id DESC',
        mapper: (Map<String, Object?> row) => FileDownloadRecord(id: row['id'] as int?, serverUrl: row['server_url'] as String, userId: row['user_id'] as String, remotePath: row['remote_path'] as String, sign: row['sign'] as String, name: row['name'] as String, localPath: row['local_path'] as String, createTime: row['create_time'] as int, thumbnail: row['thumbnail'] as String?, requestHeaders: row['request_headers'] as String?, limitFrequency: row['limit_frequency'] as int?),
        arguments: [serverUrl, userId]);
  }

  @override
  Future<int> insertRecord(FileDownloadRecord record) {
    return _fileDownloadRecordInsertionAdapter.insertAndReturnId(
        record, OnConflictStrategy.abort);
  }

  @override
  Future<int> updateRecord(FileDownloadRecord record) {
    return _fileDownloadRecordUpdateAdapter.updateAndReturnChangedRows(
        record, OnConflictStrategy.abort);
  }

  @override
  Future<int> deleteRecord(FileDownloadRecord record) {
    return _fileDownloadRecordDeletionAdapter
        .deleteAndReturnChangedRows(record);
  }
}

class _$FilePasswordDao extends FilePasswordDao {
  _$FilePasswordDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _filePasswordInsertionAdapter = InsertionAdapter(
            database,
            'file_password',
            (FilePassword item) => <String, Object?>{
                  'id': item.id,
                  'server_url': item.serverUrl,
                  'user_id': item.userId,
                  'remote_path': item.remotePath,
                  'password': item.password,
                  'create_time': item.createTime
                }),
        _filePasswordUpdateAdapter = UpdateAdapter(
            database,
            'file_password',
            ['id'],
            (FilePassword item) => <String, Object?>{
                  'id': item.id,
                  'server_url': item.serverUrl,
                  'user_id': item.userId,
                  'remote_path': item.remotePath,
                  'password': item.password,
                  'create_time': item.createTime
                }),
        _filePasswordDeletionAdapter = DeletionAdapter(
            database,
            'file_password',
            ['id'],
            (FilePassword item) => <String, Object?>{
                  'id': item.id,
                  'server_url': item.serverUrl,
                  'user_id': item.userId,
                  'remote_path': item.remotePath,
                  'password': item.password,
                  'create_time': item.createTime
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<FilePassword> _filePasswordInsertionAdapter;

  final UpdateAdapter<FilePassword> _filePasswordUpdateAdapter;

  final DeletionAdapter<FilePassword> _filePasswordDeletionAdapter;

  @override
  Future<void> deleteByPath(
    String serverUrl,
    String userId,
    String remotePath,
  ) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM file_password WHERE server_url = ?1 AND user_id=?2 AND remote_path=?3',
        arguments: [serverUrl, userId, remotePath]);
  }

  @override
  Future<FilePassword?> findPasswordByPath(
    String serverUrl,
    String userId,
    String remotePath,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM file_password WHERE server_url = ?1 AND user_id=?2 AND remote_path=?3 ORDER BY id DESC LIMIT 1',
        mapper: (Map<String, Object?> row) => FilePassword(id: row['id'] as int?, serverUrl: row['server_url'] as String, userId: row['user_id'] as String, remotePath: row['remote_path'] as String, password: row['password'] as String, createTime: row['create_time'] as int),
        arguments: [serverUrl, userId, remotePath]);
  }

  @override
  Future<int> insertFilePassword(FilePassword filePassword) {
    return _filePasswordInsertionAdapter.insertAndReturnId(
        filePassword, OnConflictStrategy.abort);
  }

  @override
  Future<int> updateFilePassword(FilePassword filePassword) {
    return _filePasswordUpdateAdapter.updateAndReturnChangedRows(
        filePassword, OnConflictStrategy.abort);
  }

  @override
  Future<int> deleteFilePassword(FilePassword filePassword) {
    return _filePasswordDeletionAdapter
        .deleteAndReturnChangedRows(filePassword);
  }
}

class _$ServerDao extends ServerDao {
  _$ServerDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _serverInsertionAdapter = InsertionAdapter(
            database,
            'server',
            (Server item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'server_url': item.serverUrl,
                  'user_id': item.userId,
                  'password': item.password,
                  'token': item.token,
                  'guest': item.guest ? 1 : 0,
                  'ignore_ssl_error': item.ignoreSSLError ? 1 : 0,
                  'create_time': item.createTime,
                  'update_time': item.updateTime
                },
            changeListener),
        _serverUpdateAdapter = UpdateAdapter(
            database,
            'server',
            ['id'],
            (Server item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'server_url': item.serverUrl,
                  'user_id': item.userId,
                  'password': item.password,
                  'token': item.token,
                  'guest': item.guest ? 1 : 0,
                  'ignore_ssl_error': item.ignoreSSLError ? 1 : 0,
                  'create_time': item.createTime,
                  'update_time': item.updateTime
                },
            changeListener),
        _serverDeletionAdapter = DeletionAdapter(
            database,
            'server',
            ['id'],
            (Server item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'server_url': item.serverUrl,
                  'user_id': item.userId,
                  'password': item.password,
                  'token': item.token,
                  'guest': item.guest ? 1 : 0,
                  'ignore_ssl_error': item.ignoreSSLError ? 1 : 0,
                  'create_time': item.createTime,
                  'update_time': item.updateTime
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Server> _serverInsertionAdapter;

  final UpdateAdapter<Server> _serverUpdateAdapter;

  final DeletionAdapter<Server> _serverDeletionAdapter;

  @override
  Future<Server?> findServer(
    String serverUrl,
    String userId,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM server WHERE server_url = ?1 AND user_id=?2 LIMIT 1',
        mapper: (Map<String, Object?> row) => Server(
            id: row['id'] as int?,
            name: row['name'] as String,
            serverUrl: row['server_url'] as String,
            userId: row['user_id'] as String,
            password: row['password'] as String,
            token: row['token'] as String,
            guest: (row['guest'] as int) != 0,
            ignoreSSLError: (row['ignore_ssl_error'] as int) != 0,
            createTime: row['create_time'] as int,
            updateTime: row['update_time'] as int),
        arguments: [serverUrl, userId]);
  }

  @override
  Stream<List<Server>?> serverList() {
    return _queryAdapter.queryListStream(
        'SELECT * FROM server ORDER BY id desc LIMIT 100',
        mapper: (Map<String, Object?> row) => Server(
            id: row['id'] as int?,
            name: row['name'] as String,
            serverUrl: row['server_url'] as String,
            userId: row['user_id'] as String,
            password: row['password'] as String,
            token: row['token'] as String,
            guest: (row['guest'] as int) != 0,
            ignoreSSLError: (row['ignore_ssl_error'] as int) != 0,
            createTime: row['create_time'] as int,
            updateTime: row['update_time'] as int),
        queryableName: 'server',
        isView: false);
  }

  @override
  Future<int> insertServer(Server server) {
    return _serverInsertionAdapter.insertAndReturnId(
        server, OnConflictStrategy.abort);
  }

  @override
  Future<int> updateServer(Server server) {
    return _serverUpdateAdapter.updateAndReturnChangedRows(
        server, OnConflictStrategy.abort);
  }

  @override
  Future<int> deleteServer(Server server) {
    return _serverDeletionAdapter.deleteAndReturnChangedRows(server);
  }
}

class _$FileViewingRecordDao extends FileViewingRecordDao {
  _$FileViewingRecordDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _fileViewingRecordInsertionAdapter = InsertionAdapter(
            database,
            'file_viewing_record',
            (FileViewingRecord item) => <String, Object?>{
                  'id': item.id,
                  'server_url': item.serverUrl,
                  'user_id': item.userId,
                  'remote_path': item.remotePath,
                  'name': item.name,
                  'size': item.size,
                  'sign': item.sign,
                  'thumb': item.thumb,
                  'modified': item.modified,
                  'provider': item.provider,
                  'create_time': item.createTime,
                  'path': item.path
                },
            changeListener),
        _fileViewingRecordUpdateAdapter = UpdateAdapter(
            database,
            'file_viewing_record',
            ['id'],
            (FileViewingRecord item) => <String, Object?>{
                  'id': item.id,
                  'server_url': item.serverUrl,
                  'user_id': item.userId,
                  'remote_path': item.remotePath,
                  'name': item.name,
                  'size': item.size,
                  'sign': item.sign,
                  'thumb': item.thumb,
                  'modified': item.modified,
                  'provider': item.provider,
                  'create_time': item.createTime,
                  'path': item.path
                },
            changeListener),
        _fileViewingRecordDeletionAdapter = DeletionAdapter(
            database,
            'file_viewing_record',
            ['id'],
            (FileViewingRecord item) => <String, Object?>{
                  'id': item.id,
                  'server_url': item.serverUrl,
                  'user_id': item.userId,
                  'remote_path': item.remotePath,
                  'name': item.name,
                  'size': item.size,
                  'sign': item.sign,
                  'thumb': item.thumb,
                  'modified': item.modified,
                  'provider': item.provider,
                  'create_time': item.createTime,
                  'path': item.path
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<FileViewingRecord> _fileViewingRecordInsertionAdapter;

  final UpdateAdapter<FileViewingRecord> _fileViewingRecordUpdateAdapter;

  final DeletionAdapter<FileViewingRecord> _fileViewingRecordDeletionAdapter;

  @override
  Stream<List<FileViewingRecord>?> recordList(
    String serverUrl,
    String userId,
  ) {
    return _queryAdapter.queryListStream(
        'SELECT * FROM file_viewing_record WHERE server_url = ?1 AND user_id=?2 ORDER BY id DESC LIMIT 100',
        mapper: (Map<String, Object?> row) => FileViewingRecord(
            id: row['id'] as int?,
            serverUrl: row['server_url'] as String,
            userId: row['user_id'] as String,
            remotePath: row['remote_path'] as String,
            name: row['name'] as String,
            path: row['path'] as String,
            size: row['size'] as int,
            sign: row['sign'] as String?,
            thumb: row['thumb'] as String?,
            modified: row['modified'] as int,
            provider: row['provider'] as String,
            createTime: row['create_time'] as int),
        arguments: [serverUrl, userId],
        queryableName: 'file_viewing_record',
        isView: false);
  }

  @override
  Future<void> deleteByPath(
    String serverUrl,
    String userId,
    String remotePath,
  ) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM file_viewing_record WHERE server_url = ?1 AND user_id=?2 AND remote_path=?3',
        arguments: [serverUrl, userId, remotePath]);
  }

  @override
  Future<int> insertRecord(FileViewingRecord record) {
    return _fileViewingRecordInsertionAdapter.insertAndReturnId(
        record, OnConflictStrategy.abort);
  }

  @override
  Future<int> updateRecord(FileViewingRecord record) {
    return _fileViewingRecordUpdateAdapter.updateAndReturnChangedRows(
        record, OnConflictStrategy.abort);
  }

  @override
  Future<int> deleteRecord(FileViewingRecord record) {
    return _fileViewingRecordDeletionAdapter.deleteAndReturnChangedRows(record);
  }
}
