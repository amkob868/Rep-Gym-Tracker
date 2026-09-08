# Rep — Gym Tracker

A native iOS workout tracker built with **SwiftUI** and an **AWS Amplify** serverless backend. Log workouts on a calendar, track sets/reps/weight per exercise, and see your progress, personal records, and streaks — all synced to the cloud and scoped to the signed-in user.

> Formerly prototyped as "Forge"; some internal type names still use that prefix.

---

## Features

- **Email/password auth** via Amazon Cognito, with automatic session restoration and expired-session handling (routes back to login instead of failing silently).
- **Calendar-based tracking** — tap any day to log or edit that day's workout; saved days are marked on the calendar.
- **Per-exercise logging** — sets, reps, and weight, including per-set custom values.
- **Progress dashboard** — real stats computed from your history: workouts this month, total sets, personal records, and a weight-progression chart per exercise.
- **Personal records** — heaviest set per exercise, de-duplicated case-insensitively so "Pull Ups" and "pull ups" collapse into one record.
- **Streaks** — a true consecutive-day streak derived from workout dates.

## Tech stack

| Layer | Technology |
|-------|------------|
| UI | SwiftUI, Swift Charts |
| Auth | AWS Amplify · Amazon Cognito (User Pools) |
| API | AWS AppSync (GraphQL) with owner-based authorization |
| Data | Amazon DynamoDB (via Amplify models) |
| Language | Swift 5, async/await, default main-actor isolation |

## Architecture

- **`WorkoutService`** — a single service layer that owns all data access (GraphQL fetch/save with a date predicate, an actor-based cache, upsert-on-save) and all analytics as pure, testable functions (personal records, streak, weekly volume, weight progression, timezone-safe date handling).
- **`AppState`** — app-wide observable state (auth status, profile, current plan) and the single source of truth for "signed in".
- **Views** are thin: they render state and delegate work to `WorkoutService`. Screens like the day editor, calendar, and progress dashboard are composed from small subviews.
- **Amplify models** (`Workout`, `CompletedExercise`, `CompletedSet`) are generated from the GraphQL schema (`amplifybackendapigymreptrackerschema.graphql`).

## Building it yourself

This repo intentionally **excludes the AWS configuration** (`amplifyconfiguration.json` / `awsconfiguration.json`) and the Amplify backend definitions — they contain environment-specific identifiers. To run it against your own backend:

1. Install [Amplify CLI](https://docs.amplify.aws/) and run `amplify init` / `amplify pull` in the project, or create a User Pool + AppSync API matching the schema in `amplifybackendapigymreptrackerschema.graphql`.
2. Drop the generated `amplifyconfiguration.json` and `awsconfiguration.json` into the app target.
3. Open `Rep - Gym Tracker.xcodeproj`, select an iOS Simulator, and run.

Requires Xcode 16+ and iOS 17+.

## Screenshots

_Add screenshots here (e.g. `docs/home.png`, `docs/progress.png`) and reference them:_

```
![Home](docs/home.png) ![Progress](docs/progress.png)
```

## License

[MIT](LICENSE)
