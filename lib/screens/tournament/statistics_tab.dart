import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/tournament_detail_provider.dart';
import '../../models/enums.dart';
import '../../models/match_model.dart';
import '../../services/standings_calculator.dart';
import '../../widgets/team_badge.dart';

/// تبويب الإحصائيات العامة للبطولة (الفصل 7.10)
class StatisticsTab extends StatelessWidget {
  const StatisticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentDetailProvider>();
    final stats = StandingsCalculator.computeGeneralStats(provider.matches);

    final totalMatches = stats['totalMatches'] as int;
    if (totalMatches == 0) {
      return const Center(child: Text('لا توجد مباريات منتهية بعد لعرض الإحصائيات'));
    }

    final biggestWin = stats['biggestWin'] as MatchModel?;
    final mostGoals = stats['mostGoalsMatch'] as MatchModel?;
    final leastGoals = stats['leastGoalsMatch'] as MatchModel?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _StatCard(label: 'عدد المباريات', value: '$totalMatches', icon: Icons.sports_soccer),
            _StatCard(label: 'عدد الأهداف', value: '${stats['totalGoals']}', icon: Icons.sports_score),
            _StatCard(
              label: 'معدل الأهداف/مباراة',
              value: '${stats['averageGoalsPerMatch']}',
              icon: Icons.trending_up,
            ),
            _StatCard(
              label: 'المباريات المتبقية',
              value: '${provider.matches.where((m) => m.status == MatchStatus.notPlayed).length}',
              icon: Icons.hourglass_empty,
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (biggestWin != null)
          _MatchHighlightCard(
            title: '🔥 أكبر فوز',
            match: biggestWin,
            provider: provider,
          ),
        if (mostGoals != null)
          _MatchHighlightCard(
            title: '⚽ أكثر مباراة أهدافًا',
            match: mostGoals,
            provider: provider,
          ),
        if (leastGoals != null)
          _MatchHighlightCard(
            title: '🛡️ أقل مباراة أهدافًا',
            match: leastGoals,
            provider: provider,
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _MatchHighlightCard extends StatelessWidget {
  final String title;
  final MatchModel match;
  final TournamentDetailProvider provider;
  const _MatchHighlightCard({required this.title, required this.match, required this.provider});

  @override
  Widget build(BuildContext context) {
    final home = provider.teamById(match.homeTeamId);
    final away = provider.teamById(match.awayTeamId);
    if (home == null || away == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${home.playerNameSnapshot} × ${away.playerNameSnapshot}'),
        leading: TeamBadge(name: home.name, colorHex: home.colorHex, size: 36),
        trailing: Text('${match.homeGoals} - ${match.awayGoals}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
