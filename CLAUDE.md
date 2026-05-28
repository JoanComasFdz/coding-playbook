# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal **Coding Playbook** by the author — a curated set of building blocks, concise how-tos, and dated decisions for writing simple, honest, robust code in high-level general-purpose languages (C# and Java are the named targets).

It is **documentation, not software**. There is no build system, no test suite, and no runnable code at present. Content lives (or will live) as Markdown files. The `.gitignore` is a stock .NET template — its presence does not imply a .NET project; treat it as boilerplate until actual code appears.

## Scope: code-level, not architecture

This is a *Coding* Playbook, not an architecture book. It is about the **anatomy of a module and its functions** — what a signature promises, what a function receives and returns, how its internals compose. It is **not** about system topology.

Operational patterns (outbox, sagas, retries, circuit breakers, event-driven messaging, deployment) are **out of scope**: they are *consumers* of these building blocks, not building blocks themselves. If a draft drifts toward "how to architect a system," pull it back to "how to write the code inside the module."

A few edge concerns are explicitly **in** scope *because they shape code*: the composition root / wiring, mapping between boundary↔domain↔persistence representations, and where stateful resources (caches, connection pools, connections) live — the answer being the impure shell, never the core.

## The central model

Most content should align to one model:

> Pure functions over immutable types, returning values or **action DUs**; a single impure orchestrator is the only seam; stateful resources are held in the shell and fed in as values.

That sentence is effectively a module's public-API contract. Three consequences to keep consistent across examples:

- A pure function that decides *what should happen* returns a discriminated union of actions/events (e.g. `Add | Update | Remove`); the caller executes them outside the pure core — the decision is pure, the execution is impure. State machines are just the first part with the entity's state added as input and threaded into each successful variant. Treat "return actions" and "pure state machine" as the same building block, not two.
- Once functions return `Result`/`Option`, **compose** them with map/bind/traverse rather than nesting `if`s. Distinguish short-circuiting (monadic `Result`) from accumulating (applicative validation, for collecting multiple `ValidationError`s).
- **Always separate the pure call from the pattern match on its result** — see [Axiom 8's "match on a named value" convention](book/chapter1/axiom-08-pattern-matching.md#convention-match-on-a-named-value-never-on-an-inline-call). Shape: `var decision = Compute(...); switch (decision) { ... }`, never `switch (Compute(...)) { ... }`. Applies to `switch` and `Match` equally. The purpose is visual: pure call on one line, impure dispatch on the next, so a reviewer sees the Impureim sandwich's two halves at a glance.

## Vocabulary

Use these terms consistently — they are the playbook's building blocks: data vs behaviour, immutable records, `Option`/`Maybe`, `Result`/`Either`, discriminated unions, pattern matching, total/honest signatures, pure vs impure functions, first-class & higher-order functions, the **Impureim sandwich**, value objects with smart constructors, **parse don't validate**, **make illegal states unrepresentable**, the **Decider**, composition/combinators.

## Audience and voice

The intended reader is a working engineer in a high-level OO language. When drafting or editing:

- North star is **simplicity first** — "as simple as possible, as honest as possible, as robust as possible," in that order. Let it settle ties: prefer the simpler formulation, then the more honest, then the more robust only when it costs nothing above the first two.
- The playbook is opinionated and first-person. Match that register; don't neutralize it into generic best-practices prose.
- **Never attack a discipline, language, framework, or architecture.** Present alternatives as points on a trade-off curve, never as targets. Every strong opinion is "what I do today, and why," with an explicit "when not to."
- Favor examples in C# or Java unless told otherwise. Immutable-record persistence leans on EF `AsNoTracking()` (possibly Dapper) for C#, jOOQ for Java.

## How content is organized: three kinds of "why"

Keep the **how-to concise** and put justifications elsewhere, split by *kind*:

- **Principles** — the axioms (purity, immutability, simplicity-first). Non-negotiable for this playbook; one north-star document. Do **not** wrap them in ADRs — that implies they're up for per-use debate.
- **Conceptual why** — why a technique is good in general (why `Result` over exceptions, why value objects). Durable, pedagogical; lives *with* the concept, kept short.
- **Contextual choices** — dated, reversible tooling/tactical picks (`AsNoTracking` by default, jOOQ, short-circuit vs accumulate). These go in **ADRs**: central, dated, append-only; supersede, don't rewrite.

Prose density runs in three tiers: a **how-to** file is near-zero prose (mechanics + links), a **concept** file carries a tight why, an **ADR** carries the choice between alternatives. Link them: how-to → concept (durable why) → ADR (dated choice).

## Per-topic template

For consistency and fairness, draft each topic as: **Problem / forces → What I do today → Why → C#/Java example → Trade-offs & when NOT to → What might change tomorrow.** The last two sections are the playbook's non-dogmatism — don't skip them.

## When adding content

- Prefer extending or splitting existing Markdown files over new top-level files. Once a directory structure emerges, follow it; until then, **ask before introducing one** (ADRs conventionally collect in one place — confirm the location before creating it).
- Mind the two halves: the concept intro is the **Fundamentals**; the applied per-part chapters (triggers / core / output) are the **Plays**.