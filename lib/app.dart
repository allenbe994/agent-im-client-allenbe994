import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'feature/session/cubit/session_cubit.dart';
import 'feature/session/ui/session_list_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SessionCubit()..loadSessions()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Agent IM Client',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const SessionListPage(),
      ),
    );
  }
}

