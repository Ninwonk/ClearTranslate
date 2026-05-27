import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/history_record.dart';
import '../../domain/repositories/history_repository.dart';

class LocalHistoryRepository implements HistoryRepository {
  LocalHistoryRepository({Directory? historyDirectory})
      : _historyDirectory = historyDirectory;

  static const _historyFileName = 'history_records.json';
  static const _maxRecords = 500;

  final Directory? _historyDirectory;

  @override
  Future<List<HistoryRecord>> listRecent() async {
    final records = await _readRecords();
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  @override
  Future<void> add(HistoryRecord record) async {
    final records = await _readRecords();
    final nextRecords = [
      record,
      ...records.where((item) => item.id != record.id),
    ].take(_maxRecords).toList();
    await _writeRecords(nextRecords);
  }

  @override
  Future<void> delete(String id) async {
    final records = await _readRecords();
    await _writeRecords(records.where((record) => record.id != id).toList());
  }

  @override
  Future<void> clear() async {
    await _writeRecords([]);
  }

  Future<List<HistoryRecord>> _readRecords() async {
    final file = await _historyFile();
    if (!await file.exists()) {
      return [];
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return [];
    }

    final decoded = jsonDecode(content);
    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map((json) => HistoryRecord.fromJson(Map<String, Object?>.from(json)))
        .toList();
  }

  Future<void> _writeRecords(List<HistoryRecord> records) async {
    final file = await _historyFile();
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(
      encoder.convert(records.map((record) => record.toJson()).toList()),
    );
  }

  Future<File> _historyFile() async {
    final directory =
        _historyDirectory ?? await getApplicationSupportDirectory();
    return File(p.join(directory.path, _historyFileName));
  }
}
