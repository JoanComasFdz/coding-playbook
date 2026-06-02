# Concept Registry

*Every coding concept I've considered — and where it landed, or why it didn't.*

Joan Comas, Senior Software Architect — since June 2024

**Status legend:** ✅ **Axiomatized** (became its own axiom) · 🔁 **Folded** (absorbed into an existing axiom) · ❌ **Discarded** (too niche / out of scope) · 🔍 **Open** (not yet decided)

**Recommendation tags** — on a concept still being weighed, the *suggested* disposition, not a decision: **[AXIOM?]** possible standalone axiom · **[FOLD]** fold into an existing axiom as a named hook / "why" · **[CONTRAST]** trade-off / non-dogmatism material · **[SKIP]** too niche, or already covered under another name.

---

## Immutability — [✅ AXIOMATIZED]

- [Axiom 1 — Immutability](chapter1/axiom-01-immutability.md)

---

## Maybe — [✅ AXIOMATIZED]

- [Axiom 12 — Maybe](chapter1/axiom-12-maybe.md)

---

## Either — [✅ AXIOMATIZED]

- [Axiom 13 — Either](chapter1/axiom-13-either.md)

---

## Result pattern — [✅ AXIOMATIZED]

- [Axiom 15 — Result](chapter1/axiom-15-result.md)

---

## Discriminated unions — [✅ AXIOMATIZED]

- [Axiom 20 — Discriminated unions](chapter1/axiom-20-discriminated-unions.md)

---

## Pattern matching — [✅ AXIOMATIZED]

- [Axiom 10 — Pattern matching](chapter1/axiom-10-pattern-matching.md)

---

## Side effects — [✅ AXIOMATIZED]

- [Axiom 2 — Side effects](chapter1/axiom-02-side-effects.md)

---

## Impure functions — [✅ AXIOMATIZED]

- [Axiom 3 — Impure functions](chapter1/axiom-03-impure-functions.md)

---

## Pure functions — [✅ AXIOMATIZED]

- [Axiom 4 — Pure functions](chapter1/axiom-04-pure-functions.md)

---

## First-class functions — [✅ AXIOMATIZED]

- [Axiom 8 — First-class functions](chapter1/axiom-08-first-class-functions.md)

---

## Higher-order functions — [✅ AXIOMATIZED]

- [Axiom 9 — Higher-order functions](chapter1/axiom-09-higher-order-functions.md)

---

## Impureheim: the impure–pure–impure sandwich — [✅ AXIOMATIZED]

- [Axiom 11 — Impureheim](chapter1/axiom-11-impureheim.md)

---

## Value Objects — [✅ AXIOMATIZED]

- [Axiom 17 — Value objects](chapter1/axiom-17-value-objects.md)

---

## State Machines — [✅ AXIOMATIZED]

- [Axiom 23 — State machines](chapter1/axiom-23-state-machines.md)

---

## Pure functions return actions — [✅ AXIOMATIZED]

- [Axiom 22 — Pure functions returning actions](chapter1/axiom-22-pure-functions-returning-actions.md)

---

## Session Context — [✅ AXIOMATIZED]

- [Axiom 24 — Session Context](chapter1/axiom-24-session-context.md)

---

## Stateful Shell — [✅ AXIOMATIZED]

- [Axiom 25 — Stateful Shell](chapter1/axiom-25-stateful-shell.md)

---

## Encode ordering in types (temporal coupling) — [✅ AXIOMATIZED]

- [Axiom 26 — Typestate](chapter1/axiom-26-typestate.md) — ordering encoded in the type, so an out-of-sequence call won't compile.

---

## Connascence — [✅ AXIOMATIZED]

A coupling taxonomy; the chapter's second evaluative lens, set beside [Cohesion](chapter1/axiom-06-cohesion.md).

