import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/player.dart';

/// مستودع اللاعبين — الوسيط الوحيد بين قاعدة البيانات ونماذج [Player]
/// (الفصل 2 بالكامل)
class PlayerRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Player>> getAll({String? searchQuery}) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> maps;
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      maps = await db.query(
        'players',
        where: 'name LIKE ?',
        whereArgs: ['%${searchQuery.trim()}%'],
        orderBy: 'name ASC',
      );
    } else {
      maps = await db.query('players', orderBy: 'name ASC');
    }
    return maps.map((m) => Player.fromMap(m)).toList();
  }

  Future<Player?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('players', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Player.fromMap(maps.first);
  }

  /// هل يوجد لاعب بنفس الاسم؟ (الفصل 2.6 — لا يمنع الإنشاء، فقط يُنبّه)
  Future<bool> existsByName(String name) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'players',
      where: 'name = ?',
      whereArgs: [name.trim()],
    );
    return maps.isNotEmpty;
  }

  Future<void> insert(Player player) async {
    final db = await _dbHelper.database;
    await db.insert('players', player.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(Player player) async {
    final db = await _dbHelper.database;
    await db.update('players', player.toMap(),
        where: 'id = ?', whereArgs: [player.id]);
  }

  /// هل يشارك هذا اللاعب في أي بطولة "جارية" حاليًا؟ (الفصل 2.8)
  Future<bool> isInActiveTournament(String playerId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as cnt
      FROM teams t
      INNER JOIN tournaments tour ON t.tournamentId = tour.id
      WHERE t.playerId = ? AND tour.status = 'ongoing'
    ''', [playerId]);
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  /// حذف اللاعب — يفشل بصمت (يُرجع false) إذا كان يشارك في بطولة جارية
  Future<bool> delete(String id) async {
    final active = await isInActiveTournament(id);
    if (active) return false;
    final db = await _dbHelper.database;
    await db.delete('players', where: 'id = ?', whereArgs: [id]);
    return true;
  }

  /// عدد البطولات التي شارك بها اللاعب فعليًا (فرق مختلفة عبر بطولات مختلفة)
  Future<int> countTournamentsFor(String playerId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COUNT(DISTINCT tournamentId) as cnt FROM teams WHERE playerId = ?
    ''', [playerId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
