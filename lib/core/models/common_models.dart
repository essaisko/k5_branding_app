import 'package:equatable/equatable.dart';

/// 저장 결과를 나타내는 불변 클래스
class SaveResult extends Equatable {
  final int savedCount;
  final int updatedCount;
  final int skippedCount;

  const SaveResult({
    this.savedCount = 0,
    this.updatedCount = 0,
    this.skippedCount = 0,
  });

  int get totalProcessed => savedCount + updatedCount + skippedCount;

  SaveResult copyWith({
    int? savedCount,
    int? updatedCount,
    int? skippedCount,
  }) {
    return SaveResult(
      savedCount: savedCount ?? this.savedCount,
      updatedCount: updatedCount ?? this.updatedCount,
      skippedCount: skippedCount ?? this.skippedCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'savedCount': savedCount,
      'updatedCount': updatedCount,
      'skippedCount': skippedCount,
      'totalProcessed': totalProcessed,
    };
  }

  factory SaveResult.fromJson(Map<String, dynamic> json) {
    return SaveResult(
      savedCount: json['savedCount'] ?? 0,
      updatedCount: json['updatedCount'] ?? 0,
      skippedCount: json['skippedCount'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [savedCount, updatedCount, skippedCount];

  @override
  String toString() {
    return 'SaveResult(saved: $savedCount, updated: $updatedCount, skipped: $skippedCount)';
  }
}

/// 팀 순위를 나타내는 불변 클래스
class TeamRanking extends Equatable {
  final int rank;
  final String teamName;
  final int matches;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int points;
  final int goalDifference;

  const TeamRanking({
    this.rank = 0,
    required this.teamName,
    required this.matches,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.points,
    required this.goalDifference,
  });

  TeamRanking copyWith({
    int? rank,
    String? teamName,
    int? matches,
    int? wins,
    int? draws,
    int? losses,
    int? goalsFor,
    int? goalsAgainst,
    int? points,
    int? goalDifference,
  }) {
    return TeamRanking(
      rank: rank ?? this.rank,
      teamName: teamName ?? this.teamName,
      matches: matches ?? this.matches,
      wins: wins ?? this.wins,
      draws: draws ?? this.draws,
      losses: losses ?? this.losses,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
      points: points ?? this.points,
      goalDifference: goalDifference ?? this.goalDifference,
    );
  }

  /// 승률 계산 (백분율)
  double get winRate => matches > 0 ? (wins / matches) * 100 : 0.0;

  /// 평균 득점
  double get averageGoalsFor => matches > 0 ? goalsFor / matches : 0.0;

  /// 평균 실점
  double get averageGoalsAgainst => matches > 0 ? goalsAgainst / matches : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'teamName': teamName,
      'matches': matches,
      'wins': wins,
      'draws': draws,
      'losses': losses,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
      'points': points,
      'goalDifference': goalDifference,
    };
  }

  factory TeamRanking.fromJson(Map<String, dynamic> json) {
    return TeamRanking(
      rank: json['rank'] ?? 0,
      teamName: json['teamName'] ?? '',
      matches: json['matches'] ?? 0,
      wins: json['wins'] ?? 0,
      draws: json['draws'] ?? 0,
      losses: json['losses'] ?? 0,
      goalsFor: json['goalsFor'] ?? 0,
      goalsAgainst: json['goalsAgainst'] ?? 0,
      points: json['points'] ?? 0,
      goalDifference: json['goalDifference'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        rank,
        teamName,
        matches,
        wins,
        draws,
        losses,
        goalsFor,
        goalsAgainst,
        points,
        goalDifference,
      ];

  @override
  String toString() {
    return 'TeamRanking(rank: $rank, team: $teamName, points: $points)';
  }
}

/// 동기화 상태를 나타내는 열거형
enum SyncStatus {
  idle('idle', '대기'),
  syncing('syncing', '동기화 중'),
  success('success', '성공'),
  error('error', '오류'),
  cancelled('cancelled', '취소됨');

  const SyncStatus(this.code, this.displayName);

  final String code;
  final String displayName;

  static SyncStatus fromCode(String code) {
    return SyncStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => SyncStatus.idle,
    );
  }
}

/// 동기화 결과를 나타내는 불변 클래스
class SyncResult extends Equatable {
  final SyncStatus status;
  final String message;
  final DateTime timestamp;
  final SaveResult? saveResult;
  final String? errorDetails;
  final int crawledCount;
  final List<String> crawlErrors;

  const SyncResult({
    required this.status,
    required this.message,
    required this.timestamp,
    this.saveResult,
    this.errorDetails,
    this.crawledCount = 0,
    this.crawlErrors = const [],
  });

  SyncResult copyWith({
    SyncStatus? status,
    String? message,
    DateTime? timestamp,
    SaveResult? saveResult,
    String? errorDetails,
    int? crawledCount,
    List<String>? crawlErrors,
  }) {
    return SyncResult(
      status: status ?? this.status,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      saveResult: saveResult ?? this.saveResult,
      errorDetails: errorDetails ?? this.errorDetails,
      crawledCount: crawledCount ?? this.crawledCount,
      crawlErrors: crawlErrors ?? this.crawlErrors,
    );
  }

  bool get isSuccess => status == SyncStatus.success;
  bool get isError => status == SyncStatus.error;
  bool get isInProgress => status == SyncStatus.syncing;

  // 편의 메서드들
  int get savedCount => saveResult?.savedCount ?? 0;
  int get updatedCount => saveResult?.updatedCount ?? 0;
  int get skippedCount => saveResult?.skippedCount ?? 0;
  String? get error => errorDetails;
  double get successRate =>
      crawledCount > 0 ? (savedCount + updatedCount) / crawledCount * 100 : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'status': status.code,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'saveResult': saveResult?.toJson(),
      'errorDetails': errorDetails,
      'crawledCount': crawledCount,
      'crawlErrors': crawlErrors,
    };
  }

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      status: SyncStatus.fromCode(json['status'] ?? 'idle'),
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      saveResult: json['saveResult'] != null
          ? SaveResult.fromJson(json['saveResult'])
          : null,
      errorDetails: json['errorDetails'],
      crawledCount: json['crawledCount'] ?? 0,
      crawlErrors: List<String>.from(json['crawlErrors'] ?? []),
    );
  }

  @override
  List<Object?> get props => [
        status,
        message,
        timestamp,
        saveResult,
        errorDetails,
        crawledCount,
        crawlErrors
      ];

  @override
  String toString() {
    return 'SyncResult(status: ${status.displayName}, message: $message)';
  }
}

