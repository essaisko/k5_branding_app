# K5 Branding App

K5 리그를 위한 브랜딩 애플리케이션입니다. 축구 매치 편집, 팀 로고 관리, 그리고 브랜딩 콘텐츠 제작을 위한 도구를 제공합니다.

## 🚀 주요 기능

### 인증 시스템
- **오프닝 페이지**: 앱 시작 시 표시되는 브랜딩 페이지
  - K5 리그 로고와 브랜딩 요소
  - 매력적인 애니메이션 효과
  - 로그인/회원가입으로의 진입점
  
- **로그인 페이지**: 사용자 인증을 위한 로그인 화면
  - 이메일/비밀번호 입력
  - 소셜 로그인 옵션 (Google, Apple)
  - 비밀번호 찾기 기능
  - 로그인 유지 옵션
  
- **회원가입 페이지**: 새로운 사용자 계정 생성
  - 사용자 정보 입력 (이름, 이메일, 비밀번호)
  - 비밀번호 확인 및 검증
  - 약관 동의 (이용약관, 개인정보처리방침)
  - 마케팅 수신 동의 (선택사항)

### 매치 편집 시스템
- **실시간 매치 편집**: 축구 경기 정보를 실시간으로 편집
- **팀 로고 관리**: 다양한 팀 로고를 관리하고 매치에 적용
- **브랜딩 템플릿**: K5 리그 브랜딩에 맞는 템플릿 제공

## 🏗️ 아키텍처

프로젝트는 Clean Architecture 패턴을 따라 구성되어 있습니다:

```
lib/
├── core/                    # 핵심 기능 및 공통 코드
│   ├── constants/          # 앱 전체에서 사용되는 상수
│   └── theme/              # 앱 테마 및 스타일링
├── features/               # 기능별 모듈
│   ├── authentication/     # 인증 기능
│   │   ├── domain/        # 비즈니스 로직 및 엔티티
│   │   │   └── entities/  # User 엔티티
│   │   └── presentation/  # UI 레이어
│   │       ├── pages/     # 오프닝, 로그인, 회원가입 페이지
│   │       └── providers/ # 상태 관리 (Riverpod)
│   ├── match_editor/      # 매치 편집 기능
│   └── common/            # 공통 UI 컴포넌트
├── presentation/          # 전역 프레젠테이션 레이어
│   └── navigation/        # 라우팅 설정
├── data/                  # 데이터 레이어
├── domain/               # 도메인 레이어
└── infrastructure/       # 인프라스트럭처 레이어
```

## 📱 화면 흐름

1. **앱 시작** → 오프닝 페이지
2. **오프닝 페이지** → 로그인 또는 회원가입 선택
3. **회원가입** → 계정 생성 후 로그인 페이지로 이동
4. **로그인** → 성공 시 메인 매치 편집 화면으로 이동
5. **둘러보기** → 게스트로 메인 화면 접근

## 🛠️ 기술 스택

- **Flutter**: 크로스 플랫폼 앱 개발
- **Riverpod**: 상태 관리
- **SQLite**: 로컬 데이터베이스
- **SharedPreferences**: 사용자 설정 저장
- **Material Design**: UI 디자인 시스템

## 🎨 디자인 철학

스티브 잡스의 디자인 철학을 따라 구현:
- **단순함**: 복잡한 메뉴 구조 대신 핵심 기능에 직접 접근
- **일관성**: 동일한 디자인 언어를 전체 앱에 적용
- **주의력**: 사용자가 현재 수행 중인 작업에 집중할 수 있는 UX
- **디테일**: 모든 상호작용에서 품질 유지

## 🔥 Firebase 설정

이 앱은 Firebase Authentication과 Firestore를 사용합니다. 다음 단계를 따라 설정해주세요:

