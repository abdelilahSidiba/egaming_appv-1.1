import 'package:flutter/material.dart';
import '../../data/player_repository.dart';
import '../../models/player.dart';
import '../../widgets/team_badge.dart';
import '../players/player_details_screen.dart';

/// قاعة الشرف — "متحف" التطبيق، يعرض أفضل اللاعبين عبر التاريخ (الفصل 8.7 / 8.8)
class HallOfFameScreen extends StatefulWidget {
  const HallOfFameScreen({super.key});

  @override
  State<HallOfFameScreen> createState() => _HallOfFameScreenState();
}

class _HallOfFameScreenState extends State<HallOfFameScreen> {
  final _repository = PlayerRepository();
  List<Player> _players = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await _repository.getAll();
    // ترتيب حسب عدد الألقاب، ثم نسبة الفوز عند التعادل (الفصل 8.8)
    all.sort((a, b) {
      final byTitles = b.titlesWon.compareTo(a.titlesWon);
      if (byTitles != 0) return byTitles;
      return b.winRate.compareTo(a.winRate);
    });
    setState(() {
      _players = all;
      _loading = false;
    });
  }

  String _medalFor(int index) {
    switch (index) {
      case 0:
        return '🥇';
      case 1:
        return '🥈';
      case 2:
        return '🥉';
      default:
        return '${index + 1}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('👑 قاعة الشرف')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _players.isEmpty
              ? const Center(child: Text('لا يوجد لاعبون بعد'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _players.length,
                    itemBuilder: (context, index) {
                      final player = _players[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        color: player.isLegend ? Colors.amber.withOpacity(0.12) : null,
                        child: ListTile(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlayerDetailsScreen(playerId: player.id),
                            ),
                          ),
                          leading: SizedBox(
                            width: 56,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_medalFor(index), style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                TeamBadge(
                                  name: player.name,
                                  colorHex: player.colorHex,
                                  photoPath: player.photoPath,
                                  assetPath: player.logoAssetPath,
                                  size: 40,
                                ),
                              ],
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(child: Text(player.name, overflow: TextOverflow.ellipsis)),
                              if (player.isLegend) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            '🏆 ${player.titlesWon} لقب  •  ⚽ ${player.matchesPlayed} مباراة  •  '
                            'نسبة الفوز ${player.winRate.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (i) {
                              final filled = i < player.starRating.round();
                              return Icon(
                                filled ? Icons.star : Icons.star_border,
                                size: 14,
                                color: Colors.amber,
                              );
                            }),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
