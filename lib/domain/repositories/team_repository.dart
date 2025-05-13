import 'package:flutter/material.dart';
import 'package:k5_branding_app/domain/entities/team.dart';

/// 팀 정보 저장소 인터페이스
///
/// 팀 정보 데이터 액세스를 담당하는 저장소의 계약을 정의합니다.
abstract class TeamRepository {
  /// 모든 팀 목록 조회
  Future<List<Team>> getAllTeams();

  /// ID로 팀 정보 조회
  Future<Team?> getTeamById(String id);

  /// 이름으로 팀 정보 조회
  Future<Team?> getTeamByName(String name);

  /// 팀 정보 저장/업데이트
  Future<void> saveTeam(Team team);

  /// 팀 정보 삭제
  Future<void> deleteTeam(String id);

  /// 모든 팀 이름 목록 조회 (자동완성 등에 사용)
  Future<List<String>> getAllTeamNames();

  /// 팀 이름으로 팀 색상 조회
  Color getTeamColor(String teamName);
}
