import 'package:clear_translate/domain/entities/history_record.dart';
import 'package:clear_translate/domain/repositories/history_repository.dart';

class FakeHistoryRepository implements HistoryRepository {
  final records = <HistoryRecord>[];

  @override
  Future<void> add(HistoryRecord record) async {
    records.insert(0, record);
  }

  @override
  Future<void> clear() async {
    records.clear();
  }

  @override
  Future<void> delete(String id) async {
    records.removeWhere((record) => record.id == id);
  }

  @override
  Future<List<HistoryRecord>> listRecent() async {
    return List.unmodifiable(records);
  }
}
