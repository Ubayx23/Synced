# Synced — Claude Code Reference

## What this app is
Synced is an iOS recovery and readiness tracking app for serious gym-goers.
Users do a pre-lift check-in before each session and a post-lift check-in
after. The app surfaces patterns over time showing what inputs (sleep, food,
timing, hydration) drive their best sessions. Includes weekly tier ranking
and friend leaderboard.

Positioning: software-only Whoop. No hardware required. Social by default.

## Critical rules — read before touching any file
- No em dashes anywhere in copy or comments. Use "and" or rewrite the sentence.
- One file per Claude Code prompt unless explicitly told otherwise.
- Confirm current git branch before making any changes.
- Never modify project.pbxproj by hand. Edit project.yml and run xcodegen generate.
- Never introduce new hex values, font sizes, or spacing constants outside DesignSystem/.
- Never change the visual design, colors, animations, or component styling.
  The design is locked. Backend wiring only unless explicitly told otherwise.
- Mobile first. Test at 393pt wide (iPhone 15 Pro).
- Always use existing SYN.* color tokens, existing components, existing spacing.
- Never use lorem ipsum or placeholder copy in any screen.

## Current state
The app is a complete front-end prototype with full UI and animations.
All data is currently mock and hardcoded. The next phase is wiring
real Supabase backend — auth, data persistence, real scoring,
real leaderboard, real insights.

DO NOT change any UI, layout, colors, animations, or copy unless
explicitly instructed. All design decisions are final.

## Tech stack
- SwiftUI, iOS 17+, Swift 5.10
- @Observable for state management
- Swift Charts for session history graph
- XcodeGen — project.yml is source of truth for Xcode project
- Supabase for auth, database, and real-time (being added now)
- No external SPM packages except Supabase Swift SDK (being added)
- Portrait only, dark only, iPhone only
- SF Pro fonts only (synDisplay, synText, synMono)

## Supabase configuration
Project URL: https://olkjemjxsuabmxuqtzsf.supabase.co
Anon key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9sa2plbWp4c3VhYm14dXF0enNmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxNTAyNzcsImV4cCI6MjA5NDcyNjI3N30.J5jmTnpo1GQgDPaZ7EPs7dCFjPqqmWKYdvFEWJxZfnM
Service role key: NEVER put this in client code. Server only.

Initialize Supabase client inside handler functions, never at module
level. Module level initialization causes build failures (learned from wrrapd).

## Database schema (already created in Supabase)
Tables with RLS enabled on all:

profiles:
  id UUID (PK, FK auth.users), username TEXT, training_goal TEXT,
  training_frequency INT default 4, sleep_baseline FLOAT default 7.5,
  tier TEXT default 'Active', score INT default 0, streak INT default 0,
  created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ

pre_lift_checkins:
  id UUID (PK), user_id UUID (FK auth.users), muscle_groups TEXT[],
  last_trained_gap TEXT, sleep_hours FLOAT, meal_items JSONB,
  meal_time TIMESTAMPTZ, lift_time TIMESTAMPTZ, hydration TEXT,
  pre_workout TEXT, input_score INT, created_at TIMESTAMPTZ

post_lift_checkins:
  id UUID (PK), user_id UUID (FK auth.users), pre_lift_id UUID (FK),
  session_rating INT (1-5), performance_vs_expectation TEXT,
  session_duration TEXT, notes TEXT, created_at TIMESTAMPTZ

leaderboard_entries:
  id UUID (PK), user_id UUID (FK auth.users, UNIQUE), display_name TEXT,
  tier TEXT default 'Active', score INT default 0, streak INT default 0,
  updated_at TIMESTAMPTZ

waitlist:
  id UUID (PK), name TEXT, email TEXT (UNIQUE), gym_frequency INT,
  source TEXT default 'landing_page', created_at TIMESTAMPTZ

RLS policies:
- profiles: authenticated users own their row (auth.uid() = id)
- pre_lift_checkins: authenticated users own their rows
- post_lift_checkins: authenticated users own their rows
- leaderboard_entries: anyone authenticated can SELECT, users own INSERT/UPDATE
- waitlist: anon can INSERT, authenticated can SELECT

Auto-trigger: handle_new_user() creates a profile row on every new auth.users insert.

