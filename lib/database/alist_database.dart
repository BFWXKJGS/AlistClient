// database.dart

import 'dart:async';

import 'package:floor/floor.dart';

import 'dao/video_viewing_record_dao.dart';
import 'table/video_viewing_record.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'alist_database.g.dart';// the generated code will be there

@Database(version: 1, entities: [VideoViewingRecord])
abstract class AlistDatabase extends FloorDatabase {
  VideoViewingRecordDao get recordDao;
}