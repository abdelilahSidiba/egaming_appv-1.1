import 'dart:math';
import '../models/enums.dart';
import '../models/match_model.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/tournament.dart';
import 'group_stage_generator.dart';
import 'knockout_generator.dart';
import 'round_robin_generator.dart';
import 'standings_calculator.dart';
import 'swiss_league_generator.dart';

/// استثناء يُطلق عند فشل التحقق من صحة بيانات البطولة قبل إنشائها (الفصل 5.3)
class TournamentValidationException implements Exception {
  final String message;
  TournamentValidationException(this.message);
  @override
  String toString() => message;
}

/// نتيجة تجميع اللاعبين والفرق قبل الإنشاء، تدعم حالة "لاعب يتحكم بأكثر من فريق"
/// (الفصل 3.8 / 3.10)
class PlayerTeamAssignment {
  final Player player;
  final List<String> teamNames; // قد يكون أكثر من اسم فريق لنفس اللاعب
  PlayerTeamAssignment(this.player, this.teamNames);
}

/// محرك إنشاء البطولات والمباريات — "العقل الحقيقي للتطبيق" (الفصل 5 بالكامل)
///
/// هذا المحرك لا يتعامل مع قاعدة البيانات مباشرة (Pure Engine)؛ طبقة أعلى
/// (Repository/Provider) هي من تستدعي هذه الدوال ثم تحفظ النتائج في SQLite.
/// هذا يجعل المحرك قابلاً للاختبار بمعزل عن الواجهة وقاعدة البيانات.
class TournamentEngine {
  final Random random;
  TournamentEngine({Random? random}) : random = random ?? Random();

  // ---------------------------------------------------------------------
  // الخطوة 1: التحقق من صحة البيانات (الفصل 5.3)
  // ---------------------------------------------------------------------
  void validate({
    required String tournamentName,
    required List<PlayerTeamAssignment> assignments,
    required int? requiredTeamCount,
  }) {
    if (tournamentName.trim().isEmpty) {
      throw TournamentValidationException('يجب إدخال اسم البطولة.');
    }

    if (assignments.isEmpty) {
      throw TournamentValidationException('يجب اختيار لاعب واحد على الأقل.');
    }

    // عدم وجود لاعب مكرر
    final playerIds = assignments.map((a) => a.player.id).toList();
    if (playerIds.toSet().length != playerIds.length) {
      throw TournamentValidationException('يوجد لاعب مكرر داخل البطولة.');
    }

    // عدم وجود اسم فريق مكرر
    final allTeamNames =
        assignments.expand((a) => a.teamNames).map((n) => n.trim()).toList();
    if (allTeamNames.toSet().length != allTeamNames.length) {
      throw TournamentValidationException('يوجد اسم فريق مكرر داخل البطولة.');
    }

    // إذا كانت بطولة رسمية بعدد فرق ثابت: تحقق من مطابقة العدد
    if (requiredTeamCount != null && allTeamNames.length != requiredTeamCount) {
      throw TournamentValidationException(
        'عدد الفرق ($requiredTeamCount) لا يطابق عدد الفرق المحددة (${allTeamNames.length}).',
      );
    }
  }

  // ---------------------------------------------------------------------
  // الخطوة 3-4: إنشاء الفرق وربطها باللاعبين (الفصل 5.5 / 5.6)
  // ---------------------------------------------------------------------
  List<Team> createTeams({
    required String tournamentId,
    required List<PlayerTeamAssignment> assignments,
    required List<String> officialLogoPaths, // شعارات جاهزة إن وجدت (بطولة رسمية)
  }) {
    final teams = <Team>[];
    int seed = 0;
    int logoIndex = 0;

    for (final assignment in assignments) {
      for (final teamName in assignment.teamNames) {
        final logo = logoIndex < officialLogoPaths.length
            ? officialLogoPaths[logoIndex]
            : assignment.player.logoAssetPath;
        logoIndex++;

        teams.add(Team(
          id: 'team_${tournamentId}_$seed',
          tournamentId: tournamentId,
          name: teamName,
          logoAssetPath: logo,
          playerId: assignment.player.id,
          playerNameSnapshot: assignment.player.name, // لقطة ثابتة (الفصل 8.20)
          colorHex: assignment.player.colorHex,
          seed: seed,
        ));
        seed++;
      }
    }
    return teams;
  }

