import 'package:alist/database/alist_database.dart';
import 'package:alist/database/dao/video_viewing_record_dao.dart';
import 'package:get/get.dart';

class AlistDatabaseController extends GetxController {
  late AlistDatabase database;
  late VideoViewingRecordDao recordDao;

  Future<void> init() async {
    database = await $FloorAlistDatabase.databaseBuilder('alist.db').build();
    recordDao = database.recordDao;
  }
}
