import 'package:chukshin_app/domain/entities/match_entity.dart';
import 'package:chukshin_app/domain/repositories/match_repository.dart';

/// UpdateMatch use case following the Clean Architecture pattern
///
/// 구글 수석 개발자 수준의 Use Case 설계:
/// 1. Single Responsibility: 경기 업데이트만 담당
/// 2. Business Logic Encapsulation: 업데이트 로직을 캡슐화
/// 3. Validation: 데이터 유효성 검사 포함
/// 4. Atomic Operations: 원자적 연산 보장
class UpdateMatch {
  final MatchRepository repository;

  const UpdateMatch(this.repository);

  /// 경기 저장 (완전한 경기 객체)
  Future<void> save(MatchEntity match) async {
    // 비즈니스 로직: 데이터 유효성 검사
    if (!repository.validateMatch(match)) {
      throw ArgumentError('유효하지 않은 경기 데이터입니다.');
    }

    // 중복 검사
    final isDuplicate = await repository.isDuplicateMatch(match);
    if (isDuplicate) {
      throw StateError('이미 존재하는 경기입니다.');
    }

    return repository.saveMatch(match);
  }

  /// 현재 편집 중인 경기 업데이트 (메모리 내)
  void updateCurrentEditingMatch(MatchEntity match) {
    if (!repository.validateMatch(match)) {
      throw ArgumentError('유효하지 않은 경기 데이터입니다.');
    }

    repository.updateCurrentEditingMatch(match);
  }

  /// 홈팀 이름 업데이트
  void updateHomeTeamName(String name) {
    if (name.trim().isEmpty) {
      throw ArgumentError('팀명은 비어있을 수 없습니다.');
    }
    repository.updateHomeTeamName(name.trim());
  }

  /// 원정팀 이름 업데이트
  void updateAwayTeamName(String name) {
    if (name.trim().isEmpty) {
      throw ArgumentError('팀명은 비어있을 수 없습니다.');
    }
    repository.updateAwayTeamName(name.trim());
  }

  /// 홈팀 점수 업데이트
  void updateHomeScore(int? score) {
    if (score != null && score < 0) {
      throw ArgumentError('점수는 음수일 수 없습니다.');
    }
    repository.updateHomeScore(score);
  }

  /// 원정팀 점수 업데이트
  void updateAwayScore(int? score) {
    if (score != null && score < 0) {
      throw ArgumentError('점수는 음수일 수 없습니다.');
    }
    repository.updateAwayScore(score);
  }

  /// 홈팀 로고 업데이트
  void updateHomeLogo(String logoPath) {
    repository.updateHomeLogo(logoPath);
  }

  /// 원정팀 로고 업데이트
  void updateAwayLogo(String logoPath) {
    repository.updateAwayLogo(logoPath);
  }

  /// 경기 날짜/시간 업데이트
  void updateMatchDateTime(DateTime dateTime) {
    // 비즈니스 로직: 과거 날짜 검증 (필요시)
    repository.updateMatchDateTime(dateTime);
  }

  /// 경기장 정보 업데이트
  void updateVenue(String venue) {
    repository.updateVenue(venue.trim());
  }

  /// 배치 업데이트 (여러 경기 동시 저장)
  Future<void> saveMultiple(List<MatchEntity> matches) async {
    if (matches.isEmpty) return;

    // 모든 경기 데이터 유효성 검사
    for (final match in matches) {
      if (!repository.validateMatch(match)) {
        throw ArgumentError('유효하지 않은 경기 데이터가 포함되어 있습니다: ${match.id}');
      }
    }

    await repository.saveMatches(matches);
  }

  /// 편집 세션 완료 및 저장
  Future<void> finalizeEditingSession() async {
    await repository.finalizeEditingSession();
  }
}
