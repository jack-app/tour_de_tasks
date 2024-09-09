import 'package:flutter/material.dart';
import 'start_page.dart';
import 'user_data.dart';
import 'app_data.dart' as app;

// Widgetの設定（ステートに依存しない）を行う．
// sample.dartを参考にすると良い
class GoalPage extends StatefulWidget {
  const GoalPage({super.key});

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  @override
  void initState() {
    super.initState();
    // アプリの中断時にこのページから起動するためにUserDataのpageを設定
    UserData().page = app.Page.goal;
  }

  @override
  Widget build(BuildContext context) {
    // ここでwidgetを組み合わせる
    // 以下の記述は動作テスト用のものなので残す必要はない
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Goal Page'),
      ),
      body: Column(
        children: <Widget>[
          const Text('ゴールページ'),
          ElevatedButton(
            onPressed: () {
              // ページ遷移はこんな感じ
              Navigator
              .of(context)
              .pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const StartPage()
                )
              );
            }, 
            child: const Text('遷移')
          ),
        ],
      )
    );
  }
}
