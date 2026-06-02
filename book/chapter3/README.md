# Chapter 3 — Plays

Chapter 2 built the **Fundamentals**: the anatomy of a module and its functions, as a sequence of axioms. This chapter is one level up — the **Plays**: how those axioms compose into a *designed, persisted domain*.

Nothing here is a new principle. Every Play applies and combines Chapter 2 axioms; where a pattern is really an axiom wearing different clothes (a DDD value object *is* [Axiom 17](../chapter2/axiom-17-value-objects.md)), it links back rather than re-teaching. The chapter stays on the **tactical** (code-shaped) side of design — not bounded contexts, context maps, or system topology.

One stance holds the chapter together: **FP-style DDD**. Behaviour is pure functions and deciders over immutable data — invariants in smart constructors, decisions returning action DUs — not methods on mutable entities. The "rich domain model" / Tell-Don't-Ask orthodoxy is the road not taken, presented as a trade-off, never attacked. See [Axiom 0 — Data is not Behaviour](../chapter2/axiom-00-data-vs-behaviour.md).

## What's expected here

- **FP-style DDD tactical patterns.** Aggregates, entities, repositories, domain events — modelled the book's way. An aggregate is a **Decider**: a pure `decide` returning action/event DUs ([Axiom 22](../chapter2/axiom-22-pure-functions-returning-actions.md)), an `evolve` folding them back into state — an entity's lifecycle *is* a [state machine](../chapter2/axiom-23-state-machines.md), a domain event *is* a [discriminated union](../chapter2/axiom-20-discriminated-unions.md), a value object *is* [Axiom 17](../chapter2/axiom-17-value-objects.md). This is where the FP-style domain answers the *"isn't that just an anemic model?"* charge: it looks anemic only by the misreading that equates richness with mutable methods; by the real definition — the domain's logic lives *in* the domain, as pure functions — it is not.

- **Designing errors out of existence.** The design-level face of the fold already in [Axiom 5](../chapter2/axiom-05-honest-total-signatures.md) and [Axiom 15](../chapter2/axiom-15-result.md): how aggregate boundaries, value objects, and invariants-at-construction erase whole *classes* of error before any `Result` is reached for. The recurring instinct of the chapter — make the bad case unrepresentable, don't handle it.

- **Deep modules, small interfaces.** Ousterhout's "module value = functionality ÷ interface cost": designing a module that hides a lot behind a little — and the counterweight to tiny-function enthusiasm, where over-splitting multiplies *shallow* interfaces and adds complexity. Chapter 2's two evaluative lenses carry up here at module grain: a deep module is high [Cohesion](../chapter2/axiom-06-cohesion.md) behind a thin surface, and a small interface is less [Connascence](../chapter2/axiom-07-connascence.md) crossing the boundary. Its other face is **information hiding**, below — the secret is exactly what the small interface hides.

- **Immutable-data persistence.** Reading and writing immutable records without an identity-tracking ORM fighting you: EF `AsNoTracking()` (and Dapper) for C#, jOOQ for Java. This is the concrete shell of the Impureheim sandwich — the *gather* step materializes immutable records for the pure core, the *act* step maps action DUs back to commands. Mapping boundary↔domain↔persistence representations lives here. The *technique* is the Play; the specific tool pick (`AsNoTracking` by default, jOOQ) is a dated contextual choice that resolves to an ADR, linked from here rather than argued in prose.

- **Information hiding (Parnas).** "A module hides a design decision likely to change," at the in-scope, code-shaping end: the impure shell hiding the stateful secret ([Axiom 25](../chapter2/axiom-25-stateful-shell.md)), not architectural decomposition. The other face of **deep modules** above — same idea read from the secret's side rather than the interface's.

> This README is a skeleton — the scope and planned Plays, not yet the Plays themselves. Order still to be decided (likely: design the immutable domain first, then persist it).
