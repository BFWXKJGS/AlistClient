import 'package:floor/floor.dart';

@Entity(tableName: "server")
class Server {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  @ColumnInfo(name: 'name')
  final String name;

  @ColumnInfo(name: 'server_url')
  final String serverUrl;

  @ColumnInfo(name: 'user_id')
  final String userId;

  @ColumnInfo(name: 'password')
  final String password;

  @ColumnInfo(name: 'token')
  final String token;

  @ColumnInfo(name: 'guest')
  final bool guest;

  @ColumnInfo(name: 'ignore_ssl_error')
  final bool ignoreSSLError;

  @ColumnInfo(name: 'create_time')
  final int createTime;

  @ColumnInfo(name: 'update_time')
  final int updateTime;

  Server({
    this.id,
    required this.name,
    required this.serverUrl,
    required this.userId,
    required this.password,
    required this.token,
    required this.guest,
    required this.ignoreSSLError,
    required this.createTime,
    required this.updateTime,
  });
}
