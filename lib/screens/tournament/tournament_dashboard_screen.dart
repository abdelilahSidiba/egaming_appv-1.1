import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/tournament_detail_provider.dart';
import '../../theme/app_theme.dart';
import 'matches_tab.dart';
import 'standings_tab.dart';
import 'statistics_tab.dart';
import 'tournament_home_tab.dart';

/// لوحة تحكم البطولة الكاملة — مركز التحكم الرئيسي أثناء البطولة (الفصل 9.1 / 9.4)
/// تبويبات: 🏠 الرئيسية | ⚽ المباريات | 📊 الترتيب | 📈 الإحصائيات
class TournamentDashboardScreen extends StatelessWidget {
  final String tournamentId;
  const TournamentDashboardScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TournamentDetailProvider(tournamentId)..load(),
      child: const _DashboardBody(),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentDetailProvider>();

    if (provider.isLoading || provider.tournament == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tournament = provider.tournament!;
    final color = AppTheme.colorFromHex(tournament.primaryColorHex);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: color,
          foregroundColor: Colors.white,
          title: Text(tournament.name),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.home_outlined), text: 'الرئيسية'),
              Tab(icon: Icon(Icons.sports_soccer_outlined), text: 'المباريات'),
              Tab(icon: Icon(Icons.leaderboard_outlined), text: 'الترتيب'),
              Tab(icon: Icon(Icons.bar_chart_outlined), text: 'الإحصائيات'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TournamentHomeTab(),
            MatchesTab(),
            StandingsTab(),
            StatisticsTab(),
          ],
        ),
      ),
    );
  }
}
