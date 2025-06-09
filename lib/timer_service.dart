import 'dart:async';

enum SessionType { focus, shortBreak, longBreak }
enum TimerState { idle, running, paused }

class PomodoroTimer {
  Duration focusDuration;
  Duration shortBreakDuration;
  Duration longBreakDuration;
  int longBreakInterval;

  // 내부 상태
  late SessionType _currentSession;
  late Duration    _remainingTime;
  TimerState       _state = TimerState.idle;
  int              _focusCount = 0;
  Timer?           _timer;

  // UI 콜백
  void Function(SessionType session, Duration remaining)? onTick;
  void Function(SessionType session)? onSessionComplete;

  // 외부에서 읽기 전용으로 사용
  SessionType get currentSession => _currentSession;
  Duration    get remaining      => _remainingTime;
  TimerState  get state          => _state;

  PomodoroTimer({
    required this.focusDuration,
    required this.shortBreakDuration,
    required this.longBreakDuration,
    required this.longBreakInterval,
    this.onTick,
    this.onSessionComplete,
  })
  {
    _reset();
  }

  void updateSettings({
    Duration? focus,
    Duration? shortBreak,
    Duration? longBreak,
    int? interval,
  }) {
    _timer?.cancel();

    focusDuration      = focus       ?? focusDuration;
    shortBreakDuration = shortBreak  ?? shortBreakDuration;
    longBreakDuration  = longBreak   ?? longBreakDuration;
    longBreakInterval  = interval    ?? longBreakInterval;

    _reset();
  }

  void _reset() {
    _currentSession = SessionType.focus;
    _remainingTime = focusDuration;
    _state = TimerState.idle;
    _focusCount = 0;

    onTick?.call(_currentSession, _remainingTime);
  }

  /// Start 버튼 눌렀을 때
  void start() {
    if (_state == TimerState.idle) {
      _state = TimerState.running;
      _startTimer();
    } else if (_state == TimerState.paused) {
      resume();
    }
  }

  /// Pause 버튼 눌렀을 때
  void pause() {
    if (_state == TimerState.running) {
      _timer?.cancel();
      _state = TimerState.paused;
    }
  }

  /// Resume 버튼 눌렀을 때
  void resume() {
    if (_state == TimerState.paused) {
      _state = TimerState.running;
      _startTimer();
    }
  }

  /// Skip 버튼 눌렀을 때 (기록 없이 다음 세션으로 바로 전환)
  void skip() {
    _timer?.cancel();
    _completeSession(skip: true);
  }

  /// 내부 타이머를 실제로 돌리는 부분
  void _startTimer() {
    _timer?.cancel();
    // 첫 틱 전에도 UI 갱신
    onTick?.call(_currentSession, _remainingTime);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _remainingTime -= const Duration(seconds: 1);

      if (_remainingTime.inSeconds <= 0) {
        _completeSession();
      } else {
        onTick?.call(_currentSession, _remainingTime);
      }
    });
  }

  /// 세션이 끝났을 때 처리
  void _completeSession({bool skip = false}) {
    _timer?.cancel();
    _state = TimerState.idle;

    // focus 세션 완료 시에만 서버 전송용 콜백 호출
    if (!skip && _currentSession == SessionType.focus) {
      onSessionComplete?.call(_currentSession);
    }

    // focus 세션이었으면 카운트 증가
    if (_currentSession == SessionType.focus) {
      _focusCount++;
    }

    // 다음 세션 결정
    if (_currentSession == SessionType.focus) {
      if (_focusCount % longBreakInterval == 0) {
        _currentSession  = SessionType.longBreak;
        _remainingTime   = longBreakDuration;
      } else {
        _currentSession  = SessionType.shortBreak;
        _remainingTime   = shortBreakDuration;
      }
    } else {
      // break 이후엔 항상 focus
      _currentSession  = SessionType.focus;
      _remainingTime   = focusDuration;
    }

    // 세션 전환 후 UI에 새 모드와 시간을 알림
    onTick?.call(_currentSession, _remainingTime);
  }
}
