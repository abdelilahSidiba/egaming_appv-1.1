/// أنواع البطولات الرسمية والمخصصة المتاحة داخل التطبيق
/// (الفصل 3.3 - البطولات الرسمية الموجودة داخل التطبيق)
enum TournamentType {
  // بطولات المنتخبات
  worldCup,
  africaCup,
  europeCup,
  copaAmerica,

  // بطولات الأندية
  uclOldFormat, // دوري أبطال أوروبا - النظام القديم
  uclNewFormat, // دوري أبطال أوروبا - النظام الجديد (سويسري)
  laLiga,
  premierLeague,
  serieA,
  bundesliga,
  ligue1,

  // بطولات مخصصة
  customLeague,
  customCup,
  customGroupsKnockout,
}

/// الصيغة الهيكلية التي يعمل بها محرك التوليد (الفصل 5)
/// هذا هو ما يحدد الخوارزمية المستخدمة فعليًا، بغض النظر عن اسم البطولة
enum TournamentFormat {
  league, // دوري كامل (Round Robin)
  cup, // كأس / خروج مغلوب مباشر
  groupsThenKnockout, // مجموعات ثم خروج مغلوب (كأس العالم، دوري الأبطال القديم)
  swissThenKnockout, // دوري موحد (سويسري) ثم ملحق وخروج مغلوب (دوري الأبطال الجديد)
}

/// حالة البطولة (الفصل 9.8)
enum TournamentStatus {
  notStarted, // 🟡 لم تبدأ
  ongoing, // 🟢 جارية
  finished, // 🔵 انتهت
}

/// مراحل البطولة الداخلية، تُستخدم لتصنيف المباريات
enum TournamentStage {
  groupStage, // دور المجموعات
  leagueStage, // دور الدوري (Round Robin كامل أو دوري سويسري موحد)
  playoff, // الملحق (دوري الأبطال الجديد: فرق 9-24)
  roundOf32,
  roundOf16,
  quarterFinal,
  semiFinal,
  thirdPlace, // مباراة تحديد المركز الثالث
  final_,
}

/// حالة المباراة (الفصل 6.4)
enum MatchStatus {
  notPlayed, // ⚪ لم تلعب بعد
  played, // 🟢 انتهت
  postponed, // 📌 مؤجلة (الفصل 6.14)
}

/// طريقة حسم المباريات الإقصائية المتعادلة (الفصل 4.7)
enum KnockoutTiebreakRule {
  directPenalties, // مباشرة إلى ركلات الترجيح
  extraTimeThenPenalties, // أشواط إضافية ثم ركلات ترجيح
  replayMatch, // إعادة المباراة
}

/// معايير كسر التعادل في جدول الترتيب (الفصل 4.4 / 7.6)
/// الترتيب داخل القائمة يحدد أولوية التطبيق
enum TiebreakCriteria {
  points,
  headToHead, // المواجهات المباشرة
  goalDifference, // فارق الأهداف
  goalsFor, // الأهداف المسجلة
  goalsAgainstFewest, // أقل أهداف مستقبلة
  draw, // القرعة العشوائية كحل أخير
}

/// مستوى القوانين مقارنة بالقوانين الرسمية (الفصل 4 - فكرة "مستوى القوانين")
enum RulesLevel {
  official, // 🟢 رسمي 100%
  modified, // 🟡 معدل
  fullyCustom, // 🔴 مخصص بالكامل
}

/// نتيجة البطولة بالنسبة للاعب (تُستخدم في سجل قاعة الشرف - الفصل 8)
enum TournamentResult {
  champion,
  runnerUp,
  thirdPlace,
  participant,
}
