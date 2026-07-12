import 'package:flutter/foundation.dart';
import '../models/enums.dart';
import '../models/match_model.dart';
import '../models/team.dart';
import '../models/tournament.dart';
import '../services/match_progression_service.dart';
import 'match_repository.dart';
import 'team_repository.dart';
import 'tournament_repository.dart';

/// يحمّل بيانات بطولة واحدة (البطولة + الفرق + كل المباريات) ويُشاركها بين
/// كل تبويبات لوحة التحكم (نظرة عامة، المباريات، الترتيب، الإحصائيات)
/// حتى تُحدَّث كلها معًا فور حفظ أي نتيجة (الفصل 9.1).
class TournamentDetailProvider extends ChangeNotifier {
  final String tournamentId;
  final _tournamentRepo = TournamentRepository();
  final _teamRepo = TeamRepository();
  final _matchRepo = MatchRepository();
  final _progressionService = MatchProgressionService();

  TournamentDetailProvider(this.tournamentId);

  Tournament? tournament;
  List<Team> teams = [];
  List<MatchModel> matches = [];
  bool isLoading = true;

  Team? teamById(String id) => teams.where((t) => t.id == id).firstOrNullSafe;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    tournament = await _tournamentRepo.getById(tournamentId);
    teams = await _teamRepo.getByTournament(tournamentId);
    matches = await _matchRepo.getByTournament(tournamentId);

    isLoading = false;
    notifyListeners();
  }

  /// أرقام الجولات المتاحة فعليًا (مُرتبة) — تُستخدم في مستكشف الجولات (الفصل 6.2)
  List<int> get availableRounds =>
      matches.map((m) => m.round).toSet().toList()..sort();

  List<MatchModel> matchesForRound(int round) =>
      matches.where((m) => m.round == round).toList();

  /// أسماء المجموعات الموجودة في مرحلة المجموعات فقط (الفصل 7.7)
  List<String> get groupNames => matches
      .where((m) => m.stage == TournamentStage.groupStage)
      .map((m) => m.groupName)
      .whereType<String>()
      .toSet()
      .toList()
    ..sort();

  Future<void> saveResult({
    required MatchModel match,
    required int homeGoals,
    required int awayGoals,
    int? homePenalties,
    int? awayPenalties,
    bool wentToExtraTime = false,
  }) async {
    await _progressionService.recordResult(
      match: match,
      homeGoals: homeGoals,
      awayGoals: awayGoals,
      homePenalties: homePenalties,
      awayPenalties: awayPenalties,
      wentToExtraTime: wentToExtraTime,
    );
    await load(); // إعادة تحميل كل شيء لضمان تطابق الترتيب والإحصائيات فورًا
  }

  Future<void> postponeMatch(MatchModel match) async {
    await _progressionService.postponeMatch(match);
    await load();
  }

  Future<void> resetRound(int round) async {
    await _progressionService.resetRound(tournamentId, round);
    await load();
  }
}

extension _FirstOrNullSafe<T> on Iterable<T> {
  T? get firstOrNullSafe => isEmpty ? null : first;
}
