import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/data/repositories/match_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 데이터베이스 클래스
/// 
/// 이 클래스는 다양한 데이터 액세스 객체(DAO)를 관리합니다.
/// 현재는 SharedPreferences를 기반으로 간단한 구현을 제공합니다.
class AppDatabase {
  late final SharedPreferences _prefs;
  late final MatchDao matchDao;

  AppDatabase._({required SharedPreferences prefs}) {
    _prefs = prefs;
    matchDao = MatchDao(prefs);
  }

  static Future<AppDatabase> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    return AppDatabase._(prefs: prefs);
  }
}

/// Match 데이터 액세스 객체
class MatchDao {
  final SharedPreferences _prefs;

  MatchDao(this._prefs);
}

/// 앱 데이터베이스 프로바이더
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('appDatabaseProvider must be initialized with override');
});

/// 실제 구현에서는 main.dart에서 아래와 같이 오버라이드해야 합니다:
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   final database = await AppDatabase.initialize();
///   
///   runApp(
///     ProviderScope(
///       overrides: [
///         appDatabaseProvider.overrideWithValue(database),
///       ],
///       child: const MyApp(),
///     ),
///   );
/// }
/// ```