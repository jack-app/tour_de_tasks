import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:tour_de_tasks/user_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LapRepository lapRepo = LapRepository();
  await lapRepo.prepare();
  lapRepo.run();
  await Future.delayed(const Duration(seconds: 1));
  lapRepo.rest();
  log((await lapRepo.get(0)).toString(), name: 'testLapRepo');
  log((await lapRepo.getLast()).toString(), name: 'testLapRepo');
  lapRepo.reset();
}
