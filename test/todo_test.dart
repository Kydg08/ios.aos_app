import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todos/todo.dart';

void main() {
  group('Todo.fromMap', () {
    test('Supabase 행을 모델로 변환한다', () {
      final todo = Todo.fromMap({
        'id': 'abc',
        'user_id': 'user-1',
        'title': '우유 사기',
        'is_done': true,
        'created_at': '2026-10-02T09:00:00+00:00',
        'updated_at': '2026-10-02T10:00:00+00:00',
      });

      expect(todo.id, 'abc');
      expect(todo.userId, 'user-1');
      expect(todo.title, '우유 사기');
      expect(todo.isDone, isTrue);
      expect(todo.createdAt.isUtc, isFalse);
    });

    test('is_done 이 없으면 false 로 처리한다', () {
      final todo = Todo.fromMap({
        'id': 'abc',
        'user_id': 'user-1',
        'title': '제목',
        'created_at': '2026-10-02T09:00:00Z',
        'updated_at': '2026-10-02T09:00:00Z',
      });
      expect(todo.isDone, isFalse);
    });

    test('copyWith 는 지정한 필드만 바꾼다', () {
      final todo = Todo.fromMap({
        'id': 'abc',
        'user_id': 'user-1',
        'title': '제목',
        'is_done': false,
        'created_at': '2026-10-02T09:00:00Z',
        'updated_at': '2026-10-02T09:00:00Z',
      });
      final updated = todo.copyWith(isDone: true);
      expect(updated.isDone, isTrue);
      expect(updated.title, '제목');
      expect(updated.id, 'abc');
    });
  });
}
