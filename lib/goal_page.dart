import 'package:flutter/material.dart';
import 'package:tour_de_tasks/start_page.dart';
import 'package:tour_de_tasks/user_data.dart';
import 'package:tour_de_tasks/app_data.dart' as app;

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

  Future<double> calcPassedTimeFromStartInDays() async {
    LapRepository laps = LapRepository();
    Lap? first = await laps.getFirst();
    Lap? last = await laps.getLast();
    if (first == null || last == null) {
      return 0.0;
    }
    int passedTimeInEpoch = last.whenEpochSec - first.whenEpochSec;
    double passedTimeInDays = passedTimeInEpoch / (60 * 60 * 24);
    return passedTimeInDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Goal Page'),
        ),
        body: Column(
          children: <Widget>[
            const Text('Congratulation!', style: TextStyle(fontSize: 30)),
            const Expanded(
              child: ColoredBox(
                color: Colors.redAccent,
                child: Center(
                  child: Text('Paris', style: TextStyle(fontSize: 30)),
                ),
              ),
            ),
            Text(
                '${UserData().startCity} から ${UserData().goalDistanceKm} km を完走しました！',
                style: const TextStyle(fontSize: 20)),
            FutureBuilder(
                future: calcPassedTimeFromStartInDays(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                        '所要日数は ${snapshot.data!.toStringAsPrecision(4)} 日でした！',
                        style: const TextStyle(fontSize: 20));
                  } else {
                    return const Text('所要日数は  日でした!',
                        style: TextStyle(fontSize: 20));
                  }
                }),
            Expanded(
              child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (context) => const StartPage()));
                      },
                      child:
                          const Text('終了する', style: TextStyle(fontSize: 30)))),
            ),
          ],
        ));
  }
}
