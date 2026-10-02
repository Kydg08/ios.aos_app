import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'todo.dart';
import 'todo_repository.dart';

enum _Filter { all, active, done }

/// 할 일 목록 화면. 추가 / 완료 체크 / 수정 / 삭제를 지원합니다.
class TodosPage extends StatefulWidget {
  const TodosPage({super.key});

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  late final TodoRepository _repository;
  late final Stream<List<Todo>> _todos;
  final _inputController = TextEditingController();
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _repository = TodoRepository(Supabase.instance.client);
    _todos = _repository.watchAll();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, {String? failure}) async {
    try {
      await action();
    } on PostgrestException catch (e) {
      _showError(failure ?? e.message);
    } catch (_) {
      _showError(failure ?? '작업에 실패했습니다. 네트워크를 확인해 주세요.');
    }
  }

  void _showError(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
  }

  Future<void> _addTodo() async {
    final title = _inputController.text.trim();
    if (title.isEmpty) return;
    _inputController.clear();
    await _run(() => _repository.add(title), failure: '할 일을 추가하지 못했습니다.');
  }

  Future<void> _editTodo(Todo todo) async {
    final controller = TextEditingController(text: todo.title);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할 일 수정'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 200,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(context).pop(value),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    controller.dispose();

    final title = result?.trim() ?? '';
    if (title.isEmpty || title == todo.title) return;
    await _run(() => _repository.rename(todo.id, title),
        failure: '수정하지 못했습니다.');
  }

  Future<void> _deleteTodo(Todo todo) async {
    await _run(() => _repository.remove(todo.id), failure: '삭제하지 못했습니다.');
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('"${todo.title}" 삭제됨')));
  }

  Future<void> _clearCompleted(int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('완료된 항목 삭제'),
        content: Text('완료된 할 일 $count개를 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(_repository.removeCompleted, failure: '삭제하지 못했습니다.');
  }

  Future<void> _signOut() async {
    await _run(() => Supabase.instance.client.auth.signOut(),
        failure: '로그아웃하지 못했습니다.');
  }

  List<Todo> _applyFilter(List<Todo> todos) {
    return switch (_filter) {
      _Filter.all => todos,
      _Filter.active => todos.where((t) => !t.isDone).toList(),
      _Filter.done => todos.where((t) => t.isDone).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('할 일'),
        actions: [
          PopupMenuButton<String>(
            tooltip: '계정',
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) {
              if (value == 'signout') _signOut();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(email, overflow: TextOverflow.ellipsis),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'signout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('로그아웃'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _AddTodoBar(controller: _inputController, onSubmit: _addTodo),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<_Filter>(
              segments: const [
                ButtonSegment(value: _Filter.all, label: Text('전체')),
                ButtonSegment(value: _Filter.active, label: Text('진행 중')),
                ButtonSegment(value: _Filter.done, label: Text('완료')),
              ],
              selected: {_filter},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Todo>>(
              stream: _todos,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _Message(
                    icon: Icons.cloud_off,
                    title: '목록을 불러오지 못했습니다',
                    subtitle: '네트워크 연결과 Supabase 설정을 확인해 주세요.',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all = snapshot.data!;
                final visible = _applyFilter(all);
                final doneCount = all.where((t) => t.isDone).length;

                if (all.isEmpty) {
                  return const _Message(
                    icon: Icons.task_alt,
                    title: '아직 할 일이 없습니다',
                    subtitle: '위 입력창에 첫 번째 할 일을 추가해 보세요.',
                  );
                }
                if (visible.isEmpty) {
                  return const _Message(
                    icon: Icons.filter_list_off,
                    title: '해당하는 항목이 없습니다',
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final todo = visible[index];
                          return _TodoTile(
                            key: ValueKey(todo.id),
                            todo: todo,
                            onToggle: (value) => _run(
                              () => _repository.setDone(todo.id, value),
                              failure: '상태를 변경하지 못했습니다.',
                            ),
                            onEdit: () => _editTodo(todo),
                            onDelete: () => _deleteTodo(todo),
                          );
                        },
                      ),
                    ),
                    _Footer(
                      total: all.length,
                      done: doneCount,
                      onClearCompleted:
                          doneCount == 0 ? null : () => _clearCompleted(doneCount),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTodoBar extends StatelessWidget {
  const _AddTodoBar({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: 200,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              decoration: const InputDecoration(
                hintText: '새 할 일 입력',
                counterText: '',
                prefixIcon: Icon(Icons.add_task),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onSubmit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Todo todo;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey('dismiss-${todo.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        color: theme.colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
      ),
      child: CheckboxListTile(
        value: todo.isDone,
        onChanged: (value) => onToggle(value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          todo.title,
          style: todo.isDone
              ? TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : null,
        ),
        secondary: IconButton(
          tooltip: '수정',
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.total,
    required this.done,
    required this.onClearCompleted,
  });

  final int total;
  final int done;
  final VoidCallback? onClearCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '$total개 중 $done개 완료',
                style: theme.textTheme.bodyMedium,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onClearCompleted,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('완료 항목 삭제'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
