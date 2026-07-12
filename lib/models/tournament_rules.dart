import 'enums.dart';

/// محرك قوانين البطولة (الفصل 4 بالكامل)
/// كل بطولة رسمية تُنشئ نسخة "افتراضية رسمية" من هذا الكائن تلقائيًا،
/// ويمكن للمنظم تعديل أي حقل منها لتصبح بطولة بقوانين مخصصة.
class TournamentRules {
  // نظام النقاط (الفصل 4.3)
  int pointsForWin;
  int pointsForDraw;
  int pointsForLoss;

  // ترتيب كسر التعادل القابل لإعادة الترتيب بالسحب والإفلات (الفصل 4.4)
  List<TiebreakCriteria> tiebreakOrder;

  // الذهاب والإياب (الفصل 4.5)
  bool homeAndAway;

  // عدد المتأهلين من كل مجموعة (الفصل 4.6)
  int qualifiersPerGroup;

  // نظام خروج المغلوب عند التعادل (الفصل 4.7)
  KnockoutTiebreakRule knockoutTiebreak;

  // هل هذه القوانين رسمية 100% أم عُدّلت؟ (فكرة "مستوى القوانين" - الفصل 4)
  final bool startedAsOfficial;

  TournamentRules({
    this.pointsForWin = 3,
    this.pointsForDraw = 1,
    this.pointsForLoss = 0,
    List<TiebreakCriteria>? tiebreakOrder,
    this.homeAndAway = true,
    this.qualifiersPerGroup = 2,
    this.knockoutTiebreak = KnockoutTiebreakRule.extraTimeThenPenalties,
    this.startedAsOfficial = true,
  }) : tiebreakOrder = tiebreakOrder ??
            [
              TiebreakCriteria.points,
              TiebreakCriteria.headToHead,
              TiebreakCriteria.goalDifference,
              TiebreakCriteria.goalsFor,
              TiebreakCriteria.goalsAgainstFewest,
              TiebreakCriteria.draw,
            ];

  /// يحسب مستوى القوانين مقارنة بالنسخة الرسمية الافتراضية لنفس نوع البطولة
  /// (الفصل 4 - فكرة "مستوى القوانين" 🟢🟡🔴)
  RulesLevel computeLevel(TournamentRules officialDefaults) {
    final samePoints = pointsForWin == officialDefaults.pointsForWin &&
        pointsForDraw == officialDefaults.pointsForDraw &&
        pointsForLoss == officialDefaults.pointsForLoss;
    final sameHomeAway = homeAndAway == officialDefaults.homeAndAway;
    final sameQualifiers =
        qualifiersPerGroup == officialDefaults.qualifiersPerGroup;
    final sameKnockout = knockoutTiebreak == officialDefaults.knockoutTiebreak;

    final allSame = samePoints && sameHomeAway && sameQualifiers && sameKnockout;
    final allDifferent =
        !samePoints && !sameHomeAway && !sameQualifiers && !sameKnockout;

    if (allSame) return RulesLevel.official;
    if (allDifferent) return RulesLevel.fullyCustom;
    return RulesLevel.modified;
  }

  Map<String, dynamic> toMap() => {
        'pointsForWin': pointsForWin,
        'pointsForDraw': pointsForDraw,
        'pointsForLoss': pointsForLoss,
        'tiebreakOrder': tiebreakOrder.map((e) => e.name).toList(),
        'homeAndAway': homeAndAway ? 1 : 0,
        'qualifiersPerGroup': qualifiersPerGroup,
        'knockoutTiebreak': knockoutTiebreak.name,
        'startedAsOfficial': startedAsOfficial ? 1 : 0,
      };

  factory TournamentRules.fromMap(Map<String, dynamic> map) {
    return TournamentRules(
      pointsForWin: map['pointsForWin'] as int? ?? 3,
      pointsForDraw: map['pointsForDraw'] as int? ?? 1,
      pointsForLoss: map['pointsForLoss'] as int? ?? 0,
      tiebreakOrder: (map['tiebreakOrder'] as List?)
              ?.map((e) => TiebreakCriteria.values
                  .firstWhere((c) => c.name == e))
              .toList() ??
          [],
      homeAndAway: (map['homeAndAway'] as int? ?? 1) == 1,
      qualifiersPerGroup: map['qualifiersPerGroup'] as int? ?? 2,
      knockoutTiebreak: KnockoutTiebreakRule.values.firstWhere(
        (e) => e.name == map['knockoutTiebreak'],
        orElse: () => KnockoutTiebreakRule.extraTimeThenPenalties,
      ),
      startedAsOfficial: (map['startedAsOfficial'] as int? ?? 1) == 1,
    );
  }

  TournamentRules copyWith({
    int? pointsForWin,
    int? pointsForDraw,
    int? pointsForLoss,
    List<TiebreakCriteria>? tiebreakOrder,
    bool? homeAndAway,
    int? qualifiersPerGroup,
    KnockoutTiebreakRule? knockoutTiebreak,
  }) {
    return TournamentRules(
      pointsForWin: pointsForWin ?? this.pointsForWin,
      pointsForDraw: pointsForDraw ?? this.pointsForDraw,
      pointsForLoss: pointsForLoss ?? this.pointsForLoss,
      tiebreakOrder: tiebreakOrder ?? List.of(this.tiebreakOrder),
      homeAndAway: homeAndAway ?? this.homeAndAway,
      qualifiersPerGroup: qualifiersPerGroup ?? this.qualifiersPerGroup,
      knockoutTiebreak: knockoutTiebreak ?? this.knockoutTiebreak,
      startedAsOfficial: startedAsOfficial,
    );
  }

  /// القوانين الرسمية الافتراضية لكل نوع بطولة (الفصل 4.11)
  static TournamentRules officialFor(TournamentType type) {
    switch (type) {
      case TournamentType.worldCup:
      case TournamentType.africaCup:
      case TournamentType.europeCup:
      case TournamentType.copaAmerica:
        return TournamentRules(
          homeAndAway: false,
          qualifiersPerGroup: 2,
          knockoutTiebreak: KnockoutTiebreakRule.extraTimeThenPenalties,
        );
      case TournamentType.uclOldFormat:
        return TournamentRules(
          homeAndAway: true,
          qualifiersPerGroup: 2,
          knockoutTiebreak: KnockoutTiebreakRule.extraTimeThenPenalties,
        );
      case TournamentType.uclNewFormat:
        return TournamentRules(
          homeAndAway: false,
          qualifiersPerGroup: 8, // أول 8 يتأهلون مباشرة لدور الـ16
          knockoutTiebreak: KnockoutTiebreakRule.extraTimeThenPenalties,
        );
      case TournamentType.laLiga:
      case TournamentType.premierLeague:
      case TournamentType.serieA:
      case TournamentType.bundesliga:
      case TournamentType.ligue1:
        return TournamentRules(homeAndAway: true);
      case TournamentType.customLeague:
      case TournamentType.customCup:
      case TournamentType.customGroupsKnockout:
        return TournamentRules(startedAsOfficial: false);
    }
  }
}
