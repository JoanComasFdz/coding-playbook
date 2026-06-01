# Concept Registry

*Every coding concept I've considered — and where it landed, or why it didn't.*

Joan Comas, Senior Software Architect — since June 2024

**Status legend:** ✅ **Axiomatized** (became its own axiom) · 🔁 **Folded** (absorbed into an existing axiom) · ❌ **Discarded** (too niche / out of scope) · 🔍 **Open** (not yet decided — any `[TAG]` is the *recommended* disposition, not a decision yet)

---

## Immutability

✅ **Axiomatized** → [Axiom 1 — Immutability](chapter1/axiom-01-immutability.md)

---

## Maybe

✅ **Axiomatized** → [Axiom 12 — Maybe](chapter1/axiom-12-maybe.md)

---

## Either

✅ **Axiomatized** → [Axiom 13 — Either](chapter1/axiom-13-either.md)

---

## Result pattern

✅ **Axiomatized** → [Axiom 15 — Result](chapter1/axiom-15-result.md)

---

## Discriminated unions

✅ **Axiomatized** → [Axiom 20 — Discriminated unions](chapter1/axiom-20-discriminated-unions.md)

---

## Pattern matching

✅ **Axiomatized** → [Axiom 10 — Pattern matching](chapter1/axiom-10-pattern-matching.md)

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

✅ **Axiomatized** → [Axiom 8 — First-class functions](chapter1/axiom-08-first-class-functions.md)

---

## Higher-order functions

✅ **Axiomatized** → [Axiom 9 — Higher-order functions](chapter1/axiom-09-higher-order-functions.md)

---

## Impureheim: the impure–pure–impure sandwich

✅ **Axiomatized** → [Axiom 11 — Impureheim](chapter1/axiom-11-impureheim.md)

---

## Value Objects

✅ **Axiomatized** → [Axiom 17 — Value objects](chapter1/axiom-17-value-objects.md)

---

## State Machines

✅ **Axiomatized** → [Axiom 23 — State machines](chapter1/axiom-23-state-machines.md)

---

## Pure functions return actions

✅ **Axiomatized** → [Axiom 22 — Pure functions returning actions](chapter1/axiom-22-pure-functions-returning-actions.md)

---

## Session Context

✅ **Axiomatized** → [Axiom 24 — Session Context](chapter1/axiom-24-session-context.md)

---

## Stateful Shell

✅ **Axiomatized** → [Axiom 25 — Stateful Shell](chapter1/axiom-25-stateful-shell.md)

---

## Encode ordering in types (temporal coupling)

✅ **Axiomatized** → [Axiom 26 — Typestate](chapter1/axiom-26-typestate.md)

---

## Connascence

✅ **Axiomatized** → [Axiom 7 — Connascence](chapter1/axiom-07-connascence.md)

The chapter's second evaluative lens, set beside Cohesion. This resolves the top-pick open candidate in the research sweep below: connascence landed as an inline lens-axiom at position 7, not a separate framing chapter. Its taxonomy keeps Page-Jones's static/dynamic split, but the cut the playbook optimises against is *compiler-enforced vs. convention-carried*; the contested Position-vs-Algorithm strength ordering is flagged rather than asserted.

---

## Closures

