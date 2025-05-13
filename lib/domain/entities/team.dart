import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 축구팀 엔티티 클래스
///
/// 팀 정보를 표현하는 도메인 모델
/// - 팀명, 로고, 색상 등의 기본 정보 포함
/// - 나중에 선수 정보 확장 가능한 구조
@immutable
class Team {
  /// 팀 식별자
  final String id;

  /// 팀 이름
  final String name;

  /// 팀 로고 경로
  final String logoPath;

  /// 팀 주요 색상 (브랜드 색상)
  final Color primaryColor;

  /// 팀 보조 색상 (선택 사항)
  final Color? secondaryColor;

  /// 선수 목록 (향후 확장)
  final List<Player> players;

  /// 팀 약칭 또는 별명 (선택 사항)
  final String? shortName;

  /// 창단년도 (선택 사항)
  final int? foundedYear;

  /// 홈구장 (선택 사항)
  final String? homeStadium;

  const Team({
    required this.id,
    required this.name,
    required this.logoPath,
    required this.primaryColor,
    this.secondaryColor,
    this.players = const [],
    this.shortName,
    this.foundedYear,
    this.homeStadium,
  });

  /// 복사본 생성
  Team copyWith({
    String? id,
    String? name,
    String? logoPath,
    Color? primaryColor,
    Color? secondaryColor,
    List<Player>? players,
    String? shortName,
    int? foundedYear,
    String? homeStadium,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      logoPath: logoPath ?? this.logoPath,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      players: players ?? this.players,
      shortName: shortName ?? this.shortName,
      foundedYear: foundedYear ?? this.foundedYear,
      homeStadium: homeStadium ?? this.homeStadium,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Team &&
        other.id == id &&
        other.name == name &&
        other.logoPath == logoPath &&
        other.primaryColor == primaryColor &&
        other.secondaryColor == secondaryColor &&
        listEquals(other.players, players) &&
        other.shortName == shortName &&
        other.foundedYear == foundedYear &&
        other.homeStadium == homeStadium;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        logoPath.hashCode ^
        primaryColor.hashCode ^
        secondaryColor.hashCode ^
        players.hashCode ^
        shortName.hashCode ^
        foundedYear.hashCode ^
        homeStadium.hashCode;
  }
}

/// 축구 선수 엔티티 클래스
///
/// 개별 선수 정보를 표현하는 도메인 모델
/// - 향후 해당 모델을 확장하여 더 많은 선수 관련 정보 추가 가능
@immutable
class Player {
  /// 선수 식별자
  final String id;

  /// 선수 이름
  final String name;

  /// 등번호
  final int? number;

  /// 포지션
  final String? position;

  /// 생년월일
  final DateTime? birthDate;

  /// 키 (cm)
  final int? height;

  /// 국적
  final String? nationality;

  const Player({
    required this.id,
    required this.name,
    this.number,
    this.position,
    this.birthDate,
    this.height,
    this.nationality,
  });

  /// 복사본 생성
  Player copyWith({
    String? id,
    String? name,
    int? number,
    String? position,
    DateTime? birthDate,
    int? height,
    String? nationality,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      position: position ?? this.position,
      birthDate: birthDate ?? this.birthDate,
      height: height ?? this.height,
      nationality: nationality ?? this.nationality,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Player &&
        other.id == id &&
        other.name == name &&
        other.number == number &&
        other.position == position &&
        other.birthDate == birthDate &&
        other.height == height &&
        other.nationality == nationality;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        number.hashCode ^
        position.hashCode ^
        birthDate.hashCode ^
        height.hashCode ^
        nationality.hashCode;
  }
}
