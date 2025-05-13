import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/core/theme/app_typography.dart';
import 'package:k5_branding_app/domain/entities/match.dart';
import 'package:k5_branding_app/features/match_editor/providers/match_editor_provider.dart';

/// Next match information input section
///
/// Allows users to add information about upcoming matches
class NextMatchSection extends ConsumerStatefulWidget {
  const NextMatchSection({super.key});

  @override
  ConsumerState<NextMatchSection> createState() => _NextMatchSectionState();
}

class _NextMatchSectionState extends ConsumerState<NextMatchSection> {
  late TextEditingController venueController;

  @override
  void initState() {
    super.initState();
    final match = ref.read(matchEditorProvider);
    venueController = TextEditingController(text: match.venueLocation ?? '');
  }

  @override
  void dispose() {
    venueController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update controller if venue location changes externally
    final match = ref.read(matchEditorProvider);
    if (venueController.text != (match.venueLocation ?? '')) {
      venueController.text = match.venueLocation ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchEditorNotifier = ref.read(matchEditorProvider.notifier);
    final match = ref.watch(matchEditorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '다음 경기 정보',
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Date picker - Using a simpler implementation to prevent crashes
        GestureDetector(
          onTap: () => _safeSelectDate(context, matchEditorNotifier, match),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('경기 일자', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        match.matchDateTime != null
                            ? '${match.matchDateTime!.year}년 ${match.matchDateTime!.month}월 ${match.matchDateTime!.day}일'
                            : '날짜를 선택하세요',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Time picker - Using a simpler implementation to prevent crashes
        GestureDetector(
          onTap: () => _safeSelectTime(context, matchEditorNotifier, match),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('경기 시간', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        match.matchDateTime != null
                            ? '${match.matchDateTime!.hour}시 ${match.matchDateTime!.minute}분'
                            : '시간을 선택하세요',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Venue input
        TextField(
          controller: venueController,
          decoration: const InputDecoration(
            labelText: '경기장',
            hintText: '경기장 이름을 입력하세요',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => matchEditorNotifier.updateVenueLocation(value),
        ),
      ],
    );
  }

  /// Shows date picker dialog with error handling
  Future<void> _safeSelectDate(
    BuildContext context,
    MatchEditorNotifier notifier,
    Match match,
  ) async {
    try {
      // 에러 발생 가능성을 줄이기 위해 간단한 인라인 date picker UI 표시
      final now = DateTime.now();
      final initialDate = match.matchDateTime ?? now;
      DateTime? selectedDate;

      await showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '날짜 선택',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: CalendarDatePicker(
                      initialDate: initialDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      onDateChanged: (date) {
                        selectedDate = date;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ).then((confirmed) {
        if (confirmed == true && selectedDate != null && context.mounted) {
          final newDateTime = DateTime(
            selectedDate!.year,
            selectedDate!.month,
            selectedDate!.day,
            match.matchDateTime?.hour ?? 19,
            match.matchDateTime?.minute ?? 0,
          );
          notifier.updateMatchDateTime(newDateTime);
        }
      });
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, '날짜 선택 중 오류가 발생했습니다');
      }
    }
  }

  /// Shows time picker dialog with error handling
  Future<void> _safeSelectTime(
    BuildContext context,
    MatchEditorNotifier notifier,
    Match match,
  ) async {
    try {
      // 커스텀 시간 선택 UI로 대체
      final initialTime =
          match.matchDateTime != null
              ? TimeOfDay(
                hour: match.matchDateTime!.hour,
                minute: match.matchDateTime!.minute,
              )
              : const TimeOfDay(hour: 19, minute: 0);

      int selectedHour = initialTime.hour;
      int selectedMinute = initialTime.minute;

      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '시간 선택',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 시간 선택
                          Column(
                            children: [
                              const Text('시'),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 150,
                                width: 60,
                                child: ListView.builder(
                                  itemCount: 24,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedHour = index;
                                        });
                                      },
                                      child: Container(
                                        height: 40,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color:
                                              selectedHour == index
                                                  ? Colors.blue.withOpacity(0.2)
                                                  : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '$index',
                                          style: TextStyle(
                                            fontWeight:
                                                selectedHour == index
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // 분 선택
                          Column(
                            children: [
                              const Text('분'),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 150,
                                width: 60,
                                child: ListView.builder(
                                  itemCount: 60,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedMinute = index;
                                        });
                                      },
                                      child: Container(
                                        height: 40,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color:
                                              selectedMinute == index
                                                  ? Colors.blue.withOpacity(0.2)
                                                  : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '$index',
                                          style: TextStyle(
                                            fontWeight:
                                                selectedMinute == index
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('취소'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('확인'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ).then((confirmed) {
        if (confirmed == true && context.mounted) {
          final now = DateTime.now();
          final newDateTime = DateTime(
            match.matchDateTime?.year ?? now.year,
            match.matchDateTime?.month ?? now.month,
            match.matchDateTime?.day ?? now.day,
            selectedHour,
            selectedMinute,
          );
          notifier.updateMatchDateTime(newDateTime);
        }
      });
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, '시간 선택 중 오류가 발생했습니다');
      }
    }
  }

  /// Helper to show error message
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