🔁 **Folded** → [Axiom 8 — First-class functions](chapter1/axiom-08-first-class-functions.md) (Why #3, "Closures carry state along with the function").

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

## CQRS [ARCHITECTURE - OUT OF SCOPE]

🔍 **Open** — record the boundary only.

Note (from research): CQRS is system topology = **out of scope** (it's a *consumer* of the building blocks, not one). Its code-level sibling is **CQS** (see the Command–Query Separation entry in the research sweep below) — a method returns a value *xor* changes state — and that one is now folded into [Axiom 11 — Impureheim](chapter1/axiom-11-impureheim.md) (and named in [Axiom 4](chapter1/axiom-04-pure-functions.md) and [Axiom 22](chapter1/axiom-22-pure-functions-returning-actions.md)). Keep this section only to *record the boundary*, not to write an axiom.

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

### Connascence (Meilir Page-Jones) — [✅ AXIOMATIZED → [Axiom 7](chapter1/axiom-07-connascence.md)]

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

### Boolean blindness (Licata / Harper; De Goes) — [🔁 FOLDED → coined in [Axiom 5](chapter1/axiom-05-honest-total-signatures.md); named across 6, 17, 20]

---

### Algebraic Data Types — the umbrella + state-counting — [🔁 FOLDED → [Axiom 21](chapter1/axiom-21-illegal-states.md); named in [1](chapter1/axiom-01-immutability.md) & [20](chapter1/axiom-20-discriminated-unions.md)]

---

### Design by Contract (Meyer) — [🔁 FOLDED → [Axiom 17](chapter1/axiom-17-value-objects.md); postconditions via [5](chapter1/axiom-05-honest-total-signatures.md), preconditions-as-sequence via [26](chapter1/axiom-26-typestate.md)]

---

### Fail-fast on bugs vs. return-values for expected failures — [🔁 FOLDED → [Axiom 15](chapter1/axiom-15-result.md)]

The distinction was already explicit in Axiom 15 (the "what counts as an error?" heuristics and the When-NOT-to exception bullets); this fold only added the *fail-fast* name and the offensive-programming lineage.

**`assert` half deferred — not for now.** The dev-time `assert` / `Debug.Assert` mechanism for catching contract violations at their source was deliberately left out: in practice I've never reached for it or seen it used. Revisit only if it earns its keep.

**Source:** James Shore, *Fail Fast* (IEEE Software, 2004); offensive programming (lore).

---

### DRY — the real (knowledge) definition — [🔁 FOLDED → [Axiom 6](chapter1/axiom-06-cohesion.md)]

Axiom 6 already corrected the *misreading* (dedupe-on-sight) via reason-to-change; this fold added the missing half — naming DRY's original *knowledge, not code text* definition (Hunt & Thomas) and connecting it to reason-to-change as that rule made operational.

---

### SLAP — single level of abstraction per function — [🔁 FOLDED → [Axiom 6](chapter1/axiom-06-cohesion.md)]

SLAP bundles two claims the chapter already states more sharply, plus one residue it declines. Its "each function does one job" half *is* [Cohesion](chapter1/axiom-06-cohesion.md) — and the principle's own canonical reference (Principles Wiki) falls back on cohesion to explain when SLAP goes wrong. Its "read the body as a paragraph of same-level steps" half is a *byproduct* of [Impureheim](chapter1/axiom-11-impureheim.md)'s gather→decide→act step-down, not a separate law. The only standalone residue — "match every statement to one altitude" — rests on a "level of abstraction" that is **nowhere defined**, not even by the principle's own references; it is precisely the undefined vibe-metric the playbook replaces with checkable ones (reason-to-change, honest signatures). Applied mechanically it produces *extract-till-you-drop*: a swarm of one-line helpers the reader must mentally re-inline — the "mental inlining" failure already guarded by [Axiom 6](chapter1/axiom-06-cohesion.md)'s locality bullet, and the deep-vs-shallow-modules tension logged above in this sweep.

This fold added a one-line reading-smell kernel to Axiom 6's *When NOT to*: a body that forces mental inlining wants a named extraction — extract when the detail is a concept with its own reason to change, not to hit an altitude quota.

**Lineage:** Kent Beck's *Composed Method* (*Smalltalk Best Practice Patterns*, 1997) is the root; the acronym SLAP is credited to Glenn Vanderburg and popularized by Neal Ford, *The Productive Programmer* (2008, ch. 13 "Composed Method and SLAP"); Robert C. Martin restated it as the *Stepdown Rule* in *Clean Code* (2009). Over-application critiqued by John Ousterhout, *A Philosophy of Software Design* (2018, deep vs. shallow modules), and the Christin Gorman vs. Robert C. Martin "extract till you drop" debate.

---

### Lenses / optics — [CONTRAST / restrained]

**What:** the nested-immutable-update tax; composable getter+setter bundles (lens=field, prism=case, traversal=many).

**Verdict:** cover the *pain* + the cheap built-in answer (`with` / withers) inside Immutability; name optics only as the *deep-nesting escape hatch*, parked in "what might change tomorrow" (JDK 25 / JEP 468 shifts the calculus). A full optic library isn't recommended for mainstream C#/Java today.

**Source:** Kmett `lens`; Scott Logic "The Immutability Gap" series.

---

### Postel's Law vs. parse-don't-validate (the tension) — [🔁 FOLDED → [Axiom 17](chapter1/axiom-17-value-objects.md), "Postel's Law, reconciled" aside in the *Why*]

The two only *look* opposed. Postel's *Robustness Principle* — *"be conservative in what you do, be liberal in what you accept"* (RFC 760, 1980) — governs **surface form**; parse-don't-validate governs **meaning** crossing the boundary. The synthesis is *lenient lexer, strict parser*: a smart constructor may be generous about the forms it accepts but must emit exactly one canonical value or a `Failure`, with the leniency confined to that step. Far from a rival, the smart constructor is the **cure** for Postel's harmful form — the IETF itself has since recanted the principle (Thomson & Schinazi, *Maintaining Robust Protocols*, RFC 9413, 2023), because liberal acceptance *without* normalisation is exactly the spec-drift / ossification a boundary parse prevents.

**Source:** RFC 760 / RFC 793 (Postel); RFC 9413 (Thomson & Schinazi, 2023); Alexis King, *Parse, Don't Validate* (2019).

---

### Command–Query Separation (CQS) — [🔁 FOLDED → [Axiom 11](chapter1/axiom-11-impureheim.md); query half named in [Axiom 4](chapter1/axiom-04-pure-functions.md), command half in [Axiom 22](chapter1/axiom-22-pure-functions-returning-actions.md)]

**What:** a method returns a value (query) *xor* changes state (command), never both. The OO ancestor of the pure/impure split; purity is strictly stronger (a CQS "query" may still read mutable globals).

**What the fold added.** CQS was covered but unnamed — out of step with how the other famous-but-covered principles landed (DRY, SLAP, Design by Contract all got named at their landing spot). This fold names it in three places, each at a distinct angle: [Axiom 11](chapter1/axiom-11-impureheim.md) is the primary home — Impureheim *is* CQS promoted from the method to the unit of work (gather = query, act = command, the seam a layer boundary rather than a naming convention), with Meyer added as reference [3] there. [Axiom 4](chapter1/axiom-04-pure-functions.md) carries the query half: purity outruns it, forbidding the *read* of mutable state that a CQS query still permits. [Axiom 22](chapter1/axiom-22-pure-functions-returning-actions.md) carries the command half: the would-be command splits into a pure `Decide` (returns a value) and an impure execute (returns nothing).

**CQRS stays out of the axioms.** Only the registry records the CQS (code) vs CQRS (architecture, out of scope) distinction — see the [CQRS](#cqrs) section. No axiom mentions CQRS.

**Source:** Bertrand Meyer, *Object-Oriented Software Construction* (2nd ed., 1997).

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

**Verdict:** historical bedrock, subsumed by connascence's finer grain. Cited in [Axiom 7 — Connascence](chapter1/axiom-07-connascence.md) (Structured Design = ref [5]).

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
