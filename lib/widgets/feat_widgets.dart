import 'package:flutter/material.dart';
import 'package:pomotask_client/main.dart';
import 'package:pomotask_client/timer_service.dart';


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

  final List<String> _taskGroups = [
    'Full Stack Service Programming',
    'Game Graphic Programming',
    'Game Interactive Technology',
  ];

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
      onSessionComplete: (session)
      {
        // TODO: 서버에 완료 내역 전송
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
            taskGroups: _taskGroups,
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

class Sidebar extends StatelessWidget
{
  final String             username;
  final List<String>       taskGroups;
  final VoidCallback       onLogout;
  final VoidCallback       onSelectPomodoro;
  final VoidCallback       onSelectInFocus;
  final ValueChanged<String> onSelectTaskGroup;

  const Sidebar(
  {
    Key? key,
    required this.username,
    required this.taskGroups,
    required this.onLogout,
    required this.onSelectPomodoro,
    required this.onSelectInFocus,
    required this.onSelectTaskGroup,
  }) : super(key: key);

  @override
  Widget build(BuildContext context)
  {
    const backgroundColor = Color(0xFFFBF7FD);
    const iconColor       = Color(0xFF7E57C2);
    const textColor       = Colors.black87;

    return Container(
      width: 350,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_circle,
                size: 40,
                color: iconColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  username,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                color: iconColor,
              ),
            ],
          ),

          const SizedBox(height: 32),

          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Pomodoro'),
            horizontalTitleGap: 10,
            onTap: onSelectPomodoro,
          ),

          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('In Focus'),
            horizontalTitleGap: 10,
            onTap: onSelectInFocus,
          ),

          const Divider(),

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

          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: taskGroups.length,
              itemBuilder: (context, idx)
              {
                final name = taskGroups[idx];
                return ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(name),
                  horizontalTitleGap: 10,
                  onTap: () => onSelectTaskGroup(name),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
