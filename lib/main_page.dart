import 'dart:async';
import 'dart:math';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:tour_de_tasks/start_page.dart';
import 'package:tour_de_tasks/goal_page.dart';
import 'package:tour_de_tasks/user_data.dart';
import 'package:tour_de_tasks/app_data.dart' as app;

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
  // <private>
  MainPageController._internal();

  factory MainPageController() {
    // 中断からの復帰で状況を復元する
    developer.log('controller required', name: 'mainPageController');
    final MainPageController controller = MainPageController._internal();
    if (UserData().running) {
      controller._startTimer();
    } else {
      controller._stopTimer();
    }
    return controller;
  }

  Future<bool> Function()? _updateProgressBar; // falseが返された場合それ以上の更新を行うべきでない
  Future<bool> Function()? _updateSlideShow; // falseが返された場合それ以上の更新を行うべきでない
  Future<bool> Function()? _autoTransition; // falseが返された場合それ以上の更新を行うべきでない
  Timer? _timer;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 6), _onEveryFrame);
    _onEveryFrame(_timer!); // 初回のフレームにも更新を行う
    developer.log('timer started', name: 'mainPageController');
  }

  void _stopTimer() {
    _timer?.cancel();
    developer.log('timer stopped', name: 'mainPageController');
  }

  void _onEveryFrame(Timer timer) async {
    // 初期化が終わっていない場合は何もしない
    if (_updateProgressBar == null ||
        _updateSlideShow == null ||
        _autoTransition == null) {
      developer.log('onEveryFrame was called but initializing not completed',
          name: 'onEverySecond');
      return;
    }

    // all Future should return true to keep the timer alive
    var timerShouldBeAlive = (await Future.wait(
            [_updateProgressBar!(), _updateSlideShow!(), _autoTransition!()]))
        .every((result) => result);

    if (!timerShouldBeAlive) {
      _stopTimer();
    }
  }
  // </private>

  // <public>
  Future<int> getKeepRunningTimeInSec({Lap? lastLap}) async {
    var lap = lastLap ?? await LapRepository().getLast();
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
    var lap = await LapRepository().getLast();
    if (lap == null) {
      return 0.0;
    } else if (lap.act == 'rest') {
      return UserData().confPassedDistanceKm;
    } else if (lap.act == 'run') {
      final passedDistanceKm =
          await calcPassedDistanceKmFromLastRest(lastLap: lap);
      return UserData().confPassedDistanceKm + passedDistanceKm;
    } else {
      throw Exception('Invalid act');
    }
  }

  Future<double> calcRemainingDistanceKm() async {
    final passedDistanceKm = await calcPassedDistanceKm();
    return max(0, UserData().goalDistanceKm - passedDistanceKm);
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
    return passedDistanceKm / UserData().goalDistanceKm;
  }

  void rest() {
    if (!UserData().running) {
      return;
    }
    UserData().running = false;
    calcPassedDistanceKm().then((distanceKm) {
      UserData().confPassedDistanceKm = distanceKm;
      LapRepository().rest();
    });
    // 必要があればスライドショーなどの更新をここでする
    _stopTimer();
  }

  void run() {
    if (UserData().running) {
      return;
    }
    LapRepository().run();
    UserData().running = true;
    // 必要があればスライドショーなどの更新をここでする
    _startTimer();
  }
  // </public>
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
          controller.rest();
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
            Expanded(
              child: SlideShow(controller: controller),
            ),
            Expanded(
              child: ControlPanel(controller: controller),
            )
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
  late String location;

  @override
  void initState() {
    super.initState();
    location = UserData().startCity;
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Center(child: ProgressBar(controller: controller)),
        Expanded(
            child: Padding(
          padding: const EdgeInsets.all(5),
          child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: controller.run, child: const Text('走る'))),
        )),
        Expanded(
            child: Padding(
                padding: const EdgeInsets.all(5),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: controller.rest, child: const Text('休む')),
                ))),
        Padding(
            padding: const EdgeInsets.all(5),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const StartPage()));
                  },
                  child: const Text('リセット')),
            )),
      ],
    );
  }
}

class ProgressBar extends StatefulWidget {
  final MainPageController controller;
  final double? width;
  final double? height;
  const ProgressBar(
      {super.key, required this.controller, this.width, this.height});

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  double passedDistanceKm = 0.0;
  double remainingDistanceKm = 0.0;
  double width = 0;
  double widgetHeight = 40;

  @override
  void initState() {
    super.initState();
    widget.controller._updateProgressBar = () async {
      if (mounted) {
        widget.controller.calcRemainingDistanceKm().then((distanceKm) {
          setState(() {
            remainingDistanceKm = distanceKm;
          });
        });
        widget.controller.calcPassedDistanceKm().then((distanceKm) {
          setState(() {
            passedDistanceKm = distanceKm;
          });
        });
        return true;
      } else {
        return false; // すでに表示されていないので，更新を行うべきでない
      }
    };
    widgetHeight = widget.height ?? widgetHeight;
  }

  static const double iconOffset = -10;
  static const double iconSize = 8;
  double barWidth = 5;

  @override
  Widget build(BuildContext context) {
    width = widget.width ?? MediaQuery.of(context).size.width * 0.9;
    // アイコンを見切れさせないためにpaddingを手動設定
    var padding = (MediaQuery.of(context).size.width - width) / 2;
    var progress = passedDistanceKm / app.cities[UserData().startCity]!;
    if (progress > 1) {
      progress = 1;
    }
    // 位置を計算
    var iconRight = padding + width * progress + iconOffset - (iconSize / 2);
    var iconLeft =
        padding + width * (1 - progress) + iconOffset - (iconSize / 2);
    var textRight =
        progress > 0.7 ? null : padding + width * progress + iconSize;
    var textLeft =
        progress > 0.7 ? padding + width * (1 - progress) + iconSize : null;

    widget.controller._updateProgressBar!();
    return Container(
        width: double.infinity,
        height: widgetHeight,
        clipBehavior: Clip.none,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // カスタマイズするため，デフォルトで提供されているLinearProgressIndicatorは使わない
            Stack(
              alignment: Alignment.centerRight,
              children: [
                // <プログレスバーの背景部分/>
                Container(
                  width: width,
                  height: barWidth,
                  color: Colors.grey,
                ),
                // <プログレスバーの進捗表示部分/>
                Container(
                  width: width * progress,
                  height: barWidth,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
            // <アイコン/>
            Positioned(
              right: iconRight,
              left: iconLeft,
              top: widgetHeight / 4 - (iconSize / 2),
              child: Image.asset(
                'images/rider_icon.png',
              ),
            ),
            // <テキスト表示/>
            Positioned(
              left: textLeft,
              right: textRight,
              top: 0,
              child: Text(
                'あと ${remainingDistanceKm.toStringAsFixed(1)} km',
              ),
            ),
          ],
        ));
  }
}
