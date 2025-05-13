/// Asset paths management class following Steve Jobs' simplicity philosophy
/// - All asset paths are centralized in one place
/// - Type safety with strong typing
/// - Easy to maintain and extend

class AssetPaths {
  // Private constructor to prevent instantiation
  AssetPaths._();

  // Image base paths
  static const String _imageBase = 'assets/images';

  // Team logos - 실제 존재하는 파일만 포함
  static const String defaultCrest = '$_imageBase/default_crest.png';

  /// 팀 로고 맵 - 안전하게 실제 존재하는 파일만 포함
  static const Map<String, String> teamLogos = {
    'daegu_fc': '$_imageBase/daegu_fc_crest.png',
    'fc_seoul': '$_imageBase/fc_seoul_crest.png',
    'jeonbuk_hyundai': '$_imageBase/jeonbuk_hyundai_crest.png',
    'yangsan_united': '$_imageBase/yangsan_united_logo.png',
    'pluzz_fc': '$_imageBase/pluzz_fc_logo.png',
    'jinjudaesung': '$_imageBase/jinjudaesung_logo.png',
    'kimhae_jaemics_fc': '$_imageBase/kimhae_jaemics_fc_logo.png',
    'one_touch_fc': '$_imageBase/one_touch_fc_logo.png',
    // 나머지 팀 로고는 파일이 추가된 후에 주석 해제
    /* 
    'gangwon_fc': '$_imageBase/gangwon_fc_crest.png',
    'gimcheon_sangmu': '$_imageBase/gimcheon_sangmu_crest.png',
    'gwangju_fc': '$_imageBase/gwangju_fc_crest.png',
    'incheon_utd': '$_imageBase/incheon_utd_crest.png',
    'jeju_utd': '$_imageBase/jeju_utd_crest.png',
    'pohang_steelers': '$_imageBase/pohang_steelers_crest.png',
    'suwon_fc': '$_imageBase/suwon_fc_crest.png',
    'ulsan_hyundai': '$_imageBase/ulsan_hyundai_crest.png',
    */
  };

  /// 모든 로고 경로 리스트
  static List<String> get allLogoPaths => [defaultCrest, ...teamLogos.values];

  /// 로고 경로에서 팀 이름 추출
  static String getTeamNameFromPath(String path) {
    final fileName = path
        .split('/')
        .last
        .replaceAll('_crest.png', '')
        .replaceAll('_logo.png', '');
    return fileName
        .split('_')
        .map(
          (word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
        )
        .join(' ');
  }

  /// 로고 경로 유효성 확인
  static bool isValidLogoPath(String path) {
    return path == defaultCrest || teamLogos.values.contains(path);
  }

  /// 안전한 로고 경로 반환 (잘못된 경로인 경우 기본값 사용)
  static String getSafeLogoPath(String path) {
    return isValidLogoPath(path) ? path : defaultCrest;
  }
}