- [Axiom 7 — Connascence](chapter1/axiom-07-connascence.md) — keeps Page-Jones's static/dynamic split, but the cut the playbook optimises against is *compiler-enforced vs. convention-carried*; the contested Position-vs-Algorithm strength ordering is flagged, not asserted.

---

## Closures — [🔁 FOLDED]

- [Axiom 8 — First-class functions](chapter1/axiom-08-first-class-functions.md) — Why #3: "Closures carry state along with the function."

---

## Code reusability — [🔁 FOLDED]

- [Axiom 6 — Cohesion](chapter1/axiom-06-cohesion.md) — code is shared only when it is genuinely one concept with one reason to change (e.g. money formatting), never on surface similarity; the rule of three holds the line.

---

## Code locality — [🔁 FOLDED]

- [Axiom 6 — Cohesion](chapter1/axiom-06-cohesion.md) — the *When NOT to* locality bullet: cohesion read at reading-distance — keep statements that read as one thought together rather than shredding them into one-line helpers.

---

## No flag arguments — [🔁 FOLDED]

- [Axiom 6 — Cohesion](chapter1/axiom-06-cohesion.md) — a `bool`/enum that switches a function's body is the tell for two reasons to change living in one place.

---

## Caches — [❌ DISCARDED]

Memoising results behind a stateful store. Too niche to be an axiom.

If ever revisited: explore the FP take plus the correctness of the decorator pattern, especially in OOP.

---

## SOLID critique

🔍 **Open** — critique to write.

Ammunition from the CUPID research (below): North's framing — **principles are compliance gates (binary: you conform or you don't); properties are gradients you move along** — is the cleanest published "why avoid SOLID," and it lines up with simplicity-first + the three-tier why model (Principles / Conceptual-why / Contextual-choices).

