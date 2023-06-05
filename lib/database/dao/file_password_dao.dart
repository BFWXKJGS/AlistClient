import 'package:alist/database/table/file_download_record.dart';
import 'package:alist/database/table/file_password.dart';
import 'package:floor/floor.dart';

@dao
abstract class FilePasswordDao {
  @insert
  Future<int> insertFilePassword(FilePassword filePassword);

  @update
  Future<int> updateFilePassword(FilePassword filePassword);

  @delete
  Future<int> deleteFilePassword(FilePassword filePassword);

  @Query("DELETE FROM file_password WHERE server_url = :serverUrl AND user_id=:userId AND remote_path=:remotePath")
  Future<void> deleteByPath(String serverUrl, String userId, String remotePath);

  @Query(
      "SELECT * FROM file_password WHERE server_url = :serverUrl AND user_id=:userId AND remote_path=:remotePath ORDER BY id DESC LIMIT 1")
  Future<FilePassword?> findPasswordByPath(
    String serverUrl,
    String userId,
    String remotePath,
  );
}
