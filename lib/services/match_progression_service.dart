import 'dart:math';
import '../data/match_repository.dart';
import '../data/team_repository.dart';
import '../data/tournament_repository.dart';
import '../models/enums.dart';
import '../models/match_model.dart';
import '../models/team.dart';
import '../models/tournament.dart';
import 'knockout_generator.dart';
import 'player_stats_service.dart';
import 'standings_calculator.dart';
import 'swiss_league_generator.dart';
import 'tournament_engine.dart';

/// خدمة تسجيل نتائج المباريات والانتقال التلقائي بين المراحل (الفصل 5.14-5.16 / 6)
/// هذه هي الطبقة التي "تربط" محرك البطولات (Pure Engine) بقاعدة البيانات.
class MatchProgressionService {
  final _matchRepo = MatchRepository();
  final _teamRepo = TeamRepository();
  final _tournamentRepo = TournamentRepository();
  final _statsService = PlayerStatsService();
  final _engine = TournamentEngine();
  final _random = Random();

  /// يسجّل نتيجة مباراة، يحدّث كل الإحصائيات المتأثرة، ثم يفحص إن كانت
  /// المرحلة الحالية اكتملت لينشئ المرحلة التالية تلقائيًا (الفصل 5.15).
  Future<void> recordResult({
    required MatchModel match,
    required int homeGoals,
    required int awayGoals,
    int? homePenalties,
    int? awayPenalties,
    bool wentToExtraTime = false,
  }) async {
    match.homeGoals = homeGoals;
    match.awayGoals = awayGoals;
    match.homePenalties = homePenalties;
    match.awayPenalties = awayPenalties;
    match.wentToExtraTime = wentToExtraTime;
    match.status = MatchStatus.played;
    match.isPostponed = false;

    await _matchRepo.update(match);

    // تحديث إحصائيات كلا اللاعبين (الفصل 5.14 / 6.10) — إعادة حساب كاملة
    // آمنة حتى عند تعديل نتيجة سابقة (الفصل 6.9)
    final teams = await _teamRepo.getByTournament(match.tournamentId);
    final homeTeam = teams.where((t) => t.id == match.homeTeamId).firstOrNull;
    final awayTeam = teams.where((t) => t.id == match.awayTeamId).firstOrNull;
    if (homeTeam != null) await _statsService.recalculate(homeTeam.playerId);
    if (awayTeam != null) await _statsService.recalculate(awayTeam.playerId);

    await _checkAndAdvance(match.tournamentId);
  }

  /// تأجيل مباراة (الفصل 6.14)
  Future<void> postponeMatch(MatchModel match) async {
    match.isPostponed = true;
    match.status = MatchStatus.postponed;
    await _matchRepo.update(match);
  }

  /// إعادة ضبط جولة كاملة: حذف كل نتائجها فقط (الفصل 6.15)
  Future<void> resetRound(String tournamentId, int round) async {
    final matches = await _matchRepo.getByRound(tournamentId: tournamentId, round: round);
    for (final m in matches) {
      if (m.isBye) continue; // لا نلمس مباريات الإعفاء التقنية
      m.homeGoals = null;
      m.awayGoals = null;
      m.homePenalties = null;
      m.awayPenalties = null;
      m.status = MatchStatus.notPlayed;
      await _matchRepo.update(m);
    }
  }

