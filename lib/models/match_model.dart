import 'enums.dart';

/// نموذج المباراة (الفصل 5.13 / 6)
/// اسم الملف match_model.dart لتجنب تعارض مع مكتبة dart:core الاسم "Match"
class MatchModel {
  final String id;
  final String tournamentId;
  final TournamentStage stage;
  final String? groupName; // في حال كانت المباراة ضمن مجموعة
  final int round; // رقم الجولة داخل مرحلتها
  final int leg; // 1 = ذهاب، 2 = إياب (للمباريات الإقصائية المزدوجة)

  final String homeTeamId;
  final String awayTeamId;

  int? homeGoals;
  int? awayGoals;

  // ركلات الترجيح (الفصل 4.8)
  int? homePenalties;
  int? awayPenalties;
  bool wentToExtraTime;

  MatchStatus status;
  DateTime? scheduledDate;
  bool isPostponed;

  /// معرّف المباراة "الزوجية" (الإياب) إن وجدت، لحساب المجموع التراكمي
  String? pairedMatchId;

  MatchModel({
    required this.id,
    required this.tournamentId,
    required this.stage,
    this.groupName,
    required this.round,
    this.leg = 1,
    required this.homeTeamId,
    required this.awayTeamId,
    this.homeGoals,
    this.awayGoals,
    this.homePenalties,
    this.awayPenalties,
    this.wentToExtraTime = false,
    this.status = MatchStatus.notPlayed,
    this.scheduledDate,
    this.isPostponed = false,
    this.pairedMatchId,
  });

  bool get isBye => homeTeamId == '__BYE__' || awayTeamId == '__BYE__';

  bool get hasPenalties => homePenalties != null && awayPenalties != null;

  /// الفائز في هذه المباراة فقط (وليس بالضرورة المتأهل في حال الذهاب والإياب)
  String? get winnerTeamId {
    if (status != MatchStatus.played) return null;
    if (homeGoals == null || awayGoals == null) return null;
    if (homeGoals! > awayGoals!) return homeTeamId;
    if (awayGoals! > homeGoals!) return awayTeamId;
    // تعادل بالنتيجة العادية -> نرجع لركلات الترجيح إن وجدت
    if (hasPenalties) {
      return homePenalties! > awayPenalties! ? homeTeamId : awayTeamId;
    }
    return null; // تعادل حقيقي (في بطولات الدوري)
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'tournamentId': tournamentId,
        'stage': stage.name,
        'groupName': groupName,
        'round': round,
        'leg': leg,
        'homeTeamId': homeTeamId,
        'awayTeamId': awayTeamId,
        'homeGoals': homeGoals,
        'awayGoals': awayGoals,
        'homePenalties': homePenalties,
        'awayPenalties': awayPenalties,
        'wentToExtraTime': wentToExtraTime ? 1 : 0,
        'status': status.name,
        'scheduledDate': scheduledDate?.toIso8601String(),
        'isPostponed': isPostponed ? 1 : 0,
        'pairedMatchId': pairedMatchId,
      };

  factory MatchModel.fromMap(Map<String, dynamic> map) => MatchModel(
        id: map['id'] as String,
        tournamentId: map['tournamentId'] as String,
        stage: TournamentStage.values.firstWhere((e) => e.name == map['stage']),
        groupName: map['groupName'] as String?,
        round: map['round'] as int,
        leg: map['leg'] as int? ?? 1,
        homeTeamId: map['homeTeamId'] as String,
        awayTeamId: map['awayTeamId'] as String,
        homeGoals: map['homeGoals'] as int?,
        awayGoals: map['awayGoals'] as int?,
        homePenalties: map['homePenalties'] as int?,
        awayPenalties: map['awayPenalties'] as int?,
        wentToExtraTime: (map['wentToExtraTime'] as int? ?? 0) == 1,
        status: MatchStatus.values.firstWhere((e) => e.name == map['status']),
        scheduledDate: map['scheduledDate'] != null
            ? DateTime.parse(map['scheduledDate'] as String)
            : null,
        isPostponed: (map['isPostponed'] as int? ?? 0) == 1,
        pairedMatchId: map['pairedMatchId'] as String?,
      );
}
