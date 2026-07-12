import '../models/enums.dart';
import '../models/match_model.dart';
import '../models/standing_entry.dart';
import '../models/tournament_rules.dart';

/// محرك حساب جدول الترتيب وتطبيق معايير كسر التعادل (الفصل 7.5 / 7.6)
/// جميع الحسابات هنا تلقائية بالكامل ولا تُعدَّل يدويًا (الفصل 7.18).
class StandingsCalculator {
  /// يحسب جدول ترتيب فرق مجموعة/دوري واحد بناءً على المباريات المنتهية فقط
  static Map<String, StandingEntry> calculate({
    required List<String> teamIds,
    required List<MatchModel> matches,
    required TournamentRules rules,
  }) {
    final table = {for (final id in teamIds) id: StandingEntry(id)};

    for (final match in matches) {
      if (match.status != MatchStatus.played) continue;
      if (match.isBye) continue;
      if (match.homeGoals == null || match.awayGoals == null) continue;

      final home = table[match.homeTeamId];
      final away = table[match.awayTeamId];
      if (home == null || away == null) continue;

      home.addMatchResult(
        goalsScored: match.homeGoals!,
        goalsConceded: match.awayGoals!,
        pointsForWin: rules.pointsForWin,
        pointsForDraw: rules.pointsForDraw,
        pointsForLoss: rules.pointsForLoss,
      );
      away.addMatchResult(
        goalsScored: match.awayGoals!,
        goalsConceded: match.homeGoals!,
        pointsForWin: rules.pointsForWin,
        pointsForDraw: rules.pointsForDraw,
        pointsForLoss: rules.pointsForLoss,
      );
    }

    return table;
  }

  /// يرتّب قائمة الفرق حسب النقاط ثم معايير كسر التعادل بالترتيب المحدد في القوانين
  static List<String> sortStandings({
    required Map<String, StandingEntry> table,
    required List<MatchModel> allMatchesForHeadToHead,
    required TournamentRules rules,
  }) {
    final teamIds = table.keys.toList();

    teamIds.sort((a, b) {
      for (final criteria in rules.tiebreakOrder) {
        final comparison = _compareByCriteria(
          a,
          b,
          table,
          allMatchesForHeadToHead,
          criteria,
        );
        if (comparison != 0) return comparison;
      }
      return 0; // تعادل تام (نادر جدًا) — يبقى بترتيب القرعة الأصلي
    });

    return teamIds;
  }

  static int _compareByCriteria(
    String teamA,
    String teamB,
    Map<String, StandingEntry> table,
    List<MatchModel> allMatches,
    TiebreakCriteria criteria,
  ) {
    final entryA = table[teamA]!;
    final entryB = table[teamB]!;

    switch (criteria) {
      case TiebreakCriteria.points:
        return entryB.points.compareTo(entryA.points);

      case TiebreakCriteria.goalDifference:
        return entryB.goalDifference.compareTo(entryA.goalDifference);

      case TiebreakCriteria.goalsFor:
        return entryB.goalsFor.compareTo(entryA.goalsFor);

      case TiebreakCriteria.goalsAgainstFewest:
        return entryA.goalsAgainst.compareTo(entryB.goalsAgainst);

      case TiebreakCriteria.headToHead:
        return _headToHeadComparison(teamA, teamB, allMatches);

      case TiebreakCriteria.draw:
        // حل أخير: القرعة العشوائية — نُبقي الترتيب الحالي (مستقر)
        return 0;
    }
  }

  /// يقارن فريقين بناءً على نتائج مواجهاتهما المباشرة فقط
  static int _headToHeadComparison(
    String teamA,
    String teamB,
    List<MatchModel> allMatches,
  ) {
    int pointsA = 0;
    int pointsB = 0;
    int goalsA = 0;
    int goalsB = 0;

    for (final match in allMatches) {
      if (match.status != MatchStatus.played) continue;
      final isDirectMatch =
          (match.homeTeamId == teamA && match.awayTeamId == teamB) ||
              (match.homeTeamId == teamB && match.awayTeamId == teamA);
      if (!isDirectMatch) continue;
      if (match.homeGoals == null || match.awayGoals == null) continue;

      if (match.homeTeamId == teamA) {
        goalsA += match.homeGoals!;
        goalsB += match.awayGoals!;
        if (match.homeGoals! > match.awayGoals!) {
          pointsA += 3;
        } else if (match.homeGoals! < match.awayGoals!) {
          pointsB += 3;
        } else {
          pointsA += 1;
          pointsB += 1;
        }
      } else {
        goalsB += match.homeGoals!;
        goalsA += match.awayGoals!;
        if (match.homeGoals! > match.awayGoals!) {
          pointsB += 3;
        } else if (match.homeGoals! < match.awayGoals!) {
          pointsA += 3;
        } else {
          pointsA += 1;
          pointsB += 1;
        }
      }
    }

    if (pointsA != pointsB) return pointsB.compareTo(pointsA);
    return goalsB.compareTo(goalsA);
  }

  /// إحصائيات عامة للبطولة (الفصل 7.10)
  static Map<String, dynamic> computeGeneralStats(List<MatchModel> matches) {
    final played = matches
        .where((m) => m.status == MatchStatus.played && !m.isBye)
        .toList();

    if (played.isEmpty) {
      return {
        'totalMatches': 0,
        'totalGoals': 0,
        'averageGoalsPerMatch': 0.0,
        'biggestWin': null,
        'mostGoalsMatch': null,
        'leastGoalsMatch': null,
      };
    }

    int totalGoals = 0;
    MatchModel? biggestWin;
    int biggestWinMargin = -1;
    MatchModel? mostGoalsMatch;
    int mostGoalsCount = -1;
    MatchModel? leastGoalsMatch;
    int leastGoalsCount = 1 << 30;

    for (final m in played) {
      final hg = m.homeGoals ?? 0;
      final ag = m.awayGoals ?? 0;
      final totalInMatch = hg + ag;
      final margin = (hg - ag).abs();

      totalGoals += totalInMatch;

      if (margin > biggestWinMargin) {
        biggestWinMargin = margin;
        biggestWin = m;
      }
      if (totalInMatch > mostGoalsCount) {
        mostGoalsCount = totalInMatch;
        mostGoalsMatch = m;
      }
      if (totalInMatch < leastGoalsCount) {
        leastGoalsCount = totalInMatch;
        leastGoalsMatch = m;
      }
    }

    return {
      'totalMatches': played.length,
      'totalGoals': totalGoals,
      'averageGoalsPerMatch':
          double.parse((totalGoals / played.length).toStringAsFixed(2)),
      'biggestWin': biggestWin,
      'mostGoalsMatch': mostGoalsMatch,
      'leastGoalsMatch': leastGoalsMatch,
    };
  }
}
