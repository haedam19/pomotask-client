import 'package:flutter/material.dart';
import 'package:pomotask_client/main.dart';
import 'package:pomotask_client/timer_service.dart';
import 'package:pomotask_client/api_service.dart' as api_service;

class MainPage extends StatefulWidget
{
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
{
  late PomodoroTimer _pomoTimer;
  late SessionType  _uiSession;
  late Duration     _uiRemaining;
  late TimerState   _uiTimerState;

  @override
  void initState()
  {
    super.initState();

    _pomoTimer = PomodoroTimer(
      focusDuration:      const Duration(minutes: 1),
      shortBreakDuration: const Duration(minutes: 1),
      longBreakDuration:  const Duration(minutes: 1),
      longBreakInterval:  4,
      onTick: (session, remaining, state)
      {
        setState(()
        {
          _uiSession    = session;
          _uiRemaining  = remaining;
          _uiTimerState = state;
        });
      },
      onSessionComplete: (session) async
      {
        if (session == SessionType.focus)
        {
          final success = await api_service.recordSession(
            serverAddress: serverAddress,
            username: loggedInUser,
            sessionType: session.name,
            // 통계를 위해 시작 시간은 현재 시간에서 세션 시간을 뺀 값이라고 추정
            startTime: DateTime.now().subtract(_pomoTimer.focusDuration), 
            endTime: DateTime.now()
          );

          if (success)
          {
            debugPrint('[SESSION COMPLETE] $loggedInUser completed a $session session. '
              '(${_pomoTimer.focusDuration.inMinutes} minutes)');
          }
          else
          {
            debugPrint('⚠️ Failed to record session for $loggedInUser');
          }
        }
      },
    );

    _uiSession    = _pomoTimer.currentSession;
    _uiRemaining  = _pomoTimer.remaining;
    _uiTimerState = _pomoTimer.state;
  }

  @override
  void dispose()
  {
    _pomoTimer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d)
  {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return '$m:$s';
  }

  int _totalSecondsFor(SessionType s)
  {
    switch (s)
    {
      case SessionType.focus:
      {
        return _pomoTimer.focusDuration.inSeconds;
      }
      case SessionType.shortBreak:
      {
        return _pomoTimer.shortBreakDuration.inSeconds;
      }
      case SessionType.longBreak:
      {
        return _pomoTimer.longBreakDuration.inSeconds;
      }
    }
  }

  @override
  Widget build(BuildContext context)
  {
    const bgcolor       = Color(0xFFF3E5F5);
    const activeColor   = Color(0xFF7E57C2);
    final inactiveColor = Colors.grey.shade400;

    final totalSec = _totalSecondsFor(_uiSession);
    final progress = _uiRemaining.inSeconds / totalSec;

    return Scaffold(
      backgroundColor: bgcolor,
      body: Row(
        children: [
          Sidebar(
            username: loggedInUser,
            onLogout: ()
            {
              // TODO: 로그아웃 처리
            },
            onSelectPomodoro: ()
            {
              // TODO: Pomodoro로 이동
            },
            onSelectInFocus: ()
            {
              // TODO: In Focus로 이동
            },
            onSelectTaskGroup: (name)
            {
              // TODO: Task Group 페이지 이동
            },
          ),

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
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            onPressed: ()
                            {
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
                          final label =
                          {
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
                                  backgroundColor: isActive ? activeColor : inactiveColor,
                                  foregroundColor: isActive ? Colors.white : Colors.black87,
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                ),
                                onPressed: ()
                                {
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
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        ),
                        icon: Icon(
                          _uiTimerState == TimerState.running ? Icons.pause : Icons.play_arrow,
                          size: 28,
                        ),
                        label: Text(
                          _uiTimerState == TimerState.running
                          ? 'Pause'
                          : (_uiTimerState == TimerState.paused ? 'Resume' : 'Start'),
                          style: const TextStyle(fontSize: 20),
                        ),
                        onPressed: ()
                        {
                          switch (_pomoTimer.state)
                          {
                            case TimerState.idle:
                            {
                              _pomoTimer.start();
                              setState(()
                              {
                                _uiTimerState = TimerState.running;
                              });
                              break;
                            }
                            case TimerState.running:
                            {
                              _pomoTimer.pause();
                              setState(()
                              {
                                _uiTimerState = TimerState.paused;
                              });
                              break;
                            }
                            case TimerState.paused:
                            {
                              _pomoTimer.resume();
                              setState(()
                              {
                                _uiTimerState = TimerState.running;
                              });
                              break;
                            }
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
                              onPressed: ()
                              {
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
            IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
            IconButton(icon: const Icon(Icons.close), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

class Sidebar extends StatefulWidget {
  final String            username;
  final VoidCallback      onLogout;
  final VoidCallback      onSelectPomodoro;
  final VoidCallback      onSelectInFocus;
  final ValueChanged<int> onSelectTaskGroup;

  const Sidebar({
    Key? key,
    required this.username,
    required this.onLogout,
    required this.onSelectPomodoro,
    required this.onSelectInFocus,
    required this.onSelectTaskGroup,
  }) : super(key: key);

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  List<Map<String, dynamic>> _taskLists = [];
  bool _loading = true; // 서버로부터 Task Group 가져오는 중
  bool _isAdding  = false; // 새 Task Group 추가 중
  final TextEditingController _newNameController = TextEditingController(); // 새 Task Group 이름 입력

  @override
  void initState() {
    super.initState();
    _fetchTaskLists();
  }

  Future<void> _fetchTaskLists() async {
    final lists = await api_service.fetchUserTaskLists(
      serverAddress, widget.username);
    setState(() {
      _taskLists = lists;
      _loading = false;
    });
  }

  Future<void> _createAndRefresh(String name) async {
    // 서버에 새 Task Group 생성
    await api_service.createTaskList(
      server: serverAddress,
      username: widget.username,
      title: name);
    // 다시 목록 동기화
    await _fetchTaskLists();
    // 추가 모드 종료
    setState(() {
      _isAdding = false;
      _newNameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFFBF7FD);
    const iconColor       = Color(0xFF7E57C2);
    const textColor       = Colors.black87;

    // Task Group 리스트 섹션
    Widget groupSection = _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _taskLists.length,
            itemBuilder: (context, idx) {
              final item = _taskLists[idx];
              return ListTile(
                leading: const Icon(Icons.folder, color: textColor),
                horizontalTitleGap: 10,
                title: Text(
                  item['name'],
                  style: const TextStyle(fontSize: 14, color: textColor),
                ),
                onTap: () => widget.onSelectTaskGroup(item['id']),
              );
            },
          );

    // 새 Task Group 추가 버튼 또는 입력창
    Widget addButtonOrField = _isAdding
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: TextField(
              controller: _newNameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '새 Task Group 이름 입력',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
              style: const TextStyle(fontSize: 14, color: textColor),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _createAndRefresh(value.trim());
                } else {
                  setState(() => _isAdding = false);
                }
              },
            ),
          )
        : GestureDetector(
            onTap: () => setState(() => _isAdding = true),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.add, size: 24, color: iconColor),
              ),
            ),
          );

    return Container(
      width: 350,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 상단: 사용자 정보 + 로그아웃
          Row(
            children: [
              Icon(Icons.account_circle, size: 40, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.username,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout),
                color: iconColor,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── 네비게이션: Pomodoro
          ListTile(
            leading: const Icon(Icons.timer),
            horizontalTitleGap: 10,
            title: const Text(
              'Pomodoro',
              style: TextStyle(fontSize: 14),
            ),
            onTap: widget.onSelectPomodoro,
          ),

          // ── 네비게이션: In Focus
          ListTile(
            leading: const Icon(Icons.list),
            horizontalTitleGap: 10,
            title: const Text(
              'In Focus',
              style: TextStyle(fontSize: 14),
            ),
            onTap: widget.onSelectInFocus,
          ),

          const Divider(),

          // ── Task Group 헤더
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Task Group',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),

          // ── Task Group 리스트
          Expanded(child: groupSection),

          // ── 새 Task Group 추가
          addButtonOrField,
        ],
      ),
    );
  }

}