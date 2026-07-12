import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/tournament_detail_provider.dart';
import '../../models/enums.dart';
import '../../models/match_model.dart';
import '../../models/team.dart';
import '../../widgets/team_badge.dart';
import 'match_result_dialog.dart';

/// تبويب المباريات — الأكثر استخدامًا داخل البطولة (الفصل 6 بالكامل)
class MatchesTab extends StatefulWidget {
  const MatchesTab({super.key});

  @override
  State<MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends State<MatchesTab> {
  int? _selectedRound;
  bool _quickEntryMode = false; // ⚡ الإدخال السريع (فكرة الفصل 6)

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentDetailProvider>();
    final rounds = provider.availableRounds;
    if (rounds.isEmpty) {
      return const Center(child: Text('لا توجد مباريات بعد'));
    }

    _selectedRound ??= rounds.first;
    if (!rounds.contains(_selectedRound)) _selectedRound = rounds.first;

    final roundMatches = provider.matchesForRound(_selectedRound!).where((m) => !m.isBye).toList();
    final finished = roundMatches.where((m) => m.status == MatchStatus.played).length;

    return Column(
      children: [
        _RoundSelector(
          currentRound: _selectedRound!,
          allRounds: rounds,
          onChanged: (r) => setState(() => _selectedRound = r),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '✅ $finished مباريات انتهت | ⏳ ${roundMatches.length - finished} متبقية',
                  style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                ),
              ),
              Row(
                children: [
                  const Text('⚡ إدخال سريع', style: TextStyle(fontSize: 12)),
                  Switch(
                    value: _quickEntryMode,
                    onChanged: (v) => setState(() => _quickEntryMode = v),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.restart_alt),
                tooltip: 'إعادة ضبط الجولة',
                onPressed: () => _confirmResetRound(context, provider, _selectedRound!),
              ),
            ],
          ),
        ),
        Expanded(
          child: roundMatches.isEmpty
              ? const Center(child: Text('لا توجد مباريات في هذه الجولة'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: roundMatches.length,
                  itemBuilder: (context, index) {
                    final match = roundMatches[index];
                    final home = provider.teamById(match.homeTeamId);
                    final away = provider.teamById(match.awayTeamId);
                    if (home == null || away == null) return const SizedBox.shrink();

                    return _quickEntryMode
                        ? _QuickEntryMatchCard(match: match, homeTeam: home, awayTeam: away)
                        : _MatchCard(match: match, homeTeam: home, awayTeam: away);
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _confirmResetRound(
      BuildContext context, TournamentDetailProvider provider, int round) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة ضبط الجولة'),
        content: Text('سيتم حذف جميع نتائج الجولة $round فقط. هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
          FilledButton.tonal(onPressed: () => Navigator.of(context).pop(true), child: const Text('تأكيد')),
        ],
      ),
    );
    if (confirmed == true) await provider.resetRound(round);
  }
}

class _RoundSelector extends StatelessWidget {
  final int currentRound;
  final List<int> allRounds;
  final ValueChanged<int> onChanged;
  const _RoundSelector({required this.currentRound, required this.allRounds, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final index = allRounds.indexOf(currentRound);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: index > 0 ? () => onChanged(allRounds[index - 1]) : null,
          ),
          Text('الجولة $currentRound', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: index < allRounds.length - 1 ? () => onChanged(allRounds[index + 1]) : null,
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchModel match;
  final Team homeTeam;
  final Team awayTeam;
  const _MatchCard({required this.match, required this.homeTeam, required this.awayTeam});

  Color? _resultColor(BuildContext context, bool isHomeSide) {
    if (match.status != MatchStatus.played) return null;
    final winner = match.winnerTeamId;
    if (winner == null) return null; // تعادل حقيقي
    final isWinnerSide = isHomeSide ? winner == match.homeTeamId : winner == match.awayTeamId;
    return isWinnerSide ? Colors.green : null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openResultSheet(context),
        onLongPress: () => _showLongPressMenu(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    TeamBadge(name: homeTeam.name, colorHex: homeTeam.colorHex, size: 36),
                    const SizedBox(height: 4),
                    Text(homeTeam.playerNameSnapshot ?? '',
                        style: TextStyle(fontWeight: FontWeight.bold, color: _resultColor(context, true)),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              SizedBox(
                width: 90,
                child: Column(
                  children: [
                    Text(
                      match.status == MatchStatus.played
                          ? '${match.homeGoals} - ${match.awayGoals}'
                          : '—',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (match.hasPenalties)
                      Text('(${match.homePenalties}-${match.awayPenalties} ر.ت)',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    if (match.isPostponed)
                      const Text('📌 مؤجلة', style: TextStyle(fontSize: 11, color: Colors.orange)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    TeamBadge(name: awayTeam.name, colorHex: awayTeam.colorHex, size: 36),
                    const SizedBox(height: 4),
                    Text(awayTeam.playerNameSnapshot ?? '',
                        style: TextStyle(fontWeight: FontWeight.bold, color: _resultColor(context, false)),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _isKnockout => match.stage != TournamentStage.leagueStage && match.stage != TournamentStage.groupStage;

  Future<void> _openResultSheet(BuildContext context) async {
    final provider = context.read<TournamentDetailProvider>();
    final rules = provider.tournament!.rules;
    final result = await showMatchResultSheet(
      context: context,
      match: match,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      isKnockoutStage: _isKnockout,
      rules: rules,
    );
    if (result != null) {
      await provider.saveResult(
        match: match,
        homeGoals: result.homeGoals,
        awayGoals: result.awayGoals,
        homePenalties: result.homePenalties,
        awayPenalties: result.awayPenalties,
        wentToExtraTime: result.wentToExtraTime,
      );
    }
  }

  void _showLongPressMenu(BuildContext context) {
    final provider = context.read<TournamentDetailProvider>();
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('تعديل النتيجة'),
              onTap: () {
                Navigator.of(context).pop();
                _openResultSheet(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.push_pin_outlined),
              title: const Text('📌 تأجيل المباراة'),
              onTap: () async {
                Navigator.of(context).pop();
                await provider.postponeMatch(match);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة الإدخال السريع (⚡ فكرة الفصل 6) — حقلا إدخال مباشرين داخل البطاقة
class _QuickEntryMatchCard extends StatefulWidget {
  final MatchModel match;
  final Team homeTeam;
  final Team awayTeam;
  const _QuickEntryMatchCard({required this.match, required this.homeTeam, required this.awayTeam});

  @override
  State<_QuickEntryMatchCard> createState() => _QuickEntryMatchCardState();
}

class _QuickEntryMatchCardState extends State<_QuickEntryMatchCard> {
  late final TextEditingController _homeController;
  late final TextEditingController _awayController;

  @override
  void initState() {
    super.initState();
    _homeController = TextEditingController(text: widget.match.homeGoals?.toString() ?? '');
    _awayController = TextEditingController(text: widget.match.awayGoals?.toString() ?? '');
  }

  @override
  void dispose() {
    _homeController.dispose();
    _awayController.dispose();
    super.dispose();
  }

  Future<void> _quickSave() async {
    final h = int.tryParse(_homeController.text);
    final a = int.tryParse(_awayController.text);
    if (h == null || a == null || h < 0 || a < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل نتيجة صحيحة')));
      return;
    }
    // ملاحظة: الإدخال السريع لا يدعم ركلات الترجيح — يُستخدم للجولات العادية
    // (الدوري/المجموعات)؛ للمباريات الإقصائية يُفضّل استخدام النافذة الكاملة.
    await context.read<TournamentDetailProvider>().saveResult(
          match: widget.match,
          homeGoals: h,
          awayGoals: a,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(widget.homeTeam.playerNameSnapshot ?? '', overflow: TextOverflow.ellipsis),
            ),
            SizedBox(
              width: 44,
              child: TextField(
                controller: _homeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(isDense: true),
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('-')),
            SizedBox(
              width: 44,
              child: TextField(
                controller: _awayController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(isDense: true),
              ),
            ),
            Expanded(
              child: Text(widget.awayTeam.playerNameSnapshot ?? '',
                  overflow: TextOverflow.ellipsis, textAlign: TextAlign.left),
            ),
            IconButton(icon: const Icon(Icons.check_circle_outline), onPressed: _quickSave),
          ],
        ),
      ),
    );
  }
}
