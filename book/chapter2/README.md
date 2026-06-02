# Chapter 2 — Fundamentals

This chapter introduces all foundational axioms that will shape the rest of the playbook.

The axioms are sequenced so each one rests only on axioms already introduced. Read top to bottom, since the list forms a narrative spine.

The code examples they provide are for educational purposes and are not final, production-ready, comprehensive implementations.

## Table of Contents

- [0. Data vs Behaviour](#0-data-vs-behaviour)
- [1. Immutability](#1-immutability)
- [2. Side effects](#2-side-effects)
- [3. Impure functions](#3-impure-functions)
- [4. Pure functions](#4-pure-functions)
- [5. Honest, total signatures](#5-honest-total-signatures)
- [6. Cohesion](#6-cohesion)
- [7. Connascence](#7-connascence)
- [8. First-class functions](#8-first-class-functions)
- [9. Higher-order functions](#9-higher-order-functions)
- [10. Pattern matching](#10-pattern-matching)
- [11. Impureheim](#11-impureheim)
- [12. Maybe](#12-maybe)
- [13. Either](#13-either)
- [14. Unit](#14-unit)
- [15. Result](#15-result)
- [16. Result combinators](#16-result-combinators)
- [17. Value objects](#17-value-objects)
- [18. Railway](#18-railway)
- [19. Validation](#19-validation)
- [20. Discriminated unions](#20-discriminated-unions)
- [21. Make illegal states unrepresentable](#21-make-illegal-states-unrepresentable)
- [22. Pure functions returning actions](#22-pure-functions-returning-actions)
- [23. State machines](#23-state-machines)
- [24. Session Context](#24-session-context)
- [25. Stateful Shell](#25-stateful-shell)
- [26. Typestate](#26-typestate)

## The axioms

### 0. [Data vs Behaviour](axiom-00-data-vs-behaviour.md)

Data is a fact; behaviour is an operation. We keep the two separate.

*↳ The founding premise. Once data is a fact rather than an object that owns and mutates its own state, the first thing you want from a fact is that it stays put.*

### 1. [Immutability](axiom-01-immutability.md)

Data that can't change after creation.

*↳ Removes one whole class of bug (mutating state); the other source is code that reaches outside itself — so next we name that.*

### 2. [Side effects](axiom-02-side-effects.md)

Interactions with the outside world.

*↳ Once you can spot an effect, you can label the functions that contain them.*

### 3. [Impure functions](axiom-03-impure-functions.md)

Functions carrying side effects; unpredictable output.

*↳ And only now, with impurity named, can we define its opposite.*

### 4. [Pure functions](axiom-04-pure-functions.md)

No effects; same input, same output.

*↳ Purity closes the back door — no hidden inputs or outputs through effects. The front door can still lie, though: silently undefined on some inputs, or smuggling outcomes through nulls and sentinels.*

### 5. [Honest, total signatures](axiom-05-honest-total-signatures.md)

Every outcome named in the return type; defined for every input the types admit.

*↳ Honesty fixes what the signature says about its outcomes; it does not stop the function from promising too many at once. A signature can tell the whole truth and still weld two jobs together — so the companion criterion is that the function has only one.*

### 6. [Cohesion](axiom-06-cohesion.md)

One function, one reason to change: one input shape, one decision, one output shape. Group and split code by reason-to-change, not by surface similarity.

*↳ Cohesion measured a single unit from the inside — one reason to change. Turn the same question outward — what forces a change in one unit to ripple into another? — and you have the chapter's second lens.*

### 7. [Connascence](axiom-07-connascence.md)

A graded, named taxonomy of how two units are coupled (name, type, meaning, position, algorithm, execution order), judged on three axes: strength, degree, locality. The work is to weaken strong connascence toward weak, shrink its degree, and pull connascent units closer. The chapter's second evaluative lens — it builds nothing, but names what every weakening still to come is doing.

*↳ Pure, honest, cohesive, and weakly coupled — the criteria for well-formed code are now complete, and the rest of the chapter is the toolkit. We'll want to compose such functions, which first means treating functions as values.*

### 8. [First-class functions](axiom-08-first-class-functions.md)

Functions stored, passed, returned.

*↳ Once functions are values, functions can take and return other functions.*

### 9. [Higher-order functions](axiom-09-higher-order-functions.md)

Functions over functions.

*↳ That's the machinery the container types will need (map/flatMap are HOFs) — but before introducing them, we need a clean way to take their values apart.*

### 10. [Pattern matching](axiom-10-pattern-matching.md)

Branch on a value's shape.

*↳ With pure/impure understood, a criterion for good signatures, and a way to branch, we can now sketch the target we're building toward.*

### 11. [Impureheim](axiom-11-impureheim.md)

*(concept only)* — effects at the edges, pure logic in the middle.

*↳ The north star. That pure core is only worth having if we have good types to fill it — starting with the simplest.*

### 12. [Maybe](axiom-12-maybe.md)

Presence or absence (examples now lean on the HOFs from [9](axiom-09-higher-order-functions.md)).

*↳ Absence is one missing case; next, a value that's one of two types.*

### 13. [Either](axiom-13-either.md)

One of two types (a sealed interface + records).

*↳ Before specializing this into success/failure, we must handle operations that succeed but return nothing.*

### 14. [Unit](axiom-14-unit.md)

A type with a single value, for "nothing meaningful to return."

*↳ With Unit available for the no-value case, Result can be defined cleanly.*

### 15. [Result](axiom-15-result.md)

*(concept)* — success or failure, no exceptions.

*↳ A bare Result is clumsy; the HOFs from earlier let us transform and chain it.*

### 16. [Result combinators](axiom-16-result-combinators.md)

map / flatMap / mapError.

*↳ Chaining needs things to chain: small fallible constructors.*

### 17. [Value objects](axiom-17-value-objects.md)

*(string failures first)* — make invalid states unrepresentable; each `from` returns a Result.

*↳ A domain full of fallible constructors is exactly what we can now wire together.*

### 18. [Railway](axiom-18-railway.md)

Chain them so the first failure short-circuits.

*↳ But stopping at the first error isn't always what you want.*

### 19. [Validation](axiom-19-validation.md)

A `ValidationError` convention plus accumulate-every-error, the deliberate contrast to railway.

*↳ All of this handled two outcomes; for three or more we generalize the shape.*

### 20. [Discriminated unions](axiom-20-discriminated-unions.md)

*(3+ outcomes)* — consumed via the pattern matching from [10](axiom-10-pattern-matching.md); the reveal that Either and Result were DUs all along.

*↳ The same sum-type machinery models not just a computation's outcomes but the persistent shape of a thing across its lifecycle.*

### 21. [Make illegal states unrepresentable](axiom-21-illegal-states.md)

Model a thing that is in one of several states as a sum of per-state records, not a product of nullable fields; each field lives only on the state where it is valid. The data-shape sibling of value objects ([17](axiom-17-value-objects.md)), and the base from which the state machine ([23](axiom-23-state-machines.md)) and typestate ([26](axiom-26-typestate.md)) escalate.

*↳ That was data at rest; when the pure core decides what should *happen*, model its output the same way — as a DU of actions.*

### 22. [Pure functions returning actions](axiom-22-pure-functions-returning-actions.md)

The pure core decides, the impure shell executes (delivering the sandwich from [11](axiom-11-impureheim.md)).

*↳ Generalize "decide an action" into "decide the next state."*

### 23. [State machines](axiom-23-state-machines.md)

Centralized state, transitions as DUs, decisions as pure functions returning actions. Everything composes.

*↳ The shell was one-shot — load, decide, persist, return. Many programs aren't one-shot. Before we can describe what their longer-lived shells *do*, we need to name what they *hold*.*

### 24. [Session Context](axiom-24-session-context.md)

Per-session mutable state held by the shell: accumulators, signals, flags, callbacks. Distinct from FSM state and from globals.

*↳ With a place to keep the session's working memory, the shell shape can grow beyond one-shot — into a loop that drives the FSM forward over the whole session.*

### 25. [Stateful Shell](axiom-25-stateful-shell.md)

The long-running shell shape: read current state, dispatch the effect that state demands, await an environmental event, call `Transition`, repeat. *(Lineage: the language-runtime fetch-decode-execute *Interpreter Loop*.)*

*↳ Twenty-five axioms in, the structural toolkit is complete — entities, decisions, shells, the session-scoped state they hold, and the long-lived resources the shell carries between calls. One niche escalation closes the chapter: when the legal *order* of calls is itself part of the contract, lift each state into its own type so the wrong-order call cannot be written.*

### 26. [Typestate](axiom-26-typestate.md)

Encode call order in the type system; each state is its own type, transitions return the next type, and operations valid only in one state live only on that state's type. The narrow-use type-level counterpart to the value-level state machines from [23](axiom-23-state-machines.md).

---

*Note: most bridges are strict dependencies — the next axiom literally needs the previous one. A few are deliberately not. Connascence ([7](axiom-07-connascence.md)) is an evaluative lens set beside Cohesion: the tools that follow it do not depend on it, but it names what each of them is doing. Impureheim ([11](axiom-11-impureheim.md)) is introduced early as a "north star" to give the tool-building that follows a clear purpose, and it pays off at [22](axiom-22-pure-functions-returning-actions.md). And Typestate ([26](axiom-26-typestate.md)) is the chapter's one out-of-arc item — a niche tool placed at the end so it does not interrupt the constantly-used material that precedes it.*