  /// حل حالة "عدد اللاعبين أقل من عدد الفرق" بتوزيع الفرق الإضافية بعدالة
  /// على اللاعبين المتاحين (الفصل 3.10)
  static List<PlayerTeamAssignment> distributeExtraTeamsFairly({
    required List<Player> players,
    required List<String> allTeamNames,
    Random? random,
  }) {
    final rnd = random ?? Random();
    final shuffledTeams = List<String>.from(allTeamNames)..shuffle(rnd);
    final assignments = {for (final p in players) p.id: <String>[]};

    for (int i = 0; i < shuffledTeams.length; i++) {
      final player = players[i % players.length];
      assignments[player.id]!.add(shuffledTeams[i]);
    }

    return players
        .map((p) => PlayerTeamAssignment(p, assignments[p.id]!))
        .toList();
  }

  // ---------------------------------------------------------------------
  // الخطوة 5: إنشاء جدول المباريات حسب صيغة البطولة (الفصل 5.7 - 5.11)
  // ---------------------------------------------------------------------
  List<MatchModel> generateInitialFixtures({
    required Tournament tournament,
    required List<Team> teams,
  }) {
    switch (tournament.format) {
      case TournamentFormat.league:
        return _generateLeagueFixtures(tournament, teams);
      case TournamentFormat.cup:
        return _generateCupFixtures(tournament, teams);
      case TournamentFormat.groupsThenKnockout:
        return _generateGroupsFixtures(tournament, teams);
      case TournamentFormat.swissThenKnockout:
        return _generateSwissFixtures(tournament, teams);
    }
  }

  List<MatchModel> _generateLeagueFixtures(
      Tournament tournament, List<Team> teams) {
    final teamIds = teams.map((t) => t.id).toList();
    final rounds = tournament.rules.homeAndAway
        ? RoundRobinGenerator.generateHomeAndAway(teamIds)
        : RoundRobinGenerator.generateSingleLeg(teamIds);

    tournament.totalRounds = rounds.length;

    final matches = <MatchModel>[];
    for (int r = 0; r < rounds.length; r++) {
      for (final pair in rounds[r]) {
        matches.add(_newMatch(
          tournament: tournament,
          stage: TournamentStage.leagueStage,
          round: r + 1,
          homeId: pair[0],
          awayId: pair[1],
        ));
      }
    }
    return matches;
  }

  List<MatchModel> _generateCupFixtures(
      Tournament tournament, List<Team> teams) {
    final fixtures =
        KnockoutGenerator.generateFirstRound(qualifiedTeams: teams, random: random);

    tournament.totalRounds = _knockoutRoundsNeeded(teams.length);

    return fixtures
        .map((f) => _newMatch(
              tournament: tournament,
              stage: f.stage,
              round: 1,
              homeId: f.homeTeamId,
              awayId: f.awayTeamId,
            ))
        .toList();
  }

  int _knockoutRoundsNeeded(int teamCount) {
    int rounds = 0;
    int size = 2;
    while (size < teamCount) {
      size *= 2;
      rounds++;
    }
    return rounds + 1;
  }

  List<MatchModel> _generateGroupsFixtures(
      Tournament tournament, List<Team> teams) {
    // حجم مجموعة افتراضي = 4 فرق (كأس العالم/دوري الأبطال القديم)
    const groupSize = 4;
    final groups = GroupStageGenerator.drawGroups(
      teams: teams,
      groupSize: groupSize,
      random: random,
    );
    final groupRounds = GroupStageGenerator.generateGroupMatches(
      groups: groups,
      homeAndAway: tournament.rules.homeAndAway,
    );

    final matches = <MatchModel>[];
    int maxRounds = 0;

    groupRounds.forEach((groupName, rounds) {
      maxRounds = max(maxRounds, rounds.length);
      for (int r = 0; r < rounds.length; r++) {
        for (final pair in rounds[r]) {
          matches.add(_newMatch(
            tournament: tournament,
            stage: TournamentStage.groupStage,
            groupName: groupName,
            round: r + 1,
            homeId: pair[0],
            awayId: pair[1],
          ));
        }
      }
    });

    // إجمالي الجولات = جولات المجموعات + الأدوار الإقصائية المتوقعة بعدها
    final qualifiersCount = groups.length * tournament.rules.qualifiersPerGroup;
    tournament.totalRounds = maxRounds + _knockoutRoundsNeeded(qualifiersCount);

    return matches;
  }

