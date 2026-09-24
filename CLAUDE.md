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
Four screens total:
1. Sign up / Sign in
2. Week view (the main screen after auth)
3. Log session sheet
4. Profile sheet (email display and sign out)

Plan and log are one flow:
- Tap a day in the Week view to add a planned session.
- Tap a planned session to mark it done and log it. The Log session sheet
  opens pre-filled with the planned session type.

Session types:
- Climb: includes a V-grade (V0 to V17).
- Lift: includes a muscle group focus.
- Rest: no extra fields.

The Log session sheet is a single adaptive form (type picker, then fields
for that type, then save). It is not a multi-step flow.

Out of scope for MVP, do not build or preserve:
- Onboarding beyond auth
- Tiers, scores, streaks, leaderboard
- Stats screen, insights, charts
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
- `lift_exercises JSONB`: read by Progress, not yet written by the app.
  Expected shape:
  `[{"name": "Bench press", "sets": [{"weight_lbs": 185, "reps": 5}]}]`.
  Progress fetches with `select *` so the column may be absent.

Lifter-specific columns (meal_items, meal_time, hydration, pre_workout,
pre_workout_brand, pre_workout_caffeine_mg, and similar) become nullable and
unused. Do not drop any column. They may come back post-MVP, and dropping
data is not reversible.

A single `sessions` table may replace these later. That is post-MVP; for now
make additive changes to the existing tables only.

## Current code state (before MVP restructure)
The repo still reflects the previous lifter-focused product. Describe and
change it; do not treat it as the target.

Entry and routing:
- SyncedApp mounts RootView.
- RootView shows LaunchScreen, then routes on `SessionStore.phase`:
  signed in goes to MainTabView, signed out goes to OnboardingFlow.
- SessionStore (State/SessionStore.swift) owns auth state: `bootstrap()`,
  `markSignedIn()`, `signOut()`.

Onboarding (OnboardingFlow.swift, 5 steps): S1Welcome, S2Value, S3Setup,
SignUpView, S12TierReveal. SignInView is a full-screen cover opened from
S1Welcome's "I already have an account" link. Parked screens (S2ValueIntro,
S3Name, S4Age, S7Goal, S8Frequency, S9Sleep, S8CheckInLoop, S9Notifications)
are out of the flow but still compile.

Main app: MainTabView has Home, Stats, and Learn (EducateView) tabs.
LeaderboardView exists but is not in the tab bar. ProfileView is a sheet
from HomeView. PreLiftCheckInView (multi-step, with a UserDefaults draft)
and PostLiftCheckInView (2 steps) are full-screen sheets from HomeView and
also compute scores and write profile and leaderboard rollups.

Shared UI to reuse:
- Components/: ScreenShell, ProgressHeader, PrimaryButton, SecondaryButton,
  TextLinkButton, SpecInput, SpecSlider, SelectableCard, EyebrowTag, GlowDot,
  PhaseReveal (.phaseFadeUp), AgePicker, LuminousOrb, CheckInCalendarSheet
- DesignSystem/: Tokens (SYN.*, Spacing, Radius), Typography (synDisplay,
  synText, synMono, EyebrowText), Atmosphere, Wordmark

## Do not touch for MVP
- Auth: SignUpView, SignInView, SessionStore. They work.
- The Supabase client singleton and RLS policies.
- DesignSystem/ tokens (colors, typography, spacing, radius), except adding
  a missing token.
- XcodeGen config beyond adding or removing source files.

Known coupling: SignUpView reads `OnboardingModel` from the environment and
uses `ScreenProgress` for its progress bar and "Step N of M" label, and its
`writeProfile()` writes onboarding answers to profiles. When stripping
onboarding, make the smallest change that keeps SignUpView compiling and
working (for example, keep `OnboardingModel` and `ScreenProgress` alive, or
trim `writeProfile()` to id, email, and username). Do not redesign the auth
screens.

## Will change for MVP
- HomeView is replaced by the Week view, the main screen after auth.
- MainTabView is simplified, most likely to no tab bar. Profile becomes a
  sheet from the Week view.
- PreLiftCheckInView and PostLiftCheckInView are gutted and replaced by the
  single adaptive Log session sheet. Their scoring and leaderboard rollup
  code goes with them.
- StatsView, LeaderboardView, EducateView, and every onboarding screen
  except SignUpView and SignInView are removed. Move a file to
  Synced/.parked/ only if it is worth preserving; otherwise delete it.
  project.yml sources `Synced/`, so confirm parked files are excluded from
  the build (or exclude them in project.yml) and run `xcodegen generate`.
- Unused UserDefaults keys (userAge, trainingGoal, sleepBaseline, the
  pre-lift draft) can be removed along with the screens that use them.

## MVP build order
1. Additive DB migration in Supabase: session_type, climb_grade_v,
   is_planned.
2. Strip dead screens (Stats, Leaderboard, Educate, all onboarding screens
   except SignUp and SignIn). Route straight from auth to the Week view; a
   temporary placeholder screen is fine for this step.
3. Build the Week view: 7-day grid, tap a day to plan, tap a planned
   session to log.
4. Build the Log session sheet: type picker, adaptive fields, save.
5. Build the Profile sheet: email display and sign out.
6. Smoke test end to end: sign up, Week view, plan a session, tap to log,
   see it filled in, sign out, sign in, data persists.

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
