# 📋 Implementation Plans — Miqotul Khoir TV

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

## Overview

Kumpulan 12 implementation plan documents untuk membangun aplikasi **Miqotul Khoir TV** — jam masjid digital dan jadwal sholat untuk Android TV. Setiap plan disusun berdasarkan [6 Technical Specifications](../spec/) dan dirancang untuk eksekusi bertahap.

## 📊 Summary

| Metric | Count |
|--------|:-----:|
| Total Plans | 12 |
| Total Tasks (TASK-xxx) | ~380+ |
| Total Tests | ~160 |
| Estimated Files | ~70+ |
| Phases per Plan | 5-10 |

---

## 📑 Plan Index

### Foundation Layer

| # | Plan | Spec | Scope | Status |
|:-:|------|------|-------|:------:|
| 01 | [infrastructure-database-1.md](infrastructure-database-1.md) | SPEC-01 Part A | DatabaseHelper, DDL, migration, seed cities | ✅ |
| 02 | [feature-data-layer-1.md](feature-data-layer-1.md) | SPEC-01 Part B | Entities, models, repositories, PIN hashing | ✅ |
| 03 | [design-theme-system-1.md](design-theme-system-1.md) | SPEC-02 Part A | Colors, typography, ThemeData, ScreenUtil, TV safe area | ✅ |
| 04 | [design-ui-components-1.md](design-ui-components-1.md) | SPEC-02 Part B | GlassmorphismCard, FocusableWidget, Background, RunningText | ✅ |

### Core Business Logic

| # | Plan | Spec | Scope | Status |
|:-:|------|------|-------|:------:|
| 05 | [feature-prayer-calculation-1.md](feature-prayer-calculation-1.md) | SPEC-03 Part A | PrayerTime entities, CalculateUseCase, adhan-dart, Hijri | ✅ |
| 06 | [feature-prayer-cubit-1.md](feature-prayer-cubit-1.md) | SPEC-03 Part B | PrayerTimeCubit, states, midnight timer | ✅ |
| 07 | [feature-state-evaluation-1.md](feature-state-evaluation-1.md) | SPEC-04 Part A | DisplayState classes (5 states), EvaluateUseCase | ✅ |
| 08 | [feature-display-state-machine-1.md](feature-display-state-machine-1.md) | SPEC-04 Part B | DisplayStateCubit, tick timer, power recovery | ✅ |

### Application Features

| # | Plan | Spec | Scope | Status |
|:-:|------|------|-------|:------:|
| 09 | [feature-setup-wizard-logic-1.md](feature-setup-wizard-logic-1.md) | SPEC-05 Part A | SetupWizardCubit, validation, step navigation | ✅ |
| 10 | [feature-setup-wizard-ui-1.md](feature-setup-wizard-ui-1.md) | SPEC-05 Part B | 4 step pages, city picker, prayer preview | ✅ |
| 11 | [feature-settings-logic-1.md](feature-settings-logic-1.md) | SPEC-06 Part A | SettingsCubit, auto-save, PIN management | ✅ |
| 12 | [feature-settings-ui-1.md](feature-settings-ui-1.md) | SPEC-06 Part B | Menu pages, DPadStepper, PinInput, 6 sections | ✅ |
| 13 | [feature-main-display-ui-1.md](feature-main-display-ui-1.md) | SPEC-04 Part B & SPEC-02 | MainDisplayPage, 5 State Layouts, PrayerCards, DigitalClock | ✅ |

> **Legend**: ⬜ Planned · 🔄 In Progress · ✅ Completed

---

## 🔗 Dependency Graph

```
Wave 1 (Paralel):   Plan 01 ─────────────┐
                     Plan 03 ─────────────┤
                     Plan 04 ─────────────┘
                                          │
Wave 2:              Plan 02 ◄────────────┘ (depends on 01)
                                          │
Wave 3:              Plan 05 ◄────────────┘ (depends on 02)
                                          │
Wave 4:              Plan 06 ◄────────────┘ (depends on 05)
                                          │
Wave 5:              Plan 07 ◄────────────┘ (depends on 06)
                                          │
Wave 6:              Plan 08 ◄────────────┘ (depends on 07)
                                          │
Wave 7 (Paralel):   Plan 09 ◄────────────┤ (depends on 02, 04)
                     Plan 11 ◄────────────┘ (depends on 02, 06, 08)
                                          │
Wave 8 (Paralel):   Plan 10 ◄────────────┤ (depends on 09, 04)
                     Plan 12 ◄────────────┘ (depends on 11, 04)
```

---

## 🗂 Spec-to-Plan Mapping

| Specification | Plans |
|---------------|-------|
| [SPEC-01: Database Schema](../spec/spec-schema-database.md) | Plan 01 + 02 |
| [SPEC-02: UI Foundation](../spec/spec-design-ui-foundation.md) | Plan 03 + 04 |
| [SPEC-03: Prayer Time Calculation](../spec/spec-process-prayer-time.md) | Plan 05 + 06 |
| [SPEC-04: Display State Machine](../spec/spec-process-state-machine.md) | Plan 07 + 08 |
| [SPEC-05: Setup Wizard](../spec/spec-process-setup-wizard.md) | Plan 09 + 10 |
| [SPEC-06: Settings & Content](../spec/spec-process-settings.md) | Plan 11 + 12 |

---

## 📦 Package Dependencies Summary

| Package | Added in | Purpose |
|---------|:--------:|---------|
| `sqflite` | Plan 01 | SQLite database |
| `path` | Plan 01 | File path utils |
| `sqflite_common_ffi` | Plan 01 | Testing (dev) |
| `equatable` | Plan 02 | Value equality |
| `crypto` | Plan 02 | PIN hashing |
| `flutter_screenutil` | Plan 03 | Responsive scaling |
| `google_fonts` | Plan 03 | Typography (Poppins) |
| `marquee` | Plan 04 | Running text |
| `adhan` | Plan 05 | Prayer time calc |
| `hijri` | Plan 05 | Hijri calendar |
| `intl` | Plan 05 | Date formatting |
| `flutter_bloc` | Plan 06 | State management |
| `bloc_test` | Plan 06 | Testing (dev) |
| `mocktail` | Plan 06 | Mocking (dev) |

---

## 🚀 Execution Workflow

Setiap plan dieksekusi mengikuti phased approach dari [EXECUTION_WORKFLOW.md](../docs/EXECUTION_WORKFLOW.md):

1. **Phase Setup** → Package + file creation
2. **Phase Logic** → Business logic implementation
3. **Phase UI** → Presentation layer (jika applicable)
4. **Phase Polish** → Testing + verification

Checkpoint gates setelah setiap phase: static analysis, tests pass, user approval.