## App architecture
SyncedApp (@main)
  RootView
    LaunchScreen (animated splash, runs every cold launch)
    OnboardingFlow (if hasCompletedOnboarding == false)
    MainTabView (if hasCompletedOnboarding == true)
      HomeView (tab 1)
      LeaderboardView (tab 2)
      StatsView (tab 3)

ProfileView opens as a sheet from HomeView gear icon.
Pre-lift and post-lift check-ins open as full-screen sheets from HomeView.

## Onboarding flow (10 screens)
Step machine in OnboardingFlow.swift. Steps 1-10:
1. S1Welcome: wordmark, get started
2. S2Value: how it works, 3 benefit cards
3. S3Name: first name input, saves to UserDefaults "userName"
4. S4Age: age drum roll picker, saves to UserDefaults "userAge"
5. S7Goal: training goal selection, saves "trainingGoal"
6. S8Frequency: days per week slider, saves "trainingFrequency"
7. S9Sleep: sleep baseline slider, saves "sleepBaseline"
8. S8CheckInLoop: explains pre/post check-in loop
9. S9Notifications: notification permission request
10. S12TierReveal: shows Active tier, "Enter Synced" sets
    hasCompletedOnboarding = true and routes to MainTabView

Note: file names (S7Goal, S8Frequency etc) are historical and do not
match step order. OnboardingFlow.swift switch is the source of truth.

## UserDefaults keys
hasCompletedOnboarding: Bool
userName: String
userAge: Int
trainingGoal: String
trainingFrequency: Int
sleepBaseline: Double
preLiftDraft.v5: Data (pre-lift draft, same-day resume only)

Reset onboarding in ProfileView clears all of these.

## Pre-lift check-in (4 steps)
PreLiftCheckInView.swift — full screen modal sheet
Step 1 RecoveryStep: muscle groups multi-select tiles + last trained gap 4 options
Step 2 SleepStep: sleep hours slider 4h to 12h
Step 3 FoodStep: meal pill tag input (MealTagInput) + recent meal chips
Step 4 TimingStep: meal time picker + lift time picker + gap card +
       hydration 3-tap + pre-workout 3-tap

Draft persistence: saves entire state to UserDefaults preLiftDraft.v5 on every
change. Restores same-day. Discards previous day drafts. Schema versioned.
Uses single draftSnapshot hash to avoid Swift compiler timeout from chaining
multiple .onChange modifiers.

## Post-lift check-in (2 steps)
PostLiftCheckInView.swift — full screen modal sheet
Step 1 PerformanceStep: session rating 1-5 colored circles +
       performance vs expectation 3 cards
Step 2 SessionDetailsStep: session duration 2x2 grid + optional free text notes

No draft persistence for post-lift.

## Tier system
Defined in OnboardingModel.swift (enum Tier):
cooked: 0-39, gray #5A5A60
active: 40-59, white #FFFFFF
dialed: 60-74, green #22C55E
lockedIn: 75-89, cyan #00E5FF
synced: 90-100, cyan gradient with glow

Tiers reset every Sunday at midnight.
Score is currently mock (hardcoded 67). Will be server-driven.

## Score calculation (to be implemented)
Input score 0-100 from pre-lift inputs:
Sleep component 35%:
  under 6h = 20pts, 6-6.5h = 40pts, 7-7.5h = 70pts,
  8-9h = 100pts, over 9h = 80pts
Meal timing component 35%:
  under 1hr gap = 20pts, 1-1.5hr = 50pts, 2-3hr = 100pts,
  3-4hr = 80pts, over 4hr = 60pts
Hydration component 15%:
  Low = 30pts, Normal = 70pts, High = 100pts
Pre-workout component 15%:
  None = 70pts, Coffee = 85pts, Pre-workout = 90pts

Weekly score = 7-day rolling average of input scores weighted against
session ratings. Server-driven calculation via Supabase Edge Function.

## Design system — DO NOT MODIFY
All in Synced/DesignSystem/. Never bypass these tokens.

Colors SYN.*:
  bg #0A0A0A, bgDeep #050505
  surface #161618, surfaceHi #1F1F23
  border #2A2A2E
  text #FFFFFF, textDim #8E8E93, textFaint #5A5A60
  cyan #00E5FF, cyanSoft cyan at 20% opacity
  red #EF4444, amber #F59E0B, green #22C55E, bronze #CD7F32

