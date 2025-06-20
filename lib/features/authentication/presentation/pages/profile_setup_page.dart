import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:chukshin_app/presentation/navigation/routes.dart';
import 'package:chukshin_app/features/authentication/presentation/providers/auth_provider.dart';

/// 휴대전화번호 로그인 후 추가 정보 입력 페이지
///
/// 단계별로 정보를 수집합니다:
/// 1. 이름 입력
/// 2. 생년월일 선택
/// 3. 거주지역 선택
/// 4. 소속팀 선택 (필수)
/// 5. 포지션 선택 (필수)
class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _residenceController = TextEditingController();

  // 현재 단계 (0: 이름, 1: 생년월일, 2: 거주지역, 3: 소속팀, 4: 포지션, 5: 완료)
  int _currentStep = 0;

  // 생년월일 관련
  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedDay;
  DateTime? get _selectedBirthDate {
    if (_selectedYear != null &&
        _selectedMonth != null &&
        _selectedDay != null) {
      return DateTime(_selectedYear!, _selectedMonth!, _selectedDay!);
    }
    return null;
  }

  String? _selectedResidenceArea;
  List<String> _selectedAffiliatedTeams = [];
  String? _selectedPosition;
  bool _isLocationLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // 소속팀 목록 (기타 항목을 최상단에 추가)
  final List<String> _teams = [
    '기타',
    '한마음FC',
    '한FC',
    '수우FC',
  ];

  // 간소화된 포지션 목록 (기타 항목을 최상단에 추가)
  final List<Map<String, String>> _positions = [
    {'name': '기타', 'description': '위에 없는 포지션이거나 해당사항 없음'},
    {'name': '골키퍼', 'description': '골문을 지키는 포지션'},
    {'name': '센터백', 'description': '중앙 수비수'},
    {'name': '풀백', 'description': '좌우 측면 수비수'},
    {'name': '수비형 미드필더', 'description': '수비를 도와주는 미드필더'},
    {'name': '중앙 미드필더', 'description': '중앙에서 게임을 조율'},
    {'name': '공격형 미드필더', 'description': '공격을 주도하는 미드필더'},
    {'name': '좌측 미드필더', 'description': '왼쪽 측면 미드필더'},
    {'name': '우측 미드필더', 'description': '오른쪽 측면 미드필더'},
    {'name': '윙어', 'description': '측면에서 돌파하는 선수'},
    {'name': '스트라이커', 'description': '골을 넣는 공격수'},
    {'name': '세컨드 스트라이커', 'description': '스트라이커를 도와주는 공격수'},
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _residenceController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 5) {
      setState(() {
        _currentStep++;
      });
      _fadeController.reset();
      _fadeController.forward();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _fadeController.reset();
      _fadeController.forward();
    }
  }

  /// GPS를 통해 현재 위치를 가져오고 주소로 변환
  Future<void> _getCurrentLocation() async {
    setState(() => _isLocationLoading = true);

    try {
      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        setState(() => _isLocationLoading = false);
        return;
      }

      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDeniedDialog();
          setState(() => _isLocationLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDeniedForeverDialog();
        setState(() => _isLocationLoading = false);
        return;
      }

      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 좌표를 주소로 변환
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';

        // 한국 주소 형식으로 구성
        if (place.administrativeArea != null) {
          address += '${place.administrativeArea} ';
        }
        if (place.locality != null) {
          address += '${place.locality} ';
        }
        if (place.subLocality != null) {
          address += '${place.subLocality} ';
        }
        if (place.thoroughfare != null) {
          address += place.thoroughfare!;
        }

        setState(() {
          _selectedResidenceArea = address.trim();
          _residenceController.text = address.trim();
          _isLocationLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('현재 위치가 감지되었습니다: $address'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLocationLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('위치를 가져오는데 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('위치 서비스 비활성화', style: TextStyle(fontSize: 20)),
          content: const Text('거주지역 자동 감지를 위해 위치 서비스를 활성화해주세요.',
              style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('나중에', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
              child: const Text('설정으로 이동', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('위치 권한 필요', style: TextStyle(fontSize: 20)),
          content: const Text('거주지역 자동 감지를 위해 위치 권한이 필요합니다.',
              style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('나중에', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _getCurrentLocation();
              },
              child: const Text('다시 시도', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('위치 권한 거부됨', style: TextStyle(fontSize: 20)),
          content: const Text('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.',
              style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('나중에', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
              child: const Text('설정으로 이동', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  void _showManualResidenceInput() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController manualController = TextEditingController();
        return AlertDialog(
          title: const Text('거주지역 직접 입력', style: TextStyle(fontSize: 20)),
          content: TextField(
            controller: manualController,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              labelText: '거주지역',
              labelStyle: const TextStyle(fontSize: 16),
              hintText: '예: 서울 강남구 역삼동',
              hintStyle:
                  TextStyle(fontSize: 16, color: Colors.grey.withOpacity(0.6)),
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () {
                if (manualController.text.trim().isNotEmpty) {
                  setState(() {
                    _selectedResidenceArea = manualController.text.trim();
                    _residenceController.text = manualController.text.trim();
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('확인', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleComplete() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이름을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('생년월일을 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedResidenceArea == null || _selectedResidenceArea!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('거주지역을 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedAffiliatedTeams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('소속팀을 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('포지션을 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ref.read(authProvider.notifier).updateUserProfile(
            name: _nameController.text.trim(),
            birthDate: _selectedBirthDate!,
            residenceArea: _selectedResidenceArea!,
            affiliatedTeams: _selectedAffiliatedTeams,
            position: _selectedPosition,
            isProfileSetupComplete: true,
          );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필 설정이 완료되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 저장에 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이름을 입력해주세요';
    }
    if (value.trim().length < 2) {
      return '이름은 2글자 이상 입력해주세요';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor.withOpacity(0.1),
              Colors.white,
              theme.primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // 진행 상황 표시
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        '추가 정보 입력',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index <= _currentStep
                                  ? theme.primaryColor
                                  : Colors.grey[300],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_currentStep + 1} / 6 단계',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // 단계별 콘텐츠
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildStepContent(),
                  ),
                ),

                // 하단 버튼들
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousStep,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                            child: const Text('이전'),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 16),
                      Expanded(
                        flex: _currentStep == 0 ? 1 : 2,
                        child: ElevatedButton(
                          onPressed: _getNextButtonAction(),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          child: Text(_getNextButtonText()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildBirthDateStep();
      case 2:
        return _buildResidenceStep();
      case 3:
        return _buildTeamStep();
      case 4:
        return _buildPositionStep();
      case 5:
        return _buildCompleteStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Center(
          child: Icon(
            Icons.person,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '이름을 입력해주세요',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '실명을 정확히 입력해주세요',
          style: TextStyle(
            color: Colors.grey.withOpacity(0.7),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameController,
            validator: _validateName,
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 20),
            decoration: InputDecoration(
              hintText: '홍길동',
              hintStyle:
                  TextStyle(fontSize: 18, color: Colors.grey.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.person, size: 28),
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            ),
            onFieldSubmitted: (_) {
              if (_formKey.currentState!.validate()) {
                _nextStep();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBirthDateStep() {
    // 년도 목록 (1950년부터 현재년도까지)
    final currentYear = DateTime.now().year;
    final years =
        List.generate(currentYear - 1949, (index) => currentYear - index);

    // 월 목록
    final months = List.generate(12, (index) => index + 1);

    // 일 목록 (선택된 년월에 따라 동적으로 계산)
    List<int> getDaysInMonth() {
      if (_selectedYear == null || _selectedMonth == null) {
        return List.generate(31, (index) => index + 1);
      }
      final daysInMonth = DateTime(_selectedYear!, _selectedMonth! + 1, 0).day;
      return List.generate(daysInMonth, (index) => index + 1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Center(
          child: Icon(
            Icons.cake,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '생년월일을 선택해주세요',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '정확한 나이 확인을 위해 필요합니다',
          style: TextStyle(
            color: Colors.grey.withOpacity(0.7),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        // 년/월/일 드롭다운 - 부드러운 디자인
        Row(
          children: [
            // 년도 선택
            Expanded(
              flex: 2,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _selectedYear != null
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300]!,
                      width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    hint: Text(
                      '년도',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: _selectedYear != null
                          ? Theme.of(context).primaryColor
                          : Colors.grey[400],
                      size: 28,
                    ),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    menuMaxHeight: 300,
                    items: years.map((year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '$year년',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value;
                        // 년도가 변경되면 일자를 재검증
                        if (_selectedMonth != null) {
                          final daysInMonth = getDaysInMonth();
                          if (_selectedDay != null &&
                              _selectedDay! > daysInMonth.length) {
                            _selectedDay = null;
                          }
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 월 선택
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _selectedMonth != null
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300]!,
                      width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    hint: Text(
                      '월',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: _selectedMonth != null
                          ? Theme.of(context).primaryColor
                          : Colors.grey[400],
                      size: 28,
                    ),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    menuMaxHeight: 300,
                    items: months.map((month) {
                      return DropdownMenuItem<int>(
                        value: month,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '$month월',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value;
                        // 월이 변경되면 일자를 재검증
                        if (_selectedYear != null) {
                          final daysInMonth = getDaysInMonth();
                          if (_selectedDay != null &&
                              _selectedDay! > daysInMonth.length) {
                            _selectedDay = null;
                          }
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 일 선택
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _selectedDay != null
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300]!,
                      width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedDay,
                    hint: Text(
                      '일',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: _selectedDay != null
                          ? Theme.of(context).primaryColor
                          : Colors.grey[400],
                      size: 28,
                    ),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    menuMaxHeight: 300,
                    items: getDaysInMonth().map((day) {
                      return DropdownMenuItem<int>(
                        value: day,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '$day일',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDay = value;
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 선택된 날짜 표시 - 개선된 디자인
        if (_selectedBirthDate != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '선택된 생년월일',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedBirthDate!.year}년 ${_selectedBirthDate!.month}월 ${_selectedBirthDate!.day}일',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildResidenceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Center(
          child: Icon(
            Icons.location_on,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '거주지역을 선택해주세요',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'GPS로 자동 감지하거나 직접 입력하세요',
          style: TextStyle(
            color: Colors.grey.withOpacity(0.7),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        if (_selectedResidenceArea != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).primaryColor),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Theme.of(context).primaryColor, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _selectedResidenceArea!,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLocationLoading ? null : _getCurrentLocation,
                icon: _isLocationLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 24),
                label: Text(
                  _isLocationLoading ? '위치 찾는 중...' : '현재 위치',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showManualResidenceInput,
                icon: const Icon(Icons.edit, size: 24),
                label: const Text(
                  '직접 입력',
                  style: TextStyle(fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Center(
          child: Icon(
            Icons.groups,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '소속팀을 선택해주세요',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '필수 선택사항입니다. 해당없으면 기타를 선택하세요',
          style: TextStyle(
            color: Colors.grey.withOpacity(0.7),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _teams.map((team) {
            final isSelected = _selectedAffiliatedTeams.contains(team);
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 72) / 2, // 2열로 배치
              child: FilterChip(
                label: Text(
                  team,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedAffiliatedTeams.add(team);
                    } else {
                      _selectedAffiliatedTeams.remove(team);
                    }
                  });
                },
                selectedColor: Theme.of(context).primaryColor,
                backgroundColor: Colors.grey[100],
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: Colors.orange[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '소속팀 선택은 필수입니다. 해당하는 팀이 없으면 "기타"를 선택해주세요.',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPositionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Center(
          child: Icon(
            Icons.sports_soccer,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '포지션을 선택해주세요',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '필수 선택사항입니다. 해당없으면 기타를 선택하세요',
          style: TextStyle(
            color: Colors.grey.withOpacity(0.7),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        // 스크롤 가능 힌트 텍스트
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swipe_vertical, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                '위아래로 스크롤하여 모든 포지션을 확인하세요',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 포지션 선택 영역 (높이 증가)
        Container(
          height: 450, // 높이를 고정하여 더 넓게 만듦
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              // 스크롤 인디케이터 상단
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.keyboard_arrow_up, color: Colors.grey[600]),
                    Text(
                      '위로 스크롤',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _positions.length,
                  itemBuilder: (context, index) {
                    final position = _positions[index];
                    final isSelected = _selectedPosition == position['name'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedPosition = position['name'];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.black,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      position['name']!,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      position['description']!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isSelected
                                            ? Colors.white.withOpacity(0.9)
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 스크롤 인디케이터 하단
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                    Text(
                      '아래로 스크롤',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: Colors.orange[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '포지션 선택은 필수입니다. 해당하는 포지션이 없으면 "기타"를 선택해주세요.',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Center(
          child: Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '정보 입력이 완료되었습니다!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '입력하신 정보를 확인해주세요',
          style: TextStyle(
            color: Colors.grey.withOpacity(0.7),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('이름', _nameController.text.trim()),
              _buildInfoRow(
                  '생년월일',
                  _selectedBirthDate != null
                      ? '${_selectedBirthDate!.year}년 ${_selectedBirthDate!.month}월 ${_selectedBirthDate!.day}일'
                      : '미입력'),
              _buildInfoRow('거주지역', _selectedResidenceArea ?? '미입력'),
              _buildInfoRow(
                  '소속팀',
                  _selectedAffiliatedTeams.isEmpty
                      ? '선택하지 않음'
                      : _selectedAffiliatedTeams.join(', ')),
              _buildInfoRow('포지션', _selectedPosition ?? '선택하지 않음'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback? _getNextButtonAction() {
    switch (_currentStep) {
      case 0:
        return () {
          if (_formKey.currentState!.validate()) {
            _nextStep();
          }
        };
      case 1:
        return _selectedBirthDate != null ? _nextStep : null;
      case 2:
        return _selectedResidenceArea != null ? _nextStep : null;
      case 3:
        return _selectedAffiliatedTeams.isNotEmpty ? _nextStep : null; // 필수 변경
      case 4:
        return _selectedPosition != null ? _nextStep : null; // 필수 변경
      case 5:
        return _handleComplete;
      default:
        return null;
    }
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 0:
      case 1:
      case 2:
      case 3:
      case 4:
        return '다음';
      case 5:
        return '완료';
      default:
        return '다음';
    }
  }
}
