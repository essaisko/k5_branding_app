import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chukshin_app/core/services/storage_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
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
      if (firebaseUser != null) {
        // 사용자가 로그인된 경우, Firestore에서 추가 정보 가져오기
        final userDoc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final user = app_user.User.fromMap(userData);

          state = state.copyWith(
            user: user,
            isLoading: false,
            error: null,
          );
        } else {
          // Firestore에 사용자 정보가 없는 경우 (새 사용자)
          state = state.copyWith(
            user: null,
            isLoading: false,
            error: null,
          );
        }
      } else {
        // 사용자가 로그아웃된 경우
        state = state.copyWith(
          user: null,
          isLoading: false,
          error: null,
        );
      }
    } catch (e) {
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
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        // 새 사용자 - 기본 정보 생성
        final newUser = app_user.User(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? '신규 사용자',
          email: firebaseUser.email,
          phoneNumber: firebaseUser.phoneNumber ?? '',
          profileImageUrl: firebaseUser.photoURL,
          provider: credential.signInMethod,
        );
        await _firestore
            .collection('users')
            .doc(newUser.id)
            .set(newUser.toMap());

        state = state.copyWith(user: newUser, isLoading: false);
        return true; // 새 사용자
      } else {
        // 기존 사용자
        final existingUser = app_user.User.fromMap(userDoc.data()!);

        // 프로바이더 정보 업데이트 (예: 이전에 전화번호로 로그인하고, 이번에 구글로 로그인)
        if (existingUser.provider != credential.signInMethod) {
          await _firestore
              .collection('users')
              .doc(existingUser.id)
              .update({'provider': credential.signInMethod});
        }

        state = state.copyWith(user: existingUser, isLoading: false);
        return false; // 기존 사용자
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '로그인에 실패했습니다: ${e.toString()}',
      );
      return false;
    }
  }

  /// 구글 계정으로 로그인
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return false; // 사용자가 로그인 취소
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _signInWithCredential(credential);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Google 로그인에 실패했습니다: ${e.toString()}',
      );
      return false;
    }
  }

  /// 카카오 계정으로 로그인
  Future<bool> signInWithKakao() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      bool isKakaoInstalled = await isKakaoTalkInstalled();

      if (isKakaoInstalled) {
        // 카카오톡으로 로그인
        await UserApi.instance.loginWithKakaoTalk();
      } else {
        // 카카오 계정으로 로그인 (웹뷰)
        await UserApi.instance.loginWithKakaoAccount();
      }

      final kakao_sdk.User kakaoUser = await UserApi.instance.me();
      final String? email = kakaoUser.kakaoAccount?.email;

      if (email == null) {
        throw Exception('카카오 계정에서 이메일을 가져올 수 없습니다.');
      }

      // Firebase에 카카오 사용자가 있는지 확인
      final signInMethods =
          await _firebaseAuth.fetchSignInMethodsForEmail(email);

      if (signInMethods.isEmpty) {
        // Firebase에 없는 새 사용자 -> 임시 토큰으로 로그인 시도 (커스텀 인증)
        // 이 부분은 서버에서 커스텀 토큰을 생성하여 전달해야 합니다.
        // 현재는 클라이언트에서 직접 처리할 수 없으므로 에러로 처리합니다.
        throw Exception('신규 카카오 사용자는 현재 지원되지 않습니다. 서버 연동이 필요합니다.');
      } else {
        // 기존 사용자 -> 구글 프로바이더를 통해 우회 로그인
        // 이 방법은 보안상 취약하며, 실제 프로덕션에서는 서버를 통한 커스텀 토큰 인증을 사용해야 합니다.
        // 여기서는 데모를 위해 이메일/비밀번호 없는 로그인 방식을 가정합니다.
        // 실제로는 이메일로 로그인 링크를 보내거나, 다른 방식을 사용해야 합니다.
        throw Exception('기존 카카오 사용자의 Firebase 로그인은 서버 연동이 필요합니다.');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '카카오 로그인에 실패했습니다: ${e.toString()}',
      );
      return false;
    }
  }

  /// 사용자 프로필 업데이트
  Future<void> updateUserProfile({
    required String name,
    DateTime? birthDate,
    String? residenceArea,
    List<String>? affiliatedTeams,
    String? position,
    String? profileImagePath,
  }) async {
    if (state.user == null) {
      state = state.copyWith(error: '사용자 정보가 없습니다. 다시 로그인해주세요.');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final currentUser = state.user!;
      String? profileImageUrl = currentUser.profileImageUrl;

      // 새 프로필 이미지가 있으면 업로드
      if (profileImagePath != null) {
        final storageService = StorageService();
        profileImageUrl = await storageService.uploadProfileImage(
          userId: currentUser.id,
          imagePath: profileImagePath,
        );
      }

      final updatedUser = currentUser.copyWith(
        name: name,
        birthDate: birthDate,
        residenceArea: residenceArea,
        affiliatedTeams: affiliatedTeams,
        position: position,
        profileImageUrl: profileImageUrl,
        isProfileSetupComplete: true, // 프로필 설정 완료
      );

      await _firestore
          .collection('users')
          .doc(updatedUser.id)
          .set(updatedUser.toMap());

      state = state.copyWith(user: updatedUser, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '프로필 업데이트에 실패했습니다: ${e.toString()}',
      );
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      // 모든 소셜 로그인 세션 종료
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      // Kakao 로그아웃
      try {
        await UserApi.instance.logout();
      } catch (e) {
        // 이미 로그아웃된 경우 등 예외 무시
      }

      await _firebaseAuth.signOut();

      state = const AuthState(); // 초기 상태로 리셋
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '로그아웃에 실패했습니다: ${e.toString()}',
      );
    }
  }

  /// 회원 탈퇴
  Future<void> deleteAccount() async {
    if (state.user == null) return;

    state = state.copyWith(isLoading: true);
    final userId = state.user!.id;

    try {
      // Firestore에서 사용자 데이터 삭제
      await _firestore.collection('users').doc(userId).delete();

      // Firebase Storage에서 프로필 이미지 삭제 (선택 사항)
      try {
        final storageService = StorageService();
        await storageService.deleteProfileImage(userId: userId);
      } catch (e) {
        // 이미지 삭제 실패는 전체 프로세스를 중단하지 않음
      }

      // Firebase Auth에서 사용자 삭제
      await _firebaseAuth.currentUser?.delete();

      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '회원 탈퇴에 실패했습니다: ${e.toString()}',
      );
      // 재인증이 필요한 경우 처리
      if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
        state = state.copyWith(error: '보안을 위해 재로그인이 필요합니다. 다시 로그인 후 시도해주세요.');
      }
    }
  }

  /// 휴대전화번호 포맷 정규화
  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('010')) {
      return '+82${cleaned.substring(1)}';
    }
    return phone; // 기본값
  }

  /// 로컬 상태 초기화 (디버깅용)
  void resetState() {
    state = const AuthState();
  }
}

/// 전역 인증 프로바이더
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
