import 'package:flutter/material.dart';

import '../../cubit/session_state.dart';

class SessionTile extends StatelessWidget {
  const SessionTile({
    super.key,
    required this.session,
    required this.active,
    required this.onTap,
    required this.onDelete,
  });

  final Session session;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      selected: active,
      selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      title: Text(
        session.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('最后事件的id: ${session.lastEventId}'),
      onTap: onTap,
      trailing: IconButton(
        tooltip: '删除',
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline),
      ),
    );
  }
}

