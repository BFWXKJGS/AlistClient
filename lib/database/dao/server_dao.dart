import 'package:alist/database/table/server.dart';
import 'package:floor/floor.dart';

@dao
abstract class ServerDao {
  @insert
  Future<int> insertServer(Server server);

  @update
  Future<int> updateServer(Server server);

  @delete
  Future<int> deleteServer(Server server);

  @Query(
      "SELECT * FROM server WHERE server_url = :serverUrl AND user_id=:userId LIMIT 1")
  Future<Server?> findServer(String serverUrl, String userId);

  @Query("SELECT * FROM server ORDER BY id desc LIMIT 100")
  Stream<List<Server>?> serverList();
}
