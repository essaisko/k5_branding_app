import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/data/repositories/match_repository_impl.dart';
import 'package:k5_branding_app/data/repositories/team_repository_impl.dart';
import 'package:k5_branding_app/domain/repositories/match_repository.dart';
import 'package:k5_branding_app/domain/repositories/team_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 초기화 프로바이더
///
/// 앱 실행 시 필요한 리소스를 초기화하는 프로바이더
final appInitializerProvider = FutureProvider<AppInitializer>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final initializer = AppInitializer(prefs);
  await initializer.initialize(ref);
  return initializer;
});

/// 앱 초기화 클래스
///
/// 앱 실행 시 필요한 리소스를 초기화하는 클래스
class AppInitializer {
  final SharedPreferences prefs;

  AppInitializer(this.prefs);

  Future<void> initialize(Ref ref) async {
    // 저장소 초기화
    _initializeRepositories(ref);

    // 나머지 리소스 초기화
  }

  void _initializeRepositories(Ref ref) {
    // 프로바이더 오버라이드 방식은 앱의 main.dart에서 처리
    // 여기서는 필요한 경우 다른 초기화 작업 수행
  }
}
