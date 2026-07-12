import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../models/match_model.dart';
import '../../models/team.dart';
import '../../models/tournament_rules.dart';
import '../../widgets/team_badge.dart';

/// نتيجة الحوار: القيم التي أدخلها المستخدم، أو null إذا أُلغي
class MatchResultInput {
  final int homeGoals;
  final int awayGoals;
  final int? homePenalties;
  final int? awayPenalties;
  final bool wentToExtraTime;

  MatchResultInput({
    required this.homeGoals,
    required this.awayGoals,
    this.homePenalties,
    this.awayPenalties,
    this.wentToExtraTime = false,
  });
}

/// نافذة إدخال نتيجة المباراة — منبثقة من الأسفل (Bottom Sheet) بدل شاشة كاملة
/// لأن إدخال النتيجة عملية سريعة (الفصل 6.5 / 6.6)
Future<MatchResultInput?> showMatchResultSheet({
  required BuildContext context,
  required MatchModel match,
  required Team homeTeam,
  required Team awayTeam,
  required bool isKnockoutStage,
  required TournamentRules rules,
}) {
  return showModalBottomSheet<MatchResultInput>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _MatchResultSheet(
      match: match,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      isKnockoutStage: isKnockoutStage,
      rules: rules,
    ),
  );
}

class _MatchResultSheet extends StatefulWidget {
  final MatchModel match;
  final Team homeTeam;
  final Team awayTeam;
  final bool isKnockoutStage;
  final TournamentRules rules;

  const _MatchResultSheet({
    required this.match,
    required this.homeTeam,
    required this.awayTeam,
    required this.isKnockoutStage,
    required this.rules,
  });

  @override
  State<_MatchResultSheet> createState() => _MatchResultSheetState();
}

class _MatchResultSheetState extends State<_MatchResultSheet> {
  late final TextEditingController _homeController;
  late final TextEditingController _awayController;
  late final TextEditingController _homePensController;
  late final TextEditingController _awayPensController;

  bool? _wentToExtraTime; // null = لم يُسأل بعد (فقط عند نظام الأشواط الإضافية)
  bool _showPenalties = false;

  @override
  void initState() {
    super.initState();
    _homeController = TextEditingController(text: widget.match.homeGoals?.toString() ?? '');
    _awayController = TextEditingController(text: widget.match.awayGoals?.toString() ?? '');
    _homePensController = TextEditingController(text: widget.match.homePenalties?.toString() ?? '');
    _awayPensController = TextEditingController(text: widget.match.awayPenalties?.toString() ?? '');
    _showPenalties = widget.match.hasPenalties;
  }

  @override
  void dispose() {
    _homeController.dispose();
    _awayController.dispose();
    _homePensController.dispose();
    _awayPensController.dispose();
    super.dispose();
  }

  bool get _isDraw {
    final h = int.tryParse(_homeController.text);
    final a = int.tryParse(_awayController.text);
    if (h == null || a == null) return false;
    return h == a;
  }

  void _submit() {
    final homeGoals = int.tryParse(_homeController.text);
    final awayGoals = int.tryParse(_awayController.text);

    if (homeGoals == null || awayGoals == null || homeGoals < 0 || awayGoals < 0) {
      _showError('يرجى إدخال نتيجة صحيحة (أرقام موجبة).');
      return;
    }

    int? homePens;
    int? awayPens;

    if (widget.isKnockoutStage &&
        homeGoals == awayGoals &&
        widget.rules.knockoutTiebreak != KnockoutTiebreakRule.replayMatch) {
      // نظام أشواط إضافية: نتأكد أولًا أن المستخدم أجاب عن السؤال
      if (widget.rules.knockoutTiebreak == KnockoutTiebreakRule.extraTimeThenPenalties &&
          _wentToExtraTime != true) {
        _showError('يرجى تحديد ما إذا انتهت المباراة بعد الأشواط الإضافية.');
        return;
      }
      homePens = int.tryParse(_homePensController.text);
      awayPens = int.tryParse(_awayPensController.text);
      if (homePens == null || awayPens == null || homePens == awayPens) {
        _showError('يجب إدخال نتيجة ركلات ترجيح صحيحة وغير متعادلة.');
        return;
      }
    }

    Navigator.of(context).pop(MatchResultInput(
      homeGoals: homeGoals,
      awayGoals: awayGoals,
      homePenalties: homePens,
      awayPenalties: awayPens,
      wentToExtraTime: _wentToExtraTime ?? false,
    ));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final needsPenaltyQuestion = widget.isKnockoutStage &&
        _isDraw &&
        widget.rules.knockoutTiebreak == KnockoutTiebreakRule.extraTimeThenPenalties;
    final needsDirectPenalties = widget.isKnockoutStage &&
        _isDraw &&
        widget.rules.knockoutTiebreak == KnockoutTiebreakRule.directPenalties;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TeamColumn(team: widget.homeTeam),
                Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ScoreField(controller: _homeController, onChanged: () => setState(() {})),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('×', style: TextStyle(fontSize: 20)),
                        ),
                        _ScoreField(controller: _awayController, onChanged: () => setState(() {})),
                      ],
                    ),
                  ],
                ),
                _TeamColumn(team: widget.awayTeam),
              ],
            ),
            if (needsPenaltyQuestion) ...[
              const SizedBox(height: 16),
              const Text('هل انتهت المباراة بعد الأشواط الإضافية؟'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('لا، تحتاج ركلات ترجيح'),
                    selected: _wentToExtraTime == true,
                    onSelected: (_) => setState(() => _wentToExtraTime = true),
                  ),
                ],
              ),
            ],
            if ((needsPenaltyQuestion && _wentToExtraTime == true) || needsDirectPenalties) ...[
              const SizedBox(height: 16),
              const Text('ركلات الترجيح', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ScoreField(controller: _homePensController, onChanged: () => setState(() {})),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('×'),
                  ),
                  _ScoreField(controller: _awayPensController, onChanged: () => setState(() {})),
                ],
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text('✅ حفظ النتيجة'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  final Team team;
  const _TeamColumn({required this.team});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamBadge(name: team.name, colorHex: team.colorHex, size: 48),
        const SizedBox(height: 6),
        SizedBox(
          width: 90,
          child: Text(
            team.playerNameSnapshot ?? '',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          width: 90,
          child: Text(
            team.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

class _ScoreField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  const _ScoreField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(counterText: ''),
        maxLength: 2,
        onChanged: (_) => onChanged(),
      ),
    );
  }
}
