# K5 브랜딩 앱 (K5 Branding App)

Flutter로 개발된 K리그 5부 축구 브랜딩 및 매치 결과 관리 애플리케이션입니다.

## 주요 기능

### 🏆 매치 에디터
- 실시간 경기 결과 입력 및 편집
- 다양한 디자인 템플릿 제공
- 팀 로고 및 색상 커스터마이징
- 득점자, 카드, 교체 정보 관리

### 📊 기록 관리
- 리그별/디비전별 경기 결과 조회
- 순위표 및 통계 정보
- 경기 일정 및 결과 추적

### 🎨 브랜딩 도구
- 팀 로고 및 색상 관리
- 경기 포스터 자동 생성
- 소셜 미디어 공유 기능

### 👥 커뮤니티
- 팀별 게시판
- 경기 후기 및 분석
- 선수/팬 소통 공간

## 🛠 기술 스택

### Frontend (Flutter)
- **Flutter 3.x**
- **Riverpod** (상태 관리)
- **Go Router** (네비게이션)
- **Firebase** (인증 및 데이터베이스)

### 데이터 소스
- **Firebase Firestore**
- **실시간 경기 결과**
- **팀 정보 및 통계**

## 🚀 설치 및 실행

### Flutter 앱 실행
```bash
# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

## 📁 프로젝트 구조

```
k5_branding_app/
├── lib/
│   ├── core/                    # 핵심 기능
│   │   ├── services/
│   │   │   └── firebase_sync_service.dart
│   │   ├── theme/               # 앱 테마
│   │   └── utils/               # 유틸리티
│   ├── features/                # 주요 기능
│   │   ├── match_editor/        # 매치 에디터
│   │   ├── authentication/      # 인증
│   │   └── common/              # 공통 기능
│   └── presentation/            # UI 레이어
│       └── pages/
│           └── records_page.dart
└── assets/                      # 리소스 파일
```

## 🔧 개발 환경 설정

### Flutter 개발 환경
```bash
# Flutter SDK 설치 확인
flutter doctor

# 개발 도구 설정
flutter pub get
flutter pub run build_runner build
```

## 🚀 배포

### Flutter 웹 배포
```bash
flutter build web
```

### Android APK 빌드
```bash
flutter build apk --release
```

### iOS 빌드
```bash
flutter build ios --release
```

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 📞 연락처

프로젝트 관련 문의사항이 있으시면 언제든지 연락주세요.
