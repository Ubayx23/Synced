# Synced

iOS app for **recovery and readiness tracking** aimed at serious gym-goers. Aesthetic is dark, premium, minimal — Whoop / Linear-adjacent. Currently the app implements a 12-screen onboarding flow that culminates in a tier reveal, plus a placeholder home screen.

## Tech stack

- **SwiftUI** on **iOS 17+** (`@Observable`, `TimelineView`, phase-based animations)
- **Swift 5.10**
- **XcodeGen** is the source of truth for the Xcode project — `project.yml` generates `Synced.xcodeproj`. **Do not hand-edit `project.pbxproj`.** Re-run `xcodegen generate` after adding files or changing build settings.
- No external dependencies. No SPM packages. System SF fonts only.
- Code signing is disabled in the spec (`CODE_SIGNING_ALLOWED: NO`) — the app builds and runs in Simulator without a team.

## Repo layout

```
project.yml                     XcodeGen spec — single source of truth for the project
Synced.xcodeproj/               Generated; safe to delete and regenerate
Synced/
  SyncedApp.swift               @main; mounts OnboardingFlow, forces .dark color scheme
  DesignSystem/
    Tokens.swift                SYN.* color palette, Spacing, Radius
    Typography.swift            Font.synDisplay / synText / synMono helpers, EyebrowText
    Atmosphere.swift            ScreenBackground (radial vignette) + AmbientGlow (breathing halo)
    Wordmark.swift              "synced." wordmark + PulseRingIcon
  Components/                   Reusable UI primitives (see "Components" below)
  Screens/
    OnboardingFlow.swift        Step machine (1..13), drives transitions, owns OnboardingModel
    S1Welcome … S12TierReveal   Onboarding steps in numeric order
    SHome.swift                 Post-onboarding placeholder/home
  State/
    OnboardingModel.swift       @Observable; firstName/age/goal/daysPerWeek/sleepHours/
                                diagnostic/tier (+ previewTier for live tier scrubbing)
  Assets.xcassets/              AppIcon, AccentColor (currently empty placeholders)
DesignReference/                **Handoff bundle from claude.ai/design — reference only, not shipped.**
  README.md                     Explains the bundle's purpose
  chats/                        Original design conversations (intent + spec live here)
  project/                      HTML/JSX prototypes the Swift code is recreating
```

`DesignReference/` is the original design handoff. It is **not** part of the build target (see `project.yml` → `targets.Synced.sources` only includes `Synced/`). Treat it as the design spec — when something is ambiguous in the Swift code, the chat transcripts and HTML prototypes are authoritative for intent.

## Design system

All visuals route through `Synced/DesignSystem/`. Use the tokens — don't introduce new hex values, font sizes, or spacing constants in screen code.

- **Colors** — `SYN.bg / bgDeep / surface / surfaceHi / border / text / textDim / textFaint / cyan / cyanSoft / red / amber / green`
- **Spacing** — `Spacing.xs/s/m/md/l/lg/xl/xxl`, page horizontal padding is `Spacing.pageH` (24)
- **Radius** — `Radius.button (14) / card (16) / input (14) / pill (999)`
- **Typography** — `Font.synDisplay`, `Font.synText`, `Font.synMono`. Uppercase eyebrows use `EyebrowText` with 2.0 tracking.
- **Background** — every screen sits over `ScreenBackground()` (mounted once in `OnboardingFlow`); ambient cyan halo via `AmbientGlow`.

Accent is **cyan `#00E5FF`** with a soft glow. Numerics (ages, hours, percentages) are monospaced.

## Onboarding flow

`OnboardingFlow` is a simple integer step machine (1…13) over `OnboardingModel`. Progress percentages per step are pinned in both `OnboardingFlow.progress` and the `ScreenProgress` enum — keep them in sync.

| Step | Screen              | Purpose                                                         |
|-----:|---------------------|-----------------------------------------------------------------|
| 1    | `S1Welcome`         | Wordmark + pulse ring, "Get Started"                            |
| 2    | `S2Value`           | Value prop                                                      |
| 3    | `S3Name`            | First name input                                                |
| 4    | `S4Age`             | Age picker                                                      |
| 5    | `S5Hook`            | Emotional hook with `LuminousOrb`                               |
| 6    | `S6Benefits`        | Benefits list                                                   |
| 7    | `S7Goal`            | Single-select `Goal`                                            |
| 8    | `S8Frequency`       | Days/week (slider)                                              |
| 9    | `S9Sleep`           | Sleep hours (slider)                                            |
| 10   | `S10Diagnostic`     | Single-select `DiagnosticOption`                                |
| 11   | `S11Loading`        | Computes tier (`OnboardingModel.computeTier`)                   |
| 12   | `S12TierReveal`     | Reveals computed `Tier` via `LuminousOrb` in tier mode          |
| 13+  | `SHome`             | Placeholder home; "Replay onboarding" resets the model          |

**Tiers** (in `OnboardingModel.swift`): `cooked` (0–19) · `active` (20–49) · `dialed` (50–79) · `lockedIn` (80–94) · `synced` (95–100). The current `computeTier` is intentionally a toy — the production version is server-driven.

**Debug deeplink:** launch with `-startStep N` (1–13) to jump straight to a screen. Useful for iterating on a single screen without clicking through.

## Components

Located in `Synced/Components/`. Each is a self-contained primitive:

- `ScreenShell` — standard page chrome (progress header + back + CTA slot). All onboarding screens use this.
- `ProgressHeader` — top progress bar; takes a `Double` 0…1 and an optional `onBack`.
- `Buttons` — `PrimaryButton` (cyan fill, black text), `SecondaryButton` (outlined), `TextLinkButton`.
- `SpecInput`, `SpecSlider`, `AgePicker` — form inputs with monospace numerics.
- `SelectableCard` — single-select card with cyan-glow selected state.
- `EyebrowTag` — small uppercase pill label.
- `LuminousOrb` — 240pt animated orb with three orbital rings + breathing core (`tierMode: true` recolors for tier reveal). Respects `accessibilityReduceMotion`.
- `PhaseReveal` — `.phaseFadeUp(phase:delay:)` modifier for staged screen entrance.

## Conventions

- Screens take explicit `onBack` / `onNext` closures. They do **not** know about the step index — `OnboardingFlow` owns navigation.
- The shared `OnboardingModel` is passed in via init (and also exposed via `.environment(model)` for nested use).
- Animations are short (`.easeOut(0.32)` for transitions, springs for entrance) and respect `accessibilityReduceMotion` where motion is meaningful (e.g. `LuminousOrb`).
- Portrait-only, dark-only, iPhone-only (`TARGETED_DEVICE_FAMILY: "1"`).
- Don't introduce new color/spacing/font constants outside `DesignSystem/`. If a token is missing, add it there.
- Don't render the HTML prototypes in a browser — read the source. Dimensions, colors, layout are spelled out in the chats.

## Common workflows

```bash
# Regenerate the Xcode project after editing project.yml or adding/removing files
xcodegen generate

# Open in Xcode
open Synced.xcodeproj

# Build for the iOS Simulator from the CLI
xcodebuild -project Synced.xcodeproj -scheme Synced \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

## What's not here yet

- No tests, no CI.
- Assets.xcassets icons are placeholders.
- No persistence — onboarding state lives in memory only.
- No networking; tier computation is local and toy.
- No sign-in flow ("I already have an account" on S1 is a stub).
