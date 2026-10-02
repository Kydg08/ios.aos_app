/// Supabase 접속 정보.
///
/// 빌드 시 `--dart-define` 으로 덮어쓸 수 있습니다.
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
///
/// 아래 기본값은 공개(publishable) 키이므로 클라이언트 앱에 포함해도 됩니다.
/// 데이터 접근 권한은 서버의 RLS 정책이 통제합니다.
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wklbgosbycbphcrggfaq.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_sP5LiCHOpVxz2mA1f0Uh7A_yhKgI6cS',
  );
}
