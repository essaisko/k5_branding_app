# 📱 ChukShin App - 아키텍처 가이드

## 🏗️ 프로젝트 구조

### 전체 디렉토리 구조
```
lib/
├── core/                    # 핵심 공통 코드
│   ├── constants/           # 상수 및 설정
│   │   ├── app_constants.dart
│   │   └── asset_paths.dart
│   ├── exceptions/          # 예외 처리
│   │   └── app_exceptions.dart
│   ├── services/           # 비즈니스 서비스
│   │   └── storage_service.dart
│   ├── theme/              # 테마 및 스타일
│   │   ├── app_colors.dart
│   │   ├── app_theme.dart
│   │   └── app_typography.dart
│   └── utils/              # 유틸리티
│       └── color_utils.dart
├── data/                   # 데이터 계층
│   └── repositories/       # Repository 구현체
│       ├── match_repository_impl.dart
│       └── team_repository_impl.dart
├── domain/                 # 도메인 계층
│   ├── entities/           # 엔티티 클래스
│   │   ├── match.dart
│   │   └── team.dart
│   ├── repositories/       # Repository 인터페이스
│   │   ├── match_repository.dart
│   │   └── team_repository.dart
│   └── usecases/          # 비즈니스 로직
│       ├── get_match_details.dart
│       └── update_match.dart
├── features/              # 기능별 모듈
│   ├── authentication/    # 인증 기능
│   │   ├── domain/
│   │   │   └── entities/
│   │   └── presentation/
│   │       ├── pages/
│   │       └── providers/
│   ├── common/           # 공통 위젯
│   │   └── widgets/
│   ├── match_editor/     # 매치 에디터
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   └── widgets/
│   │   └── providers/
│   └── team/            # 팀 관리
│       └── providers/
├── infrastructure/       # 인프라 계층
│   └── database/
├── presentation/        # 공통 프레젠테이션
│   ├── navigation/      # 라우팅
│   └── pages/          # 메인 페이지들
├── firebase_options.dart
└── main.dart
```

## 🧱 아키텍처 원칙

### 1. Clean Architecture
- **도메인 계층**: 비즈니스 로직의 핵심
- **데이터 계층**: 외부 데이터 소스와의 연동
- **프레젠테이션 계층**: UI 및 사용자 상호작용

### 2. Feature-First 구조
```
features/
├── authentication/     # 로그인, 회원가입, 프로필 관리
├── team/              # 팀 관리, 팀 커뮤니티
├── match_editor/      # 경기 결과 편집
└── common/           # 공통 위젯들
```

### 3. 의존성 분리
- **Core 계층**: 앱의 핵심 기능들
- **Services**: 외부 API 및 Firebase 연동
- **Exceptions**: 중앙화된 에러 처리

## 🔧 주요 컴포넌트

### 1. Core Services

#### StorageService
```dart
class StorageService {
  static Future<String> uploadProfileImage(File imageFile, String userId)
  static Future<String> uploadTeamHeaderImage(File imageFile, String teamId)
  static Future<void> deleteImage(String imageUrl)
}
```

#### AppConstants
```dart
class AppConstants {
  static const String profileImagesPath = 'profile_images';
  static const String teamImagesPath = 'team_images';
  static const List<String> positions = [...];
}
```

### 2. Exception Handling
```dart
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
}

// 특화된 예외들
- AuthException
- StorageException  
- NetworkException
- DatabaseException
- ValidationException
- PermissionException
```

### 3. State Management (Riverpod)
```dart
// 인증 상태 관리
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>

// 팀 상태 관리  
final teamProvider = StateNotifierProvider<TeamNotifier, TeamState>

// 템플릿 상태 관리
final templateProvider = StateProvider<TemplateType>
```

## 📱 주요 기능 모듈

### 1. Authentication (인증)
- **로그인**: Google, 카카오, 전화번호 인증
- **프로필 관리**: 이미지 업로드, 정보 수정
- **권한 관리**: 사용자 권한 확인

### 2. Team Management (팀 관리)
- **팀 커뮤니티**: 갤러리, 커뮤니티, 일정, 멤버
- **헤더 이미지**: 관리자 권한으로 팀 대문 사진 편집
- **팀 컬러**: 팀별 고유 색상 테마

### 3. Match Editor (매치 에디터)
- **템플릿 시스템**: 다양한 경기 결과 템플릿
- **이미지 생성**: 경기 결과 카드 생성
- **실시간 편집**: 라이브 프리뷰

## 🔐 보안 및 권한

### Firebase Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 프로필 이미지: 본인만 읽기/쓰기
    match /profile_images/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 팀 이미지: 인증된 사용자 읽기, 관리자 쓰기
    match /team_images/{teamId}/{imageId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null; // TODO: 팀 관리자 권한 확인
    }
  }
}
```

## 🎨 UI/UX 가이드라인

### 1. 테마 시스템
- **색상**: `AppColors` 클래스로 중앙 관리
- **타이포그래피**: `AppTypography` 클래스
- **일관된 스타일**: `AppTheme` 클래스

### 2. 반응형 디자인
- **패딩**: `AppConstants.defaultPadding` 사용
- **애니메이션**: 일관된 duration 설정
- **접근성**: 충분한 터치 영역 확보

## 🚀 성능 최적화

### 1. 이미지 처리
- **압축**: 자동 이미지 압축 (80% 품질)
- **크기 제한**: 최대 1920x1080 해상도
- **캐싱**: 로컬 이미지 캐시 시스템

### 2. 상태 관리
- **Provider 분리**: 기능별 독립적인 상태 관리
- **불필요한 재빌드 방지**: 적절한 selector 사용

## 📈 확장성 고려사항

### 1. 모듈화
- **기능별 분리**: 독립적인 feature 모듈
- **의존성 주입**: Riverpod Provider 시스템
- **인터페이스 분리**: Repository 패턴

### 2. 테스트 가능성
- **비즈니스 로직 분리**: Service 계층
- **Mock 가능한 구조**: Interface 기반 설계
- **단위 테스트 친화적**: 순수 함수 우선

## 🔄 데이터 플로우

```
UI Layer (Widgets)
    ↓
State Management (Riverpod)
    ↓  
Business Logic (Services/UseCases)
    ↓
Data Layer (Repositories)
    ↓
External APIs (Firebase/REST)
```

## 🛠️ 개발 가이드라인

### 1. 코딩 컨벤션
- **네이밍**: camelCase for variables, PascalCase for classes
- **파일명**: snake_case
- **상수**: UPPER_SNAKE_CASE

### 2. 에러 처리
- **중앙화**: AppException 기반 에러 처리
- **사용자 친화적**: 명확한 에러 메시지
- **로깅**: 개발 시 상세 로그, 프로덕션 시 필수 로그만

### 3. 코드 리뷰 체크리스트
- [ ] 비즈니스 로직이 Service 계층에 있는가?
- [ ] 하드코딩된 값이 Constants에 정의되어 있는가?
- [ ] 적절한 예외 처리가 되어 있는가?
- [ ] UI와 비즈니스 로직이 분리되어 있는가?
- [ ] 불필요한 의존성이 없는가?

---

## 📞 문의사항

프로젝트 구조나 아키텍처에 대한 문의사항이 있으시면 개발팀에 연락해주세요.

**마지막 업데이트**: 2025년 1월 14일 