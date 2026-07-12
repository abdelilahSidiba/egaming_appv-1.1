/// صف واحد داخل جدول الترتيب (الفصل 7.3 / 7.4)
/// يُحسب بالكامل من نتائج المباريات ولا يُعدَّل يدويًا أبدًا (الفصل 7.18)
class StandingEntry {
  final String teamId;
  int played = 0;
  int won = 0;
  int drawn = 0;
  int lost = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;
  int points = 0;

  StandingEntry(this.teamId);

  int get goalDifference => goalsFor - goalsAgainst;

  void addMatchResult({
    required int goalsScored,
    required int goalsConceded,
    required int pointsForWin,
    required int pointsForDraw,
    required int pointsForLoss,
  }) {
    played++;
    goalsFor += goalsScored;
    goalsAgainst += goalsConceded;
    if (goalsScored > goalsConceded) {
      won++;
      points += pointsForWin;
    } else if (goalsScored == goalsConceded) {
      drawn++;
      points += pointsForDraw;
    } else {
      lost++;
      points += pointsForLoss;
    }
  }

  Map<String, dynamic> toDisplayMap() => {
        'teamId': teamId,
        'played': played,
        'won': won,
        'drawn': drawn,
        'lost': lost,
        'goalsFor': goalsFor,
        'goalsAgainst': goalsAgainst,
        'goalDifference': goalDifference,
        'points': points,
      };
}
