import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tour_de_tasks/main_page.dart';
import 'package:tour_de_tasks/app_data.dart' as app;
import 'package:tour_de_tasks/user_data.dart';

// Widgetの設定（ステートに依存しない）を行う．
// sample.dartを参考にすると良い
class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  late GlobalKey<_CitySelectorState> citySelectorKey;

  @override
  void initState() {
    super.initState();
    // アプリの中断時にこのページから起動するためにUserDataのpageを設定
    UserData().page = app.Page.start;
    citySelectorKey = GlobalKey();
  }

  @override
  Widget build(BuildContext context) {
    // ここでwidgetを組み合わせる
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Start Page'),
        ),
        body: Column(
          children: <Widget>[
            CitySelector(
              key: citySelectorKey,
              onSelectedCityChanged: () {
                setState(() {});
              },
            ),
            Container(
              width: double.infinity,
              height: 80,
              color: Colors.black, // 背景色を黒
              alignment: Alignment.center, // テキストを中央
              child: Text(
                '都市:  ${selectedCity}   距離:  ${app.cities[selectedCity]!} km   ',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Container(
              width: double.infinity, // 横いっぱいに広げる
              height: 80,
              color: Colors.grey[800], // 背景色
              alignment: Alignment.center, // テキストを中央
              child: Text(
                '目安所要時間: ${(app.cities[selectedCity]! / app.initialSpeedKmPerSec).toStringAsFixed(2)}  ',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Spacer(flex: 1),
            SizedBox(
              width: 500,
              height: 100,
              child: ElevatedButton(
                  onPressed: () {
                    // ページ遷移はこんな感じ
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const MainPage()));
                    // ページ遷移とともにUserDataとLapRepositoryを初期化する
                    UserData().startCity = selectedCity;
                    UserData().confPassedDistanceKm = 0;
                    UserData().goalDistanceKm = app.cities[selectedCity]!;
                    UserData().running = true;
                    LapRepository().reset();
                    LapRepository().run();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text(
                    '旅に出る!',
                    style: TextStyle(color: Colors.white),
                  )),
            ),
            Spacer(flex: 1)
          ],
        ));
  }

  String get selectedCity =>
      citySelectorKey.currentState?.selectedCity ?? app.cities.keys.first;
}

class CitySelector extends StatefulWidget {
  final void Function()? onSelectedCityChanged;
  void _onSelectedCityChanged() {
    if (onSelectedCityChanged != null) {
      onSelectedCityChanged!();
    }
  }

  const CitySelector({super.key, this.onSelectedCityChanged});

  @override
  State<CitySelector> createState() => _CitySelectorState();
}

class _CitySelectorState extends State<CitySelector> {
  late PageController controller;
  late Random randomProvider;
  int? index;

  @override
  void initState() {
    super.initState();
    controller = PageController();
    controller.addListener(() {
      if (index != controller.page?.round()) {
        index = controller.page?.round();
        widget._onSelectedCityChanged();
      }
    });
    randomProvider = Random();
  }

  String get selectedCity {
    final cities = app.cities.keys.toList();
    final index = controller.page?.round() ?? 0;
    return cities[index];
  }

  Color provideColor(int index) {
    var options = [
      Colors.redAccent,
      Colors.greenAccent,
      Colors.blueAccent,
      Colors.amber
    ];
    return options[index % options.length];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height / 2,
        child: PageView(
          controller: controller,
          children: [
            for (var i = 0; i < app.cities.length; i++)
              // <ここを画像に>
              Container(
                color: provideColor(i),
                child: Center(
                  child: Text(app.cities.keys.elementAt(i),
                      style: const TextStyle(fontSize: 30)),
                ),
              ),
            // </ここを画像に>
          ],
        ));
  }
}
