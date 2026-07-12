import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../data/tournament_repository.dart';
import '../../../models/enums.dart';
import '../../../models/match_model.dart';
import '../../../models/team.dart';
import '../../../models/tournament.dart';
import '../../../services/tournament_engine.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/team_badge.dart';
import '../../tournament/tournament_dashboard_screen.dart';
import '../wizard_state.dart';

class Step6Review extends StatefulWidget {
  const Step6Review({super.key});

  @override
  State<Step6Review> createState() => _Step6ReviewState();
}

class _Step6ReviewState extends State<Step6Review> {
  bool _isCreating = false;

  Future<void> _createTournament(WizardState state) async {
    setState(() => _isCreating = true);
    try {
      final engine = TournamentEngine();
      const uuid = Uuid();
      final tournamentId = uuid.v4();

      // بناء الفرق مباشرة من فتحات القرعة المعتمدة (تحتفظ بلون كل فريق)
      final teams = <Team>[];
      int seed = 0;
      for (final slot in state.teamSlots) {
        teams.add(Team(
          id: 'team_${tournamentId}_$seed',
          tournamentId: tournamentId,
          name: slot.teamName,
          playerId: slot.playerId,
          playerNameSnapshot: slot.playerName,
          colorHex: slot.teamColorHex,
          seed: seed,
        ));
        seed++;
      }

      final teamsPerPlayer = <String, int>{};
      for (final slot in state.teamSlots) {
        teamsPerPlayer[slot.playerId] = (teamsPerPlayer[slot.playerId] ?? 0) + 1;
      }
      final allowsMulti = teamsPerPlayer.values.any((c) => c > 1);

      final tournament = Tournament(
        id: tournamentId,
        name: state.name.trim(),
        type: state.selectedType!,
        format: Tournament.formatFor(state.selectedType!),
        primaryColorHex: state.primaryColorHex,
        startDate: state.tournamentDate,
        notes: state.notes,
        status: TournamentStatus.ongoing,
        rules: state.rules,
        allowsMultiTeamPerPlayer: allowsMulti,
      );

      // التحقق النهائي من صحة البيانات قبل الحفظ (الفصل 5.3)
      engine.validate(
        tournamentName: tournament.name,
        assignments: _buildAssignments(state),
        requiredTeamCount: state.requiredTeamCount,
      );

      final matches = engine.generateInitialFixtures(tournament: tournament, teams: teams);

      await TournamentRepository().createFullTournament(
        tournament: tournament,
        teams: teams,
        matches: matches,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TournamentDashboardScreen(tournamentId: tournament.id),
        ),
      );
    } on TournamentValidationException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('حدث خطأ غير متوقع أثناء إنشاء البطولة: $e');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  List<PlayerTeamAssignment> _buildAssignments(WizardState state) {
    final grouped = <String, List<String>>{};
    for (final slot in state.teamSlots) {
      grouped.putIfAbsent(slot.playerId, () => []).add(slot.teamName);
    }
    return state.selectedPlayers
        .where((p) => grouped.containsKey(p.id))
        .map((p) => PlayerTeamAssignment(p, grouped[p.id]!))
        .toList();
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعذّر إنشاء البطولة'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('حسنًا')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WizardState>();
    final color = AppTheme.colorFromHex(state.primaryColorHex);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: color.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                TeamBadge(name: state.name, colorHex: state.primaryColorHex, size: 60),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(state.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(Tournament.defaultNameFor(state.selectedType!) == state.name
                          ? 'بطولة رسمية'
                          : 'بطولة مخصصة الاسم'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ReviewTile(icon: Icons.people_outline, label: 'عدد اللاعبين', value: '${state.selectedPlayers.length}'),
        _ReviewTile(icon: Icons.shield_outlined, label: 'عدد الفرق', value: '${state.teamSlots.length}'),
        _ReviewTile(
          icon: Icons.calendar_today_outlined,
          label: 'تاريخ البطولة',
          value: state.tournamentDate != null ? DateFormat('yyyy/MM/dd').format(state.tournamentDate!) : 'غير محدد',
        ),
        _ReviewTile(
          icon: Icons.rule_outlined,
          label: 'مستوى القوانين',
          value: switch (state.rulesLevel) {
            RulesLevel.official => '🟢 رسمي 100%',
            RulesLevel.modified => '🟡 معدل',
            RulesLevel.fullyCustom => '🔴 مخصص بالكامل',
          },
        ),
        if (state.notes != null && state.notes!.trim().isNotEmpty)
          _ReviewTile(icon: Icons.notes_outlined, label: 'ملاحظات', value: state.notes!),
        const SizedBox(height: 20),
        const Text('الفرق المشاركة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: state.teamSlots
              .map((slot) => Chip(
                    avatar: TeamBadge(name: slot.teamName, colorHex: slot.teamColorHex, size: 24),
                    label: Text('${slot.teamName} (${slot.playerName})', style: const TextStyle(fontSize: 11)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: _isCreating ? null : () => _createTournament(state),
          icon: _isCreating
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.emoji_events),
          label: Text(_isCreating ? 'جارٍ الإنشاء...' : '🏆 إنشاء البطولة'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: color),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ReviewTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
