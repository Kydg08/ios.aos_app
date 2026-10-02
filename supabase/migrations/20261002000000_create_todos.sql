-- Todo 앱용 테이블
-- Supabase 대시보드 > SQL Editor 에 붙여넣어 실행하거나,
-- `supabase db push` 로 적용하세요.

create table if not exists public.todos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 200),
  is_done boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists todos_user_id_created_at_idx
  on public.todos (user_id, created_at desc);

-- updated_at 자동 갱신
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists todos_set_updated_at on public.todos;
create trigger todos_set_updated_at
  before update on public.todos
  for each row execute function public.set_updated_at();

-- 행 단위 보안(RLS): 로그인한 사용자가 본인 데이터만 접근
alter table public.todos enable row level security;

drop policy if exists "todos_select_own" on public.todos;
create policy "todos_select_own" on public.todos
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "todos_insert_own" on public.todos;
create policy "todos_insert_own" on public.todos
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "todos_update_own" on public.todos;
create policy "todos_update_own" on public.todos
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "todos_delete_own" on public.todos;
create policy "todos_delete_own" on public.todos
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- 실시간 동기화(Realtime) 활성화
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'todos'
  ) then
    alter publication supabase_realtime add table public.todos;
  end if;
end $$;
