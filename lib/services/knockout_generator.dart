import 'dart:math';
import '../models/enums.dart';
import '../models/team.dart';

/// وصف مباراة إقصائية واحدة قبل حفظها في قاعدة البيانات
class KnockoutFixture {
  final TournamentStage stage;
  final String homeTeamId;
  final String awayTeamId;
  final int matchNumber; // موقع المباراة داخل الدور (لبناء الدور التالي)

  KnockoutFixture({
    required this.stage,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.matchNumber,
  });
}

/// توليد شجرة خروج المغلوب (الفصل 5.9)
/// يدعم أعداد الفرق غير القياسية عبر منح "إعفاءات" (Bye) عشوائية.
class KnockoutGenerator {
  /// يحدد أقرب قوة للعدد 2 أكبر من أو تساوي [n] (16, 32, 8 ...)
  static int _nextPowerOfTwo(int n) {
    int power = 1;
    while (power < n) {
      power *= 2;
    }
    return power;
  }

  static TournamentStage _stageForBracketSize(int teamsInRound) {
    switch (teamsInRound) {
      case 2:
        return TournamentStage.final_;
      case 4:
        return TournamentStage.semiFinal;
      case 8:
        return TournamentStage.quarterFinal;
      case 16:
        return TournamentStage.roundOf16;
      case 32:
        return TournamentStage.roundOf32;
      default:
        return TournamentStage.roundOf32;
    }
  }

  /// يولّد الدور الأول فقط من شجرة الكأس (الأدوار اللاحقة تُبنى تلقائيًا
  /// بعد معرفة الفائزين عبر [buildNextRound])
  static List<KnockoutFixture> generateFirstRound({
    required List<Team> qualifiedTeams,
    Random? random,
  }) {
    final rnd = random ?? Random();
    final shuffled = List<Team>.from(qualifiedTeams)..shuffle(rnd);

    final bracketSize = _nextPowerOfTwo(shuffled.length);
    final byeCount = bracketSize - shuffled.length;

    // نمنح الإعفاءات لأول فرق بعد الخلط (عشوائي بالفعل بسبب الشفل أعلاه)
    final withByes = <String>[
      ...List.generate(byeCount, (_) => byeTeamId),
      ...shuffled.map((t) => t.id),
    ]..shuffle(rnd);

    final stage = _stageForBracketSize(bracketSize);
    final fixtures = <KnockoutFixture>[];
    for (int i = 0; i < withByes.length; i += 2) {
      fixtures.add(KnockoutFixture(
        stage: stage,
        homeTeamId: withByes[i],
        awayTeamId: withByes[i + 1],
        matchNumber: i ~/ 2,
      ));
    }
    return fixtures;
  }

  /// يبني الدور التالي انطلاقًا من قائمة الفائزين بترتيب مباريات الدور السابق
  /// (الفصل 5.15 - اكتشاف نهاية المرحلة والانتقال التلقائي)
  static List<KnockoutFixture> buildNextRound(List<String> winnersInOrder) {
    final stage = _stageForBracketSize(winnersInOrder.length);
    final fixtures = <KnockoutFixture>[];
    for (int i = 0; i < winnersInOrder.length; i += 2) {
      fixtures.add(KnockoutFixture(
        stage: stage,
        homeTeamId: winnersInOrder[i],
        awayTeamId: winnersInOrder[i + 1],
        matchNumber: i ~/ 2,
      ));
    }
    return fixtures;
  }
}
