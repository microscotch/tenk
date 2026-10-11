import '../src/scheduler.dart';

/// Un [Scheduler] sans vraies minuteries : les actions partent quand le test
/// avance le temps ([elapse]), dans l'ordre de leurs échéances. [onAdvance]
/// recale l'horloge du test (celle passée en `now` au serveur) à chaque
/// échéance, pour que l'action la lise à la bonne heure.
class FakeScheduler implements Scheduler {
  final void Function(Duration elapsed) onAdvance;
  final List<_Pending> _pending = [];
  Duration _now = Duration.zero;

  FakeScheduler({required this.onAdvance});

  /// Les actions encore programmées.
  int get pendingCount => _pending.where((p) => !p.cancelled).length;

  @override
  Cancellable schedule(Duration delay, void Function() action) {
    final pending = _Pending(_now + delay, action);
    _pending.add(pending);
    return pending;
  }

  /// Avance de [duration], en exécutant au passage chaque action échue — y
  /// compris celles qu'une action programme elle-même dans la fenêtre.
  void elapse(Duration duration) {
    final target = _now + duration;
    for (;;) {
      final due = _pending.where((p) => !p.cancelled && p.at <= target).toList()..sort((a, b) => a.at.compareTo(b.at));
      if (due.isEmpty) break;
      final next = due.first;
      _pending.remove(next);
      onAdvance(next.at - _now);
      _now = next.at;
      next.action();
    }
    onAdvance(target - _now);
    _now = target;
    _pending.removeWhere((p) => p.cancelled);
  }
}

class _Pending implements Cancellable {
  final Duration at;
  final void Function() action;
  bool cancelled = false;

  _Pending(this.at, this.action);

  @override
  void cancel() => cancelled = true;
}
