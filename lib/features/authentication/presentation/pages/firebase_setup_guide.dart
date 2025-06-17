import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase 설정 상태 확인 및 가이드 페이지
///
/// Firebase 연동 상태를 확인하고 설정 가이드를 제공합니다.
/// 개발 중이나 Firebase 설정이 필요할 때 사용할 수 있는 디버그용 페이지입니다.
class FirebaseSetupGuide extends StatefulWidget {
  const FirebaseSetupGuide({super.key});

  @override
  State<FirebaseSetupGuide> createState() => _FirebaseSetupGuideState();
}

class _FirebaseSetupGuideState extends State<FirebaseSetupGuide> {
  bool _isFirebaseInitialized = false;
  bool _isAuthEnabled = false;
  bool _isFirestoreEnabled = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkFirebaseStatus();
  }

  Future<void> _checkFirebaseStatus() async {
    try {
      // Firebase 초기화 상태 확인
      _isFirebaseInitialized = Firebase.apps.isNotEmpty;

      if (_isFirebaseInitialized) {
        // Firebase Auth 상태 확인
        try {
          final auth = FirebaseAuth.instance;
          _isAuthEnabled = true;
        } catch (e) {
          _isAuthEnabled = false;
        }

        // Firestore 상태 확인
        try {
          final firestore = FirebaseFirestore.instance;
          await firestore.settings; // 설정 접근으로 연결 테스트
          _isFirestoreEnabled = true;
        } catch (e) {
          _isFirestoreEnabled = false;
        }
      }

      setState(() {});
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase 설정 가이드'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상태 카드
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firebase 연동 상태',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatusItem(
                      'Firebase 초기화',
                      _isFirebaseInitialized,
                      'Firebase Core가 성공적으로 초기화되었습니다.',
                      'Firebase 프로젝트 설정이 필요합니다.',
                    ),
                    const SizedBox(height: 8),
                    _buildStatusItem(
                      'Authentication',
                      _isAuthEnabled,
                      'Firebase Authentication이 활성화되었습니다.',
                      'Firebase Console에서 Authentication을 활성화하세요.',
                    ),
                    const SizedBox(height: 8),
                    _buildStatusItem(
                      'Firestore Database',
                      _isFirestoreEnabled,
                      'Firestore Database가 연결되었습니다.',
                      'Firebase Console에서 Firestore를 활성화하세요.',
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '오류: $_errorMessage',
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 설정 가이드
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firebase 설정 가이드',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildGuideStep(
                      '1',
                      'Firebase CLI 설치',
                      'npm install -g firebase-tools',
                      '터미널에서 Firebase CLI를 전역 설치합니다.',
                    ),
                    _buildGuideStep(
                      '2',
                      'FlutterFire CLI 설치',
                      'dart pub global activate flutterfire_cli',
                      'Flutter에서 Firebase를 쉽게 설정할 수 있는 CLI를 설치합니다.',
                    ),
                    _buildGuideStep(
                      '3',
                      'Firebase 로그인',
                      'firebase login',
                      'Firebase 계정으로 로그인합니다.',
                    ),
                    _buildGuideStep(
                      '4',
                      'Flutter 프로젝트 설정',
                      'flutterfire configure',
                      '프로젝트 루트에서 실행하여 Firebase와 연결합니다.',
                    ),
                    _buildGuideStep(
                      '5',
                      'Firebase 서비스 활성화',
                      'Firebase Console에서 설정',
                      'Authentication과 Firestore Database를 활성화합니다.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 소셜 로그인 설정 가이드
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '소셜 로그인 설정 가이드',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Google 로그인 설정
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.g_mobiledata, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Google 로그인 설정',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                              '1. Firebase Console → Authentication → Sign-in method'),
                          const Text('2. Google 제공업체 사용 설정'),
                          const Text('3. 프로젝트 지원 이메일 설정'),
                          const Text('4. 저장 후 완료'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 카카오 로그인 설정
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.yellow[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.yellow[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.chat_bubble, color: Colors.brown[700]),
                              const SizedBox(width: 8),
                              Text(
                                '카카오 로그인 설정',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('1. 카카오 개발자 콘솔(developers.kakao.com) 접속'),
                          const Text('2. 내 애플리케이션 → 앱 생성'),
                          const Text('3. 플랫폼 설정 → Android/iOS 추가'),
                          const Text('4. 카카오 로그인 활성화'),
                          const Text('5. 개인정보 보호 항목에서 이메일 선택 동의'),
                          const Text('6. main.dart에서 네이티브 앱 키 설정'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "KakaoSdk.init(\n  nativeAppKey: '카카오_네이티브_앱_키',\n);",
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 액션 버튼들
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _checkFirebaseStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('상태 새로고침'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('뒤로가기'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String title, bool isEnabled, String successMessage,
      String failureMessage) {
    return Row(
      children: [
        Icon(
          isEnabled ? Icons.check_circle : Icons.cancel,
          color: isEnabled ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                isEnabled ? successMessage : failureMessage,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuideStep(
      String stepNumber, String title, String command, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    command,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
