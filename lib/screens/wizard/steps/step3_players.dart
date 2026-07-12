import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/player_provider.dart';
import '../../../models/player.dart';
import '../../../widgets/team_badge.dart';
import '../../players/add_edit_player_screen.dart';
import '../wizard_state.dart';

class Step3Players extends StatefulWidget {
  const Step3Players({super.key});

  @override
  State<Step3Players> createState() => _Step3PlayersState();
}

class _Step3PlayersState extends State<Step3Players> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayerProvider>().loadPlayers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wizardState = context.watch<WizardState>();
    final playerProvider = context.watch<PlayerProvider>();
    final required = wizardState.requiredTeamCount;

    final filtered = playerProvider.players
        .where((p) => p.name.contains(_searchController.text.trim()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  required != null
                      ? 'تم اختيار ${wizardState.selectedPlayers.length} / $required لاعبًا'
                      : 'تم اختيار ${wizardState.selectedPlayers.length} لاعبًا',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.person_add_alt_1),
                tooltip: 'إضافة لاعب جديد',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddEditPlayerScreen()),
                  );
                  if (mounted) context.read<PlayerProvider>().loadPlayers();
                },
              ),
            ],
          ),
        ),
        if (required != null && wizardState.selectedPlayers.length < required)
          _ShortagePlayersBanner(
            selectedCount: wizardState.selectedPlayers.length,
            required: required,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'ابحث عن لاعب...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: playerProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const Center(child: Text('لا يوجد لاعبون — أضف لاعبًا أولاً'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final player = filtered[index];
                        final selected = wizardState.isPlayerSelected(player);
                        return CheckboxListTile(
                          value: selected,
                          onChanged: (_) => wizardState.togglePlayer(player),
                          secondary: TeamBadge(
                            name: player.name,
                            colorHex: player.colorHex,
                            photoPath: player.photoPath,
                            assetPath: player.logoAssetPath,
                            size: 40,
                          ),
                          title: Text(player.name),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

/// رسالة الفصل 3.8: "عدد اللاعبين أقل من عدد الفرق الحقيقي"
class _ShortagePlayersBanner extends StatelessWidget {
  final int selectedCount;
  final int required;
  const _ShortagePlayersBanner({required this.selectedCount, required this.required});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'عدد اللاعبين ($selectedCount) أقل من عدد الفرق ($required). '
              'سيتحكم بعض اللاعبين بأكثر من فريق تلقائيًا في خطوة توزيع الفرق، '
              'أو يمكنك إضافة لاعبين آخرين الآن.',
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
