import 'package:floor/floor.dart';

@Entity(tableName: "video_viewing_record")
class VideoViewingRecord {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  @ColumnInfo(name: 'server_url')
  final String serverUrl;

  @ColumnInfo(name: 'user_id')
  final String userId;

  @ColumnInfo(name: 'video_sign')
  final String videoSign;

  @ColumnInfo(name: 'path')
  final String path;

  @ColumnInfo(name: 'video_duration')
  final int videoDuration;

  @ColumnInfo(name: 'video_current_position')
  final int videoCurrentPosition;

  VideoViewingRecord({
    this.id,
    required this.serverUrl,
    required this.userId,
    required this.videoSign,
    required this.path,
    required this.videoDuration,
    required this.videoCurrentPosition,
  });
}
