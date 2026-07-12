import '../data/match_repository.dart';
import '../data/player_repository.dart';
import '../data/team_repository.dart';
import '../models/team.dart';

/// سجل مواجهات مباشرة بين لاعبَين (الفصل 8.13)
class RivalryRecord {
  final String rivalPlayerId;
  final String rivalName;
  int played = 0;
  int wins = 0; // انتصارات اللاعب الأساسي
  int losses = 0;
  int draws = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;

  RivalryRecord(this.rivalPlayerId, this.rivalName);
}

/// يحسب سجل كل "الخصوم" الذين واجههم لاعب معيّن عبر تاريخه الكامل
/// (الفصل 8.13) — يُبنى ديناميكيًا من المباريات مباشرة دون تخزين منفصل.
class HeadToHeadService {
  final _playerRepo = PlayerRepository();
  final _teamRepo = TeamRepository();
  final _matchRepo = MatchRepository();

  Future<List<RivalryRecord>> getRivalries(String playerId) async {
    final myTeams = await _teamRepo.getByPlayer(playerId);
    final rivalries = <String, RivalryRecord>{};
    final teamCache = <String, Team?>{};

    for (final team in myTeams) {
      final matches = await _matchRepo.getByTeam(team.id);
      for (final match in matches) {
        if (match.isBye) continue;
        if (match.homeGoals == null || match.awayGoals == null) continue;

        final isHome = match.homeTeamId == team.id;
        final opponentTeamId = isHome ? match.awayTeamId : match.homeTeamId;

        if (!teamCache.containsKey(opponentTeamId)) {
          teamCache[opponentTeamId] = await _teamRepo.getById(opponentTeamId);
        }
        final opponentTeam = teamCache[opponentTeamId];
        if (opponentTeam == null) continue;
        final rivalPlayerId = opponentTeam.playerId;
        if (rivalPlayerId == playerId) continue; // نفس اللاعب يتحكم بفريقين (نادر) — نتجاهل

        final rivalPlayer = await _playerRepo.getById(rivalPlayerId);
        final rivalName = rivalPlayer?.name ?? opponentTeam.playerNameSnapshot ?? 'لاعب محذوف';

        final record =
            rivalries.putIfAbsent(rivalPlayerId, () => RivalryRecord(rivalPlayerId, rivalName));

        final scored = isHome ? match.homeGoals! : match.awayGoals!;
        final conceded = isHome ? match.awayGoals! : match.homeGoals!;

        record.played++;
        record.goalsFor += scored;
        record.goalsAgainst += conceded;

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
          record.wins++;
        } else if (lost) {
          record.losses++;
        } else {
          record.draws++;
        }
      }
    }

    final list = rivalries.values.toList();
    list.sort((a, b) => b.played.compareTo(a.played));
    return list;
  }
}
