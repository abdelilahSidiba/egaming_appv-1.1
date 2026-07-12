import 'package:flutter/material.dart';
import '../../data/tournament_repository.dart';
import '../../models/enums.dart';
import '../../models/tournament.dart';
import '../../theme/app_theme.dart';
import '../../widgets/team_badge.dart';
import '../archive/tournament_archive_detail_screen.dart';
import '../wizard/tournament_wizard_screen.dart';
import 'tournament_dashboard_screen.dart';

/// صفحة "البطولات" — تبويبان: الجارية (وزر الإنشاء)، والأرشيف 🏛️ (الفصل 3.2 / 8.2)
class TournamentsListScreen extends StatefulWidget {
  const TournamentsListScreen({super.key});

  @override
  State<TournamentsListScreen> createState() => _TournamentsListScreenState();
}

class _TournamentsListScreenState extends State<TournamentsListScreen>
    with SingleTickerProviderStateMixin {
  final _repository = TournamentRepository();
  late final TabController _tabController;

  List<Tournament> _activeTournaments = [];
  List<Tournament> _archivedTournaments = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final active = await _repository.getAll();
    final archived = await _repository.getAll(
      status: TournamentStatus.finished,
      searchQuery: _searchController.text,
    );
    setState(() {
      _activeTournaments = active.where((t) => t.status != TournamentStatus.finished).toList();
      _archivedTournaments = archived;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 البطولات'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الجارية'),
            Tab(text: '🏛️ الأرشيف'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveList(),
                _buildArchiveList(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openWizard,
        icon: const Icon(Icons.add),
        label: const Text('إنشاء بطولة'),
      ),
    );
  }

  Widget _buildActiveList() {
    if (_activeTournaments.isEmpty) return _EmptyState(onCreate: _openWizard);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 90, top: 8),
        itemCount: _activeTournaments.length,
        itemBuilder: (context, index) {
          final t = _activeTournaments[index];
          return _TournamentCard(
            tournament: t,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TournamentDashboardScreen(tournamentId: t.id)),
              );
              _load();
            },
          );
        },
      ),
    );
  }

  Widget _buildArchiveList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'ابحث باسم البطولة...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => _load(),
          ),
        ),
        Expanded(
          child: _archivedTournaments.isEmpty
              ? const Center(child: Text('لا توجد بطولات منتهية بعد'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: _archivedTournaments.length,
                    itemBuilder: (context, index) {
                      final t = _archivedTournaments[index];
                      return _TournamentCard(
                        tournament: t,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TournamentArchiveDetailScreen(tournamentId: t.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _openWizard() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TournamentWizardScreen()),
    );
    _load();
  }
}

class _TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;
  const _TournamentCard({required this.tournament, required this.onTap});

  String get _statusLabel {
    switch (tournament.status) {
      case TournamentStatus.notStarted:
        return '🟡 لم تبدأ';
      case TournamentStatus.ongoing:
        return '🟢 جارية';
      case TournamentStatus.finished:
        return '🔵 انتهت';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.colorFromHex(tournament.primaryColorHex);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              TeamBadge(name: tournament.name, colorHex: tournament.primaryColorHex, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tournament.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(_statusLabel, style: TextStyle(color: color, fontSize: 12)),
                    if (tournament.totalRounds > 0)
                      Text(
                        '${tournament.currentRound} / ${tournament.totalRounds} جولة',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined, size: 72, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('لا توجد بطولات جارية بعد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('أنشئ أول بطولة لك خلال أقل من دقيقة', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('إنشاء بطولة'),
            ),
          ],
        ),
      ),
    );
  }
}
