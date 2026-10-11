import 'dart:async';

/// Une action programmée, qu'on peut encore annuler.
abstract class Cancellable {
  void cancel();
}

/// Programme des actions différées. Le salon n'utilise jamais `Timer`
/// directement : les tests lui donnent une horloge qu'ils avancent eux-mêmes
/// (voir `test/fake_scheduler.dart`), comme pour `now`.
abstract class Scheduler {
  Cancellable schedule(Duration delay, void Function() action);
}

/// Le vrai : un [Timer] par action.
class TimerScheduler implements Scheduler {
  const TimerScheduler();

  @override
  Cancellable schedule(Duration delay, void Function() action) => _TimerHandle(Timer(delay, action));
}

class _TimerHandle implements Cancellable {
  final Timer _timer;
  _TimerHandle(this._timer);

  @override
  void cancel() => _timer.cancel();
}
