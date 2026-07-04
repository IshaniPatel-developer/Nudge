# Nudge - GLP-1 Titration & Lifestyle Companion

Nudge is a SwiftUI companion application designed for users tracking weekly GLP-1 injection doses alongside daily lifestyle metrics (Water, Protein, Steps). Built using **Clean Architecture** and **MVVM** design patterns, the app follows standard industry engineering practices, avoiding singletons and AI patterns.

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
   - Entirely independent of UI frameworks (except SwiftUI gradients on lightweight configuration enums) and database layers.
   - Contains pure business models (`DoseSchedule`, `DoseLog`, `LifestyleLog`), repository abstractions, and UseCases that coordinate operations.
   - The titration progression schedule is dynamically computed rather than hardcoded.

2. **Data Layer**:
   - Implements Domain-defined repository protocols (`DoseRepositoryProtocol`, `LifestyleRepositoryProtocol`).
   - Mock repositories (`MockDoseRepository`, `MockLifestyleRepository`) seed realistic progress trends and titration history.
   - Utilizes thread-safe synchronization (`NSLock`) to mimic real-world database access.

3. **Presentation Layer**:
   - SwiftUI views utilizing a dedicated Router for navigation.
   - Decoupled ViewModels that interact strictly with UseCases.
   - Fully supports **Dynamic Type**, **Safe Areas**, and **Dark/Light Mode** rendering.
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
│   ├── Theme/                  # Dynamic colors, gradient catalogs, typography
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
        ├── Dashboard/          # Dashboard weekly schedules & metrics log list
        └── Analytics/          # Swift Charts trend visualizer
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
2. Select the `Nudge` scheme and choose a simulator (e.g., iPhone 17).
3. Press `CMD + R` to compile and run.
4. Alternatively, to run via Terminal:
   ```bash
   # Boot simulator (iPhone 17)
   open -a Simulator
   xcrun simctl bootstatus "iPhone 17"
   
   # Build for simulator
   xcodebuild -project Nudge.xcodeproj -scheme Nudge -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build
   
   # Install and run
   xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/Nudge-*/Build/Products/Debug-iphonesimulator/Nudge.app
   xcrun simctl launch booted com.Nudge
   ```

### Running Unit Tests
To execute the suite of unit tests verifying titration math, date countdowns, and completion metrics:
```bash
xcodebuild test -project Nudge.xcodeproj -scheme Nudge -destination 'platform=iOS Simulator,name=iPhone 17'
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

---

## Future Improvements

1. **Persistency Integration**:
   - Swap mock repositories for SwiftData or CoreData implementations to persist logged injections and daily metrics across launches.
2. **Apple HealthKit Sync**:
   - Bind steps and water logging directly to HealthKit so steps update automatically in the background without requiring manual logs.
3. **Local Push Notifications**:
   - Schedule notifications to alert users when their GLP-1 countdown is reaching zero, or to nudge them to log their lifestyle statistics in the evening.
