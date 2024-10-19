import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'start_page.dart';
import 'main_page.dart';
import 'goal_page.dart';
import 'user_data.dart';
import 'app_data.dart' as app;

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final UserData _userData = UserData();
  late Future<void> _userDataPreparation;

  @override
  void initState() {
    super.initState();
    _userDataPreparation = _userData.prepare();
    LapRepository().prepare();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tour_de_tasks',
      scrollBehavior: const MyCustomScrollBehavior(),
      theme: ThemeData(
        // アプリのテーマ
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder(
        future: Future.wait([_userDataPreparation]),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('エラーが発生しました: ${snapshot.error.toString()}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.done) {
            // アプリ終了時のページを開く
            // ここが実行される時点でUserData, LapRepositoryはprepareされているので，
            // StartPage, MainPage, GoalPage内でprepareは不要
            switch (_userData.page) {
              case app.Page.start:
                return const StartPage();
              case app.Page.main:
                return const MainPage();
              case app.Page.goal:
                return const GoalPage();
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}

// マウス操作を有効化するためのカスタムBehavior
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  const MyCustomScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
