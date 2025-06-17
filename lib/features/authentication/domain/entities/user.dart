import 'package:flutter/foundation.dart';

/// 사용자 엔티티
///
/// 애플리케이션에서 사용되는 사용자 정보를 나타내는 도메인 모델
class User {
  /// 사용자 고유 식별자
  final String id;

  /// 사용자 이름
  final String name;

  /// 휴대전화번호 (새로 추가, 로그인 기본 필드)
  final String phoneNumber;

  /// 사용자 이메일 (선택사항으로 변경)
  final String? email;

  /// 프로필 이미지 URL (선택사항)
  final String? profileImageUrl;

  /// 계정 생성 일시
  final DateTime createdAt;

  /// 마지막 로그인 일시
  final DateTime? lastLoginAt;

  /// 휴대전화번호 인증 여부
  final bool isPhoneVerified;

  /// 계정 활성화 여부
  final bool isActive;

  /// 생년월일 (필수로 변경)
  final DateTime birthDate;

  /// 성별 (선택사항)
  final String? gender;

  /// 관심 팀 (선택사항)
  final String? favoriteTeam;

  /// 포지션 (선택사항)
  final String? position;

  /// 프로필 설정 완료 여부
  final bool isProfileSetupComplete;

  /// 거주 지역
  final String? residenceArea;

  /// 소속 팀 목록 (복수 선택 가능)
  final List<String> affiliatedTeams;

  const User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.profileImageUrl,
    required this.createdAt,
    this.lastLoginAt,
    required this.isPhoneVerified,
    required this.isActive,
    required this.birthDate,
    this.gender,
    this.favoriteTeam,
    this.position,
    this.isProfileSetupComplete = false,
    this.residenceArea,
    this.affiliatedTeams = const [],
  });

  /// User 복사 및 수정
  User copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isPhoneVerified,
    bool? isActive,
    DateTime? birthDate,
    String? gender,
    String? favoriteTeam,
    String? position,
    bool? isProfileSetupComplete,
    String? residenceArea,
    List<String>? affiliatedTeams,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isActive: isActive ?? this.isActive,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      favoriteTeam: favoriteTeam ?? this.favoriteTeam,
      position: position ?? this.position,
      isProfileSetupComplete:
          isProfileSetupComplete ?? this.isProfileSetupComplete,
      residenceArea: residenceArea ?? this.residenceArea,
      affiliatedTeams: affiliatedTeams ?? this.affiliatedTeams,
    );
  }

  /// Map으로 변환 (Firestore 저장용)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt?.millisecondsSinceEpoch,
      'isPhoneVerified': isPhoneVerified,
      'isActive': isActive,
      'birthDate': birthDate.millisecondsSinceEpoch,
      'gender': gender,
      'favoriteTeam': favoriteTeam,
      'position': position,
      'isProfileSetupComplete': isProfileSetupComplete,
      'residenceArea': residenceArea,
      'affiliatedTeams': affiliatedTeams,
    };
  }

  /// Map에서 User 생성 (Firestore 로드용)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLoginAt'])
          : null,
      isPhoneVerified: map['isPhoneVerified'] ?? false,
      isActive: map['isActive'] ?? true,
      birthDate: DateTime.fromMillisecondsSinceEpoch(map['birthDate']),
      gender: map['gender'],
      favoriteTeam: map['favoriteTeam'],
      position: map['position'],
      isProfileSetupComplete: map['isProfileSetupComplete'] ?? false,
      residenceArea: map['residenceArea'],
      affiliatedTeams: List<String>.from(map['affiliatedTeams'] ?? []),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.name == name &&
        other.phoneNumber == phoneNumber &&
        other.email == email &&
        other.profileImageUrl == profileImageUrl &&
        other.createdAt == createdAt &&
        other.lastLoginAt == lastLoginAt &&
        other.isPhoneVerified == isPhoneVerified &&
        other.isActive == isActive &&
        other.birthDate == birthDate &&
        other.gender == gender &&
        other.favoriteTeam == favoriteTeam &&
        other.position == position &&
        other.isProfileSetupComplete == isProfileSetupComplete &&
        other.residenceArea == residenceArea &&
        listEquals(other.affiliatedTeams, affiliatedTeams);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        phoneNumber.hashCode ^
        email.hashCode ^
        profileImageUrl.hashCode ^
        createdAt.hashCode ^
        lastLoginAt.hashCode ^
        isPhoneVerified.hashCode ^
        isActive.hashCode ^
        birthDate.hashCode ^
        gender.hashCode ^
        favoriteTeam.hashCode ^
        position.hashCode ^
        isProfileSetupComplete.hashCode ^
        residenceArea.hashCode ^
        affiliatedTeams.hashCode;
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, phoneNumber: $phoneNumber, email: $email, profileImageUrl: $profileImageUrl, createdAt: $createdAt, lastLoginAt: $lastLoginAt, isPhoneVerified: $isPhoneVerified, isActive: $isActive, birthDate: $birthDate, gender: $gender, favoriteTeam: $favoriteTeam, position: $position, isProfileSetupComplete: $isProfileSetupComplete, residenceArea: $residenceArea, affiliatedTeams: $affiliatedTeams)';
  }

  /// JSON에서 User 객체 생성 (로컬 저장용)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      profileImageUrl: json['profileImageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : null,
      isPhoneVerified: json['isPhoneVerified'],
      isActive: json['isActive'],
      birthDate: DateTime.parse(json['birthDate']),
      gender: json['gender'],
      favoriteTeam: json['favoriteTeam'],
      position: json['position'],
      isProfileSetupComplete: json['isProfileSetupComplete'],
      residenceArea: json['residenceArea'],
      affiliatedTeams: List<String>.from(json['affiliatedTeams'] ?? []),
    );
  }

  /// User 객체를 JSON으로 변환 (로컬 저장용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isPhoneVerified': isPhoneVerified,
      'isActive': isActive,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
      'favoriteTeam': favoriteTeam,
      'position': position,
      'isProfileSetupComplete': isProfileSetupComplete,
      'residenceArea': residenceArea,
      'affiliatedTeams': affiliatedTeams,
    };
  }
}
