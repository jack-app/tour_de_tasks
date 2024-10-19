import 'dart:math';
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
    // 以下の記述は動作テスト用のものなので残す必要はない
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Start Page'),
      ),
      body: Column(
        children: <Widget>[
          CitySelector(key:citySelectorKey),
          Container(
            width: double.infinity, 
            height: 80, 
            color: Colors.black, // 背景色を黒
            alignment: Alignment.center, // テキストを中央
            child: Text('都市:  ${selectedCity}   距離:  ${app.cities[selectedCity]!} km   ',style:const TextStyle(color: Colors.white),),
          ),
          Container(
            width: double.infinity, // 横いっぱいに広げる
            height: 80, 
            color: Colors.grey[800], // 背景色
            alignment: Alignment.center, // テキストを中央
            child: Text('目安所要時間: ${(app.cities[selectedCity]! / app.initialSpeedKmPerSec).toStringAsFixed(2)}  ',style:const TextStyle(color: Colors.white),),
          ),
          Spacer(flex: 1),
          SizedBox(
            width: 500, 
            height: 100, 
            
            child: ElevatedButton(
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
              
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey, 
                
              ),
              child: const Text('旅に出る!',style: TextStyle(color: Colors.white), )
            ),
          ),
          Spacer(flex: 1)
            
        ],
      )
    );
  }

  String get selectedCity =>
      citySelectorKey.currentState?.selectedCity ?? app.cities.keys.first;
}

class CitySelector extends StatefulWidget {
  const CitySelector({super.key});

  @override
  State<CitySelector> createState() => _CitySelectorState();
}

class _CitySelectorState extends State<CitySelector> {
  late PageController controller;
  late Random randomProvider;

  @override
  void initState() {
    super.initState();
    controller = PageController();
    randomProvider = Random();
  }

  String get selectedCity {
    final cities = app.cities.keys.toList();
    final index = controller.page?.round() ?? 0;
    return cities[index];
  }

  int nProvidedColors = 0;
  Color provideColor() {
    var options = [
      Colors.redAccent,
      Colors.greenAccent,
      Colors.blueAccent,
      Colors.amber
    ];
    nProvidedColors++;
    return options[(nProvidedColors - 1) % options.length];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height / 2,
        child: PageView(
          controller: controller,
          children: [
            for (var cityName in app.cities.keys)
              Container(
                color: provideColor(),
                child: Center(
                  child: Text(cityName),
                ),
              ),
          ],
        ));
  }
}
