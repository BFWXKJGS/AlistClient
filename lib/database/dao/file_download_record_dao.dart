import 'package:alist/database/table/file_download_record.dart';
import 'package:floor/floor.dart';

@dao
abstract class FileDownloadRecordRecordDao {
  @insert
  Future<int> insertRecord(FileDownloadRecord record);

  @update
  Future<int> updateRecord(FileDownloadRecord record);

  @delete
  Future<int> deleteRecord(FileDownloadRecord record);

  @Query("DELETE FROM file_download_record WHERE id = :id")
  Future<int?> deleteById(int id);

  @Query(
      "SELECT * FROM file_download_record WHERE server_url = :serverUrl AND user_id=:userId AND sign=:sign LIMIT 1")
  Future<FileDownloadRecord?> findRecordBySign(
    String serverUrl,
    String userId,
    String sign,
  );

  @Query(
      "SELECT * FROM file_download_record WHERE server_url = :serverUrl AND user_id=:userId AND remote_path=:remotePath LIMIT 1")
  Future<FileDownloadRecord?> findRecordByRemotePath(
    String serverUrl,
    String userId,
    String remotePath,
  );

  @Query(
      "SELECT * FROM file_download_record WHERE server_url = :serverUrl AND user_id=:userId ORDER BY id DESC")
  Future<List<FileDownloadRecord>?> findAll(String serverUrl, String userId);

  @Query(
      "UPDATE file_download_record SET local_path = :newLocalPath WHERE id = :id")
  Future<void> updateLocalPath(int id, String newLocalPath);
}
