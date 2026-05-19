# Synced

**Synced** is an iOS app for **recovery and readiness tracking**, built for serious gym-goers. It frames training as a closed loop. You log how you walk into a session, log how it went, and over time the app surfaces what actually moves your performance: sleep, meal timing, hydration, and pre-workout. The aesthetic is dark, premium, and minimal, in the spirit of Whoop and Linear.

Positioning: a software-only Whoop. No hardware required, and social by default.

The app is currently a **front-end prototype**. Every screen is built and animated, but all data is mock. There is no backend, no networking, and no real analytics yet. Score, streak, leaderboard, and insights are hardcoded. Backend wiring with Supabase (auth, persistence, real scoring, real leaderboard, real insights) is the next phase of work.

---

## Table of contents

- [What the app does](#what-the-app-does)
- [Tech stack](#tech-stack)
- [Getting started](#getting-started)
- [Repo layout](#repo-layout)
- [App architecture](#app-architecture)
- [Onboarding flow](#onboarding-flow)
- [Main app: the three tabs](#main-app-the-three-tabs)
- [Check-in flows](#check-in-flows)
- [Tiers and scoring](#tiers-and-scoring)
- [Design system](#design-system)
- [Components](#components)
- [Persistence](#persistence)
- [Conventions](#conventions)
- [Debugging](#debugging)
- [What's not built yet](#whats-not-built-yet)

---

## What the app does

Synced turns each workout into a measured loop:

1. **Pre-lift check-in.** Before training, the user logs recovery state (muscle groups, time since last trained), sleep, the meal they ate, and timing, hydration, and pre-workout details.
2. **Post-lift check-in.** After training, the user rates the session, logs how it compared to expectation, and adds duration and notes.
3. **Synced score and tier.** Those inputs roll up into a weekly readiness score (0 to 100) and a named tier, shown front and center on the home screen. The score resets weekly.
4. **Insights.** Over many sessions the app surfaces patterns, for example "you lift best after 7.5+ hours of sleep" or "rice cakes before lifting hurt your sessions".
5. **Leaderboard.** A weekly ranking against gym friends, to add social pressure.

---

## Tech stack

- **SwiftUI** targeting **iOS 17+**, using `@Observable`, phase-based animations, and Swift Charts.
- **Swift 5.10**.
- **Swift Charts** (Apple framework) for the session-history graph. No third-party charting.
- **No external dependencies** at present. No SPM packages, no CocoaPods. System SF Pro fonts only. The Supabase Swift SDK is planned as the first dependency in the backend phase.
- **XcodeGen** is the source of truth for the Xcode project. `project.yml` generates `Synced.xcodeproj`. **Do not hand-edit `project.pbxproj`.** Re-run `xcodegen generate` after adding or removing files or changing build settings.
- **Portrait-only, dark-only, iPhone-only** (`TARGETED_DEVICE_FAMILY: "1"`, `UIUserInterfaceStyle: Dark`).

### Code signing

Code signing is **enabled** in `project.yml` (`CODE_SIGNING_REQUIRED: YES`, `CODE_SIGN_STYLE: Automatic`) with a `DEVELOPMENT_TEAM` set, so the app can be deployed to a physical device. It also builds and runs in the Simulator.

---

## Getting started

```bash
# 1. Install XcodeGen if you don't have it
brew install xcodegen

# 2. Generate the Xcode project from project.yml
xcodegen generate

# 3. Open in Xcode
open Synced.xcodeproj

# 4. Build for the iOS Simulator from the CLI (optional)
xcodebuild -project Synced.xcodeproj -scheme Synced \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

Re-run `xcodegen generate` any time you edit `project.yml` or add or remove source files.

---

## Repo layout

```
project.yml                      XcodeGen spec, single source of truth for the project
Synced.xcodeproj/                Generated; safe to delete and regenerate
Synced/
  SyncedApp.swift                @main entry point; mounts RootView
  App/
    RootView.swift               Top-level router: launch, then onboarding or tabs
    MainTabView.swift            Bottom tab bar (Home, Leaderboard, Stats)
  DesignSystem/
    Tokens.swift                 SYN.* color palette, Spacing, Radius, Color(hex:)
    Typography.swift             Font.synDisplay / synText / synMono, EyebrowText
    Atmosphere.swift             ScreenBackground (radial vignette) and AmbientGlow
    Wordmark.swift               "synced." wordmark and PulseRingIcon
  Components/                    Reusable UI primitives (see "Components" below)
  Screens/
    LaunchScreen.swift           Animated splash (arc-draw animation)
    OnboardingFlow.swift         Onboarding step machine (steps 1 to 10)
    S1Welcome ... S12TierReveal  Individual onboarding steps
    HomeView.swift               Home tab: score, check-ins, quick stats
    LeaderboardView.swift        Leaderboard tab: weekly friend rankings
    StatsView.swift              Stats tab: insight cards and session chart
    ProfileView.swift            Profile sheet (opened from Home's gear icon)
  Features/
    CheckIn/                     Pre-lift and post-lift check-in flows
      PreLiftCheckInView.swift   4-step pre-lift flow with draft persistence
      PostLiftCheckInView.swift  2-step post-lift flow
      Steps/                     Individual check-in step views
      Components/                Check-in-specific inputs (meal chips, time picker)
      Models/FoodItem.swift      Codable food/meal model
    Stats/InsightCardView.swift  Insight card model and view
  State/
    OnboardingModel.swift        @Observable onboarding state, plus Goal and Tier enums
  Assets.xcassets/               AppIcon, AccentColor, LaunchBg
DesignReference/                 Design handoff bundle, reference only, NOT shipped
  README.md                      Explains the bundle's purpose
  chats/                         Original design conversations (intent and spec)
  project/                       HTML/JSX prototypes the Swift code recreates
```

`DesignReference/` is the original design handoff from claude.ai/design. It is **not** part of the build target (`project.yml` only includes `Synced/`). When something is ambiguous in the Swift code, the chat transcripts and HTML prototypes there are authoritative for design intent. Read the source; do not render the prototypes in a browser.

---

## App architecture

The app has a single top-level router, `RootView`, driven by one persistent flag:

```
SyncedApp (@main)
  RootView
    LaunchScreen          shown on every cold start, roughly a 2s animated splash
    OnboardingFlow        if hasCompletedOnboarding == false
    MainTabView           if hasCompletedOnboarding == true
      HomeView
      LeaderboardView
      StatsView
```

- `RootView` reads `@AppStorage("hasCompletedOnboarding")`. The launch screen always shows first, then crossfades to either onboarding or the tab bar.
- Finishing onboarding (the tier-reveal CTA) flips `hasCompletedOnboarding` to `true`, and `RootView` swaps to `MainTabView`.
- The whole app is forced into `.dark` color scheme.

---

## Onboarding flow

`OnboardingFlow` is a simple integer step machine (steps 1 to 10) over a shared `OnboardingModel`. Each screen takes explicit `onBack` and `onNext` closures and does not know its own step index.

| Step | Screen            | Purpose                                              |
|-----:|-------------------|------------------------------------------------------|
| 1    | `S1Welcome`       | Wordmark and pulse ring, "Get Started"               |
| 2    | `S2Value`         | Value proposition, how it works                      |
| 3    | `S3Name`          | First-name input                                     |
| 4    | `S4Age`           | Age picker                                           |
| 5    | `S7Goal`          | Single-select training `Goal`                        |
| 6    | `S8Frequency`     | Training days per week (slider)                      |
| 7    | `S9Sleep`         | Sleep-hours baseline (slider)                        |
| 8    | `S8CheckInLoop`   | Explains the pre/post-lift check-in loop             |
| 9    | `S9Notifications` | Notification opt-in prompt                           |
| 10   | `S12TierReveal`   | Reveals a tier; CTA completes onboarding             |

> Note: the screen *file names* (`S7Goal`, `S8Frequency`, `S12TierReveal`, and so on) are historical and no longer match their position in the route. The `switch` in `OnboardingFlow.swift` is the source of truth for ordering.

The progress bar advances in 10% increments (`ScreenProgress` enum). Steps 1 and 10 hide the bar entirely.

As the user moves through onboarding, individual screens persist their answers directly to `UserDefaults` (see [Persistence](#persistence)), so the home screen can read them after onboarding completes.

---

## Main app: the three tabs

### Home (`HomeView`)

The default tab. Top to bottom:

- **Header.** Greeting with the user's name, a day-streak chip, and a gear icon that opens the **Profile** sheet.
- **Hero score card.** The weekly **Synced score** (large monospace number), the current tier with its colored dot, points to next tier, and a tier progress bar. Resets Sunday at midnight.
- **Today's check-ins.** Two cards: *Pre-lift* and *Post-lift*. The post-lift card stays **locked** until the pre-lift check-in is done. Tapping a card opens that check-in as a full-screen sheet. Completing a check-in animates the score upward.
- **Quick stats.** Sleep baseline, training days per week, and last-session rating.

### Leaderboard (`LeaderboardView`)

A weekly friend ranking. Each row shows rank, avatar initials, name and username, score, and tier. The current user's row is highlighted with a cyan border and glow. The tab has an "Invite friends" pill and an empty state for users with no friends yet. Rankings reset Sunday at midnight. All friend data is mock.

### Stats (`StatsView`)

The insights tab:

- **Insights feed.** A stack of `InsightCardView` cards. Each has an icon, headline, supporting stat, a sentiment (positive, warning, negative, or neutral) that colors the border, and a confidence pill ("Early data" under 5 sessions, otherwise "Based on N sessions").
- **Session history chart.** A Swift Charts line and point graph of session ratings (1 to 5) over the last 30 days, with points colored by rating.
- **Your averages.** Average sleep, average rating, and average gap (time between meal and lift).

### Profile (`ProfileView`)

Opened as a sheet from Home's gear icon. Shows a profile header card (avatar, name, member-since, current tier), a stats grid (streak, total check-ins, weeks tracked, best tier), tier history (this week, last week, 2 weeks ago), and a settings list. The **"Reset onboarding"** settings row clears all persisted `UserDefaults` keys, sending the user back through onboarding on next launch.

---

## Check-in flows

Both check-ins are presented as full-screen sheets from the Home tab. Each has a top bar with a close button, a dotted step indicator, and an "N of M" counter, plus a bottom CTA that is disabled until the current step's required fields are filled.

### Pre-lift check-in (`PreLiftCheckInView`), 4 steps

| Step | View            | Captures                                            |
|-----:|-----------------|-----------------------------------------------------|
| 1    | `RecoveryStep`  | Muscle groups to train, time since last trained     |
| 2    | `SleepStep`     | Hours of sleep last night                           |
| 3    | `FoodStep`      | Pre-lift meal items (with optional per-item carbs)  |
| 4    | `TimingStep`    | Meal time, lift time, hydration, pre-workout        |

**Draft persistence.** The pre-lift flow auto-saves its entire state to `UserDefaults` on every change. If the user closes the sheet mid-flow and reopens it *the same day*, their progress is restored. Drafts from a previous day, or written by an older schema, are discarded. The storage key is versioned (`preLiftDraft.v5`) and bumped on each schema change. State is hashed into a single `draftSnapshot` so one `.onChange` handles all fields, a deliberate fix for a Swift compiler timeout caused by chaining nine separate `.onChange` modifiers.

### Post-lift check-in (`PostLiftCheckInView`), 2 steps

| Step | View                  | Captures                                          |
|-----:|-----------------------|---------------------------------------------------|
| 1    | `PerformanceStep`     | Session rating (1 to 5), performance vs expectation |
| 2    | `SessionDetailsStep`  | Session duration, free-text notes                 |

Completing either check-in flips a binding (`isComplete`) that the Home screen watches to update the score and unlock the next card. The post-lift flow does **not** persist a draft.

---

## Tiers and scoring

Tiers are defined in `OnboardingModel.swift` (`enum Tier`). Each maps to a score range, a display name, a color, an SF Symbol icon, and a tagline:

| Tier        | Score range | Color          |
|-------------|-------------|----------------|
| `cooked`    | 0 to 39     | faint gray     |
| `active`    | 40 to 59    | white          |
| `dialed`    | 60 to 74    | green          |
| `lockedIn`  | 75 to 89    | cyan           |
| `synced`    | 90 to 100   | cyan           |

The home screen uses the tier ranges to compute the tier progress bar and "points to next tier". Tiers reset every Sunday at midnight. Scoring is currently mock and hardcoded. The production version will be server-driven, computed from real check-in data via a Supabase Edge Function.

---

## Design system

All visuals route through `Synced/DesignSystem/`. **Use the tokens. Do not introduce new hex values, font sizes, or spacing constants in screen code.** If a token is missing, add it in `DesignSystem/`.

- **Colors** (`SYN.*`): `bg`, `bgDeep`, `surface`, `surfaceHi`, `border`, `text`, `textDim`, `textFaint`, `cyan`, `cyanSoft`, `red`, `amber`, `green`, `bronze`. There is also a `Color(hex:)` initializer accepting a `UInt32` or a string.
- **Spacing**: `Spacing.xs/s/m/md/l/lg/xl/xxl`; page horizontal padding is `Spacing.pageH` (24).
- **Radius**: `Radius.button` (14), `card` (16), `input` (14), `pill` (999).
- **Typography**: `Font.synDisplay`, `Font.synText`, `Font.synMono`. Uppercase eyebrow labels use `EyebrowText` with 0.08em tracking.
- **Background**: screens sit over `ScreenBackground` (radial vignette); an ambient cyan halo is added via `AmbientGlow`.

The accent is **cyan `#00E5FF`** with a soft glow. Numerics (ages, hours, scores, percentages) are always **monospaced** (`synMono`).

---

## Components

In `Synced/Components/`, self-contained UI primitives:

- `ScreenShell`: standard page chrome, with ambient glow, an optional progress header and back button, and a bottom CTA slot. Used by all onboarding screens.
- `ProgressHeader`: top progress bar; takes a `Double` (0 to 1) and an optional `onBack`.
- `Buttons`: `PrimaryButton` (cyan fill, black text), `SecondaryButton` (outlined), `TextLinkButton`.
- `SpecInput`, `SpecSlider`, `AgePicker`: form inputs with monospace numerics.
- `SelectableCard`: single-select card with a cyan-glow selected state.
- `EyebrowTag`: small uppercase pill label.
- `LuminousOrb`: animated orb with orbital rings and a breathing core; `tierMode` recolors it for the tier reveal. Respects `accessibilityReduceMotion`.
- `PhaseReveal`: `.phaseFadeUp(phase:delay:)` modifier for staged screen entrances.

Check-in-specific components live under `Features/CheckIn/Components/`: `MealChip`, `MealTagInput`, `TimePickerInput`.

---

## Persistence

There is no database yet. All real persistence is via `UserDefaults` and `@AppStorage`:

| Key                      | Written by             | Read by                      |
|--------------------------|------------------------|------------------------------|
| `hasCompletedOnboarding` | `OnboardingFlow`       | `RootView`, `ProfileView`    |
| `userName`               | `S3Name`               | `HomeView`                   |
| `userAge`                | `S4Age`                | (not yet read)               |
| `trainingGoal`           | `S7Goal`               | (not yet read)               |
| `trainingFrequency`      | `S8Frequency`          | `HomeView`                   |
| `sleepBaseline`          | `S9Sleep`              | `HomeView`                   |
| `preLiftDraft.v5`        | `PreLiftCheckInView`   | `PreLiftCheckInView`         |

"Reset onboarding" in `ProfileView` clears these keys (except the pre-lift draft, which the check-in view manages itself).

Everything else (Synced score, streak, leaderboard, insights, session history, tier history) is **mock data hardcoded in the views**.

---

## Conventions

- Screens take explicit `onBack` and `onNext` closures. They do **not** know their step index; `OnboardingFlow` owns navigation.
- The shared `OnboardingModel` is passed in via `init` and also exposed via `.environment(model)` for nested use.
- Animations are short (`.easeOut(0.32)` for transitions, springs for entrances) and respect `accessibilityReduceMotion` where motion is meaningful.
- Do not introduce new color, spacing, or font constants outside `DesignSystem/`.
- No em dashes anywhere in copy or comments.
- When a SwiftUI view body grows large, watch for compiler type-checking timeouts. The pre-lift draft uses a single hashed `draftSnapshot` to collapse what would otherwise be nine `.onChange` modifiers.
- `project.pbxproj` is generated. Never hand-edit it. Edit `project.yml` and re-run `xcodegen generate`.

---

## Debugging

**Onboarding deeplink.** Launch with `-startStep N` (1 to 10) to jump straight to an onboarding screen without clicking through. Useful for iterating on a single screen. Add it under Xcode, Scheme, Run, Arguments.

To re-trigger onboarding on a build that is already past it, use **Profile, Settings, Reset onboarding**, or delete the app from the Simulator or device.

---

## What's not built yet

- **No backend.** No networking, no API, no auth. "I already have an account" on Welcome is a stub. Supabase wiring is the next phase.
- **No real data.** Score, streak, leaderboard, insights, and session history are all mock.
- **No real scoring.** Tier computation is local and placeholder; the production version will be server-driven.
- **No tests, no CI.**
- **Limited persistence.** Only the handful of `UserDefaults` keys above survive a relaunch; check-in submissions are not yet stored.