/// 크롤링 결과를 나타내는 불변 클래스
class CrawlingResult extends Equatable {
  final int totalMatches;
  final int savedMatches;
  final int duplicateSkips;
  final List<String> errors;
  final DateTime completedAt;
  final Duration executionTime;

  CrawlingResult({
    this.totalMatches = 0,
    this.savedMatches = 0,
    this.duplicateSkips = 0,
    this.errors = const [],
    DateTime? completedAt,
    Duration? executionTime,
  })  : completedAt = completedAt ?? DateTime.now(),
        executionTime = executionTime ?? const Duration();

  /// 성공률 (0.0 ~ 1.0)
  double get successRate =>
      totalMatches > 0 ? savedMatches / totalMatches : 0.0;

  CrawlingResult copyWith({
    int? totalMatches,
    int? savedMatches,
    int? duplicateSkips,
    List<String>? errors,
    DateTime? completedAt,
    Duration? executionTime,
  }) {
    return CrawlingResult(
      totalMatches: totalMatches ?? this.totalMatches,
      savedMatches: savedMatches ?? this.savedMatches,
      duplicateSkips: duplicateSkips ?? this.duplicateSkips,
      errors: errors ?? this.errors,
      completedAt: completedAt ?? this.completedAt,
      executionTime: executionTime ?? this.executionTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMatches': totalMatches,
      'savedMatches': savedMatches,
      'duplicateSkips': duplicateSkips,
      'errors': errors,
      'completedAt': completedAt.toIso8601String(),
      'executionTime': executionTime.inMilliseconds,
    };
  }

