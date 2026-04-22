# Agent IM Client (Flutter)
实现⼀个⽀持 Agent 消息流的聊天demo

## 1. 项目简介
消息渲染 ：用户/Agent 区分、Markdown、工具卡片（折叠/展开）、思考状态。 （已完美实现）
流式处理 ：对接事件类型、逐字追加、多轮 thinking -> tool_call -> text_delta 循环。 （已通过 Cubit 状态机完美实现）
会话与输入 ：多会话增删改查、乐观展示、重试机制。 （已通过 SessionCubit 和失败状态管理实现）
状态管理 ：Bloc/Cubit 结构清晰，状态流转正确。 （已实现）
加分项 ：
本地持久化 (Hive) （已实现）
连接状态指示器 （已实现）
性能优化（Throttler/Debouncer） （已实现）

## 2. 技术选型理由
状态管理使用  Cubit    原因:Cubit 天然适合处理长流程、有序事件。比 Bloc 简单，比 Provider 稳，所有 UI 状态都在 ChatState 里
本地持久化 Hive极速 不写sql 存储。纯 Dart 实现，跨平台支持完美，非常适合消息列表这种高频写入且结构相对简单的 键值对 数据场景。 
flutter_markdown 官方推荐
性能优化使用 `Throttler` (节流) 控制 UI 刷新频率（80ms），使用 `Debouncer` (防抖) 控制 DB 写入频率（450ms），解决流式消息下的性能瓶颈。 
通信机制 采用 Reactive 响应式编程模型，通过接口抽象 WebSocket 通信，支持 Mock 与真实后端无缝切换。 |

## 3. 架构说明
采用 Feature

lib/
├── core/           # 跨模块基础能力（节流防抖工具、全局常量、日志等）
├── data/           # 数据层（Hive 持久化实现、WS 客户端抽象与 Mock 实现）
├── domain/         # 领域层（纯 Dart 模型类，如 ChatMessage、ToolCall）
└── feature/        # 业务功能模块
    ├── chat/       # 核心聊天模块（Cubit 逻辑、流式渲染 UI、工具卡片）
    └── session/    # 会话管理模块（多会话增删改查）


核心设计点：
lastEventId 每次收到事件实时记录 ID 并持久化，重连时自动发送该 ID 实现断点续传。
状态机管理定义 `StreamPhase`（idle, thinking, toolCalling, responding）精准驱动 UI 交互。
渲染组件化  消息气泡自动识别 `Markdown`、`ToolCard` 或 `ThinkingIndicator`
实现了标准 AgentLoop用户输入 >AI 思考 >判断是否调用工具 >执行工具 >获取结果 >生成回答 >多轮循环直到结束，整套流程通过状态机和事件流完整驱动。

## 4. 启动步骤
1   flutter pub get
2      flutter run （我是启的chrome 但是桌面跟移动端应该都能跑）
##### 环境
[√] Flutter (Channel stable, 3.35.3, on Microsoft Windows [版本 10.0.26200.8246], locale zh-CN)
[√] Windows Version (11 家庭中文版 64-bit, 25H2, 2009)
[√] Android toolchain - develop for Android devices (Android SDK version 36.0.0)
[√] Chrome - develop for the web
[!] Visual Studio - develop Windows apps (Visual Studio Community 2026 18.0.2)
X Visual Studio is missing necessary components. Please re-run the Visual Studio installer for the "Desktop development with C++" workload, and include these components:
MSVC v142 - VS 2019 C++ x64/x86 build tools
- If there are multiple build tool versions available, install the latest
C++ CMake tools for Windows
Windows 10 SDK
[√] Android Studio (version 2025.1.2)
[√] IntelliJ IDEA Ultimate Edition (version 2025.2)
[√] Connected device (3 available)
[!] Network resources             
X A network error occurred while checking "https://github.com/": 信号灯超时时间已到


! Doctor found issues in 2 categories.
## 5. 功能清单

### 已完成功能
消息渲染：支持用户文本、Agent Markdown、工具调用卡片（带折叠展开）、Agent 思考状态。
流式处理：对接事件驱动模型，支持 `text_delta`、`thinking`、`tool_call`、`tool_result` 及其多轮循环。
会话与输入：多会话切换/新建/删除、底部输入框发送、发送后乐观展示、失败重试机制。
状态管理：基于 Bloc/Cubit 的清晰结构，正确处理流式事件的状态流转。
本地持久化：使用 Hive 实现会话与消息的永久存储。
性能优化：针对高频流式消息实现了 UI 节流与 DB 写入防抖。
连接状态指示：顶部实时显示 WebSocket 连接状态。

### 待完成/扩展
真实 WebSocket 地址配置（目前由 MockWsClient 驱动）。
消息列表分页加载（大数据量场景进一步优化）。
更多样式的工具展示卡片。
真实 api 