import '../models/player.dart';

/// وصف شارة إنجاز واحدة (الفصل 7 - فكرة "سجل الإنجازات")
class Achievement {
  final String emoji;
  final String label;
  const Achievement(this.emoji, this.label);
}

/// يحسب شارات الإنجازات التي حققها لاعب معيّن، بالاعتماد فقط على إحصائياته
/// التراكمية المحفوظة أصلاً (بدون حاجة لجدول منفصل أو تتبع لحظي معقّد).
class AchievementsService {
  static List<Achievement> computeFor(Player player) {
    final achievements = <Achievement>[];

    if (player.tournamentsPlayed >= 1) {
      achievements.add(const Achievement('🏆', 'أول بطولة'));
    }
    if (player.titlesWon >= 1) {
      achievements.add(const Achievement('🥇', 'أول لقب'));
    }
    if (player.longestWinStreak >= 5) {
      achievements.add(const Achievement('🔥', '5 انتصارات متتالية'));
    }
    if (player.matchesPlayed >= 100) {
      achievements.add(const Achievement('💯', '100 مباراة'));
    }
    if (player.goalsFor >= 100) {
      achievements.add(const Achievement('⚽', '100 هدف مسجل'));
    }
    if (player.titlesWon >= 1 && player.losses == 0 && player.matchesPlayed > 0) {
      achievements.add(const Achievement('🎯', 'بطل دون أي هزيمة'));
    }
    if (player.isLegend) {
      achievements.add(const Achievement('⭐', 'أسطورة eGaming'));
    }

    return achievements;
  }
}
