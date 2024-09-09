import 'package:flutter/material.dart';
import 'main_page.dart';
import 'app_data.dart' as app;
import 'user_data.dart';

// Widgetの設定（ステートに依存しない）を行う．
// sample.dartを参考にすると良い
class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  @override
  void initState() {
    super.initState();
    // アプリの中断時にこのページから起動するためにUserDataのpageを設定
    UserData().page = app.Page.start;
  }

  @override
  Widget build(BuildContext context) {
    // ここでwidgetを組み合わせる
    // 以下の記述は動作テスト用のものなので残す必要はない
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Start Page'),
      ),
      body: Column(
        children: <Widget>[
          const CitySelector(),
          ElevatedButton(
            onPressed: () {
              // ページ遷移はこんな感じ
              Navigator
              .of(context)
              .pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const MainPage()
                )
              );
            }, 
            child: const Text('Start')
          ),
        ],
      )
    );
  }
}

class CitySelector extends StatefulWidget {
  const CitySelector({super.key});

  @override
  State<CitySelector> createState() => _CitySelectorState();
}
class _CitySelectorState extends State<CitySelector> {
  @override
  Widget build(BuildContext context) {
    return const Text('地図とボタンを配置する');
  }
}
