# Chapter 3 — Testing

[Chapter 2](../chapter2/README.md) split every module into a pure core and an impure shell. That split also decides how the code is tested. This chapter says how. None of it depends on whether the shell talks to a database, a feed or a queue.

> **Draft.** The position and its why are here. The example and some sources are still to do.

## Name tests by what they test

"Unit", "integration" and "end-to-end" name a test by how many components it runs, and teams rarely agree on what a unit is. I name a test by what it tests:

| Test | What it tests | What it runs against | Commonly called |
|---|---|---|---|
| **Function** | One pure function: values in, value out. | Nothing but the function. | Unit test |
| **Service** | One deployable service, through its own entry points. | Its own real dependencies (a real database in a container), and simulators for systems owned by others. | Integration or acceptance test |
| **Product** | The whole product, as its users see it. | Every service of the product, deployed together. | End-to-end test |
| **Solution** | Several products working together. | The products involved, deployed together. | System or end-to-end test |

Each level up is slower and more expensive to run, and finds a bug further from the line that caused it. Below all of them sits the compiler, the cheapest check of all ([Chapter 1](../chapter1/README.md#the-goal-a-codebase-that-is-a-search-oracle)).

## Problem / forces

- **A layer that hides nothing.** The common C# setup: a controller calls an `IOrderRepository`, whose only implementation calls a `DbContext`. The interface exists so a unit test can mock it ([Chapter 1](../chapter1/README.md#why-it-became-that)).
- **Tests of the wiring.** Testing a controller alone means mocking every dependency. The test checks which calls happen in which order, not what the service does, and breaks on every refactor of the wiring.
- **Service tests have a reputation.** Slow to run, hard to write, painful to maintain. That reputation is part of why the shell gets mocked instead.

## What I do today

The split between pure and impure code ([Axiom 5](../chapter2/axiom-05-impure-functions.md), [Axiom 6](../chapter2/axiom-06-pure-functions.md), [Axiom 13](../chapter2/axiom-13-impureim.md)) decides three things at once:

| | Pure core | Impure shell |
|---|---|---|
| **Share** | Yes: validation, transformations, decisions. These are business rules. | No: orchestration repeats its shape, not its knowledge ([Axiom 8](../chapter2/axiom-08-cohesion.md#what-dry-is-for)). |
| **Abstract** | Name concepts with types and functions. | Don't wrap it: no facade over the database or the framework. The controller uses `DbContext` (or jOOQ's `DSLContext`) directly. |
| **Test** | **Function tests**, thoroughly. | **Service tests**, not function tests. |

The three rows hold each other up. Without a mock to feed, the interface has no job. And once the shell is never tested alone, there is no reason to make it reusable either.

In practice:

- **The pure core gets function tests.** Decisions over immutable values need no setup and no mocks. Every edge case of a rule is one more test.
- **The shell gets service tests.** A controller, a mapper and the database access hold no decisions of their own, so they are never tested alone. A service test runs them for real.
- **Service tests run the service in-process, with real dependencies.** The test hosts the whole service and calls its endpoints. Its own database runs for real, in a container. Only systems owned by others are replaced, by simulators that behave like them at the protocol level.
- **Fewer, broader service tests.** One service test covers the handler, the mapping and the database access of a path together. A few per path are enough, because the decisions are already covered.
- **Products and solutions get a few tests on the paths that matter most.** They are the most expensive to run and to keep working.

## Why

**1. The infrastructure is tested where it can fail.**
Leaving the shell out of function tests doesn't leave it untested. A mocked repository can't fail the way a real database does: a wrong column type, a missing index, a constraint, a deadlock, a missing migration. A service test runs against the real one, so it finds exactly those failures.

**2. Tests at stable boundaries survive refactoring.**
A test that mocks what a controller calls encodes the wiring: which method is called, in which order, with which arguments. Change the wiring without changing the behavior, and the test breaks anyway. Tests that call a pure function through its signature, or a service through its own entry points, only break when the behavior changes.

**3. The cheap level gets many tests, the expensive one few.**
A pure function needs no setup, so thorough testing costs little there. The shell holds no decisions, so a few service tests cover its paths.

**4. A failing service test points somewhere.**
The usual objection to service tests is that a failure doesn't say *where*. Here it mostly does. Every decision lives in the core and has function tests, so a wrong rule fails a function test that names it. A service test that fails while every function test passes points at the shell: the wiring, the mapping, the database or a simulator. The shell is thin, so that search is short. It is the property [Chapter 1](../chapter1/README.md#the-goal-a-codebase-that-is-a-search-oracle) asks of an oracle: say *where* when the answer is no.

For example, a refund is decided by a pure `DecideRefund(order, request, today)`, function-tested with one test per rule. If a service test then fails with *"cannot insert NULL into column `refunded_at`"* while every `DecideRefund` test passes, the rule is fine and the mapping to the row is not.

**5. Service tests are cheaper than their reputation.**
Starting a database container takes seconds, once per test run. After that, a request that validates input and writes a row takes milliseconds. And a service test is cheaper to keep than the mocks it replaces: it only changes when the service's behavior changes.

**6. Without the mocks, the interfaces have no job.**
Apply [Chapter 1](../chapter1/README.md)'s [decisions-vs-ceremony test](../chapter1/README.md#enforce-decisions-not-ceremony) to the `IOrderRepository` next to its only implementation: remove it, and the reader loses nothing.

## C#/Java example

> **To do.** A controller using `DbContext` / `DSLContext` directly and calling a pure decision; the function tests for the decision; and a service test that hosts the service in-process, runs the database in a container, calls one endpoint and checks the stored row.

## Trade-offs & when NOT to

- **The setup is real work.** Containers, test data, simulators and their upkeep cost time, most of all in a service with many dependencies. Cheaper than its reputation, not free.
- **Large suites still add up.** Thousands of service tests are slow, however fast each one is. Keep them to the paths that matter, and push every decision down into function tests.
- **When logic has leaked into the shell.** A handler that branches on business conditions is no longer thin, and a failing service test no longer points anywhere useful. Move the logic into the core instead of testing the handler alone (see *Open questions*).
- **Timing and concurrency.** A service test can show that something goes wrong under load or interleaving without showing where. Those failures need their own investigation.
- **Frameworks and libraries.** Infrastructure written once for many applications is its own product, with its own reason to change. It is shared, and tested on its own.

## Scope

This chapter is about tests as code: what to test, at which level, and how. CI pipelines, test environments as infrastructure and deployment are out of scope, as they are for the whole book. Tool picks (Testcontainers, ASP.NET Core's in-process test host, WireMock and similar) are dated choices that belong in ADRs.

More to come: what makes a good simulator, and how a test is designed at each level.

## Open questions

- **"Never function-test the controller".** Is it an absolute rule, or "never, and if you feel the need, the logic is in the wrong place"? The second reading says: when an orchestrator has enough branching that you *want* to test it alone, logic has leaked into the shell, and it should move into a pure function that returns actions ([Axiom 24](../chapter2/axiom-24-pure-functions-returning-actions.md)) instead of being mocked.
- **Sources to verify before citing:** Gary Bernhardt, *Boundaries* (SCNA 2012), unit-test the core and integration-test the shell (his *Functional Core, Imperative Shell* screencast is verified and cited in [Axiom 13](../chapter2/axiom-13-impureim.md)); Spotify's "testing honeycomb" (2018); Martin Fowler, *On the Diverse And Fantastical Shapes of Testing* (2021), on what "unit" means.

---

← Previous: [Chapter 2](../chapter2/README.md) · Next: [Chapter 4 — Plays](../chapter4/README.md) →
