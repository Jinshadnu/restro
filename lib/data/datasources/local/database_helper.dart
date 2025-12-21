import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/task_model.dart';
import '../../models/sop_model.dart';
import '../../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('restro.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        role TEXT NOT NULL,
        lastSynced TEXT
      )
    ''');

    // SOPs table
    await db.execute('''
      CREATE TABLE sops (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        steps TEXT NOT NULL,
        frequency TEXT NOT NULL,
        requiresPhoto INTEGER NOT NULL DEFAULT 0,
        isCritical INTEGER NOT NULL DEFAULT 0,
        criticalThreshold TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');

    // Tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        sopId TEXT NOT NULL,
        assignedTo TEXT NOT NULL,
        assignedBy TEXT NOT NULL,
        status TEXT NOT NULL,
        frequency TEXT NOT NULL,
        dueDate TEXT,
        completedAt TEXT,
        photoUrl TEXT,
        rejectionReason TEXT,
        createdAt TEXT NOT NULL,
        verifiedAt TEXT,
        synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (sopId) REFERENCES sops (id)
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_tasks_assignedTo ON tasks(assignedTo)');
    await db.execute('CREATE INDEX idx_tasks_status ON tasks(status)');
    await db.execute('CREATE INDEX idx_tasks_synced ON tasks(synced)');
    await db.execute('CREATE INDEX idx_tasks_assignedBy ON tasks(assignedBy)');
  }

  // User operations
  Future<void> insertUser(AppUserModel user) async {
    final db = await database;
    await db.insert(
      'users',
      {
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'phone': user.phone,
        'role': user.role,
        'lastSynced': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AppUserModel?> getUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isEmpty) return null;
    return AppUserModel.fromMap(maps.first);
  }

  Future<List<AppUserModel>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users');
    return maps.map((map) => AppUserModel.fromMap(map)).toList();
  }

  // SOP operations
  Future<void> insertSOP(SOPModel sop) async {
    final db = await database;
    await db.insert(
      'sops',
      {
        'id': sop.id,
        'title': sop.title,
        'description': sop.description,
        'steps': sop.steps.join('|||'), // Using ||| as separator
        'frequency': sop.frequency.toString().split('.').last,
        'requiresPhoto': sop.requiresPhoto ? 1 : 0,
        'isCritical': sop.isCritical ? 1 : 0,
        'criticalThreshold': sop.criticalThreshold,
        'createdAt': sop.createdAt.toIso8601String(),
        'updatedAt': sop.updatedAt?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SOPModel>> getAllSOPs() async {
    final db = await database;
    final maps = await db.query('sops');
    return maps.map((map) {
      final steps = (map['steps'] as String).split('|||');
      return SOPModel.fromJson({
        'id': map['id'],
        'title': map['title'],
        'description': map['description'],
        'steps': steps,
        'frequency': map['frequency'],
        'requiresPhoto': (map['requiresPhoto'] as int) == 1,
        'isCritical': (map['isCritical'] as int) == 1,
        'criticalThreshold': map['criticalThreshold'],
        'createdAt': map['createdAt'],
        'updatedAt': map['updatedAt'],
      });
    }).toList();
  }

  Future<SOPModel?> getSOPById(String sopId) async {
    final db = await database;
    final maps = await db.query(
      'sops',
      where: 'id = ?',
      whereArgs: [sopId],
    );

    if (maps.isEmpty) return null;
    final map = maps.first;
    final steps = (map['steps'] as String).split('|||');
    return SOPModel.fromJson({
      'id': map['id'],
      'title': map['title'],
      'description': map['description'],
      'steps': steps,
      'frequency': map['frequency'],
      'requiresPhoto': (map['requiresPhoto'] as int) == 1,
      'isCritical': (map['isCritical'] as int) == 1,
      'criticalThreshold': map['criticalThreshold'],
      'createdAt': map['createdAt'],
      'updatedAt': map['updatedAt'],
    });
  }

  // Task operations
  Future<void> insertTask(TaskModel task) async {
    final db = await database;
    await db.insert(
      'tasks',
      {
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'sopid': task.sopid,
        'assignedTo': task.assignedTo,
        'assignedBy': task.assignedBy,
        'status': task.status.toString().split('.').last,
        'frequency': task.frequency.toString().split('.').last,
        'dueDate': task.dueDate?.toIso8601String(),
        'completedAt': task.completedAt?.toIso8601String(),
        'photoUrl': task.photoUrl,
        'rejectionReason': task.rejectionReason,
        'createdAt': task.createdAt.toIso8601String(),
        'verifiedAt': task.verifiedAt?.toIso8601String(),
        'synced': 0, // Not synced yet
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TaskModel>> getTasksByUser(String userId,
      {String? status}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;

    if (status != null) {
      maps = await db.query(
        'tasks',
        where: 'assignedTo = ? AND status = ?',
        whereArgs: [userId, status],
        orderBy: 'createdAt DESC',
      );
    } else {
      maps = await db.query(
        'tasks',
        where: 'assignedTo = ?',
        whereArgs: [userId],
        orderBy: 'createdAt DESC',
      );
    }

    return maps.map((map) => _taskFromMap(map)).toList();
  }

  Future<List<TaskModel>> getVerificationPendingTasks(String managerId) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'assignedBy = ? AND status = ?',
      whereArgs: [managerId, 'verificationPending'],
      orderBy: 'completedAt DESC',
    );

    return maps.map((map) => _taskFromMap(map)).toList();
  }

  Future<void> updateTaskStatus(
    String taskId,
    String status, {
    String? rejectionReason,
    String? photoUrl,
    DateTime? completedAt,
    DateTime? verifiedAt,
  }) async {
    final db = await database;
    final updateData = <String, dynamic>{
      'status': status,
      'synced': 0, // Mark as unsynced
    };

    if (rejectionReason != null) {
      updateData['rejectionReason'] = rejectionReason;
    }
    if (photoUrl != null) {
      updateData['photoUrl'] = photoUrl;
    }
    if (completedAt != null) {
      updateData['completedAt'] = completedAt.toIso8601String();
    }
    if (verifiedAt != null) {
      updateData['verifiedAt'] = verifiedAt.toIso8601String();
    }

    await db.update(
      'tasks',
      updateData,
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<List<TaskModel>> getUnsyncedTasks() async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'synced = ?',
      whereArgs: [0],
    );

    return maps.map((map) => _taskFromMap(map)).toList();
  }

  Future<void> markTaskSynced(String taskId) async {
    final db = await database;
    await db.update(
      'tasks',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  TaskModel _taskFromMap(Map<String, dynamic> map) {
    return TaskModel.fromJson({
      'id': map['id'],
      'title': map['title'],
      'description': map['description'],
      'sopId': map['sopId'],
      'assignedTo': map['assignedTo'],
      'assignedBy': map['assignedBy'],
      'status': map['status'],
      'frequency': map['frequency'],
      'dueDate': map['dueDate'],
      'completedAt': map['completedAt'],
      'photoUrl': map['photoUrl'],
      'rejectionReason': map['rejectionReason'],
      'createdAt': map['createdAt'],
      'verifiedAt': map['verifiedAt'],
    });
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
