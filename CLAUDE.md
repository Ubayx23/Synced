# Synced: Claude Code Reference

## What this app is
Synced is a training planner for climbers who also do supporting strength
work. The user programs their week (climb days, lift days, rest days) and
logs each session as they do it.

Positioning: "Plan the week. Send the project." The canonical source for
positioning and copy tone is synced.page. If this doc and the site disagree
on product voice, the site wins.

iPhone only, iOS 17+, portrait only, dark only. Pre-launch, with the Cohort 1
beta open.

## Rules
- No em dashes anywhere in copy or comments. Use "and", a comma, or rewrite
  the sentence. This is a house style rule and applies to every file.
- Confirm the current git branch before making any changes. Work lands on
  feature branches, never directly on main.
- Never modify project.pbxproj by hand. Edit project.yml and run
  `xcodegen generate`. The .xcodeproj is generated output and is gitignored;
  hand edits are lost on the next generate and break Xcode Cloud.
- Use existing SYN.* colors, Spacing, and Radius tokens. Do not introduce new
  hex values, font sizes, or spacing constants outside DesignSystem/. If a
  token is missing, add it to DesignSystem/ first, then use it. This keeps
  the visual language consistent while screens are being rebuilt.
- Test layouts at iPhone 15 Pro width (393pt).
- Never use lorem ipsum or placeholder copy in a shipped screen. A temporary
  placeholder screen during a build step is fine if its copy is real.

## Design is not locked
The UI is actively being restructured for the MVP. Removing screens,
replacing HomeView, dropping the tab bar, and redesigning layouts are all
expected. Briefs that say "rip out X" or "replace Y" are consistent with this
doc; execute them.

What stays fixed is the design language, not the layouts: dark surfaces,
cyan accent, Geist type, and the existing tokens and components. New screens
should look like they belong to the same app.

## MVP scope (v0.1, "ugly launch")
Screens:
1. Welcome (signed-out entry: Create account or I already have an account)
2. Sign up / Sign in (pushed from Welcome)
3. Week (tab 1): one Monday to Sunday week, chevrons to move between weeks
4. Progress (tab 2): headline, climb grade pyramid, lift trend cards, footer
5. Plan session sheet, Log session sheet, Profile sheet

Plan and log are one flow:
- Tap a day in the Week view to add a planned session.
- Tap a planned session to mark it done and log it. The Log session sheet
  opens pre-filled with the planned session type. Log now logs for today.

Session types:
- Climb: one or more sends, each a V-grade (V0 to V17).
- Lift: one or more muscle groups, plus optional exercises with sets of
  weight (lbs) and reps.
- Rest: no extra fields.

The Log session sheet is a single adaptive form (type picker, then fields
for that type, then save). It is not a multi-step flow.

Out of scope for MVP, do not build or preserve:
- Onboarding beyond Welcome and auth
- Tiers, scores, streaks, leaderboard
- Insights feeds
- Learn tab
- HealthKit
- Readiness inputs: sleep, food, meal timing, hydration, pre-workout

## Tech stack
- SwiftUI, iOS 17+, Swift 5.10
- @Observable for state
- XcodeGen: project.yml is the source of truth for the Xcode project
- Supabase Swift SDK (the only SPM dependency) for auth and data
- Geist and Geist Mono, bundled in Synced/Resources/Fonts and registered via
  UIAppFonts in project.yml. Always go through `Font.synDisplay`,
  `Font.synText`, and `Font.synMono`; never reference a font name directly.
- No new dependencies without explicit instruction.

## Supabase
Project URL: https://olkjemjxsuabmxuqtzsf.supabase.co
The client is a module-level `let supabase` in Synced/App/SupabaseClient.swift,
initialized with the anon key. That pattern works and is what the app uses;
do not refactor it.

The service role key never goes in client code.

## Database
RLS is enabled on every table. Users own their own rows (auth.uid() checks).
A `handle_new_user()` trigger creates a profiles row on every new auth.users
insert.

Tables:
- profiles: id (FK auth.users), username, email, training_goal,
  training_frequency, sleep_baseline, tier, score, streak, timestamps.
  For MVP only id, username, and email matter.
