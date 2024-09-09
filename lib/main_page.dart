import 'dart:async';

import 'package:flutter/material.dart';
import 'goal_page.dart';
import 'user_data.dart';
import 'app_data.dart' as app;


// このクラスのインスタンスをwidget間でリレーさせて，包括的な操作を用意にする
class WidgetsController {
  bool Function()? _updateProgressBar; // falseが返された場合それ以上の更新を行うべきでない
  bool Function()? _updateSlideShow; // falseが返された場合それ以上の更新を行うべきでない
  Timer? _timer;

  WidgetsController._internal();

  factory WidgetsController() {
    WidgetsController controller =  WidgetsController._internal();
    controller._timer = Timer.periodic(const Duration(seconds: 1), controller.onEverySecond);
    return controller;
  }

  void onEverySecond(Timer timer) {
    // 初期化が終わっていない場合は何もしない
    if (_updateProgressBar == null || _updateSlideShow == null) { return; }

    bool timerShouldBeAlive = true;
    timerShouldBeAlive &= _updateProgressBar!();
    // _updateSlideShowは毎秒呼ぶ必要はないので, 条件分岐で呼び出しを制御できると良い
    timerShouldBeAlive &= _updateSlideShow!();

    if (!timerShouldBeAlive) {
      timer.cancel();
    }
  }

  double calcDistanceKm() {
    // 要実装
    return UserData().confPassedDistanceKm;
  }

  String calcLocation() {
    // 要実装
    return UserData().startCity;
  }

  void rest() {
    // 要実装
    // Lapで記録
    // confPassedDistanceKmを更新
    // 必要があればスライドショーなどの更新
    _timer?.cancel();
  }

  void run() {
    // 要実装
    // Lapで記録
    // 必要があればスライドショーなどの更新
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), onEverySecond);
  }
}


// Widgetの設定（ステートに依存しない）を行う．
// sample.dartを参考にすると良い
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}
class _MainPageState extends State<MainPage> {
  WidgetsController? controller;

  @override
  void initState() {
    super.initState();
    // アプリの中断時にこのページから起動するためにUserDataのpageを設定
    UserData().page = app.Page.main;
    // 最初のwidgetsControllerのインスタンス化はここで行う．以降はこのインスタンスを受け渡す．
    controller = WidgetsController();
  }

  @override
  Widget build(BuildContext context) {
    // ここでwidgetを組み合わせる
    // 以下の記述は動作テスト用のものなので残す必要はない
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Main Page'),
      ),
      body: Column(
        children: <Widget>[
          SlideShow(controller: controller!),
          ControlPanel(controller: controller!),
          ElevatedButton(
            onPressed: () {
              // ページ遷移はこんな感じ
              Navigator
              .of(context)
              .pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const GoalPage()
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


class SlideShow extends StatefulWidget {
  final WidgetsController controller;
  const SlideShow({super.key, required this.controller});

  @override
  State<SlideShow> createState() => _SlideShowState();
}
class _SlideShowState extends State<SlideShow> {
  String location = app.cities[0];

  @override
  void initState() {
    super.initState();
    widget.controller._updateSlideShow = () {
      if (mounted) { // widgetが表示されているかどうか
        setState(() {
          location = widget.controller.calcLocation();
        });
        return true;
      } else {
        return false; // すでに表示されていないので，更新を行うべきでない
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return const Text('スライドショーを配置する');
  }
}



class ControlPanel extends StatelessWidget {
  final WidgetsController controller;
  const ControlPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // 仮なのでどう書き換えても良い
    return Column(
      children: <Widget>[
        ProgressBar(controller: controller),
        ElevatedButton(onPressed: controller.run, child: const Text('Run')),
        ElevatedButton(onPressed: controller.rest, child: const Text('Rest')),
      ],
    );
  }
}



class ProgressBar extends StatefulWidget {
  final WidgetsController controller;
  const ProgressBar({super.key, required this.controller});

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}
class _ProgressBarState extends State<ProgressBar> {

  int _countUpForTest = 0;
  double passedDistanceKm = 0.0;

  @override
  void initState() {
    super.initState();
    widget.controller._updateProgressBar = () {
      if (mounted) { // widgetが表示されているかどうか
        setState(() {
          _countUpForTest++;
          passedDistanceKm = widget.controller.calcDistanceKm();
        });
        return true;
      } else {
        return false; // すでに表示されていないので，更新を行うべきでない
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Text('プログレスバーを配置する $_countUpForTest');
  }
}
