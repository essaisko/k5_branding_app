import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/core/constants/asset_paths.dart';
import 'package:k5_branding_app/core/utils/color_utils.dart';
import 'package:k5_branding_app/domain/entities/team.dart';
import 'package:k5_branding_app/domain/repositories/team_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

/// 팀 정보 저장소 구현체
///
/// K5 리그 팀 정보를 제공하고 관리합니다.
class TeamRepositoryImpl implements TeamRepository {
  final SharedPreferences _prefs;
  static const _teamListKey = 'team_list';
  static const _teamKeyPrefix = 'team_';
  final _uuid = const Uuid();

  // 팀 로고 경로 매핑 (실제 에셋 사용)
  static final Map<String, String> _teamLogoPaths = {
    '양산유나이티드': 'assets/images/yangsan_united_logo.png',
    '플러즈FC': 'assets/images/pluzz_fc_logo.png',
    '재믹스축구클럽': 'assets/images/kimhae_jaemics_fc_logo.png',
    '원터치FC': 'assets/images/one_touch_fc_logo.png',
    '진주대성축구클럽': 'assets/images/jinjudaesung_logo.png',
    '거제FCMOVV': AssetPaths.defaultCrest,
  };

  // 기본 팀 목록
  final List<Team> _defaultTeams = [];

  TeamRepositoryImpl(this._prefs) {
    // 기본 팀 데이터 초기화
    _initializeDefaultTeams();
  }

  // 기본 팀 데이터 초기화
  void _initializeDefaultTeams() {
    // 사용자 요청 샘플 팀 추가
    _defaultTeams.addAll([
      Team(
        id: _uuid.v4(),
        name: '양산유나이티드',
        logoPath: _teamLogoPaths['양산유나이티드'] ?? AssetPaths.defaultCrest,
        primaryColor:
            ColorUtils.getColorFromTeamLogo(_teamLogoPaths['양산유나이티드'] ?? ''),
        homeStadium: '양산종합운동장',
      ),
      Team(
        id: _uuid.v4(),
        name: '플러즈FC',
        logoPath: _teamLogoPaths['플러즈FC'] ?? AssetPaths.defaultCrest,
        primaryColor:
            ColorUtils.getColorFromTeamLogo(_teamLogoPaths['플러즈FC'] ?? ''),
        homeStadium: '플러즈FC 홈구장',
      ),
      Team(
        id: _uuid.v4(),
        name: '재믹스축구클럽',
        logoPath: _teamLogoPaths['재믹스축구클럽'] ?? AssetPaths.defaultCrest,
        primaryColor:
            ColorUtils.getColorFromTeamLogo(_teamLogoPaths['재믹스축구클럽'] ?? ''),
        homeStadium: '재믹스 홈구장',
      ),
      Team(
        id: _uuid.v4(),
        name: '거제FCMOVV',
        logoPath: _teamLogoPaths['거제FCMOVV'] ?? AssetPaths.defaultCrest,
        primaryColor: Colors.blue.shade800,
        homeStadium: '거제종합운동장',
      ),
      Team(
        id: _uuid.v4(),
        name: '원터치FC',
        logoPath: _teamLogoPaths['원터치FC'] ?? AssetPaths.defaultCrest,
        primaryColor:
            ColorUtils.getColorFromTeamLogo(_teamLogoPaths['원터치FC'] ?? ''),
        homeStadium: '원터치FC 홈구장',
      ),
      Team(
        id: _uuid.v4(),
        name: '진주대성축구클럽',
        logoPath: _teamLogoPaths['진주대성축구클럽'] ?? AssetPaths.defaultCrest,
        primaryColor:
            ColorUtils.getColorFromTeamLogo(_teamLogoPaths['진주대성축구클럽'] ?? ''),
        homeStadium: '진주축구장',
      ),
    ]);
  }

  // 앱 최초 실행 시 기본 팀 데이터 저장
  Future<void> _saveDefaultTeamsIfNeeded() async {
    final teamIds = _prefs.getStringList(_teamListKey);
    if (teamIds == null || teamIds.isEmpty) {
      // 기본 팀 데이터 저장
      List<String> newTeamIds = [];

      for (final team in _defaultTeams) {
        final teamJson = _teamToJson(team);
        await _prefs.setString(
          '$_teamKeyPrefix${team.id}',
          jsonEncode(teamJson),
        );
        newTeamIds.add(team.id);
      }

      await _prefs.setStringList(_teamListKey, newTeamIds);
    }
  }

