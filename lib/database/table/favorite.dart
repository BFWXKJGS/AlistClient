import 'package:floor/floor.dart';

@Entity(tableName: "favorite")
class Favorite {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  @ColumnInfo(name: 'is_dir')
  final bool isDir;

  @ColumnInfo(name: 'server_url')
  final String serverUrl;

  @ColumnInfo(name: 'user_id')
  final String userId;

  @ColumnInfo(name: 'remote_path')
  final String remotePath;

  @ColumnInfo(name: 'name')
  final String name;

  @ColumnInfo(name: 'size')
  final int size;

  @ColumnInfo(name: 'sign')
  final String? sign;

  @ColumnInfo(name: 'thumb')
  final String? thumb;

  @ColumnInfo(name: 'modified')
  final int modified;

  @ColumnInfo(name: 'provider')
  final String provider;

  @ColumnInfo(name: 'create_time')
  final int createTime;

  @ColumnInfo(name: 'path')
  final String path;

  Favorite({
    this.id,
    required this.isDir,
    required this.serverUrl,
    required this.userId,
    required this.remotePath,
    required this.name,
    required this.path,
    required this.size,
    required this.sign,
    required this.thumb,
    required this.modified,
    required this.provider,
    required this.createTime,
  });
}
