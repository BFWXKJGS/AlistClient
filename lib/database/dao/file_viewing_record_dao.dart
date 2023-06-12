import 'package:alist/database/table/file_download_record.dart';
import 'package:alist/database/table/file_viewing_record.dart';
import 'package:floor/floor.dart';

@dao
abstract class FileViewingRecordDao {
  @insert
  Future<int> insertRecord(FileViewingRecord record);

  @update
  Future<int> updateRecord(FileViewingRecord record);

  @delete
  Future<int> deleteRecord(FileViewingRecord record);

  @Query(
      "SELECT * FROM file_viewing_record WHERE server_url = :serverUrl AND user_id=:userId AND remote_path=:remotePath")
  Future<List<FileViewingRecord>?> findRecordByRemotePath(
    String serverUrl,
    String userId,
    String remotePath,
  );

  @Query("SELECT * FROM file_viewing_record ORDER BY id desc LIMIT 100")
  Future<List<FileViewingRecord>?> serverList();
}
