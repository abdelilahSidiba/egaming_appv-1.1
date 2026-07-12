import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/player_provider.dart';
import '../../data/player_repository.dart';
import '../../data/team_repository.dart';
import '../../data/tournament_repository.dart';
import '../../models/enums.dart';
import '../../models/player.dart';
import '../../services/achievements_service.dart';
import '../../services/head_to_head_service.dart';
import '../../widgets/team_badge.dart';
import 'add_edit_player_screen.dart';

/// عنصر سجل بطولة واحدة داخل صفحة اللاعب (الفصل 2.10)
class _TournamentHistoryItem {
  final String tournamentName;
  final String? tournamentLogo;
  final TournamentResult result;
  _TournamentHistoryItem(this.tournamentName, this.tournamentLogo, this.result);
}

class PlayerDetailsScreen extends StatefulWidget {
  final String playerId;
  const PlayerDetailsScreen({super.key, required this.playerId});

  @override
  State<PlayerDetailsScreen> createState() => _PlayerDetailsScreenState();
}

class _PlayerDetailsScreenState extends State<PlayerDetailsScreen> {
  final _playerRepo = PlayerRepository();
  final _teamRepo = TeamRepository();
  final _tournamentRepo = TournamentRepository();
  final _headToHeadService = HeadToHeadService();

  Player? _player;
  List<_TournamentHistoryItem> _history = [];
  List<RivalryRecord> _rivalries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final player = await _playerRepo.getById(widget.playerId);
    final teams = await _teamRepo.getByPlayer(widget.playerId);

    final history = <_TournamentHistoryItem>[];
    for (final team in teams) {
      final tournament = await _tournamentRepo.getById(team.tournamentId);
      if (tournament == null) continue;

      TournamentResult result = TournamentResult.participant;
      if (tournament.championPlayerId == widget.playerId) {
        result = TournamentResult.champion;
      } else if (tournament.runnerUpPlayerId == widget.playerId) {
        result = TournamentResult.runnerUp;
      } else if (tournament.thirdPlacePlayerId == widget.playerId) {
        result = TournamentResult.thirdPlace;
      }

      history.add(_TournamentHistoryItem(tournament.name, tournament.logoAssetPath, result));
    }

    final rivalries = await _headToHeadService.getRivalries(widget.playerId);

    setState(() {
      _player = player;
      _history = history;
      _rivalries = rivalries;
      _loading = false;
    });
  }

  Future<void> _confirmDelete() async {
    final provider = context.read<PlayerProvider>();
    final active = await provider.isPlayerInActiveTournament(widget.playerId);

    if (active) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('لا يمكن حذف اللاعب'),
          content: const Text('لأنه يشارك في بطولة نشطة حاليًا.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('حسنًا'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف اللاعب'),
        content: Text('هل أنت متأكد من حذف "${_player?.name}"؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deletePlayer(widget.playerId);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final player = _player;
    if (player == null) {
      return const Scaffold(body: Center(child: Text('تعذّر إيجاد اللاعب')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(player.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEditPlayerScreen(existingPlayer: player),
                ),
              );
              _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                TeamBadge(
                  name: player.name,
                  colorHex: player.colorHex,
                  photoPath: player.photoPath,
                  assetPath: player.logoAssetPath,
                  size: 110,
                ),
                const SizedBox(height: 12),
                Text(player.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                if (player.isLegend)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Chip(
                      label: Text('⭐ أسطورة eGaming'),
                      backgroundColor: Color(0xFFFFD700),
                    ),
                  ),
                Text(
                  'أُضيف بتاريخ ${DateFormat('yyyy/MM/dd').format(player.createdAt)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _StatsGrid(player: player),
          const SizedBox(height: 24),
          _AchievementsSection(player: player),
          const SizedBox(height: 24),
          if (_rivalries.isNotEmpty) ...[
            Text('🤝 المواجهات المباشرة', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._rivalries.map((r) => _RivalryCard(rivalry: r)),
            const SizedBox(height: 24),
          ],
          Text('🏆 سجل البطولات', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_history.isEmpty)
            const Text('لم يشارك هذا اللاعب في أي بطولة بعد.',
                style: TextStyle(color: Colors.grey))
          else
            ..._history.map((h) => Card(
                  child: ListTile(
                    leading: TeamBadge(name: h.tournamentName, size: 40),
                    title: Text(h.tournamentName),
                    trailing: _ResultBadge(result: h.result),
                  ),
                )),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Player player;
  const _StatsGrid({required this.player});

  @override
  Widget build(BuildContext context) {
    final stats = <(String, String)>[
      ('عدد البطولات', '${player.tournamentsPlayed}'),
      ('الألقاب', '${player.titlesWon}'),
      ('الوصافة', '${player.runnerUpCount}'),
      ('المركز الثالث', '${player.thirdPlaceCount}'),
      ('المباريات', '${player.matchesPlayed}'),
      ('الانتصارات', '${player.wins}'),
      ('التعادلات', '${player.draws}'),
      ('الهزائم', '${player.losses}'),
      ('الأهداف المسجلة', '${player.goalsFor}'),
      ('الأهداف المستقبلة', '${player.goalsAgainst}'),
      ('فارق الأهداف', '${player.goalDifference}'),
      ('نسبة الفوز', '${player.winRate.toStringAsFixed(1)}%'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final (label, value) = stats[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  final Player player;
  const _AchievementsSection({required this.player});

  @override
  Widget build(BuildContext context) {
    final achievements = AchievementsService.computeFor(player);
    if (achievements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🏅 الإنجازات', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: achievements
              .map((a) => Chip(label: Text('${a.emoji} ${a.label}')))
              .toList(),
        ),
      ],
    );
  }
}

class _RivalryCard extends StatelessWidget {
  final RivalryRecord rivalry;
  const _RivalryCard({required this.rivalry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TeamBadge(name: rivalry.rivalName, size: 32),
                const SizedBox(width: 8),
                Text(rivalry.rivalName, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${rivalry.played} مباراة', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _RivalryStat(label: 'فوز', value: '${rivalry.wins}'),
                _RivalryStat(label: 'تعادل', value: '${rivalry.draws}'),
                _RivalryStat(label: 'خسارة', value: '${rivalry.losses}'),
                _RivalryStat(label: 'الأهداف', value: '${rivalry.goalsFor}-${rivalry.goalsAgainst}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RivalryStat extends StatelessWidget {
  final String label;
  final String value;
  const _RivalryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _ResultBadge extends StatelessWidget {
  final TournamentResult result;
  const _ResultBadge({required this.result});

  @override
  Widget build(BuildContext context) {
    switch (result) {
      case TournamentResult.champion:
        return const Text('🥇 البطل');
      case TournamentResult.runnerUp:
        return const Text('🥈 الوصيف');
      case TournamentResult.thirdPlace:
        return const Text('🥉 الثالث');
      case TournamentResult.participant:
        return const Text('مشارك', style: TextStyle(color: Colors.grey));
    }
  }
}