  // -------------------------------------------------------------------
  // المنطق الداخلي: فحص اكتمال المرحلة والانتقال التلقائي (الفصل 5.15)
  // -------------------------------------------------------------------
  Future<void> _checkAndAdvance(String tournamentId) async {
    final tournament = await _tournamentRepo.getById(tournamentId);
    if (tournament == null) return;

    final allMatches = await _matchRepo.getByTournament(tournamentId);
    final teams = await _teamRepo.getByTournament(tournamentId);

    // تحديث رقم الجولة الحالية = أكبر جولة انتهت بالكامل
    final maxRound = allMatches.isEmpty ? 0 : allMatches.map((m) => m.round).reduce(max);
    int completedRounds = 0;
    for (int r = 1; r <= maxRound; r++) {
      final roundMatches = allMatches.where((m) => m.round == r).toList();
      if (roundMatches.isNotEmpty && _engine.isStageComplete(roundMatches)) {
        completedRounds = r;
      } else {
        break;
      }
    }
    tournament.currentRound = completedRounds;

    switch (tournament.format) {
      case TournamentFormat.league:
        await _checkLeagueFinished(tournament, allMatches);
        break;
      case TournamentFormat.cup:
        await _advanceKnockout(tournament, allMatches, teams);
        break;
      case TournamentFormat.groupsThenKnockout:
        await _advanceGroupsThenKnockout(tournament, allMatches, teams);
        break;
      case TournamentFormat.swissThenKnockout:
        await _advanceSwissThenKnockout(tournament, allMatches, teams);
        break;
    }

    await _tournamentRepo.update(tournament);
  }

  /// دوري بسيط: البطولة تنتهي بانتهاء كل الجولات، والبطل = صاحب المركز الأول
  Future<void> _checkLeagueFinished(Tournament tournament, List<MatchModel> allMatches) async {
    if (tournament.status == TournamentStatus.finished) return;
    if (!_engine.isStageComplete(allMatches)) return;

    final teams = await _teamRepo.getByTournament(tournament.id);
    final table = StandingsCalculator.calculate(
      teamIds: teams.map((t) => t.id).toList(),
      matches: allMatches,
      rules: tournament.rules,
    );
    final ranked = StandingsCalculator.sortStandings(
      table: table,
      allMatchesForHeadToHead: allMatches,
      rules: tournament.rules,
    );
    if (ranked.isEmpty) return;

    final teamIdToPlayerId = {for (final t in teams) t.id: t.playerId};
    tournament.championPlayerId = teamIdToPlayerId[ranked[0]];
    if (ranked.length > 1) tournament.runnerUpPlayerId = teamIdToPlayerId[ranked[1]];
    if (ranked.length > 2) tournament.thirdPlacePlayerId = teamIdToPlayerId[ranked[2]];
    tournament.status = TournamentStatus.finished;
    tournament.finishedAt = DateTime.now();

    for (final playerId in teamIdToPlayerId.values.toSet()) {
      await _statsService.recalculate(playerId);
    }
  }

  /// كأس (خروج مغلوب مباشر): ينشئ الدور التالي كلما انتهى دور سابق (الفصل 5.15)
  Future<void> _advanceKnockout(
      Tournament tournament, List<MatchModel> allMatches, List<Team> teams) async {
    if (tournament.status == TournamentStatus.finished) return;

    final maxRound = allMatches.isEmpty ? 0 : allMatches.map((m) => m.round).reduce(max);
    final lastRoundMatches = allMatches.where((m) => m.round == maxRound).toList();

    if (!_engine.isStageComplete(lastRoundMatches)) return;
    if (_engine.hasBlockingPostponedMatches(lastRoundMatches)) return;

    final winners = lastRoundMatches.map((m) => m.winnerTeamId).whereType<String>().toList();

    if (winners.length == 1) {
      // انتهت البطولة بالفعل — هذا كان النهائي
      final teamIdToPlayerId = {for (final t in teams) t.id: t.playerId};
      _engine.finalizeTournament(
        tournament: tournament,
        finalMatch: lastRoundMatches.first,
        teamIdToPlayerId: teamIdToPlayerId,
      );
      for (final playerId in teamIdToPlayerId.values.toSet()) {
        await _statsService.recalculate(playerId);
      }
      return;
    }

    if (winners.length < 2) return; // نتائج غير مكتملة فعليًا (احتياط أمان)

    final nextRoundMatches =
        _engine.buildNextKnockoutRound(tournament: tournament, winnersInOrder: winners, nextRoundNumber: maxRound + 1);
    if (nextRoundMatches.isNotEmpty) {
      await _tournamentRepo.insertMatches(nextRoundMatches);
    }
  }

