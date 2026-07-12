import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/settings_provider.dart';
import '../../services/backup_service.dart';

/// صفحة "الإعدادات" — إدارة المظهر، الأصوات، النسخ الاحتياطي، وإعادة الضبط
/// (الفصل 10 بالكامل). كل التغييرات تُحفظ مباشرة دون زر "حفظ".
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _backupService = BackupService();
  Map<String, int> _counts = {'players': 0, 'tournaments': 0};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final counts = await _backupService.getAppInfoCounts();
    if (mounted) setState(() => _counts = counts);
  }

  Future<void> _createBackup() async {
    setState(() => _busy = true);
    try {
      final file = await _backupService.createBackup();
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'نسخة احتياطية من eGaming'),
      );
      _showSnack('تم إنشاء النسخة الاحتياطية بنجاح.');
    } catch (e) {
      _showSnack('حدث خطأ أثناء إنشاء النسخة الاحتياطية: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreBackup() async {
    final confirmed = await _confirmDialog(
      title: 'استعادة نسخة احتياطية',
      message: 'سيتم استبدال جميع البيانات الحالية. هل تريد المتابعة؟',
    );
    if (confirmed != true) return;

    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;

    setState(() => _busy = true);
    try {
      await _backupService.restoreBackup(File(result.files.single.path!));
      await _loadCounts();
      _showSnack('تمت استعادة النسخة الاحتياطية بنجاح.');
    } catch (e) {
      _showSnack('تعذّرت استعادة الملف: تأكد أنه نسخة احتياطية صحيحة من eGaming.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetApp() async {
    final confirmed = await _confirmDialog(
      title: '🗑 إعادة ضبط التطبيق',
      message: 'سيتم حذف جميع البطولات واللاعبين والإحصائيات نهائيًا. '
          'لا يمكن التراجع عن هذا الإجراء. هل أنت متأكد؟',
      isDestructive: true,
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    await _backupService.resetApp();
    await _loadCounts();
    if (mounted) setState(() => _busy = false);
    _showSnack('تم إعادة ضبط التطبيق بالكامل.');
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive
                ? FilledButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ الإعدادات')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Opacity(
          opacity: _busy ? 0.5 : 1,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _AppInfoCard(counts: _counts),
              const SizedBox(height: 20),

              const _SectionTitle('المظهر'),
              _buildThemeSelector(settings),

              const SizedBox(height: 20),
              const _SectionTitle('الأصوات والاهتزاز'),
              SwitchListTile(
                title: const Text('🔊 الأصوات'),
                value: settings.soundEnabled,
                onChanged: settings.setSoundEnabled,
              ),
              SwitchListTile(
                title: const Text('📳 الاهتزاز'),
                value: settings.vibrationEnabled,
                onChanged: settings.setVibrationEnabled,
              ),
              SwitchListTile(
                title: const Text('🎬 شاشة تقديم البطولة'),
                subtitle: const Text('شاشة احتفالية قصيرة عند بدء بطولة جديدة'),
                value: settings.introScreenEnabled,
                onChanged: settings.setIntroScreenEnabled,
              ),

              const SizedBox(height: 20),
              const _SectionTitle('النسخ الاحتياطي وإدارة البيانات'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.backup_outlined),
                      title: const Text('💾 إنشاء نسخة احتياطية'),
                      onTap: _createBackup,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restore_outlined),
                      title: const Text('📂 استعادة نسخة احتياطية'),
                      onTap: _restoreBackup,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const _SectionTitle('منطقة الخطر'),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                  title: const Text('🗑 إعادة ضبط التطبيق', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('حذف كل البيانات نهائيًا'),
                  onTap: _resetApp,
                ),
              ),

              const SizedBox(height: 20),
              const _SectionTitle('حول التطبيق'),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('eGaming', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('تطبيق إدارة بطولات eFootball بين الأصدقاء'),
                      SizedBox(height: 4),
                      Text('يعمل بالكامل بدون اتصال بالإنترنت', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(SettingsProvider settings) {
    return Card(
      child: Column(
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('☀️ الوضع الفاتح'),
            value: ThemeMode.light,
            groupValue: settings.themeMode,
            onChanged: (v) => v != null ? settings.setThemeMode(v) : null,
          ),
          RadioListTile<ThemeMode>(
            title: const Text('🌙 الوضع الداكن'),
            value: ThemeMode.dark,
            groupValue: settings.themeMode,
            onChanged: (v) => v != null ? settings.setThemeMode(v) : null,
          ),
          RadioListTile<ThemeMode>(
            title: const Text('⚙️ حسب إعدادات الهاتف'),
            value: ThemeMode.system,
            groupValue: settings.themeMode,
            onChanged: (v) => v != null ? settings.setThemeMode(v) : null,
          ),
        ],
      ),
    );
  }
}

class _AppInfoCard extends StatelessWidget {
  final Map<String, int> counts;
  const _AppInfoCard({required this.counts});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(radius: 26, child: Icon(Icons.sports_soccer)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('eGaming', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Text('الإصدار 1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('👥 ${counts['players']} لاعب  •  🏆 ${counts['tournaments']} بطولة',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }
}
