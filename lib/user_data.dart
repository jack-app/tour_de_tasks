import 'dart:ffi';

import 'package:shared_preferences/shared_preferences.dart';
// 用法はここに https://pub.dev/packages/shared_preferences
// ~~import 'package:sqflite/sqflite.dart'; -> 非対応らしい
// ~~用法はここに https://pub.dev/packages/sqflite
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';
// 用法はここに https://pub.dev/packages/sqlite3
import 'app_data.dart';

import 'dart:developer' as developer;

class UserData {
  UserData._internal();
  SharedPreferencesWithCache? prefs;

  bool prepared = false;

  // シングルトンにするためのファクトリコンストラクタ
  static final UserData _instance = UserData._internal();
  factory UserData() => _instance;

  // userDataにアクセスする前に必ず呼び出す初期化関数
  Future<void> prepare() async {
    prefs ??= await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(
      // allowList: 使えるキーのリスト
      allowList: <String>{
        'startCity',
        'goalDistance',
        'confPassedDistanceKm',
        'running',
        'page'
      },
    ));
    developer.log('UserData prepared', name: 'UserData');
    developer.log('startCity: $startCity', name: 'UserData');
    developer.log('goalDistance: $goalDistanceKm', name: 'UserData');
    developer.log('confPassedDistanceKm: $confPassedDistanceKm',
        name: 'UserData');
    developer.log('running: $running', name: 'UserData');
    developer.log('page: $page', name: 'UserData');
    prepared = true;
  }

  // 以下getter定義
  // setterについては本当はawaitしなければならないが，取り回しが悪いのでそのまま．

  // 開始地点
  String get startCity {
    var startCity = prefs!.getString('startCity');
    if (startCity == null || !cities.containsKey(startCity)) {
      return cities.keys.first;
    }
    return startCity;
  }

  set startCity(String value) => prefs!.setString('startCity', value);

  // 目標距離 (km)
  double get goalDistanceKm => prefs!.getDouble('goalDistance') ?? 0.0;
  set goalDistanceKm(double value) => prefs!.setDouble('goalDistance', value);

  // 確定した到達距離（km）- 目標達成時あるいは休むボタンを押したときにのみ更新する
  double get confPassedDistanceKm =>
      prefs!.getDouble('confPassedDistanceKm') ?? 0.0;
  set confPassedDistanceKm(double value) =>
      prefs!.setDouble('confPassedDistanceKm', value);

  // 走行中かどうか
  bool get running => prefs!.getBool('running') ?? false;
  set running(bool value) => prefs!.setBool('running', value);

  // 現在のページ
  Page get page => Page.values[prefs!.getInt('page') ?? 0];
  set page(Page value) => prefs!.setInt('page', value.index);
}

// データベースの定義

class Lap {
  final int whenEpochSec;
  final String act;

  Lap({required this.whenEpochSec, required this.act});
}

class LapRepository {
  LapRepository._internal();
  static String dbName = 'lapRecord.db';
  static String tableName = 'lapRecord';
  late final Database db;

  bool prepared = false;

  // シングルトンにするためのファクトリコンストラクタ
  static final LapRepository _instance = LapRepository._internal();
  factory LapRepository() => _instance;

  // 初期化関数
  void prepare() {
    openDB();
    db.execute('CREATE TABLE IF NOT EXISTS $tableName ('
        'whenEpochSec INTEGER PRIMARY KEY,'
        'act ENUM("run","rest"),'
        ')');
    developer.log('LapRepository prepared', name: 'LapRepository');
    prepared = true;
  }

  void openDB() {
    db = sqlite3.open(dbName);
  }

  void closeDB() {
    db.dispose();
  }

  // 走り出した時刻を記録する
  void run() {
    db.execute('INSERT INTO $tableName (whenEpochSec, act) '
        'VALUES ('
        '${DateTime.now().millisecondsSinceEpoch ~/ 1000},'
        '"run")');
  }

  // 休憩を始めた時刻を記録する
  void rest() {
    db.execute('INSERT INTO $tableName (whenEpochSec, act) '
        'VALUES ('
        '${DateTime.now().millisecondsSinceEpoch ~/ 1000},'
        '"rest")');
  }

  // すべての記録を削除する
  void reset() {
    db.execute('DROP TABLE IF EXISTS $tableName');
  }

  // 記録を取得する
  List<Lap> get(int afterEpochSec) {
    var res = db.select(
        'SELECT * FROM $tableName WHERE whenEpochSec > $afterEpochSec ORDER BY whenEpochSec');
    return res
        .map((element) =>
            Lap(whenEpochSec: element['whenEpochSec'], act: element['act']))
        .toList();
  }

  Future<Lap?> getLast() async {
    var result = await db.query(tableName,
        orderBy: 'whenEpochSec DESC', limit: 1, offset: 0);
    if (result.isEmpty) return null;
    return Lap(
        whenEpochSec: result[0]['whenEpochSec'] as int,
        act: result[0]['act'] as String);
  }
}
