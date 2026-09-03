-- build-task shared history — run this once in your new Supabase project's SQL editor.
--
-- One row per finished run, from every project that has the plugin installed.
-- Deliberately append-and-read only: there is no update or delete policy, so
-- past entries physically cannot be edited or removed through the anon key.
-- That is the "strictly read-only" rule enforced by the database itself rather
-- than by an instruction a session could ignore.

create table if not exists build_runs (
  id                bigint generated always as identity primary key,
  logged_at         timestamptz not null default now(),

  -- which project, and which task
  repo              text        not null,   -- "owner/name", or the folder name
  task              text        not null,   -- the task folder name
  run_date          date,

  -- the shape of the run
  verdict           text,                   -- feasible | blocked | needs-a-decision
  phases_completed  text[],                 -- e.g. {0,1,2,3,4,5}
  small_mode        boolean     default false,
  browser           boolean     default false,
  effort_signal     text,                   -- one line, or 'none'
  cost_usd          numeric(10,2),          -- rough estimate, may be null
  files_changed     integer,

  -- what was learned (this is the part another project can read back)
  contradictions    text,                   -- what contradicted the prompt file
  lessons           text[],                 -- up to 3 short lines
  landmines         text[]                  -- fragile things noticed, not touched
);

create index if not exists build_runs_repo_idx     on build_runs (repo);
create index if not exists build_runs_logged_idx   on build_runs (logged_at desc);

alter table build_runs enable row level security;

-- Append and read only. No update policy, no delete policy — on purpose.
drop policy if exists "append runs" on build_runs;
create policy "append runs" on build_runs
  for insert to anon
  with check (true);

drop policy if exists "read runs" on build_runs;
create policy "read runs" on build_runs
  for select to anon
  using (true);