Also worth a map: several SOLID letters already land elsewhere, usually sharper at code level —
- **S**RP ≈ [Cohesion](chapter1/axiom-06-cohesion.md) ("one reason to change", but at function grain).
- **D**IP ≈ Impureheim + the composition root.
- **I**SP ≈ honest / small surface area.
- **O**/**L** are mostly about inheritance hierarchies, which this book's FP-leaning register sidesteps.

Next action: write the critique as "where each letter already lives (better-named) here, and where it doesn't apply."

---

## CUPID

🔍 **Open** — decide *Idiomatic*; harvest the gates-vs-gradients line for SOLID.

Dan North's reaction to SOLID: five **properties** (gradients), not rules. Four of five are already covered here:
- **Composable** ≈ combinators / Railway.
- **Predictable** ≈ purity + honest signatures. (His *observability* sub-point is operational → out of scope.)
- **Unix philosophy** ≈ [Cohesion](chapter1/axiom-06-cohesion.md) (one job, judged from the *outside*).
- **Domain-based** ≈ value objects / [Ubiquitous language](#ubiquitous-language).
- **Idiomatic** — the ONLY pillar with no analog here. "Code should feel familiar; follow language + local team idioms." Rhymes with the contextual choices (`AsNoTracking`, jOOQ) — those *are* idiom picks.

Next action: decide whether **Idiomatic** earns its own (late) axiom or is just a contextual-choices note. Steal North's gates-vs-gradients line for the SOLID critique above.

Source: Dan North, "CUPID — for joyful coding" (2022), dannorth.net.

---

## DDD Tactical Patterns

🔍 **Open** — the chapter's headline area: a planned **Chapter 2 Play**, *"FP-style DDD tactical patterns"* (scoped in the [Chapter 2 README](chapter2/README.md), not yet drafted).

- Anemic models real definition, not "put methods in domain objects" — the rebuttal the FP-style domain owes, since pure-functions-over-immutable-data looks anemic only by the naive reading.
- Aggregate as a [Decider](chapter1/axiom-22-pure-functions-returning-actions.md); domain event as a [discriminated union](chapter1/axiom-20-discriminated-unions.md); entity lifecycle as a [state machine](chapter1/axiom-23-state-machines.md); value object as [Axiom 17](chapter1/axiom-17-value-objects.md).

---

## Vertical Slice Architecture

🔍 **Open**

---

## CQRS [ARCHITECTURE - OUT OF SCOPE]

🔍 **Open** — record the boundary only.

Note (from research): CQRS is system topology = **out of scope** (it's a *consumer* of the building blocks, not one). Its code-level sibling is **CQS** (see the Command–Query Separation entry below) — a method returns a value *xor* changes state — and that one is now folded into [Axiom 11 — Impureheim](chapter1/axiom-11-impureheim.md) (and named in [Axiom 4](chapter1/axiom-04-pure-functions.md) and [Axiom 22](chapter1/axiom-22-pure-functions-returning-actions.md)). Keep this section only to *record the boundary*, not to write an axiom.

---

## Ubiquitous language

🔍 **Open**

Should this be an axiom? an early one? a later one?

---

## Define errors out of existence (Ousterhout) — [🔁 FOLDED]

Redesign so the error case cannot arise, instead of reporting it (`substring` clamps to the available range; deletion is idempotent). Simplicity-first's *first* move on the error ladder — before Result/Option, not beside them.

- [Axiom 5 — Honest/total signatures](chapter1/axiom-05-honest-total-signatures.md) — the mechanics: a third route to totality is to *broaden the operation* until every input has a defined answer (clamp / idempotent / default), the imperative-world name for making a function total. Its *When NOT to* carries the counterweight — absorbing an input that can only signal a caller bug *masks* the defect, so fail fast instead of clamping.
- [Axiom 15 — Result](chapter1/axiom-15-result.md) — the ordering: the explicit ladder *eliminate → return honestly → fail fast* positions Result as rung 2, not rung 1, completing the north star (*simple → honest → robust*) for error handling.
- Structural eliminators — the same move at larger grain, each making the bad case unconstructable rather than handled: a value ([Axiom 17](chapter1/axiom-17-value-objects.md)), a record's shape ([Axiom 21](chapter1/axiom-21-illegal-states.md)), a call sequence ([Axiom 26](chapter1/axiom-26-typestate.md)).
- Honest-return rung — [Axiom 12](chapter1/axiom-12-maybe.md) / [Axiom 13](chapter1/axiom-13-either.md): when the case is a real outcome that cannot be erased, it becomes a value.
- **Surfaces in Chapter 2** as the Play *"Designing errors out of existence"* — the same move at design grain (aggregate boundaries, value-object invariants-at-construction); see the [Chapter 2 README](chapter2/README.md). Its home stays the folded axioms above; the Play composes them, adding no new principle.

**Not carried:** Ousterhout's other ch. 10 techniques — *exception masking* and *exception aggregation* are handler-placement / topology concerns (out of scope); *just crash* is already the fail-fast rung folded into [Axiom 15](chapter1/axiom-15-result.md).

**Source:** John Ousterhout, *A Philosophy of Software Design* (2018), ch. 10.

---

## Deep vs. shallow modules (Ousterhout)

🔍 **Open** — splits across both altitudes; the positive half is a planned **Chapter 2 Play**, *"Deep modules, small interfaces"* (scoped in the [Chapter 2 README](chapter2/README.md), not yet drafted).

**What:** module value = functionality ÷ interface cost; **deep** = small interface over lots of implementation. The counterweight: over-splitting into many tiny functions multiplies *shallow* interfaces and can *increase* complexity.

**Verdict:** splits by altitude. The **counterweight** half — don't over-split functions into shallow one-line helpers — stays folded at function grain in [Axiom 6](chapter1/axiom-06-cohesion.md)'s *When NOT to* (shred-locality) and [Axiom 9](chapter1/axiom-09-higher-order-functions.md)'s *Trade-offs* (deep chains of wrappers). The **positive** half — functionality ÷ interface cost — is the Chapter 2 Play, paired there with [Information Hiding](#information-hiding-parnas) as its other face and read through [Cohesion](chapter1/axiom-06-cohesion.md) / [Connascence](chapter1/axiom-07-connascence.md) at module grain.

**Source:** Ousterhout, *A Philosophy of Software Design* (2018).

---

## Boolean blindness (Licata / Harper; De Goes) — [🔁 FOLDED]

A raw `bool` (or untyped flag) throws away the meaning of *what* is true — at the call site, `true` of what?

- [Axiom 5 — Honest/total signatures](chapter1/axiom-05-honest-total-signatures.md) — coined here: an honest signature replaces the blind boolean with a type that names the outcome.
- [Axiom 6 — Cohesion](chapter1/axiom-06-cohesion.md) — named: a `bool` that switches a body is the boolean-blind call site *and* the two-reasons-to-change tell.
- [Axiom 17 — Value objects](chapter1/axiom-17-value-objects.md) — named: a meaningful type stands in place of a bare flag.
- [Axiom 20 — Discriminated unions](chapter1/axiom-20-discriminated-unions.md) — named: a DU names each case instead of encoding it as a boolean.

---

## Algebraic Data Types — the umbrella + state-counting — [🔁 FOLDED]

Sum types (one-of) and product types (all-of); a type's reachable states = the cases summed, the fields multiplied. Counting them is the tool for making illegal states unrepresentable.

- [Axiom 21 — Make illegal states unrepresentable](chapter1/axiom-21-illegal-states.md) — the home: state-counting drives the modelling.
- [Axiom 1 — Immutability](chapter1/axiom-01-immutability.md) — named: records are product types.
- [Axiom 20 — Discriminated unions](chapter1/axiom-20-discriminated-unions.md) — named: DUs are sum types.

---

## Design by Contract (Meyer) — [🔁 FOLDED]

Operations carry preconditions, postconditions, and invariants as part of their contract.

- [Axiom 17 — Value objects](chapter1/axiom-17-value-objects.md) — the home: a smart constructor enforces the type's invariant once, at construction.
- [Axiom 5 — Honest/total signatures](chapter1/axiom-05-honest-total-signatures.md) — postconditions: an honest, total signature *is* the postcondition, checkable by the compiler.
- [Axiom 26 — Typestate](chapter1/axiom-26-typestate.md) — preconditions-as-sequence: ordering preconditions encoded in the type.

---

## Fail-fast on bugs vs. return-values for expected failures — [🔁 FOLDED]

Crash immediately on a programmer error (a bug); return a value for an *expected* failure.

- [Axiom 15 — Result](chapter1/axiom-15-result.md) — the "what counts as an error?" heuristics and the *When NOT to* exception bullets draw the line; it carries the *fail-fast* name and the offensive-programming lineage.

**Not carried:** the dev-time `assert` / `Debug.Assert` mechanism for catching contract violations at their source — left out because in practice I've never reached for it. Revisit only if it earns its keep.

**Source:** James Shore, *Fail Fast* (IEEE Software, 2004); offensive programming (lore).

---

## DRY — the real (knowledge) definition — [🔁 FOLDED]

Don't Repeat Yourself governs *knowledge*, not code text: one authoritative home per piece of knowledge.

- [Axiom 6 — Cohesion](chapter1/axiom-06-cohesion.md) — reason-to-change *is* DRY made operational; it names Hunt & Thomas's original knowledge definition (ref [5] there) and corrects the dedupe-on-sight misreading.

**Source:** Andrew Hunt & David Thomas, *The Pragmatic Programmer* (1999).

---

## SLAP — single level of abstraction per function — [🔁 FOLDED]

Single Level of Abstraction Per function. Both useful halves already live elsewhere; the only standalone residue rests on an undefined "level of abstraction" the playbook declines.

- [Axiom 6 — Cohesion](chapter1/axiom-06-cohesion.md) — the "each function does one job" half *is* cohesion; its *When NOT to* carries the reading-smell kernel: a body that forces mental inlining wants a *named* extraction — extract when the detail is a concept with its own reason to change, not to hit an altitude quota.
- [Axiom 11 — Impureheim](chapter1/axiom-11-impureheim.md) — the "read the body as a paragraph of same-level steps" half is a byproduct of the gather→decide→act step-down, not a separate law.

**Why no axiom of its own** — the residue ("match every statement to one altitude") rests on a "level of abstraction" that nothing — not even SLAP's own references — defines; applied mechanically it yields *extract-till-you-drop*, the mental-inlining smell [Axiom 6](chapter1/axiom-06-cohesion.md) already guards (and the deep-vs-shallow-modules tension noted above).

**Source:** Kent Beck, *Composed Method* (*Smalltalk Best Practice Patterns*, 1997); acronym credited to Glenn Vanderburg, popularized by Neal Ford, *The Productive Programmer* (2008); restated as the *Stepdown Rule* by Robert C. Martin, *Clean Code* (2009); over-application critiqued by John Ousterhout, *A Philosophy of Software Design* (2018), and the Christin Gorman vs. Robert C. Martin "extract till you drop" debate.

---

## Lenses / optics — [CONTRAST / restrained]

**What:** the nested-immutable-update tax; composable getter+setter bundles (lens=field, prism=case, traversal=many).

**Verdict:** cover the *pain* + the cheap built-in answer (`with` / withers) inside Immutability; name optics only as the *deep-nesting escape hatch*, parked in "what might change tomorrow" (JDK 25 / JEP 468 shifts the calculus). A full optic library isn't recommended for mainstream C#/Java today.

**Source:** Kmett `lens`; Scott Logic "The Immutability Gap" series.

---

## Postel's Law vs. parse-don't-validate — [🔁 FOLDED]

The Robustness Principle — *"be conservative in what you do, be liberal in what you accept."* Only *looks* opposed to parse-don't-validate: Postel governs surface *form*, parse-don't-validate governs *meaning* crossing the boundary.

- [Axiom 17 — Value objects](chapter1/axiom-17-value-objects.md) — the "Postel's Law, reconciled" aside in the *Why*: the synthesis is *lenient lexer, strict parser* — a smart constructor may accept generous forms but must emit exactly one canonical value or a `Failure`, the leniency confined to that step. The smart constructor is the *cure* for Postel's harmful form, not its rival.

**Note:** the IETF has since recanted the principle (RFC 9413) — liberal acceptance *without* normalisation is exactly the spec-drift a boundary parse prevents.

**Source:** RFC 760 / RFC 793 (Postel); RFC 9413 (Thomson & Schinazi, 2023); Alexis King, *Parse, Don't Validate* (2019).

---

## Command–Query Separation (CQS) — [🔁 FOLDED]

A method returns a value (query) *xor* changes state (command), never both — the OO ancestor of the pure/impure split. Purity is strictly stronger: a CQS "query" may still read mutable globals.

- [Axiom 11 — Impureheim](chapter1/axiom-11-impureheim.md) — the primary home: Impureheim *is* CQS promoted from the method to the unit of work (gather = query, act = command), the seam a layer boundary rather than a naming convention. Meyer is ref [3].
- [Axiom 4 — Pure functions](chapter1/axiom-04-pure-functions.md) — the query half: purity outruns it, forbidding even the *read* of mutable state a CQS query still permits.
- [Axiom 22 — Pure functions returning actions](chapter1/axiom-22-pure-functions-returning-actions.md) — the command half: the would-be command splits into a pure `Decide` (returns a value) and an impure execute (returns nothing).

**Boundary:** CQRS is system topology and stays out of the axioms; only the registry records the CQS (code) vs. CQRS (architecture) line — see [CQRS](#cqrs-architecture---out-of-scope).

**Source:** Bertrand Meyer, *Object-Oriented Software Construction* (2nd ed., 1997).

---

## Tell, Don't Ask — [🔁 FOLDED]

The OO maxim: don't pull an object's data out to decide for it — push the decision into the object that owns the (mutable) state. A contrast piece, not a missing foundation: the playbook makes the *opposite* bet in its pure core and the *same* bet in its impure shell.

**Where it lives, and how:**

- [**Axiom 0 — Data is not Behaviour**](chapter1/axiom-00-data-vs-behaviour.md) — the road not taken. Tell-Don't-Ask moves the decision *to* the data; the playbook moves the data *to* the decision. Same goal (one home for the rule, no reaching into internals), opposite mechanism (freeze the data vs. hide it behind behaviour).
- [**Axiom 22 — Pure functions returning actions**](chapter1/axiom-22-pure-functions-returning-actions.md) — the inversion. Tell-Don't-Ask *fuses* deciding and acting; this axiom *splits* them: pure `Decide` returns an action value, impure shell executes it.
- [**Axiom 25 — Stateful Shell**](chapter1/axiom-25-stateful-shell.md) — where it belongs. Connections, pools, sockets are places, not values; the shell *tells* them and never asks for their insides. Right rule on the stateful side of the seam, wrong on the pure side.

**Why no axiom of its own** — the goods it offers already have homes: encapsulation → [Axiom 17](chapter1/axiom-17-value-objects.md); rule-in-one-place → [Axiom 6](chapter1/axiom-06-cohesion.md) + [Axiom 22](chapter1/axiom-22-pure-functions-returning-actions.md); read-write-race safety → [Axiom 1](chapter1/axiom-01-immutability.md) + [Axiom 26](chapter1/axiom-26-typestate.md).

**Source:** Andrew Hunt & David Thomas, *The Pragmatic Programmer* (1999); Martin Fowler, *TellDontAsk* (bliki) — cited at [Axiom 0](chapter1/axiom-00-data-vs-behaviour.md) ref [7].

---

## Law of Demeter — [SKIP — narrow]

"One dot" — don't navigate object graphs. Its dangerous half is designed away and the rest is trivial: the law restricts *message sends* (behaviour), not field-walks over transparent data, so a value-core gives it almost nothing to bite on — and what remains is weak, compiler-enforced coupling, not a hazard.

- [Axiom 0 — Data is not Behaviour](chapter1/axiom-00-data-vs-behaviour.md) — the behavioural half: LoD governs which *methods* a unit may call; inert immutable data has no behaviour to reach through, so walking `person.Address.Street` is not what the law targets.
- [Axiom 1 — Immutability](chapter1/axiom-01-immutability.md) — the action-at-a-distance half: immutable *all the way down* (the `Person → Address → Street` setter quiz) means no deep node can mutate underneath a holder, so deep reads are safe to pass around.
- [Axiom 7 — Connascence](chapter1/axiom-07-connascence.md) — the residual: a field chain still binds the reader to the path, but in a typed value world that is Connascence of Name/Type — the weakest, compiler-enforced forms, where a rename or reshape breaks the build at every site. It is Axiom 7's *weak-and-local* case to leave alone, not a train-wreck to fear.
- [Axiom 6 — Cohesion](chapter1/axiom-06-cohesion.md) — the look-alike: reaching deep to *recompute* a rule at the call site is a decide-in-one-place concern, not LoD.

Sibling of [Tell, Don't Ask](#tell-dont-ask): the two "don't reach through" maxims — TDA the *behavioural* reach (folded, as the opposite bet), LoD the *structural* reach (a corollary of the value-core, hence skipped).

**Source:** Karl Lieberherr & Ian Holland, *Assuring Good Style for Object-Oriented Programs* (IEEE Software, 1989) — the law stated as a restriction on which methods a unit may call; Demeter Project, Northeastern, from 1987. Andrew Hunt & David Thomas, *The Pragmatic Programmer* (1999) — treat it as a coupling heuristic for functions, not an absolute rule.

---

## Coupling & Cohesion (Constantine / Yourdon) — [SKIP — historical root]

The original "low coupling, high cohesion": a coupling ladder (content/common/external/control/stamp/data) and a cohesion ladder (coincidental→functional). Control coupling = flag args; common coupling = shared mutable state.

- [Axiom 7 — Connascence](chapter1/axiom-07-connascence.md) — the historical bedrock connascence builds on, subsumed by its finer grain; *Structured Design* is ref [5] there.

**Source:** Stevens, Myers & Constantine, "Structured Design" (IBM Systems Journal, 1974).

---

## Information Hiding (Parnas)

🔍 **Open** — its code-shaping end is a planned **Chapter 2 Play**, paired with [Deep vs. shallow modules](#deep-vs-shallow-modules-ousterhout) (scoped in the [Chapter 2 README](chapter2/README.md), not yet drafted).

A module hides a *secret* — a design decision likely to change. The root of encapsulation and of Ousterhout's deep modules; the same idea read from the secret's side rather than the interface's.

The *strategic* half — decomposition at architectural altitude — stays out of scope. Two in-scope echoes remain: the impure shell hides the stateful *secret* ([Axiom 25 — Stateful Shell](chapter1/axiom-25-stateful-shell.md)), and at module grain "hide the volatile decision behind a small interface" is the Chapter 2 deep-module Play.

**Source:** D.L. Parnas, "On the Criteria To Be Used in Decomposing Systems into Modules" (CACM, 1972).

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

- [Axiom 9 — Higher-order functions](chapter1/axiom-09-higher-order-functions.md) — `Aggregate`/`reduce` (Hughes' `foldr`) *is* the monoid fold.
- [Axiom 19 — Validation](chapter1/axiom-19-validation.md) — merging `ValidationError` lists *is* the list-concatenation monoid; that associativity is the un-named reason `Combine` is order-free and arity-scales.

Worth at most one paragraph of vocabulary, as an aside near that fold/aggregation material — not a chapter.

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

- [Axiom 10 — Pattern matching](chapter1/axiom-10-pattern-matching.md) — the home. The [`Match` method form](chapter1/axiom-10-pattern-matching.md#the-method-form) (`R Match<R>(Func<Circle,R>, …)`) *is* the catamorphism encoding — one handler per case, returning `R`, with exhaustiveness as its totality; ref [4] there already cites `Option.fold`/`Result.fold`, the catamorphisms by name.
- [Axiom 5 — Honest/total signatures](chapter1/axiom-05-honest-total-signatures.md) — that totality is the same total-consumer property: every case answered, no partial branch.
- [Axiom 12 — Maybe](chapter1/axiom-12-maybe.md), [Axiom 13 — Either](chapter1/axiom-13-either.md), [Axiom 15 — Result](chapter1/axiom-15-result.md) — each type's `.Match` is its two-case catamorphism.

The list `reduce` is itself a catamorphism (the List one), but it lives in [Monoid / Semigroup](#monoid--semigroup--skip--vocabulary-only) as the *monoid fold*; this entry is the general notion, whose everyday face on the book's flat DUs is `Match`.

---

## Persistent data structures / structural sharing — [🔁 FOLDED]

The "isn't immutability slow?" rebuttal: structural sharing rebuilds only the changed path, so immutable "copies" of large collections stay cheap.

- [Axiom 1 — Immutability](chapter1/axiom-01-immutability.md) — the ["But isn't all this copying slow?" sidebar](chapter1/axiom-01-immutability.md#but-isnt-all-this-copying-slow) in *Trade-offs*: a small record copies a few fields; a large collection uses a persistent collection (`System.Collections.Immutable`, Vavr) that shares unchanged nodes for O(log n) updates. Okasaki (ref [4] there) is the deep theory; the sidebar is the everyday answer.

---

## Referential transparency / determinism — [SKIP — already covered]

Same call always returns the same value, and is substitutable for that value.

- [Axiom 4 — Pure functions](chapter1/axiom-04-pure-functions.md) — already named here; the one thing worth surfacing is the testability payoff: RT code needs no mocks — you test it by substituting values.

---

## Idempotence — [SKIP — already covered]

Applying an action twice lands in the same state as applying it once.

- [Axiom 23 — State machines](chapter1/axiom-23-state-machines.md) — already here; the code-level half is "prefer set-shaped over delta-shaped actions — they survive replay." Its retry-safety payoff is operational, hence out of scope.

---

## Zero-One-Infinity rule — [🔁 FOLDED]

Allow none, exactly one, or unbounded-many of a thing — never an arbitrary fixed cap. Its only code-level residue is the *inverse* of [Axiom 21](chapter1/axiom-21-illegal-states.md); "arbitrary" is a domain judgment the type cannot make, so it is no standalone coding axiom.

- [Axiom 21 — Make illegal states unrepresentable](chapter1/axiom-21-illegal-states.md) — the home: the state-count run backwards. A type representing *fewer* states than the domain allows (a list capped at three for convenience) makes a **legal** state unrepresentable — the mirror of this axiom; the fix is to loosen until representable meets legal.
- [Axiom 17 — Value objects](chapter1/axiom-17-value-objects.md) — where a cap *is* a real invariant: a value object whose `Add` returns a `Result` failure on overflow encodes the bound honestly — the cure for a justified limit, not a banned number.

**Deferred:** the other half — *deciding whether a given bound is real* — is not a chapter-1 tool but a modelling discipline; it belongs with later domain-design material (DDD tactical patterns), not the foundations. The registry sits outside the chapters precisely to carry that kind of forward pointer.

**Source:** van der Poel / MacLennan.

---

## Composition over inheritance — [SKIP — already the positive program]

Reuse by holding and passing collaborators as values rather than extending a base class. Not skipped for clashing with the register — skipped because the register already *is* it: the book composes behaviour as function values, and inheritance stays on the table as an honest trade-off in the axioms' *When NOT to*, never as a target.

The composition half — the default:

- [Axiom 8 — First-class functions](chapter1/axiom-08-first-class-functions.md) — behaviour is a *value before it needs a host*, "the prerequisite for composition"; the GoF Strategy/Command/Visitor patterns (ref [1] there) are what function values collapse, Norvig's "16 of 23 patterns vanish" the count (ref [2]).
- [Axiom 9 — Higher-order functions](chapter1/axiom-09-higher-order-functions.md) — where the day-to-day composition lives (`Compose`); names the rival outright — "expressing varying behaviour through inheritance or interface plumbing" pays a type per variation where a function-as-parameter pays one slot. Template Method / Strategy resolve here (ref [2]).

The over-inheritance half — the hierarchy designed away, kept honestly:

- [Axiom 0 — Data is not Behaviour](chapter1/axiom-00-data-vs-behaviour.md) — the root: inert data plus free functions removes the base-class-for-reuse reflex at the source.
- [Axiom 20 — Discriminated unions](chapter1/axiom-20-discriminated-unions.md) — a closed subtype hierarchy consumed by polymorphic dispatch becomes a sealed DU + pattern match; the *When NOT to* keeps a virtual method per leaf for intrinsic operations and the non-sealed interface "exactly the OO shape" for an open set.
- [Axiom 10 — Pattern matching](chapter1/axiom-10-pattern-matching.md) — the same virtual-dispatch-vs-match trade-off, inheritance kept as the right tool for intrinsic behaviour and open sets.

Echoes the [SOLID critique](#solid-critique)'s note that the **O**/**L** letters are about inheritance hierarchies this FP-leaning register sidesteps.

**Source:** Gang of Four, *Design Patterns* (1994) — cross-listed at [Axiom 8](chapter1/axiom-08-first-class-functions.md) ref [1] and [Axiom 9](chapter1/axiom-09-higher-order-functions.md) ref [2].
