import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_config.dart';
import '../../../data/ws/mock_ws_server.dart';
import '../../../data/ws/ws_client.dart';
import '../../session/cubit/session_cubit.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/chat_list.dart';
import 'widgets/connection_banner.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  ChatCubit? _cubit;

  @override
  void didUpdateWidget(covariant ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId) {
      _recreateCubit();
    }
  }

  @override
  void initState() {
    super.initState();
    _recreateCubit();
  }

  void _recreateCubit() {
    _cubit?.dispose();

    final sessionCubit = context.read<SessionCubit>();
    final s = sessionCubit.state.sessions.firstWhere((e) => e.id == widget.sessionId);
    final ws = _buildWsClient();
    final c = ChatCubit(ws: ws, sessionCubit: sessionCubit, sessionId: widget.sessionId, lastEventId: s.lastEventId);
    _cubit = c..init();
    setState(() {});
  }

  WsClient _buildWsClient() {
    switch (AppConfig.mode) {
      case RuntimeMode.mock:
        return MockWsClient();
      case RuntimeMode.ws:
        return MockWsClient();
    }
  }

  @override
  void dispose() {
    _cubit?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) return const SizedBox.shrink();

    return BlocProvider.value(
      value: cubit,
      child: Column(
        children: [
          BlocBuilder<ChatCubit, ChatState>(
            buildWhen: (p, n) => p.connection != n.connection,
            builder: (context, state) => ConnectionBanner(status: state.connection),
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<ChatCubit, ChatState>(
              buildWhen: (p, n) => p.messages != n.messages,
              builder: (context, state) => ChatList(messages: state.messages),
            ),
          ),
          const Divider(height: 1),
          ChatInputBar(
            onSend: cubit.send,
          ),
        ],
      ),
    );
  }
}

