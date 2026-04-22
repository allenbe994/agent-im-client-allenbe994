import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/uuid.dart';
import '../../../data/local/session_store.dart';
import 'session_state.dart';

class SessionCubit extends Cubit<SessionState> {
  SessionCubit({SessionStore? store})
      : _store = store ?? SessionStore(),
        super(SessionState.initial);

  final SessionStore _store;

  Future<void> loadSessions() async {
    final list = _store.loadAll()..sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
    if (list.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final s = Session(
        id: UuidUtil.v4(),
        title: '新会话',
        createdAtMs: now,
        updatedAtMs: now,
        lastEventId: 0,
      );
      await _store.upsert(s);
      emit(SessionState(sessions: [s], activeSessionId: s.id, loading: false));
      return;
    }
    emit(SessionState(sessions: list, activeSessionId: list.first.id, loading: false));
  }

  Future<void> createSession() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final s = Session(
      id: UuidUtil.v4(),
      title: '新会话',
      createdAtMs: now,
      updatedAtMs: now,
      lastEventId: 0,
    );
    await _store.upsert(s);
    emit(state.copyWith(sessions: [s, ...state.sessions], activeSessionId: s.id));
  }

  Future<void> deleteSession(String id) async {
    await _store.delete(id);
    final next = state.sessions.where((e) => e.id != id).toList(growable: false);
    final nextActive = state.activeSessionId == id ? (next.isNotEmpty ? next.first.id : null) : state.activeSessionId;
    emit(state.copyWith(sessions: next, activeSessionId: nextActive));
  }

  void setActive(String id) {
    emit(state.copyWith(activeSessionId: id));
  }

  Future<void> updateLastEventId(String sessionId, int lastEventId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final next = state.sessions
        .map(
          (s) => s.id == sessionId
              ? s.copyWith(updatedAtMs: now, lastEventId: lastEventId)
              : s,
        )
        .toList(growable: false);
    final updated = next.firstWhere((s) => s.id == sessionId, orElse: () => throw StateError('session missing'));
    await _store.upsert(updated);
    emit(state.copyWith(sessions: next));
  }
}