  factory CrawlingResult.fromJson(Map<String, dynamic> json) {
    return CrawlingResult(
      totalMatches: json['totalMatches'] ?? 0,
      savedMatches: json['savedMatches'] ?? 0,
      duplicateSkips: json['duplicateSkips'] ?? 0,
      errors: List<String>.from(json['errors'] ?? []),
      completedAt: DateTime.parse(json['completedAt']),
      executionTime: Duration(milliseconds: json['executionTime'] ?? 0),
    );
  }

  @override
  List<Object?> get props => [
        totalMatches,
        savedMatches,
        duplicateSkips,
        errors,
        completedAt,
        executionTime,
      ];

  @override
  String toString() {
    return 'CrawlingResult(total: $totalMatches, saved: $savedMatches, skipped: $duplicateSkips)';
  }
}

/// 동기화 상태를 나타내는 불변 클래스
class SyncState extends Equatable {
  final bool isFullSyncRunning;
  final bool isIncrementalSyncRunning;
  final bool isAutoSyncEnabled;
  final SyncResult? lastSyncResult;
  final CrawlingProgress? currentProgress;
  final String? error;

  const SyncState({
    this.isFullSyncRunning = false,
    this.isIncrementalSyncRunning = false,
    this.isAutoSyncEnabled = false,
    this.lastSyncResult,
    this.currentProgress,
    this.error,
  });

  SyncState copyWith({
    bool? isFullSyncRunning,
    bool? isIncrementalSyncRunning,
    bool? isAutoSyncEnabled,
    SyncResult? lastSyncResult,
    CrawlingProgress? currentProgress,
    String? error,
  }) {
    return SyncState(
      isFullSyncRunning: isFullSyncRunning ?? this.isFullSyncRunning,
      isIncrementalSyncRunning:
          isIncrementalSyncRunning ?? this.isIncrementalSyncRunning,
      isAutoSyncEnabled: isAutoSyncEnabled ?? this.isAutoSyncEnabled,
      lastSyncResult: lastSyncResult ?? this.lastSyncResult,
      currentProgress: currentProgress ?? this.currentProgress,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        isFullSyncRunning,
        isIncrementalSyncRunning,
        isAutoSyncEnabled,
        lastSyncResult,
        currentProgress,
        error,
      ];

  @override
  String toString() {
    return 'SyncState(fullSync: $isFullSyncRunning, incrementalSync: $isIncrementalSyncRunning, autoSync: $isAutoSyncEnabled)';
  }
}

/// 크롤러 설정을 나타내는 불변 클래스
class CrawlerSettings extends Equatable {
  final int intervalHours;
  final List<String> targetLeagues;
  final List<String> targetAreas;
  final bool autoRetry;
  final int maxRetries;
  final bool enableNotifications;

  const CrawlerSettings({
    this.intervalHours = 24,
    this.targetLeagues = const ['K5', 'K6', 'K7'],
    this.targetAreas = const ['부산', '경남'],
    this.autoRetry = true,
    this.maxRetries = 3,
    this.enableNotifications = true,
  });

  CrawlerSettings copyWith({
    int? intervalHours,
    List<String>? targetLeagues,
    List<String>? targetAreas,
    bool? autoRetry,
    int? maxRetries,
    bool? enableNotifications,
  }) {
    return CrawlerSettings(
      intervalHours: intervalHours ?? this.intervalHours,
      targetLeagues: targetLeagues ?? this.targetLeagues,
      targetAreas: targetAreas ?? this.targetAreas,
      autoRetry: autoRetry ?? this.autoRetry,
      maxRetries: maxRetries ?? this.maxRetries,
      enableNotifications: enableNotifications ?? this.enableNotifications,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'intervalHours': intervalHours,
      'targetLeagues': targetLeagues,
      'targetAreas': targetAreas,
      'autoRetry': autoRetry,
      'maxRetries': maxRetries,
      'enableNotifications': enableNotifications,
    };
  }

