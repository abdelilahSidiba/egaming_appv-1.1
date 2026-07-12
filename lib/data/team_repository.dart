import '../database/database_helper.dart';
import '../models/team.dart';

class TeamRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Team?> getById(String teamId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('teams', where: 'id = ?', whereArgs: [teamId]);
    if (maps.isEmpty) return null;
    return Team.fromMap(maps.first);
  }

  Future<List<Team>> getByTournament(String tournamentId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'teams',
      where: 'tournamentId = ?',
      whereArgs: [tournamentId],
      orderBy: 'seed ASC',
    );
    return maps.map((m) => Team.fromMap(m)).toList();
  }

  Future<List<Team>> getByPlayer(String playerId) async {
    final db = await _dbHelper.database;
    final maps =
        await db.query('teams', where: 'playerId = ?', whereArgs: [playerId]);
    return maps.map((m) => Team.fromMap(m)).toList();
  }

  Future<void> insertAll(List<Team> teams) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final team in teams) {
      batch.insert('teams', team.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> update(Team team) async {
    final db = await _dbHelper.database;
    await db.update('teams', team.toMap(), where: 'id = ?', whereArgs: [team.id]);
  }
}
