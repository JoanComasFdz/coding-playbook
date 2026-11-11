# Concept Registry

*Every coding concept I've considered — and where it landed, or why it didn't.*

Joan Comas, Senior Software Architect — since June 2024

**Status legend:** ✅ **Axiomatized** (became its own axiom) · 🔁 **Folded** (absorbed into an existing axiom) · ❌ **Discarded** (too niche / out of scope) · 🔍 **Open** (not yet decided)

**Recommendation tags** — on a concept still being weighed, the *suggested* disposition, not a decision: **[AXIOM?]** possible standalone axiom · **[FOLD]** fold into an existing axiom as a named hook / "why" · **[CONTRAST]** trade-off / non-dogmatism material · **[SKIP]** too niche, or already covered under another name.

---

## SOLID critique

Lives in [Chapter 1](chapter1/README.md) — the motivating hook: SOLID names the symptom after a design has gone wrong, but doesn't generate one. North's framing carries it: **principles are compliance gates (binary: conform or don't); properties are gradients you move along** — the cleanest "why look past SOLID," aligned with simplicity-first and the three-tier why model.

Several SOLID letters already land elsewhere, usually sharper at code level —
- **S**RP ≈ [Cohesion](chapter2/axiom-08-cohesion.md) ("one reason to change", but at function grain).
- **D**IP ≈ Impureim + the composition root.
- **I**SP ≈ honest / small surface area.
- **O**/**L** are mostly about inheritance hierarchies, which this book's FP-leaning register sidesteps.

---

## CUPID

🔍 **Open** — mapped property-by-property in [Chapter 1](chapter1/README.md); the only thing still open is whether the three above-altitude parts (Observable, minimal dependencies in the packaging sense, domain-based boundaries) ever earn a home — a hypothetical later chapter.

Dan North's reaction to SOLID: five **properties** (gradients you *move toward*), not rules. The short of it — **CUPID names the destination, the axioms are the route** — with the full per-property map into the axioms and Plays carried in [Chapter 1](chapter1/README.md), not repeated here.

Source: Dan North, "CUPID — for joyful coding" (2022), dannorth.net; cupid.dev property pages.

---

## Search oracle

The goal behind the axioms: a codebase whose compiler is a sound, fast, informative oracle, so mistakes are rejected at compile time with a precise message, for a human or an LLM.

- [Chapter 1](chapter1/README.md#the-goal-a-codebase-that-is-a-search-oracle) — the home: oracles, search oracles, the feedback ladder from performance test to compiler, and the question every axiom is chosen with.
- [Axiom 9 — Connascence](chapter2/axiom-09-connascence.md) — the line it rests on: enforced by the compiler versus carried by convention.

**Source:** Aditya Kumar, *A Type System Is a Search Oracle* (2026); Barr et al., *The Oracle Problem in Software Testing: A Survey* (IEEE TSE, 2015).

---

## Ubiquitous Language — [✅ AXIOMATIZED]

- [Axiom 0 — Ubiquitous Language](chapter2/axiom-00-ubiquitous-language.md) — one term, one thing, everywhere; the naming discipline the rest of the axioms give teeth to.

---

## Immutability — [✅ AXIOMATIZED]

- [Axiom 3 — Immutability](chapter2/axiom-03-immutability.md)

---

## Maybe — [✅ AXIOMATIZED]

- [Axiom 14 — Maybe](chapter2/axiom-14-maybe.md)

---

## Either — [✅ AXIOMATIZED]

- [Axiom 15 — Either](chapter2/axiom-15-either.md)

---

## Result pattern — [✅ AXIOMATIZED]

- [Axiom 17 — Result](chapter2/axiom-17-result.md)

---

## Discriminated unions — [✅ AXIOMATIZED]

- [Axiom 22 — Discriminated unions](chapter2/axiom-22-discriminated-unions.md)

---

## Pattern matching — [✅ AXIOMATIZED]

- [Axiom 12 — Pattern matching](chapter2/axiom-12-pattern-matching.md)

---

## Side effects — [✅ AXIOMATIZED]

- [Axiom 4 — Side effects](chapter2/axiom-04-side-effects.md)

---

## Impure functions — [✅ AXIOMATIZED]

- [Axiom 5 — Impure functions](chapter2/axiom-05-impure-functions.md)

---

## Pure functions — [✅ AXIOMATIZED]

- [Axiom 6 — Pure functions](chapter2/axiom-06-pure-functions.md)

---

## First-class functions — [✅ AXIOMATIZED]

- [Axiom 10 — First-class functions](chapter2/axiom-10-first-class-functions.md)

---

## Higher-order functions — [✅ AXIOMATIZED]

- [Axiom 11 — Higher-order functions](chapter2/axiom-11-higher-order-functions.md)

---

## Impureim: the impure–pure–impure sandwich — [✅ AXIOMATIZED]

- [Axiom 13 — Impureim](chapter2/axiom-13-impureim.md)

---

## Functional core, imperative shell — [🔁 FOLDED]

Gary Bernhardt's name for the same split. This book says *impure* shell: the split is about effects, not style, and a shell may be written imperatively or functionally.

- [Axiom 13 — Impureim](chapter2/axiom-13-impureim.md) — the home, with *A note on the name*: imperative is a style, impure is a property.

**Source:** Gary Bernhardt, *Functional Core, Imperative Shell* (Destroy All Software, 2012); Mark Seemann, *Functional architecture is Ports and Adapters* (2016).

---

## Value Objects — [✅ AXIOMATIZED]

- [Axiom 19 — Value objects](chapter2/axiom-19-value-objects.md)

---

## Entity identity & typed IDs — [🔁 FOLDED]

The complement of the value object's equality-by-value: a type identified by a key field, and the typed ID that carries it.

- [Axiom 19 — Value objects](chapter2/axiom-19-value-objects.md#identity-and-typed-ids) — the home: the typed ID as the smallest value object, equality-by-key as the mirror of equality-by-value, and why identity must live in a field once immutable values dissolve [Connascence of Identity](chapter2/axiom-09-connascence.md#connascence-of-identity-coi). The full DDD *Entity* pattern — identity lifecycle, reconstitution — composes this in the Chapter 4 Plays.

---

## State Machines — [✅ AXIOMATIZED]

- [Axiom 25 — State machines](chapter2/axiom-25-state-machines.md)

---

## Pure functions return actions — [✅ AXIOMATIZED]

- [Axiom 24 — Pure functions returning actions](chapter2/axiom-24-pure-functions-returning-actions.md)

---

## Session Context — [✅ AXIOMATIZED]

- [Axiom 26 — Session Context](chapter2/axiom-26-session-context.md)

---

## Stateful Shell — [✅ AXIOMATIZED]

- [Axiom 27 — Stateful Shell](chapter2/axiom-27-stateful-shell.md)

---

## Encode ordering in types (temporal coupling, sequential coupling) — [✅ AXIOMATIZED]

Order-dependence between calls — *authenticate before fetch*, *open before read*. **Temporal coupling** (Hunt & Thomas) and **sequential coupling** name one smell twice; both are [Connascence of Execution](chapter2/axiom-09-connascence.md#connascence-of-execution-coe), **not** Connascence of *Timing* (the concurrency/race form, out of scope).

- [Axiom 28 — Typestate](chapter2/axiom-28-typestate.md) — ordering encoded in the type, so an out-of-sequence call won't compile; names "temporal coupling" outright (Hunt & Thomas, *Breaking Temporal Coupling*, ref [2] there).
- [Axiom 9 — Connascence](chapter2/axiom-09-connascence.md#connascence-of-execution-coe) — the lens: Connascence of Execution, a dynamic form, which typestate weakens to a static Connascence of Type.

---

## Connascence — [✅ AXIOMATIZED]

A coupling taxonomy; the chapter's second evaluative lens, set beside [Cohesion](chapter2/axiom-08-cohesion.md).

- [Axiom 9 — Connascence](chapter2/axiom-09-connascence.md) — keeps Page-Jones's static/dynamic split, but the cut the playbook optimises against is *compiler-enforced vs. convention-carried*; the loose order of Meaning, Position and Algorithm is flagged as approximate, not asserted.

---

## Closures — [🔁 FOLDED]

- [Axiom 10 — First-class functions](chapter2/axiom-10-first-class-functions.md) — Why #3: "Closures carry data along with the function."

---

## Code reusability — [🔁 FOLDED]

- [Axiom 8 — Cohesion](chapter2/axiom-08-cohesion.md) — code is shared only when it is genuinely one concept with one reason to change (e.g. money formatting), never on surface similarity; the rule of three holds the line.

---

## Code locality — [🔁 FOLDED]

- [Axiom 8 — Cohesion](chapter2/axiom-08-cohesion.md) — the *When NOT to* locality bullet: cohesion read at reading-distance — keep statements that read as one thought together rather than shredding them into one-line helpers.

---

## No flag arguments — [🔁 FOLDED]

- [Axiom 8 — Cohesion](chapter2/axiom-08-cohesion.md) — a `bool`/enum that switches a function's body is the tell for two reasons to change living in one place.

---

## Define errors out of existence (Ousterhout) — [🔁 FOLDED]

Redesign so the error case cannot arise, instead of reporting it (`substring` clamps to the available range; deletion is idempotent). Simplicity-first's *first* move on the error ladder — before Result/Option, not beside them.

- [Axiom 7 — Honest, total signatures](chapter2/axiom-07-honest-total-signatures.md) — the mechanics: a third route to totality is to *broaden the operation* until every input has a defined answer (clamp / idempotent / default), the imperative-world name for making a function total. Its *When NOT to* carries the counterweight — absorbing an input that can only signal a caller bug *masks* the defect, so fail fast instead of clamping.
- [Axiom 17 — Result](chapter2/axiom-17-result.md) — the ordering: the explicit ladder *eliminate, then return, then fail fast* positions Result as rung 2, not rung 1, completing the north star (*simple → honest → robust*) for error handling.
- Structural eliminators — the same move at larger grain, each making the bad case unconstructable rather than handled: a value ([Axiom 19](chapter2/axiom-19-value-objects.md)), a record's shape ([Axiom 23](chapter2/axiom-23-illegal-states.md)), a call sequence ([Axiom 28](chapter2/axiom-28-typestate.md)).
- Honest-return rung — [Axiom 14](chapter2/axiom-14-maybe.md) / [Axiom 15](chapter2/axiom-15-either.md): when the case is a real outcome that cannot be erased, it becomes a value.
- **Surfaces in Chapter 4** as the Play *"Designing errors out of existence"* — the same move at design grain (aggregate boundaries, value-object invariants-at-construction); see the [Chapter 4 README](chapter4/README.md). Its home stays the folded axioms above; the Play composes them, adding no new principle.

**Not carried:** Ousterhout's other ch. 10 techniques — *exception masking* and *exception aggregation* are handler-placement / topology concerns (out of scope); *just crash* is already the fail-fast rung folded into [Axiom 17](chapter2/axiom-17-result.md).

**Source:** John Ousterhout, *A Philosophy of Software Design* (2018), ch. 10.

---

## Boolean blindness (Licata / Harper; De Goes) — [🔁 FOLDED]

A raw `bool` (or untyped flag) throws away the meaning of *what* is true — at the call site, `true` of what?

- [Axiom 7 — Honest, total signatures](chapter2/axiom-07-honest-total-signatures.md) — named here: an honest signature replaces the blind boolean with a type that names the outcome.
- [Axiom 8 — Cohesion](chapter2/axiom-08-cohesion.md) — named: a `bool` that switches a body is the boolean-blind call site *and* the two-reasons-to-change tell.
- [Axiom 22 — Discriminated unions](chapter2/axiom-22-discriminated-unions.md) — named: a DU names each case instead of encoding it as a boolean.

---

## Algebraic Data Types — the umbrella + state-counting — [🔁 FOLDED]

Sum types (one-of) and product types (all-of); a type's reachable states = the cases summed, the fields multiplied. Counting them is the tool for making illegal states unrepresentable.

- [Axiom 23 — Make illegal states unrepresentable](chapter2/axiom-23-illegal-states.md) — the home: state-counting drives the modelling.
- [Axiom 3 — Immutability](chapter2/axiom-03-immutability.md) — named: records are product types.
- [Axiom 22 — Discriminated unions](chapter2/axiom-22-discriminated-unions.md) — named: DUs are sum types.

---

## Design by Contract (Meyer) — [🔁 FOLDED]

Operations carry preconditions, postconditions, and invariants as part of their contract.

- [Axiom 19 — Value objects](chapter2/axiom-19-value-objects.md) — the home: a smart constructor enforces the type's invariant once, at construction.
- [Axiom 19 — Value objects](chapter2/axiom-19-value-objects.md) — postconditions: Axiom 19 reads the honest return type of [Axiom 7](chapter2/axiom-07-honest-total-signatures.md) as the postcondition, checkable by the compiler.
- [Axiom 28 — Typestate](chapter2/axiom-28-typestate.md) — preconditions-as-sequence: a parameter of the state's type carries the precondition, checked at compile time.

---

## Fail-fast on bugs vs. return-values for expected failures — [🔁 FOLDED]

Crash immediately on a programmer error (a bug); return a value for an *expected* failure.

- [Axiom 17 — Result](chapter2/axiom-17-result.md) — *The ladder*'s rungs 2 and 3 and the *When NOT to* bullet "When the failure is a bug" draw the line; it carries the *fail-fast* name (Shore, ref [4] there).

**Not carried:** the dev-time `assert` / `Debug.Assert` mechanism for catching contract violations at their source — left out because in practice I've never reached for it. Revisit only if it earns its keep.

**Source:** James Shore, *Fail Fast* (IEEE Software, 2004); offensive programming (lore).

---

## Arrow Anti-Pattern / Pyramid of Doom — [🔁 FOLDED]

Deeply nested `if`/`try` blocks marching rightward — each success opens another indent. The *nested* twin of [Return early](#return-early-guard-clauses---folded); once every step returns `Result`, both give way to composition.

- [Axiom 20 — Railway](chapter2/axiom-20-railway.md) — the staircase of nested success-checks becomes one straight track.
- [Axiom 18 — Result combinators](chapter2/axiom-18-result-combinators.md) — the nested unwrap → check → rewrap collapses into `map`/`bind`.
- [Axiom 12 — Pattern matching](chapter2/axiom-12-pattern-matching.md) — match one named value instead of stacking conditionals.

**Source:** Jeff Atwood, *Flattening Arrow Code* ("The Arrow Anti-Pattern"), Coding Horror (2006).

---

## Return early (guard clauses) — [🔁 FOLDED]

Handle the exceptional case first and bail, leaving the happy path un-indented. The *flattened* twin of [Arrow / Pyramid of Doom](#arrow-anti-pattern--pyramid-of-doom---folded).

- [Axiom 18 — Result combinators](chapter2/axiom-18-result-combinators.md) — the **named foil**: checking by hand and returning early on a failure is the right shape for a single step whose failure needs special handling, and noise once several run back-to-back, which is exactly when the combinators name the dance once.

**Source:** Martin Fowler, *Refactoring* (1999) — "Replace Nested Conditional with Guard Clauses."

---

## Swallowing Errors — [🔁 FOLDED]

Discarding a failure instead of handling it — an empty `catch {}`, an ignored `Result`, `?.`/`??` flattening several "missing" cases into one. The **inverse** of [*Define errors out of existence*](#define-errors-out-of-existence-ousterhout---folded): that move makes the bad case *impossible*; swallowing makes a real one *invisible*.

- [Axiom 7 — Honest, total signatures](chapter2/axiom-07-honest-total-signatures.md) — swallowing yields a *dishonest* signature claiming a success it never had; its *When NOT to* already warns that absorbing a caller-bug input masks the defect.
- [Axiom 14 — Maybe](chapter2/axiom-14-maybe.md) — the named `user?.Manager?.Email ?? ""` case (*Trade-offs*): three different "missing" cases quietly collapsed into one.

---

## Explicit over implicit — [✅ AXIOMATIZED]

What code needs and does is visible where it is used: inputs, dependencies, effects, failures. A founding discipline, like Ubiquitous Language: most later axioms make one more thing explicit.

- [Axiom 1 — Explicit over implicit](chapter2/axiom-01-explicit-over-implicit.md) — the home: the five things commonly left implicit, and encapsulation split into its three jobs.
- [Axiom 7 — Honest, total signatures](chapter2/axiom-07-honest-total-signatures.md) — explicitness applied to outcomes: no out-of-band nulls or exceptions.
- [Axiom 4 — Side effects](chapter2/axiom-04-side-effects.md) — effects are declared and pushed to the shell, never smuggled into a pure-looking call.
- [Axiom 9 — Connascence](chapter2/axiom-09-connascence.md) — the measure: an explicit dependency is one the compiler can see.
- Composition root — dependencies arrive as explicit values/parameters, not reached for through static singletons or ambient context.

**Source:** Tim Peters, *The Zen of Python* (PEP 20) — "Explicit is better than implicit"; the Explicit Dependencies Principle (Microsoft architecture guidance); Carson Gross, *Locality of Behaviour* (2020); Ousterhout, *A Philosophy of Software Design* (2018) — complexity from dependencies and obscurity.

---

## Classes as modules, static pure functions — [🔁 FOLDED]

In the pure core a class is a named group of `static` functions, like a module in a functional language. In the shell, classes stay ordinary classes.

- [Axiom 6 — Pure functions](chapter2/axiom-06-pure-functions.md#definitions) — the rule: pure functions are `static`, or methods on immutable values; never instance methods on a class with mutable fields or injected services.
- [Axiom 2 — Data is not Behavior](chapter2/axiom-02-data-is-not-behavior.md) — a static class is a module: no state, no identity.
- [Axiom 13 — Impureim](chapter2/axiom-13-impureim.md#definitions) — the shell is ordinary object-oriented code: constructor injection, state where needed.
- [Chapter 2 — What the code looks like](chapter2/README.md#what-the-code-looks-like) — the two halves side by side.

---

## Encapsulation — [🔁 FOLDED]

Often taught as "make everything private". Read precisely, it bundles three jobs, and this book keeps two of them.

- [Axiom 1 — Explicit over implicit](chapter2/axiom-01-explicit-over-implicit.md#encapsulation-read-precisely) — the home: the three jobs and their verdicts.
- [Axiom 19 — Value objects](chapter2/axiom-19-value-objects.md) — invariants, kept: protected where the value is built, not by hiding fields.
- [Axiom 27 — Stateful Shell](chapter2/axiom-27-stateful-shell.md) — secrets, kept: the shell holds the socket; decisions stay visible.
- [Axiom 2 — Data is not Behavior](chapter2/axiom-02-data-is-not-behavior.md) — state hidden behind behavior, dropped: an immutable value has nothing to hide.
- [*Information hiding*](chapter4/03-information-hiding.md), the Chapter 4 Play — secrets at module grain.

**Source:** Mark Seemann, *Poka-yoke Design* (2011) and *Code That Fits in Your Head* (2021); D.L. Parnas (1972).

---

## Conciseness — [🔁 FOLDED]

Saying more with fewer lines (terseness, succinctness). A side effect of removing ceremony, never a goal: several axioms make code longer on purpose.

- [Chapter 1 — Enforce decisions, not ceremony](chapter1/README.md#enforce-decisions-not-ceremony) — the test that tells concise from cryptic: remove the structure and ask what the reader lost.
- [Axiom 12 — Pattern matching](chapter2/axiom-12-pattern-matching.md) — the clearest example (*Why*, point 2), and the overreach, *Concise can turn cryptic* (*Trade-offs*).
- [Axiom 7 — Honest, total signatures](chapter2/axiom-07-honest-total-signatures.md), [Axiom 19 — Value objects](chapter2/axiom-19-value-objects.md) — longer on purpose: honesty outranks length.

---

## DRY — the real (knowledge) definition — [🔁 FOLDED]

Don't Repeat Yourself governs *knowledge*, not code text: one authoritative home per piece of knowledge.

- [Axiom 8 — Cohesion](chapter2/axiom-08-cohesion.md) — reason-to-change *is* DRY made operational; it names Hunt & Thomas's original knowledge definition (ref [5] there) and corrects the dedupe-on-sight misreading.
- [Axiom 8 — What DRY is for](chapter2/axiom-08-cohesion.md#what-dry-is-for) — share pure business rules (validation, transformations, decisions); let impure orchestration repeat.
- [Chapter 3 — Testing](chapter3/README.md#what-i-do-today) — the same split applied to sharing, abstraction and testing.

**Source:** Andrew Hunt & David Thomas, *The Pragmatic Programmer* (1999).

---

## Speculative generality — YAGNI / premature optimization / premature generalization — [🔁 FOLDED]

Building for a future that hasn't arrived — a feature (**YAGNI**), a faster path (**premature optimization**), or an abstraction (**premature generalization**). One restraint seen from three angles; all three are facets of **simplicity-first**, the north star, not code-shape axioms of their own.

- **Simplicity-first north star** — YAGNI and premature optimization stay at *principle* grain (the non-negotiable "as simple as possible" tier), carried as restraint rather than folded into a single axiom. Knuth's "premature optimization is the root of all evil" and XP's "You Aren't Gonna Need It" name the same discipline.
- [Axiom 8 — Cohesion](chapter2/axiom-08-cohesion.md) — premature generalization is the concrete fold: the *rule of three* holds the line, and Sandi Metz's *The Wrong Abstraction* (ref [1] there) is why a too-early abstraction costs more than the duplication it removes.
- [Chapter 1](chapter1/README.md) — already names "speculative generality" as the bad, speculative reading of OCP applied ahead of a seen axis of change.

**Source:** Donald Knuth, *Structured Programming with go to Statements* (1974); Kent Beck / Ron Jeffries, Extreme Programming (YAGNI); Fowler & Beck, *Refactoring* (1999) — the "Speculative Generality" smell.

---

## SLAP — single level of abstraction per function — [🔁 FOLDED]

Single Level of Abstraction Per function. Both useful halves already live elsewhere; the only standalone residue rests on an undefined "level of abstraction" the playbook declines.

- [Axiom 8 — Cohesion](chapter2/axiom-08-cohesion.md) — the "each function does one job" half *is* cohesion; its *When NOT to* carries the reading-smell kernel: a body that forces mental inlining wants a *named* extraction — extract when the detail is a concept with its own reason to change, not to hit an altitude quota.
- [Axiom 13 — Impureim](chapter2/axiom-13-impureim.md) — the "read the body as a paragraph of same-level steps" half is a byproduct of the gather→decide→act step-down, not a separate law.

**Why no axiom of its own** — the residue ("match every statement to one altitude") rests on a "level of abstraction" that nothing — not even SLAP's own references — defines; applied mechanically it yields *extract-till-you-drop*, the mental-inlining smell [Axiom 8](chapter2/axiom-08-cohesion.md) already guards (and the deep-vs-shallow-modules tension noted below).

**Source:** Kent Beck, *Composed Method* (*Smalltalk Best Practice Patterns*, 1997); acronym credited to Glenn Vanderburg, popularized by Neal Ford, *The Productive Programmer* (2008); restated as the *Stepdown Rule* by Robert C. Martin, *Clean Code* (2009); over-application critiqued by John Ousterhout, *A Philosophy of Software Design* (2018), and the Christin Gorman vs. Robert C. Martin "extract till you drop" debate.

---

## Lenses / optics — [❌ DISCARDED]

**What:** the nested-immutable-update tax; composable getter+setter bundles (lens=field, prism=case, traversal=many).

**Verdict:** not carried: a niche problem. Deeply nested data is usually a smell in itself, and the everyday case is covered.

- [Axiom 3 — Immutability](chapter2/axiom-03-immutability.md#trade-offs) — the pain and the built-in answer: C#'s `with`, Java's `withName(...)` methods (*Trade-offs*, "Ergonomics on update").
- Optics themselves may fit a future chapter for niche techniques.

**Revisit if** JEP 468 (derived record creation, a `with` for Java records) ships. It is a Candidate, not in any JDK release yet.

**Source:** Kmett `lens`; Scott Logic "The Immutability Gap" series; Joan Comas, [*dotnet-optics*](https://github.com/JoanComasFdz/dotnet-optics), my own experiments with optics in C#.

---

## Postel's Law vs. parse-don't-validate — [🔁 FOLDED]

The Robustness Principle — *"be conservative in what you do, be liberal in what you accept."* Only *looks* opposed to parse-don't-validate: Postel governs surface *form*, parse-don't-validate governs *meaning* crossing the boundary.

- [Axiom 19 — Value objects](chapter2/axiom-19-value-objects.md) — the "Postel's law, reconciled" aside in the *Why*: Postel is about the input's *form*, the factory about its *meaning*, so a `Parse` may accept several forms but must produce exactly one canonical value or a `Failure`, the leniency confined to that step. The smart constructor is the *cure* for Postel's harmful form, not its rival.

**Note:** the IETF has since recanted the principle (RFC 9413) — liberal acceptance *without* normalisation is exactly the spec-drift a boundary parse prevents.

**Source:** RFC 760 / RFC 793 (Postel); RFC 9413 (Thomson & Schinazi, 2023); Alexis King, *Parse, Don't Validate* (2019).

---

## Command–Query Separation (CQS) — [🔁 FOLDED]

A method returns a value (query) *xor* changes state (command), never both — the OO ancestor of the pure/impure split. Purity is strictly stronger: a CQS "query" may still read mutable globals.

- [Axiom 13 — Impureim](chapter2/axiom-13-impureim.md) — the primary home: Impureim *is* CQS promoted from the method to the unit of work (gather = query, act = command), the seam a layer boundary rather than a naming convention. Meyer is ref [4].
- [Axiom 6 — Pure functions](chapter2/axiom-06-pure-functions.md) — the query half: purity outruns it, forbidding even the *read* of mutable state a CQS query still permits.
- [Axiom 24 — Pure functions returning actions](chapter2/axiom-24-pure-functions-returning-actions.md) — the command half: the would-be command splits into a pure `DecideAdd` (returns a value) and an impure execute (returns nothing).

**Boundary:** CQRS is system topology and stays out of the axioms; only the registry records the CQS (code) vs. CQRS (architecture) line — see [CQRS](#cqrs-architecture---out-of-scope).

**Source:** Bertrand Meyer, *Object-Oriented Software Construction* (2nd ed., 1997).

---

## Tell, Don't Ask — [🔁 FOLDED]

The OO maxim: don't pull an object's data out to decide for it — push the decision into the object that owns the (mutable) state. A contrast piece, not a missing foundation: the playbook makes the *opposite* bet in its pure core and the *same* bet in its impure shell.

**Where it lives, and how:**

- [**Axiom 2 — Data is not Behavior**](chapter2/axiom-02-data-is-not-behavior.md) — the road not taken. Tell-Don't-Ask moves the decision *to* the data; the playbook moves the data *to* the decision. Same goal (one home for the rule, no reaching into internals), opposite mechanism (freeze the data vs. hide it behind behaviour).
- [**Axiom 24 — Pure functions returning actions**](chapter2/axiom-24-pure-functions-returning-actions.md) — the inversion. Tell-Don't-Ask *fuses* deciding and acting; this axiom *splits* them: pure `Decide` returns an action value, impure shell executes it.
- [**Axiom 2's *When NOT to***](chapter2/axiom-02-data-is-not-behavior.md#when-not-to) — where it belongs: mutable resources (a connection, a cache, a stream) are *told* what to do, not asked for their insides. In this book they live in the shell ([Axiom 27](chapter2/axiom-27-stateful-shell.md)). Right rule on the stateful side of the seam, wrong on the pure side.

**Why no axiom of its own** — the goods it offers already have homes: encapsulation → [Axiom 19](chapter2/axiom-19-value-objects.md); rule-in-one-place → [Axiom 8](chapter2/axiom-08-cohesion.md) + [Axiom 24](chapter2/axiom-24-pure-functions-returning-actions.md); read-write-race safety → [Axiom 3](chapter2/axiom-03-immutability.md) + [Axiom 28](chapter2/axiom-28-typestate.md).

**Source:** Andrew Hunt & David Thomas, *The Pragmatic Programmer* (1999) — cited at [Axiom 2](chapter2/axiom-02-data-is-not-behavior.md) ref [7]; Martin Fowler, *TellDontAsk* (bliki).

---

## Law of Demeter — [SKIP — narrow]

"One dot" — don't navigate object graphs. Its dangerous half is designed away and the rest is trivial: the law restricts *message sends* (behaviour), not field-walks over transparent data, so a value-core gives it almost nothing to bite on — and what remains is weak, compiler-enforced coupling, not a hazard.

- [Axiom 2 — Data is not Behavior](chapter2/axiom-02-data-is-not-behavior.md) — the behavioural half: LoD governs which *methods* a unit may call; inert immutable data has no behaviour to reach through, so walking `person.Address.Street` is not what the law targets.
- [Axiom 3 — Immutability](chapter2/axiom-03-immutability.md) — the action-at-a-distance half: immutable *all the way down* (the `Person → Address → Street` setter quiz) means no deep node can mutate underneath a holder, so deep reads are safe to pass around.
- [Axiom 9 — Connascence](chapter2/axiom-09-connascence.md) — the residual: a field chain still binds the reader to the path, but in a typed value world that is Connascence of Name/Type — the weakest, compiler-enforced forms, where a rename or reshape breaks the build at every site. It is Axiom 9's *weak-and-local* case to leave alone, not a train-wreck to fear.
- [Axiom 8 — Cohesion](chapter2/axiom-08-cohesion.md) — the look-alike: reaching deep to *recompute* a rule at the call site is a decide-in-one-place concern, not LoD.

Sibling of [Tell, Don't Ask](#tell-dont-ask---folded): the two "don't reach through" maxims — TDA the *behavioural* reach (folded, as the opposite bet), LoD the *structural* reach (a corollary of the value-core, hence skipped).

**Source:** Karl Lieberherr & Ian Holland, *Assuring Good Style for Object-Oriented Programs* (IEEE Software, 1989) — the law stated as a restriction on which methods a unit may call; Demeter Project, Northeastern, from 1987. Andrew Hunt & David Thomas, *The Pragmatic Programmer* (1999) — treat it as a coupling heuristic for functions, not an absolute rule.

---

## Coupling & Cohesion (Constantine / Yourdon) — [SKIP — historical root]

The original "low coupling, high cohesion": a coupling ladder (content/common/external/control/stamp/data) and a cohesion ladder (coincidental→functional). Control coupling = flag args; common coupling = shared mutable state.

- [Axiom 9 — Connascence](chapter2/axiom-09-connascence.md) — the historical bedrock connascence builds on, subsumed by its finer grain; *Structured Design* is ref [5] there.

**Source:** Stevens, Myers & Constantine, "Structured Design" (IBM Systems Journal, 1974).

---

## Monoid / Semigroup — [SKIP — vocabulary only]

**What:** a type + an associative binary `combine` is a **semigroup**; give it an **identity** (empty/seed) element and it's a **monoid**. Both laws just name things you already use:

| type | `combine` | identity |
|---|---|---|
| `int` | `+` | `0` |
| `string` | concat | `""` |
| `List<T>` | append | `[]` |
| `bool` | `&&` | `true` |

- **Associativity** lets a fold reassociate — re-group, chunk, or parallelise the work.
- The **identity** is the seed of `Aggregate(seed, …)` and the honest answer for an empty input — a *seedless* `Aggregate` throws on empty, the partial version.

**Verdict:** declined as vocabulary. The substance is already taught, un-named, in two axioms, and naming it buys nothing in C#/Java (no `Monoid` typeclass to dispatch on); beyond one paragraph it's category-theory tourism.

- [Axiom 11 — Higher-order functions](chapter2/axiom-11-higher-order-functions.md) — `Aggregate`/`reduce` (Hughes' `foldr`) *is* the monoid fold.
- [Axiom 21 — Validation](chapter2/axiom-21-validation.md) — merging `ValidationError` lists *is* the list-concatenation monoid; that associativity is the un-named reason `Combine` is order-free and arity-scales.

---

## Catamorphism / fold — [SKIP — jargon]

**What:** the one total operation that *consumes* an algebraic data type — hand it one function per case and it collapses the value to a single result. "Catamorphism" is just the umbrella word for **fold, generalised from lists to any sum type**:

| type | the fold | handlers you supply |
|---|---|---|
| `List<T>` | `Aggregate`/`reduce` | a seed + `(acc, item) → acc` |
| `Maybe<T>` | `Match` | `onSome`, `onNone` |
| `Result<T,E>` | `Match` / `fold` | `onOk`, `onErr` |
| `Shape` (DU) | `Match` | one per variant |

- For a **recursive** type (list, tree) the fold is `Match` *plus the recursive call* threaded through each case — that recursion is what collapses the structure into one value.
- For a **flat** DU (`Add | Update | Remove`) there is nothing to recurse into, so the catamorphism just *is* exhaustive `Match`: one handler per variant.
- Its defining trait is **totality** — a handler for every case, nothing skipped — the exact property the compiler checks on an exhaustive match.

**Verdict:** declined as jargon, the same call as [Monoid / Semigroup](#monoid--semigroup--skip--vocabulary-only). The substance — the total consumer of a sum type — is already taught *and used* under the name `Match`, and the word buys nothing in C#/Java: there is no `Cata` construct to implement, `switch`/`.Match` is the whole API. Beyond a one-line aside it is category-theory tourism.

- [Axiom 12 — Pattern matching](chapter2/axiom-12-pattern-matching.md) — the home. The [`Match` method form](chapter2/axiom-12-pattern-matching.md#the-method-form) (`R Match<R>(Func<Circle,R>, …)`) *is* the catamorphism encoding — one handler per case, returning `R`, with exhaustiveness as its totality; ref [4] there is Wlaschin's series on catamorphisms and folds.
- [Axiom 7 — Honest, total signatures](chapter2/axiom-07-honest-total-signatures.md) — that totality is the same total-consumer property: every case answered, no partial branch.
- [Axiom 17 — Result](chapter2/axiom-17-result.md) — `Result.Match` is its two-case catamorphism. [Axiom 14 — Maybe](chapter2/axiom-14-maybe.md) and [Axiom 15 — Either](chapter2/axiom-15-either.md) consume their cases with a `switch`, the same total consumer at the call site.

The list `reduce` is itself a catamorphism (the List one), but it lives in [Monoid / Semigroup](#monoid--semigroup--skip--vocabulary-only) as the *monoid fold*; this entry is the general notion, whose everyday face on the book's flat DUs is `Match`.

---

## Persistent data structures / structural sharing — [🔁 FOLDED]

The "isn't immutability slow?" rebuttal: structural sharing rebuilds only the changed path, so immutable "copies" of large collections stay cheap.

- [Axiom 3 — Immutability](chapter2/axiom-03-immutability.md) — the ["But isn't all this copying slow?" sidebar](chapter2/axiom-03-immutability.md#but-isnt-all-this-copying-slow) in *Trade-offs*: a small record copies a few fields; a large collection uses a persistent collection (`System.Collections.Immutable`, Vavr) that shares unchanged nodes for O(log n) updates. Okasaki (ref [4] there) is the deep theory; the sidebar is the everyday answer.

---

## Referential transparency / determinism — [SKIP — already covered]

Same call always returns the same value, and is substitutable for that value.

- [Axiom 6 — Pure functions](chapter2/axiom-06-pure-functions.md) — already named here; the one thing worth surfacing is the testability payoff: RT code needs no mocks — you test it by substituting values.

---

## Idempotence — [SKIP — already covered]

Applying an action twice lands in the same state as applying it once.

- [Axiom 25 — State machines](chapter2/axiom-25-state-machines.md) — already here: a total `Transition` answers a repeated command (a double-clicked Cancel, a resent message) with `NoChange` instead of an error, so idempotency is built into the shape. Its retry-safety payoff is operational, hence out of scope.
- [Axiom 7 — Honest, total signatures](chapter2/axiom-07-honest-total-signatures.md) — a delete that succeeds when the row is already gone, one of the examples of defining an error out of existence.

---

## Zero-One-Infinity rule — [🔁 FOLDED]

Allow none, exactly one, or unbounded-many of a thing — never an arbitrary fixed cap. Its only code-level residue is the *inverse* of [Axiom 23](chapter2/axiom-23-illegal-states.md); "arbitrary" is a domain judgment the type cannot make, so it is no standalone coding axiom.

- [Axiom 23 — Make illegal states unrepresentable](chapter2/axiom-23-illegal-states.md) — the home: the state-count run backwards. A type representing *fewer* states than the domain allows (a list capped at three for convenience) makes a **legal** state unrepresentable — the mirror of this axiom; the fix is to loosen until representable meets legal.
- [Axiom 19 — Value objects](chapter2/axiom-19-value-objects.md) — where a cap *is* a real invariant: the value object's factory enforces it and returns a `Failure` past the limit, encoding the bound honestly — the cure for a justified limit, not a banned number.

**Deferred:** the other half — *deciding whether a given bound is real* — is not a chapter-1 tool but a modelling discipline; it belongs with later domain-design material (DDD tactical patterns), not the foundations. The registry sits outside the chapters precisely to carry that kind of forward pointer.

**Source:** van der Poel / MacLennan.

---

## Composition over inheritance — [SKIP — already the positive program]

Reuse by holding and passing collaborators as values rather than extending a base class. Not skipped for clashing with the register — skipped because the register already *is* it: the book composes behaviour as function values, and inheritance stays on the table as an honest trade-off in the axioms' *When NOT to*, never as a target.

The composition half — the default:

- [Axiom 10 — First-class functions](chapter2/axiom-10-first-class-functions.md) — behavior as a value is "the prerequisite for composition" (*Why*, point 4); the GoF Strategy/Command/Visitor patterns (ref [1] there) are what function values collapse, Norvig's "16 of 23 patterns vanish" the count (ref [2]).
- [Axiom 11 — Higher-order functions](chapter2/axiom-11-higher-order-functions.md) — where the day-to-day composition lives (`Compose`); names the rivals outright — Template Method and Strategy cost a type per variation where a function parameter costs one slot (ref [2]).

The over-inheritance half — the hierarchy designed away, kept honestly:

- [Axiom 2 — Data is not Behavior](chapter2/axiom-02-data-is-not-behavior.md) — the root: inert data plus free functions removes the base-class-for-reuse reflex at the source.
- [Axiom 22 — Discriminated unions](chapter2/axiom-22-discriminated-unions.md) — a closed subtype hierarchy consumed by polymorphic dispatch becomes a sealed DU + pattern match; the *When NOT to* keeps an interface with a method per implementation for a set open by design.
- [Axiom 12 — Pattern matching](chapter2/axiom-12-pattern-matching.md) — the same virtual-dispatch-vs-match trade-off, inheritance kept as the right tool for a set of cases open by design.

Echoes the [SOLID critique](#solid-critique)'s note that the **O**/**L** letters are about inheritance hierarchies this FP-leaning register sidesteps.

**Source:** Gang of Four, *Design Patterns* (1994) — cross-listed at [Axiom 10](chapter2/axiom-10-first-class-functions.md) ref [1] and [Axiom 11](chapter2/axiom-11-higher-order-functions.md) ref [2].

---

## DDD Tactical Patterns

🔍 **Open** — the chapter's headline area: a **Chapter 4 Play**, *DDD Tactical Patterns* ([draft](chapter4/01-DDD-tactical-patterns.md), its Repository section under review).

- Anemic models real definition, not "put methods in domain objects" — the rebuttal the FP-style domain owes, since pure-functions-over-immutable-data looks anemic only by the naive reading.
- Aggregate as a [Decider](chapter2/axiom-25-state-machines.md#definitions); domain event as a [discriminated union](chapter2/axiom-22-discriminated-unions.md); entity lifecycle as a [state machine](chapter2/axiom-25-state-machines.md); value object as [Axiom 19](chapter2/axiom-19-value-objects.md).

---

## Vertical Slice Architecture

🔍 **Open** — a planned **Chapter 4 Play**, *Vertical slices* ([skeleton](chapter4/02-vertical-slices.md), not yet drafted).

**What:** group code by feature instead of by technical layer, inside one deployable.

**Verdict:** a Play, not a principle: Cohesion and Connascence applied to the folder layout.

- [Axiom 8](chapter2/axiom-08-cohesion.md) — group by reason to change, pointed at a folder.
- [Axiom 9](chapter2/axiom-09-connascence.md) — high locality inside a slice, low degree between slices.
- [Axiom 13](chapter2/axiom-13-impureim.md) — each slice is one Impureim sandwich.
- [Chapter 1](chapter1/README.md#ocp-did-not-die-it-moved-up-the-stack) — where OCP's intent survives.

**Source:** Bogard, [*Vertical Slice Architecture*](https://www.jimmybogard.com/vertical-slice-architecture/).

---

## Deep vs. shallow modules (Ousterhout)

🔍 **Open** — splits across both altitudes; the positive half is a planned **Chapter 4 Play**, *"Deep modules, small interfaces"* (scoped in the [Chapter 4 README](chapter4/README.md), not yet drafted).

**What:** module value = functionality ÷ interface cost; **deep** = small interface over lots of implementation. The counterweight: over-splitting into many tiny functions multiplies *shallow* interfaces and can *increase* complexity.

**Verdict:** splits by altitude. The **counterweight** half — don't over-split functions into shallow one-line helpers — stays folded at function grain in [Axiom 8](chapter2/axiom-08-cohesion.md)'s *When NOT to* (shred-locality) and [Axiom 11](chapter2/axiom-11-higher-order-functions.md)'s *Trade-offs* (deep chains of wrappers). The **positive** half — functionality ÷ interface cost — is the Chapter 4 Play, paired there with [Information Hiding](#information-hiding-parnas) as its other face and read through [Cohesion](chapter2/axiom-08-cohesion.md) / [Connascence](chapter2/axiom-09-connascence.md) at module grain.

**Source:** Ousterhout, *A Philosophy of Software Design* (2018).

---

## Information Hiding (Parnas)

🔍 **Open** — its code-shaping end is a **Chapter 4 Play**, [*Information hiding*](chapter4/03-information-hiding.md) (drafted; the database is not treated as a secret), paired with [Deep vs. shallow modules](#deep-vs-shallow-modules-ousterhout).

A module hides a *secret* — a design decision likely to change. The root of encapsulation and of Ousterhout's deep modules; the same idea read from the secret's side rather than the interface's.

The *strategic* half — decomposition at architectural altitude — stays out of scope. In scope:

- [Axiom 1 — Explicit over implicit](chapter2/axiom-01-explicit-over-implicit.md#encapsulation-read-precisely) — secrets are the one thing worth hiding; intent never is.
- [Axiom 27 — Stateful Shell](chapter2/axiom-27-stateful-shell.md) — the shell holds the stateful secret.
- [*Information hiding*](chapter4/03-information-hiding.md) — the Play: name the secret, give it a small surface in domain words, keep the core explicit.

**Source:** D.L. Parnas, "On the Criteria To Be Used in Decomposing Systems into Modules" (CACM, 1972).

---

## Leaky abstraction — [🔁 FOLDED]

An abstraction whose underlying detail shows through — the caller must know what it claims to hide (Spolsky: "all non-trivial abstractions are, to some degree, leaky"). The *failure mode* of the two open Chapter 4 module Plays, with a function-grain echo.

- Chapter 4 *Deep modules, small interfaces* & *Information hiding* Plays — a leak is the secret escaping: a shallow module, or a small interface that doesn't truly cover its implementation. The named anti-pattern those Plays design against (scoped in the [Chapter 4 README](chapter4/README.md)).
- [Axiom 7 — Honest, total signatures](chapter2/axiom-07-honest-total-signatures.md) — at function grain a leaky signature is a *dishonest* one: it hides a failure or precondition the caller still has to know.

**Source:** Joel Spolsky, *The Law of Leaky Abstractions* (2002).

---

## CQRS [ARCHITECTURE - OUT OF SCOPE]

❌ **Discarded** — system topology, out of scope; this entry only records the boundary.

Note (from research): CQRS is system topology = **out of scope** (it's a *consumer* of the building blocks, not one). Its code-level sibling is **CQS** (see the Command–Query Separation entry above) — a method returns a value *xor* changes state — and that one is now folded into [Axiom 13 — Impureim](chapter2/axiom-13-impureim.md) (and named in [Axiom 6](chapter2/axiom-06-pure-functions.md) and [Axiom 24](chapter2/axiom-24-pure-functions-returning-actions.md)). Keep this section only to *record the boundary*, not to write an axiom.

---

## Boy Scout Rule — [SKIP — out of the code-shape lane]

"Always leave the code cleaner than you found it" — opportunistic, incremental cleanup as you pass through.

**Verdict:** skipped as out of scope, not as wrong. It is a *working habit over time*, not a property of code shape; the book's lane is *how to write the code*, and this is *how to work on it*. The improvements it prescribes are already governed by the axioms — the habit of applying them is not itself a code-shaping rule the playbook can carry.

**Source:** Robert C. Martin, *Clean Code* (2009) — "The Boy Scout Rule."

---

## Caches — [❌ DISCARDED]

Memoising results behind a stateful store. Too niche to be an axiom.

If ever revisited: explore the FP take plus the correctness of the decorator pattern, especially in OOP.
