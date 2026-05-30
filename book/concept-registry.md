# Concept Registry

*Every coding concept I've considered — and where it landed, or why it didn't.*

Joan Comas, Senior Software Architect — since June 2024

**Status legend:** ✅ **Axiomatized** (became its own axiom) · 🔁 **Folded** (absorbed into an existing axiom) · ❌ **Discarded** (too niche / out of scope) · 🔍 **Open** (not yet decided — any `[TAG]` is the *recommended* disposition, not a decision yet)

---

## Immutability

✅ **Axiomatized** → [Axiom 1 — Immutability](chapter1/axiom-01-immutability.md)

---

## Maybe

✅ **Axiomatized** → [Axiom 11 — Maybe](chapter1/axiom-11-maybe.md)

---

## Either

✅ **Axiomatized** → [Axiom 12 — Either](chapter1/axiom-12-either.md)

---

## Result pattern

✅ **Axiomatized** → [Axiom 14 — Result](chapter1/axiom-14-result.md)

---

## Discriminated unions

✅ **Axiomatized** → [Axiom 19 — Discriminated unions](chapter1/axiom-19-discriminated-unions.md)

---

## Pattern matching

✅ **Axiomatized** → [Axiom 9 — Pattern matching](chapter1/axiom-09-pattern-matching.md)

---

## Side effects

✅ **Axiomatized** → [Axiom 2 — Side effects](chapter1/axiom-02-side-effects.md)

---

## Impure functions

✅ **Axiomatized** → [Axiom 3 — Impure functions](chapter1/axiom-03-impure-functions.md)

---

## Pure functions

✅ **Axiomatized** → [Axiom 4 — Pure functions](chapter1/axiom-04-pure-functions.md)

---

## First-class functions

✅ **Axiomatized** → [Axiom 7 — First-class functions](chapter1/axiom-07-first-class-functions.md)

---

## Higher-order functions

✅ **Axiomatized** → [Axiom 8 — Higher-order functions](chapter1/axiom-08-higher-order-functions.md)

---

## Impureheim: the impure–pure–impure sandwich

✅ **Axiomatized** → [Axiom 10 — Impureheim](chapter1/axiom-10-impureheim.md)

---

## Value Objects

✅ **Axiomatized** → [Axiom 16 — Value objects](chapter1/axiom-16-value-objects.md)

---

## State Machines

✅ **Axiomatized** → [Axiom 22 — State machines](chapter1/axiom-22-state-machines.md)

---

## Pure functions return actions

✅ **Axiomatized** → [Axiom 21 — Pure functions returning actions](chapter1/axiom-21-pure-functions-returning-actions.md)

---

## Session Context

✅ **Axiomatized** → [Axiom 23 — Session Context](chapter1/axiom-23-session-context.md)

---

## Stateful Shell

✅ **Axiomatized** → [Axiom 24 — Stateful Shell](chapter1/axiom-24-stateful-shell.md)

---

## Encode ordering in types (temporal coupling)

✅ **Axiomatized** → [Axiom 25 — Typestate](chapter1/axiom-25-typestate.md)

---

## Closures

