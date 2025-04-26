import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/filter.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  static const String _dbName = 'filters.db';
  static const String _tableName = 'filters';
  static const String _colId = 'id';
  static const String _colRecipients = 'recipients'; // JSON String
  static const String _colConditions = 'conditions'; // JSON String

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        $_colId TEXT PRIMARY KEY,
        $_colRecipients TEXT NOT NULL,
        $_colConditions TEXT NOT NULL
      )
      ''');
  }

  // --- Filter Conversion Helpers ---

  Map<String, dynamic> _filterToMap(Filter filter) {
    return {
      _colId: filter.id,
      // Encode lists to JSON strings
      _colRecipients: jsonEncode(filter.recipients),
      _colConditions: jsonEncode(filter.conditions.map((c) => c.toJson()).toList()),
    };
  }

  Filter _filterFromMap(Map<String, dynamic> map) {
    // Decode JSON strings back to lists
    List<String> recipients = List<String>.from(jsonDecode(map[_colRecipients]));
    List<FilterCondition> conditions = (jsonDecode(map[_colConditions]) as List)
        .map((item) => FilterCondition.fromJson(item))
        .toList();

    return Filter(
      id: map[_colId],
      recipients: recipients,
      conditions: conditions,
    );
  }

  // --- FilterCondition JSON Helpers (Add these to FilterCondition class itself) ---
  // Moved to model file

  // --- CRUD Operations ---

  Future<int> insertFilter(Filter filter) async {
    Database db = await database;
    return await db.insert(_tableName, _filterToMap(filter));
  }

  Future<List<Filter>> getAllFilters() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
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
      _tableName,
      _filterToMap(filter),
      where: '$_colId = ?',
      whereArgs: [filter.id],
    );
  }

  Future<int> deleteFilter(String id) async {
    Database db = await database;
    return await db.delete(
      _tableName,
      where: '$_colId = ?',
      whereArgs: [id],
    );
  }

   Future<void> close() async {
     Database db = await database;
     await db.close();
     _database = null; // Reset static instance
   }
} 