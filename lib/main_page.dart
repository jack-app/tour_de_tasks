import 'dart:async';
import 'dart:math';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'goal_page.dart';
import 'user_data.dart';
import 'app_data.dart' as app;

// 速度は次の連続走行時間の関数で規定する
// v( t[sec] ) = initialSpeedKmPerSec + (maxSpeedKmPerSec - initialSpeedKmPerSec) * (1 - exp(-t / 60))
//             = maxSpeedKmPerSec - (maxSpeedKmPerSec - initialSpeedKmPerSec) * exp( -t / 60 )
// なお，
// L( t[sec] ) = ∫[0, t] v(τ) dτ
//             = maxSpeedKmPerSec * t
//               + (maxSpeedKmPerSec - initialSpeedKmPerSec) * exp(-t / 60) / 60
//               - (maxSpeedKmPerSec - initialSpeedKmPerSec) / 60

// このクラスのインスタンスをwidget間でリレーさせて，包括的な操作を用意にする
class MainPageController {
  Future<bool> Function()? _updateProgressBar; // falseが返された場合それ以上の更新を行うべきでない
  Future<bool> Function()? _updateSlideShow; // falseが返された場合それ以上の更新を行うべきでない
  Future<bool> Function()? _autoTransition; // falseが返された場合それ以上の更新を行うべきでない
  Timer? _timer;

  MainPageController._internal();

  final LapRepository _lapRepo = LapRepository();
  final UserData _userData = UserData();

  factory MainPageController() {
    MainPageController controller = MainPageController._internal();
    controller.run();
    return controller;
  }

  void onEveryFrame(Timer timer) async {
    // 初期化が終わっていない場合は何もしない

    if (_updateProgressBar == null ||
        _updateSlideShow == null ||
        _autoTransition == null) {
      developer.log('onEverySecond was called but initializing not completed',
          name: 'onEverySecond');
      return;
    }

    // all Future should return true to keep the timer alive
    var timerShouldBeAlive = (await Future.wait(
            [_updateProgressBar!(), _updateSlideShow!(), _autoTransition!()]))
        .every((result) => result);

    if (!timerShouldBeAlive) {
      timer.cancel();
    }
  }

  Future<int> getKeepRunningTimeInSec({Lap? lastLap}) async {
    var lap = lastLap ?? await _lapRepo.getLast();
    if (lap == null || lap.act == 'rest') {
      return 0;
    } else {
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 - lap.whenEpochSec;
    }
  }

  Future<double> calcSpeedKmPerSec({Lap? lastLap}) async {
    var keepRunning = await getKeepRunningTimeInSec(lastLap: lastLap);
    const minInSec = 60;
    final keepRunningTimeMin = keepRunning / minInSec;
    return app.maxSpeedKmPerSec -
        (app.maxSpeedKmPerSec - app.initialSpeedKmPerSec) *
            exp(-keepRunningTimeMin);
  }

  Future<double> calcPassedDistanceKmFromLastRest({Lap? lastLap}) async {
    var keepRunning = await getKeepRunningTimeInSec(lastLap: lastLap);
    const minInSec = 60;
    const maxMinDiff = app.maxSpeedKmPerSec - app.initialSpeedKmPerSec;
    final keepRunningTimeMin = keepRunning / minInSec;
    return app.maxSpeedKmPerSec * keepRunning +
        maxMinDiff * exp(-keepRunningTimeMin) / minInSec -
        maxMinDiff / minInSec;
  }

  Future<double> calcPassedDistanceKm() async {
    var lap = await _lapRepo.getLast();
    if (lap == null) {
      return 0.0;
    } else if (lap.act == 'rest') {
      return _userData.confPassedDistanceKm;
    } else if (lap.act == 'run') {
      final passedDistanceKm =
          await calcPassedDistanceKmFromLastRest(lastLap: lap);
      return _userData.confPassedDistanceKm + passedDistanceKm;
    } else {
      throw Exception('Invalid act');
    }
  }

  Future<double> calcRemainingDistanceKm() async {
    var initialRemainingDistanceKm = app.cities[_userData.startCity];
    if (initialRemainingDistanceKm == null) {
      throw Exception('Invalid startCity');
    }
    final passedDistanceKm = await calcPassedDistanceKm();
    return max(0, initialRemainingDistanceKm - passedDistanceKm);
  }

