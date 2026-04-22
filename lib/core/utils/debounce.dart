import 'dart:async';
//定义防抖和节流
class Debouncer {
  Debouncer(this.delay);

  final Duration delay;
  Timer? _timer;

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void flushNow(void Function() action) {
    _timer?.cancel();
    _timer = null;
    action();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

class Throttler {
  Throttler(this.interval);

  final Duration interval;
  Timer? _timer;
  void Function()? _pending;

  void call(void Function() action) {
    if (_timer == null) {
      action();
      _timer = Timer(interval, () {
        _timer = null;
        final p = _pending;
        _pending = null;
        if (p != null) call(p);
      });
      return;
    }
    _pending = action;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
  }
}

