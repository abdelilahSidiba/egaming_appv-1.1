import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/enums.dart';
import '../models/match_model.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/tournament.dart';
import 'standings_calculator.dart';

/// يبني مستند PDF كامل لتقرير البطولة (الفصل 8.6 / 5.17)
/// يحتوي على: معلومات البطولة، البطل والوصيف والثالث، الترتيب النهائي،
/// وجميع النتائج — كل ذلك دون الحاجة إلى إنترنت.
class PdfReportService {
  static Future<pw.Document> buildReport({
    required Tournament tournament,
    required List<Team> teams,
    required List<MatchModel> matches,
    required Map<String, Player> playersById,
  }) async {
    final doc = pw.Document();
    final generalStats = StandingsCalculator.computeGeneralStats(matches);

    final hasGroups = matches.any((m) => m.stage == TournamentStage.groupStage);
    final leagueMatches = matches
        .where((m) => m.stage == TournamentStage.leagueStage || m.stage == TournamentStage.groupStage)
        .toList();

    Map<String, dynamic>? standingsSection;
    if (!hasGroups && tournament.format != TournamentFormat.cup) {
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
      standingsSection = {'table': table, 'ranked': ranked};
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text(tournament.name, style: const pw.TextStyle(fontSize: 24))),
          pw.Text('تقرير البطولة الكامل', style: const pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 16),
          _buildSummarySection(tournament, generalStats, playersById),
          pw.SizedBox(height: 16),
          if (standingsSection != null)
            _buildStandingsSection(standingsSection, teams),
          pw.SizedBox(height: 16),
          _buildResultsSection(matches, teams),
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _buildSummarySection(
    Tournament tournament,
    Map<String, dynamic> stats,
    Map<String, Player> playersById,
  ) {
    String playerName(String? id) => id == null ? '-' : (playersById[id]?.name ?? '-');

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('🥇 البطل: ${playerName(tournament.championPlayerId)}'),
          pw.Text('🥈 الوصيف: ${playerName(tournament.runnerUpPlayerId)}'),
          if (tournament.thirdPlacePlayerId != null)
            pw.Text('🥉 المركز الثالث: ${playerName(tournament.thirdPlacePlayerId)}'),
          pw.SizedBox(height: 8),
          pw.Text('عدد المباريات: ${stats['totalMatches']}'),
          pw.Text('عدد الأهداف: ${stats['totalGoals']}'),
          pw.Text('معدل الأهداف لكل مباراة: ${stats['averageGoalsPerMatch']}'),
        ],
      ),
    );
  }

  static pw.Widget _buildStandingsSection(Map<String, dynamic> section, List<Team> teams) {
    final ranked = section['ranked'] as List<String>;
    final table = section['table'] as Map<String, dynamic>;

    final rows = <List<String>>[
      ['#', 'اللاعب', 'لعب', 'فاز', 'تعادل', 'خسر', 'له', 'عليه', 'الفرق', 'نقاط'],
    ];

    for (int i = 0; i < ranked.length; i++) {
      final teamId = ranked[i];
      final entry = table[teamId];
      final team = teams.firstWhere((t) => t.id == teamId);
      rows.add([
        '${i + 1}',
        team.playerNameSnapshot ?? '',
        '${entry.played}',
        '${entry.won}',
        '${entry.drawn}',
        '${entry.lost}',
        '${entry.goalsFor}',
        '${entry.goalsAgainst}',
        '${entry.goalDifference}',
        '${entry.points}',
      ]);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('جدول الترتيب النهائي', style: const pw.TextStyle(fontSize: 16)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(data: rows),
      ],
    );
  }

  static pw.Widget _buildResultsSection(List<MatchModel> matches, List<Team> teams) {
    Team? teamById(String id) => teams.where((t) => t.id == id).isEmpty
        ? null
        : teams.firstWhere((t) => t.id == id);

    final played = matches.where((m) => m.status == MatchStatus.played && !m.isBye).toList()
      ..sort((a, b) => a.round.compareTo(b.round));

    final rows = <List<String>>[
      ['الجولة', 'الفريق الأول', 'النتيجة', 'الفريق الثاني'],
    ];
    for (final m in played) {
      final home = teamById(m.homeTeamId);
      final away = teamById(m.awayTeamId);
      final scoreText = m.hasPenalties
          ? '${m.homeGoals}-${m.awayGoals} (${m.homePenalties}-${m.awayPenalties} ر.ت)'
          : '${m.homeGoals}-${m.awayGoals}';
      rows.add([
        '${m.round}',
        home?.playerNameSnapshot ?? '-',
        scoreText,
        away?.playerNameSnapshot ?? '-',
      ]);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('جميع النتائج', style: const pw.TextStyle(fontSize: 16)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(data: rows),
      ],
    );
  }
}
