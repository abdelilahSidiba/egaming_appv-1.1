import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/tournament_detail_provider.dart';
import '../../models/enums.dart';
import '../../models/match_model.dart';
import '../../models/standing_entry.dart';
import '../../models/team.dart';
import '../../services/standings_calculator.dart';
import '../../widgets/team_badge.dart';

/// تبويب جدول الترتيب (الفصل 7.3 / 7.4) — يدعم مجموعات متعددة (الفصل 7.7)
class StandingsTab extends StatefulWidget {
  const StandingsTab({super.key});

  @override
  State<StandingsTab> createState() => _StandingsTabState();
}

class _StandingsTabState extends State<StandingsTab> {
  String? _selectedGroup;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentDetailProvider>();
    final tournament = provider.tournament;
    if (tournament == null) return const SizedBox.shrink();

    final groupNames = provider.groupNames;
    final hasGroups = groupNames.isNotEmpty;

    // بطولات الكأس المحضة لا تحتاج جدول ترتيب (الفصل 7.9)
    if (tournament.format == TournamentFormat.cup) {
      return const Center(child: Text('لا يوجد جدول ترتيب لبطولات الكأس'));
    }

    List<Team> relevantTeams;
    List<MatchModel> relevantMatches;

    if (hasGroups) {
      _selectedGroup ??= groupNames.first;
      relevantTeams = provider.teams.where((t) => t.groupName == _selectedGroup).toList();
      relevantMatches = provider.matches
          .where((m) => m.stage == TournamentStage.groupStage && m.groupName == _selectedGroup)
          .toList();
    } else {
      relevantTeams = provider.teams;
      relevantMatches = provider.matches
          .where((m) => m.stage == TournamentStage.leagueStage)
          .toList();
    }

    final table = StandingsCalculator.calculate(
      teamIds: relevantTeams.map((t) => t.id).toList(),
      matches: relevantMatches,
      rules: tournament.rules,
    );
    final ranked = StandingsCalculator.sortStandings(
      table: table,
      allMatchesForHeadToHead: relevantMatches,
      rules: tournament.rules,
    );

    final isSwissFormat = tournament.format == TournamentFormat.swissThenKnockout;

    return Column(
      children: [
        if (hasGroups)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: groupNames.map((g) {
                final selected = g == _selectedGroup;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('مجموعة $g'),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedGroup = g),
                  ),
                );
              }).toList(),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: _StandingsTable(
              ranked: ranked,
              table: table,
              teams: relevantTeams,
              qualifiersCount: hasGroups ? tournament.rules.qualifiersPerGroup : null,
              isSwissFormat: isSwissFormat,
            ),
          ),
        ),
      ],
    );
  }
}

class _StandingsTable extends StatelessWidget {
  final List<String> ranked;
  final Map<String, StandingEntry> table;
  final List<Team> teams;
  final int? qualifiersCount;
  final bool isSwissFormat;

  const _StandingsTable({
    required this.ranked,
    required this.table,
    required this.teams,
    required this.qualifiersCount,
    required this.isSwissFormat,
  });

  Color? _rowColor(int position, int total) {
    if (isSwissFormat) {
      if (position <= 8) return Colors.green.withOpacity(0.12);
      if (position <= 24) return Colors.orange.withOpacity(0.12);
      return Colors.red.withOpacity(0.08);
    }
    if (qualifiersCount != null) {
      if (position <= qualifiersCount!) return Colors.green.withOpacity(0.12);
    }
    if (position == 1) return Colors.amber.withOpacity(0.15);
    if (position == 2) return Colors.grey.withOpacity(0.15);
    if (position == 3) return const Color(0xFFCD7F32).withOpacity(0.12);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('اللاعب')),
          DataColumn(label: Text('لعب')),
          DataColumn(label: Text('فاز')),
          DataColumn(label: Text('تعادل')),
          DataColumn(label: Text('خسر')),
          DataColumn(label: Text('له')),
          DataColumn(label: Text('عليه')),
          DataColumn(label: Text('الفرق')),
          DataColumn(label: Text('نقاط')),
        ],
        rows: List.generate(ranked.length, (index) {
          final teamId = ranked[index];
          final entry = table[teamId]!;
          final team = teams.firstWhere((t) => t.id == teamId);
          final position = index + 1;

          return DataRow(
            color: WidgetStateProperty.all(_rowColor(position, ranked.length)),
            cells: [
              DataCell(Text('$position')),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TeamBadge(name: team.name, colorHex: team.colorHex, size: 26),
                  const SizedBox(width: 6),
                  Text(team.playerNameSnapshot ?? ''),
                ],
              )),
              DataCell(Text('${entry.played}')),
              DataCell(Text('${entry.won}')),
              DataCell(Text('${entry.drawn}')),
              DataCell(Text('${entry.lost}')),
              DataCell(Text('${entry.goalsFor}')),
              DataCell(Text('${entry.goalsAgainst}')),
              DataCell(Text('${entry.goalDifference}')),
              DataCell(Text('${entry.points}', style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          );
        }),
      ),
    );
  }
}
