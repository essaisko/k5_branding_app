import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chukshin_app/core/services/storage_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' hide User;
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao_sdk
    show User;
import 'package:chukshin_app/features/authentication/domain/entities/user.dart'
    as app_user;

/// 인증 상태를 나타내는 클래스
class AuthState {
  /// 현재 로그인된 사용자 (null이면 로그아웃 상태)
  final app_user.User? user;

  /// 로딩 상태
  final bool isLoading;

  /// 에러 메시지
  final String? error;

  /// SMS 인증 진행 상태
  final bool isVerificationInProgress;

  /// 인증 ID (SMS 인증 시 사용)
  final String? verificationId;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isVerificationInProgress = false,
    this.verificationId,
  });

  /// AuthState 복사 및 수정
  AuthState copyWith({
    app_user.User? user,
    bool? isLoading,
    String? error,
    bool? isVerificationInProgress,
    String? verificationId,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isVerificationInProgress:
          isVerificationInProgress ?? this.isVerificationInProgress,
      verificationId: verificationId ?? this.verificationId,
    );
  }

  /// 로그인 상태 확인
  bool get isAuthenticated => user != null;

  /// 에러 상태 확인
  bool get hasError => error != null;
}

/// Firebase Authentication을 사용한 인증 상태 관리 프로바이더
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthNotifier() : super(const AuthState()) {
    // Firebase Auth 상태 변경 리스너 설정
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Firebase Auth 상태 변경 처리
  Future<void> _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    try {
      print('📡 AuthStateChanged 트리거됨: ${firebaseUser?.uid}');

      if (firebaseUser != null) {
        print('📡 사용자 로그인 상태 - Firestore에서 추가 정보 가져오는 중...');

        // 사용자가 로그인된 경우, Firestore에서 추가 정보 가져오기
        final userDoc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();

        if (userDoc.exists) {
          print('📡 Firestore에서 사용자 정보 발견');
          final userData = userDoc.data()!;
          final user = app_user.User.fromMap(userData);

          print('📡 사용자 정보: ${user.name} (${user.email})');
          print('📡 프로필 설정 완료: ${user.isProfileSetupComplete}');

          state = state.copyWith(
            user: user,
            isLoading: false,
            error: null,
          );
          print('📡 State 업데이트 완료 - 기존 사용자 정보 로드');
        } else {
          print('📡 Firestore에 사용자 정보 없음 (새 사용자 또는 미완성)');
          // Firestore에 사용자 정보가 없는 경우 (새 사용자)
          state = state.copyWith(
            user: null,
            isLoading: false,
            error: null,
          );
          print('📡 State 업데이트 완료 - 사용자 정보 없음');
        }
      } else {
        print('📡 사용자 로그아웃 상태');
        // 사용자가 로그아웃된 경우
        state = state.copyWith(
          user: null,
          isLoading: false,
          error: null,
        );
        print('📡 State 업데이트 완료 - 로그아웃');
      }
    } catch (e) {
      print('🔴 AuthStateChanged 오류: ${e.toString()}');
      state = state.copyWith(
        isLoading: false,
        error: '인증 상태 확인 중 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  /// 휴대전화번호로 인증 코드 전송
  Future<void> sendVerificationCode(String phoneNumber) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      isVerificationInProgress: false,
    );

    try {
      // 전화번호 형식 정규화 (+82로 시작하도록)
      String formattedPhoneNumber = _formatPhoneNumber(phoneNumber);

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: formattedPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // 자동 인증 완료 (Android에서만 가능)
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage = '인증 코드 전송에 실패했습니다.';

          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = '올바르지 않은 휴대전화번호입니다.';
              break;
            case 'too-many-requests':
              errorMessage = '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
              break;
            case 'quota-exceeded':
              errorMessage = '일일 SMS 전송 한도를 초과했습니다.';
              break;
          }

          state = state.copyWith(
            isLoading: false,
            error: errorMessage,
            isVerificationInProgress: false,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          state = state.copyWith(
            isLoading: false,
            error: null,
            isVerificationInProgress: true,
            verificationId: verificationId,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // 자동 검색 시간 초과
          state = state.copyWith(
            verificationId: verificationId,
          );
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '인증 코드 전송 중 오류가 발생했습니다: ${e.toString()}',
        isVerificationInProgress: false,
      );
    }
  }

  /// 인증 코드로 로그인
  Future<bool> verifyCodeAndSignIn(String verificationCode) async {
    if (state.verificationId == null) {
      state = state.copyWith(
        error: '인증 ID가 없습니다. 다시 시도해주세요.',
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: state.verificationId!,
        smsCode: verificationCode,
      );

      final isNewUser = await _signInWithCredential(credential);
      return isNewUser;
    } catch (e) {
      String errorMessage = '인증에 실패했습니다.';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-verification-code':
            errorMessage = '잘못된 인증 코드입니다.';
            break;
          case 'session-expired':
            errorMessage = '인증 세션이 만료되었습니다. 다시 시도해주세요.';
            break;
        }
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  /// Credential로 로그인 처리
  Future<bool> _signInWithCredential(AuthCredential credential) async {
    try {
      print('🔥 Firebase signInWithCredential 시작');
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      print('🔥 Firebase 사용자 정보:');
      print('   - UID: ${firebaseUser.uid}');
      print('   - Email: ${firebaseUser.email}');
      print('   - DisplayName: ${firebaseUser.displayName}');
      print('   - PhoneNumber: ${firebaseUser.phoneNumber}');

      // 새 사용자인지 확인
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      print('🔥 새 사용자 여부: $isNewUser');

      if (isNewUser) {
        print('🔥 새 사용자 - Firestore에 기본 정보 저장 중...');
        // 새 사용자인 경우 - Firebase에 기본 사용자 정보 생성 (프로필 미완성 상태)
        final incompleteUser = app_user.User(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? '',
          phoneNumber: firebaseUser.phoneNumber ?? '',
          email: firebaseUser.email ?? '',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isPhoneVerified: firebaseUser.phoneNumber != null,
          isActive: true,
          birthDate: DateTime(1990, 1, 1), // 임시 기본값, 프로필 설정에서 실제 값 입력
          isProfileSetupComplete: false, // 프로필 미완성
        );

        // Firestore에 기본 정보 저장
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(incompleteUser.toMap());

        print('🔥 Firestore 저장 완료');

        state = state.copyWith(
          user: incompleteUser,
          isLoading: false,
          error: null,
          isVerificationInProgress: false,
          verificationId: null,
        );
        print('🔥 State 업데이트 완료 - 새 사용자');
        return true; // 새 사용자
      } else {
        print('🔥 기존 사용자 - 로그인 시간 업데이트 중...');
        // 기존 사용자인 경우 - 로그인 완료
        await _updateLastLoginTime(firebaseUser.uid);
        print('🔥 로그인 시간 업데이트 완료');

        // authStateChanges 리스너가 사용자 정보를 업데이트할 것임
        state = state.copyWith(
          isLoading: false,
          error: null,
          isVerificationInProgress: false,
          verificationId: null,
        );
        print('🔥 State 업데이트 완료 - 기존 사용자');
        return false; // 기존 사용자
      }
    } catch (e) {
      print('🔴 _signInWithCredential 오류: ${e.toString()}');
      print('🔴 오류 타입: ${e.runtimeType}');
      state = state.copyWith(
        isLoading: false,
        error: '로그인 처리 중 오류가 발생했습니다: ${e.toString()}',
        isVerificationInProgress: false,
      );
      rethrow;
    }
  }

  /// Google 로그인
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🟢 Google Sign-In 시작');

      // Google Sign-In 진행
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('🟢 Google Sign-In 계정 선택: ${googleUser?.email}');

      if (googleUser == null) {
        // 사용자가 로그인을 취소한 경우
        print('🟡 Google Sign-In 취소됨');
        state = state.copyWith(isLoading: false, error: null);
        return false;
      }

      print('🟢 Google 인증 정보 가져오는 중...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('🟢 AccessToken 존재: ${googleAuth.accessToken != null}');
      print('🟢 IdToken 존재: ${googleAuth.idToken != null}');

      // Firebase Auth 자격 증명 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🟢 Firebase 자격 증명 생성 완료');

      // Firebase에 로그인
      print('🟢 Firebase 로그인 시도 중...');
      final isNewUser = await _signInWithCredential(credential);
      print('🟢 Firebase 로그인 완료 - 새 사용자: $isNewUser');
      return isNewUser;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = '이미 다른 방법으로 가입된 계정입니다.';
          break;
        case 'invalid-credential':
          errorMessage = '유효하지 않은 자격 증명입니다.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Google 로그인이 비활성화되어 있습니다.';
          break;
        case 'user-disabled':
          errorMessage = '비활성화된 계정입니다.';
          break;
        default:
          errorMessage = 'Google 로그인 중 오류가 발생했습니다: ${e.message}';
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      throw Exception(errorMessage);
    } catch (e) {
      final errorMessage = 'Google 로그인 중 예상치 못한 오류가 발생했습니다: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      throw Exception(errorMessage);
    }
  }

  /// 카카오 로그인
  Future<bool> signInWithKakao() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      OAuthToken token;

      // 카카오톡으로 로그인 가능한지 확인 후 시도
      if (await isKakaoTalkInstalled()) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          // 카카오톡으로 로그인 실패 시 카카오계정으로 로그인 시도
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        // 카카오톡이 설치되지 않은 경우 바로 카카오계정으로 로그인
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      // 카카오 사용자 정보 가져오기
      final kakaoUser = await UserApi.instance.me();

      // Firebase Custom Token 생성을 위한 정보 준비
      // 실제로는 서버에서 Custom Token을 생성해야 하지만,
      // 여기서는 간단히 이메일/비밀번호 방식으로 계정 생성/로그인 시도
      final email = kakaoUser.kakaoAccount?.email;
      final name = kakaoUser.kakaoAccount?.profile?.nickname ?? 'Kakao User';

      if (email == null) {
        throw Exception(
            '카카오 계정에서 이메일 정보를 가져올 수 없습니다. 카카오 개발자 콘솔에서 이메일 수집을 활성화해주세요.');
      }

      // Firebase에서 해당 이메일로 계정이 있는지 확인
      try {
        final methods = await _firebaseAuth.fetchSignInMethodsForEmail(email);

        if (methods.isEmpty) {
          // 신규 사용자 - 임시 비밀번호로 계정 생성
          final tempPassword = 'kakao_${kakaoUser.id}_temp_password_k5league';
          final userCredential =
              await _firebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: tempPassword,
          );

          if (userCredential.user != null) {
            // 프로필 정보 업데이트
            await userCredential.user!.updateDisplayName(name);

            // 새 사용자이므로 추가 정보 입력 필요
            state = state.copyWith(isLoading: false, error: null);
            return true;
          }
        } else {
          // 기존 사용자 - 카카오 로그인으로 등록된 계정인지 확인
          final userDoc = await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .get();

          if (userDoc.docs.isNotEmpty) {
            // 카카오로 등록된 계정 - 임시 비밀번호로 로그인
            final tempPassword = 'kakao_${kakaoUser.id}_temp_password_k5league';
            await _firebaseAuth.signInWithEmailAndPassword(
              email: email,
              password: tempPassword,
            );

            // 마지막 로그인 시간 업데이트
            await _firestore
                .collection('users')
                .doc(userDoc.docs.first.id)
                .update({'lastLoginAt': FieldValue.serverTimestamp()});

            state = state.copyWith(isLoading: false, error: null);
            return false; // 기존 사용자
          } else {
            throw Exception('이미 다른 방법으로 가입된 이메일입니다. 해당 방법으로 로그인해주세요.');
          }
        }
      } catch (e) {
        if (e.toString().contains('이미 다른 방법으로 가입된')) {
          rethrow;
        }
        throw Exception('카카오 로그인 처리 중 오류가 발생했습니다: ${e.toString()}');
      }

      // authStateChanges 리스너가 상태를 업데이트할 것임
      return false;
    } catch (e) {
      String errorMessage;
      if (e is PlatformException) {
        switch (e.code) {
          case 'KakaoClientErrorCancelled':
            errorMessage = '로그인이 취소되었습니다.';
            break;
          default:
            errorMessage = '카카오 로그인 중 오류가 발생했습니다: ${e.message}';
        }
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );

      if (!errorMessage.contains('취소되었습니다')) {
        throw Exception(errorMessage);
      }
      return false;
    }
  }

  /// 새 사용자 등록 (추가 정보와 함께)
  Future<void> completeSignup({
    required String name,
    required DateTime birthDate,
    String? residenceArea,
    List<String>? affiliatedTeams,
    String? position,
  }) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw Exception('로그인된 사용자가 없습니다.');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = app_user.User(
        id: firebaseUser.uid,
        name: name,
        phoneNumber: firebaseUser.phoneNumber ?? '',
        email: firebaseUser.email,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isPhoneVerified: firebaseUser.phoneNumber != null,
        isActive: true,
        birthDate: birthDate,
        isProfileSetupComplete: true,
        residenceArea: residenceArea,
        affiliatedTeams: affiliatedTeams ?? [],
        position: position,
      );

      // Firestore에 사용자 정보 저장
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toMap());

      state = state.copyWith(
        user: user,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '회원가입 처리 중 오류가 발생했습니다: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// 사용자 프로필 업데이트
  Future<void> updateUserProfile({
    String? name,
    DateTime? birthDate,
    String? gender,
    String? favoriteTeam,
    String? position,
    String? residenceArea,
    List<String>? affiliatedTeams,
    bool? isProfileSetupComplete,
    File? profileImage,
  }) async {
    if (state.user == null) {
      throw Exception('로그인된 사용자가 없습니다.');
    }

    print('🔥 프로필 업데이트 시작');
    print('🔥 업데이트할 필드들:');
    print('   - name: $name');
    print('   - birthDate: $birthDate');
    print('   - position: $position');
    print('   - residenceArea: $residenceArea');
    print('   - affiliatedTeams: $affiliatedTeams');
    print(
        '   - profileImage: ${profileImage != null ? "있음 (${profileImage.path})" : "없음"}');

    state = state.copyWith(isLoading: true, error: null);

    try {
      String? profileImageUrl;

      // 프로필 이미지 업로드 처리
      if (profileImage != null) {
        print('🔥 프로필 이미지 업로드 중...');
        profileImageUrl =
            await _uploadProfileImage(profileImage, state.user!.id);
        print('🔥 프로필 이미지 업로드 완료: $profileImageUrl');
      } else {
        print('🔥 프로필 이미지 업로드 없음');
      }

      final updatedUser = state.user!.copyWith(
        name: name,
        birthDate: birthDate,
        gender: gender,
        favoriteTeam: favoriteTeam,
        position: position,
        residenceArea: residenceArea,
        affiliatedTeams: affiliatedTeams,
        isProfileSetupComplete: isProfileSetupComplete,
        profileImageUrl: profileImageUrl ?? state.user!.profileImageUrl,
      );

      print('🔥 업데이트된 사용자 정보:');
      print('   - profileImageUrl: ${updatedUser.profileImageUrl}');

      // Firestore 업데이트
      print('🔥 Firestore 업데이트 중...');
      await _firestore
          .collection('users')
          .doc(state.user!.id)
          .update(updatedUser.toMap());
      print('🔥 Firestore 업데이트 완료');

      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
        error: null,
      );
      print('🔥 프로필 업데이트 성공');
    } catch (e) {
      print('🔴 프로필 업데이트 오류: ${e.toString()}');
      print('🔴 오류 타입: ${e.runtimeType}');
      state = state.copyWith(
        isLoading: false,
        error: '프로필 업데이트 중 오류가 발생했습니다: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// 프로필 이미지를 Firebase Storage에 업로드
  Future<String> _uploadProfileImage(File imageFile, String userId) async {
    try {
      return await StorageService.uploadProfileImage(imageFile, userId);
    } catch (e) {
      throw Exception('프로필 이미지 업로드 실패: ${e.toString()}');
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _firebaseAuth.signOut();

      state = state.copyWith(
        user: null,
        isLoading: false,
        error: null,
        isVerificationInProgress: false,
        verificationId: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '로그아웃 중 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  /// 현재 사용자 정보 새로고침
  Future<void> refreshUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      await _onAuthStateChanged(firebaseUser);
    }
  }

  /// 에러 상태 클리어
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 마지막 로그인 시간 업데이트
  Future<void> _updateLastLoginTime(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'lastLoginAt': FieldValue.serverTimestamp()});
    } catch (e) {
      // 로그인 시간 업데이트 실패는 중요하지 않으므로 무시
    }
  }

  /// 전화번호 형식 정규화
  String _formatPhoneNumber(String phoneNumber) {
    // 공백과 하이픈 제거
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');

    // 010으로 시작하는 경우 +8210으로 변경
    if (cleaned.startsWith('010')) {
      return '+82${cleaned.substring(1)}';
    }

    // 이미 +82로 시작하는 경우 그대로 반환
    if (cleaned.startsWith('+82')) {
      return cleaned;
    }

    // 그 외의 경우 그대로 반환 (국제번호 등)
    return cleaned;
  }
}

/// 인증 상태 프로바이더
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// 현재 사용자 프로바이더 (편의용)
final currentUserProvider = Provider<app_user.User?>((ref) {
  return ref.watch(authProvider).user;
});

/// 인증 상태 확인 프로바이더 (편의용)
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Firebase Auth 인스턴스 프로바이더
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Firebase Firestore 인스턴스 프로바이더
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});
