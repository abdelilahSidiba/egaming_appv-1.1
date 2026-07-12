import 'package:flutter/material.dart';
import '../models/player.dart';
import 'team_badge.dart';

/// بطاقة اللاعب داخل صفحة "اللاعبون" (الفصل 2.2)
class PlayerCard extends StatelessWidget {
  final Player player;
  final VoidCallback onTap;

  const PlayerCard({super.key, required this.player, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              TeamBadge(
                name: player.name,
                colorHex: player.colorHex,
                photoPath: player.photoPath,
                assetPath: player.logoAssetPath,
                size: 56,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            player.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (player.isLegend) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StatChip(icon: '🏆', label: '${player.tournamentsPlayed} بطولة'),
                        const SizedBox(width: 8),
                        _StatChip(icon: '🥇', label: '${player.titlesWon} لقب'),
                        const SizedBox(width: 8),
                        _StatChip(icon: '⚽', label: '${player.matchesPlayed} مباراة'),
                      ],
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

class _StatChip extends StatelessWidget {
  final String icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text('$icon $label', style: const TextStyle(fontSize: 12));
  }
}