### 1. Firebase 프로젝트 생성
1. [Firebase Console](https://console.firebase.google.com/)에 접속
2. 새 프로젝트 생성 또는 기존 프로젝트 선택
3. 프로젝트 설정에서 앱 추가 (Android/iOS/Web)

### 2. Firebase CLI 설치 및 설정
```bash
# Firebase CLI 설치
npm install -g firebase-tools

# Firebase 로그인
firebase login

# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 프로젝트와 연결
flutterfire configure
```

### 3. Firebase 서비스 활성화
Firebase Console에서 다음 서비스들을 활성화해주세요:
- **Authentication**: 이메일/비밀번호 로그인 방식 활성화
- **Firestore Database**: 사용자 데이터 저장을 위한 NoSQL 데이터베이스
- **Storage** (선택사항): 프로필 이미지 업로드용

### 4. Firestore 보안 규칙 설정
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 사용자는 자신의 문서만 읽기/쓰기 가능
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 5. Android 설정 (선택사항)
`android/app/build.gradle`에서 minSdkVersion을 21 이상으로 설정:
```gradle
defaultConfig {
    minSdkVersion 21
    // ...
}
```

## 🔐 소셜 로그인 설정

### Google 로그인 설정
1. **Firebase Console 설정**
   - Firebase Console → Authentication → Sign-in method
   - Google 제공업체 사용 설정 활성화
   - 프로젝트 지원 이메일 설정
   - 저장 후 완료

2. **추가 설정 불필요**
   - Flutter 앱에서는 별도 설정 없이 바로 사용 가능
   - `google_sign_in` 패키지가 자동으로 Firebase와 연동

### 카카오 로그인 설정
1. **카카오 개발자 콘솔 설정**
   - [카카오 개발자 콘솔](https://developers.kakao.com/) 접속
   - 내 애플리케이션 → 앱 생성
   - 플랫폼 설정에서 Android/iOS 추가
   - 카카오 로그인 활성화
   - 동의항목에서 이메일 선택 동의로 설정

2. **앱 키 설정**
   - `lib/main.dart`에서 카카오 네이티브 앱 키 설정:
   ```dart
   KakaoSdk.init(
     nativeAppKey: '카카오_네이티브_앱_키',
   );
   ```

3. **Android 설정**
   - `android/app/src/main/res/values/strings.xml` 추가:
   ```xml
   <resources>
       <string name="kakao_app_key">카카오_네이티브_앱_키</string>
   </resources>
   ```
   - `android/app/src/main/AndroidManifest.xml`에 카카오 로그인 설정 추가

4. **iOS 설정**
   - `ios/Runner/Info.plist`에 카카오 URL 스킴 추가

### 소셜 로그인 테스트
앱에서 Firebase 설정 상태를 확인하려면:
```dart
Navigator.of(context).pushNamed('/firebase-setup');
```

## 🚦 시작하기

### 필요 조건
- Flutter SDK (3.0 이상)
- Dart SDK
- Android Studio 또는 VS Code

### 설치 및 실행
```bash
# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

## 📋 할 일 목록

### 인증 기능
- [ ] 실제 API 연동
- [ ] 소셜 로그인 구현 (Google, Apple)
- [ ] 비밀번호 찾기 기능 구현
- [ ] 이메일 인증 기능
- [ ] 생체 인증 (지문, Face ID)

### 매치 편집 기능
- [x] 기본 매치 편집 인터페이스
- [x] 팀 로고 관리
- [ ] 실시간 스코어 업데이트
- [ ] 경기 통계 관리
- [ ] 브랜딩 템플릿 확장

### 기타 기능
- [ ] 다국어 지원 확장
- [ ] 오프라인 모드
- [ ] 데이터 동기화
- [ ] 푸시 알림

## 🤝 기여하기

프로젝트에 기여하고 싶으시다면:
1. Fork 후 브랜치 생성
2. 변경사항 커밋
3. Pull Request 생성

## 📄 라이선스

이 프로젝트는 [MIT 라이선스](LICENSE) 하에 배포됩니다.

---

© 2024 K5 League. All rights reserved.
