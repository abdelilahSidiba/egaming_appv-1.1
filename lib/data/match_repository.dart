import '../database/database_helper.dart';
import '../models/enums.dart';
import '../models/match_model.dart';

class MatchRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<MatchModel>> getByTournament(String tournamentId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'matches',
      where: 'tournamentId = ?',
      whereArgs: [tournamentId],
      orderBy: 'round ASC',
    );
    return maps.map((m) => MatchModel.fromMap(m)).toList();
  }

  Future<List<MatchModel>> getByRound({
    required String tournamentId,
    required int round,
    String? groupName,
  }) async {
    final db = await _dbHelper.database;
    final whereClauses = ['tournamentId = ?', 'round = ?'];
    final whereArgs = <Object?>[tournamentId, round];
    if (groupName != null) {
      whereClauses.add('groupName = ?');
      whereArgs.add(groupName);
    }
    final maps = await db.query(
      'matches',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
    );
    return maps.map((m) => MatchModel.fromMap(m)).toList();
  }

  Future<List<MatchModel>> getByStage({
    required String tournamentId,
    required TournamentStage stage,
  }) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'matches',
      where: 'tournamentId = ? AND stage = ?',
      whereArgs: [tournamentId, stage.name],
    );
    return maps.map((m) => MatchModel.fromMap(m)).toList();
  }

  Future<void> insertAll(List<MatchModel> matches) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final m in matches) {
      batch.insert('matches', m.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> update(MatchModel match) async {
    final db = await _dbHelper.database;
    await db.update('matches', match.toMap(),
        where: 'id = ?', whereArgs: [match.id]);
  }

  Future<void> deleteByRound(String tournamentId, int round) async {
    final db = await _dbHelper.database;
    await db.delete(
      'matches',
      where: 'tournamentId = ? AND round = ?',
      whereArgs: [tournamentId, round],
    );
  }

  /// كل مباريات فريق معيّن المنتهية (يُستخدم لحساب إحصائيات اللاعب التراكمية)
  /// معرّف الفريق فريد عالميًا (يحتوي على tournamentId داخل تركيبته) لذا لا
  /// حاجة لتمرير tournamentId هنا.
  Future<List<MatchModel>> getByTeam(String teamId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'matches',
      where: '(homeTeamId = ? OR awayTeamId = ?) AND status = ?',
      whereArgs: [teamId, teamId, MatchStatus.played.name],
    );
    return maps.map((m) => MatchModel.fromMap(m)).toList();
  }
}
