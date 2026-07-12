import '../data/match_repository.dart';
import '../data/player_repository.dart';
import '../data/team_repository.dart';
import '../data/tournament_repository.dart';
import '../models/tournament.dart';

/// يعيد حساب جميع إحصائيات اللاعب التراكمية من الصفر بناءً على كل مبارياته
/// المنتهية عبر كل البطولات (الفصل 2.13). إعادة الحساب الكامل (بدل تحديث
/// تراكمي بالفرق) تتجنّب أي خطأ عند تعديل نتيجة سابقة (الفصل 6.9).
class PlayerStatsService {
  final _playerRepo = PlayerRepository();
  final _teamRepo = TeamRepository();
  final _matchRepo = MatchRepository();
  final _tournamentRepo = TournamentRepository();

  Future<void> recalculate(String playerId) async {
    final player = await _playerRepo.getById(playerId);
    if (player == null) return;

    final teams = await _teamRepo.getByPlayer(playerId);
    final tournamentsCache = <String, Tournament?>{};

    int matchesPlayed = 0, wins = 0, draws = 0, losses = 0;
    int goalsFor = 0, goalsAgainst = 0;

    // كل المباريات المنتهية الحقيقية (غير الوهمية Bye) مع بيانات ترتيبها الزمني
    final chronological = <_ChronoMatch>[];

    for (final team in teams) {
      final matches = await _matchRepo.getByTeam(team.id);
      tournamentsCache.putIfAbsent(team.tournamentId, () => null);

      for (final match in matches) {
        if (match.isBye) continue;
        if (match.homeGoals == null || match.awayGoals == null) continue;

        final isHome = match.homeTeamId == team.id;
        final scored = isHome ? match.homeGoals! : match.awayGoals!;
        final conceded = isHome ? match.awayGoals! : match.homeGoals!;

        matchesPlayed++;
        goalsFor += scored;
        goalsAgainst += conceded;

        bool won = scored > conceded;
        bool lost = scored < conceded;
        if (scored == conceded && match.hasPenalties) {
          final wonPens = isHome
              ? match.homePenalties! > match.awayPenalties!
              : match.awayPenalties! > match.homePenalties!;
          won = wonPens;
          lost = !wonPens;
        }

        if (won) {
          wins++;
        } else if (lost) {
          losses++;
        } else {
          draws++;
        }

        chronological.add(_ChronoMatch(
          tournamentId: team.tournamentId,
          round: match.round,
          won: won,
        ));
      }
    }

    // نجلب تواريخ إنشاء البطولات مرة واحدة لترتيب المباريات زمنيًا عبر بطولات مختلفة
    for (final tid in tournamentsCache.keys.toList()) {
      tournamentsCache[tid] = await _tournamentRepo.getById(tid);
    }
    chronological.sort((a, b) {
      final ta = tournamentsCache[a.tournamentId]?.createdAt ?? DateTime(2000);
      final tb = tournamentsCache[b.tournamentId]?.createdAt ?? DateTime(2000);
      final byTournament = ta.compareTo(tb);
      if (byTournament != 0) return byTournament;
      return a.round.compareTo(b.round);
    });

    int longestStreak = 0;
    int runningStreak = 0;
    for (final m in chronological) {
      if (m.won) {
        runningStreak++;
        longestStreak = runningStreak > longestStreak ? runningStreak : longestStreak;
      } else {
        runningStreak = 0;
      }
    }

    // السلسلة "الحالية" = عدد الانتصارات المتتالية في آخر المباريات فقط
    int currentStreak = 0;
    for (int i = chronological.length - 1; i >= 0; i--) {
      if (chronological[i].won) {
        currentStreak++;
      } else {
        break;
      }
    }

    // الألقاب والوصافة والمركز الثالث: نمسح كل البطولات (حجم محلي صغير بطبيعته)
    final allTournaments = await _tournamentRepo.getAll();
    int titles = 0, runnerUps = 0, thirdPlaces = 0;
    for (final t in allTournaments) {
      if (t.championPlayerId == playerId) titles++;
      if (t.runnerUpPlayerId == playerId) runnerUps++;
      if (t.thirdPlacePlayerId == playerId) thirdPlaces++;
    }

    final tournamentsPlayed = teams.map((t) => t.tournamentId).toSet().length;

    final updated = player.copyWith();
    updated.tournamentsPlayed = tournamentsPlayed;
    updated.titlesWon = titles;
    updated.runnerUpCount = runnerUps;
    updated.thirdPlaceCount = thirdPlaces;
    updated.matchesPlayed = matchesPlayed;
    updated.wins = wins;
    updated.draws = draws;
    updated.losses = losses;
    updated.goalsFor = goalsFor;
    updated.goalsAgainst = goalsAgainst;
    updated.longestWinStreak = longestStreak;
    updated.currentWinStreak = currentStreak;

    await _playerRepo.update(updated);
  }
}

class _ChronoMatch {
  final String tournamentId;
  final int round;
  final bool won;
  _ChronoMatch({required this.tournamentId, required this.round, required this.won});
}
