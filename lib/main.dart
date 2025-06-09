import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:window_size/window_size.dart' as window_size;
import 'package:pomotask_client/api_service.dart' as api_service;
import 'package:pomotask_client/timer_service.dart';

// App 전체에서 사용되는 Data와 객체
late String serverAddress;
late String loggedInUser;
late PomodoroTimer timer;

void main() {
  loadConfig();
  timer = PomodoroTimer(
    focusDuration: Duration(minutes: 25),
    shortBreakDuration: Duration(minutes: 5),
    longBreakDuration: Duration(minutes: 15),
    longBreakInterval: 4,
    onTick: (session, remaining) {
      // setState로 UI 타이머 텍스트·슬라이드바 갱신
    },
    onSessionComplete: (session) {
      // 서버로 기록 전송(API 호출)
    }
  );
  
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

class MainPage extends StatefulWidget
{
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
{
  SessionType _selectedSession = SessionType.focus;
  bool _isRunning = false;

  Duration _focusDuration      = Duration(minutes: 25);
  Duration _shortBreakDuration = Duration(minutes: 5);
  Duration _longBreakDuration  = Duration(minutes: 15);

  String _formatDuration(Duration d)
  {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context)
  {
    const Color backgroundColor       = Color(0xFFF3E5F5);
    const Color activeButtonColor     = Color(0xFF7E57C2);
    final   Color inactiveButtonColor = Colors.grey.shade400;

    final Duration currentDuration =
    _selectedSession == SessionType.focus
        ? _focusDuration
        : _selectedSession == SessionType.shortBreak
            ? _shortBreakDuration
            : _longBreakDuration;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          // 좌측 고정 사이드바 공간
          Container(
            width: 350,
            color: Colors.transparent,
          ),

          // 우측 메인 컨텐츠
          Expanded(
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Settings 버튼 (배경 흰색, 글자 보라색)
                      Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: activeButtonColor,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            onPressed: ()
                            {
                              // TODO: 설정 팝업 호출
                            },
                            child: const Text('Settings'),
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Session 선택 버튼 (폭 고정)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSessionButton(
                            label: 'Focus',
                            isActive: _selectedSession == SessionType.focus,
                            activeColor: activeButtonColor,
                            inactiveColor: inactiveButtonColor,
                            onTap: ()
                            {
                              setState(() {
                                _selectedSession = SessionType.focus;
                              });
                            },
                          ),
                          const SizedBox(width: 13),
                          _buildSessionButton(
                            label: 'Short Break',
                            isActive:
                                _selectedSession == SessionType.shortBreak,
                            activeColor: activeButtonColor,
                            inactiveColor: inactiveButtonColor,
                            onTap: ()
                            {
                              setState(() {
                                _selectedSession = SessionType.shortBreak;
                              });
                            },
                          ),
                          const SizedBox(width: 13),
                          _buildSessionButton(
                            label: 'Long Break',
                            isActive:
                                _selectedSession == SessionType.longBreak,
                            activeColor: activeButtonColor,
                            inactiveColor: inactiveButtonColor,
                            onTap: ()
                            {
                              setState(() {
                                _selectedSession = SessionType.longBreak;
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // 타이머 텍스트
                      Text(
                        _formatDuration(currentDuration),
                        style: const TextStyle(
                          fontSize: 96,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 진행도 슬라이드 바
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor: Colors.white,
                          value: 1.0, // TODO: 진행도에 맞춰 value 변경
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Start / Pause 버튼
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeButtonColor,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 48, vertical: 16),
                        ),
                        icon: Icon(
                          _isRunning ? Icons.pause : Icons.play_arrow,
                          size: 28,
                        ),
                        label: Text(
                          _isRunning ? 'Pause' : 'Start',
                          style: const TextStyle(fontSize: 20),
                        ),
                        onPressed: ()
                        {
                          setState(() {
                            _isRunning = !_isRunning;
                          });
                          // TODO: 타이머 start/pause 로직
                        },
                      ),

                      const SizedBox(height: 64),

                      // In Focus 제목
                      const Text(
                        'In Focus',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // In Focus 리스트 (외형만)
                      _buildInFocusItem('Task 1'),
                      _buildInFocusItem('Task 2'),

                      // 새 항목 추가 버튼
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: IconButton(
                              icon: const Icon(Icons.add, size: 32),
                              onPressed: ()
                              {
                                // TODO: 새 In Focus 항목 추가
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

  // 세션 버튼 빌더 (폭 고정, 선택 시 글자 흰색)
  Widget _buildSessionButton({
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
  })
  {
    return SizedBox(
      width: 120, // Short Break 버튼 폭에 맞춤
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? activeColor : inactiveColor,
          foregroundColor: isActive ? Colors.white : Colors.black87,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }

  // In Focus 항목 빌더 (변경 없음)
  Widget _buildInFocusItem(String title)
  {
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
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () { /* TODO */ },
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () { /* TODO */ },
            ),
          ],
        ),
      ),
    );
  }
}
