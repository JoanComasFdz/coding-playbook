# Chapter 4 — Plays

[Chapter 2](../chapter2/README.md) built the **Fundamentals**: the anatomy of a module and its functions, as a sequence of axioms. [Chapter 3](../chapter3/README.md) said how to test code built that way. This chapter is one level up — the **Plays**: how those axioms compose into a *designed, persisted domain*.

Nothing here is a new principle. Every Play applies and combines Chapter 2 axioms; where a pattern is really an axiom wearing different clothes (a DDD value object *is* [Axiom 19](../chapter2/axiom-19-value-objects.md)), it links back rather than re-teaching. The chapter stays on the **tactical** (code-shaped) side of design — not bounded contexts, context maps, or system topology.

One stance holds the chapter together: **FP-style DDD**. Behaviour is pure functions and deciders over immutable data — invariants in smart constructors, decisions returning action DUs — not methods on mutable entities. The "rich domain model" / Tell-Don't-Ask orthodoxy is the road not taken, presented as a trade-off, never attacked. See [Axiom 2 — Data is not Behaviour](../chapter2/axiom-02-data-is-not-behavior.md).

## What's expected here

- **FP-style DDD tactical patterns.** Aggregates, entities, repositories, domain events — modelled the book's way. An aggregate is a **Decider**: a pure `decide` returning action/event DUs ([Axiom 24](../chapter2/axiom-24-pure-functions-returning-actions.md)), an `evolve` folding them back into state — an entity's lifecycle *is* a [state machine](../chapter2/axiom-25-state-machines.md), a domain event *is* a [discriminated union](../chapter2/axiom-22-discriminated-unions.md), a value object *is* [Axiom 19](../chapter2/axiom-19-value-objects.md). This is where the FP-style domain answers the *"isn't that just an anemic model?"* charge: it looks anemic only by the misreading that equates richness with mutable methods; by the real definition — the domain's logic lives *in* the domain, as pure functions — it is not.

- **Designing errors out of existence.** The design-level face of the fold already in [Axiom 7](../chapter2/axiom-07-honest-total-signatures.md) and [Axiom 17](../chapter2/axiom-17-result.md): how aggregate boundaries, value objects, and invariants-at-construction erase whole *classes* of error before any `Result` is reached for. The recurring instinct of the chapter — make the bad case unrepresentable, don't handle it.

- **Deep modules, small interfaces.** Ousterhout's "module value = functionality ÷ interface cost": designing a module that hides a lot behind a little — and the counterweight to tiny-function enthusiasm, where over-splitting multiplies *shallow* interfaces and adds complexity. Chapter 2's two evaluative lenses carry up here at module grain: a deep module is high [Cohesion](../chapter2/axiom-08-cohesion.md) behind a thin surface, and a small interface is less [Connascence](../chapter2/axiom-09-connascence.md) crossing the boundary. Its other face is **information hiding**, below — the secret is exactly what the small interface hides. Here "module" is Ousterhout's and Parnas's sense, a unit of any size with an interface and a secret (a class, a module, a whole [component](../chapter2/README.md#components)), not the static class of pure functions that [Axiom 2](../chapter2/axiom-02-data-is-not-behavior.md) calls a module.

- **Vertical slices.** Grouping code by feature instead of by technical layer, inside one deployable: [Cohesion](../chapter2/axiom-08-cohesion.md) and [Connascence](../chapter2/axiom-09-connascence.md) applied to the folder layout, with each slice one Impureim sandwich. Not service decomposition. See the [skeleton](02-vertical-slices.md).

- **Immutable-data persistence.** Reading and writing immutable records without an identity-tracking ORM fighting you: EF `AsNoTracking()` (and Dapper) for C#, jOOQ for Java. This is the concrete shell of the Impureim sandwich — the *gather* step materializes immutable records for the pure core, the *act* step maps action DUs back to commands. Mapping boundary↔domain↔persistence representations lives here. The *technique* is the Play; the specific tool pick (`AsNoTracking` by default, jOOQ) is a dated contextual choice that resolves to an ADR, linked from here rather than argued in prose.

- **Information hiding (Parnas).** "A module hides a design decision likely to change," at the in-scope, code-shaping end: the impure shell hiding the stateful secret ([Axiom 27](../chapter2/axiom-27-stateful-shell.md)), not architectural decomposition. The other face of **deep modules** above — same idea read from the secret's side rather than the interface's. See the [draft](03-information-hiding.md).

- **Anatomy of a component.** What one [component](../chapter2/README.md#components) looks like in code: its API (API-first, as [Chapter 3](../chapter3/README.md) requires of component tests), the shell's entry points and orchestrators as ordinary classes, the core's static modules, and the adapters to systems owned by others. A service adds a composition root and its own dependencies (database, message broker); a library has neither. The inside view of what a component test treats as a black box. How components relate to each other stays out of scope. See the [work in progress](04-anatomy-of-a-component.md).

- **When code becomes a library.** Code shared by several services is its own product, with its own reason to change, its own versioning and its own tests. Only pure business rules and real infrastructure qualify; orchestration never does ([Axiom 8](../chapter2/axiom-08-cohesion.md#what-dry-is-for)).

> This README is a skeleton — the scope and planned Plays, not yet the Plays themselves. Order still to be decided (likely: design the immutable domain first, then persist it).

---

← Previous: [Chapter 3 — Testing](../chapter3/README.md) · Next: [Chapter 5 — Next to Hexagonal Architecture and DDD](../chapter5/README.md) →
