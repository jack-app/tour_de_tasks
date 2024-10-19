import 'package:shared_preferences/shared_preferences.dart';
// 用法はここに https://pub.dev/packages/shared_preferences
import 'package:sqflite/sqflite.dart';
// 用法はここに https://pub.dev/packages/sqflite
import 'app_data.dart';

import 'dart:developer' as developer;

class UserData {
  // インスタンスとsheredPreferencesを利用するための変数
  static UserData? _instance;
  SharedPreferencesWithCache? prefs;

  bool prepared = false;

  // シングルトンにするためのファクトリコンストラクタ
  factory UserData() {
    _instance ??= UserData._internal();
    return _instance!;
  }
  UserData._internal();

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
  static String dbName = 'lapRecord.db';
  static String tableName = 'lapRecord';
  Database? db;

  bool prepared = false;

  // シングルトンにするためのファクトリコンストラクタ
  factory LapRepository() {
    return LapRepository._internal();
  }
  LapRepository._internal();

  // 初期化関数
  Future<void> prepare() async {
    db ??= await openDatabase(
      dbName,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE $tableName ('
            'whenEpochSec INTEGER PRIMARY KEY,'
            'act ENUM("run","rest"),'
            ')');
      },
    );
    prepared = true;
  }

  // 走り出した時刻を記録する
  Future<void> run() async {
    await db!.insert(tableName, <String, dynamic>{
      'whenEpochSec': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'act': 'run',
    });
  }

  // 休憩を始めた時刻を記録する
  Future<void> rest() async {
    await db!.insert(tableName, <String, dynamic>{
      'whenEpochSec': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'act': 'rest',
    });
  }

  // すべての記録を削除する
  Future<void> reset() async {
    await db!.delete(tableName);
  }

  // 記録を取得する
  Future<List<Lap>?> get(int afterEpochSec) async {
    var results = await db!.query(tableName,
        where: 'whenEpochSec > ?', whereArgs: [afterEpochSec]);
    return results
        .map((e) => Lap(
            whenEpochSec: e['whenEpochSec'] as int, act: e['act'] as String))
        .toList();
  }

  Future<Lap?> getLast() async {
    var result = await db!
        .query(tableName, orderBy: 'whenEpochSec DESC', limit: 1, offset: 0);
    if (result.isEmpty) return null;
    return Lap(
        whenEpochSec: result[0]['whenEpochSec'] as int,
        act: result[0]['act'] as String);
  }
}
