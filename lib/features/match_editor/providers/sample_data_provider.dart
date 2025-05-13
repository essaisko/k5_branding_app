import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/core/constants/asset_paths.dart';
import 'package:k5_branding_app/domain/entities/team.dart';

// 샘플 팀 데이터 프로바이더 선언
final sampleTeamsProvider = Provider<List<Team>>((ref) {
  // 샘플 팀 데이터 - 실제 앱에서는 저장소(Repository)에서 로드하게 될 것
  return [
    Team(
      id: '1',
      name: '양산유나이티드',
      logoPath: 'assets/images/yangsan_united_logo.png',
      primaryColor: const Color(0xFF542583),
    ),
    Team(
      id: '2',
      name: '플러즈FC',
      logoPath: 'assets/images/pluzz_fc_logo.png',
      primaryColor: const Color(0xFF004D98),
    ),
    Team(
      id: '3',
      name: '재믹스축구클럽',
      logoPath: 'assets/images/kimhae_jaemics_fc_logo.png',
      primaryColor: const Color(0xFFFFD700),
    ),
    Team(
      id: '4',
      name: '거제FCMOVV',
      logoPath: AssetPaths.defaultCrest, // 일관성을 위해 AssetPaths 사용
      primaryColor: const Color(0xFF007941),
    ),
    Team(
      id: '5',
      name: '원터치FC',
      logoPath: 'assets/images/one_touch_fc_logo.png',
      primaryColor: const Color(0xFF1D1160),
    ),
    Team(
      id: '6',
      name: '진주대성축구클럽',
      logoPath: 'assets/images/jinjudaesung_logo.png',
      primaryColor: const Color(0xFFCE1141),
    ),
  ];
});
