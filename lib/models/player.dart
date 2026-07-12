/// نموذج اللاعب — يُضاف مرة واحدة فقط ويُستخدم في عدد غير محدود من البطولات
/// (الفصل 2 بالكامل)
class Player {
  final String id;
  String name;
  String? photoPath; // صورة شخصية من الهاتف
  String? logoAssetPath; // شعار من مكتبة التطبيق (الافتراضي)
  String? colorHex; // لون اللاعب المميز (الفصل 2.12)
  final DateTime createdAt;

  // إحصائيات تراكمية (الفصل 2.13 / 2.9) — تُحدَّث تلقائيًا بعد كل مباراة
  int tournamentsPlayed;
  int titlesWon;
  int runnerUpCount;
  int thirdPlaceCount;
  int matchesPlayed;
  int wins;
  int draws;
  int losses;
  int goalsFor;
  int goalsAgainst;
  int longestWinStreak;
  int currentWinStreak;

  Player({
    required this.id,
    required this.name,
    this.photoPath,
    this.logoAssetPath,
    this.colorHex,
    DateTime? createdAt,
    this.tournamentsPlayed = 0,
    this.titlesWon = 0,
    this.runnerUpCount = 0,
    this.thirdPlaceCount = 0,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.longestWinStreak = 0,
    this.currentWinStreak = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  int get goalDifference => goalsFor - goalsAgainst;

  double get winRate => matchesPlayed == 0 ? 0 : wins / matchesPlayed * 100;

  /// نظام النجوم (فكرة الفصل 8 المقترحة) — تقييم مبسّط من 1 إلى 5
  double get starRating {
    double score = 0;
    score += titlesWon * 1.0;
    score += (winRate / 100) * 2.0;
    score += (matchesPlayed / 50).clamp(0, 1.0);
    final rating = 1 + (score.clamp(0, 4));
    return double.parse(rating.toStringAsFixed(1));
  }

  /// هل يستحق بطاقة "أسطورة eGaming"؟ (الفصل 8.17)
  bool get isLegend => titlesWon >= 10;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'photoPath': photoPath,
        'logoAssetPath': logoAssetPath,
        'colorHex': colorHex,
        'createdAt': createdAt.toIso8601String(),
        'tournamentsPlayed': tournamentsPlayed,
        'titlesWon': titlesWon,
        'runnerUpCount': runnerUpCount,
        'thirdPlaceCount': thirdPlaceCount,
        'matchesPlayed': matchesPlayed,
        'wins': wins,
        'draws': draws,
        'losses': losses,
        'goalsFor': goalsFor,
        'goalsAgainst': goalsAgainst,
        'longestWinStreak': longestWinStreak,
        'currentWinStreak': currentWinStreak,
      };

  factory Player.fromMap(Map<String, dynamic> map) => Player(
        id: map['id'] as String,
        name: map['name'] as String,
        photoPath: map['photoPath'] as String?,
        logoAssetPath: map['logoAssetPath'] as String?,
        colorHex: map['colorHex'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
        tournamentsPlayed: map['tournamentsPlayed'] as int? ?? 0,
        titlesWon: map['titlesWon'] as int? ?? 0,
        runnerUpCount: map['runnerUpCount'] as int? ?? 0,
        thirdPlaceCount: map['thirdPlaceCount'] as int? ?? 0,
        matchesPlayed: map['matchesPlayed'] as int? ?? 0,
        wins: map['wins'] as int? ?? 0,
        draws: map['draws'] as int? ?? 0,
        losses: map['losses'] as int? ?? 0,
        goalsFor: map['goalsFor'] as int? ?? 0,
        goalsAgainst: map['goalsAgainst'] as int? ?? 0,
        longestWinStreak: map['longestWinStreak'] as int? ?? 0,
        currentWinStreak: map['currentWinStreak'] as int? ?? 0,
      );

  Player copyWith({
    String? name,
    String? photoPath,
    String? logoAssetPath,
    String? colorHex,
  }) {
    return Player(
      id: id,
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      logoAssetPath: logoAssetPath ?? this.logoAssetPath,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt,
      tournamentsPlayed: tournamentsPlayed,
      titlesWon: titlesWon,
      runnerUpCount: runnerUpCount,
      thirdPlaceCount: thirdPlaceCount,
      matchesPlayed: matchesPlayed,
      wins: wins,
      draws: draws,
      losses: losses,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      longestWinStreak: longestWinStreak,
      currentWinStreak: currentWinStreak,
    );
  }
}
