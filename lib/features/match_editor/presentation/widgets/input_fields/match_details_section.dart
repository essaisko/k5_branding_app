import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/core/theme/app_typography.dart';
import 'package:k5_branding_app/domain/entities/match.dart';
import 'package:k5_branding_app/features/match_editor/providers/match_editor_provider.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/input_fields/league_name_section.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// 경기 세부 정보 입력 섹션 - 컴팩트 버전
///
/// 경기 날짜, 시간, 경기장 등의 세부 정보를 입력할 수 있는 위젯
class MatchDetailsSection extends ConsumerStatefulWidget {
  const MatchDetailsSection({super.key});

  @override
  ConsumerState<MatchDetailsSection> createState() =>
      _MatchDetailsSectionState();
}

class _MatchDetailsSectionState extends ConsumerState<MatchDetailsSection> {
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
        // 리그 선택 섹션 추가
        const LeagueNameSection(),
        const SizedBox(height: 16),

        // 헤더와 경기장 입력을 같은 줄에 배치
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Text(
                    '경기 세부 정보',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 경기장 정보 (같은 줄에 배치)
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: venueController,
                  decoration: const InputDecoration(
                    labelText: '경기장',
                    hintText: '경기장을 입력해주세요',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.location_on, size: 16),
                    prefixIconConstraints: BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (value) {
                    matchEditorNotifier.updateVenueLocation(value);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 날짜 및 시간 선택을 한 줄에 배치
        Row(
          children: [
            // 날짜 선택 버튼
            Expanded(
              child: _buildCompactDateButton(
                context,
                match,
                matchEditorNotifier,
              ),
            ),

            const SizedBox(width: 8),

            // 시간 선택 버튼
            Expanded(
              child: _buildCompactTimeButton(
                context,
                match,
                matchEditorNotifier,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 날짜 선택 컴팩트 버튼
  Widget _buildCompactDateButton(
    BuildContext context,
    Match match,
    MatchEditorNotifier matchEditorNotifier,
  ) {
    return InkWell(
      onTap: () => _selectDate(context, match, matchEditorNotifier),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                match.matchDateTime != null
                    ? '${match.matchDateTime!.year}.${match.matchDateTime!.month.toString().padLeft(2, '0')}.${match.matchDateTime!.day.toString().padLeft(2, '0')}'
                    : '경기 일자를 입력해주세요',
                style: TextStyle(
                  fontSize: 13,
                  color: match.matchDateTime != null
                      ? Colors.black87
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 시간 선택 컴팩트 버튼
  Widget _buildCompactTimeButton(
    BuildContext context,
    Match match,
    MatchEditorNotifier matchEditorNotifier,
  ) {
    return InkWell(
      onTap: () => _selectTime(context, match, matchEditorNotifier),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                match.matchDateTime != null
                    ? '${match.matchDateTime!.hour.toString().padLeft(2, '0')}:${match.matchDateTime!.minute.toString().padLeft(2, '0')}'
                    : '시간을 입력해주세요',
                style: TextStyle(
                  fontSize: 13,
                  color: match.matchDateTime != null
                      ? Colors.black87
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 날짜 선택 다이얼로그
  Future<void> _selectDate(
    BuildContext context,
    Match match,
    MatchEditorNotifier matchEditorNotifier,
  ) async {
    try {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: match.matchDateTime ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        locale: const Locale('ko', 'KR'), // 한국어 로케일 설정
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: Colors.blue, // 메인 컬러
                  ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black, // 버튼 텍스트 색상
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedDate != null) {
        final currentTime = match.matchDateTime ?? DateTime.now();
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          currentTime.hour,
          currentTime.minute,
        );
        matchEditorNotifier.updateMatchDateTime(newDateTime);
      }
    } catch (e) {
      print('날짜 선택 오류: $e');
    }
  }

  // 시간 선택 다이얼로그
  Future<void> _selectTime(
    BuildContext context,
    Match match,
    MatchEditorNotifier matchEditorNotifier,
  ) async {
    try {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: match.matchDateTime != null
            ? TimeOfDay.fromDateTime(match.matchDateTime!)
            : TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                dayPeriodTextColor: Colors.blue,
                hourMinuteTextColor: Colors.blue,
                dialHandColor: Colors.blue,
                dialBackgroundColor: Colors.blue.shade50,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue, // 버튼 텍스트 색상
                ),
              ),
            ),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                alwaysUse24HourFormat: false, // 오전/오후 형식 사용
              ),
              child: child!,
            ),
          );
        },
      );

      if (pickedTime != null) {
        final currentDate = match.matchDateTime ?? DateTime.now();
        final newDateTime = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        matchEditorNotifier.updateMatchDateTime(newDateTime);
      }
    } catch (e) {
      print('시간 선택 오류: $e');
    }
  }
}
