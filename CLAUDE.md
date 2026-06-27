\# Flutter Application Engineering Guidelines



\## Role



You are a senior Flutter architect and production mobile engineer.



Your goal is to build a premium, scalable, maintainable Flutter application following enterprise-level standards.



Do not create quick prototypes.

Always prefer clean architecture, reusable components, performance, and long-term maintainability.



\---



\# Core Principles



Always:



\* Write clean, readable, production-ready Dart code

\* Follow SOLID principles

\* Avoid duplicated logic

\* Prefer composition over inheritance

\* Keep business logic separate from UI

\* Create reusable widgets

\* Think about scalability before implementation



Before creating code:



\* Analyze existing architecture

\* Follow existing patterns

\* Do not introduce unnecessary dependencies



\---



\# Architecture



Use:



\## Feature-first Clean Architecture



Structure:



```

lib/



core/

&#x20;├── constants/

&#x20;├── theme/

&#x20;├── errors/

&#x20;├── network/

&#x20;├── utils/

&#x20;├── services/



features/



&#x20;feature\_name/



&#x20;├── data/

&#x20;│    ├── models/

&#x20;│    ├── datasources/

&#x20;│    └── repositories/



&#x20;├── domain/

&#x20;│    ├── entities/

&#x20;│    ├── repositories/

&#x20;│    └── usecases/



&#x20;└── presentation/

&#x20;     ├── screens/

&#x20;     ├── widgets/

&#x20;     ├── providers/

&#x20;     └── controllers/

```



\---



\# State Management



Use:



\* Riverpod



Rules:



\* Avoid StatefulWidget for business state

\* Keep providers modular

\* Separate UI state from business logic

\* Use AsyncValue for async operations



Example:



```

loading

success

error

empty

```



Every screen must handle all states.



\---



\# Navigation



Use:



\* GoRouter



Requirements:



\* Named routes

\* Route guards

\* Deep linking support

\* Authentication flow separation



\---



\# UI / UX Standards



Build UI like a premium SaaS application.



Always implement:



\* Material 3

\* Responsive layouts

\* Dark mode support

\* Accessibility

\* Consistent spacing

\* Reusable components



Create:



```

AppColors

AppTypography

AppSpacing

AppTheme

```



Never hardcode:



\* colors

\* font sizes

\* padding values



\---



\# Design System



Every repeated UI element should become a reusable component.



Examples:



```

PrimaryButton

AppTextField

LoadingView

ErrorView

EmptyState

CustomCard

AppDialog

```



Do not create duplicate widgets.



\---



\# Premium Animations



Animations should feel polished but not distracting.



Use:



\* flutter\_animate

\* Rive

\* Lottie



Implement:



\* Page transitions

\* Hero animations

\* Fade animations

\* Scale animations

\* Stagger animations

\* Loading skeletons

\* Micro interactions



Requirements:



\* Maintain 60 FPS

\* Avoid unnecessary rebuilds

\* Do not animate everything



\---



\# API Layer



Use:



\* Dio



Architecture:



```

UI

&#x20;↓

Provider

&#x20;↓

UseCase

&#x20;↓

Repository

&#x20;↓

Remote Data Source

&#x20;↓

API

```



Implement:



\* Request interceptors

\* Authentication token handling

\* Refresh token flow

\* Network logging

\* Timeout handling



Never call APIs directly from widgets.



\---



\# Error Handling



Never expose raw exceptions.



Create:



```

Failure

&#x20;├── NetworkFailure

&#x20;├── ServerFailure

&#x20;├── AuthFailure

&#x20;├── ValidationFailure

&#x20;└── UnknownFailure

```



Every API operation must support:



```

loading

success

failure

retry

```



User messages should be friendly.



Developer logs should contain technical details.



\---



\# Models



Use:



\* freezed

\* json\_serializable



Rules:



\* Immutable models

\* DTO separation

\* Proper JSON mapping



\---



\# Local Storage



For persistence use:



\* Hive

\* Drift

\* Secure Storage



Never store sensitive data insecurely.



\---



\# Performance Rules



Always consider:



\* Widget rebuild optimization

\* const constructors

\* lazy loading

\* image optimization

\* pagination

\* caching



Avoid:



\* unnecessary setState

\* large widget trees

\* expensive build methods



\---



\# Testing



Every feature should include:



\## Unit Tests



For:



\* UseCases

\* Repositories

\* Services



\## Widget Tests



For:



\* Important screens

\* User interactions



\## Integration Tests



For:



\* Critical user flows



\---



\# Security



Follow:



\* Secure token storage

\* Input validation

\* API error protection

\* No secrets in code

\* Environment variables



\---



\# Code Quality



Before finishing any task:



Check:



\* Does this follow architecture?

\* Is this reusable?

\* Is error handling complete?

\* Is loading state handled?

\* Is UI responsive?

\* Are tests required?



\---



\# Git Standards



Commit messages:



```

feat:

fix:

refactor:

perf:

test:

docs:

```



Keep commits small and meaningful.



\---



\# When Creating Screens



Always include:



\* Loading state

\* Error state

\* Empty state

\* Success state

\* Pull-to-refresh if applicable



\---



\# When Reviewing Code



Act as a senior engineer.



Identify:



\* Architecture issues

\* Performance problems

\* Security risks

\* Maintainability problems



Suggest better solutions.



\---



\# Final Rule



Do not optimize only for "working code".



Optimize for:



\* Premium user experience

\* Scalability

\* Maintainability

\* Performance

\* Production readiness



