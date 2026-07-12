import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/team_badge.dart';
import '../wizard_state.dart';

class Step2Info extends StatefulWidget {
  const Step2Info({super.key});

  @override
  State<Step2Info> createState() => _Step2InfoState();
}

class _Step2InfoState extends State<Step2Info> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final state = context.read<WizardState>();
    _nameController = TextEditingController(text: state.name);
    _notesController = TextEditingController(text: state.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final state = context.read<WizardState>();
    final picked = await showDatePicker(
      context: context,
      initialDate: state.tournamentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) state.updateInfo(date: picked);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WizardState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: TeamBadge(
            name: state.name.isEmpty ? '?' : state.name,
            colorHex: state.primaryColorHex,
            size: 90,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'اسم البطولة *', prefixIcon: Icon(Icons.emoji_events_outlined)),
          onChanged: (v) => context.read<WizardState>().updateInfo(name: v),
        ),
        const SizedBox(height: 16),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          leading: const Icon(Icons.calendar_today_outlined),
          title: Text(state.tournamentDate == null
              ? 'تاريخ البطولة (اختياري)'
              : DateFormat('yyyy/MM/dd').format(state.tournamentDate!)),
          trailing: const Icon(Icons.edit_calendar_outlined),
          onTap: _pickDate,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'ملاحظات البطولة (اختياري)',
            hintText: 'مثلاً: نهائي البطولة يوم الجمعة',
            prefixIcon: Icon(Icons.notes_outlined),
          ),
          onChanged: (v) => context.read<WizardState>().updateInfo(notes: v),
        ),
        const SizedBox(height: 16),
        _ColorPicker(state: state),
      ],
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final WizardState state;
  const _ColorPicker({required this.state});

  static const _palette = [
    '#1565C0', '#C8102E', '#0A1F44', '#3D195B',
    '#D4AF37', '#009639', '#8B0000', '#1E90FF',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('لون البطولة', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: _palette.map((hex) {
            final color = AppTheme.colorFromHex(hex);
            final isSelected = state.primaryColorHex == hex;
            return GestureDetector(
              onTap: () {
                state.primaryColorHex = hex;
                state.updateInfo();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(width: 3, color: Colors.black87) : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
