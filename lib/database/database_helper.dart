import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// المسؤول عن إنشاء وفتح قاعدة بيانات eGaming المحلية (الفصل 9.18 / 10)
/// يستخدم SQLite مع فهارس لتحسين سرعة البحث والتحديث حتى مع آلاف المباريات.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'egaming.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // اللاعبون (الفصل 2)
    batch.execute('''
      CREATE TABLE players (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        photoPath TEXT,
        logoAssetPath TEXT,
        colorHex TEXT,
        createdAt TEXT NOT NULL,
        tournamentsPlayed INTEGER DEFAULT 0,
        titlesWon INTEGER DEFAULT 0,
        runnerUpCount INTEGER DEFAULT 0,
        thirdPlaceCount INTEGER DEFAULT 0,
        matchesPlayed INTEGER DEFAULT 0,
        wins INTEGER DEFAULT 0,
        draws INTEGER DEFAULT 0,
        losses INTEGER DEFAULT 0,
        goalsFor INTEGER DEFAULT 0,
        goalsAgainst INTEGER DEFAULT 0,
        longestWinStreak INTEGER DEFAULT 0,
        currentWinStreak INTEGER DEFAULT 0
      )
    ''');
    batch.execute('CREATE INDEX idx_players_name ON players(name)');

    // البطولات (الفصل 5.4) - القوانين تُخزَّن كـ JSON داخل عمود rules
    batch.execute('''
      CREATE TABLE tournaments (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        format TEXT NOT NULL,
        logoAssetPath TEXT,
        primaryColorHex TEXT,
        secondaryColorHex TEXT,
        createdAt TEXT NOT NULL,
        startDate TEXT,
        finishedAt TEXT,
        notes TEXT,
        status TEXT NOT NULL,
        rulesJson TEXT NOT NULL,
        currentRound INTEGER DEFAULT 0,
        totalRounds INTEGER DEFAULT 0,
        championPlayerId TEXT,
        runnerUpPlayerId TEXT,
        thirdPlacePlayerId TEXT,
        allowsMultiTeamPerPlayer INTEGER DEFAULT 0
      )
    ''');
    batch.execute('CREATE INDEX idx_tournaments_status ON tournaments(status)');
    batch.execute('CREATE INDEX idx_tournaments_type ON tournaments(type)');

    // الفرق (الفصل 5.5)
    batch.execute('''
      CREATE TABLE teams (
        id TEXT PRIMARY KEY,
        tournamentId TEXT NOT NULL,
        name TEXT NOT NULL,
        logoAssetPath TEXT,
        playerId TEXT NOT NULL,
        playerNameSnapshot TEXT,
        colorHex TEXT,
        groupName TEXT,
        seed INTEGER DEFAULT 0,
        FOREIGN KEY (tournamentId) REFERENCES tournaments(id) ON DELETE CASCADE
      )
    ''');
    batch.execute('CREATE INDEX idx_teams_tournament ON teams(tournamentId)');
    batch.execute('CREATE INDEX idx_teams_player ON teams(playerId)');

    // المباريات (الفصل 5.7 / 6)
    batch.execute('''
      CREATE TABLE matches (
        id TEXT PRIMARY KEY,
        tournamentId TEXT NOT NULL,
        stage TEXT NOT NULL,
        groupName TEXT,
        round INTEGER NOT NULL,
        leg INTEGER DEFAULT 1,
        homeTeamId TEXT NOT NULL,
        awayTeamId TEXT NOT NULL,
        homeGoals INTEGER,
        awayGoals INTEGER,
        homePenalties INTEGER,
        awayPenalties INTEGER,
        wentToExtraTime INTEGER DEFAULT 0,
        status TEXT NOT NULL,
        scheduledDate TEXT,
        isPostponed INTEGER DEFAULT 0,
        pairedMatchId TEXT,
        FOREIGN KEY (tournamentId) REFERENCES tournaments(id) ON DELETE CASCADE
      )
    ''');
    batch.execute('CREATE INDEX idx_matches_tournament ON matches(tournamentId)');
    batch.execute('CREATE INDEX idx_matches_round ON matches(tournamentId, round)');
    batch.execute('CREATE INDEX idx_matches_stage ON matches(tournamentId, stage)');

    // لقطات الترتيب بعد كل جولة (الفصل 7.17 - سجل تطور الترتيب)
    batch.execute('''
      CREATE TABLE standings_history (
        id TEXT PRIMARY KEY,
        tournamentId TEXT NOT NULL,
        groupName TEXT,
        round INTEGER NOT NULL,
        standingsJson TEXT NOT NULL,
        FOREIGN KEY (tournamentId) REFERENCES tournaments(id) ON DELETE CASCADE
      )
    ''');
    batch.execute(
        'CREATE INDEX idx_standings_history ON standings_history(tournamentId, round)');

    // قوالب القوانين المخصصة (الفصل 4 - حفظ كقالب)
    batch.execute('''
      CREATE TABLE rule_templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        rulesJson TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // المواسم (الفصل 8 - فكرة موسم eGaming)
    batch.execute('''
      CREATE TABLE seasons (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        startedAt TEXT NOT NULL,
        endedAt TEXT
      )
    ''');
    batch.execute('''
      CREATE TABLE season_tournaments (
        seasonId TEXT NOT NULL,
        tournamentId TEXT NOT NULL,
        PRIMARY KEY (seasonId, tournamentId)
      )
    ''');

    // الإنجازات (الفصل 7 - سجل الإنجازات)
    batch.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        playerId TEXT NOT NULL,
        achievementKey TEXT NOT NULL,
        unlockedAt TEXT NOT NULL,
        tournamentId TEXT
      )
    ''');
    batch.execute('CREATE INDEX idx_achievements_player ON achievements(playerId)');

    await batch.commit(noResult: true);
  }

  /// تحويل مساعد: يفصل حقل rulesJson عن باقي أعمدة البطولة عند القراءة
  Map<String, dynamic> decodeRules(String rulesJson) =>
      jsonDecode(rulesJson) as Map<String, dynamic>;

  String encodeRules(Map<String, dynamic> rulesMap) => jsonEncode(rulesMap);

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
