import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/official_tournament_data.dart';
import '../../../widgets/team_badge.dart';
import '../wizard_state.dart';

class Step4TeamDistribution extends StatefulWidget {
  const Step4TeamDistribution({super.key});

  @override
  State<Step4TeamDistribution> createState() => _Step4TeamDistributionState();
}

class _Step4TeamDistributionState extends State<Step4TeamDistribution> {
  final _random = Random();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<WizardState>();
      if (state.teamSlots.isEmpty) _draw(state);
    });
  }

  /// يبني قائمة أسماء الفرق المتاحة: من مكتبة التطبيق للبطولات الرسمية،
  /// أو أسماء افتراضية قابلة للتعديل يدويًا للبطولات المخصصة (الفصل 3.5)
  List<OfficialTeamData> _teamPool(WizardState state) {
    if (!state.isCustomType && state.selectedType != null) {
      final officialPool = OfficialTournamentData.teamsFor(state.selectedType!);
      if (officialPool.isNotEmpty) return officialPool;
    }
    final count = state.requiredTeamCount ?? state.selectedPlayers.length;
    return List.generate(count, (i) => OfficialTeamData('فريق ${i + 1}', '#1565C0'));
  }

  /// يوزّع عدد فتحات الفرق على اللاعبين بعدالة (الفصل 3.10)
  List<String> _playerIdsPerSlot(WizardState state, int slotCount) {
    final players = state.selectedPlayers;
    final result = <String>[];
    for (int i = 0; i < slotCount; i++) {
      result.add(players[i % players.length].id);
    }
    return result;
  }

  /// إجراء القرعة العشوائية الكاملة (الفصل 3.9) — يُستدعى عند أول دخول
  /// للخطوة، وأيضًا عند الضغط على "🎲 إعادة القرعة"
  void _draw(WizardState state) {
    final pool = List<OfficialTeamData>.from(_teamPool(state))..shuffle(_random);
    final slotCount = state.requiredTeamCount ?? state.selectedPlayers.length;
    final playerIds = _playerIdsPerSlot(state, slotCount)..shuffle(_random);

    final slots = <TeamSlot>[];
    for (int i = 0; i < slotCount; i++) {
      final playerId = playerIds[i];
      final player = state.selectedPlayers.firstWhere((p) => p.id == playerId);
      final teamData = pool[i % pool.length];
      slots.add(TeamSlot(
        playerId: player.id,
        playerName: player.name,
        playerColorHex: player.colorHex,
        teamName: teamData.name,
        teamColorHex: teamData.colorHex,
      ));
    }
    state.setTeamSlots(slots);
  }

  Future<void> _renameSlot(WizardState state, TeamSlot slot) async {
    final controller = TextEditingController(text: slot.teamName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل اسم الفريق'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      setState(() => slot.teamName = newName);
      state.setTeamSlots(state.teamSlots); // لإشعار المستمعين بالتغيير
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WizardState>();

    // ترتيب العرض: تجميع فتحات كل لاعب معًا لتسهيل القراءة
    final grouped = <String, List<TeamSlot>>{};
    for (final slot in state.teamSlots) {
      grouped.putIfAbsent(slot.playerId, () => []).add(slot);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: state.drawConfirmed ? null : () => _draw(state),
                  icon: const Icon(Icons.casino_outlined),
                  label: const Text('🎲 إعادة القرعة'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.drawConfirmed
                      ? null
                      : () {
                          state.confirmDraw();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('🎉 اكتملت القرعة!')),
                          );
                        },
                  icon: Icon(state.drawConfirmed ? Icons.check_circle : Icons.check),
                  label: Text(state.drawConfirmed ? 'تم الاعتماد' : '✅ اعتماد القرعة'),
                ),
              ),
            ],
          ),
        ),
        if (state.drawConfirmed)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'لا يمكن تعديل الفرق بعد الاعتماد — احذف البطولة وأعد إنشاءها لتغييرها لاحقًا.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries.map((entry) {
              final slots = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TeamBadge(name: slots.first.playerName, colorHex: slots.first.playerColorHex, size: 32),
                          const SizedBox(width: 8),
                          Text(slots.first.playerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (slots.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Chip(
                                label: Text('${slots.length} فرق', style: const TextStyle(fontSize: 11)),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                        ],
                      ),
                      const Divider(),
                      ...slots.map((slot) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: TeamBadge(name: slot.teamName, colorHex: slot.teamColorHex, size: 36),
                            title: Text(slot.teamName),
                            trailing: state.drawConfirmed
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    onPressed: () => _renameSlot(state, slot),
                                  ),
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