  List<MatchModel> _generateSwissFixtures(
      Tournament tournament, List<Team> teams) {
    const matchesPerTeam = 8; // النظام الحقيقي لدوري الأبطال الجديد (الفصل 4.10)
    final teamIds = teams.map((t) => t.id).toList();

    final fixtures = SwissLeagueGenerator.generateFixtures(
      teamIds: teamIds,
      matchesPerTeam: matchesPerTeam,
      random: random,
    );
    final rounds = SwissLeagueGenerator.scheduleIntoRounds(
      fixtures: fixtures,
      allTeamIds: teamIds,
    );

    // جولات الدوري الموحد + الملحق (دور واحد) + دور16 + ربع + نصف + نهائي = +5
    tournament.totalRounds = rounds.length + 5;

    final matches = <MatchModel>[];
    for (int r = 0; r < rounds.length; r++) {
      for (final pair in rounds[r]) {
        matches.add(_newMatch(
          tournament: tournament,
          stage: TournamentStage.leagueStage,
          round: r + 1,
          homeId: pair[0],
          awayId: pair[1],
        ));
      }
    }
    return matches;
  }

  MatchModel _newMatch({
    required Tournament tournament,
    required TournamentStage stage,
    String? groupName,
    required int round,
    required String homeId,
    required String awayId,
    int leg = 1,
  }) {
    return MatchModel(
      id: 'match_${tournament.id}_${stage.name}_${groupName ?? ""}_${round}_${homeId}_$awayId',
      tournamentId: tournament.id,
      stage: stage,
      groupName: groupName,
      round: round,
      leg: leg,
      homeTeamId: homeId,
      awayTeamId: awayId,
      // مباريات الإعفاء (Bye) تُعتبر منتهية فورًا بفوز الفريق الحقيقي 0-0 تقني
      status: (homeId == byeTeamId || awayId == byeTeamId)
          ? MatchStatus.played
          : MatchStatus.notPlayed,
      homeGoals: homeId == byeTeamId ? 0 : (awayId == byeTeamId ? 1 : null),
      awayGoals: awayId == byeTeamId ? 0 : (homeId == byeTeamId ? 1 : null),
    );
  }

  // ---------------------------------------------------------------------
  // الفصل 5.15: اكتشاف نهاية المرحلة والانتقال التلقائي للمرحلة التالية
  // ---------------------------------------------------------------------

  /// هل انتهت جميع مباريات مرحلة/دور معيّن؟
  bool isStageComplete(List<MatchModel> stageMatches) {
    if (stageMatches.isEmpty) return false;
    return stageMatches.every((m) =>
        m.status == MatchStatus.played || m.status == MatchStatus.postponed);
  }

  /// هل توجد مباريات مؤجلة تمنع إنشاء المرحلة التالية؟ (الفصل 6.14)
  bool hasBlockingPostponedMatches(List<MatchModel> stageMatches) {
    return stageMatches.any((m) => m.status == MatchStatus.postponed);
  }

  /// يبني مباريات الدور الإقصائي التالي بعد معرفة الفائزين (الفصل 5.15)
  List<MatchModel> buildNextKnockoutRound({
    required Tournament tournament,
    required List<String> winnersInOrder,
    required int nextRoundNumber,
  }) {
    if (winnersInOrder.length == 1) return []; // انتهت البطولة بالفعل

    final fixtures = KnockoutGenerator.buildNextRound(winnersInOrder);
    return fixtures
        .map((f) => _newMatch(
              tournament: tournament,
              stage: f.stage,
              round: nextRoundNumber,
              homeId: f.homeTeamId,
              awayId: f.awayTeamId,
            ))
        .toList();
  }

  // ---------------------------------------------------------------------
  // الفصل 5.16: نهاية البطولة وتحديد البطل والوصيف والمركز الثالث
  // ---------------------------------------------------------------------
  void finalizeTournament({
    required Tournament tournament,
    required MatchModel finalMatch,
    MatchModel? thirdPlaceMatch,
    required Map<String, String> teamIdToPlayerId,
  }) {
    final championTeam = finalMatch.winnerTeamId;
    if (championTeam == null) return; // النهائي لم يُحسم بعد

    final runnerUpTeam = championTeam == finalMatch.homeTeamId
        ? finalMatch.awayTeamId
        : finalMatch.homeTeamId;

    tournament.championPlayerId = teamIdToPlayerId[championTeam];
    tournament.runnerUpPlayerId = teamIdToPlayerId[runnerUpTeam];

    if (thirdPlaceMatch != null) {
      final thirdTeam = thirdPlaceMatch.winnerTeamId;
      if (thirdTeam != null) {
        tournament.thirdPlacePlayerId = teamIdToPlayerId[thirdTeam];
      }
    }

    tournament.status = TournamentStatus.finished;
    tournament.finishedAt = DateTime.now();
  }
}
