import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 이메일 + 비밀번호 로그인 / 회원가입 화면.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isSignUp) {
        final response =
            await _client.auth.signUp(email: email, password: password);
        if (!mounted) return;
        // 이메일 인증이 켜져 있으면 세션 없이 user 만 반환됩니다.
        if (response.session == null) {
          _showMessage('가입 확인 메일을 보냈습니다. 메일함을 확인해 주세요.');
          setState(() => _isSignUp = false);
        }
      } else {
        await _client.auth.signInWithPassword(email: email, password: password);
      }
    } on AuthException catch (e) {
      _showMessage(_friendlyAuthMessage(e), isError: true);
    } catch (_) {
      _showMessage('네트워크 오류가 발생했습니다. 다시 시도해 주세요.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyAuthMessage(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    }
    if (message.contains('email not confirmed')) {
      return '이메일 인증이 아직 완료되지 않았습니다.';
    }
    if (message.contains('already registered')) {
      return '이미 가입된 이메일입니다.';
    }
    if (message.contains('rate limit')) {
      return '요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.';
    }
    return e.message;
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: isError ? scheme.error : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 72,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '할 일',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSignUp ? '새 계정을 만들어 시작하세요' : '로그인하여 할 일을 동기화하세요',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: '이메일',
                          prefixIcon: Icon(Icons.mail_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return '이메일을 입력해 주세요.';
                          if (!v.contains('@') || !v.contains('.')) {
                            return '올바른 이메일 형식이 아닙니다.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_isLoading,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: '비밀번호',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword ? '비밀번호 보기' : '비밀번호 숨기기',
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').isEmpty) return '비밀번호를 입력해 주세요.';
                          if (_isSignUp && value!.length < 6) {
                            return '비밀번호는 6자 이상이어야 합니다.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isSignUp ? '회원가입' : '로그인'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(_isSignUp
                            ? '이미 계정이 있으신가요? 로그인'
                            : '계정이 없으신가요? 회원가입'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
