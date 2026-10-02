/// 할 일 한 건. `public.todos` 테이블의 한 행과 대응됩니다.
class Todo {
  const Todo({
    required this.id,
    required this.userId,
    required this.title,
    required this.isDone,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final bool isDone;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      isDone: map['is_done'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
    );
  }

  Todo copyWith({String? title, bool? isDone}) {
    return Todo(
      id: id,
      userId: userId,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
