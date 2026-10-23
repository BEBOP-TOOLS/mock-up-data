-- BEBOP Spec Sheet Maker · Supabase 초기 설정
-- Supabase 대시보드 → SQL Editor → 붙여넣고 Run (한 번만)

-- @bebop.kr 구글 계정만 허용
create or replace function public.is_bebop() returns boolean
language sql stable as $$
  select lower(coalesce(auth.jwt() ->> 'email', '')) like '%@bebop.kr'
$$;

-- 프로젝트 목록 (Open 창에 보이는 정보)
create table if not exists public.projects (
  id          text primary key,
  name        text not null default 'Untitled',
  pages       int  not null default 0,
  saved_at    timestamptz not null default now(),
  saved_by    text,
  editing_by  text,          -- 지금 편집 중인 사람
  editing_at  timestamptz
);

alter table public.projects enable row level security;

drop policy if exists "bebop only" on public.projects;
create policy "bebop only" on public.projects
  for all to authenticated
  using (public.is_bebop()) with check (public.is_bebop());

-- 프로젝트 본문 (캡처 이미지 포함 JSON) 은 Storage 에 저장
insert into storage.buckets (id, name, public)
values ('docs', 'docs', false)
on conflict (id) do nothing;

drop policy if exists "bebop docs" on storage.objects;
create policy "bebop docs" on storage.objects
  for all to authenticated
  using (bucket_id = 'docs' and public.is_bebop())
  with check (bucket_id = 'docs' and public.is_bebop());
