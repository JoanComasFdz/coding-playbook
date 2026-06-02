# Chapter 2 — Fundamentals

This chapter introduces all foundational axioms that will shape the rest of the playbook.

The axioms are sequenced so each one rests only on axioms already introduced. Read top to bottom, since the list forms a narrative spine.

The code examples they provide are for educational purposes and are not final, production-ready, comprehensive implementations.

## Table of Contents

- [0. Ubiquitous Language](#0-ubiquitous-language)
- [1. Data vs Behaviour](#1-data-vs-behaviour)
- [2. Immutability](#2-immutability)
- [3. Side effects](#3-side-effects)
- [4. Impure functions](#4-impure-functions)
- [5. Pure functions](#5-pure-functions)
- [6. Honest, total signatures](#6-honest-total-signatures)
- [7. Cohesion](#7-cohesion)
- [8. Connascence](#8-connascence)
- [9. First-class functions](#9-first-class-functions)
- [10. Higher-order functions](#10-higher-order-functions)
- [11. Pattern matching](#11-pattern-matching)
- [12. Impureheim](#12-impureheim)
- [13. Maybe](#13-maybe)
- [14. Either](#14-either)
- [15. Unit](#15-unit)
- [16. Result](#16-result)
- [17. Result combinators](#17-result-combinators)
- [18. Value objects](#18-value-objects)
- [19. Railway](#19-railway)
- [20. Validation](#20-validation)
- [21. Discriminated unions](#21-discriminated-unions)
- [22. Make illegal states unrepresentable](#22-make-illegal-states-unrepresentable)
- [23. Pure functions returning actions](#23-pure-functions-returning-actions)
- [24. State machines](#24-state-machines)
- [25. Session Context](#25-session-context)
- [26. Stateful Shell](#26-stateful-shell)
- [27. Typestate](#27-typestate)

## The axioms

### 0. [Ubiquitous Language](axiom-00-ubiquitous-language.md)

One name per concept, one concept per name — the code speaks the domain's words, everywhere.

*↳ The names come first; the structure follows. The first thing the code decides about a named concept is what it fundamentally is — and the answer is inert data, not behaviour.*

### 1. [Data vs Behaviour](axiom-01-data-vs-behaviour.md)

Data is a fact; behaviour is an operation. We keep the two separate.

*↳ The founding premise. Once data is a fact rather than an object that owns and mutates its own state, the first thing you want from a fact is that it stays put.*

### 2. [Immutability](axiom-02-immutability.md)

Data that can't change after creation.

*↳ Removes one whole class of bug (mutating state); the other source is code that reaches outside itself — so next we name that.*

### 3. [Side effects](axiom-03-side-effects.md)

Interactions with the outside world.

*↳ Once you can spot an effect, you can label the functions that contain them.*

### 4. [Impure functions](axiom-04-impure-functions.md)

Functions carrying side effects; unpredictable output.

*↳ And only now, with impurity named, can we define its opposite.*

### 5. [Pure functions](axiom-05-pure-functions.md)

No effects; same input, same output.

*↳ Purity closes the back door — no hidden inputs or outputs through effects. The front door can still lie, though: silently undefined on some inputs, or smuggling outcomes through nulls and sentinels.*

### 6. [Honest, total signatures](axiom-06-honest-total-signatures.md)

Every outcome named in the return type; defined for every input the types admit.

*↳ Honesty fixes what the signature says about its outcomes; it does not stop the function from promising too many at once. A signature can tell the whole truth and still weld two jobs together — so the companion criterion is that the function has only one.*

### 7. [Cohesion](axiom-07-cohesion.md)

One function, one reason to change: one input shape, one decision, one output shape. Group and split code by reason-to-change, not by surface similarity.

*↳ Cohesion measured a single unit from the inside — one reason to change. Turn the same question outward — what forces a change in one unit to ripple into another? — and you have the chapter's second lens.*

### 8. [Connascence](axiom-08-connascence.md)

A graded, named taxonomy of how two units are coupled (name, type, meaning, position, algorithm, execution order), judged on three axes: strength, degree, locality. The work is to weaken strong connascence toward weak, shrink its degree, and pull connascent units closer. The chapter's second evaluative lens — it builds nothing, but names what every weakening still to come is doing.

*↳ Pure, honest, cohesive, and weakly coupled — the criteria for well-formed code are now complete, and the rest of the chapter is the toolkit. We'll want to compose such functions, which first means treating functions as values.*

### 9. [First-class functions](axiom-09-first-class-functions.md)

Functions stored, passed, returned.

*↳ Once functions are values, functions can take and return other functions.*

### 10. [Higher-order functions](axiom-10-higher-order-functions.md)

Functions over functions.

*↳ That's the machinery the container types will need (map/flatMap are HOFs) — but before introducing them, we need a clean way to take their values apart.*

### 11. [Pattern matching](axiom-11-pattern-matching.md)

Branch on a value's shape.

*↳ With pure/impure understood, a criterion for good signatures, and a way to branch, we can now sketch the target we're building toward.*

### 12. [Impureheim](axiom-12-impureheim.md)

*(concept only)* — effects at the edges, pure logic in the middle.

*↳ The north star. That pure core is only worth having if we have good types to fill it — starting with the simplest.*

### 13. [Maybe](axiom-13-maybe.md)

Presence or absence (examples now lean on the HOFs from [10](axiom-10-higher-order-functions.md)).

*↳ Absence is one missing case; next, a value that's one of two types.*

### 14. [Either](axiom-14-either.md)

One of two types (a sealed interface + records).

*↳ Before specializing this into success/failure, we must handle operations that succeed but return nothing.*

### 15. [Unit](axiom-15-unit.md)

A type with a single value, for "nothing meaningful to return."

*↳ With Unit available for the no-value case, Result can be defined cleanly.*

### 16. [Result](axiom-16-result.md)

*(concept)* — success or failure, no exceptions.

*↳ A bare Result is clumsy; the HOFs from earlier let us transform and chain it.*

### 17. [Result combinators](axiom-17-result-combinators.md)

map / flatMap / mapError.

*↳ Chaining needs things to chain: small fallible constructors.*

### 18. [Value objects](axiom-18-value-objects.md)

*(string failures first)* — make invalid states unrepresentable; each `from` returns a Result.

*↳ A domain full of fallible constructors is exactly what we can now wire together.*

### 19. [Railway](axiom-19-railway.md)

Chain them so the first failure short-circuits.

*↳ But stopping at the first error isn't always what you want.*

### 20. [Validation](axiom-20-validation.md)

A `ValidationError` convention plus accumulate-every-error, the deliberate contrast to railway.

*↳ All of this handled two outcomes; for three or more we generalize the shape.*

### 21. [Discriminated unions](axiom-21-discriminated-unions.md)

*(3+ outcomes)* — consumed via the pattern matching from [11](axiom-11-pattern-matching.md); the reveal that Either and Result were DUs all along.

*↳ The same sum-type machinery models not just a computation's outcomes but the persistent shape of a thing across its lifecycle.*

### 22. [Make illegal states unrepresentable](axiom-22-illegal-states.md)

Model a thing that is in one of several states as a sum of per-state records, not a product of nullable fields; each field lives only on the state where it is valid. The data-shape sibling of value objects ([18](axiom-18-value-objects.md)), and the base from which the state machine ([24](axiom-24-state-machines.md)) and typestate ([27](axiom-27-typestate.md)) escalate.

*↳ That was data at rest; when the pure core decides what should *happen*, model its output the same way — as a DU of actions.*

### 23. [Pure functions returning actions](axiom-23-pure-functions-returning-actions.md)

The pure core decides, the impure shell executes (delivering the sandwich from [12](axiom-12-impureheim.md)).

*↳ Generalize "decide an action" into "decide the next state."*

### 24. [State machines](axiom-24-state-machines.md)

Centralized state, transitions as DUs, decisions as pure functions returning actions. Everything composes.

*↳ The shell was one-shot — load, decide, persist, return. Many programs aren't one-shot. Before we can describe what their longer-lived shells *do*, we need to name what they *hold*.*

### 25. [Session Context](axiom-25-session-context.md)

Per-session mutable state held by the shell: accumulators, signals, flags, callbacks. Distinct from FSM state and from globals.

*↳ With a place to keep the session's working memory, the shell shape can grow beyond one-shot — into a loop that drives the FSM forward over the whole session.*

### 26. [Stateful Shell](axiom-26-stateful-shell.md)

The long-running shell shape: read current state, dispatch the effect that state demands, await an environmental event, call `Transition`, repeat. *(Lineage: the language-runtime fetch-decode-execute *Interpreter Loop*.)*

*↳ Twenty-six axioms in, the structural toolkit is complete — entities, decisions, shells, the session-scoped state they hold, and the long-lived resources the shell carries between calls. One niche escalation closes the chapter: when the legal *order* of calls is itself part of the contract, lift each state into its own type so the wrong-order call cannot be written.*

### 27. [Typestate](axiom-27-typestate.md)

Encode call order in the type system; each state is its own type, transitions return the next type, and operations valid only in one state live only on that state's type. The narrow-use type-level counterpart to the value-level state machines from [24](axiom-24-state-machines.md).

---

*Note: most bridges are strict dependencies — the next axiom literally needs the previous one. A few are deliberately not. Ubiquitous Language ([0](axiom-00-ubiquitous-language.md)) opens the chapter not because the next axiom needs it, but because it is the discipline the rest enforce: nothing structurally depends on it, yet every type, signature, and case that follows is where one of the domain's names gets compiled in. Connascence ([8](axiom-08-connascence.md)) is an evaluative lens set beside Cohesion: the tools that follow it do not depend on it, but it names what each of them is doing. Impureheim ([12](axiom-12-impureheim.md)) is introduced early as a "north star" to give the tool-building that follows a clear purpose, and it pays off at [23](axiom-23-pure-functions-returning-actions.md). And Typestate ([27](axiom-27-typestate.md)) is the chapter's one out-of-arc item — a niche tool placed at the end so it does not interrupt the constantly-used material that precedes it.*

---

← Previous: [Chapter 1](../chapter1/README.md) · Start: [Axiom 0 — Ubiquitous Language](axiom-00-ubiquitous-language.md) →
