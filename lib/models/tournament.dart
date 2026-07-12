import 'enums.dart';
import 'tournament_rules.dart';

/// نموذج البطولة (الفصل 5.4)
class Tournament {
  final String id;
  String name;
  final TournamentType type;
  final TournamentFormat format;
  String? logoAssetPath;
  String primaryColorHex;
  String? secondaryColorHex;
  final DateTime createdAt;
  DateTime? startDate;
  DateTime? finishedAt;
  String? notes;
  TournamentStatus status;
  TournamentRules rules;

  int currentRound;
  int totalRounds;

  // نتائج نهائية (الفصل 5.16)
  String? championPlayerId;
  String? runnerUpPlayerId;
  String? thirdPlacePlayerId;

  // هل لاعب واحد يتحكم بأكثر من فريق؟ (الفصل 3.8/3.10)
  bool allowsMultiTeamPerPlayer;

  Tournament({
    required this.id,
    required this.name,
    required this.type,
    required this.format,
    this.logoAssetPath,
    this.primaryColorHex = '#1565C0',
    this.secondaryColorHex,
    DateTime? createdAt,
    this.startDate,
    this.finishedAt,
    this.notes,
    this.status = TournamentStatus.notStarted,
    required this.rules,
    this.currentRound = 0,
    this.totalRounds = 0,
    this.championPlayerId,
    this.runnerUpPlayerId,
    this.thirdPlacePlayerId,
    this.allowsMultiTeamPerPlayer = false,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progressPercent =>
      totalRounds == 0 ? 0 : (currentRound / totalRounds * 100).clamp(0, 100);

  /// هوية البطولة اللونية الافتراضية (الفصل 9.6)
  static String defaultColorFor(TournamentType type) {
    switch (type) {
      case TournamentType.worldCup:
        return '#D4AF37'; // ذهبي
      case TournamentType.uclOldFormat:
      case TournamentType.uclNewFormat:
        return '#0A1F44'; // أزرق غامق
      case TournamentType.laLiga:
        return '#C8102E'; // أحمر
      case TournamentType.premierLeague:
        return '#3D195B'; // بنفسجي
      case TournamentType.serieA:
        return '#004C99'; // أزرق
      case TournamentType.bundesliga:
        return '#8B0000'; // أحمر داكن
      case TournamentType.ligue1:
        return '#1E90FF'; // أزرق فاتح
      case TournamentType.africaCup:
        return '#009639'; // أخضر
      case TournamentType.copaAmerica:
        return '#FDB913';
      case TournamentType.europeCup:
        return '#003399';
      default:
        return '#1565C0';
    }
  }

  static String defaultNameFor(TournamentType type) {
    switch (type) {
      case TournamentType.worldCup:
        return 'كأس العالم FIFA';
      case TournamentType.africaCup:
        return 'كأس أمم إفريقيا';
      case TournamentType.europeCup:
        return 'كأس أمم أوروبا';
      case TournamentType.copaAmerica:
        return 'كوبا أمريكا';
      case TournamentType.uclOldFormat:
        return 'دوري أبطال أوروبا (النظام القديم)';
      case TournamentType.uclNewFormat:
        return 'دوري أبطال أوروبا (النظام الجديد)';
      case TournamentType.laLiga:
        return 'الدوري الإسباني';
      case TournamentType.premierLeague:
        return 'الدوري الإنجليزي';
      case TournamentType.serieA:
        return 'الدوري الإيطالي';
      case TournamentType.bundesliga:
        return 'الدوري الألماني';
      case TournamentType.ligue1:
        return 'الدوري الفرنسي';
      case TournamentType.customLeague:
        return 'دوري مخصص';
      case TournamentType.customCup:
        return 'كأس مخصصة';
      case TournamentType.customGroupsKnockout:
        return 'مجموعات + خروج مغلوب';
    }
  }

  static TournamentFormat formatFor(TournamentType type) {
    switch (type) {
      case TournamentType.laLiga:
      case TournamentType.premierLeague:
      case TournamentType.serieA:
      case TournamentType.bundesliga:
      case TournamentType.ligue1:
      case TournamentType.customLeague:
        return TournamentFormat.league;
      case TournamentType.customCup:
        return TournamentFormat.cup;
      case TournamentType.worldCup:
      case TournamentType.africaCup:
      case TournamentType.europeCup:
      case TournamentType.copaAmerica:
      case TournamentType.uclOldFormat:
      case TournamentType.customGroupsKnockout:
        return TournamentFormat.groupsThenKnockout;
      case TournamentType.uclNewFormat:
        return TournamentFormat.swissThenKnockout;
    }
  }

  /// العدد الحقيقي للفرق في البطولات الرسمية (الفصل 3.3)
  static int? officialTeamCount(TournamentType type) {
    switch (type) {
      case TournamentType.worldCup:
        return 32;
      case TournamentType.africaCup:
        return 24;
      case TournamentType.europeCup:
        return 24;
      case TournamentType.copaAmerica:
        return 16;
      case TournamentType.uclOldFormat:
        return 32;
      case TournamentType.uclNewFormat:
        return 36;
      case TournamentType.laLiga:
      case TournamentType.serieA:
        return 20;
      case TournamentType.premierLeague:
        return 20;
      case TournamentType.bundesliga:
        return 18;
      case TournamentType.ligue1:
        return 18;
      default:
        return null; // مخصصة: يحددها المستخدم
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'format': format.name,
        'logoAssetPath': logoAssetPath,
        'primaryColorHex': primaryColorHex,
        'secondaryColorHex': secondaryColorHex,
        'createdAt': createdAt.toIso8601String(),
        'startDate': startDate?.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'notes': notes,
        'status': status.name,
        'rules': rules.toMap(),
        'currentRound': currentRound,
        'totalRounds': totalRounds,
        'championPlayerId': championPlayerId,
        'runnerUpPlayerId': runnerUpPlayerId,
        'thirdPlacePlayerId': thirdPlacePlayerId,
        'allowsMultiTeamPerPlayer': allowsMultiTeamPerPlayer ? 1 : 0,
      };

  factory Tournament.fromMap(
      Map<String, dynamic> map, Map<String, dynamic> rulesMap) {
    return Tournament(
      id: map['id'] as String,
      name: map['name'] as String,
      type: TournamentType.values.firstWhere((e) => e.name == map['type']),
      format:
          TournamentFormat.values.firstWhere((e) => e.name == map['format']),
      logoAssetPath: map['logoAssetPath'] as String?,
      primaryColorHex: map['primaryColorHex'] as String? ?? '#1565C0',
      secondaryColorHex: map['secondaryColorHex'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'] as String)
          : null,
      finishedAt: map['finishedAt'] != null
          ? DateTime.parse(map['finishedAt'] as String)
          : null,
      notes: map['notes'] as String?,
      status:
          TournamentStatus.values.firstWhere((e) => e.name == map['status']),
      rules: TournamentRules.fromMap(rulesMap),
      currentRound: map['currentRound'] as int? ?? 0,
      totalRounds: map['totalRounds'] as int? ?? 0,
      championPlayerId: map['championPlayerId'] as String?,
      runnerUpPlayerId: map['runnerUpPlayerId'] as String?,
      thirdPlacePlayerId: map['thirdPlacePlayerId'] as String?,
      allowsMultiTeamPerPlayer:
          (map['allowsMultiTeamPerPlayer'] as int? ?? 0) == 1,
    );
  }
}
