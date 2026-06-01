# Concept Registry

*Every coding concept I've considered — and where it landed, or why it didn't.*

Joan Comas, Senior Software Architect — since June 2024

**Status legend:** ✅ **Axiomatized** (became its own axiom) · 🔁 **Folded** (absorbed into an existing axiom) · ❌ **Discarded** (too niche / out of scope) · 🔍 **Open** (not yet decided — any `[TAG]` is the *recommended* disposition, not a decision yet)

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

🔍 **Open**

- Anemic models real definition, not "put methods in domain objects".

---

## Vertical Slice Architecture

🔍 **Open**

---

## CQRS [ARCHITECTURE - OUT OF SCOPE]

🔍 **Open** — record the boundary only.

Note (from research): CQRS is system topology = **out of scope** (it's a *consumer* of the building blocks, not one). Its code-level sibling is **CQS** (see the Command–Query Separation entry in the research sweep below) — a method returns a value *xor* changes state — and that one is now folded into [Axiom 11 — Impureheim](chapter1/axiom-11-impureheim.md) (and named in [Axiom 4](chapter1/axiom-04-pure-functions.md) and [Axiom 22](chapter1/axiom-22-pure-functions-returning-actions.md)). Keep this section only to *record the boundary*, not to write an axiom.

---

## Ubiquitous language

🔍 **Open**

Should this be an axiom? an early one? a later one?

---

## Research sweep — 2026-05-29: external concepts not yet covered

A web + literature sweep against the current axioms surfaced the candidates below. Many have since been resolved — ✅ **axiomatized** or 🔁 **folded** — or set aside (skipped); the rest still carry a `[TAG]` recommending a disposition not yet decided.

**Verdict tags:** **[AXIOM?]** possible standalone axiom · **[FOLD]** fold into an existing axiom as a named hook / "why" · **[CONTRAST]** trade-off / non-dogmatism material · **[SKIP]** too niche, or already covered under another name.

Headline: most famous "principles" I hadn't named (SOLID, CUPID, CQS, Tell-Don't-Ask, Demeter, coupling/cohesion) are *already mine under better names* or are contrast pieces. The genuinely new territory is narrow: **connascence** (a meta-lens, now Axiom 7) and **"define errors out of existence"** (a still-open rung below `Result`).

---

### Connascence (Meilir Page-Jones) — [✅ AXIOMATIZED]

The sweep's top pick; full entry under **Connascence** earlier in this registry.

- [Axiom 7 — Connascence](chapter1/axiom-07-connascence.md) — the chapter's second evaluative lens.

---

### Define errors out of existence (Ousterhout) — [AXIOM? / FOLD]

**What:** redesign the API so the error case can't arise, instead of reporting it (`unlink` succeeds / marks-for-deletion; `substring` clamps to the available range). It sits *before* Result/Option in the simplicity ladder.

**Why it matters:** it completes the north star into an explicit ordering the book only implies — *eliminate the error (simplest) → else return it honestly as Result/Option/DU (honest) → never throw for control flow (robust).*

**Verdict:** high value. Either a short standalone axiom, or a "why" prepended to the Maybe/Result axioms. Decide which.

**Source:** John Ousterhout, *A Philosophy of Software Design* (2018).

---

### Deep vs. shallow modules (Ousterhout) — [AXIOM? / CONTRAST]

**What:** module value = functionality ÷ interface cost; **deep** = small interface over lots of implementation. The counterweight: over-splitting into many tiny functions multiplies *shallow* interfaces and can *increase* complexity.

**Verdict:** a healthy tension against combinator / tiny-function enthusiasm. Could be its own note, or a "when NOT to" inside [Cohesion](chapter1/axiom-06-cohesion.md) / Higher-order functions.

**Source:** Ousterhout, *A Philosophy of Software Design* (2018).

---

### Boolean blindness (Licata / Harper; De Goes) — [🔁 FOLDED]

A raw `bool` (or untyped flag) throws away the meaning of *what* is true — at the call site, `true` of what?

- [Axiom 5 — Honest/total signatures](chapter1/axiom-05-honest-total-signatures.md) — coined here: an honest signature replaces the blind boolean with a type that names the outcome.
- [Axiom 6 — Cohesion](chapter1/axiom-06-cohesion.md) — named: a `bool` that switches a body is the boolean-blind call site *and* the two-reasons-to-change tell.
- [Axiom 17 — Value objects](chapter1/axiom-17-value-objects.md) — named: a meaningful type stands in place of a bare flag.
- [Axiom 20 — Discriminated unions](chapter1/axiom-20-discriminated-unions.md) — named: a DU names each case instead of encoding it as a boolean.

