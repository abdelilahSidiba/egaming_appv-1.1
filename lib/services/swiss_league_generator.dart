import 'dart:math';

/// توليد "الدوري الموحد" الخاص بدوري أبطال أوروبا بالنظام الجديد (الفصل 4.10 / 5.11)
///
/// المتطلبات كما وردت في الشرح:
/// ✅ كل فريق يلعب عددًا ثابتًا من المباريات (افتراضيًا 8) ضد خصوم مختلفين.
/// ✅ لا تتكرر أي مواجهة بين نفس الفريقين.
/// ✅ توزيع المباريات عادل قدر الإمكان (كل الفرق تلعب نفس العدد).
///
/// الطريقة: نستخدم "الرسم البياني الدائري" (Circulant Graph) — نرتب الفرق
/// بشكل دائري عشوائي، ثم كل فريق يلعب الفرق التي تبعد عنه بمسافات
/// 1, 2, ..., k/2 في الاتجاهين (يمينًا ويسارًا)، مما يعطي بالضبط k جارًا
/// مختلفًا لكل فريق دون أي تكرار. هذه طريقة رياضية مضمونة وسريعة
/// (بعكس المحاولة العشوائية بالتجربة والخطأ التي قد لا تتقارب).
class SwissLeagueGenerator {
  /// يولّد قائمة المباريات (كأزواج [homeId, awayId]) لدوري موحد بنظام سويسري
  /// [matchesPerTeam] يجب أن يكون عددًا زوجيًا (كل مسافة تعطي مباراتين: ذهاب وإياب اتجاهيًا)
  static List<List<String>> generateFixtures({
    required List<String> teamIds,
    required int matchesPerTeam,
    Random? random,
  }) {
    assert(matchesPerTeam.isEven,
        'عدد المباريات لكل فريق يجب أن يكون زوجيًا لتوزيع متماثل بين الطرفين');
    assert(teamIds.length > matchesPerTeam,
        'عدد الفرق يجب أن يكون أكبر من عدد المباريات المطلوبة لكل فريق');

    final rnd = random ?? Random();
    final circle = List<String>.from(teamIds)..shuffle(rnd);
    final n = circle.length;
    final distances = matchesPerTeam ~/ 2; // عدد المسافات المطلوبة لكل جانب

    final fixtures = <List<String>>[];
    final seenPairs = <String>{};

    for (int d = 1; d <= distances; d++) {
      for (int i = 0; i < n; i++) {
        final teamA = circle[i];
        final teamB = circle[(i + d) % n];
        if (teamA == teamB) continue;

        final pairKey = _pairKey(teamA, teamB);
        if (seenPairs.contains(pairKey)) continue;
        seenPairs.add(pairKey);

        // نتبادل الأرضية بالتناوب حسب فردية/زوجية موقع الفريق لتحقيق توازن
        if (i.isEven) {
          fixtures.add([teamA, teamB]);
        } else {
          fixtures.add([teamB, teamA]);
        }
      }
    }
    return fixtures;
  }

  static String _pairKey(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}__${sorted[1]}';
  }

  /// يجدول المباريات المولّدة على "جولات" بحيث لا يلعب أي فريق مرتين
  /// في نفس الجولة (خوارزمية جشعة/Greedy بسيطة وفعالة عمليًا)
  static List<List<List<String>>> scheduleIntoRounds({
    required List<List<String>> fixtures,
    required List<String> allTeamIds,
  }) {
    final remaining = List<List<String>>.from(fixtures);
    final rounds = <List<List<String>>>[];

    while (remaining.isNotEmpty) {
      final round = <List<String>>[];
      final busyTeams = <String>{};
      final leftover = <List<String>>[];

      for (final fixture in remaining) {
        final home = fixture[0];
        final away = fixture[1];
        if (busyTeams.contains(home) || busyTeams.contains(away)) {
          leftover.add(fixture);
        } else {
          round.add(fixture);
          busyTeams.add(home);
          busyTeams.add(away);
        }
      }

      rounds.add(round);
      remaining
        ..clear()
        ..addAll(leftover);
    }
    return rounds;
  }

  /// يحدد الفرق المتأهلة مباشرة (1-8)، فرق الملحق (9-24)، والمقصاة (25+)
  /// بناءً على الترتيب النهائي للدوري الموحد (الفصل 5.11 / 7.15)
  static Map<String, List<String>> classifyStandings(
      List<String> orderedTeamIdsByRank) {
    return {
      'directQualifiers': orderedTeamIdsByRank.take(8).toList(),
      'playoff': orderedTeamIdsByRank.skip(8).take(16).toList(), // 9-24
      'eliminated': orderedTeamIdsByRank.skip(24).toList(), // 25+
    };
  }
}
