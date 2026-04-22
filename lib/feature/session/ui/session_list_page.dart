import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../chat/ui/chat_page.dart';
import '../cubit/session_cubit.dart';
import '../cubit/session_state.dart';
import 'widgets/session_tile.dart';

class SessionListPage extends StatelessWidget {
  const SessionListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<SessionCubit, SessionState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            final sessions = state.sessions;
            final activeId = state.activeSessionId;
            return Row(
              children: [
                SizedBox(
                  width: 280,
                  child: Column(
                    children: [
                      _SidebarHeader(
                        onNew: () => context.read<SessionCubit>().createSession(),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          itemCount: sessions.length,
                          itemBuilder: (context, i) {
                            final s = sessions[i];
                            return SessionTile(
                              session: s,
                              active: s.id == activeId,
                              onTap: () => context.read<SessionCubit>().setActive(s.id),
                              onDelete: () => context.read<SessionCubit>().deleteSession(s.id),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: activeId == null
                      ? const Center(child: Text('暂无会话，请新建一个。'))
                      : ChatPage(sessionId: activeId),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.onNew});

  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '会话',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.add),
            label: const Text('新建'),
          ),
        ],
      ),
    );
  }
}

