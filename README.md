# One Shot: Nerve Runner

Fast neon-dark action survival built with Flutter, Flame, Forge2D, Rive-ready
animation architecture, low-latency reactive audio, local saves, and
Supabase-backed cloud save sync.

## Run

```sh
flutter pub get
flutter run -d chrome
```

The Supabase publishable client config is wired through Dart environment values
and has project defaults checked in for local play:

```sh
flutter run -d chrome \
  --dart-define=NEXT_PUBLIC_SUPABASE_URL=https://gjbqjhlwowsfxfelrmbo.supabase.co \
  --dart-define=NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_vrLet83r4IW6hIGiqQAcMw_3tJb1hVY
```

## Backend

Remote saves use anonymous Supabase auth and the
`public.nerve_runner_profiles` table. Apply the migration before expecting
remote sync:

```sh
supabase db push
```

Migration file:

```text
supabase/migrations/20260521170000_create_nerve_runner_profiles.sql
```

The game is local-first. If Supabase auth, networking, or the save table is not
available, play continues using `SharedPreferences` and sync resumes once the
backend is ready.

## Verify

```sh
bash scripts/verify.sh
```

The verification gate installs dependencies, runs static analysis, executes the
test suite, and builds the release web artifact. GitHub Actions runs the same
script on pushes and pull requests to `main`.
