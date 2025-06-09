import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:window_size/window_size.dart' as window_size;
import 'package:pomotask_client/api_service.dart' as api_service;
import 'package:pomotask_client/timer_service.dart';

// App 전체에서 사용되는 Data와 객체
late String serverAddress;
late String loggedInUser;

void main() {
  loadConfig();

  WidgetsFlutterBinding.ensureInitialized();
  // 데스크톱 환경에서 창 최소 크기 설정(800×600)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
  {
    window_size.setWindowMinSize(const Size(800, 600));
  }

  runApp(const MyApp());
}

void loadConfig()
{
  final file = File('config/config.json');
  final content = file.readAsStringSync();
  final jsonData = jsonDecode(content);
  serverAddress = jsonData['serverAddress'];
}

class MyApp extends StatelessWidget
{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro Login',
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _idController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() 
  {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() 
  {
    final id = _idController.text;
    final password = _passwordController.text;

    debugPrint('[LOGIN] 아이디: $id, 비밀번호: $password'); // 터미널에 입력값 출력
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MainPage()));
  }

  void _handleSignUp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpPage()),
    );
  }

  @override
    Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 800,
              minHeight: 600,
            ),
            child: Center(
              child: SizedBox(
                width: 600,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'PomoTaskManager에 오신 것을 환영합니다.',
                        style: TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _idController,
                        decoration: InputDecoration(
                          labelText: '아이디',
                          prefixIcon: Icon(Icons.perm_identity),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: '비밀번호',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleLogin,
                          child: const Text('로그인'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _handleSignUp(context),
                          child: const Text('회원가입'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SignUpPage extends StatefulWidget
{
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
{
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose()
  {
    _idController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleSignUp() async
  {
    final id = _idController.text;
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    // 비밀번호와 확인이 다르면 아무 동작 없이 그대로
    if (password != confirm)
    {
      debugPrint('⚠️ 비밀번호와 비밀번호 확인이 일치하지 않습니다.');
      return;
    }

    // 일치하면 debugPrint 후 이전 화면으로 팝
    final success = await api_service.signUp(serverAddress, id, password);
    if (success)
    {
      debugPrint('[SIGNIN] 아이디: $id, 비밀번호: $password');
      Navigator.pop(context);
    }
    else
    {
      debugPrint('⚠️ 회원가입 실패');
    }
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: Center(
        child: SizedBox(
          width: 600,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: '아이디',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmController,
                  decoration: const InputDecoration(
                    labelText: '비밀번호 확인',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleSignUp,
                    child: const Text('회원가입'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late PomodoroTimer _pomoTimer;

  // UI에 표시할 현재 세션, 남은 시간, 그리고 타이머 상태
  late SessionType _uiSession;
  late Duration    _uiRemaining;
  late TimerState  _uiTimerState;

  @override
  void initState() {
    super.initState();

    // 1) PomodoroTimer 인스턴스 생성 & 콜백 바인딩
    _pomoTimer = PomodoroTimer(
      focusDuration:      const Duration(minutes: 1),
      shortBreakDuration: const Duration(minutes: 1),
      longBreakDuration:  const Duration(minutes: 1),
      longBreakInterval:  4,
      onTick: (session, remaining, state) {
        setState(() {
          _uiSession    = session;
          _uiRemaining  = remaining;
          _uiTimerState = state;
        });
      },
      onSessionComplete: (session) {
        // TODO: 서버에 완료 내역 전송
      },
    );

    // 2) 초기 UI state 세팅
    _uiSession    = _pomoTimer.currentSession;
    _uiRemaining  = _pomoTimer.remaining;
    _uiTimerState = _pomoTimer.state;
  }

  @override
  void dispose() {
    // 타이머가 돌고 있다면 해제
    _pomoTimer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return '$m:$s';
  }

  int _totalSecondsFor(SessionType s) {
    switch (s) {
      case SessionType.focus:
        return _pomoTimer.focusDuration.inSeconds;
      case SessionType.shortBreak:
        return _pomoTimer.shortBreakDuration.inSeconds;
      case SessionType.longBreak:
        return _pomoTimer.longBreakDuration.inSeconds;
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgcolor        = Color(0xFFF3E5F5);
    const activeColor    = Color(0xFF7E57C2);
    final inactiveColor  = Colors.grey.shade400;

    final totalSec = _totalSecondsFor(_uiSession);
    final progress = _uiRemaining.inSeconds / totalSec;

    return Scaffold(
      backgroundColor: bgcolor,
      body: Row(
        children: [
          // 고정된 사이드바 공간
          Container(width: 350, color: Colors.transparent),

          // 메인 컨텐츠
          Expanded(
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Settings
                      Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: activeColor,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            onPressed: () {
                              // TODO: 설정 팝업
                            },
                            child: const Text('Settings'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // 세션 버튼
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: SessionType.values.map((type) {
                          final label = {
                            SessionType.focus: 'Focus',
                            SessionType.shortBreak: 'Short Break',
                            SessionType.longBreak: 'Long Break',
                          }[type]!;
                          final isActive = _uiSession == type;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: SizedBox(
                              width: 120,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isActive ? activeColor : inactiveColor,
                                  foregroundColor:
                                      isActive ? Colors.white : Colors.black87,
                                  shape: const StadiumBorder(),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  _pomoTimer.skipSessionByButton(type);
                                },
                                child: Text(label),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // 타이머 텍스트
                      Text(
                        _formatDuration(_uiRemaining),
                        style: const TextStyle(
                          fontSize: 96,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 진행도 바
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor: Colors.white,
                          value: progress.clamp(0.0, 1.0),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Start / Pause / Resume 버튼
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeColor,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 48, vertical: 16),
                        ),
                        icon: Icon(
                          _uiTimerState == TimerState.running
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 28,
                        ),
                        label: Text(
                          _uiTimerState == TimerState.running
                              ? 'Pause'
                              : (_uiTimerState == TimerState.paused
                                  ? 'Resume'
                                  : 'Start'),
                          style: const TextStyle(fontSize: 20),
                        ),
                        onPressed: () {
                          switch (_pomoTimer.state) {
                            case TimerState.idle:
                              _pomoTimer.start();
                              setState(() {
                                _uiTimerState = TimerState.running;
                              });
                              break;
                            case TimerState.running:
                              _pomoTimer.pause();
                              setState(() {
                                _uiTimerState = TimerState.paused;
                              });
                              break;
                            case TimerState.paused:
                              _pomoTimer.resume();
                              setState(() {
                                _uiTimerState = TimerState.running;
                              });
                              break;
                          }
                        },
                      ),

                      const SizedBox(height: 64),
                      const Text(
                        'In Focus',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // In Focus 리스트 외형
                      _buildInFocusItem('Task 1'),
                      _buildInFocusItem('Task 2'),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: IconButton(
                              icon: const Icon(Icons.add, size: 32),
                              onPressed: () {
                                // TODO: 항목 추가
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInFocusItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFE1BEE7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.check_circle, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
            IconButton(icon: const Icon(Icons.close), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}