- pre_lift_checkins, post_lift_checkins: repurposed as session storage for
  MVP (see migration below). post_lift_checkins links to its pre-lift row
  via pre_lift_id.
- leaderboard_entries, waitlist: exist but are unwired for MVP. Leave their
  schema alone.

### Session columns in use (pre_lift_checkins, one row per session)
- `session_type TEXT`: 'climb', 'lift', 'rest'
- `scheduled_date DATE`: the day the session belongs to, written as
  yyyy-MM-dd in the device time zone
- `is_planned BOOLEAN DEFAULT false`: true until the session is logged
- `climb_grades_sent INTEGER[]`: one entry per send, e.g. [2, 2, 3]
- `climb_grade_v INTEGER`: mirrors max(climb_grades_sent)
- `muscle_groups TEXT[]`: lift focus, e.g. ['chest', 'arms']
- `rating INTEGER` (1 to 5, optional), `notes TEXT` (optional)
- `lift_exercises JSONB`: written by the Log sheet, read by Progress and
  by the exercise suggestions. Shape:
  `[{"name": "Bench press", "muscle_group": "chest", "sets": [{"weight_lbs": 185, "reps": 5}]}]`.
  `muscle_group` ties each exercise to one group for suggestions; older
  entries omit it and fall back to the session's muscle_groups.

Lifter-specific columns (meal_items, meal_time, hydration, pre_workout,
pre_workout_brand, pre_workout_caffeine_mg, and similar) become nullable and
unused. Do not drop any column. They may come back post-MVP, and dropping
data is not reversible.

A single `sessions` table may replace these later. That is post-MVP; for now
make additive changes to the existing tables only.

## Current code state
Entry and routing:
- SyncedApp mounts RootView.
- RootView shows LaunchScreen, then routes on `SessionStore.phase`:
  signed in goes to MainTabView; signed out goes to a NavigationStack rooted
  at WelcomeView, which pushes SignUpView or SignInView. The nav bar is
  hidden; each auth screen has its own back chevron back to Welcome, and
  each links to the other.
- SessionStore (State/SessionStore.swift) owns auth state: `bootstrap()`,
  `markSignedIn()`, `signOut()`.

Main app (Features/):
- MainTabView (App/): Week and Progress tabs. Each tab's header has the
  profile icon that opens ProfileSheet.
- Week/: WeekView, WeekStore (fetch, plan, log, delete), PlanSessionSheet,
  LogSessionSheet, ExercisesEditor.
- Progress/: ProgressScreen and ProgressStore (one fetch, all aggregation
  client side).
- Profile/: ProfileSheet (sign out).
- Auth/: WelcomeView, SignUpView, SignInView.

Shared UI to reuse:
- Components/: ScreenShell, ProgressHeader, PrimaryButton, SecondaryButton,
  TextLinkButton, SpecInput, SpecSlider, SelectableCard, EyebrowTag, GlowDot,
  PhaseReveal (.phaseFadeUp), AgePicker, LuminousOrb, FlowLayout
- DesignSystem/: Tokens (SYN.*, Spacing, Radius), Typography (synDisplay,
  synText, synMono, EyebrowText), Atmosphere, Wordmark

## Do not touch for MVP
- SessionStore, SignUpView's `writeProfile()`, and the Sign in with Apple
  scaffolding. Auth screen layout can change; the auth flow itself should
  not.
- The Supabase client singleton and RLS policies.
- DesignSystem/ tokens (colors, typography, spacing, radius), except adding
  a missing token.
- XcodeGen config beyond adding or removing source files.

## Build and CI
- `brew install xcodegen && xcodegen generate && open Synced.xcodeproj`
- Xcode Cloud runs ci_scripts/ci_post_clone.sh, which installs XcodeGen,
  generates the project, and copies the root Package.resolved into the
  workspace. Package.resolved is committed on purpose (force-added past
  .gitignore); keep it in sync when SPM versions change.
- Bundle id: page.synced.app. Do not change it.

## Git conventions
- Main branch: main. Feature branches: feat/description.
- Commit format: "type: description", for example
  "feat: week view with tap-to-plan".