---

### Algebraic Data Types — the umbrella + state-counting — [🔁 FOLDED]

Sum types (one-of) and product types (all-of); a type's reachable states = the cases summed, the fields multiplied. Counting them is the tool for making illegal states unrepresentable.

- [Axiom 21 — Make illegal states unrepresentable](chapter1/axiom-21-illegal-states.md) — the home: state-counting drives the modelling.
- [Axiom 1 — Immutability](chapter1/axiom-01-immutability.md) — named: records are product types.
- [Axiom 20 — Discriminated unions](chapter1/axiom-20-discriminated-unions.md) — named: DUs are sum types.

---

### Design by Contract (Meyer) — [🔁 FOLDED]

Operations carry preconditions, postconditions, and invariants as part of their contract.

- [Axiom 17 — Value objects](chapter1/axiom-17-value-objects.md) — the home: a smart constructor enforces the type's invariant once, at construction.
- [Axiom 5 — Honest/total signatures](chapter1/axiom-05-honest-total-signatures.md) — postconditions: an honest, total signature *is* the postcondition, checkable by the compiler.
- [Axiom 26 — Typestate](chapter1/axiom-26-typestate.md) — preconditions-as-sequence: ordering preconditions encoded in the type.

---

### Fail-fast on bugs vs. return-values for expected failures — [🔁 FOLDED]

Crash immediately on a programmer error (a bug); return a value for an *expected* failure.

- [Axiom 15 — Result](chapter1/axiom-15-result.md) — the "what counts as an error?" heuristics and the *When NOT to* exception bullets draw the line; it carries the *fail-fast* name and the offensive-programming lineage.

**Not carried:** the dev-time `assert` / `Debug.Assert` mechanism for catching contract violations at their source — left out because in practice I've never reached for it. Revisit only if it earns its keep.

**Source:** James Shore, *Fail Fast* (IEEE Software, 2004); offensive programming (lore).

---

### DRY — the real (knowledge) definition — [🔁 FOLDED]

Don't Repeat Yourself governs *knowledge*, not code text: one authoritative home per piece of knowledge.

- [Axiom 6 — Cohesion](chapter1/axiom-06-cohesion.md) — reason-to-change *is* DRY made operational; it names Hunt & Thomas's original knowledge definition (ref [5] there) and corrects the dedupe-on-sight misreading.

**Source:** Andrew Hunt & David Thomas, *The Pragmatic Programmer* (1999).

---

### SLAP — single level of abstraction per function — [🔁 FOLDED]

Single Level of Abstraction Per function. Both useful halves already live elsewhere; the only standalone residue rests on an undefined "level of abstraction" the playbook declines.

- [Axiom 6 — Cohesion](chapter1/axiom-06-cohesion.md) — the "each function does one job" half *is* cohesion; its *When NOT to* carries the reading-smell kernel: a body that forces mental inlining wants a *named* extraction — extract when the detail is a concept with its own reason to change, not to hit an altitude quota.
- [Axiom 11 — Impureheim](chapter1/axiom-11-impureheim.md) — the "read the body as a paragraph of same-level steps" half is a byproduct of the gather→decide→act step-down, not a separate law.

**Why no axiom of its own** — the residue ("match every statement to one altitude") rests on a "level of abstraction" that nothing — not even SLAP's own references — defines; applied mechanically it yields *extract-till-you-drop*, the mental-inlining smell [Axiom 6](chapter1/axiom-06-cohesion.md) already guards (and the deep-vs-shallow-modules tension logged above in this sweep).

**Source:** Kent Beck, *Composed Method* (*Smalltalk Best Practice Patterns*, 1997); acronym credited to Glenn Vanderburg, popularized by Neal Ford, *The Productive Programmer* (2008); restated as the *Stepdown Rule* by Robert C. Martin, *Clean Code* (2009); over-application critiqued by John Ousterhout, *A Philosophy of Software Design* (2018), and the Christin Gorman vs. Robert C. Martin "extract till you drop" debate.

---

### Lenses / optics — [CONTRAST / restrained]

