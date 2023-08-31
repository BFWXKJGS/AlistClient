import 'package:alist/database/table/favorite.dart';
import 'package:floor/floor.dart';

@dao
abstract class FavoriteDao {
  @insert
  Future<int> insertRecord(Favorite favorite);

  @update
  Future<int> updateRecord(Favorite favorite);

  @delete
  Future<int> deleteRecord(Favorite favorite);

  @Query(
      "SELECT * FROM favorite WHERE server_url = :serverUrl AND user_id=:userId AND path=:path LIMIT 1")
  Future<Favorite?> findByPath(
    String serverUrl,
    String userId,
    String path,
  );

  @Query(
      "SELECT * FROM favorite WHERE server_url = :serverUrl AND user_id=:userId ORDER BY id DESC")
  Stream<List<Favorite>?> list(
    String serverUrl,
    String userId,
  );

  @Query("SELECT COUNT(id) FROM favorite")
  Stream<int?> countStream();

  @Query(
      "DELETE FROM favorite WHERE server_url = :serverUrl AND user_id=:userId AND remote_path=:remotePath")
  Future<void> deleteByPath(
    String serverUrl,
    String userId,
    String remotePath,
  );
}