  /// مجموعات ثم خروج مغلوب: كأس العالم، دوري الأبطال القديم... (الفصل 5.8 / 5.15)
  Future<void> _advanceGroupsThenKnockout(
      Tournament tournament, List<MatchModel> allMatches, List<Team> teams) async {
    if (tournament.status == TournamentStatus.finished) return;

    final groupMatches = allMatches.where((m) => m.stage == TournamentStage.groupStage).toList();
    final knockoutMatches = allMatches.where((m) => m.stage != TournamentStage.groupStage).toList();

    if (knockoutMatches.isEmpty) {
      // لا تزال في مرحلة المجموعات — هل انتهت بالكامل؟
      if (groupMatches.isEmpty || !_engine.isStageComplete(groupMatches)) return;

      // تحديد المتأهلين من كل مجموعة حسب الترتيب (الفصل 7.8)
      final groupNames = groupMatches.map((m) => m.groupName).whereType<String>().toSet();
      final qualifiedTeams = <Team>[];

      for (final groupName in groupNames) {
        final groupTeams = teams.where((t) => t.groupName == groupName).toList();
        final groupMatchesOnly = groupMatches.where((m) => m.groupName == groupName).toList();
        final table = StandingsCalculator.calculate(
          teamIds: groupTeams.map((t) => t.id).toList(),
          matches: groupMatchesOnly,
          rules: tournament.rules,
        );
        final ranked = StandingsCalculator.sortStandings(
          table: table,
          allMatchesForHeadToHead: groupMatchesOnly,
          rules: tournament.rules,
        );
        final qualifiersCount = tournament.rules.qualifiersPerGroup;
        for (final teamId in ranked.take(qualifiersCount)) {
          qualifiedTeams.add(groupTeams.firstWhere((t) => t.id == teamId));
        }
      }

      if (qualifiedTeams.isEmpty) return;

      final fixtures = KnockoutGenerator.generateFirstRound(
        qualifiedTeams: qualifiedTeams,
        random: _random,
      );
      final maxGroupRound = groupMatches.map((m) => m.round).reduce(max);
      final nextRound = maxGroupRound + 1;

      final newMatches = fixtures
          .map((f) => MatchModel(
                id: 'match_${tournament.id}_${f.stage.name}_${nextRound}_${f.homeTeamId}_${f.awayTeamId}',
                tournamentId: tournament.id,
                stage: f.stage,
                round: nextRound,
                homeTeamId: f.homeTeamId,
                awayTeamId: f.awayTeamId,
                status: (f.homeTeamId == byeTeamId || f.awayTeamId == byeTeamId)
                    ? MatchStatus.played
                    : MatchStatus.notPlayed,
                homeGoals: f.homeTeamId == byeTeamId ? 0 : (f.awayTeamId == byeTeamId ? 1 : null),
                awayGoals: f.awayTeamId == byeTeamId ? 0 : (f.homeTeamId == byeTeamId ? 1 : null),
              ))
          .toList();
      await _tournamentRepo.insertMatches(newMatches);
      return;
    }

    // في مرحلة خروج المغلوب: نفس منطق الكأس
    await _advanceKnockout(tournament, knockoutMatches, teams);
  }

