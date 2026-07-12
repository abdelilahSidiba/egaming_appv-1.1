import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';

/// أسماء كل الجداول المشمولة بالنسخ الاحتياطي (الفصل 10.8)
const _backupTables = [
  'players',
  'tournaments',
  'teams',
  'matches',
  'standings_history',
  'rule_templates',
  'seasons',
  'season_tournaments',
  'achievements',
];

/// خدمة النسخ الاحتياطي الكامل واستعادته (الفصل 10.8 / 10.9)
/// يعمل بالكامل محليًا دون أي اتصال بالإنترنت — كل البيانات تُحفظ داخل
/// ملف JSON واحد بامتداد eGaming.egaming
class BackupService {
  final _dbHelper = DatabaseHelper.instance;

  /// ينشئ ملف نسخة احتياطية كاملة ويُرجع مسار الملف الناتج
  Future<File> createBackup() async {
    final db = await _dbHelper.database;
    final backupData = <String, dynamic>{
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'tables': <String, dynamic>{},
    };

    for (final table in _backupTables) {
      final rows = await db.query(table);
      backupData['tables'][table] = rows;
    }

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'eGaming_Backup_${DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now())}.egaming';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(jsonEncode(backupData));
    return file;
  }

  /// يستعيد نسخة احتياطية من ملف — يستبدل كل البيانات الحالية بالكامل
  /// (الفصل 10.9: "سيتم استبدال جميع البيانات الحالية")
  Future<void> restoreBackup(File file) async {
    final content = await file.readAsString();
    final backupData = jsonDecode(content) as Map<String, dynamic>;
    final tables = backupData['tables'] as Map<String, dynamic>;

    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // نحذف كل البيانات الحالية أولاً (بترتيب يحترم العلاقات الأجنبية)
      for (final table in _backupTables.reversed) {
        await txn.delete(table);
      }
      // ثم نُدرج بيانات النسخة الاحتياطية (بالترتيب الطبيعي)
      for (final table in _backupTables) {
        final rows = (tables[table] as List?) ?? [];
        for (final row in rows) {
          await txn.insert(table, Map<String, dynamic>.from(row as Map));
        }
      }
    });
  }

  /// إحصائيات سريعة تُعرض في صفحة الإعدادات (الفصل 10.2)
  Future<Map<String, int>> getAppInfoCounts() async {
    final db = await _dbHelper.database;
    final players = await db.rawQuery('SELECT COUNT(*) as cnt FROM players');
    final tournaments = await db.rawQuery('SELECT COUNT(*) as cnt FROM tournaments');
    return {
      'players': (players.first['cnt'] as int?) ?? 0,
      'tournaments': (tournaments.first['cnt'] as int?) ?? 0,
    };
  }

  /// حذف كل بيانات التطبيق والعودة لحالة ما بعد التثبيت مباشرة (الفصل 10.12)
  Future<void> resetApp() async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (final table in _backupTables.reversed) {
        await txn.delete(table);
      }
    });
  }
}