  factory CrawlerSettings.fromJson(Map<String, dynamic> json) {
    return CrawlerSettings(
      intervalHours: json['intervalHours'] ?? 24,
      targetLeagues:
          List<String>.from(json['targetLeagues'] ?? ['K5', 'K6', 'K7']),
      targetAreas: List<String>.from(json['targetAreas'] ?? ['부산', '경남']),
      autoRetry: json['autoRetry'] ?? true,
      maxRetries: json['maxRetries'] ?? 3,
      enableNotifications: json['enableNotifications'] ?? true,
    );
  }

  @override
  List<Object?> get props => [
        intervalHours,
        targetLeagues,
        targetAreas,
        autoRetry,
        maxRetries,
        enableNotifications,
      ];

  @override
  String toString() {
    return 'CrawlerSettings(interval: ${intervalHours}h, leagues: $targetLeagues)';
  }
}

/// 크롤링 진행 상황을 나타내는 불변 클래스
class CrawlingProgress extends Equatable {
  final int currentPage;
  final int totalPages;
  final int processedMatches;
  final int totalMatches;
  final String currentTask;
  final bool isCompleted;
  final int completedTasks;
  final int totalTasks;
  final double progress;
  final int successCount;
  final int errorCount;

  const CrawlingProgress({
    this.currentPage = 0,
    this.totalPages = 0,
    this.processedMatches = 0,
    this.totalMatches = 0,
    this.currentTask = '',
    this.isCompleted = false,
    this.completedTasks = 0,
    this.totalTasks = 0,
    this.progress = 0.0,
    this.successCount = 0,
    this.errorCount = 0,
  });

  CrawlingProgress copyWith({
    int? currentPage,
    int? totalPages,
    int? processedMatches,
    int? totalMatches,
    String? currentTask,
    bool? isCompleted,
    int? completedTasks,
    int? totalTasks,
    double? progress,
    int? successCount,
    int? errorCount,
  }) {
    return CrawlingProgress(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      processedMatches: processedMatches ?? this.processedMatches,
      totalMatches: totalMatches ?? this.totalMatches,
      currentTask: currentTask ?? this.currentTask,
      isCompleted: isCompleted ?? this.isCompleted,
      completedTasks: completedTasks ?? this.completedTasks,
      totalTasks: totalTasks ?? this.totalTasks,
      progress: progress ?? this.progress,
      successCount: successCount ?? this.successCount,
      errorCount: errorCount ?? this.errorCount,
    );
  }

  /// 페이지 진행률 (0.0 ~ 1.0)
  double get pageProgress => totalPages > 0 ? currentPage / totalPages : 0.0;

  /// 매치 진행률 (0.0 ~ 1.0)
  double get matchProgress =>
      totalMatches > 0 ? processedMatches / totalMatches : 0.0;

  /// 전체 진행률 (0.0 ~ 1.0)
  double get overallProgress => (pageProgress + matchProgress) / 2;

  /// 현재 상태 텍스트
  String get currentStatus =>
      isCompleted ? '완료' : (currentTask.isNotEmpty ? currentTask : '진행 중');

  /// 진행률 텍스트
  String get progressText => '${(progress * 100).toStringAsFixed(1)}%';

  /// 메시지 (currentTask와 동일)
  String get message => currentTask;

  @override
  List<Object?> get props => [
        currentPage,
        totalPages,
        processedMatches,
        totalMatches,
        currentTask,
        isCompleted,
        completedTasks,
        totalTasks,
        progress,
        successCount,
        errorCount,
      ];

  @override
  String toString() {
    return 'CrawlingProgress(page: $currentPage/$totalPages, matches: $processedMatches/$totalMatches)';
  }
}
