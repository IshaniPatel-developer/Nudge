# Nudge - GLP-1 Titration & Lifestyle Companion

Nudge is a SwiftUI companion application designed for users tracking weekly GLP-1 injection doses alongside daily lifestyle metrics (Water, Steps, Weight). Built using **Clean Architecture** and **MVVM** design patterns, the app follows standard industry engineering practices, avoiding global state singletons or untested frameworks.

---

## Key Features

1. **GLP-1 Dose Tracking & Calculations**
   - **Step-up Schedule**: Computes next titration date and dosage amount dynamically (increases every 4 weeks) using clinical protocol schedules (0.25mg → 0.5mg → 1.0mg → 1.7mg → 2.4mg).
   - **Double-Button Action Card**: Log injections directly on the dashboard:
     - **Log Taken**: Instantly log today's dose.
     - **Log Missed**: Record a missed weekly injection.
     - **Back-date**: Select a historical date using a calendar view.
   - **Dynamic Timeline**: Displays visually responsive progress indicators showing what steps are completed, what is active, and what is upcoming.

2. **Lifestyle Vitals Tracking**
   - Track three key health metrics: **Water (ml)**, **Steps (count)**, and **Weight (kg)**.
   - **Visual Telemetry**: Features premium circular progress rings and a dynamic 7-day trend bar graph showing partial/completed goals.
   - **Inline Value Editing**: Seamless edit functionality via a low-profile **pencil icon** next to each status value (e.g. `1.1L of 2.5L ✎`), completely replacing bulky action buttons.

3. **Premium UX & Design System**
   - **Inter Font Family**: Custom-loaded geometric typeface integrated across all elements with a safe fallback mechanism.
   - **Content-Sized Bottom Sheets**: Clean bottom sheets that auto-resize dynamically to wrap content perfectly (no empty/transparent top-half screens).
   - **Dark Mode Aesthetics**: Sleek glassmorphic components (`.glassCard()`) and vibrant color gradients customized per metric.

---

## Architectural Principles

The application is built on **Clean Architecture**, enforcing a strict unidirectional dependency rule: **Presentation -> Domain <- Data**.

```
                           ┌─────────────────┐
                           │   Presentation  │
                           │ (Views/VMs/Nav) │
                           └────────┬────────┘
                                    │
                                    ▼
                           ┌─────────────────┐
                           │      Domain     │  ◀── (Repository Protocols)
                           │ (Entities/UCs)  │
                           └─────────────────┘
                                    ▲
                                    │ (Implements)
                           ┌────────┴────────┐
                           │       Data      │
                           │  (Repositories) │
                           └─────────────────┘
```

1. **Domain Layer (Core)**: 
   - Contains pure business models (`DoseSchedule`, `DoseLog`, `LifestyleLog`), repository abstractions, and UseCases that coordinate operations.
   - The titration progression schedule is dynamically computed rather than hardcoded.

2. **Data Layer**:
   - Implements Domain-defined repository protocols (`DoseRepositoryProtocol`, `LifestyleRepositoryProtocol`).
   - Mock repositories (`MockDoseRepository`, `MockLifestyleRepository`) seed realistic progress trends and titration history.
   - Utilizes thread-safe synchronization (`NSLock`) to mimic real-world database access.

3. **Presentation Layer**:
   - SwiftUI views utilizing a dedicated Router for navigation.
   - Decoupled ViewModels that interact strictly with UseCases.
   - Built-in custom ViewModifiers (e.g. `.glassCard()`) and reusable controls (`ProgressRing`, `PrimaryButton`, `CountdownView`).

4. **Dependency Injection & Routing**:
   - Constructor injection is managed at the root-level via `CompositionRoot`. No global singletons are used.
   - View models are injected into views using composition factories and the environment context.

---

## Folder Structure

```
Nudge/
├── App/
│   ├── NudgeApp.swift          # Main App entry point
│   └── CompositionRoot.swift   # Composition root managing dependencies
├── Core/
│   ├── Theme/                  # Dynamic colors, gradient catalogs, typography (Inter)
│   ├── Utilities/              # Formatting extensions, ViewState types, Date helpers
│   ├── Extensions/             # View modifiers (e.g. GlassCard)
│   └── Components/             # Reusable UI elements (Rings, Buttons, headers)
├── Domain/
│   ├── Entities/               # Domain models (DoseLog, LifestyleMetric)
│   ├── Repositories/           # Repository protocols (interfaces)
│   └── UseCases/               # Orchestrates business rules (DoseUseCase, LifestyleUseCase)
├── Data/
│   ├── Repositories/           # Mock implementations of repository protocols
│   └── Models/                 # Shared Data/Error models (AppError)
└── Presentation/
    ├── Navigation/             # Navigation path state routers (AppRouter)
    └── Features/               # Modular features
        ├── Dashboard/          # Dashboard weekly schedules & metrics overview
        ├── DoseTracking/       # Injections tracking, history lists, log screens
        ├── Lifestyle/          # Daily vitals, log sheets, custom 3D asset cards
        └── Analytics/          # Swift Charts trend analysis and progress insights
```

---

## Build & Run Instructions

### Prerequisites
- macOS Sequoia (or latest macOS)
- Xcode 16+ (iOS 17.0+ SDK)

### Running on the Simulator
1. Open the project in Xcode:
   ```bash
   open Nudge.xcodeproj
   ```
2. Select the `Nudge` scheme and choose a simulator (e.g., iPhone 17 Pro).
3. Press `CMD + R` to compile and run.
4. Alternatively, to build and run via Terminal:
   ```bash
   # Build the project
   xcodebuild -project Nudge.xcodeproj -scheme Nudge -destination 'generic/platform=iOS Simulator' build
   ```

---

## Trade-offs & Architecture Decisions

1. **In-Memory Thread-Safe Cache vs. Database Store**:
   - *Decision*: Mock repositories use local arrays protected by `NSLock` to prevent race conditions during async/await execution.
   - *Trade-off*: App data resets on compile relaunch. However, the interface-segregated protocol design allows swapping this for CoreData, SwiftData, or a Network API client by simply creating a new repository implementing the protocol and updating `CompositionRoot.swift`, requiring **zero changes** to Presentation or Domain layers.

2. **Combined Navigation Router**:
   - *Decision*: A unified `AppRouter` managing the `TabView` selection and detailed navigation path is injected into the environment.
   - *Trade-off*: While simple, for complex workflows with dozens of screens, we would separate navigation by features. For this companion scope, it prevents navigation routing sprawl and keeps view models completely free of navigation logic.

3. **No Third-Party Dependencies**:
   - *Decision*: The app uses native SwiftUI elements, Swift Charts, and Swift Concurrency exclusively.
   - *Trade-off*: Avoids bundle size bloat and target link issues. Custom progress rings and glassmorphic treatments are built manually to maintain high visual appeal and premium feedback.