  @override
  Future<List<Team>> getAllTeams() async {
    // 기본 팀 데이터 저장 (최초 실행 시에만)
    await _saveDefaultTeamsIfNeeded();

    final teamIds = _prefs.getStringList(_teamListKey) ?? [];
    List<Team> teams = [];

    for (final id in teamIds) {
      final teamJson = _prefs.getString('$_teamKeyPrefix$id');
      if (teamJson != null) {
        try {
          final teamMap = jsonDecode(teamJson) as Map<String, dynamic>;
          teams.add(_teamFromJson(teamMap));
        } catch (e) {
          print('팀 데이터 로딩 오류 ($id): $e');
        }
      }
    }

    // 이름순 정렬
    teams.sort((a, b) => a.name.compareTo(b.name));
    return teams;
  }

  @override
  Future<Team?> getTeamById(String id) async {
    final teamJson = _prefs.getString('$_teamKeyPrefix$id');
    if (teamJson == null) return null;

    try {
      final teamMap = jsonDecode(teamJson) as Map<String, dynamic>;
      return _teamFromJson(teamMap);
    } catch (e) {
      print('팀 데이터 로딩 오류 ($id): $e');
      return null;
    }
  }

  @override
  Future<Team?> getTeamByName(String name) async {
    final teams = await getAllTeams();
    return teams.firstWhere(
      (team) => team.name.toLowerCase() == name.toLowerCase(),
      orElse: () => throw Exception('팀 정보를 찾을 수 없습니다: $name'),
    );
  }

  @override
  Future<void> saveTeam(Team team) async {
    // 팀 ID 목록 업데이트
    final teamIds = _prefs.getStringList(_teamListKey) ?? [];
    if (!teamIds.contains(team.id)) {
      teamIds.add(team.id);
      await _prefs.setStringList(_teamListKey, teamIds);
    }

    // 팀 데이터 저장
    final teamJson = _teamToJson(team);
    await _prefs.setString('$_teamKeyPrefix${team.id}', jsonEncode(teamJson));
  }

  @override
  Future<void> deleteTeam(String id) async {
    // 팀 데이터 삭제
    await _prefs.remove('$_teamKeyPrefix$id');

    // 팀 ID 목록 업데이트
    final teamIds = _prefs.getStringList(_teamListKey) ?? [];
    teamIds.remove(id);
    await _prefs.setStringList(_teamListKey, teamIds);
  }

  @override
  Future<List<String>> getAllTeamNames() async {
    final teams = await getAllTeams();
    return teams.map((team) => team.name).toList();
  }

  @override
  Color getTeamColor(String teamName) {
    return ColorUtils.getColorFromTeamLogo(_teamLogoPaths[teamName] ?? '');
  }

  // JSON 변환 유틸리티 메서드

  Team _teamFromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      logoPath: json['logoPath'] as String,
      primaryColor: Color(json['primaryColor'] as int),
      secondaryColor: json['secondaryColor'] != null
          ? Color(json['secondaryColor'] as int)
          : null,
      players: (json['players'] as List?)
              ?.map((e) => _playerFromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      shortName: json['shortName'] as String?,
      foundedYear: json['foundedYear'] as int?,
      homeStadium: json['homeStadium'] as String?,
    );
  }

  Map<String, dynamic> _teamToJson(Team team) {
    return {
      'id': team.id,
      'name': team.name,
      'logoPath': team.logoPath,
      'primaryColor': team.primaryColor.value,
      'secondaryColor': team.secondaryColor?.value,
      'players': team.players.map(_playerToJson).toList(),
      'shortName': team.shortName,
      'foundedYear': team.foundedYear,
      'homeStadium': team.homeStadium,
    };
  }

  Player _playerFromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      number: json['number'] as int?,
      position: json['position'] as String?,
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      height: json['height'] as int?,
      nationality: json['nationality'] as String?,
    );
  }

  Map<String, dynamic> _playerToJson(Player player) {
    return {
      'id': player.id,
      'name': player.name,
      'number': player.number,
      'position': player.position,
      'birthDate': player.birthDate?.toIso8601String(),
      'height': player.height,
      'nationality': player.nationality,
    };
  }
}

/// 팀 저장소 프로바이더
final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  throw UnimplementedError('팀 저장소 프로바이더가 오버라이드되지 않았습니다');
});
