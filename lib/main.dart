import 'dart:async';
import 'dart:ui';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:tour_de_tasks/start_page.dart';
import 'package:tour_de_tasks/main_page.dart';
import 'package:tour_de_tasks/goal_page.dart';
import 'package:tour_de_tasks/user_data.dart';
import 'package:tour_de_tasks/app_data.dart' as app;

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
  late Future<void> _lapRepositoryPreparation;

  @override
  void initState() {
    super.initState();
    _userDataPreparation = _userData.prepare();
    _lapRepositoryPreparation = LapRepository().prepare();
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
        future: Future.wait([_userDataPreparation, _lapRepositoryPreparation]),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            developer.log('エラーが発生しました: ${snapshot.error.toString()}',
                name: 'MainApp');
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
