import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._init();

  static Database? _database;

  LocalDatabaseService._init();

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
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) async {
        await _createMedicinesTable(db);
        await _createAppointmentsTable(db);
        await _createMedicineDoseStatusTable(db);
        await _ensureAppointmentCompletedAtColumn(db);
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await _createMedicinesTable(db);
    await _createAppointmentsTable(db);
    await _createMedicineDoseStatusTable(db);
  }

  Future<void> _upgradeDB(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    await _createMedicinesTable(db);
    await _createAppointmentsTable(db);
    await _createMedicineDoseStatusTable(db);

    if (oldVersion < 3) {
      await _ensureAppointmentCompletedAtColumn(db);
    }
  }

  // ============================================================
  // MEDICINES
  // ============================================================

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

  // ============================================================
  // APPOINTMENTS
  // ============================================================

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
        completedAt TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _ensureAppointmentCompletedAtColumn(
    Database db,
  ) async {
    try {
      final columns = await db.rawQuery(
        'PRAGMA table_info(appointments)',
      );

      final hasCompletedAt = columns.any(
        (column) => column['name'] == 'completedAt',
      );

      if (!hasCompletedAt) {
        await db.execute(
          'ALTER TABLE appointments ADD COLUMN completedAt TEXT',
        );
      }
    } catch (_) {
      // Ignore if the column already exists.
    }
  }

  // ============================================================
  // MEDICINE DOSE STATUS
  // ============================================================

  Future<void> _createMedicineDoseStatusTable(
    Database db,
  ) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medicine_dose_status (
        medicineId TEXT NOT NULL,
        userId TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        status TEXT NOT NULL,
        postponedUntil TEXT,
        updatedAt TEXT NOT NULL,
        PRIMARY KEY (medicineId, date, time)
      )
    ''');
  }

  // ============================================================
  // MEDICINE CRUD
  // ============================================================

  Future<String> insertMedicine(
    Map<String, dynamic> medicine,
  ) async {
    final db = await database;

    await db.insert(
      'medicines',
      medicine,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return medicine['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getMedicines(
    String userId,
  ) async {
    final db = await database;

    return await db.query(
      'medicines',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<Map<String, dynamic>?> getMedicine(
    String id,
  ) async {
    final db = await database;

    final results = await db.query(
      'medicines',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }

  Future<int> updateMedicine(
    String id,
    Map<String, dynamic> medicine,
  ) async {
    final db = await database;

    return await db.update(
      'medicines',
      medicine,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMedicine(String id) async {
    final db = await database;

    await db.delete(
      'medicine_dose_status',
      where: 'medicineId = ?',
      whereArgs: [id],
    );

    return await db.delete(
      'medicines',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllMedicines(String userId) async {
    final db = await database;

    final medicines = await db.query(
      'medicines',
      columns: ['id'],
      where: 'userId = ?',
      whereArgs: [userId],
    );

    for (final medicine in medicines) {
      await db.delete(
        'medicine_dose_status',
        where: 'medicineId = ?',
        whereArgs: [medicine['id']],
      );
    }

    return await db.delete(
      'medicines',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // ============================================================
  // DOSE STATUS
  // ============================================================

  Future<void> upsertMedicineDoseStatus({
    required String medicineId,
    required String userId,
    required String date,
    required String time,
    required String status,
    DateTime? postponedUntil,
  }) async {
    final db = await database;

    await db.insert(
      'medicine_dose_status',
      {
        'medicineId': medicineId,
        'userId': userId,
        'date': date,
        'time': time,
        'status': status,
        'postponedUntil': postponedUntil?.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getMedicineDoseStatus({
    required String medicineId,
    required String date,
    required String time,
  }) async {
    final db = await database;

    final results = await db.query(
      'medicine_dose_status',
      where: 'medicineId = ? AND date = ? AND time = ?',
      whereArgs: [
        medicineId,
        date,
        time,
      ],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }

  Future<List<Map<String, dynamic>>> getMedicineDoseStatusesForDate({
    required String userId,
    required String date,
  }) async {
    final db = await database;

    return await db.query(
      'medicine_dose_status',
      where: 'userId = ? AND date = ?',
      whereArgs: [
        userId,
        date,
      ],
    );
  }

  Future<int> deleteMedicineDoseStatuses(
    String medicineId,
  ) async {
    final db = await database;

    return await db.delete(
      'medicine_dose_status',
      where: 'medicineId = ?',
      whereArgs: [medicineId],
    );
  }

  // ============================================================
  // CLOSE
  // ============================================================

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
