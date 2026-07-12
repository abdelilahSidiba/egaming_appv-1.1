import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../data/player_repository.dart';
import '../../data/tournament_detail_provider.dart';
import '../../models/enums.dart';
import '../../models/player.dart';
import '../../services/pdf_report_service.dart';
import '../../services/standings_calculator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/team_badge.dart';

/// صفحة تفاصيل بطولة منتهية داخل الأرشيف — تعرضها وكأنها ما زالت جارية
/// (الفصل 8.5)، مع إمكانية تصدير تقرير PDF كامل (الفصل 8.6).
class TournamentArchiveDetailScreen extends StatefulWidget {
  final String tournamentId;
  const TournamentArchiveDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentArchiveDetailScreen> createState() => _TournamentArchiveDetailScreenState();
}

class _TournamentArchiveDetailScreenState extends State<TournamentArchiveDetailScreen> {
  late final TournamentDetailProvider _provider;
  final _playerRepo = PlayerRepository();
  Player? _champion, _runnerUp, _thirdPlace;
  bool _generatingPdf = false;

  @override
  void initState() {
    super.initState();
    _provider = TournamentDetailProvider(widget.tournamentId);
    _load();
  }

  Future<void> _load() async {
    await _provider.load();
    final t = _provider.tournament;
    if (t != null) {
      _champion = t.championPlayerId == null ? null : await _playerRepo.getById(t.championPlayerId!);
      _runnerUp = t.runnerUpPlayerId == null ? null : await _playerRepo.getById(t.runnerUpPlayerId!);
      _thirdPlace = t.thirdPlacePlayerId == null ? null : await _playerRepo.getById(t.thirdPlacePlayerId!);
    }
    if (mounted) setState(() {});
  }

  Future<void> _exportPdf() async {
    final t = _provider.tournament;
    if (t == null) return;
    setState(() => _generatingPdf = true);

    final playersById = <String, Player>{};
    for (final team in _provider.teams) {
      final player = await _playerRepo.getById(team.playerId);
      if (player != null) playersById[team.playerId] = player;
    }

    final doc = await PdfReportService.buildReport(
      tournament: t,
      teams: _provider.teams,
      matches: _provider.matches,
      playersById: playersById,
    );

    setState(() => _generatingPdf = false);

    if (!mounted) return;
    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    final t = _provider.tournament;
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final color = AppTheme.colorFromHex(t.primaryColorHex);
    final stats = StandingsCalculator.computeGeneralStats(_provider.matches);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Text(t.name),
        actions: [
          IconButton(
            icon: _generatingPdf
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf_outlined),
            tooltip: '📄 تصدير تقرير PDF',
            onPressed: _generatingPdf ? null : _exportPdf,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PodiumSection(champion: _champion, runnerUp: _runnerUp, thirdPlace: _thirdPlace),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _InfoStat(label: 'المباريات', value: '${stats['totalMatches']}')),
              Expanded(child: _InfoStat(label: 'الأهداف', value: '${stats['totalGoals']}')),
              Expanded(child: _InfoStat(label: 'الفرق', value: '${_provider.teams.length}')),
            ],
          ),
          const SizedBox(height: 20),
          const Text('كل النتائج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ..._buildResultsByRound(),
        ],
      ),
    );
  }

  List<Widget> _buildResultsByRound() {
    final rounds = _provider.availableRounds;
    return rounds.map((round) {
      final matches = _provider.matchesForRound(round).where((m) => !m.isBye).toList();
      if (matches.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الجولة $round', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ...matches.map((m) {
              final home = _provider.teamById(m.homeTeamId);
              final away = _provider.teamById(m.awayTeamId);
              if (home == null || away == null) return const SizedBox.shrink();
              final scoreText = m.status == MatchStatus.played
                  ? (m.hasPenalties
                      ? '${m.homeGoals}-${m.awayGoals} (${m.homePenalties}-${m.awayPenalties} ر.ت)'
                      : '${m.homeGoals} - ${m.awayGoals}')
                  : '—';
              return ListTile(
                dense: true,
                leading: TeamBadge(name: home.name, colorHex: home.colorHex, size: 28),
                title: Text('${home.playerNameSnapshot} × ${away.playerNameSnapshot}'),
                trailing: Text(scoreText, style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            }),
          ],
        ),
      );
    }).toList();
  }
}

class _PodiumSection extends StatelessWidget {
  final Player? champion;
  final Player? runnerUp;
  final Player? thirdPlace;
  const _PodiumSection({this.champion, this.runnerUp, this.thirdPlace});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _PodiumPlace(player: runnerUp, medal: '🥈', height: 70),
        _PodiumPlace(player: champion, medal: '🥇', height: 95),
        _PodiumPlace(player: thirdPlace, medal: '🥉', height: 55),
      ],
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  final Player? player;
  final String medal;
  final double height;
  const _PodiumPlace({required this.player, required this.medal, required this.height});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(medal, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        TeamBadge(
          name: player?.name ?? '-',
          colorHex: player?.colorHex,
          photoPath: player?.photoPath,
          assetPath: player?.logoAssetPath,
          size: 48,
        ),
        const SizedBox(height: 4),
        Text(player?.name ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
      ],
    );
  }
}

class _InfoStat extends StatelessWidget {
  final String label;
  final String value;
  const _InfoStat({required this.label, required this.value});

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
