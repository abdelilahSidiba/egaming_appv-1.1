/// نموذج الفريق — فريق مرتبط ببطولة واحدة ولاعب واحد (الفصل 5.5 / 5.6)
/// ملاحظة مهمة (الفصل 2.7 / 8.20): الاسم والشعار هنا "مجمّدان" وقت إنشاء البطولة
/// ولا يتأثران بأي تعديل لاحق على بيانات اللاعب العامة، حفاظًا على تاريخ البطولة.
class Team {
  final String id;
  final String tournamentId;
  String name; // اسم الفريق (مثلاً: برشلونة)
  String? logoAssetPath; // شعار الفريق كما كان وقت إنشاء البطولة
  final String playerId; // اللاعب المتحكم في الفريق
  String? playerNameSnapshot; // لقطة من اسم اللاعب وقت إنشاء البطولة
  String? colorHex;
  String? groupName; // اسم المجموعة إن وجدت (A, B, C ...)
  int seed; // ترتيب التصنيف (يُستخدم في القرعة والبطولات الإقصائية)

  Team({
    required this.id,
    required this.tournamentId,
    required this.name,
    this.logoAssetPath,
    required this.playerId,
    this.playerNameSnapshot,
    this.colorHex,
    this.groupName,
    this.seed = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'tournamentId': tournamentId,
        'name': name,
        'logoAssetPath': logoAssetPath,
        'playerId': playerId,
        'playerNameSnapshot': playerNameSnapshot,
        'colorHex': colorHex,
        'groupName': groupName,
        'seed': seed,
      };

  factory Team.fromMap(Map<String, dynamic> map) => Team(
        id: map['id'] as String,
        tournamentId: map['tournamentId'] as String,
        name: map['name'] as String,
        logoAssetPath: map['logoAssetPath'] as String?,
        playerId: map['playerId'] as String,
        playerNameSnapshot: map['playerNameSnapshot'] as String?,
        colorHex: map['colorHex'] as String?,
        groupName: map['groupName'] as String?,
        seed: map['seed'] as int? ?? 0,
      );
}

/// فريق "وهمي" يُستخدم فقط داخليًا للجدولة (Bye) عندما يكون عدد الفرق فرديًا
/// أو غير مناسب لشجرة الكأس (الفصل 5.9)
const String byeTeamId = '__BYE__';
