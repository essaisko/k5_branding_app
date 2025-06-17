import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'firebase_options.dart';
import 'package:chukshin_app/core/theme/app_theme.dart';
import 'package:chukshin_app/data/repositories/match_repository_impl.dart';
import 'package:chukshin_app/data/repositories/team_repository_impl.dart';
import 'package:chukshin_app/presentation/navigation/app_router.dart';
import 'package:chukshin_app/presentation/navigation/routes.dart';
import 'package:chukshin_app/core/constants/asset_paths.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as dev;
import 'package:chukshin_app/infrastructure/database/app_database.dart';

// 이미지 프리로딩을 위한 전역 상태 관리
final imagesPreloadedProvider = StateProvider<bool>((ref) => false);

void main() async {
  // 앱 실행 전 기본 설정
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 카카오 SDK 초기화 (실제 앱 키가 있을 때만 초기화)
  // TODO: 실제 카카오 앱 키로 교체 필요
  // KakaoSdk.init(
  //   nativeAppKey: 'YOUR_KAKAO_NATIVE_APP_KEY',
  //   javaScriptAppKey: 'YOUR_KAKAO_JAVASCRIPT_APP_KEY',
  // );

  // 현재는 임시로 비활성화 (카카오 키 설정 후 활성화)
  try {
    KakaoSdk.init(
      nativeAppKey: 'temp_key', // 임시 키
      javaScriptAppKey: 'temp_key', // 임시 키
    );
  } catch (e) {
    dev.log('카카오 SDK 초기화 실패 (키 설정 필요): $e', name: 'Main');
  }

  // SharedPreferences 초기화
  final prefs = await SharedPreferences.getInstance();

  // AppDatabase 초기화
  final database = await AppDatabase.initialize();

  // 픽셀 오버플로우 방지를 위한 시스템 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // 이미지 캐시 최적화 설정
  PaintingBinding.instance.imageCache.maximumSize = 100; // 캐시 크기 제한
  PaintingBinding.instance.imageCache.clear();

  // 비동기적으로 이미지 프리로드 - context 없이 진행
  _preloadImagesWithoutContext();

  runApp(
    ProviderScope(
      overrides: [
        // Database 프로바이더 등록
        appDatabaseProvider.overrideWithValue(database),
        // Repository 구현체 제공
        matchRepositoryProvider.overrideWithValue(MatchRepositoryImpl(prefs)),
        // 팀 저장소 구현체 제공
        teamRepositoryProvider.overrideWithValue(TeamRepositoryImpl(prefs)),
      ],
      child: const ChukShinApp(),
    ),
  );
}

// context 없이 이미지 로드 (위험한 precacheImage 호출 방지)
Future<void> _preloadImagesWithoutContext() async {
  try {
    final logoPathsToLoad = AssetPaths.allLogoPaths;

    // 각 이미지를 메모리에 로드 (실제 프리캐싱은 앱 실행 후 진행)
    for (final path in logoPathsToLoad) {
      try {
        // 이미지 로드 시도 (실제 캐싱은 아님)
        await rootBundle.load(path);
        dev.log('이미지 로드 확인: $path', name: 'ImagePreload');
      } catch (e) {
        dev.log('이미지 확인 중 오류 ($path): $e', name: 'ImagePreload');
      }
    }
  } catch (e) {
    dev.log('이미지 사전 확인 오류: $e', name: 'ImagePreload');
  }
}

/// 축신 앱의 메인 애플리케이션 위젯
///
/// 스티브 잡스의 디자인 철학을 따른 직관적이고 심미적인 디자인 구조 적용:
/// - 단순함: 복잡한 메뉴 구조 대신 핵심 기능에 직접 접근
/// - 일관성: 동일한 디자인 언어를 전체 앱에 적용
/// - 주의력: 사용자가 현재 수행 중인 작업에 집중할 수 있는 UX
/// - 디테일: 모든 상호작용에서 품질 유지
class ChukShinApp extends StatefulWidget {
  const ChukShinApp({super.key});

  @override
  State<ChukShinApp> createState() => _ChukShinAppState();
}

class _ChukShinAppState extends State<ChukShinApp> {
  bool _imagesLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // didChangeDependencies에서 실제 이미지 프리캐싱 시작
    if (!_imagesLoading) {
      _imagesLoading = true;
      // 지연 실행으로 UI 블로킹 방지
      Future.microtask(() => _safelyPreloadImages());
    }
  }

  // 안전하게 이미지 프리로드 (context 사용 가능 시점)
  Future<void> _safelyPreloadImages() async {
    try {
      final logoPathsToLoad = AssetPaths.allLogoPaths;
      int loaded = 0;

      // 3개씩 묶어서 순차적으로 로드 (메모리 부담 감소)
      for (int i = 0; i < logoPathsToLoad.length; i += 3) {
        final chunk = logoPathsToLoad.skip(i).take(3);
        final futures = <Future>[];

        for (final path in chunk) {
          if (!mounted) return; // 안전 검사

          futures.add(
            precacheImage(AssetImage(path), context).then((_) {
              loaded++;
              dev.log(
                '이미지 캐싱 완료 ($loaded/${logoPathsToLoad.length}): $path',
                name: 'ChukShinApp',
              );
            }).catchError((e) {
              dev.log('이미지 캐싱 실패 ($path): $e', name: 'ChukShinApp');
            }),
          );
        }

        // 청크 단위로 대기 (메모리 압력 분산)
        await Future.wait(futures);

        // 프레임 간 충분한 지연 추가 (UI 블로킹 방지)
        if (mounted) await Future.delayed(const Duration(milliseconds: 100));
      }

      dev.log('모든 이미지 프리로드 완료', name: 'ChukShinApp');
    } catch (e) {
      dev.log('이미지 프리로드 오류: $e', name: 'ChukShinApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '축신 - ChukShin',

      // AppTheme의 lightTheme 적용
      theme: AppTheme.lightTheme,

      // 한국어 로케일 설정
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 커스텀 스크롤 동작 적용
      scrollBehavior: const ScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
        // 모든 플랫폼에서 동일한 스크롤바 스타일
        scrollbars: true,
      ),

      // 디버그 배너 숨기기
      debugShowCheckedModeBanner: false,

      // 라우팅 설정 - 개발 중이므로 디버그 페이지를 첫 화면으로 설정
      initialRoute: AppRoutes.debug,
      routes: AppRouter.routes,
      onGenerateRoute: AppRouter.onGenerateRoute,
      onUnknownRoute: AppRouter.unknownRouteHandler,
    );
  }
}
