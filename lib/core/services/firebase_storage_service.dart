import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// Firebase Storage 서비스
/// 이미지 업로드 및 관리를 담당
class FirebaseStorageService {
  static final FirebaseStorageService _instance =
      FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const _uuid = Uuid();

  /// 이미지 업로드
  /// [imageFile]: 업로드할 이미지 파일
  /// [folder]: 저장할 폴더 경로 (예: 'posts', 'profiles')
  /// 반환값: 업로드된 이미지의 다운로드 URL
  Future<String> uploadImage(File imageFile, String folder) async {
    try {
      // 고유한 파일명 생성
      final fileName = '${_uuid.v4()}.jpg';
      final path = '$folder/$fileName';

      // Firebase Storage에 업로드
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(imageFile);

      // 업로드 진행 상황 모니터링
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        final progress =
            taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
        print('📤 업로드 진행률: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // 업로드 완료 대기
      final snapshot = await uploadTask;

      // 다운로드 URL 획득
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ 이미지 업로드 완료: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ 이미지 업로드 실패: $e');
      throw Exception('이미지 업로드에 실패했습니다: $e');
    }
  }

  /// 여러 이미지 업로드
  /// [imageFiles]: 업로드할 이미지 파일 목록
  /// [folder]: 저장할 폴더 경로
  /// 반환값: 업로드된 이미지들의 다운로드 URL 목록
  Future<List<String>> uploadImages(
      List<File> imageFiles, String folder) async {
    try {
      print('📤 ${imageFiles.length}개 이미지 업로드 시작...');

      final uploadTasks = imageFiles.map((file) => uploadImage(file, folder));
      final downloadUrls = await Future.wait(uploadTasks);

      print('✅ ${downloadUrls.length}개 이미지 업로드 완료');
      return downloadUrls;
    } catch (e) {
      print('❌ 이미지들 업로드 실패: $e');
      throw Exception('이미지들 업로드에 실패했습니다: $e');
    }
  }

  /// 이미지 삭제
  /// [imageUrl]: 삭제할 이미지의 다운로드 URL
  Future<void> deleteImage(String imageUrl) async {
    try {
      // URL에서 Firebase Storage 참조 생성
      final ref = _storage.refFromURL(imageUrl);

      // 이미지 삭제
      await ref.delete();

      print('✅ 이미지 삭제 완료: $imageUrl');
    } catch (e) {
      print('❌ 이미지 삭제 실패: $e');
      throw Exception('이미지 삭제에 실패했습니다: $e');
    }
  }

  /// 여러 이미지 삭제
  /// [imageUrls]: 삭제할 이미지들의 다운로드 URL 목록
  Future<void> deleteImages(List<String> imageUrls) async {
    try {
      print('🗑️ ${imageUrls.length}개 이미지 삭제 시작...');

      final deleteTasks = imageUrls.map((url) => deleteImage(url));
      await Future.wait(deleteTasks);

      print('✅ ${imageUrls.length}개 이미지 삭제 완료');
    } catch (e) {
      print('❌ 이미지들 삭제 실패: $e');
      throw Exception('이미지들 삭제에 실패했습니다: $e');
    }
  }

  /// 이미지 메타데이터 가져오기
  /// [imageUrl]: 메타데이터를 가져올 이미지의 다운로드 URL
  Future<FullMetadata> getImageMetadata(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      return await ref.getMetadata();
    } catch (e) {
      print('❌ 이미지 메타데이터 가져오기 실패: $e');
      throw Exception('이미지 메타데이터를 가져올 수 없습니다: $e');
    }
  }

  /// 저장소 사용량 체크 (개발용)
  Future<void> checkStorageUsage() async {
    try {
      final rootRef = _storage.ref();
      final result = await rootRef.listAll();

      print('📊 저장된 파일 수: ${result.items.length}');
      print('📁 폴더 수: ${result.prefixes.length}');

      // 각 폴더별 파일 수 출력
      for (final prefix in result.prefixes) {
        final prefixResult = await prefix.listAll();
        print('  📁 ${prefix.name}: ${prefixResult.items.length}개 파일');
      }
    } catch (e) {
      print('❌ 저장소 사용량 체크 실패: $e');
    }
  }

  /// 팀 배경 이미지 업로드
  /// [imageFile]: 업로드할 배경 이미지 파일
  /// [teamName]: 팀 이름
  /// 반환값: 업로드된 이미지의 다운로드 URL
  Future<String> uploadTeamBackground(File imageFile, String teamName) async {
    try {
      // 팀 이름을 파일명으로 사용 (기존 배경 이미지 덮어쓰기)
      final fileName = '${teamName.replaceAll(' ', '_')}_background.jpg';
      final path = 'team_backgrounds/$fileName';

      // Firebase Storage에 업로드
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(imageFile);

      // 업로드 진행 상황 모니터링
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        final progress =
            taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
        print('📤 팀 배경 이미지 업로드 진행률: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // 업로드 완료 대기
      final snapshot = await uploadTask;

      // 다운로드 URL 획득
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ 팀 배경 이미지 업로드 완료: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ 팀 배경 이미지 업로드 실패: $e');
      throw Exception('팀 배경 이미지 업로드에 실패했습니다: $e');
    }
  }

  /// 팀 배경 이미지 삭제
  /// [teamName]: 팀 이름
  Future<void> deleteTeamBackground(String teamName) async {
    try {
      final fileName = '${teamName.replaceAll(' ', '_')}_background.jpg';
      final path = 'team_backgrounds/$fileName';

      final ref = _storage.ref().child(path);
      await ref.delete();

      print('✅ 팀 배경 이미지 삭제 완료: $teamName');
    } catch (e) {
      print('❌ 팀 배경 이미지 삭제 실패: $e');
      // 파일이 존재하지 않는 경우는 무시
      if (!e.toString().contains('object-not-found')) {
        throw Exception('팀 배경 이미지 삭제에 실패했습니다: $e');
      }
    }
  }
}
