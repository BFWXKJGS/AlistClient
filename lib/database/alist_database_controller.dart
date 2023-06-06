import 'package:alist/database/alist_database.dart';
import 'package:alist/database/dao/file_download_record_dao.dart';
import 'package:alist/database/dao/file_password_dao.dart';
import 'package:alist/database/dao/file_viewing_record_dao.dart';
import 'package:alist/database/dao/server_dao.dart';
import 'package:alist/database/dao/video_viewing_record_dao.dart';
import 'package:alist/database/table/file_password.dart';
import 'package:floor/floor.dart';
import 'package:get/get.dart';

class AlistDatabaseController extends GetxController {
  late AlistDatabase database;
  late VideoViewingRecordDao videoViewingRecordDao;
  late FileDownloadRecordRecordDao downloadRecordRecordDao;
  late FilePasswordDao filePasswordDao;
  late ServerDao serverDao;
  late FileViewingRecordDao fileViewingRecordDao;

  // create migration
  final migration1to2 = Migration(1, 2, (database) async {
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
  final migration2to3 = Migration(2, 3, (database) async {
    await database.execute(
        'ALTER TABLE `file_viewing_record` ADD COLUMN `path` TEXT NOT NULL DEFAULT ""');
    await database.execute(
        'ALTER TABLE `file_viewing_record` MODIFY `modified` INTEGER NOT NULL');
  });

  Future<void> init() async {
    database = await $FloorAlistDatabase
        .databaseBuilder('alist.db')
        .addMigrations([migration1to2, migration2to3]).build();
    videoViewingRecordDao = database.videoViewingRecordDao;
    downloadRecordRecordDao = database.downloadRecordRecordDao;
    filePasswordDao = database.filePasswordDao;
    serverDao = database.serverDao;
    fileViewingRecordDao = database.fileViewingRecordDao;
  }
}
