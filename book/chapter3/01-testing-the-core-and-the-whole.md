# Testing the core and the whole

> **Draft.** The position and its why are here. The example and some sources are still to do.

The split between pure and impure code ([Axiom 5](../chapter2/axiom-05-impure-functions.md), [Axiom 6](../chapter2/axiom-06-pure-functions.md), [Axiom 13](../chapter2/axiom-13-impureim.md)) decides three things at once: what to share, what to abstract, and what to test, and how.

| | Pure core | Impure shell |
|---|---|---|
| **Share (DRY)** | Yes: validation, transformations, decisions. These are business rules. | No: orchestration repeats its shape, not its knowledge ([Axiom 8](../chapter2/axiom-08-cohesion.md#what-dry-is-for)). |
| **Abstract** | Name concepts with types and functions. | Don't wrap it: no facade over the database or the framework. |
| **Test** | Function tests: values in, value out. | Service tests: the whole service with its real dependencies, plus simulators for systems you don't own. |

The three rows hold each other up. A repository interface usually exists so a unit test can mock it ([Chapter 1](../chapter1/README.md#why-it-became-that)). Without that test, the interface has no job left. And once the shell is never unit-tested, there is no reason to make it reusable either.

## Problem / forces

- The common C# setup: a controller calls an `IOrderRepository`, whose single implementation calls a `DbContext`. The interface and the class add a layer that hides nothing.
- Unit tests of controllers need mocks of every dependency. They test the wiring, not the behavior, and break on every refactor of the wiring.
- Three controllers that fetch from the same table, transform the data and save, publish or return it look alike. The reflex is to merge them into one generic handler, or one function that takes a "transformation" parameter. That couples three reasons to change behind one body.

## What I do today

- **Share only pure code.** Input validation and transformation logic are shared. Orchestration repeats, and that's fine.
- **Don't hide impure code behind a reusable facade.** The controller (the orchestrator) uses `DbContext` (or jOOQ's `DSLContext`) directly.
- **Test in two layers:**
  - pure functions: function tests;
  - the whole service: service tests, with real dependencies (for example a real database in a container) and simulators for third-party systems.
- **No function tests for controllers.** The controller is the orchestrator of the Impureim sandwich; the service tests cover it.

## Why

**1. The infrastructure is tested where it can fail.**
Leaving the shell out of function tests doesn't leave it untested. A mocked repository can't fail the way a real database does: a wrong column type, a missing index, a constraint, a transaction that deadlocks. A service test runs against a real database (in a container), so it finds exactly those failures. The shell is tested at the only level where its bugs show up.

**2. Tests at stable boundaries survive refactoring.**
A function test on a controller mocks what the controller calls, so it encodes the wiring: which method is called, in which order, with which arguments. Change the wiring without changing the behavior, and those tests break anyway. The time goes into updating tests that found nothing. Tests that call a pure function through its signature, or a service through its own entry points, only break when the behavior changes.

**3. Decisions are cheap to test thoroughly; the shell is thin.**
A pure function needs no setup, so every edge case of a rule costs one line of test. The shell holds no decisions, so a few service tests cover its paths. The expensive level gets few tests, and the cheap level gets many.

**4. Without the mocks, the interfaces have no job.**
An `IOrderRepository` next to its only `OrderRepository` usually exists so a unit test can replace it. Apply [Chapter 1](../chapter1/README.md)'s [decisions-vs-ceremony test](../chapter1/README.md#enforce-decisions-not-ceremony): remove it, and the reader loses nothing.

## C#/Java example

> To do. A controller calling `DbContext` / `DSLContext` directly, a pure decision it calls, the function test for the decision, and a service test with a real database.

## Trade-offs & when NOT to

- Whole-service tests are slower and need test infrastructure (containers, simulators).
- **Exception for frameworks and libraries:** infrastructure written once for many applications is its own product, with its own reason to change. It is shared, and it is tested on its own.

> **Open question: "never unit-test the controller".** Is this an absolute rule, or "never, and if you feel the need, the logic is in the wrong place"? The second reading says: when an orchestrator has enough branching that you *want* to unit-test it, logic has leaked into the shell, and it should move into a pure function that returns actions ([Axiom 24](../chapter2/axiom-24-pure-functions-returning-actions.md)) instead of being mocked. To decide when this file is written.

## What might change tomorrow

- Tool choices (Testcontainers, WireMock and similar) are dated decisions. They go in ADRs once the ADR location is decided.

## Open questions

- **Sources to verify before citing:** Gary Bernhardt, *Boundaries* (SCNA 2012) — unit-test the core, integration-test the shell (his *Functional Core, Imperative Shell* screencast is verified and cited in [Axiom 13](../chapter2/axiom-13-impureim.md)); Spotify's "testing honeycomb" (2018).
