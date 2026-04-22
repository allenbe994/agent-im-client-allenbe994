import 'package:equatable/equatable.dart';

class Session extends Equatable {
  const Session({
    required this.id,
    required this.title,
    required this.createdAtMs,
    required this.updatedAtMs,
    required this.lastEventId,
  });

  final String id;
  final String title;
  final int createdAtMs;
  final int updatedAtMs;
  final int lastEventId;

  Session copyWith({String? title, int? updatedAtMs, int? lastEventId}) {
    return Session(
      id: id,
      title: title ?? this.title,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      lastEventId: lastEventId ?? this.lastEventId,
    );
  }

  @override
  List<Object?> get props => [id, title, createdAtMs, updatedAtMs, lastEventId];
}

class SessionState extends Equatable {
  const SessionState({
    required this.sessions,
    required this.activeSessionId,
    required this.loading,
  });

  final List<Session> sessions;
  final String? activeSessionId;
  final bool loading;

  SessionState copyWith({
    List<Session>? sessions,
    String? activeSessionId,
    bool? loading,
  }) {
    return SessionState(
      sessions: sessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [sessions, activeSessionId, loading];

  static const initial = SessionState(sessions: [], activeSessionId: null, loading: true);
}

