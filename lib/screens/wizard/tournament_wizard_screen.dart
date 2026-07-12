import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'wizard_state.dart';
import 'steps/step1_type_selection.dart';
import 'steps/step2_info.dart';
import 'steps/step3_players.dart';
import 'steps/step4_team_distribution.dart';
import 'steps/step5_rules.dart';
import 'steps/step6_review.dart';

const List<String> _stepTitles = [
  'اختيار البطولة',
  'المعلومات',
  'اللاعبون',
  'توزيع الفرق',
  'القوانين',
  'المراجعة',
];

/// معالج إنشاء البطولة بخطواته الست (الفصل 3.2)
/// لا ينتقل المستخدم إلى الخطوة التالية إلا بعد إكمال الحالية.
class TournamentWizardScreen extends StatelessWidget {
  const TournamentWizardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WizardState(),
      child: const _WizardBody(),
    );
  }
}

class _WizardBody extends StatefulWidget {
  const _WizardBody();

  @override
  State<_WizardBody> createState() => _WizardBodyState();
}

class _WizardBodyState extends State<_WizardBody> {
  int _currentStep = 0;
  final _pageController = PageController();

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    final state = context.read<WizardState>();
    if (!state.canProceedFromStep(_currentStep)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إكمال هذه الخطوة قبل المتابعة.')),
      );
      return;
    }
    if (_currentStep < _stepTitles.length - 1) _goToStep(_currentStep + 1);
  }

  void _back() {
    if (_currentStep > 0) _goToStep(_currentStep - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('➕ إنشاء بطولة'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          _ProgressHeader(currentStep: _currentStep, onStepTap: _goToStep),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // التنقل عبر الأزرار فقط
              children: const [
                Step1TypeSelection(),
                Step2Info(),
                Step3Players(),
                Step4TeamDistribution(),
                Step5Rules(),
                Step6Review(),
              ],
            ),
          ),
          _NavigationBar(
            currentStep: _currentStep,
            totalSteps: _stepTitles.length,
            onBack: _back,
            onNext: _next,
          ),
        ],
      ),
    );
  }
}

/// شريط تقدم الخطوات في أعلى الشاشة (الفصل 3.2)
class _ProgressHeader extends StatelessWidget {
  final int currentStep;
  final ValueChanged<int> onStepTap;
  const _ProgressHeader({required this.currentStep, required this.onStepTap});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WizardState>();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: List.generate(_stepTitles.length, (index) {
            final isActive = index == currentStep;
            final isCompleted = index < currentStep && state.canProceedFromStep(index);
            return GestureDetector(
              onTap: () {
                // يسمح بالرجوع لخطوة سابقة فقط، وليس القفز للأمام
                if (index <= currentStep) onStepTap(index);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isActive
                          ? Theme.of(context).colorScheme.primary
                          : (isCompleted ? Colors.green : Colors.grey.shade400),
                      child: isCompleted
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : Text('${index + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stepTitles[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavigationBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _NavigationBar({
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == totalSteps - 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: const Text('السابق'),
                ),
              ),
            if (currentStep > 0) const SizedBox(width: 12),
            if (!isLastStep)
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: onNext,
                  child: const Text('التالي'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
