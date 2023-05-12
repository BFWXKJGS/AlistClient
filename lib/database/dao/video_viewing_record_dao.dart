import 'package:alist/database/table/video_viewing_record.dart';
import 'package:floor/floor.dart';

@dao
abstract class VideoViewingRecordDao {
  @insert
  Future<int> insertRecord(VideoViewingRecord record);

  @update
  Future<int> updateRecord(VideoViewingRecord record);

  @Query(
      "SELECT * FROM video_viewing_record WHERE server_url = :serverUrl AND user_id=:userId AND video_sign=:sign LIMIT 1")
  Future<VideoViewingRecord?> findRecordBySign(
    String serverUrl,
    String userId,
    String sign,
  );

  @Query(
      "SELECT * FROM video_viewing_record WHERE server_url = :serverUrl AND user_id=:userId AND path=:path LIMIT 1")
  Future<VideoViewingRecord?> findRecordByPath(
      String serverUrl,
      String userId,
      String path,
      );
}
