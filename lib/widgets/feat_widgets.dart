import 'package:flutter/material.dart';
import 'package:pomotask_client/main.dart';
import 'package:pomotask_client/timer_service.dart';
import 'package:pomotask_client/api_service.dart' as api_service;

class PomodoroAndInFocusContent extends StatelessWidget {
  final PomodoroTimer timer;
  final SessionType  session;
  final Duration     remaining;
  final TimerState   state;

  const PomodoroAndInFocusContent({
    Key? key,
    required this.timer,
    required this.session,
    required this.remaining,
    required this.state,
  }) : super(key: key);

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2,'0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  int _totalSeconds() {
    switch(session) {
      case SessionType.focus:     return timer.focusDuration.inSeconds;
      case SessionType.shortBreak:return timer.shortBreakDuration.inSeconds;
      case SessionType.longBreak: return timer.longBreakDuration.inSeconds;
    }
  }

  @override
  Widget build(BuildContext context) {
    const activeColor   = Color(0xFF7E57C2);
    const inactiveColor = Colors.grey;
    final progress      = remaining.inSeconds / _totalSeconds();

    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical:24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Settings 버튼
              Padding(
                padding: const EdgeInsets.only(right:24),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: activeColor,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () {/* TODO */},
                    child: const Text('Settings'),
                  ),
                ),
              ),
              const SizedBox(height:48),

              // Session 선택 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: SessionType.values.map((t) {
                  final label = {
                    SessionType.focus: 'Focus',
                    SessionType.shortBreak: 'Short Break',
                    SessionType.longBreak: 'Long Break',
                  }[t]!;
                  final isActive = session == t;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal:6),
                    child: SizedBox(
                      width:125,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive ? activeColor : inactiveColor,
                          foregroundColor: isActive ? Colors.white : Colors.black87,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          timer.skipSessionByButton(t);
                        },
                        child: Text(label),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height:32),

              // 타이머 표시
              Text(
                _format(remaining),
                style: const TextStyle(fontSize:96, color:Colors.white),
              ),
              const SizedBox(height:16),

              // 진행도 바
              Padding(
                padding: const EdgeInsets.symmetric(horizontal:48),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  backgroundColor: Colors.white,
                  value: progress.clamp(0.0,1.0),
                ),
              ),
              const SizedBox(height:32),

              // Start/Pause/Resume 버튼
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeColor,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal:48, vertical:16),
                ),
                icon: Icon(
                  state == TimerState.running
                    ? Icons.pause
                    : Icons.play_arrow,
                  size:28,
                ),
                label: Text(
                  state == TimerState.running
                    ? 'Pause'
                    : (state == TimerState.paused ? 'Resume' : 'Start'),
                  style: const TextStyle(fontSize:20),
                ),
                onPressed: () {
                  switch(state) {
                    case TimerState.idle:   timer.start();    break;
                    case TimerState.running:timer.pause();    break;
                    case TimerState.paused: timer.resume();   break;
                  }
                },
              ),

              const SizedBox(height:64),
              const Text(
                'In Focus',
                style: TextStyle(fontSize:28, fontWeight:FontWeight.bold),
              ),
              const SizedBox(height:24),

              // In Focus 리스트는 기존에 구현하신 _buildInFocusItem(row) 등을 그대로 사용
              // 예: _buildInFocusItem('Task 1'), ...

            ],
          ),
        ),
      ),
    );
  }
}

class TaskListPage extends StatefulWidget {
  final int      groupId;
  final String   groupName;
  /// 그룹이 삭제되었을 때 호출
  final ValueChanged<int> onDelete;

  const TaskListPage({
    Key? key,
    required this.groupId,
    required this.groupName,
    required this.onDelete,
  }) : super(key: key);

  @override
  _TaskListPageState createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;

