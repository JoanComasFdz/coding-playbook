# Testing the core and the whole

> **Placeholder.** This file collects the author's position and the open questions around it. The full write-up, examples and sources are still to do.

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

> To do. Points to develop:
> - Mocks test wiring, not behavior; service tests test what users see.
> - Pure functions are cheap to test exhaustively; the shell is thin, so a few service tests cover it.
> - Apply the [decisions-vs-ceremony test](../chapter1/README.md#enforce-decisions-not-ceremony) from [Chapter 1](../chapter1/README.md) to the repository interface: remove it, and the reader loses nothing.

## C#/Java example

> To do. A controller calling `DbContext` / `DSLContext` directly, a pure decision it calls, the function test for the decision, and a service test with a real database.

## Trade-offs & when NOT to

- Whole-service tests are slower and need test infrastructure (containers, simulators).
- **Exception for frameworks and libraries:** infrastructure written once for many applications is its own product, with its own reason to change. It is shared, and it is tested on its own.

> **Open question: "never unit-test the controller".** Is this an absolute rule, or "never, and if you feel the need, the logic is in the wrong place"? The second reading says: when an orchestrator has enough branching that you *want* to unit-test it, logic has leaked into the shell, and it should move into a pure function that returns actions ([Axiom 24](../chapter2/axiom-24-pure-functions-returning-actions.md)) instead of being mocked. To decide when this file is written.

## What might change tomorrow

- Tool choices (Testcontainers, WireMock and similar) are dated decisions. They go in ADRs once the ADR location is decided.

## Open questions

- **Repository section of the DDD Play.** [DDD tactical patterns](../chapter4/01-DDD-tactical-patterns.md#repository) currently defines a repository as `LoadOrder` / `SaveOrder` delegates, an abstraction this file argues against. Decide whether it goes, or when a named load/save function earns its place (for example, a query many handlers share).
- **Sources to verify before citing:** Gary Bernhardt, *Boundaries* (SCNA 2012) — unit-test the core, integration-test the shell (his *Functional Core, Imperative Shell* screencast is verified and cited in [Axiom 13](../chapter2/axiom-13-impureim.md)); Spotify's "testing honeycomb" (2018).
