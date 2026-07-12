import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/enums.dart';
import '../../../models/tournament.dart';
import '../../../theme/app_theme.dart';
import '../wizard_state.dart';

const _nationTypes = [
  TournamentType.worldCup,
  TournamentType.africaCup,
  TournamentType.europeCup,
  TournamentType.copaAmerica,
];

const _clubTypes = [
  TournamentType.uclOldFormat,
  TournamentType.uclNewFormat,
  TournamentType.laLiga,
  TournamentType.premierLeague,
  TournamentType.serieA,
  TournamentType.bundesliga,
  TournamentType.ligue1,
];

const _customTypes = [
  TournamentType.customLeague,
  TournamentType.customCup,
  TournamentType.customGroupsKnockout,
];

String _typeDescription(TournamentType type) {
  switch (type) {
    case TournamentType.worldCup:
      return 'مجموعات ثم خروج مغلوب — 32 منتخبًا';
    case TournamentType.africaCup:
      return 'مجموعات ثم خروج مغلوب — 24 منتخبًا';
    case TournamentType.europeCup:
      return 'مجموعات ثم خروج مغلوب — 24 منتخبًا';
    case TournamentType.copaAmerica:
      return 'مجموعات ثم خروج مغلوب — 16 منتخبًا';
    case TournamentType.uclOldFormat:
      return 'مجموعات + ذهاب وإياب — 32 ناديًا';
    case TournamentType.uclNewFormat:
      return 'دوري موحد (8 مباريات) + ملحق — 36 ناديًا';
    case TournamentType.laLiga:
      return 'دوري ذهاب وإياب — 20 ناديًا';
    case TournamentType.premierLeague:
      return 'دوري ذهاب وإياب — 20 ناديًا';
    case TournamentType.serieA:
      return 'دوري ذهاب وإياب — 20 ناديًا';
    case TournamentType.bundesliga:
      return 'دوري ذهاب وإياب — 18 ناديًا';
    case TournamentType.ligue1:
      return 'دوري ذهاب وإياب — 18 ناديًا';
    case TournamentType.customLeague:
      return 'دوري بعدد فرق تحدده أنت';
    case TournamentType.customCup:
      return 'خروج مغلوب مباشر بعدد فرق تحدده أنت';
    case TournamentType.customGroupsKnockout:
      return 'مجموعات ثم خروج مغلوب بعدد فرق تحدده أنت';
  }
}

class Step1TypeSelection extends StatelessWidget {
  const Step1TypeSelection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WizardState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle('🌍 بطولات المنتخبات'),
        ..._nationTypes.map((t) => _TypeCard(type: t, selected: state.selectedType == t)),
        const SizedBox(height: 12),
        const _SectionTitle('🏆 بطولات الأندية'),
        ..._clubTypes.map((t) => _TypeCard(type: t, selected: state.selectedType == t)),
        const SizedBox(height: 12),
        const _SectionTitle('⚽ بطولات مخصصة'),
        ..._customTypes.map((t) => _TypeCard(type: t, selected: state.selectedType == t)),
        if (state.isCustomType) ...[
          const SizedBox(height: 12),
          _CustomTeamCountField(state: state),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final TournamentType type;
  final bool selected;
  const _TypeCard({required this.type, required this.selected});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.colorFromHex(Tournament.defaultColorFor(type));
    final count = Tournament.officialTeamCount(type);

    return Card(
      color: selected ? color.withOpacity(0.15) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: selected ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        onTap: () => context.read<WizardState>().selectType(type),
        leading: CircleAvatar(backgroundColor: color, child: const Icon(Icons.emoji_events, color: Colors.white)),
        title: Text(Tournament.defaultNameFor(type), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(_typeDescription(type)),
        trailing: count != null ? Text('$count فريق') : null,
      ),
    );
  }
}

class _CustomTeamCountField extends StatelessWidget {
  final WizardState state;
  const _CustomTeamCountField({required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Expanded(child: Text('عدد الفرق في هذه البطولة:')),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                final current = state.customTeamCount ?? 4;
                if (current > 2) state.setCustomTeamCount(current - 1);
              },
            ),
            Text('${state.customTeamCount ?? 4}', style: const TextStyle(fontSize: 18)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                final current = state.customTeamCount ?? 4;
                state.setCustomTeamCount(current + 1);
              },
            ),
          ],
        ),
      ),
    );
  }
}
