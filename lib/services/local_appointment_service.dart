import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalAppointmentService {
  static final LocalAppointmentService instance =
      LocalAppointmentService._init();

  static Database? _database;

  LocalAppointmentService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('medelyra.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) async {
        // Make sure both tables exist regardless of which local service
        // opened the database first.
        await _createMedicinesTable(db);
        await _createAppointmentsTable(db);
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await _createMedicinesTable(db);
    await _createAppointmentsTable(db);
  }

  Future<void> _upgradeDB(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    await _createMedicinesTable(db);
    await _createAppointmentsTable(db);
  }

  Future<void> _createMedicinesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medicines (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        medicineName TEXT NOT NULL,
        medicineType TEXT NOT NULL,
        dose TEXT NOT NULL,
        instructions TEXT NOT NULL,
        frequency TEXT NOT NULL,
        times TEXT NOT NULL,
        duration TEXT NOT NULL,
        durationDays INTEGER,
        startDate TEXT NOT NULL,
        endDate TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createAppointmentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS appointments (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        appointmentType TEXT NOT NULL,
        hospital TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        reason TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<String> insertAppointment(
    Map<String, dynamic> appointment,
  ) async {
    final db = await database;

    await db.insert(
      'appointments',
      appointment,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return appointment['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getAppointments(
    String userId,
  ) async {
    final db = await database;

    return await db.query(
      'appointments',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'dateTime ASC',
    );
  }

  Future<Map<String, dynamic>?> getAppointment(String id) async {
    final db = await database;

    final results = await db.query(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }

  Future<int> updateAppointment(
    String id,
    Map<String, dynamic> appointment,
  ) async {
    final db = await database;

    return await db.update(
      'appointments',
      appointment,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAppointment(String id) async {
    final db = await database;

    return await db.delete(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllAppointments(String userId) async {
    final db = await database;

    return await db.delete(
      'appointments',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
