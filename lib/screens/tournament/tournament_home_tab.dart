import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/tournament_detail_provider.dart';
import '../../models/enums.dart';
import '../../services/standings_calculator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/team_badge.dart';

/// تبويب "الرئيسية" داخل البطولة — ملخص سريع (الفصل 9.5)
class TournamentHomeTab extends StatelessWidget {
  const TournamentHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentDetailProvider>();
    final tournament = provider.tournament;
    if (tournament == null) return const SizedBox.shrink();

    final color = AppTheme.colorFromHex(tournament.primaryColorHex);
    final nextMatch = provider.matches
        .where((m) => m.status == MatchStatus.notPlayed && !m.isBye)
        .toList();
    nextMatch.sort((a, b) => a.round.compareTo(b.round));

    final generalStats = StandingsCalculator.computeGeneralStats(provider.matches);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _IdentityCard(color: color, progressPercent: tournament.progressPercent, tournament: tournament),
        const SizedBox(height: 16),
        if (nextMatch.isNotEmpty) _NextMatchCard(match: nextMatch.first, provider: provider),
        const SizedBox(height: 16),
        _QuickStatsCard(stats: generalStats, remaining: provider.matches.where((m) => m.status == MatchStatus.notPlayed).length),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final Color color;
  final double progressPercent;
  final dynamic tournament;
  const _IdentityCard({required this.color, required this.progressPercent, required this.tournament});

  String get _statusLabel {
    switch (tournament.status) {
      case TournamentStatus.notStarted:
        return '🟡 لم تبدأ';
      case TournamentStatus.ongoing:
        return '🟢 البطولة جارية';
      case TournamentStatus.finished:
        return '🔵 انتهت البطولة';
      default:
        return '⚪ حالة غير معروفة';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TeamBadge(name: tournament.name, colorHex: tournament.primaryColorHex, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tournament.name,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(_statusLabel, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressPercent / 100,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${tournament.currentRound} / ${tournament.totalRounds} جولة (${progressPercent.toStringAsFixed(0)}%)',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _NextMatchCard extends StatelessWidget {
  final dynamic match;
  final TournamentDetailProvider provider;
  const _NextMatchCard({required this.match, required this.provider});

  @override
  Widget build(BuildContext context) {
    final home = provider.teamById(match.homeTeamId);
    final away = provider.teamById(match.awayTeamId);
    if (home == null || away == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('⏭️ المباراة القادمة', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(children: [
                  TeamBadge(name: home.name, colorHex: home.colorHex, size: 44),
                  Text(home.playerNameSnapshot ?? ''),
                ]),
                const Text('×', style: TextStyle(fontSize: 20)),
                Column(children: [
                  TeamBadge(name: away.name, colorHex: away.colorHex, size: 44),
                  Text(away.playerNameSnapshot ?? ''),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  final int remaining;
  const _QuickStatsCard({required this.stats, required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _MiniStat(label: 'المباريات', value: '${stats['totalMatches']}'),
            _MiniStat(label: 'الأهداف', value: '${stats['totalGoals']}'),
            _MiniStat(label: 'المتبقي', value: '$remaining'),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
