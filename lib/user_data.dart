import 'dart:io';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';
// 用法はここに https://pub.dev/packages/shared_preferences
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' as sqflite_ffi_web;
// 用法はここに https://pub.dev/packages/sqflite
//            https://github.com/tekartik/sqflite/blob/master/sqflite_common_ffi/doc/using_ffi_instead_of_sqflite.md
//            https://pub.dev/packages/sqflite_common_ffi_web
import 'app_data.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

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
  Future<void> prepare() async {
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
      sqflite_ffi.sqfliteFfiInit();
      databaseFactory = sqflite_ffi.databaseFactoryFfi;
    } else if (kIsWeb) {
      databaseFactory = sqflite_ffi_web.databaseFactoryFfiWeb;
    }
    db = await openDatabase(dbName);
    await db.execute('CREATE TABLE IF NOT EXISTS $tableName ('
        '\'whenEpochSec\' INTEGER PRIMARY KEY,'
        '\'act\' TEXT,'
        'CHECK (act = \'run\' OR act = \'rest\')'
        ');');
    developer.log('LapRepository prepared', name: 'LapRepository');
    prepared = true;
  }

  // 走り出した時刻を記録する
  // 記録に失敗した場合はfalseを返す
  Future<bool> run() async {
    try {
      await db.execute('INSERT INTO $tableName (whenEpochSec, act) '
          'VALUES ('
          '${DateTime.now().millisecondsSinceEpoch ~/ 1000},'
          '\'run\')');
      return true;
    } catch (e) {
      developer.log(e.toString(), name: 'LapRepository');
      return false;
    }
  }

  // 休憩を始めた時刻を記録する
  // 記録に失敗した場合はfalseを返す
  Future<bool> rest() async {
    try {
      await db.execute('INSERT INTO $tableName (whenEpochSec, act) '
          'VALUES ('
          '${DateTime.now().millisecondsSinceEpoch ~/ 1000},'
          '\'rest\')');
      return true;
    } catch (e) {
      developer.log(e.toString(), name: 'LapRepository');
      return false;
    }
  }

  // すべての記録を削除する
  // 記録に失敗した場合はfalseを返す
  Future<bool> reset() async {
    try {
      await db.execute('DELETE FROM $tableName');
      return true;
    } catch (e) {
      developer.log(e.toString(), name: 'LapRepository');
      return false;
    }
  }

  // 記録を取得する
  Future<List<Lap>> get(int afterEpochSec) async {
    var res = await db.query(
        '$tableName WHERE whenEpochSec > $afterEpochSec ORDER BY whenEpochSec');
    return res
        .map((element) => Lap(
            whenEpochSec: element['whenEpochSec'] as int,
            act: element['act'] as String))
        .toList();
  }

  Future<Lap?> getLast() async {
    var result =
        await db.query('$tableName ORDER BY whenEpochSec DESC LIMIT 1');
    if (result.isEmpty) {
      return null;
    } else {
      return Lap(
          whenEpochSec: result.first['whenEpochSec'] as int,
          act: result.first['act'] as String);
    }
  }

  Future<Lap?> getFirst() async {
    var result = await db.query('$tableName ORDER BY whenEpochSec LIMIT 1');
    if (result.isEmpty) {
      return null;
    } else {
      return Lap(
          whenEpochSec: result.first['whenEpochSec'] as int,
          act: result.first['act'] as String);
    }
  }
}
