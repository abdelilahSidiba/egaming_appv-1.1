import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// شعار بصري دائري: صورة حقيقية إن توفرت، وإلا دائرة ملوّنة بأول حرفين
/// من الاسم (الفصل 2.4 / 2.5).
///
/// ملاحظة: في هذه المرحلة لا تتوفر ملفات PNG حقيقية للشعارات الرسمية، لذا
/// يُعتمد افتراضيًا على "الشعار المولّد" (بالأحرف الأولى + لون مميز). عند
/// إضافة صور PNG حقيقية لاحقًا إلى assets/logos/... يكفي تمرير assetPath
/// وسيُستخدم تلقائيًا، مع رجوع تلقائي للشعار المولّد عند أي خطأ تحميل.
class TeamBadge extends StatelessWidget {
  final String name;
  final String? colorHex;
  final double size;
  final String? assetPath; // شعار من مكتبة التطبيق (مستقبلًا)
  final String? photoPath; // صورة شخصية اختارها المستخدم من الهاتف

  const TeamBadge({
    super.key,
    required this.name,
    this.colorHex,
    this.size = 48,
    this.assetPath,
    this.photoPath,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts.first;
      return p.length <= 2 ? p : p.substring(0, 2);
    }
    final a = parts[0].isNotEmpty ? parts[0].substring(0, 1) : '';
    final b = parts[1].isNotEmpty ? parts[1].substring(0, 1) : '';
    return '$a$b';
  }

  @override
  Widget build(BuildContext context) {
    if (photoPath != null && photoPath!.isNotEmpty) {
      return ClipOval(
        child: Image.file(
          File(photoPath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _generatedBadge(),
        ),
      );
    }
    if (assetPath != null && assetPath!.startsWith('assets/')) {
      return ClipOval(
        child: Image.asset(
          assetPath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _generatedBadge(),
        ),
      );
    }
    return _generatedBadge();
  }

  Widget _generatedBadge() {
    final color = AppTheme.colorFromHex(colorHex);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.35,
        ),
      ),
    );
  }
}
