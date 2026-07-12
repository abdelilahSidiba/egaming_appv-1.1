import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/player.dart';
import 'player_repository.dart';

/// نتيجة محاولة إنشاء لاعب — تميّز بين النجاح، الخطأ، وتحذير الاسم المكرر
/// (الفصل 2.6: "قد يوجد شخصان يحملان نفس الاسم" — القرار يُترك للمستخدم)
class PlayerCreationResult {
  final bool isSuccess;
  final bool isDuplicateWarning;
  final String? errorMessage;

  PlayerCreationResult._(this.isSuccess, this.isDuplicateWarning, this.errorMessage);

  factory PlayerCreationResult.success() =>
      PlayerCreationResult._(true, false, null);
  factory PlayerCreationResult.error(String msg) =>
      PlayerCreationResult._(false, false, msg);
  factory PlayerCreationResult.duplicateNameWarning() =>
      PlayerCreationResult._(false, true, null);
}

/// مزوّد حالة اللاعبين — يربط شاشات اللاعبين بمستودع البيانات ويُخطر
/// الواجهة تلقائيًا عند أي تغيير (إضافة، تعديل، حذف) — الفصل 2 بالكامل.
class PlayerProvider extends ChangeNotifier {
  final PlayerRepository _repository = PlayerRepository();
  static const _uuid = Uuid();

  List<Player> _players = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Player> get players => _players;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  Future<void> loadPlayers() async {
    _isLoading = true;
    notifyListeners();
    _players = await _repository.getAll(searchQuery: _searchQuery);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    await loadPlayers();
  }

  /// [confirmDuplicateName] تكون true فقط بعد موافقة صريحة من المستخدم
  /// على وجود لاعب آخر بنفس الاسم (الفصل 2.6)
  Future<PlayerCreationResult> addPlayer({
    required String name,
    String? photoPath,
    String? logoAssetPath,
    String? colorHex,
    bool confirmDuplicateName = false,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return PlayerCreationResult.error('يجب إدخال اسم اللاعب.');
    }

    if (!confirmDuplicateName && await _repository.existsByName(trimmed)) {
      return PlayerCreationResult.duplicateNameWarning();
    }

    final player = Player(
      id: _uuid.v4(),
      name: trimmed,
      photoPath: photoPath,
      logoAssetPath: logoAssetPath,
      colorHex: colorHex,
    );
    await _repository.insert(player);
    await loadPlayers();
    return PlayerCreationResult.success();
  }

  /// تعديل بيانات اللاعب — لا يؤثر على البطولات الجارية أو المنتهية
  /// (الفصل 2.7: البطولات تحتفظ بلقطة ثابتة من الاسم/الشعار وقت إنشائها)
  Future<void> updatePlayer(Player player) async {
    await _repository.update(player);
    await loadPlayers();
  }

  /// يحاول حذف لاعب، يرجع false إن كان مشاركًا في بطولة جارية حاليًا (الفصل 2.8)
  Future<bool> deletePlayer(String playerId) async {
    final deleted = await _repository.delete(playerId);
    if (deleted) await loadPlayers();
    return deleted;
  }

  Future<bool> isPlayerInActiveTournament(String playerId) {
    return _repository.isInActiveTournament(playerId);
  }
}
