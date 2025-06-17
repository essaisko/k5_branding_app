import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chukshin_app/core/exceptions/app_exceptions.dart';

/// Firebase Storage 서비스
/// 파일 업로드, 다운로드, 삭제 등의 작업을 담당
class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 프로필 이미지 업로드
  static Future<String> uploadProfileImage(
      File imageFile, String userId) async {
    try {
      // 인증 상태 확인
      final currentUser = FirebaseAuth.instance.currentUser;
      print('🔥 프로필 이미지 업로드 시작: $userId');
      print('🔥 현재 인증된 사용자: ${currentUser?.uid}');
      print('🔥 사용자 인증 상태: ${currentUser != null ? "인증됨" : "미인증"}');
      print('🔥 제공된 userId와 인증 userId 일치: ${currentUser?.uid == userId}');
      print('🔥 이미지 파일 존재: ${imageFile.existsSync()}');
      print('🔥 이미지 파일 크기: ${imageFile.lengthSync()} bytes');

      // 사용자 인증 상태 확인
      if (currentUser == null) {
        throw StorageException('사용자가 인증되지 않았습니다. 다시 로그인해주세요.');
      }

      if (currentUser.uid != userId) {
        throw StorageException('제공된 사용자 ID와 인증된 사용자 ID가 일치하지 않습니다.');
      }

      // 파일 확장자 확인
      final String fileName = imageFile.path.split('/').last;
      final String fileExtension = fileName.split('.').last.toLowerCase();
      print('🔥 파일 확장자: $fileExtension');

      final storageRef = _storage
          .ref()
          .child('profile_images')
          .child(userId)
          .child('profile.$fileExtension');

      print('🔥 Storage Reference 생성 완료: ${storageRef.fullPath}');
      print('🔥 Firebase Auth 토큰 확인 중...');
      final idToken = await currentUser.getIdToken();
      print('🔥 ID 토큰 존재: ${idToken?.isNotEmpty ?? false}');
      print('🔥 ID 토큰 길이: ${idToken?.length ?? 0} 문자');

      // 메타데이터 설정
      final metadata = SettableMetadata(
        contentType: _getContentType(fileExtension),
        customMetadata: {
          'uploadedBy': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
          'type': 'profile_image',
        },
      );

      final uploadTask = storageRef.putFile(imageFile, metadata);
      print('🔥 업로드 태스크 시작 (메타데이터 포함)');

      // 업로드 진행률 모니터링
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        final progress =
            (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100;
        print('🔥 업로드 진행률: ${progress.toStringAsFixed(1)}%');
      });

      final snapshot = await uploadTask;
      print('🔥 업로드 완료: ${snapshot.state}');
      print('🔥 총 전송된 바이트: ${snapshot.bytesTransferred}');

      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('🔥 다운로드 URL 획득: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('🔴 프로필 이미지 업로드 오류: ${e.toString()}');
      print('🔴 오류 타입: ${e.runtimeType}');

      if (e is FirebaseException) {
        print('🔴 Firebase 오류 코드: ${e.code}');
        print('🔴 Firebase 오류 메시지: ${e.message}');

        switch (e.code) {
          case 'storage/unauthorized':
            throw StorageException('프로필 이미지 업로드 권한이 없습니다. 다시 로그인해주세요.');
          case 'storage/canceled':
            throw StorageException('프로필 이미지 업로드가 취소되었습니다.');
          case 'storage/unknown':
            throw StorageException('알 수 없는 오류로 프로필 이미지 업로드에 실패했습니다.');
          default:
            throw StorageException('프로필 이미지 업로드 실패: ${e.message}');
        }
      }

      throw StorageException('프로필 이미지 업로드 실패: ${e.toString()}');
    }
  }

  /// 팀 헤더 이미지 업로드
  static Future<String> uploadTeamHeaderImage(
      File imageFile, String teamId) async {
    try {
      print('🔥 팀 헤더 이미지 업로드 시작: $teamId');

      final String fileName = imageFile.path.split('/').last;
      final String fileExtension = fileName.split('.').last.toLowerCase();

      final storageRef = _storage
          .ref()
          .child('team_images')
          .child(teamId)
          .child('header.$fileExtension');

      final metadata = SettableMetadata(
        contentType: _getContentType(fileExtension),
        customMetadata: {
          'teamId': teamId,
          'uploadedAt': DateTime.now().toIso8601String(),
          'type': 'team_header',
        },
      );

      final uploadTask = storageRef.putFile(imageFile, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('🔥 팀 헤더 이미지 업로드 완료: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('🔴 팀 헤더 이미지 업로드 오류: ${e.toString()}');
      throw StorageException('팀 헤더 이미지 업로드 실패: ${e.toString()}');
    }
  }

  /// 이미지 삭제
  static Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('🔥 이미지 삭제 완료: $imageUrl');
    } catch (e) {
      print('🔴 이미지 삭제 오류: ${e.toString()}');
      throw StorageException('이미지 삭제 실패: ${e.toString()}');
    }
  }

  /// 파일 확장자에 따른 Content-Type 반환
  static String _getContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
