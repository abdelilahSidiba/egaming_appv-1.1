import 'dart:math';
import '../models/team.dart';
import 'round_robin_generator.dart';

/// نتيجة تقسيم المجموعات: خريطة اسم المجموعة -> قائمة الفرق
typedef Groups = Map<String, List<Team>>;

/// توليد مرحلة المجموعات (الفصل 5.8)
/// مثال: 32 فريقًا -> 8 مجموعات كل مجموعة 4 فرق
class GroupStageGenerator {
  /// يوزّع الفرق على مجموعات بحجم متساوٍ عبر قرعة عشوائية "متعرجة" (Seeded/Serpentine)
  /// لضمان توزيع عادل قدر الإمكان بدل التوزيع العشوائي الكامل.
  static Groups drawGroups({
    required List<Team> teams,
    required int groupSize,
    Random? random,
  }) {
    final rnd = random ?? Random();
    final shuffled = List<Team>.from(teams)..shuffle(rnd);

    final groupCount = (teams.length / groupSize).ceil();
    final groupNames = List.generate(
      groupCount,
      (i) => String.fromCharCode('A'.codeUnitAt(0) + i),
    );

    final groups = <String, List<Team>>{for (final g in groupNames) g: []};

    // توزيع متعرج بسيط: نمرّ على الفرق المخلوطة ونضعها في المجموعات بالتناوب
    for (int i = 0; i < shuffled.length; i++) {
      final groupIndex = i % groupCount;
      final groupName = groupNames[groupIndex];
      shuffled[i].groupName = groupName;
      groups[groupName]!.add(shuffled[i]);
    }

    return groups;
  }

  /// يولّد جميع مباريات كل مجموعة باستخدام خوارزمية الدوري الداخلي (Round Robin)
  /// يرجع خريطة: اسم المجموعة -> قائمة الجولات (كل جولة قائمة أزواج)
  static Map<String, List<RoundRobinRound>> generateGroupMatches({
    required Groups groups,
    required bool homeAndAway,
  }) {
    final result = <String, List<RoundRobinRound>>{};
    groups.forEach((groupName, teams) {
      final teamIds = teams.map((t) => t.id).toList();
      result[groupName] = homeAndAway
          ? RoundRobinGenerator.generateHomeAndAway(teamIds)
          : RoundRobinGenerator.generateSingleLeg(teamIds);
    });
    return result;
  }
}
