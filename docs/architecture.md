# Architecture — Senior Companion Prototype

This document describes the technical architecture after **Group 2** and serves
as the implementation guide for future milestones.

---

## Table of contents

1. [Layer overview](#1-layer-overview)
2. [Bootstrap flow](#2-bootstrap-flow)
3. [Dependency injection with Riverpod](#3-dependency-injection-with-riverpod)
4. [Repository pattern](#4-repository-pattern)
5. [Event bus](#5-event-bus)
6. [Notification service](#6-notification-service)
7. [Storage service](#7-storage-service)
8. [Error handling and AppResult](#8-error-handling-and-appresult)
9. [Theme and design system](#9-theme-and-design-system)
10. [Routing](#10-routing)
11. [How to add a new feature module](#11-how-to-add-a-new-feature-module)
12. [How to add a new repository](#12-how-to-add-a-new-repository)
13. [AI layer integration path](#13-ai-layer-integration-path)
14. [Known prototype limitations](#14-known-prototype-limitations)

---

## 1. Layer overview

```
lib/
  app/          — App shell: bootstrap, routing, theme
  core/         — Technical services, abstractions, cross-cutting concerns
  features/     — Feature modules (one folder per product feature)
  shared/       — Models, widgets, constants, utils shared across features
```

### `lib/app`

Contains only the app-level wiring. Nothing domain-specific lives here.

| Path | Responsibility |
|---|---|
| `app/app.dart` | Root `MaterialApp.router` widget |
| `app/bootstrap/app_bootstrap.dart` | Constructs services, returns `ProviderScope` overrides |
| `app/bootstrap/app_initializer.dart` | Awaits async service initialization at startup |
| `app/bootstrap/providers.dart` | All root Riverpod providers, injected at bootstrap |
| `app/router/app_router.dart` | `GoRouter` route definitions |
| `app/router/app_routes.dart` | Route path string constants |
| `app/theme/app_theme.dart` | `ThemeData` + `AppStatusColors` extension |
| `app/theme/app_colors.dart` | Colour constants |

### `lib/core`

Cross-cutting technical services. Features import from here; core never
imports from features.

| Folder | Responsibility |
|---|---|
| `config/` | Environment-aware app configuration |
| `errors/` | `AppException` + `AppErrorMapper` |
| `events/` | Sealed `AppEvent` hierarchy, `AppEventBus`, persisted event mapping, status engine |
| `logging/` | `AppLogger` abstraction + `DebugAppLogger` |
| `networking/` | Dio client + `ApiClient.guard()` + error mapping |
| `notifications/` | `NotificationService` abstraction + local implementation |
| `permissions/` | `PermissionService` abstraction + implementation |
| `repositories/` | Repository interfaces + `local/` implementations |
| `storage/` | SharedPreferences storage + Hive structured storage bootstrap |

### `lib/features`

One folder per product feature. Each folder is self-contained:

```
features/
  my_feature/
    my_feature_screen.dart     — UI
    my_feature_providers.dart  — Riverpod providers
    my_feature_repository.dart — (optional) feature-specific repository interface
```

Features may import from `core/` and `shared/`. They must **not** import from
other feature folders directly — use the event bus for cross-feature communication.

### `lib/shared`

Reusable code with no feature ownership.

| Folder | Responsibility |
|---|---|
| `models/` | Base enums and value objects (`AppRole`, `AppResult`, `SeniorGlobalStatus`, …) |
| `widgets/` | Reusable UI components (`AppScaffoldShell`, `FeaturePlaceholderCard`) |
| `constants/` | `AppSpacing`, `Gaps`, `AppBorderRadius`, `AppConstants` |
| `utils/` | Pure utility functions (`toFriendlyErrorMessage`) |

---

## 2. Bootstrap flow

```
main()
  │
  ├─ AppEnvironment resolved from --dart-define=APP_ENV
  │
  └─ AppBootstrap.bootstrap(environment)
       │
       ├─ DebugAppLogger constructed
       ├─ AppConfig.fromEnvironment(environment)
       ├─ SharedPreferencesStorageService constructed
       ├─ HiveInitializer constructed
       ├─ LocalProfileRepository constructed
       ├─ LocalDemoSeedRepository constructed
       ├─ PermissionHandlerPermissionService constructed
       ├─ LocalNotificationService constructed
       │
       └─ AppInitializer.initialize()
            ├─ storageService.initialize()      ← awaited
            ├─ hiveInitializer.initialize()     ← awaited
            ├─ demoSeedRepository.seedIfNeeded() ← awaited
            └─ notificationService.initialize() ← awaited
       │
       └─ AppBootstrapData returned
            ├─ overrides: List<Override>   ← injected into ProviderScope
            └─ logger: AppLogger           ← used for global error handlers
  │
  ├─ FlutterError.onError wired
  ├─ PlatformDispatcher.instance.onError wired
  │
  └─ runZonedGuarded
       └─ runApp(ProviderScope(overrides: ..., child: SeniorCompanionApp()))
```

All services are constructed **before** `runApp`. The `ProviderScope` overrides
ensure every provider in `providers.dart` that declares
`throw UnimplementedError(...)` as its default is replaced with the real
instance before any widget reads it.

---

## 3. Dependency injection with Riverpod

All providers are declared in `lib/app/bootstrap/providers.dart`.

### Bootstrap-injected providers

These providers throw `UnimplementedError` by default — they **must** be
overridden in `AppBootstrap`. Reading them before the override is applied
is a programming error and will crash immediately.

```dart
final appConfigProvider = Provider<AppConfig>(
  (_) => throw UnimplementedError('must be overridden at bootstrap'),
);
```

### Derived providers

Providers that depend on bootstrap providers are declared normally. Riverpod
resolves the dependency graph automatically.

```dart
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  return buildDioClient(config, logger: ref.watch(appLoggerProvider));
});
```

### Feature providers

Feature-specific providers live in their own feature folder, not in
`providers.dart`. They read core providers via `ref.watch` or `ref.read`:

```dart
// features/check_in/check_in_providers.dart
final checkInSummaryProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(checkInRepositoryProvider);
  return repo.getTodaySummary();
});
```

### When to use `ref.watch` vs `ref.read`

| Scenario | Use |
|---|---|
| Inside `build()` or a `FutureProvider` body — reactive dependency | `ref.watch` |
| Inside a button callback, gesture handler, or user action | `ref.read` |
| Inside `initState` or lifecycle methods | `ref.read` |

Never call `ref.watch` inside callbacks — it will throw at runtime.

---

## 4. Repository pattern

### Interface location

All repository interfaces live in `lib/core/repositories/`.

```dart
// lib/core/repositories/check_in_repository.dart
abstract class CheckInRepository {
  Future<CheckInSummary> getTodaySummary(String seniorId);
  Future<void> recordCheckIn(String seniorId);
  Future<List<CheckInEvent>> getHistory(String seniorId, {int limit = 20});
}
```

### Implementation location

Concrete implementations live in subfolders of `core/repositories/`:

```
core/repositories/
  check_in_repository.dart          ← interface
  local/
  local_check_in_repository.dart  ← dedicated local store / in-memory implementation
  remote/
    remote_check_in_repository.dart ← HTTP implementation (future)
```

### Provider registration

Register the repository in `providers.dart`, pointing at the local
implementation for the prototype:

```dart
final checkInRepositoryProvider = Provider<CheckInRepository>(
  (ref) => LocalCheckInRepository(
    storage: ref.watch(storageServiceProvider),
    logger: ref.watch(appLoggerProvider),
  ),
);
```

To switch to a remote implementation later, change only this one line.

### Rules

- Features depend on the **interface**, never on a concrete class.
- Local implementations use `StorageService`, Hive, or in-memory lists for the prototype.
- Mock implementations must use `_kMockDelay` before returning data so that
  loading states are always exercised in the UI.

### G2 event repository baseline

Group 2 adds a reusable local-first event core:

- `EventRepository` interface in `core/repositories/event_repository.dart`
- `LocalEventRepository` backed by Hive `event_records` box
- timeline/history query methods:
  - per senior
  - by event type
  - recent events (newest first)
  - guardian-linked seniors
- explicit `AppEvent -> PersistedEventRecord` mapping via `AppEventMapper`

---

## 5. Event bus

The event bus enables modules to communicate without direct coupling.

### Publishing an event

```dart
await ref.read(appEventRecorderProvider).publishAndPersist(
  CheckInCompletedEvent(
    seniorId: session.activeProfileId,
    happenedAt: DateTime.now(),
  ),
  source: 'developer',
);
```

`AppEventRecorder` is the canonical G2 path for prototype actions that must both
publish runtime events and persist timeline records.

### Subscribing to events

Subscribe inside a Riverpod `Notifier`, `StateNotifier`, or a service
constructor. Cancel the subscription when the object is disposed.

```dart
class GuardianDashboardNotifier extends AutoDisposeNotifier<DashboardState> {
  StreamSubscription<AppEvent>? _sub;

  @override
  DashboardState build() {
    _sub = ref.read(appEventBusProvider).stream.listen(_onEvent);
    ref.onDispose(() => _sub?.cancel());
    return const DashboardState.initial();
  }

  void _onEvent(AppEvent event) {
    switch (event) {
      case CheckInCompletedEvent(:final seniorId):
        // update dashboard state
      case MedicationMissedEvent(:final medicationName):
        // generate alert
      default:
        break;
    }
  }
}
```

### Adding a new event type

1. Add the new case to `AppEventType` enum in `app_event.dart`.
2. Add a new `final class MyNewEvent extends AppEvent` with the relevant fields.
3. Extend `AppEventMapper` so the event has a stable persisted payload.
4. Every exhaustive `switch` in the codebase that handles `AppEvent` will
   produce a compile-time warning until the new case is handled.

### Rules

- Events flow **one way**: producers publish, consumers subscribe.
- Do not use the event bus to pass data back to the producer — use a
  `Future` return value or a shared Riverpod provider instead.
- Events must be immutable value objects. No mutable state in event payloads.

---

## 6. Notification service

### Severity levels

| Level | When to use |
|---|---|
| `info` | Routine reminders (medication due, check-in reminder) |
| `warning` | Something needs attention (missed check-in, missed medication) |
| `critical` | Immediate action required (unresolved incident, emergency) |

### Usage from a feature

```dart
final notifications = ref.read(notificationServiceProvider);

// Routine reminder
await notifications.showInfo(
  title: 'Medication reminder',
  body: 'Time to take Aspirin',
);

// Guardian alert
await notifications.showCritical(
  title: 'Action required',
  body: 'Ahmed has not checked in for 4 hours',
);
```

### Permission handling

The notification service checks permission before showing each notification.
If permission is not granted, the notification is silently skipped with a log
warning. Request permission explicitly during onboarding:

```dart
await ref.read(notificationServiceProvider).requestPermission();
```

---

## 7. Storage service

Group 1 storage policy uses two layers:

- `StorageService` (`SharedPreferences`) for lightweight preferences/flags/session.
- Hive for structured local entities (profiles, links, event records, future entities).

### SharedPreferences usage

`StorageService` remains a thin abstraction over SharedPreferences and should be
used only for simple values.

```dart
final storage = ref.read(storageServiceProvider);

// Write
await storage.setString(StorageKeys.preferredRole, 'guardian');
await storage.setBool(StorageKeys.notificationsEnabled, true);
await storage.setStringList('dismissed_banners', ['v1.0', 'v1.1']);

// Read
final role = storage.getString(StorageKeys.preferredRole);
final enabled = storage.getBool(StorageKeys.notificationsEnabled) ?? false;
```

### Adding a new storage key

Add a `static const String` to `StorageKeys` in `lib/core/storage/storage_keys.dart`:

```dart
class StorageKeys {
  static const appSession = 'app_session';
  static const preferredRole = 'preferred_role';
  static const myNewKey = 'my_new_key';  // ← add here
}
```

Never use raw string literals for storage keys outside of `StorageKeys`.

### Hive structured entity storage (G1)

Hive is initialized during bootstrap via `HiveInitializer`, and these boxes are
opened at startup:

- `senior_profiles`
- `guardian_profiles`
- `profile_links`
- `event_records`
- `prototype_metadata`

Local repositories use those boxes for profile/session-adjacent prototype data.

### G2 status engine

`SeniorStatusEngine` derives `SeniorGlobalStatus` from persisted events with
deterministic, explainable rules:

1. emergency event or unresolved confirmed incident -> `actionRequired`
2. unresolved suspected incident -> `watch` (unless already escalated)
3. three or more missed routine signals today (missed check-ins + meds) -> `actionRequired`
4. one or two missed routine signals -> `watch`
5. otherwise -> `ok`

`LocalDashboardRepository` aggregates these outputs into `DashboardSummary`
for Home/Guardian views without mock counters.

### Demo data reset workflow

Settings exposes developer actions for fast demo iteration:

- **Clear Session**: removes local session and returns to onboarding.
- **Reseed Demo Data**: clears and re-seeds deterministic profile/link data.
- **Reset Demo Data**: clears structured data and seed marker, then clears session.

### When NOT to use StorageService

Do not store structured entities in SharedPreferences. Use Hive-backed local
repositories instead.

---

## 8. Error handling and AppResult

### AppResult

`AppResult<T>` is a sealed class with two subtypes: `Success<T>` and `Failure<T>`.

```dart
// Producing
AppResult<int> result = AppResult.success(42);
AppResult<int> error  = AppResult.failure(ApiError(...));

// Consuming — exhaustive
final message = result.when(
  success: (value) => 'Loaded $value items',
  failure: (error) => error.userMessage,
);

// Consuming — nullable shortcut
final value = result.getOrNull(); // int? — null on failure
```

Use `AppResult` as the return type of any repository method or service call
that can fail in a domain-meaningful way.

### AppException

`AppException` is the structured exception type used throughout core services.
It carries both a technical `message` (for logs) and a `userMessage` (safe to
display in the UI).

```dart
throw AppException(
  code: 'checkin-failed',
  message: 'Storage write returned false for key check_in_2024_01_01',
  userMessage: 'Could not save your check-in. Please try again.',
);
```

### Global error handlers

Three global error boundaries are wired in `main.dart`:

| Handler | Catches |
|---|---|
| `FlutterError.onError` | Framework-level widget and rendering errors |
| `PlatformDispatcher.instance.onError` | Platform channel errors |
| `runZonedGuarded` | All other uncaught Dart exceptions and async errors |

All three log to `AppLogger` and do not swallow the error.

---

## 9. Theme and design system

### Accessing the theme

```dart
// Standard Material theme
final textTheme = Theme.of(context).textTheme;
final colorScheme = Theme.of(context).colorScheme;

// Custom status colors extension
final statusColors = Theme.of(context).extension<AppStatusColors>()!;
Color okColor = statusColors.ok;
Color watchColor = statusColors.watch;
Color actionRequiredColor = statusColors.actionRequired;
```

### Typography scale

| Style | Size | Weight | Use case |
|---|---|---|---|
| `displayLarge` | 32sp | w700 | Senior confirmation screens ("I'm okay") |
| `headlineLarge` | 28sp | w700 | Hero headings |
| `headlineSmall` | 20sp | w700 | Screen titles, section headings |
| `titleLarge` | 18sp | w600 | Card headings |
| `bodyLarge` | 18sp | w400 | Primary body text (senior-readable) |
| `bodyMedium` | 16sp | w400 | Secondary body text |
| `labelLarge` | 16sp | w600 | Button labels |

All sizes are intentionally larger than Material defaults to meet the
senior accessibility requirement of minimum 18sp body text.

### Button variants

| Button | Min height | Use case |
|---|---|---|
| `ElevatedButton` | 48px | Standard actions |
| `FilledButton` | 56px, full-width | Senior primary actions ("I'm okay", "Confirm") |
| `OutlinedButton` | 48px | Secondary and destructive actions |
| `TextButton` | 44px | Inline links and tertiary actions |

### Spacing and border radius

```dart
// Spacing
AppSpacing.sm   //  8px
AppSpacing.md   // 16px
AppSpacing.lg   // 24px
AppSpacing.xl   // 32px
AppSpacing.xxl  // 48px — senior tap target height

// Prebuilt gap widgets
Gaps.v16        // vertical SizedBox(height: 16)
Gaps.h8         // horizontal SizedBox(width: 8)

// Border radius
AppBorderRadius.mdAll  // BorderRadius.circular(12) — cards, inputs
AppBorderRadius.lgAll  // BorderRadius.circular(16) — sheets, modals
AppBorderRadius.pillAll // BorderRadius.circular(999) — chips, badges
```

---

## 10. Routing

Routes are defined in `lib/app/router/app_routes.dart` (path constants) and
`lib/app/router/app_router.dart` (GoRouter configuration).

### Current routes

| Constant | Path | Screen |
|---|---|---|
| `AppRoutes.splash` | `/splash` | `SplashScreen` |
| `AppRoutes.onboardingRole` | `/onboarding/role` | `RoleSelectionScreen` |
| `AppRoutes.onboardingProfile` | `/onboarding/profile/:role` | `ProfileSelectionScreen` |
| `AppRoutes.home` | `/home` | `HomeScreen` (demo hub) |
| `AppRoutes.seniorHome` | `/senior` | `SeniorHomePlaceholderScreen` |
| `AppRoutes.guardianHome` | `/guardian` | `GuardianHomePlaceholderScreen` |
| `AppRoutes.settings` | `/settings` | `SettingsScreen` |

### Splash routing logic

The splash screen reads the active local session and routes accordingly:

- Session exists with senior role → `/senior`
- Session exists with guardian role → `/guardian`
- No valid session/profile → `/onboarding/role`

From onboarding:
- Role selected at `/onboarding/role`
- Demo profile selected at `/onboarding/profile/:role`
- Session created locally and routed to role experience

### Navigation

```dart
// Navigate and replace current route
context.go(AppRoutes.seniorHome);

// Push on top of the current route
context.push(AppRoutes.settings);

// Pop back
context.pop();
```

---

## 11. How to add a new feature module

### Step 1 — Create the feature folder

```
lib/features/check_in/
  check_in_screen.dart
  check_in_providers.dart
```

### Step 2 — Add the route

In `lib/app/router/app_routes.dart`:
```dart
static const checkIn = '/check-in';
```

In `lib/app/router/app_router.dart`, add a `GoRoute` to the routes list:
```dart
GoRoute(
  path: AppRoutes.checkIn,
  name: 'check-in',
  builder: (_, __) => const CheckInScreen(),
),
```

### Step 3 — Create feature providers

In `lib/features/check_in/check_in_providers.dart`:
```dart
final checkInSummaryProvider = FutureProvider.autoDispose((ref) {
  final repo = ref.watch(checkInRepositoryProvider);
  return repo.getTodaySummary('current-senior-id');
});
```

### Step 4 — Use providers in your screen

```dart
class CheckInScreen extends ConsumerWidget {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(checkInSummaryProvider);
    return summaryAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
      data: (summary) => Text('Check-ins today: ${summary.count}'),
    );
  }
}
```

### Step 5 — Publish domain events

When the senior performs an action, publish the appropriate event:
```dart
ref.read(appEventBusProvider).publish(
  CheckInCompletedEvent(seniorId: seniorId, happenedAt: DateTime.now()),
);
```

---

## 12. How to add a new repository

### Step 1 — Define the interface

```dart
// lib/core/repositories/check_in_repository.dart
abstract class CheckInRepository {
  Future<int> getTodayCount(String seniorId);
  Future<void> record(String seniorId);
}
```

### Step 2 — Write the local implementation

```dart
// lib/core/repositories/local/local_check_in_repository.dart
const _kMockDelay = Duration(milliseconds: 300);

class LocalCheckInRepository implements CheckInRepository {
  LocalCheckInRepository({required this.storage});
  final StorageService storage;

  @override
  Future<int> getTodayCount(String seniorId) async {
    await Future.delayed(_kMockDelay);
    return storage.getInt('checkin_count_$seniorId') ?? 0;
  }

  @override
  Future<void> record(String seniorId) async {
    final current = storage.getInt('checkin_count_$seniorId') ?? 0;
    await storage.setInt('checkin_count_$seniorId', current + 1);
  }
}
```

### Step 3 — Register the provider

In `lib/app/bootstrap/providers.dart`:
```dart
final checkInRepositoryProvider = Provider<CheckInRepository>(
  (ref) => LocalCheckInRepository(
    storage: ref.watch(storageServiceProvider),
  ),
);
```

---

## 13. AI layer integration path

The AI contributor's work (summaries, prioritization, TTS, companion chat)
will be integrated by:

### Step 1 — Define the AI service interfaces in `core/`

```dart
// lib/core/ai/ai_summary_service.dart
abstract class AiSummaryService {
  Future<String> generateDailySummary(String seniorId, DateRange range);
}

// lib/core/ai/ai_alert_prioritizer.dart
abstract class AiAlertPrioritizer {
  Future<List<Alert>> prioritize(List<Alert> alerts);
}
```

### Step 2 — Create stub implementations for the prototype

```dart
class StubAiSummaryService implements AiSummaryService {
  @override
  Future<String> generateDailySummary(String seniorId, DateRange range) async {
    return 'Ahmed had a normal day. One missed medication in the evening. '
           'Check-in completed in the morning.';
  }
}
```

### Step 3 — Register in providers.dart

```dart
final aiSummaryServiceProvider = Provider<AiSummaryService>(
  (ref) => StubAiSummaryService(),
);
```

### Step 4 — Replace the stub

When the AI contributor delivers their implementation, replace the stub
in `providers.dart`:

```dart
final aiSummaryServiceProvider = Provider<AiSummaryService>(
  (ref) => GeminiAiSummaryService(apiKey: ref.watch(appConfigProvider).aiApiKey),
);
```

No other file needs to change.

---

## 14. Known prototype limitations

| Limitation | Location | Target milestone |
|---|---|---|
| `mock_dashboard_repository` keeps hardcoded fallback values (non-source of truth after G2) | `mock_dashboard_repository.dart` | Backlog cleanup |
| No dark theme | `app_theme.dart` | G8 |
| `AppSession.toJson/fromJson` remains manual (no codegen) | `app_session.dart` | G2+ |
| Dio is configured but never used | `networking/` | Later API milestone |
| Widget/bootstrap routing tests need expansion over time | `test/` | Iterative |
