# Chapter 2 — Fundamentals

This chapter introduces the foundational axioms that shape the rest of this book.

Read them in order. Each axiom rests only on the ones before it. The *Leads to* line under each one says why the next axiom follows.

Code examples are for teaching. They are not complete, production-ready implementations.

## The axioms

### 0. [Ubiquitous Language](axiom-00-ubiquitous-language.md)

One name per concept, one concept per name. The code speaks the domain's words, everywhere.

***Leads to Data is not Behavior:*** *The names come first; the structure follows. The first thing the code decides about a named concept is what it fundamentally is, and the answer is inert data, not behavior.*

### 1. [Data is not Behavior](axiom-01-data-is-not-behavior.md)

Data is a fact; behavior is an operation. We keep the two separate. This is the founding premise.

***Leads to Immutability:*** *Once data is a fact rather than an object that owns and mutates its own state, the first thing you want from a fact is that it stays put.*

### 2. [Immutability](axiom-02-immutability.md)

Data that can't change after creation.

***Leads to Side effects:*** *Immutability removes one class of bug: state changing under you. Another comes from code that reaches outside itself, so next we name that.*

### 3. [Side effects](axiom-03-side-effects.md)

Interactions with the outside world.

***Leads to Impure functions:*** *Once you can spot an effect, you can label the functions that contain them.*

### 4. [Impure functions](axiom-04-impure-functions.md)

Functions with side effects; their output depends on more than their inputs.

***Leads to Pure functions:*** *And only now, with impurity named, can we define its opposite.*

### 5. [Pure functions](axiom-05-pure-functions.md)

No effects; same input, same output.

***Leads to Honest, total signatures:*** *Purity closes the back door: no hidden inputs or outputs through effects. The front door can still lie, though: silently undefined on some inputs, or smuggling outcomes through nulls and sentinels.*

### 6. [Honest, total signatures](axiom-06-honest-total-signatures.md)

Every outcome named in the return type; defined for every input the types admit.

***Leads to Cohesion:*** *Honesty fixes what the signature says about its outcomes. It does not stop the function from promising too many at once. A signature can tell the whole truth and still weld two jobs together, so the companion criterion is that the function has only one.*

### 7. [Cohesion](axiom-07-cohesion.md)

One function, one reason to change: one input shape, one decision, one output shape. Group and split code by reason to change, not by surface similarity.

***Leads to Connascence:*** *Cohesion measures a single unit from the inside. Turn the same question outward (what forces a change in one unit to ripple into another?) and you have the chapter's second lens.*

### 8. [Connascence](axiom-08-connascence.md)

A named, graded taxonomy of how two units are coupled, judged on strength, degree and locality. The chapter's second evaluative lens: it builds nothing, but names what every later tool is doing.

***Leads to First-class functions:*** *Pure, honest, cohesive and weakly coupled: the criteria for well-formed code are now complete, and the rest of the chapter is the toolkit. We'll want to compose such functions, which first means treating functions as values.*

### 9. [First-class functions](axiom-09-first-class-functions.md)

Functions stored, passed, returned.

***Leads to Higher-order functions:*** *Once functions are values, functions can take and return other functions.*

### 10. [Higher-order functions](axiom-10-higher-order-functions.md)

Functions over functions.

***Leads to Pattern matching:*** *Higher-order functions are the machinery the container types will need (map/flatMap are higher-order functions). But before introducing them, we need a clean way to take their values apart.*

### 11. [Pattern matching](axiom-11-pattern-matching.md)

Branch on a value's shape.

***Leads to Impureim:*** *With pure and impure understood, criteria for good functions, and a way to branch, we can now sketch the target we're building toward.*

### 12. [Impureim](axiom-12-impureim.md)

Effects at the edges, pure logic in the middle. The north star: a concept, not a construct.

***Leads to Maybe:*** *The pure core is only worth having if we have good types to fill it, starting with the simplest.*

### 13. [Maybe](axiom-13-maybe.md)

Presence or absence. The examples lean on the higher-order functions from [10](axiom-10-higher-order-functions.md).

***Leads to Either:*** *Absence is one missing case; next, a value that's one of two types.*

### 14. [Either](axiom-14-either.md)

One of two types, built from a sealed interface and records.

***Leads to Unit:*** *Before specializing this into success and failure, we must handle operations that succeed but return nothing.*

### 15. [Unit](axiom-15-unit.md)

A type with a single value, for "nothing meaningful to return."

