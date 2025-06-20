import 'package:chukshin_app/domain/entities/match_entity.dart';
import 'package:chukshin_app/domain/repositories/match_repository.dart';

/// GetMatchDetails use case following the Clean Architecture pattern
///
/// 구글 수석 개발자 수준의 Use Case 설계:
/// 1. Single Responsibility: 경기 조회만 담당
/// 2. Business Logic Encapsulation: 비즈니스 로직을 캡슐화
/// 3. Repository Abstraction: Repository 인터페이스에만 의존
/// 4. Immutable State: 상태 변경 없음
class GetMatchDetails {
  final MatchRepository repository;

  const GetMatchDetails(this.repository);

  /// 특정 ID로 경기 조회
  Future<MatchEntity?> call(String id) async {
    // 비즈니스 로직: ID 유효성 검사
    if (id.trim().isEmpty) {
      throw ArgumentError('경기 ID는 비어있을 수 없습니다.');
    }

    return repository.getMatch(id);
  }

  /// 현재 편집 중인 경기 조회
  MatchEntity getCurrentEditingMatch() {
    return repository.getCurrentEditingMatch();
  }

  /// 여러 경기 한 번에 조회
  Future<List<MatchEntity>> getMultipleMatches(List<String> ids) async {
    if (ids.isEmpty) return [];

    final results = <MatchEntity>[];
    for (final id in ids) {
      final match = await call(id);
      if (match != null) {
        results.add(match);
      }
    }
    return results;
  }

  /// 팀별 최근 경기 조회
  Future<List<MatchEntity>> getRecentMatchesByTeam(
    String teamName, {
    int limit = 10,
  }) async {
    if (teamName.trim().isEmpty) {
      throw ArgumentError('팀명은 비어있을 수 없습니다.');
    }

    return repository.getRecentMatches(limit: limit, teamName: teamName);
  }
}
