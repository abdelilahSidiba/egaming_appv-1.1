import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../data/player_provider.dart';
import '../../models/player.dart';
import '../../widgets/team_badge.dart';
import 'logo_picker_screen.dart';

/// شاشة إضافة لاعب جديد، أو تعديل لاعب موجود إن مُرِّر [existingPlayer]
/// (الفصل 2.3 / 2.7)
class AddEditPlayerScreen extends StatefulWidget {
  final Player? existingPlayer;
  const AddEditPlayerScreen({super.key, this.existingPlayer});

  @override
  State<AddEditPlayerScreen> createState() => _AddEditPlayerScreenState();
}

class _AddEditPlayerScreenState extends State<AddEditPlayerScreen> {
  late final TextEditingController _nameController;
  String? _photoPath;
  String? _logoAssetPath;
  String? _colorHex;
  String? _displayLogoName; // اسم الفريق المختار (لعرضه في الشعار المولّد)
  bool _isSaving = false;

  bool get _isEditing => widget.existingPlayer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingPlayer?.name ?? '');
    _photoPath = widget.existingPlayer?.photoPath;
    _logoAssetPath = widget.existingPlayer?.logoAssetPath;
    _colorHex = widget.existingPlayer?.colorHex;
    _displayLogoName = widget.existingPlayer?.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      setState(() {
        _photoPath = image.path;
        _logoAssetPath = null; // الصورة الشخصية تُغني عن شعار المكتبة
      });
    }
  }

  Future<void> _pickLogo() async {
    final result = await Navigator.of(context).push<SelectedLogo>(
      MaterialPageRoute(builder: (_) => const LogoPickerScreen()),
    );
    if (result != null) {
      setState(() {
        _colorHex = result.colorHex;
        _displayLogoName = result.name;
        _photoPath = null; // شعار المكتبة يُغني عن الصورة الشخصية
      });
    }
  }

  Future<void> _save({bool confirmDuplicate = false}) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('يجب إدخال اسم اللاعب.');
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<PlayerProvider>();

    if (_isEditing) {
      final updated = widget.existingPlayer!.copyWith(
        name: name,
        photoPath: _photoPath,
        logoAssetPath: _logoAssetPath,
        colorHex: _colorHex,
      );
      await provider.updatePlayer(updated);
      setState(() => _isSaving = false);
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final result = await provider.addPlayer(
      name: name,
      photoPath: _photoPath,
      logoAssetPath: _logoAssetPath,
      colorHex: _colorHex,
      confirmDuplicateName: confirmDuplicate,
    );

    setState(() => _isSaving = false);

    if (result.isSuccess) {
      if (mounted) Navigator.of(context).pop();
    } else if (result.isDuplicateWarning) {
      _showDuplicateNameDialog(name);
    } else {
      _showSnack(result.errorMessage ?? 'حدث خطأ غير متوقع.');
    }
  }

  void _showDuplicateNameDialog(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('يوجد لاعب بنفس الاسم'),
        content: Text('يوجد لاعب مسجّل مسبقًا باسم "$name".\n'
            'هل تريد إنشاء لاعب آخر بنفس الاسم؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _save(confirmDuplicate: true);
            },
            child: const Text('نعم، أنشئ لاعبًا آخر'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'تعديل اللاعب' : 'إضافة لاعب جديد')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: TeamBadge(
              name: _displayLogoName ?? (_nameController.text.isEmpty ? '?' : _nameController.text),
              colorHex: _colorHex,
              photoPath: _photoPath,
              assetPath: _logoAssetPath,
              size: 96,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'اسم اللاعب *',
              prefixIcon: Icon(Icons.person),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickLogo,
                  icon: const Icon(Icons.shield_outlined),
                  label: const Text('اختيار شعار'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('صورة من الهاتف'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _isSaving ? null : () => _save(),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _isSaving
                ? const SizedBox(
                    width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_isEditing ? 'حفظ التعديلات' : 'إضافة اللاعب'),
          ),
        ],
      ),
    );
  }
}
