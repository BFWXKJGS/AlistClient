import 'dart:async';
import 'dart:io';

import 'package:alist/database/alist_database.dart';
import 'package:alist/database/dao/favorite_dao.dart';
import 'package:alist/database/dao/file_download_record_dao.dart';
import 'package:alist/database/dao/file_password_dao.dart';
import 'package:alist/database/dao/file_viewing_record_dao.dart';
import 'package:alist/database/dao/server_dao.dart';
import 'package:alist/database/dao/video_viewing_record_dao.dart';
import 'package:floor/floor.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AlistDatabaseController extends GetxController {
  late final AlistDatabase database;
  late final VideoViewingRecordDao videoViewingRecordDao;
  late final FileDownloadRecordRecordDao downloadRecordRecordDao;
  late final FilePasswordDao filePasswordDao;
  late final ServerDao serverDao;
  late final FileViewingRecordDao fileViewingRecordDao;
  late final FavoriteDao favoriteDao;

  // create migration
  final _migration1to2 = Migration(1, 2, (database) async {
    await database.execute(
        'CREATE TABLE IF NOT EXISTS `file_download_record` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `server_url` TEXT NOT NULL, `user_id` TEXT NOT NULL, `remote_path` TEXT NOT NULL, `sign` TEXT NOT NULL, `name` TEXT NOT NULL, `local_path` TEXT NOT NULL, `create_time` INTEGER NOT NULL)');
    await database.execute(
        'CREATE TABLE IF NOT EXISTS `file_password` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `server_url` TEXT NOT NULL, `user_id` TEXT NOT NULL, `remote_path` TEXT NOT NULL, `password` TEXT NOT NULL, `create_time` INTEGER NOT NULL)');
    await database.execute(
        'CREATE TABLE IF NOT EXISTS `server` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` TEXT, `server_url` TEXT NOT NULL, `user_id` TEXT NOT NULL, `password` TEXT NOT NULL, `guest` INTEGER NOT NULL, `ignore_ssl_error` INTEGER NOT NULL, `create_time` INTEGER NOT NULL, `update_time` INTEGER NOT NULL)');
    await database.execute(
        'CREATE TABLE IF NOT EXISTS `file_viewing_record` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `server_url` TEXT NOT NULL, `user_id` TEXT NOT NULL, `remote_path` TEXT NOT NULL, `name` TEXT NOT NULL, `size` INTEGER NOT NULL, `sign` TEXT, `thumb` TEXT, `modified` TEXT NOT NULL, `provider` TEXT NOT NULL, `create_time` INTEGER NOT NULL)');
  });

  // create migration
  final _migration2to3 = Migration(2, 3, (database) async {
    await database.execute('DROP TABLE `file_viewing_record`');
    await database.execute(
        'CREATE TABLE IF NOT EXISTS `file_viewing_record` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `server_url` TEXT NOT NULL, `user_id` TEXT NOT NULL, `remote_path` TEXT NOT NULL, `name` TEXT NOT NULL, `size` INTEGER NOT NULL, `sign` TEXT, `thumb` TEXT, `modified` INTEGER NOT NULL, `provider` TEXT NOT NULL, `create_time` INTEGER NOT NULL, `path` TEXT NOT NULL)');
  });

  // create migration
  final _migration3to4 = Migration(3, 4, (database) async {
    await database.execute('DROP TABLE `server`');
    await database.execute(
        'CREATE TABLE IF NOT EXISTS `server` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` TEXT NOT NULL, `server_url` TEXT NOT NULL, `user_id` TEXT NOT NULL, `password` TEXT NOT NULL, `token` TEXT NOT NULL, `guest` INTEGER NOT NULL, `ignore_ssl_error` INTEGER NOT NULL, `create_time` INTEGER NOT NULL, `update_time` INTEGER NOT NULL)');
  });

  // create migration
  final _migration4to5 = Migration(4, 5, (database) async {
    await database
        .execute('ALTER TABLE `file_download_record` ADD `thumbnail` TEXT');
    await database.execute(
        'ALTER TABLE `file_download_record` ADD `request_headers` TEXT');
    await database.execute(
        'ALTER TABLE `file_download_record` ADD `limit_frequency` INTEGER');
    await database
        .execute('ALTER TABLE `file_download_record` ADD `finished` INTEGER');
    await database.execute(
        'CREATE TABLE IF NOT EXISTS `favorite` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `is_dir` INTEGER NOT NULL, `server_url` TEXT NOT NULL, `user_id` TEXT NOT NULL, `remote_path` TEXT NOT NULL, `name` TEXT NOT NULL, `size` INTEGER NOT NULL, `sign` TEXT, `thumb` TEXT, `modified` INTEGER NOT NULL, `provider` TEXT NOT NULL, `create_time` INTEGER NOT NULL, `path` TEXT NOT NULL)');
  });

  Future<void> init() async {
    var dbName = "alist.db";
    if (Platform.isIOS) {
      var directory = await getApplicationSupportDirectory();
      var dbPath = path.join(directory.path, "database", "alist.db");
      if (!await File(dbPath).exists()) {
        var directoryOld = await getApplicationDocumentsDirectory();
        var dbPathOld = path.join(directoryOld.path, "alist.db");
        if (await File(dbPathOld).exists()) {
          await File(dbPathOld).rename(dbPath);
        }
      }
      dbName = dbPath;
    }

    database = await $FloorAlistDatabase.databaseBuilder(dbName).addMigrations([
      _migration1to2,
      _migration2to3,
      _migration3to4,
      _migration4to5,
    ]).build();
    videoViewingRecordDao = database.videoViewingRecordDao;
    downloadRecordRecordDao = database.downloadRecordRecordDao;
    filePasswordDao = database.filePasswordDao;
    serverDao = database.serverDao;
    fileViewingRecordDao = database.fileViewingRecordDao;
    favoriteDao = database.favoriteDao;
  }
}