**What:** the nested-immutable-update tax; composable getter+setter bundles (lens=field, prism=case, traversal=many).

**Verdict:** cover the *pain* + the cheap built-in answer (`with` / withers) inside Immutability; name optics only as the *deep-nesting escape hatch*, parked in "what might change tomorrow" (JDK 25 / JEP 468 shifts the calculus). A full optic library isn't recommended for mainstream C#/Java today.

**Source:** Kmett `lens`; Scott Logic "The Immutability Gap" series.

---

### Postel's Law vs. parse-don't-validate — [🔁 FOLDED]

The Robustness Principle — *"be conservative in what you do, be liberal in what you accept."* Only *looks* opposed to parse-don't-validate: Postel governs surface *form*, parse-don't-validate governs *meaning* crossing the boundary.

- [Axiom 17 — Value objects](chapter1/axiom-17-value-objects.md) — the "Postel's Law, reconciled" aside in the *Why*: the synthesis is *lenient lexer, strict parser* — a smart constructor may accept generous forms but must emit exactly one canonical value or a `Failure`, the leniency confined to that step. The smart constructor is the *cure* for Postel's harmful form, not its rival.

**Note:** the IETF has since recanted the principle (RFC 9413) — liberal acceptance *without* normalisation is exactly the spec-drift a boundary parse prevents.

**Source:** RFC 760 / RFC 793 (Postel); RFC 9413 (Thomson & Schinazi, 2023); Alexis King, *Parse, Don't Validate* (2019).

---

### Command–Query Separation (CQS) — [🔁 FOLDED]

A method returns a value (query) *xor* changes state (command), never both — the OO ancestor of the pure/impure split. Purity is strictly stronger: a CQS "query" may still read mutable globals.

- [Axiom 11 — Impureheim](chapter1/axiom-11-impureheim.md) — the primary home: Impureheim *is* CQS promoted from the method to the unit of work (gather = query, act = command), the seam a layer boundary rather than a naming convention. Meyer is ref [3].
- [Axiom 4 — Pure functions](chapter1/axiom-04-pure-functions.md) — the query half: purity outruns it, forbidding even the *read* of mutable state a CQS query still permits.
- [Axiom 22 — Pure functions returning actions](chapter1/axiom-22-pure-functions-returning-actions.md) — the command half: the would-be command splits into a pure `Decide` (returns a value) and an impure execute (returns nothing).

