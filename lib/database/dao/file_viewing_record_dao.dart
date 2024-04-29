import 'package:alist/database/table/file_viewing_record.dart';
import 'package:floor/floor.dart';

@dao
abstract class FileViewingRecordDao {
  @insert
  Future<int> insertRecord(FileViewingRecord record);

  @update
  Future<int> updateRecord(FileViewingRecord record);

  @update
  Future<int> updateRecords(List<FileViewingRecord> record);

  @delete
  Future<int> deleteRecord(FileViewingRecord record);

  @Query(
      "SELECT * FROM file_viewing_record WHERE server_url = :serverUrl AND user_id=:userId ORDER BY id DESC LIMIT 100")
  Stream<List<FileViewingRecord>?> recordList(
    String serverUrl,
    String userId,
  );

  @Query(
      "DELETE FROM file_viewing_record WHERE server_url = :serverUrl AND user_id=:userId AND remote_path=:remotePath")
  Future<void> deleteByPath(
    String serverUrl,
    String userId,
    String remotePath,
  );
}
