import 'package:floor/floor.dart';

@Entity(tableName: "file_password")
class FilePassword {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  @ColumnInfo(name: 'server_url')
  final String serverUrl;

  @ColumnInfo(name: 'user_id')
  final String userId;

  @ColumnInfo(name: 'remote_path')
  final String remotePath;

  @ColumnInfo(name: 'password')
  final String password;

  @ColumnInfo(name: 'create_time')
  final int createTime;

  FilePassword({
    this.id,
    required this.serverUrl,
    required this.userId,
    required this.remotePath,
    required this.password,
    required this.createTime,
  });
}