Typography:
  synDisplay: SF Pro Display (headings)
  synText: SF Pro Text (body)
  synMono: SF Mono (numbers, scores, data)
  EyebrowText: uppercase, tracked 0.08em

Spacing: Spacing.pageH = 24pt horizontal padding throughout
Radius: button 14, card 16, input 14, pill 999

## Components in Synced/Components/
DO NOT recreate these. Always reuse:
ScreenShell: page chrome with progress header + back + CTA slot
ProgressHeader: top progress bar, takes Double 0-1
PrimaryButton: cyan fill, black text, 56pt tall, full width
SecondaryButton: outlined
TextLinkButton: plain text link
SpecInput: styled text field
SpecSlider: styled slider with monospace number display
AgePicker: drum roll age picker
SelectableCard: single-select with cyan glow selected state
EyebrowTag: small uppercase pill label
LuminousOrb: animated orb with orbital rings (tier reveal)
PhaseReveal: .phaseFadeUp modifier for staged entrances

Check-in components in Features/CheckIn/Components/:
MealChip: recent meal chip with clock icon
MealTagInput: pill tag input for food items with carb tracking
TimePickerInput: custom time picker (hour/minute columns + AM/PM toggle)

## FoodItem model
Location: Features/CheckIn/Models/FoodItem.swift
struct FoodItem: Codable, Identifiable, Equatable {
  var id: UUID = UUID()
  var name: String
  var carbsG: Int? = nil
}

## Repo layout
project.yml: XcodeGen spec, source of truth
Synced/
  SyncedApp.swift: @main entry point
  App/
    RootView.swift: launch, onboarding, and tabs router
    MainTabView.swift: tab bar Home/Leaderboard/Stats
  DesignSystem/: Tokens, Typography, Atmosphere, Wordmark
  Components/: shared UI primitives
  Screens/
    LaunchScreen.swift: animated splash
    OnboardingFlow.swift: 10-step onboarding machine
    S1Welcome through S12TierReveal: individual onboarding screens
    HomeView.swift: home tab
    LeaderboardView.swift: leaderboard tab
    StatsView.swift: stats tab
    ProfileView.swift: profile sheet
  Features/
    CheckIn/
      PreLiftCheckInView.swift: 4-step pre-lift modal
      PostLiftCheckInView.swift: 2-step post-lift modal
      Steps/: individual step views
      Components/: check-in input components
      Models/FoodItem.swift: food item model
    Stats/InsightCardView.swift: insight card view
  State/
    OnboardingModel.swift: @Observable onboarding state
  Assets.xcassets/
DesignReference/: design handoff, reference only, not shipped

## Git conventions
Main branch: main (clean, stable)
Feature branches: feat/description
Next branch to create: feat/auth-supabase
Commit format: "type: description"
Example: "feat: Supabase auth sign up and sign in screens"

## What to build next (in order)
1. Add Supabase Swift SDK via Swift Package Manager
2. Create SupabaseClient.swift singleton
3. Build auth screens: sign up, sign in, Sign in with Apple
4. Update RootView to check Supabase session
5. Save onboarding data to profiles table on completion
6. Save pre-lift check-in to pre_lift_checkins on completion
7. Save post-lift check-in to post_lift_checkins on completion
8. Calculate real input score on pre-lift completion
9. Calculate real weekly score and tier from actual data
10. Wire leaderboard to real leaderboard_entries data
11. Generate real insight cards from user session data
12. Sunday midnight tier reset via Supabase Edge Function
13. Push notifications for pre-lift and post-lift reminders
14. Friend system for leaderboard

## Debugging
Onboarding deeplink: launch with -startStep N (1-10) to jump to a specific
onboarding screen without clicking through.
To re-trigger onboarding: Profile Settings Reset onboarding or delete app.

## What never changes
- Visual design, colors, animations, component styling
- Design system tokens in DesignSystem/
- Dark only, portrait only, iPhone only constraints
- No em dashes anywhere in any file
- No new dependencies without explicit instruction
- No hand-editing project.pbxproj