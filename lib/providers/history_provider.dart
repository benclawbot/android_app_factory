import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_record.dart';

class HistoryProvider extends ChangeNotifier {
  static const _fileName = 'android_app_factory_history.json';
  static const _maxRecords = 50;

  List<AppRecord> _records = [];
  bool _loaded = false;

  List<AppRecord> get records => _records;
  bool get isEmpty => _records.isEmpty;
  bool get isLoaded => _loaded;

  HistoryProvider() {
    _load();
  }

  // ── Persistence ─────────────────────────────────────────────────────────────

  Future<File> _historyFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _load() async {
    try {
      final file = await _historyFile();
      if (!await file.exists()) {
        _loaded = true;
        notifyListeners();
        return;
      }
      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List<dynamic>;
      _records = list
          .map((e) => AppRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      // Sort newest first
      _records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      // Corrupt file — start fresh
      _records = [];
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final file = await _historyFile();
      final json = jsonEncode(_records.map((r) => r.toJson()).toList());
      await file.writeAsString(json);
    } catch (_) {
      // Best-effort — silently ignore write errors
    }
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Add a new record (called after successful generation).
  Future<void> addRecord(AppRecord record) async {
    _records.insert(0, record);
    // Prune oldest records beyond limit
    if (_records.length > _maxRecords) {
      _records = _records.sublist(0, _maxRecords);
    }
    notifyListeners();
    await _save();
  }

  /// Replace an existing record after an update (matched by id).
  Future<void> updateRecord(AppRecord record) async {
    final idx = _records.indexWhere((r) => r.id == record.id);
    if (idx == -1) return;
    _records[idx] = record;
    // Re-sort so updated record floats to top
    _records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
    await _save();
  }

  /// Delete a record; optionally remove files from disk.
  Future<void> deleteRecord(String id, {bool deleteFiles = false}) async {
    final record = _records.firstWhere(
      (r) => r.id == id,
      orElse: () => throw StateError('Record $id not found'),
    );

    if (deleteFiles) {
      try {
        final dir = Directory(record.outputPath);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (_) {
        // Don't block the delete if file removal fails
      }
    }

    _records.removeWhere((r) => r.id == id);
    notifyListeners();
    await _save();
  }

  /// Lookup by id — returns null if not found.
  AppRecord? findById(String id) {
    try {
      return _records.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
