# 할 일 (Todo) 앱 — Flutter + Supabase

iOS와 Android에서 동작하는 할 일 관리 앱입니다.
이메일 로그인 후 할 일을 추가 / 완료 / 수정 / 삭제할 수 있고,
Supabase에 저장되어 여러 기기에서 실시간으로 동기화됩니다.

## 기술 스택

| 영역 | 선택 |
|------|------|
| 프레임워크 | Flutter 3.47 (Dart 3.13) |
| 백엔드 | Supabase (Auth + Postgres + Realtime) |
| 상태 관리 | Supabase Stream + `StreamBuilder` (추가 라이브러리 없음) |
| 디자인 | Material 3, 라이트 / 다크 테마 자동 |

## 프로젝트 구조

```
lib/
├── main.dart                        # 앱 진입점, Supabase 초기화, 테마
├── core/
│   └── supabase_config.dart         # Supabase URL / 공개 키
└── features/
    ├── auth/
    │   ├── auth_gate.dart           # 로그인 여부에 따라 화면 분기
    │   └── login_page.dart          # 이메일 로그인 / 회원가입
    └── todos/
        ├── todo.dart                # 데이터 모델
        ├── todo_repository.dart     # Supabase CRUD + 실시간 스트림
        └── todos_page.dart          # 목록 화면 UI
supabase/
└── migrations/
    └── 20261002000000_create_todos.sql   # 테이블, RLS 정책, Realtime
test/
└── todo_test.dart
```

## 시작하기

### 1. Supabase 테이블 만들기 (최초 1회)

`supabase/migrations/20261002000000_create_todos.sql` 내용을
[Supabase 대시보드](https://supabase.com/dashboard) → **SQL Editor** 에 붙여넣고 실행하세요.

- `todos` 테이블 생성
- RLS 정책: 로그인한 사용자가 **본인 데이터만** 읽고 쓸 수 있음
- Realtime 발행 등록 (기기 간 실시간 동기화)

### 2. Flutter 환경 준비

- [Flutter 설치](https://docs.flutter.dev/get-started/install)
- Android: Android Studio + 에뮬레이터 또는 실기기
- iOS: macOS + Xcode (Mac에서만 빌드 가능)

```bash
flutter doctor        # 환경 점검
flutter pub get       # 의존성 설치
```

### 3. 실행

```bash
flutter run
```

다른 Supabase 프로젝트를 쓰려면 빌드 시 값을 덮어쓸 수 있습니다.

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxxx
```

### 4. 검사 / 테스트

```bash
flutter analyze
flutter test
```

## 회원가입 시 이메일 인증

Supabase 기본 설정은 가입 후 **이메일 인증**이 필요합니다.
개발 중 바로 로그인하고 싶다면
대시보드 → **Authentication → Providers → Email → Confirm email** 을 끄세요.

## 다음 단계 아이디어

- 소셜 로그인 (Google, Apple)
- 마감일 / 알림
- 오프라인 캐시
- 앱 아이콘 / 스플래시 화면 (`flutter_launcher_icons`, `flutter_native_splash`)
