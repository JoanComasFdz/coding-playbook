# Chapter 3 — Testing

[Chapter 2](../chapter2/README.md) split every module into a pure core and an impure shell. That split also decides how the code is tested. This chapter says how, before any Play: testing doesn't depend on whether the shell talks to a database, a feed or a queue. Every Play in [Chapter 4](../chapter4/README.md) is tested the way this chapter describes.

## Name tests by what they test

"Unit", "integration" and "end-to-end" name a test by how many components it runs, and teams rarely agree on what a unit is. I name a test by what it tests:

| Test | What it tests | What it runs against | Commonly called |
|---|---|---|---|
| **Function** | One pure function: values in, value out. | Nothing but the function. | Unit test |
| **Service** | One deployable service, through its own entry points. | Its own real dependencies (a real database in a container), and simulators for systems owned by others. | Integration or acceptance test |
| **Product** | The whole product, as its users see it. | Every service of the product, deployed together. | End-to-end test |
| **Solution** | Several products working together. | The products involved, deployed together. | System or end-to-end test |

Each level up is slower and more expensive to run, and finds a bug further from the line that caused it. Below all of them sits the compiler, the cheapest check of all ([Chapter 1](../chapter1/README.md#the-goal-a-codebase-that-is-a-search-oracle)).

## What I test where

- **The pure core: function tests.** Decisions over immutable values need no setup and no mocks. Test them thoroughly here.
- **The shell: service tests, not function tests.** A controller, a mapper and the database access hold no decisions of their own. Testing them alone means mocking what they call, which tests the wiring, not the behavior. A service test covers them by running the real thing.
- **Products and solutions: a few tests on the paths that matter most.** They are the most expensive to run and to keep working.

## In this chapter

- [Testing the core and the whole](01-testing-the-core-and-the-whole.md) — the position in short, and the open questions around it. *(Placeholder.)*

More to come: why no function test for a controller, a mapper or the database access; what makes a good simulator; how a test is designed at each level.

## Scope

This chapter is about tests as code: what to test, at which level, and how. CI pipelines, test environments as infrastructure and deployment are out of scope, as they are for the whole book. Tool picks (Testcontainers, WireMock and similar) are dated choices that belong in ADRs.

---

← Previous: [Chapter 2](../chapter2/README.md) · Next: [Chapter 4 — Plays](../chapter4/README.md) →
