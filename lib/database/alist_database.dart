// database.dart

import 'dart:async';

import 'package:alist/database/dao/file_download_record_dao.dart';
import 'package:alist/database/dao/file_password_dao.dart';
import 'package:alist/database/dao/file_viewing_record_dao.dart';
import 'package:alist/database/dao/server_dao.dart';
import 'package:alist/database/table/file_download_record.dart';
import 'package:alist/database/table/file_password.dart';
import 'package:alist/database/table/file_viewing_record.dart';
import 'package:alist/database/table/server.dart';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'dao/video_viewing_record_dao.dart';
import 'table/video_viewing_record.dart';

part 'alist_database.g.dart'; // the generated code will be there

@Database(version: 3, entities: [
  VideoViewingRecord,
  FileDownloadRecord,
  FilePassword,
  Server,
  FileViewingRecord
])
abstract class AlistDatabase extends FloorDatabase {
  VideoViewingRecordDao get videoViewingRecordDao;

  FileDownloadRecordRecordDao get downloadRecordRecordDao;

  FilePasswordDao get filePasswordDao;

  ServerDao get serverDao;

  FileViewingRecordDao get fileViewingRecordDao;
}
