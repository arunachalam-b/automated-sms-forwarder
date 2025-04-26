import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/filter.dart';
import '../models/forwarded_sms_log.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  static const String _dbName = 'app_data.db';
  static const String _filtersTable = 'filters';
  static const String _logsTable = 'forwarded_logs';

  static const String _fColId = 'id';
  static const String _fColRecipients = 'recipients';
  static const String _fColConditions = 'conditions';

  static const String _lColId = 'id';
  static const String _lColFilterId = 'filterId';
  static const String _lColOriginalSender = 'originalSender';
  static const String _lColForwardedTo = 'forwardedTo';
  static const String _lColMessageContent = 'messageContent';
  static const String _lColDateTime = 'dateTime';
  static const String _lColStatus = 'status';
  static const String _lColErrorMessage = 'errorMessage';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);
    return await openDatabase(path, version: 2, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future _onCreate(Database db, int version) async {
    await _createFiltersTable(db);
    await _createLogsTable(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createLogsTable(db);
    }
  }

  Future<void> _createFiltersTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_filtersTable (
        $_fColId TEXT PRIMARY KEY,
        $_fColRecipients TEXT NOT NULL,
        $_fColConditions TEXT NOT NULL
      )
      ''');
  }

  Future<void> _createLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_logsTable (
        $_lColId TEXT PRIMARY KEY,
        $_lColFilterId TEXT NOT NULL,
        $_lColOriginalSender TEXT NOT NULL,
        $_lColForwardedTo TEXT NOT NULL,
        $_lColMessageContent TEXT NOT NULL,
        $_lColDateTime TEXT NOT NULL,
        $_lColStatus TEXT NOT NULL,
        $_lColErrorMessage TEXT
      )
      ''');
  }

  Map<String, dynamic> _filterToMap(Filter filter) {
    return {
      _fColId: filter.id,
      _fColRecipients: jsonEncode(filter.recipients),
      _fColConditions: jsonEncode(filter.conditions.map((c) => c.toJson()).toList()),
    };
  }

  Filter _filterFromMap(Map<String, dynamic> map) {
    List<String> recipients = List<String>.from(jsonDecode(map[_fColRecipients]));
    List<FilterCondition> conditions = (jsonDecode(map[_fColConditions]) as List)
        .map((item) => FilterCondition.fromJson(item))
        .toList();
    return Filter(
      id: map[_fColId],
      recipients: recipients,
      conditions: conditions,
    );
  }

  Future<int> insertFilter(Filter filter) async {
    Database db = await database;
    return await db.insert(_filtersTable, _filterToMap(filter));
  }

  Future<List<Filter>> getAllFilters() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_filtersTable);
    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) {
      return _filterFromMap(maps[i]);
    });
  }

  Future<int> updateFilter(Filter filter) async {
    Database db = await database;
    return await db.update(
      _filtersTable,
      _filterToMap(filter),
      where: '$_fColId = ?',
      whereArgs: [filter.id],
    );
  }

  Future<int> deleteFilter(String id) async {
    Database db = await database;
    return await db.delete(
      _filtersTable,
      where: '$_fColId = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertForwardedSmsLog(ForwardedSmsLog log) async {
    Database db = await database;
    return await db.insert(_logsTable, log.toMap());
  }

  Future<List<ForwardedSmsLog>> getAllForwardedSmsLogs({int limit = 100}) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
        _logsTable,
        orderBy: '$_lColDateTime DESC',
        limit: limit,
    );
    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) {
      return ForwardedSmsLog.fromMap(maps[i]);
    });
  }

  Future<int> deleteAllLogs() async {
    Database db = await database;
    return await db.delete(_logsTable);
  }

  Future<int> deleteLogsForFilter(String filterId) async {
    Database db = await database;
    return await db.delete(
        _logsTable,
        where: '$_lColFilterId = ?',
        whereArgs: [filterId],
    );
  }

  Future<void> close() async {
    Database db = await database;
    await db.close();
    _database = null;
  }
} 