**Boundary:** CQRS is system topology and stays out of the axioms; only the registry records the CQS (code) vs. CQRS (architecture) line — see [CQRS](#cqrs-architecture---out-of-scope).

**Source:** Bertrand Meyer, *Object-Oriented Software Construction* (2nd ed., 1997).

---

### Tell, Don't Ask — [🔁 FOLDED]

The OO maxim: don't pull an object's data out to decide for it — push the decision into the object that owns the (mutable) state. A contrast piece, not a missing foundation: the playbook makes the *opposite* bet in its pure core and the *same* bet in its impure shell.

**Where it lives, and how:**

- [**Axiom 0 — Data is not Behaviour**](chapter1/axiom-00-data-vs-behaviour.md) — the road not taken. Tell-Don't-Ask moves the decision *to* the data; the playbook moves the data *to* the decision. Same goal (one home for the rule, no reaching into internals), opposite mechanism (freeze the data vs. hide it behind behaviour).
- [**Axiom 22 — Pure functions returning actions**](chapter1/axiom-22-pure-functions-returning-actions.md) — the inversion. Tell-Don't-Ask *fuses* deciding and acting; this axiom *splits* them: pure `Decide` returns an action value, impure shell executes it.
- [**Axiom 25 — Stateful Shell**](chapter1/axiom-25-stateful-shell.md) — where it belongs. Connections, pools, sockets are places, not values; the shell *tells* them and never asks for their insides. Right rule on the stateful side of the seam, wrong on the pure side.

**Why no axiom of its own** — the goods it offers already have homes: encapsulation → [Axiom 17](chapter1/axiom-17-value-objects.md); rule-in-one-place → [Axiom 6](chapter1/axiom-06-cohesion.md) + [Axiom 22](chapter1/axiom-22-pure-functions-returning-actions.md); read-write-race safety → [Axiom 1](chapter1/axiom-01-immutability.md) + [Axiom 26](chapter1/axiom-26-typestate.md).

**Source:** Andrew Hunt & David Thomas, *The Pragmatic Programmer* (1999); Martin Fowler, *TellDontAsk* (bliki) — cited at [Axiom 0](chapter1/axiom-00-data-vs-behaviour.md) ref [7].

---

### Law of Demeter — [SKIP — narrow]

"One dot" — don't navigate object graphs. Largely *designed away* by value-passing pure cores: a core that receives plain values has no strangers to talk to.

- [Axiom 7 — Connascence](chapter1/axiom-07-connascence.md) — subsumes it; a train-wreck is bad-locality connascence. Worth a mention as a coupling heuristic at most.

**Source:** Ian Holland, Demeter Project (1987).

---

### Coupling & Cohesion (Constantine / Yourdon) — [SKIP — historical root]

The original "low coupling, high cohesion": a coupling ladder (content/common/external/control/stamp/data) and a cohesion ladder (coincidental→functional). Control coupling = flag args; common coupling = shared mutable state.

- [Axiom 7 — Connascence](chapter1/axiom-07-connascence.md) — the historical bedrock connascence builds on, subsumed by its finer grain; *Structured Design* is ref [5] there.

**Source:** Stevens, Myers & Constantine, "Structured Design" (IBM Systems Journal, 1974).

---

### Information Hiding (Parnas) — [SKIP — mostly architecture]

A module hides a *secret* — a design decision likely to change. The root of encapsulation and of Ousterhout's deep modules.

Mostly a decomposition criterion at architectural altitude, hence out of scope. The one in-scope echo: the impure shell hides the stateful *secret* — see [Axiom 25 — Stateful Shell](chapter1/axiom-25-stateful-shell.md).

**Source:** D.L. Parnas, "On the Criteria To Be Used in Decomposing Systems into Modules" (CACM, 1972).

---

### Monoid / Semigroup — [SKIP — vocabulary only]

An associative `combine` (plus an identity element for a monoid). `Aggregate`/`reduce` *is* a monoid fold; associativity is what licenses parallel reduction.

Worth at most one paragraph of vocabulary near any aggregation/fold material — not a chapter; beyond that it's category-theory tourism.

---

### Catamorphism / fold — [SKIP — jargon]

The exhaustive `Match` on a DU *is* that DU's catamorphism — the total consumer of a sum type.

Too jargon-heavy to name; the totality point is already carried by [Axiom 10 — Pattern matching](chapter1/axiom-10-pattern-matching.md) and [Axiom 5 — Honest/total signatures](chapter1/axiom-05-honest-total-signatures.md). A one-line aside for the curious at most.

---

### Persistent data structures / structural sharing — [SKIP — sidebar]

The "isn't immutability slow?" rebuttal: structural sharing makes "copies" cheap (only the changed path is rebuilt); reach for the standard immutable collections (`System.Collections.Immutable`, Vavr) rather than rolling your own.

Worth one reassurance sidebar inside [Axiom 1 — Immutability](chapter1/axiom-01-immutability.md); Okasaki-level theory is academic for this audience.

---

### Referential transparency / determinism — [SKIP — already covered]

Same call always returns the same value, and is substitutable for that value.

- [Axiom 4 — Pure functions](chapter1/axiom-04-pure-functions.md) — already named here; the one thing worth surfacing is the testability payoff: RT code needs no mocks — you test it by substituting values.

---

### Idempotence — [SKIP — already covered]

Applying an action twice lands in the same state as applying it once.

- [Axiom 23 — State machines](chapter1/axiom-23-state-machines.md) — already here; the code-level half is "prefer set-shaped over delta-shaped actions — they survive replay." Its retry-safety payoff is operational, hence out of scope.

---

### Zero-One-Infinity rule — [SKIP — one-liner]

No arbitrary fixed limits in your types — allow 0, exactly 1, or many, never "up to 3."

Memorable but narrow; a one-line aside in domain-modelling at most.

**Source:** van der Poel / MacLennan.

---

### Composition over inheritance — [SKIP — off-register]

Reuse by holding collaborators (delegation) rather than extending base classes.

Foundational but OO-classical, against this book's FP-leaning register. If used at all, recast in the book's idiom (functions/values + explicit delegation) and present inheritance as a trade-off point — never an attack (per CLAUDE.md).

**Source:** Gang of Four, *Design Patterns* (1994).
