import 'package:alist/database/table/video_viewing_record.dart';
import 'package:floor/floor.dart';

@dao
abstract class VideoViewingRecordDao {
  @insert
  Future<int> insertRecord(VideoViewingRecord record);

  @update
  Future<int> updateRecord(VideoViewingRecord record);

  @delete
  Future<void> deleteRecord(VideoViewingRecord record);

  @Query(
      "SELECT * FROM video_viewing_record WHERE server_url = :serverUrl AND user_id=:userId AND path=:path LIMIT 1")
  Future<VideoViewingRecord?> findRecordByPath(
    String serverUrl,
    String userId,
    String path,
  );
}
