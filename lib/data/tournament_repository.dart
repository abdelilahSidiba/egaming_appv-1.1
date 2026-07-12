import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/enums.dart';
import '../models/match_model.dart';
import '../models/team.dart';
import '../models/tournament.dart';

class TournamentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// يحفظ البطولة كاملة (بطولة + فرق + مباريات) داخل معاملة واحدة (Transaction)
  /// حتى لا تُحفظ بيانات جزئية في حال حدوث خطأ أثناء الحفظ (الفصل 5.4 - 5.8)
  Future<void> createFullTournament({
    required Tournament tournament,
    required List<Team> teams,
    required List<MatchModel> matches,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final tMap = tournament.toMap();
      final rulesMap = tMap.remove('rules') as Map<String, dynamic>;
      tMap['rulesJson'] = _dbHelper.encodeRules(rulesMap);
      await txn.insert('tournaments', tMap);

      final teamBatch = txn.batch();
      for (final team in teams) {
        teamBatch.insert('teams', team.toMap());
      }
      await teamBatch.commit(noResult: true);

      final matchBatch = txn.batch();
      for (final match in matches) {
        matchBatch.insert('matches', match.toMap());
      }
      await matchBatch.commit(noResult: true);
    });
  }

  Future<List<Tournament>> getAll({TournamentStatus? status, String? searchQuery}) async {
    final db = await _dbHelper.database;
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (status != null) {
      whereClauses.add('status = ?');
      whereArgs.add(status.name);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('name LIKE ?');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    final maps = await db.query(
      'tournaments',
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereClauses.isEmpty ? null : whereArgs,
      orderBy: 'createdAt DESC',
    );

    return maps.map((m) {
      final rulesJson = m['rulesJson'] as String;
      final rulesMap = _dbHelper.decodeRules(rulesJson);
      return Tournament.fromMap(m, rulesMap);
    }).toList();
  }

  Future<Tournament?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('tournaments', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final rulesMap = _dbHelper.decodeRules(maps.first['rulesJson'] as String);
    return Tournament.fromMap(maps.first, rulesMap);
  }

  Future<void> update(Tournament tournament) async {
    final db = await _dbHelper.database;
    final tMap = tournament.toMap();
    final rulesMap = tMap.remove('rules') as Map<String, dynamic>;
    tMap['rulesJson'] = _dbHelper.encodeRules(rulesMap);
    await db.update('tournaments', tMap, where: 'id = ?', whereArgs: [tournament.id]);
  }

  /// حذف بطولة بالكامل (الفرق والمباريات تُحذف تلقائيًا عبر ON DELETE CASCADE)
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('tournaments', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertMatches(List<MatchModel> matches) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final m in matches) {
      batch.insert('matches', m.toMap());
    }
    await batch.commit(noResult: true);
  }
}
