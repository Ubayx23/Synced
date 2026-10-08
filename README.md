# Synced

Plan the week. Send the project.

Synced is an iOS training planner for climbers who also do supporting strength work. Users program their week (climb days, lift days, rest days) and log each session as it happens.

## Status

- iPhone only, iOS 17+, portrait, dark mode only.
- On TestFlight. Cohort 1 open for internal testing.
- Bundle id: `page.synced.app`.

## Stack

- SwiftUI with `@Observable` state
- Supabase (auth, plus Postgres with Row Level Security)
- MuscleMap for the Recovery anatomy view; small charts are drawn in SwiftUI
- XcodeGen for project generation: `project.yml` is the source of truth, `Synced.xcodeproj` is generated and gitignored
- Geist and Geist Mono bundled fonts, accessed only through `Font.synDisplay`, `synText`, and `synMono`
- No CocoaPods, no other SPM packages

## Screens

1. **Welcome**: signed-out entry with Create account and I already have an account.
2. **Sign up / Sign in**: email and password, with a password requirements checklist on Sign up and Forgot password? on Sign in.
3. **Week** (first tab): Monday to Sunday, chevrons to move between weeks; tap a day to plan, tap a planned session to log it.
4. **Recovery** (second tab): front and back anatomy map; muscles glow cyan when ready and turn gray when recently worked, from logged lifts and climbs over the last 14 days.
5. **Progress** (third tab): headline, climb grade pyramid, and lift trend cards with session-over-session deltas.
6. **Sheets**: Plan session, Log session (adapts to climb, lift, or rest), and Profile (daily reminder toggle and time, and sign out).

## Data model

Two tables matter. `profiles` holds id (FK to `auth.users`), email, and timestamps. `sessions` holds one row per planned or logged session: `session_type` (`climb`, `lift`, or `rest`), `scheduled_date`, `is_planned`, and type-specific columns (`climb_grades_sent`, `climb_grade_v`, `muscle_groups`, `lift_exercises` JSONB, `rating`, `notes`). Row Level Security ensures users only see their own rows. The full column list and the JSONB shape live in [CLAUDE.md](CLAUDE.md).

## Getting started

```bash
brew install xcodegen
git clone <repo>
cd Synced
xcodegen generate
open Synced.xcodeproj
```

Xcode resolves the Supabase package on first open. To run on a device, set your own team under Signing & Capabilities, or change `DEVELOPMENT_TEAM` in `project.yml`.

Re-run `xcodegen generate` whenever `project.yml` changes or files are added, removed, or moved. Editing existing files does not need it. Never hand-edit `project.pbxproj`.

## Deployment

Xcode Cloud watches `main` and builds on every push. `ci_scripts/ci_post_clone.sh` installs XcodeGen, generates the project, and copies the committed `Package.resolved` into the workspace. Builds land in App Store Connect and appear in TestFlight after processing. Xcode Cloud assigns the build number on each archive through `CI_BUILD_NUMBER` (local builds use 1). The user-facing version is `MARKETING_VERSION` in `project.yml` (currently `0.1.0`); the generated `Info.plist` reads both from build settings.

## Repo layout

```
project.yml                XcodeGen spec
Package.resolved           Pinned SPM versions, copied in by CI
Synced.xcodeproj/          Generated, gitignored
Synced/
  SyncedApp.swift          @main; mounts RootView
  App/                     RootView, MainTabView, NotificationRouting,
                           SupabaseClient
  Screens/                 LaunchScreen
  Features/
    Auth/                  WelcomeView, SignUpView, SignInView
    Week/                  WeekView, WeekStore, PlanSessionSheet,
                           LogSessionSheet, ExercisesEditor
    Recovery/              RecoveryView, RecoveryStore, Muscles,
                           ExerciseCatalog, BodyModel
    Progress/              ProgressScreen, ProgressStore, MiniBarChart
    Profile/               ProfileSheet
    Reminders/             ReminderScheduler
  State/                   SessionStore (auth state)
  Components/              ScreenShell, buttons, SpecInput, FlowLayout,
                           LuminousOrb, PhaseReveal, and other primitives
  DesignSystem/            Tokens (SYN.*), Typography, Atmosphere, Wordmark
  Resources/Fonts/         Geist and Geist Mono
  Assets.xcassets/         App icon, colors
  Info.plist               Generated from project.yml
ci_scripts/                Xcode Cloud hooks
DesignReference/           Historical design handoff, not shipped
CLAUDE.md                  Engineering reference: schema, rules, conventions
README.md                  This file
```

## House rules

- No em dashes anywhere in copy or comments.
- Feature branches only; never commit directly to `main`.

The full engineering rules (design tokens, XcodeGen policy, schema constraints, do-not-touch list) live in [CLAUDE.md](CLAUDE.md).

## Where it's headed

Cohort 1 external TestFlight beta, then a hard-paywall Pro tier covering long-term progression, exercise-level trends, and HealthKit sync. Notifications (a daily log nudge and a weekly recap) are the next major addition. Not on the roadmap: tiers, scores, streaks as gamification, or a leaderboard.