  Future<String> calcLocation() async {
    final remainingDistanceKm = await calcRemainingDistanceKm();
    final city = app.cities.entries
        .firstWhere((entry) => entry.value >= remainingDistanceKm)
        .key;
    return city;
  }

  Future<double> calcProgress() async {
    final passedDistanceKm = await calcPassedDistanceKm();
    return passedDistanceKm / app.cities[_userData.startCity]!;
  }

  void rest() {
    _userData.running = false;
    calcPassedDistanceKm().then((distanceKm) {
      _userData.confPassedDistanceKm = distanceKm;
      _lapRepo.rest();
    });
    // 必要があればスライドショーなどの更新
    _timer?.cancel();
  }

  void run() {
    _lapRepo.run();
    _userData.running = true;
    // 必要があればスライドショーなどの更新
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 600), onEveryFrame);
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
  late MainPageController controller;

  @override
  void initState() {
    super.initState();
    // アプリの中断時にこのページから起動するためにUserDataのpageを設定
    UserData().page = app.Page.main;
    // 最初のwidgetsControllerのインスタンス化はここで行う．以降はこのインスタンスを受け渡す．
    controller = MainPageController();
  }

  @override
  Widget build(BuildContext context) {
    // 自動遷移の設定
    controller._autoTransition = () async {
      final remainingDistanceKm = await controller.calcRemainingDistanceKm();
      if (remainingDistanceKm <= 0) {
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const GoalPage()));
        }
        return false;
      } else {
        return true;
      }
    };
    // ここでwidgetを組み合わせる
    // 以下の記述は動作テスト用のものなので残す必要はない
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Main Page'),
        ),
        body: Column(
          children: <Widget>[
            SlideShow(controller: controller),
            ControlPanel(controller: controller),
            ElevatedButton(
                onPressed: () {
                  // ページ遷移はこんな感じ
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => const GoalPage()));
                },
                child: const Text('遷移')),
          ],
        ));
  }
}

class SlideShow extends StatefulWidget {
  final MainPageController controller;
  const SlideShow({super.key, required this.controller});

  @override
  State<SlideShow> createState() => _SlideShowState();
}

class _SlideShowState extends State<SlideShow> {
  String location = app.cities.keys.first;

  @override
  void initState() {
    super.initState();
    widget.controller._updateSlideShow = () async {
      // widgetが表示されているかどうか
      if (mounted) {
        widget.controller.calcLocation().then((location) {
          setState(() {
            this.location = location;
          });
        });
        return true;
      } else {
        // すでに表示されていないので，更新を行うべきでない
        return false;
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return const Text('スライドショーを配置する');
  }
}

class ControlPanel extends StatelessWidget {
  final MainPageController controller;
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
  final MainPageController controller;
  const ProgressBar({super.key, required this.controller});

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  double passedDistanceKm = 0.0;
  double remainingDistanceKm = 0.0;
  double speedKmPerSec = 0.0;
  String location = '';

  @override
  void initState() {
    super.initState();
    widget.controller._updateProgressBar = () async {
      if (mounted) {
        // widgetが表示されているかどうか
        widget.controller.calcPassedDistanceKm().then((distanceKm) {
          setState(() {
            passedDistanceKm = distanceKm;
          });
        });
        widget.controller.calcRemainingDistanceKm().then((distanceKm) {
          setState(() {
            remainingDistanceKm = distanceKm;
          });
        });
        widget.controller.calcSpeedKmPerSec().then((speed) {
          setState(() {
            speedKmPerSec = speed;
          });
        });
        widget.controller.calcLocation().then((location) {
          setState(() {
            this.location = location;
          });
        });
        return true;
      } else {
        return false; // すでに表示されていないので，更新を行うべきでない
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Text('プログレスバーを配置する'),
      Text('passedDistanceKm: $passedDistanceKm'),
      Text('remainingDistanceKm: $remainingDistanceKm'),
      Text('speedKmPerSec: $speedKmPerSec'),
      Text('location: $location'),
    ]);
  }
}
