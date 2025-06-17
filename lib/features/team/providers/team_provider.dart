import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chukshin_app/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chukshin_app/core/services/firebase_storage_service.dart';
import 'dart:io';

/// 팀 정보 클래스
class Team {
  final String id;
  final String name;
  final String? headerImagePath;
  final Color color;
  final List<String> members;
  final DateTime createdAt;

  const Team({
    required this.id,
    required this.name,
    this.headerImagePath,
    required this.color,
    required this.members,
    required this.createdAt,
  });

  Team copyWith({
    String? id,
    String? name,
    String? headerImagePath,
    Color? color,
    List<String>? members,
    DateTime? createdAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      headerImagePath: headerImagePath ?? this.headerImagePath,
      color: color ?? this.color,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 팀 상태 클래스
class TeamState {
  final List<Team> teams;
  final Map<String, File> headerImages;
  final bool isLoading;
  final String? error;

  const TeamState({
    required this.teams,
    required this.headerImages,
    required this.isLoading,
    this.error,
  });

  TeamState copyWith({
    List<Team>? teams,
    Map<String, File>? headerImages,
    bool? isLoading,
    String? error,
  }) {
    return TeamState(
      teams: teams ?? this.teams,
      headerImages: headerImages ?? this.headerImages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// 팀 관리 StateNotifier
class TeamNotifier extends StateNotifier<TeamState> {
  TeamNotifier()
      : super(TeamState(
          teams: _getInitialTeams(),
          headerImages: {},
          isLoading: false,
        ));

  /// 초기 팀 데이터
  static List<Team> _getInitialTeams() {
    return [
      Team(
        id: 'team1',
        name: '한마음FC',
        color: const Color(0xFFE74C3C),
        members: ['user1', 'user2', 'user3'],
        createdAt: DateTime.now(),
      ),
      Team(
        id: 'team2',
        name: '수우FC',
        color: const Color(0xFF3498DB),
        members: ['user4', 'user5'],
        createdAt: DateTime.now(),
      ),
      Team(
        id: 'team3',
        name: '한FC',
        color: const Color(0xFF27AE60),
        members: ['user6', 'user7', 'user8'],
        createdAt: DateTime.now(),
      ),
    ];
  }

  /// 팀 헤더 이미지 업데이트
  Future<void> updateTeamHeaderImage(String teamId, File imageFile) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🔥 팀 헤더 이미지 업데이트 시작: $teamId');
      print('🔥 이미지 파일 경로: ${imageFile.path}');
      print('🔥 파일 존재 여부: ${imageFile.existsSync()}');

      // Firebase Storage에 이미지 업로드
      final downloadUrl =
          await StorageService.uploadTeamHeaderImage(imageFile, teamId);
      print('🔥 Firebase Storage 업로드 완료: $downloadUrl');

      // 로컬 상태에도 저장 (캐시용)
      final updatedHeaderImages = Map<String, File>.from(state.headerImages);
      updatedHeaderImages[teamId] = imageFile;

      // 팀 정보 업데이트 (Firebase URL로 저장)
      final updatedTeams = state.teams.map((team) {
        if (team.id == teamId) {
          return team.copyWith(headerImagePath: downloadUrl);
        }
        return team;
      }).toList();

      state = state.copyWith(
        teams: updatedTeams,
        headerImages: updatedHeaderImages,
        isLoading: false,
      );

      print('🔥 팀 헤더 이미지 업데이트 완료');
    } catch (e) {
      print('🔴 팀 헤더 이미지 업데이트 오류: $e');
      state = state.copyWith(
        isLoading: false,
        error: '헤더 이미지 업데이트 실패: $e',
      );
      rethrow;
    }
  }

  /// 팀 헤더 이미지 가져오기
  File? getTeamHeaderImage(String teamId) {
    return state.headerImages[teamId];
  }

  /// 팀 정보 가져오기
  Team? getTeam(String teamId) {
    try {
      return state.teams.firstWhere((team) => team.id == teamId);
    } catch (e) {
      return null;
    }
  }

  /// 팀 이름으로 팀 정보 가져오기
  Team? getTeamByName(String teamName) {
    try {
      return state.teams.firstWhere((team) => team.name == teamName);
    } catch (e) {
      return null;
    }
  }

  /// 사용자가 속한 팀 목록 가져오기
  List<Team> getUserTeams(String userId) {
    return state.teams.where((team) => team.members.contains(userId)).toList();
  }

  /// 에러 상태 클리어
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// 팀 프로바이더
final teamProvider = StateNotifierProvider<TeamNotifier, TeamState>((ref) {
  return TeamNotifier();
});

/// 특정 팀 정보 프로바이더
final teamByNameProvider = Provider.family<Team?, String>((ref, teamName) {
  final teamState = ref.watch(teamProvider);
  return teamState.teams.where((team) => team.name == teamName).firstOrNull;
});

/// 팀 헤더 이미지 프로바이더
final teamHeaderImageProvider = Provider.family<File?, String>((ref, teamId) {
  final teamState = ref.watch(teamProvider);
  return teamState.headerImages[teamId];
});

// 팀 배경 이미지 상태 관리
class TeamBackgroundNotifier extends StateNotifier<Map<String, String?>> {
  TeamBackgroundNotifier() : super({}) {
    _loadBackgroundImages();
  }

  final FirebaseStorageService _storageService = FirebaseStorageService();
  final ImagePicker _imagePicker = ImagePicker();

  // SharedPreferences에서 배경 이미지 URL 로드
  Future<void> _loadBackgroundImages() async {
    final prefs = await SharedPreferences.getInstance();
    final keys =
        prefs.getKeys().where((key) => key.startsWith('team_bg_')).toList();

    final backgroundImages = <String, String?>{};
    for (final key in keys) {
      final teamName = key.replaceFirst('team_bg_', '');
      backgroundImages[teamName] = prefs.getString(key);
    }

    state = backgroundImages;
  }

  // 팀 배경 이미지 설정
  Future<void> setTeamBackgroundImage(String teamName, String? imageUrl) async {
    final prefs = await SharedPreferences.getInstance();

    if (imageUrl != null) {
      await prefs.setString('team_bg_$teamName', imageUrl);
    } else {
      await prefs.remove('team_bg_$teamName');
    }

    state = {
      ...state,
      teamName: imageUrl,
    };
  }

  // 이미지 선택 및 업로드
  Future<String?> pickAndUploadImage(String teamName) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Firebase Storage에 업로드
      final imageUrl = await _storageService.uploadTeamBackground(
        File(image.path),
        teamName,
      );

      // 로컬에 저장
      await setTeamBackgroundImage(teamName, imageUrl);

      return imageUrl;
    } catch (e) {
      print('이미지 업로드 실패: $e');
      return null;
    }
  }

  // 배경 이미지 제거
  Future<void> removeBackgroundImage(String teamName) async {
    await setTeamBackgroundImage(teamName, null);
  }

  // 특정 팀의 배경 이미지 URL 가져오기
  String? getTeamBackgroundImage(String teamName) {
    return state[teamName];
  }
}

// Provider 정의
final teamBackgroundProvider =
    StateNotifierProvider<TeamBackgroundNotifier, Map<String, String?>>((ref) {
  return TeamBackgroundNotifier();
});
