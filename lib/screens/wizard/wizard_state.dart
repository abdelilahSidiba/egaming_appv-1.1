import 'package:flutter/foundation.dart';
import '../../models/enums.dart';
import '../../models/player.dart';
import '../../models/tournament.dart';
import '../../models/tournament_rules.dart';

/// فتحة فريق واحدة داخل خطوة توزيع الفرق (الفصل 3.9)
/// قد يمتلك أكثر من فتحة نفس playerId إذا كان يتحكم بأكثر من فريق
class TeamSlot {
  final String playerId;
  final String playerName;
  final String? playerColorHex;
  String teamName;
  String teamColorHex;

  TeamSlot({
    required this.playerId,
    required this.playerName,
    this.playerColorHex,
    required this.teamName,
    required this.teamColorHex,
  });
}

/// حالة معالج إنشاء البطولة (الفصل 3 بالكامل) — تُشارك بين الخطوات الست
/// عبر ChangeNotifierProvider محصور بنطاق شاشة المعالج فقط.
class WizardState extends ChangeNotifier {
  // ------- الخطوة 1: نوع البطولة -------
  TournamentType? selectedType;
  int? customTeamCount; // للبطولات المخصصة فقط

  bool get isCustomType =>
      selectedType == TournamentType.customLeague ||
      selectedType == TournamentType.customCup ||
      selectedType == TournamentType.customGroupsKnockout;

  int? get requiredTeamCount =>
      isCustomType ? customTeamCount : (selectedType == null ? null : Tournament.officialTeamCount(selectedType!));

  void selectType(TournamentType type) {
    selectedType = type;
    name = Tournament.defaultNameFor(type);
    primaryColorHex = Tournament.defaultColorFor(type);
    rules = TournamentRules.officialFor(type);
    if (isCustomType) {
      customTeamCount ??= 4;
    }
    notifyListeners();
  }

  void setCustomTeamCount(int count) {
    customTeamCount = count;
    notifyListeners();
  }

  // ------- الخطوة 2: المعلومات -------
  String name = '';
  String primaryColorHex = '#1565C0';
  DateTime? tournamentDate;
  String? notes;

  void updateInfo({String? name, DateTime? date, String? notes}) {
    if (name != null) this.name = name;
    if (date != null) tournamentDate = date;
    if (notes != null) this.notes = notes;
    notifyListeners();
  }

  // ------- الخطوة 3: اللاعبون -------
  final List<Player> selectedPlayers = [];

  bool isPlayerSelected(Player p) => selectedPlayers.any((sp) => sp.id == p.id);

  void togglePlayer(Player p) {
    if (isPlayerSelected(p)) {
      selectedPlayers.removeWhere((sp) => sp.id == p.id);
    } else {
      selectedPlayers.add(p);
    }
    notifyListeners();
  }

  // ------- الخطوة 4: توزيع الفرق -------
  List<TeamSlot> teamSlots = [];
  bool drawConfirmed = false;

  void setTeamSlots(List<TeamSlot> slots) {
    teamSlots = slots;
    notifyListeners();
  }

  void confirmDraw() {
    drawConfirmed = true;
    notifyListeners();
  }

  // ------- الخطوة 5: القوانين -------
  TournamentRules rules = TournamentRules();

  void updateRules(TournamentRules newRules) {
    rules = newRules;
    notifyListeners();
  }

  RulesLevel get rulesLevel {
    if (selectedType == null) return RulesLevel.official;
    final official = TournamentRules.officialFor(selectedType!);
    return rules.computeLevel(official);
  }

  // ------- التحقق من إمكانية الانتقال بين الخطوات -------
  bool canProceedFromStep(int step) {
    switch (step) {
      case 0:
        return selectedType != null && (!isCustomType || (customTeamCount ?? 0) >= 2);
      case 1:
        return name.trim().isNotEmpty;
      case 2:
        return selectedPlayers.isNotEmpty;
      case 3:
        return drawConfirmed && teamSlots.isNotEmpty;
      case 4:
        return true; // القوانين دائمًا لها قيم افتراضية صالحة
      default:
        return true;
    }
  }

  void reset() {
    selectedType = null;
    customTeamCount = null;
    name = '';
    primaryColorHex = '#1565C0';
    tournamentDate = null;
    notes = null;
    selectedPlayers.clear();
    teamSlots = [];
    drawConfirmed = false;
    rules = TournamentRules();
    notifyListeners();
  }
}
