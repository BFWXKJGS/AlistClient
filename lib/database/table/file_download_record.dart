import 'package:floor/floor.dart';

@Entity(tableName: "file_download_record")
class FileDownloadRecord {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  @ColumnInfo(name: 'server_url')
  final String serverUrl;

  @ColumnInfo(name: 'user_id')
  final String userId;

  @ColumnInfo(name: 'remote_path')
  final String remotePath;

  @ColumnInfo(name: 'sign')
  final String sign;

  @ColumnInfo(name: 'name')
  final String name;

  @ColumnInfo(name: 'local_path')
  final String localPath;

  @ColumnInfo(name: 'create_time')
  final int createTime;

  FileDownloadRecord({
    this.id,
    required this.serverUrl,
    required this.userId,
    required this.remotePath,
    required this.sign,
    required this.name,
    required this.localPath,
    required this.createTime,
  });
}