  // new task 팝업용
  final TextEditingController _newTaskNameController = TextEditingController();
  final TextEditingController _newTaskDescController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    final tasks = await api_service.fetchTasksInList(serverAddress, widget.groupId);
    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  Future<void> _showAddTaskDialog() async {
    // 초기화
    _newTaskNameController.clear();
    _newTaskDescController.clear();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('태스크 이름'),
            ),
            TextField(
              controller: _newTaskNameController,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('태스크 설명'),
            ),
            TextField(
              controller: _newTaskDescController,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result == true) {
      final name = _newTaskNameController.text.trim();
      final desc = _newTaskDescController.text.trim();
      if (name.isEmpty) return;

      // 기존 태스크 중 가장 큰 order 값 찾아서 +1
      final maxOrder = _tasks.fold<int>(
        0,
        (prev, t) => (t['order'] as int? ?? 0) > prev ? t['order'] as int : prev,
      );
      final newOrder = maxOrder + 1;

      // 서버에 새 태스크 추가
      await api_service.addTaskToList(
        server: serverAddress,
        listId: widget.groupId,
        title: name,
        description: desc,
        order: newOrder,
      );

      // 다시 목록 불러오기
      await _fetchTasks();
    }
  }

  Future<void> _deleteList() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('리스트 삭제'),
        content: const Text('정말 이 리스트를 삭제하시겠습니까? 모든 태스크가 함께 삭제됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context,false), child: const Text('아니오')),
          TextButton(onPressed: () => Navigator.pop(context,true),  child: const Text('예')),
        ],
      ),
    );
    if (confirmed == true) {
      await api_service.deleteTaskList(serverAddress, widget.groupId);
      widget.onDelete(widget.groupId);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor     = Color(0xFFF3E5F5);
    const cardColor   = Colors.white;
    const iconColor   = Color(0xFF7E57C2);
    const textColor   = Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // 제목 (클릭 시 편집 팝업 예정)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // TODO: 제목 편집 팝업
                  },
                  child: Text(
                    widget.groupName,
                    style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // New Task 버튼
              ElevatedButton.icon(
                onPressed: _showAddTaskDialog,
                icon: const Icon(Icons.add),
                label: const Text('New Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cardColor,
                  foregroundColor: iconColor,
                  elevation: 1,
                  padding: const EdgeInsets.symmetric(horizontal:12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Delete List 버튼
              ElevatedButton.icon(
                onPressed: _deleteList,
                icon: const Icon(Icons.delete),
                label: const Text('Delete List'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cardColor,
                  foregroundColor: iconColor,
                  elevation: 1,
                  padding: const EdgeInsets.symmetric(horizontal:12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _tasks.length,
            itemBuilder: (context, idx) {
              final t = _tasks[idx];
              final done = t['completed'] as bool? ?? false;

              return Card(
                color: cardColor,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // 완료 토글
                      IconButton(
                        icon: Icon(
                          Icons.check_circle,
                          color: done ? iconColor : Colors.grey,
                        ),
                        onPressed: () async {
                          // TODO: 서버에 완료 상태 업데이트
                          setState(() {
                            _tasks[idx]['completed'] = !done;
                          });
                        },
                      ),

                      // 제목 (팝업 예정)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // TODO: 상세 팝업
                          },
                          child: Text(
                            t['title'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              color: textColor,
                              decoration: done
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            ),
                          ),
                        ),
                      ),

                      // 수정
                      IconButton(
                        icon: const Icon(Icons.edit, color: iconColor),
                        onPressed: () {
                          // TODO: 수정 팝업
                        },
                      ),

                      // In Focus 추가
                      IconButton(
                        icon: const Icon(Icons.playlist_add, color: iconColor),
                        onPressed: () {
                          // TODO: In Focus 추가
                        },
                      ),

                      // 삭제
                      IconButton(
                        icon: const Icon(Icons.delete, color: iconColor),
                        onPressed: () async {
                          await api_service.deleteTask(serverAddress, t['id'] as int,);
                          setState(() {
                            _tasks.removeAt(idx);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
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
  // 사이드바 제어용 키
  final GlobalKey<_SidebarState> _sidebarKey = GlobalKey<_SidebarState>();

  // 뽀모도로 타이머 관련 데이터
  late PomodoroTimer _pomoTimer;
  late SessionType  _uiSession;
  late Duration     _uiRemaining;
  late TimerState   _uiTimerState;

  // Task Group 관련 데이터
  int? _selectedGroupId;
  String? _selectedGroupName;

  @override
  void initState()
  {
    super.initState();

    _pomoTimer = PomodoroTimer(
      focusDuration:      const Duration(minutes: 2),
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
            key: _sidebarKey,
            username: loggedInUser,
            onLogout: ()
            {
              // TODO: 로그아웃 처리
            },
            onSelectPomodoro:   () {
              setState(() {
                _selectedGroupId   = null;
                _selectedGroupName = null;
              });
            },
            onSelectInFocus: () {
              setState(() {
                _selectedGroupId   = null;
                _selectedGroupName = null;
              });
            },
            onSelectTaskGroup: (id, name) {
              setState(() {
                _selectedGroupId   = id;
                _selectedGroupName = name;
             });
            },
          ),

          Expanded(
            child: _selectedGroupId == null
              ? PomodoroAndInFocusContent(
                  timer: _pomoTimer,
                  session: _uiSession,
                  remaining: _uiRemaining,
                  state: _uiTimerState,
                )
              : TaskListPage(
                  groupId:   _selectedGroupId!,
                  groupName: _selectedGroupName!,
                  onDelete:  (deletedGroupId) {
                    // 삭제되면 다시 Pomodoro 화면으로 돌아가기
                    setState(() {
                      _selectedGroupId = null;
                      _selectedGroupName = null;
                    });
                    _sidebarKey.currentState?.refreshTaskLists();
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class Sidebar extends StatefulWidget {
  final String            username;
  final VoidCallback      onLogout;
  final VoidCallback      onSelectPomodoro;
  final VoidCallback      onSelectInFocus;
  final void Function(int id, String name) onSelectTaskGroup;

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

  void refreshTaskLists() {
    setState(() {
      _loading = true;
    });
    _fetchTaskLists();
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
                onTap: () => widget.onSelectTaskGroup(
                  item['id'] as int,
                  item['name'] as String,
               ),
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