🔁 **Folded** → [Axiom 7 — First-class functions](chapter1/axiom-07-first-class-functions.md) (Why #3, "Closures carry state along with the function").

---

## Code reusability

🔁 **Folded** → [Axiom 6 — Cohesion](chapter1/axiom-06-cohesion.md)

---

## Code locality

🔁 **Folded** → [Axiom 6 — Cohesion](chapter1/axiom-06-cohesion.md)

---

## No flag arguments

🔁 **Folded** → [Axiom 6 — Cohesion](chapter1/axiom-06-cohesion.md)

---

## Caches

❌ **Discarded** — too niche to be an axiom. (If ever revisited: explore the FP take + the correctness of the decorator pattern, especially in OOP.)

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

## CQRS

🔍 **Open** — record the boundary only.

Note (from research): CQRS is system topology = **out of scope** (it's a *consumer* of the building blocks, not one). Its code-level sibling is **CQS** (see the Command–Query Separation entry in the research sweep below) — a method returns a value *xor* changes state — and that one is already covered by Pure functions + Impureheim. Keep this section only to *record the boundary*, not to write an axiom.

---

## Ubiquitous language

🔍 **Open**

Should this be an axiom? an early one? a later one?

---

## Research sweep — 2026-05-29: external concepts not yet covered

🔍 Everything in this section is **Open**. A web + literature sweep against the current axioms surfaced the candidates below; the `[TAG]` after each title is the *recommended* disposition, not a decision yet — dig deeper, then axiomatize / fold / discard.

**Verdict tags:** **[AXIOM?]** possible standalone axiom · **[FOLD]** fold into an existing axiom as a named hook / "why" · **[CONTRAST]** trade-off / non-dogmatism material · **[SKIP]** too niche, or already covered under another name.

Headline: most famous "principles" I hadn't named (SOLID, CUPID, CQS, Tell-Don't-Ask, Demeter, coupling/cohesion) are *already yours under better names* or are contrast pieces. The genuinely new territory is narrow: **connascence** (a meta-lens) and **"define errors out of existence"** (a missing rung below `Result`).

---

### Connascence (Meilir Page-Jones) — [AXIOM? — top pick]

**What:** a graded, named taxonomy of coupling. Static (Name → Type → Meaning → Position → Algorithm) + dynamic (Execution order → Timing → Value → Identity), weakest→strongest. Three axes: **strength, degree, locality**. Weirich's rules: convert strong→weak; the farther apart two things sit, the weaker their connascence must be.

**Why it's the standout:** it's the *measurement theory underneath axioms I already wrote*, and it retroactively justifies them — Typestate = Execution-order → Type; value objects = Meaning → Type; make-illegal-states = killing Connascence of Value; immutability = killing Connascence of Identity; flag args = Connascence of Meaning; positional→named/records = Position → Name. The "thinking tool to argue about borderline coupling" I felt was missing.

**Open question to resolve:** leaf axiom, or a *cross-cutting lens / framing chapter* (since it explains the others rather than sitting beside them)? Also: verify the Position-vs-Algorithm ordering against the Page-Jones primary text — secondary sources disagree.

**Source:** Page-Jones, *Fundamentals of OO Design in UML* (1999); connascence.io; Jim Weirich talks.

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

### Boolean blindness (Licata / Harper; De Goes) — [FOLD → Discriminated unions + flag-args]

**What:** a `bool` param/return erases *which case you're in*; a `bool` is a degenerate, anonymous 2-case sum type. The deeper "why" beneath flag-args ("prefer a named DU").

**Verdict:** fold as the named "why" into the DU axiom and the flag-args material already absorbed into [Cohesion](chapter1/axiom-06-cohesion.md). Jargon-light and memorable — generalizes flag-args from "ugly call site" to "lost type information."

**Source:** term coined by Dan Licata / Robert Harper; De Goes, "Destroy All Ifs".

---

### Algebraic Data Types — the umbrella + state-counting — [FOLD → records / DUs / illegal-states]

**What:** name the umbrella over what's already split across axioms — **products** (records) multiply states, **sums** (DUs) add them. The cardinality arithmetic is a *mechanical* justification for make-illegal-states: count reachable states; a `bool×bool` (4) modelling a concept with 3 valid combos is a smell a sum collapses to exactly 3.

**Verdict:** near-zero new mechanics, high pedagogical payoff. Fold as a unifying frame tying Immutability(records), DUs(sums), and make-illegal-states together.

**Source:** ML/Haskell lineage; jrsinclair, "ADTs I wish someone had explained".

---

### Design by Contract (Meyer) — [FOLD → Value objects / parse-don't-validate]

**What:** preconditions + postconditions + class invariants. The lens that sharpens *why types beat runtime assertions* — smart constructors enforce invariants by construction; parse-don't-validate *discharges* preconditions at the type boundary; types can't be disabled in production (Eiffel's assertions can).

**Verdict:** conceptual-why material for value-objects + honest-signatures, not a technique of its own. "DbC asks the same three questions; we answer them with types, at compile time."

**Source:** Meyer, *OO Software Construction*; "Applying Design by Contract" (IEEE, 1992).

---

### Fail-fast on bugs vs. return-values for expected failures — [FOLD → Result / exceptions story]

**What:** the one distinction not yet explicit — contract violations / bugs should **throw/assert** (never `Result`); anticipated domain failures are **values** (`Result`/`Option`). The principled half of "offensive programming."

**Verdict:** short "why" inside the Result axiom; sharpens the Result-vs-exceptions boundary.

**Source:** offensive programming (Wikipedia); fail-fast lore.

---

### DRY — the real (knowledge) definition — [FOLD → Cohesion]

**What:** "one authoritative representation of *knowledge*, not deduplicated *code text*." Worth stating *because the common misreading (dedupe code) fights simplicity-first* — incidental duplication is fine; divergent representations of one piece of knowledge is the sin. This is exactly the boundary↔domain↔persistence mapping tension.

**Verdict:** fold into [Cohesion](chapter1/axiom-06-cohesion.md) (already holds rule-of-three / duplication-vs-wrong-abstraction) — add the knowledge-vs-text inoculation.

**Source:** Hunt & Thomas, *The Pragmatic Programmer*.

---

### SLAP — single level of abstraction per function — [AXIOM?-soft / FOLD]

**What:** every statement in a function body at the same altitude; push the "how" down into named helpers, read the body as a paragraph of same-level steps.

**Verdict:** in-scope (it's literally "anatomy of a function") and uncovered, but soft — a concise how-to, sibling to Cohesion / honest-signatures. Needs a "when NOT to" (don't extract one-line helpers just to comply).

**Source:** Robert C. Martin, *Clean Code* (2009).

---

### Lenses / optics — [CONTRAST / restrained]

**What:** the nested-immutable-update tax; composable getter+setter bundles (lens=field, prism=case, traversal=many).

**Verdict:** cover the *pain* + the cheap built-in answer (`with` / withers) inside Immutability; name optics only as the *deep-nesting escape hatch*, parked in "what might change tomorrow" (JDK 25 / JEP 468 shifts the calculus). A full optic library isn't recommended for mainstream C#/Java today.

**Source:** Kmett `lens`; Scott Logic "The Immutability Gap" series.

---

### Postel's Law vs. parse-don't-validate (the tension) — [CONTRAST / FOLD]

**What:** they look opposed but aren't — Postel ("liberal in what you accept") is about *surface form*; parse-don't-validate is strict about *meaning crossing the boundary*. "Lenient lexing, strict typing." Postel itself is now a cautionary tale (IETF "Postel was wrong"), not a rule to follow.

**Verdict:** a sharp concept note reinforcing honest-signatures / parse-don't-validate; not an axiom.

**Source:** RFC 760; Thomson, "Harmful Consequences of the Robustness Principle"; Alexis King, "Parse, don't validate".

---

### Command–Query Separation (CQS) — [SKIP — covered; distinct from CQRS]

**What:** a method returns a value (query) *xor* changes state (command), never both. The OO ancestor of the pure/impure split; purity is strictly stronger (a CQS "query" may still read mutable globals).

**Verdict:** one-line note; covered by Pure functions + Impureheim. Pin the **CQS (code) vs CQRS (architecture, out of scope)** distinction — see the [CQRS](#cqrs) section.

**Source:** Bertrand Meyer.

---

### Tell, Don't Ask — [CONTRAST]

**What:** push behaviour into the stateful object instead of pulling data out to decide. The *OO* answer to cohesion — the deliberate opposite of the functional core ("pull data out as values, decide purely").

**Verdict:** trade-off / non-dogmatism piece; sharpens why the functional core makes a different bet. Not a missing foundation.

**Source:** Hunt & Thomas; Fowler bliki.

---

### Law of Demeter — [SKIP — narrow]

**What:** "one dot" / don't navigate object graphs. Largely *designed away* by value-passing pure cores (a core that receives plain values has no strangers to talk to).

**Verdict:** mention as a coupling heuristic at most; subsumed by connascence (a train-wreck = bad-locality connascence). Lowest priority.

**Source:** Ian Holland, Demeter Project, 1987.

---

### Coupling & Cohesion (Constantine / Yourdon) — [SKIP / historical root]

**What:** the original "low coupling, high cohesion". Coupling ladder (content/common/external/control/stamp/data); cohesion ladder (coincidental→functional). Control coupling = flag args; common coupling = shared mutable state.

**Verdict:** historical bedrock, subsumed by connascence's finer grain. Cite once where connascence lands.

**Source:** Stevens, Myers & Constantine, "Structured Design" (IBM Systems Journal, 1974).

---

### Information Hiding (Parnas) — [SKIP — mostly architecture]

**What:** a module hides a *secret* = a design decision likely to change. Root of encapsulation and of Ousterhout's deep modules.

**Verdict:** mostly out of scope (it's a decomposition criterion = architectural altitude). Cite once as the root of "the impure shell hides the stateful secret."

**Source:** D.L. Parnas, "On the Criteria To Be Used in Decomposing Systems into Modules" (CACM, 1972).

---

### Monoid / Semigroup — [SKIP — vocabulary only]

**What:** associative `combine` (+ identity element). `Aggregate`/`reduce` *is* a monoid fold; associativity is what licenses parallel reduction.

**Verdict:** one paragraph of vocabulary near any aggregation/fold material, at most. Not a chapter — beyond that it's category-theory tourism.

---

### Catamorphism / fold — [SKIP — jargon]

**What:** the exhaustive `Match` on a DU *is* that DU's catamorphism (the total consumer of a sum type).

**Verdict:** too jargon-heavy to name; the totality point is already carried by pattern-matching + honest-signatures. One-line aside for the curious at most.

---

### Persistent data structures / structural sharing — [SKIP — sidebar]

**What:** the "isn't immutability slow?" rebuttal — structural sharing makes "copies" cheap (only the changed path is rebuilt); reach for the standard immutable collections (`System.Collections.Immutable`, Vavr) rather than rolling your own.

**Verdict:** one reassurance sidebar inside Immutability. Okasaki-level theory is academic for this audience.

---

### Referential transparency / determinism — [SKIP — already in Pure functions]

Already named in the Pure functions axiom. Only thing worth surfacing there: the **testability payoff** — RT code needs no mocks; you test it by substituting values.

---

### Idempotence — [SKIP — already in State machines; payoff out of scope]

Already in the State machines axiom. Its main payoff (retry-safety) is operational → out of scope. Keep only the code-level half: "prefer set-shaped over delta-shaped actions — they survive replay," where actions live.

---

### Zero-One-Infinity rule — [SKIP — one-liner]

No arbitrary fixed limits in your types — allow 0, exactly 1, or many. Memorable but narrow; a one-line aside in domain-modelling at most.

**Source:** van der Poel / MacLennan.

---

### Composition over inheritance — [SKIP / off-register]

**What:** reuse by holding collaborators (delegation) rather than extending base classes.

**Verdict:** foundational but OO-classical and against this book's FP-leaning register. If used at all, recast in this book's idiom (functions/values + explicit delegation) and present inheritance as a trade-off point — never an attack (per CLAUDE.md).

**Source:** Gang of Four, *Design Patterns* (1994).

---
