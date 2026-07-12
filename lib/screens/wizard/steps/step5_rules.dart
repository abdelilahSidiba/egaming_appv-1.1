import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/rule_template_repository.dart';
import '../../../models/enums.dart';
import '../../../models/tournament.dart';
import '../wizard_state.dart';

String _tiebreakLabel(TiebreakCriteria c) {
  switch (c) {
    case TiebreakCriteria.points:
      return 'النقاط';
    case TiebreakCriteria.headToHead:
      return 'المواجهات المباشرة';
    case TiebreakCriteria.goalDifference:
      return 'فارق الأهداف';
    case TiebreakCriteria.goalsFor:
      return 'الأهداف المسجلة';
    case TiebreakCriteria.goalsAgainstFewest:
      return 'أقل أهداف مستقبلة';
    case TiebreakCriteria.draw:
      return 'القرعة';
  }
}

String _knockoutRuleLabel(KnockoutTiebreakRule r) {
  switch (r) {
    case KnockoutTiebreakRule.directPenalties:
      return 'مباشرة إلى ركلات الترجيح';
    case KnockoutTiebreakRule.extraTimeThenPenalties:
      return 'أشواط إضافية ثم ركلات ترجيح';
    case KnockoutTiebreakRule.replayMatch:
      return 'إعادة المباراة';
  }
}

class Step5Rules extends StatelessWidget {
  const Step5Rules({super.key});

  bool _hasKnockoutStage(TournamentFormat? format) =>
      format == TournamentFormat.cup ||
      format == TournamentFormat.groupsThenKnockout ||
      format == TournamentFormat.swissThenKnockout;

  bool _hasGroups(TournamentFormat? format) =>
      format == TournamentFormat.groupsThenKnockout ||
      format == TournamentFormat.swissThenKnockout;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WizardState>();
    final format = state.selectedType == null ? null : Tournament.formatFor(state.selectedType!);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _RulesLevelBanner(level: state.rulesLevel),
        const SizedBox(height: 16),

        const _SectionHeader('نظام النقاط'),
        _PointsRow(
          label: 'الفوز',
          value: state.rules.pointsForWin,
          onChanged: (v) => state.updateRules(state.rules.copyWith(pointsForWin: v)),
        ),
        _PointsRow(
          label: 'التعادل',
          value: state.rules.pointsForDraw,
          onChanged: (v) => state.updateRules(state.rules.copyWith(pointsForDraw: v)),
        ),
        _PointsRow(
          label: 'الخسارة',
          value: state.rules.pointsForLoss,
          onChanged: (v) => state.updateRules(state.rules.copyWith(pointsForLoss: v)),
        ),

        const SizedBox(height: 20),
        const _SectionHeader('ترتيب كسر التعادل (اسحب لإعادة الترتيب)'),
        _TiebreakReorderList(state: state),

        const SizedBox(height: 20),
        SwitchListTile(
          title: const Text('ذهاب وإياب'),
          subtitle: const Text('إنشاء مباراة ثانية لكل مواجهة'),
          value: state.rules.homeAndAway,
          onChanged: (v) => state.updateRules(state.rules.copyWith(homeAndAway: v)),
        ),

        if (_hasGroups(format)) ...[
          const SizedBox(height: 12),
          const _SectionHeader('عدد المتأهلين من كل مجموعة'),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: state.rules.qualifiersPerGroup > 1
                    ? () => state.updateRules(
                        state.rules.copyWith(qualifiersPerGroup: state.rules.qualifiersPerGroup - 1))
                    : null,
              ),
              Text('${state.rules.qualifiersPerGroup}', style: const TextStyle(fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => state.updateRules(
                    state.rules.copyWith(qualifiersPerGroup: state.rules.qualifiersPerGroup + 1)),
              ),
            ],
          ),
        ],

        if (_hasKnockoutStage(format)) ...[
          const SizedBox(height: 12),
          const _SectionHeader('نظام خروج المغلوب عند التعادل'),
          ...KnockoutTiebreakRule.values.map((rule) => RadioListTile<KnockoutTiebreakRule>(
                value: rule,
                groupValue: state.rules.knockoutTiebreak,
                title: Text(_knockoutRuleLabel(rule)),
                onChanged: (v) {
                  if (v != null) state.updateRules(state.rules.copyWith(knockoutTiebreak: v));
                },
              )),
        ],

        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: const Icon(Icons.save_outlined),
          label: const Text('💾 حفظ كقالب'),
          onPressed: () => _saveAsTemplate(context, state),
        ),
      ],
    );
  }

  Future<void> _saveAsTemplate(BuildContext context, WizardState state) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حفظ القوانين كقالب'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'مثلاً: بطولة المقهى'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await RuleTemplateRepository().save(name, state.rules);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ القالب "$name"')));
      }
    }
  }
}

class _RulesLevelBanner extends StatelessWidget {
  final RulesLevel level;
  const _RulesLevelBanner({required this.level});

  @override
  Widget build(BuildContext context) {
    late String emoji;
    late String label;
    late Color color;
    switch (level) {
      case RulesLevel.official:
        emoji = '🟢';
        label = 'رسمي 100%';
        color = Colors.green;
        break;
      case RulesLevel.modified:
        emoji = '🟡';
        label = 'معدل';
        color = Colors.orange;
        break;
      case RulesLevel.fullyCustom:
        emoji = '🔴';
        label = 'مخصص بالكامل';
        color = Colors.red;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text('مستوى القوانين: $label', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }
}

class _PointsRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _PointsRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(width: 24, child: Text('$value', textAlign: TextAlign.center)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _TiebreakReorderList extends StatelessWidget {
  final WizardState state;
  const _TiebreakReorderList({required this.state});

  @override
  Widget build(BuildContext context) {
    final order = state.rules.tiebreakOrder;
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: order.length,
      onReorder: (oldIndex, newIndex) {
        final newOrder = List<TiebreakCriteria>.from(order);
        if (newIndex > oldIndex) newIndex -= 1;
        final item = newOrder.removeAt(oldIndex);
        newOrder.insert(newIndex, item);
        state.updateRules(state.rules.copyWith(tiebreakOrder: newOrder));
      },
      itemBuilder: (context, index) {
        final criteria = order[index];
        return ListTile(
          key: ValueKey(criteria),
          leading: CircleAvatar(radius: 12, child: Text('${index + 1}', style: const TextStyle(fontSize: 12))),
          title: Text(_tiebreakLabel(criteria)),
          trailing: const Icon(Icons.drag_handle),
        );
      },
    );
  }
}
