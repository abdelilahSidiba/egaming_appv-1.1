import '../models/team.dart';

/// نتيجة توليد جدول الدوري: قائمة جولات، كل جولة قائمة أزواج (فريق1، فريق2)
typedef RoundRobinRound = List<List<String>>; // كل عنصر: [homeTeamId, awayTeamId]

/// خوارزمية "الدائرة" (Circle Method) الكلاسيكية لتوليد جدول دوري كامل
/// (الفصل 5.7): كل فريق يلعب ضد جميع الفرق مرة واحدة، دون تكرار أي مباراة
/// ودون أن يلعب أي فريق مباراتين في نفس الجولة.
class RoundRobinGenerator {
  /// يولّد جولات الذهاب فقط. إن أردت ذهاب وإياب استخدم [generateHomeAndAway].
  static List<RoundRobinRound> generateSingleLeg(List<String> teamIds) {
    final teams = List<String>.from(teamIds);
    final hasBye = teams.length.isOdd;
    if (hasBye) teams.add(byeTeamId); // فريق وهمي لضمان عدد زوجي

    final n = teams.length;
    final rounds = <RoundRobinRound>[];

    // نُثبّت الفريق الأول ونُدوّر البقية (خوارزمية الدائرة القياسية)
    final rotating = teams.sublist(1);

    for (int r = 0; r < n - 1; r++) {
      final round = <List<String>>[];
      final roundTeams = [teams[0], ...rotating];

      for (int i = 0; i < n ~/ 2; i++) {
        final home = roundTeams[i];
        final away = roundTeams[n - 1 - i];
        if (home == byeTeamId || away == byeTeamId) continue;

        // نُبدّل الطرف المضيف بالتناوب لتحقيق توازن أكبر في عدد مباريات الأرض
        if (r.isEven) {
          round.add([home, away]);
        } else {
          round.add([away, home]);
        }
      }
      rounds.add(round);

      // تدوير القائمة: آخر عنصر ينتقل إلى بداية الجزء المتحرك
      rotating.insert(0, rotating.removeLast());
    }
    return rounds;
  }

  /// جولات الذهاب والإياب: نكرر جولات الذهاب مع عكس الطرفين
  /// (الفصل 4.5: "يقوم التطبيق تلقائيًا بإنشاء مباراة ثانية لكل مواجهة")
  static List<RoundRobinRound> generateHomeAndAway(List<String> teamIds) {
    final firstLeg = generateSingleLeg(teamIds);
    final secondLeg = firstLeg
        .map((round) => round.map((pair) => [pair[1], pair[0]]).toList())
        .toList();
    return [...firstLeg, ...secondLeg];
  }

  /// عدد الجولات المتوقع لدوري كامل بعدد فرق معيّن
  static int expectedRounds(int teamCount, {required bool homeAndAway}) {
    final singleLegRounds =
        teamCount.isOdd ? teamCount : teamCount - 1;
    return homeAndAway ? singleLegRounds * 2 : singleLegRounds;
  }
}
