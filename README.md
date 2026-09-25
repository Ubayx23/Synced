# Synced

**Plan the week. Send the project.**

Synced is an iPhone training planner for climbers who also do supporting strength work. You program your week (climb days, lift days, rest days), then log each session as you do it. Over time the Progress tab shows your climbing grades and lift numbers moving.

Status: pre-launch, with the Cohort 1 beta open. This is the v0.1 "ugly launch" MVP. The product voice and positioning live at [synced.page](https://synced.page).

iPhone only, iOS 17+, portrait only, dark only.

---

## Table of contents

- [What the app does](#what-the-app-does)
- [Tech stack](#tech-stack)
- [Getting started](#getting-started)
- [Repo layout](#repo-layout)
- [App architecture](#app-architecture)
- [Screens](#screens)
- [Data model](#data-model)
- [Design system](#design-system)
- [Components](#components)
- [Build and CI](#build-and-ci)
- [Conventions](#conventions)
- [Out of scope for the MVP](#out-of-scope-for-the-mvp)

---

## What the app does

1. **Plan.** Open the Week view, tap a day, and add a planned session: Climb, Lift, or Rest.
2. **Log.** Tap a planned session to mark it done. The Log session sheet opens pre-filled with that session type. **Log now** logs a session for today without planning it first.
3. **Track.** The Progress tab turns logged sessions into a climb grade pyramid, lift trend cards, and a short summary.

Session types:

| Type  | What you log                                                                 |
|-------|------------------------------------------------------------------------------|
| Climb | One or more sends, each a V-grade (V0 to V17)                                |
| Lift  | One or more muscle groups, plus optional exercises with sets of weight (lbs) and reps |
| Rest  | Nothing extra                                                                |

Every session can also carry an optional 1 to 5 rating and notes.

---

## Tech stack

- **SwiftUI**, iOS 17+, **Swift 5.10**, `@Observable` for state.
- **Swift Charts** (Apple framework) for Progress charts.
- **Supabase Swift SDK** for auth and data. It is the only SPM dependency; do not add others without a clear reason.
- **XcodeGen**: `project.yml` is the source of truth. `Synced.xcodeproj` is generated and gitignored. Never hand-edit `project.pbxproj`.
- **Geist and Geist Mono** fonts, bundled in `Synced/Resources/Fonts` and registered via `UIAppFonts` in `project.yml`.
- Bundle id: `page.synced.app`.

---

## Getting started

```bash
# 1. Install XcodeGen
brew install xcodegen

# 2. Generate the Xcode project from project.yml
xcodegen generate

# 3. Open in Xcode
open Synced.xcodeproj
```

Re-run `xcodegen generate` whenever you add or remove source files or edit `project.yml`.

The app talks to the hosted Supabase project out of the box (the anon key is in `Synced/App/SupabaseClient.swift`). Create an account from the Welcome screen to start planning.

---

## Repo layout

```
project.yml                     XcodeGen spec, single source of truth for the project
Package.resolved                Pinned SPM versions, committed on purpose for Xcode Cloud
ci_scripts/ci_post_clone.sh     Xcode Cloud setup: installs XcodeGen, generates the project
CLAUDE.md                       Working rules and reference for coding agents
Synced/
  SyncedApp.swift               @main entry point; mounts RootView
  App/
    RootView.swift              Router: launch screen, then auth or the tab bar
    MainTabView.swift           Week and Progress tabs
    SupabaseClient.swift        Module-level `let supabase` client
  State/
    SessionStore.swift          Auth state: bootstrap, markSignedIn, signOut
  Features/
    Auth/                       WelcomeView, SignUpView, SignInView
    Week/                       WeekView, WeekStore, PlanSessionSheet,
                                LogSessionSheet, ExercisesEditor
    Progress/                   ProgressScreen, ProgressStore
    Profile/                    ProfileSheet (sign out)
  Screens/
    LaunchScreen.swift          Animated splash shown on cold start
  Components/                   Reusable UI primitives (see below)
  DesignSystem/                 Tokens, Typography, Atmosphere, Wordmark
  Resources/Fonts/              Geist and Geist Mono (OFL licensed)
  Assets.xcassets/              AppIcon, AccentColor, LaunchBg
DesignReference/                Original design handoff from an earlier version
                                of the product. Not shipped and mostly outdated.
```

---

## App architecture

```
SyncedApp (@main)
  RootView                      owns SessionStore, injects it via .environment
    LaunchScreen                cold start, and while the session is loading
    NavigationStack             signed out
      WelcomeView
        SignUpView              pushed
        SignInView              pushed
    MainTabView                 signed in
      WeekView                  tab 1
      ProgressScreen            tab 2
```

- `SessionStore` restores the Supabase session on launch (`bootstrap()`) and exposes a `phase` of `.loading`, `.signedOut`, or `.signedIn`. `RootView` routes on it.
- The auth `NavigationStack` hides its nav bar. Each auth screen has its own back chevron to Welcome and links to the other auth screen. Signing out resets the stack to Welcome.
- `WeekStore` handles fetching a week, planning, logging, deleting, and exercise history for suggestions.
- `ProgressStore` does one fetch of logged sessions. All aggregation (`ProgressSummary`, `ProgressHero`, trends) happens client side.
- Both tab headers have a profile icon that opens `ProfileSheet`.

---

## Screens

### Welcome, Sign up, Sign in

Signed-out entry with **Create account** and **I already have an account**. Email and password auth through Supabase. A Sign in with Apple button is scaffolded but disabled until the App Store pass.

### Week (tab 1)

One Monday to Sunday week as seven rows, starting on the current week, with chevrons to move a week at a time.

- Tap a day to open **PlanSessionSheet** and add a planned Climb, Lift, or Rest.
- Tap a session to open **LogSessionSheet**, pre-filled from that row.
- **Log now** opens LogSessionSheet for today with no planned session.
- Sessions can be deleted.

**LogSessionSheet** is a single adaptive form, not a multi-step flow: pick a type, fill in the fields for that type, save. For lifts, **ExercisesEditor** handles exercises and sets, and suggests exercises from your history per muscle group. Suggestions you dismiss are remembered locally.

### Progress (tab 2)

Read-only, with a Last 30 days / All time toggle:

- **Headline** summarizing recent direction once there is enough data.
- **Climb** section: highest grade sent in the window, compared with the previous period, plus a grade pyramid of sends.
- **Lift** section: trend cards per tracked exercise.
- **Overall** footer: sessions this month, sessions this week, and rest days this week.

Pull to refresh; the tab also refetches on appear so newly logged sessions show up.

### Profile sheet

Currently just sign out.

---

## Data model

Supabase project: `https://olkjemjxsuabmxuqtzsf.supabase.co`. RLS is enabled on every table and users only see their own rows. The service role key never goes in client code.

**`profiles`**: `id` (FK `auth.users`), `email`, `created_at`, `updated_at`. Created automatically by the `handle_new_user()` trigger on sign up.

**`sessions`**: one row per planned or logged session.

| Column              | Type        | Notes                                                        |
|---------------------|-------------|--------------------------------------------------------------|
| `id`                | UUID        | Primary key                                                  |
| `user_id`           | UUID        | FK `auth.users`, on delete cascade                           |
| `created_at`        | TIMESTAMPTZ |                                                              |
| `session_type`      | TEXT        | `climb`, `lift`, or `rest`                                   |
| `scheduled_date`    | DATE        | `yyyy-MM-dd` in the device time zone                         |
| `is_planned`        | BOOLEAN     | Default false; true until the session is logged              |
| `climb_grades_sent` | INTEGER[]   | One entry per send, for example `[2, 2, 3]`                  |
| `climb_grade_v`     | INTEGER     | Mirrors `max(climb_grades_sent)`, 0 to 17                    |
| `muscle_groups`     | TEXT[]      | `chest`, `back`, `shoulders`, `arms`, `legs`, `full_body`    |
| `lift_exercises`    | JSONB       | See shape below                                              |
| `rating`            | INTEGER     | 1 to 5, optional                                             |
| `notes`             | TEXT        | Optional                                                     |

`lift_exercises` shape:

```json
[{ "name": "Bench press", "muscle_group": "chest", "sets": [{ "weight_lbs": 185, "reps": 5 }] }]
```

`muscle_group` ties each exercise to one group for suggestions. Older entries omit it and fall back to the session's `muscle_groups`.

`leaderboard_entries` and `waitlist` also exist but are not wired into the MVP.

---

## Design system

All visuals go through `Synced/DesignSystem/`. Do not add hex values, font sizes, or spacing constants in screen code. If a token is missing, add it to `DesignSystem/` first.

- **Colors** (`SYN.*`): `bg`, `bgDeep`, `surface`, `surfaceHi`, `border`, `text`, `textDim`, `textFaint`, `cyan`, `cyanSoft`, `red`, `amber`, `green`, and more. Accent is cyan `#00E5FF`.
- **Spacing**: `xs` 4, `s` 8, `m` 12, `md` 16, `l` 20, `lg` 24, `xl` 32, `xxl` 48, `pageH` 24, `tabBarClearance` 64.
- **Radius**: `button` 14, `card` 16, `input` 14, `pill` 999.
- **Typography**: always `Font.synDisplay`, `Font.synText`, or `Font.synMono`; never a font name directly. Numbers use `synMono`. Uppercase labels use `EyebrowText`.
- **Atmosphere**: `ScreenBackground` (radial vignette) and `AmbientGlow`.
- **Wordmark**: the "synced." wordmark.

Layouts are tested at iPhone 15 Pro width (393pt).

---

## Components

In `Synced/Components/`:

- `ScreenShell`: page chrome with ambient glow, optional header and back button, and a bottom CTA slot.
- `ProgressHeader`: top progress bar with optional back action.
- `Buttons`: `PrimaryButton`, `SecondaryButton`, `TextLinkButton`.
- `SpecInput`, `SpecSlider`, `AgePicker`: form inputs with monospaced numerics.
- `SelectableCard`: selectable card with a cyan glow state.
- `EyebrowTag`, `GlowDot`: small labels and indicators.
- `FlowLayout`: wrapping layout for chips.
- `LuminousOrb`: animated orb, respects Reduce Motion.
- `PhaseReveal`: `.phaseFadeUp(phase:delay:)` for staged entrances.

---

## Build and CI

- **Xcode Cloud** runs `ci_scripts/ci_post_clone.sh`, which installs XcodeGen, generates the project, and copies the root `Package.resolved` into the workspace.
- `Package.resolved` is force-added past `.gitignore`. Keep it in sync when SPM versions change.
- `CURRENT_PROJECT_VERSION` comes from Xcode Cloud's `CI_BUILD_NUMBER`. `MARKETING_VERSION` is set in `project.yml`.
- No test target yet.

---

## Conventions

- No em dashes anywhere in copy or comments.
- Work on feature branches (`feat/description`), never directly on `main`.
- Commit format: `type: description`, for example `feat: week view with tap-to-plan`.
- Never hand-edit `project.pbxproj`. Edit `project.yml` and run `xcodegen generate`.
- No lorem ipsum or placeholder copy in a shipped screen.
- See `CLAUDE.md` for the full rule set, including what not to touch during the MVP.

---

## Out of scope for the MVP

Not built and not planned for v0.1:

- Onboarding beyond Welcome and auth
- Tiers, scores, streaks, leaderboard
- Insights feeds
- Learn tab
- HealthKit
- Readiness inputs (sleep, food, meal timing, hydration, pre-workout)