***Leads to Result:*** *With Unit available for the no-value case, Result can be defined cleanly.*

### 16. [Result](axiom-16-result.md)

Success or failure, without exceptions.

***Leads to Result combinators:*** *A bare Result is clumsy; the higher-order functions from earlier let us transform and chain it.*

### 17. [Result combinators](axiom-17-result-combinators.md)

map / flatMap / mapError.

***Leads to Value objects:*** *Chaining needs things to chain: small fallible constructors.*

### 18. [Value objects](axiom-18-value-objects.md)

Make invalid values unrepresentable: each `parse` returns a Result, starting with plain string failures.

***Leads to Railway:*** *A domain full of fallible constructors is exactly what we can now wire together.*

### 19. [Railway](axiom-19-railway.md)

Chain them so the first failure short-circuits.

***Leads to Validation:*** *But stopping at the first error isn't always what you want.*

### 20. [Validation](axiom-20-validation.md)

A `ValidationError` convention plus collecting every error: the deliberate contrast to railway.

***Leads to Discriminated unions:*** *All of this handled two outcomes; for three or more we generalize the shape.*

### 21. [Discriminated unions](axiom-21-discriminated-unions.md)

Three or more outcomes, consumed with the pattern matching from [11](axiom-11-pattern-matching.md). Either and Result were DUs all along.

***Leads to Make illegal states unrepresentable:*** *The same machinery models not just a computation's outcomes but the persistent shape of a thing across its lifecycle.*

### 22. [Make illegal states unrepresentable](axiom-22-illegal-states.md)

Model a thing with several states as one record per state, not one record full of nullable fields. Each field lives only on the state where it is valid.

***Leads to Pure functions returning actions:*** *Illegal states unrepresentable was about data at rest. When the pure core decides what should happen, model its output the same way: as a DU of actions.*

### 23. [Pure functions returning actions](axiom-23-pure-functions-returning-actions.md)

The pure core decides, the impure shell executes. This delivers the sandwich from [12](axiom-12-impureim.md).

***Leads to State machines:*** *Generalize "decide an action" into "decide the next state."*

### 24. [State machines](axiom-24-state-machines.md)

Centralized state, transitions as DUs, decisions as pure functions returning actions. Everything composes.

***Leads to Session Context:*** *The shell so far was one-shot: load, decide, persist, return. Many programs aren't. Before we can describe what their longer-lived shells do, we need to name what they hold.*

### 25. [Session Context](axiom-25-session-context.md)

Per-session mutable state held by the shell: accumulators, signals, flags, callbacks. Distinct from state-machine state and from globals.

***Leads to Stateful Shell:*** *With a place to keep the session's working memory, the shell can grow beyond one-shot, into a loop that drives the state machine over the whole session.*

### 26. [Stateful Shell](axiom-26-stateful-shell.md)

The long-running shell: read the current state, run the effect that state demands, wait for an event, call the state machine's transition, repeat. Its lineage is the interpreter's fetch-decode-execute loop.

***Leads to Typestate:*** *With the stateful shell, the structural toolkit is complete. One niche escalation closes the chapter: when the legal order of calls is part of the contract, give each state its own type so a wrong-order call cannot be written.*

### 27. [Typestate](axiom-27-typestate.md)

Encode call order in the type system: each state is its own type, and each transition returns the next one. The narrow, type-level counterpart to the state machines of [24](axiom-24-state-machines.md).

---

## Where the order bends

Most *Leads to* lines are strict dependencies: the next axiom needs the previous one. Four axioms are deliberately placed out of that order:

- **Ubiquitous Language ([0](axiom-00-ubiquitous-language.md))** opens the chapter because it is the discipline the rest enforce. Nothing structurally depends on it, but every type, signature and case that follows is where one of the domain's names ends up in the code.
- **Connascence ([8](axiom-08-connascence.md))** is an evaluative lens set beside Cohesion. The tools after it do not depend on it, but it names what each of them is doing.
- **Impureim ([12](axiom-12-impureim.md))** comes early as the north star, so the tool-building that follows has a clear purpose. It is delivered in [23](axiom-23-pure-functions-returning-actions.md).
- **Typestate ([27](axiom-27-typestate.md))** is the one item outside the arc. It is a niche tool, placed last so it does not interrupt the everyday material before it.

---

← Previous: [Chapter 1](../chapter1/README.md) · Start: [Axiom 0 — Ubiquitous Language](axiom-00-ubiquitous-language.md) →
