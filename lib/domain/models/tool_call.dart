import 'package:equatable/equatable.dart';

class ToolCall extends Equatable {
  const ToolCall({
    required this.callId,
    required this.toolName,
    required this.argsJson,
    this.resultJson,
  });

  final String callId;
  final String toolName;
  final String argsJson;
  final String? resultJson;

  ToolCall copyWith({String? resultJson}) {
    return ToolCall(
      callId: callId,
      toolName: toolName,
      argsJson: argsJson,
      resultJson: resultJson ?? this.resultJson,
    );
  }

  @override
  List<Object?> get props => [callId, toolName, argsJson, resultJson];
}

