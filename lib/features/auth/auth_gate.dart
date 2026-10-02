import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../todos/todos_page.dart';
import 'login_page.dart';

/// 로그인 상태에 따라 로그인 화면 또는 할 일 목록을 보여줍니다.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session =
            snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return const LoginPage();
        }
        return const TodosPage();
      },
    );
  }
}
