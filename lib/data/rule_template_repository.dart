import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/tournament_rules.dart';

class RuleTemplate {
  final String id;
  final String name;
  final TournamentRules rules;
  final DateTime createdAt;

  RuleTemplate({
    required this.id,
    required this.name,
    required this.rules,
    required this.createdAt,
  });
}

/// مستودع قوالب القوانين المخصصة (الفصل 4 — فكرة "حفظ كقالب")
/// مثال: "بطولة المقهى"، "دوري الأصدقاء"، "كأس رمضان"
class RuleTemplateRepository {
  final _dbHelper = DatabaseHelper.instance;
  static const _uuid = Uuid();

  Future<void> save(String name, TournamentRules rules) async {
    final db = await _dbHelper.database;
    await db.insert('rule_templates', {
      'id': _uuid.v4(),
      'name': name,
      'rulesJson': _dbHelper.encodeRules(rules.toMap()),
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<RuleTemplate>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('rule_templates', orderBy: 'createdAt DESC');
    return maps
        .map((m) => RuleTemplate(
              id: m['id'] as String,
              name: m['name'] as String,
              rules: TournamentRules.fromMap(_dbHelper.decodeRules(m['rulesJson'] as String)),
              createdAt: DateTime.parse(m['createdAt'] as String),
            ))
        .toList();
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('rule_templates', where: 'id = ?', whereArgs: [id]);
  }
}