  /// دوري أبطال أوروبا الجديد: دوري موحد -> ملحق -> خروج مغلوب (الفصل 4.10 / 5.11)
  Future<void> _advanceSwissThenKnockout(
      Tournament tournament, List<MatchModel> allMatches, List<Team> teams) async {
    if (tournament.status == TournamentStatus.finished) return;

    final leagueMatches = allMatches.where((m) => m.stage == TournamentStage.leagueStage).toList();
    final playoffMatches = allMatches.where((m) => m.stage == TournamentStage.playoff).toList();
    final knockoutMatches = allMatches
        .where((m) =>
            m.stage != TournamentStage.leagueStage && m.stage != TournamentStage.playoff)
        .toList();

    if (playoffMatches.isEmpty && knockoutMatches.isEmpty) {
      // لا تزال في الدوري الموحد
      if (leagueMatches.isEmpty || !_engine.isStageComplete(leagueMatches)) return;

      final table = StandingsCalculator.calculate(
        teamIds: teams.map((t) => t.id).toList(),
        matches: leagueMatches,
        rules: tournament.rules,
      );
      final ranked = StandingsCalculator.sortStandings(
        table: table,
        allMatchesForHeadToHead: leagueMatches,
        rules: tournament.rules,
      );

      final classification = SwissLeagueGenerator.classifyStandings(ranked);
      final directQualifiers = classification['directQualifiers']!; // 1-8
      final playoffTeams = classification['playoff']!; // 9-24

      final maxLeagueRound = leagueMatches.map((m) => m.round).reduce(max);
      final playoffRound = maxLeagueRound + 1;

      // تزاوج الملحق: الأعلى ترتيبًا (9) ضد الأدنى (24)، وهكذا (الفصل 5.11)
      final newMatches = <MatchModel>[];
      for (int i = 0; i < playoffTeams.length ~/ 2; i++) {
        final higher = playoffTeams[i];
        final lower = playoffTeams[playoffTeams.length - 1 - i];
        newMatches.add(MatchModel(
          id: 'match_${tournament.id}_playoff_${playoffRound}_${higher}_$lower',
          tournamentId: tournament.id,
          stage: TournamentStage.playoff,
          round: playoffRound,
          homeTeamId: higher,
          awayTeamId: lower,
        ));
      }

      // نحفظ قائمة المتأهلين المباشرين مؤقتًا داخل ملاحظات البطولة لاستخدامها
      // لاحقًا عند بناء دور الـ16 (بديل بسيط عن جدول منفصل لهذه المرحلة الخاصة)
      tournament.notes = '${tournament.notes ?? ''}\n__direct_qualifiers__:${directQualifiers.join(",")}';

      await _tournamentRepo.insertMatches(newMatches);
      return;
    }

    if (knockoutMatches.isEmpty) {
      // في مرحلة الملحق — هل انتهت؟
      if (!_engine.isStageComplete(playoffMatches)) return;

      final playoffWinners =
          playoffMatches.map((m) => m.winnerTeamId).whereType<String>().toList();

      // استرجاع المتأهلين المباشرين المحفوظين في ملاحظات البطولة
      final directQualifiersLine = (tournament.notes ?? '')
          .split('\n')
          .firstWhere((line) => line.startsWith('__direct_qualifiers__:'), orElse: () => '');
      final directQualifiers = directQualifiersLine.isEmpty
          ? <String>[]
          : directQualifiersLine.split(':').last.split(',');

      final roundOf16Teams = [...directQualifiers, ...playoffWinners]..shuffle(_random);
      final maxPlayoffRound = playoffMatches.map((m) => m.round).reduce(max);
      final nextRound = maxPlayoffRound + 1;

      final fixtures = KnockoutGenerator.buildNextRound(roundOf16Teams);
      final newMatches = fixtures
          .map((f) => MatchModel(
                id: 'match_${tournament.id}_${f.stage.name}_${nextRound}_${f.homeTeamId}_${f.awayTeamId}',
                tournamentId: tournament.id,
                stage: f.stage,
                round: nextRound,
                homeTeamId: f.homeTeamId,
                awayTeamId: f.awayTeamId,
              ))
          .toList();
      await _tournamentRepo.insertMatches(newMatches);
      return;
    }

    // في مرحلة خروج المغلوب (دور 16 وما بعده): نفس منطق الكأس
    await _advanceKnockout(tournament, knockoutMatches, teams);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
