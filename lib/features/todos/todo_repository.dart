import 'package:supabase_flutter/supabase_flutter.dart';

import 'todo.dart';

/// `public.todos` 테이블에 대한 읽기/쓰기.
///
/// RLS 정책 덕분에 서버가 user_id 를 검사하므로,
/// 쿼리에서 따로 user_id 로 필터링하지 않아도 본인 데이터만 내려옵니다.
class TodoRepository {
  TodoRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'todos';

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('로그인이 필요합니다.');
    }
    return id;
  }

  /// 실시간으로 갱신되는 할 일 목록. 최신 항목이 먼저 옵니다.
  Stream<List<Todo>> watchAll() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(Todo.fromMap).toList(growable: false));
  }

  Future<void> add(String title) async {
    await _client.from(_table).insert({
      'user_id': _userId,
      'title': title.trim(),
    });
  }

  Future<void> setDone(String id, bool isDone) async {
    await _client.from(_table).update({'is_done': isDone}).eq('id', id);
  }

  Future<void> rename(String id, String title) async {
    await _client.from(_table).update({'title': title.trim()}).eq('id', id);
  }

  Future<void> remove(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  Future<void> removeCompleted() async {
    await _client
        .from(_table)
        .delete()
        .eq('user_id', _userId)
        .eq('is_done', true);
  }
}
