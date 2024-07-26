import 'package:alist/database/dao/file_password_dao.dart';
import 'package:alist/database/table/file_password.dart';
import 'package:alist/util/string_utils.dart';
import 'package:alist/util/user_controller.dart';
import 'package:get/get.dart';

class FilePasswordHelper {
  static final FilePasswordHelper _singleton = FilePasswordHelper._();
  late FilePasswordDao _filePasswordDao;

  FilePasswordHelper._();

  factory FilePasswordHelper() {
    return _singleton;
  }

  void setFilePasswordDao(FilePasswordDao filePasswordDao) {
    _filePasswordDao = filePasswordDao;
  }

  Future<String?> fastFindPassword(String remotePath,
      {String? backupPassword}) async {
    final userController = Get.find<UserController>();
    final user = userController.user.value;
    return await findPasswordByPath(user.serverUrl, user.username, remotePath,
        backupPassword: backupPassword);
  }

  Future<String?> findPasswordByPath(
      String serverUrl, String userId, String remotePath,
      {String? backupPassword}) async {
    var path = remotePath;
    if (!path.startsWith("/")) {
      path = "/$path";
    }
    FilePassword? filePassword;
    if (backupPassword == null) {
      do {
        filePassword =
            await _filePasswordDao.findPasswordByPath(serverUrl, userId, path);
        if (filePassword == null) {
          path = path.substringBeforeLast("/")!;
        }
      } while (filePassword == null && path != "");
    } else {
      filePassword =
          await _filePasswordDao.findPasswordByPath(serverUrl, userId, path);
      if (filePassword == null) {
        return backupPassword;
      }
    }
    return filePassword?.password;
  }
}
