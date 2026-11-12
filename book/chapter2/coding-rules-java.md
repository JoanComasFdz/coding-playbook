# Coding rules for Java

The axioms of [Coding Playbook, Chapter 2](https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/README.md), condensed into rules for Java. Each rule assumes you know the concept; the link after it is the why. The same rules for C#: [Coding rules for C#](https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/coding-rules-csharp.md).

These are **requirements, not suggestions**. Copy this file into a repository to adopt the axioms as its baseline. Keep it as is, and add project-specific rules in a separate file.

The first five sections can be checked by reading the code. The last one can't, so it has to be weighed and applied.

## Data

- **Data is immutable records.** No setters, immutable collections all the way down; a change is a new value (a `withStatus(…)` method that returns a new record). ([Axiom 3][A3])
- **Business logic never mixes data and behavior.** Records hold data, functions hold behavior. Only code a framework shapes at the boundary mixes them: controllers, event subscriptions, background workers, UI handlers, ORM entities, DTOs. ([Axiom 2][A2])
- **Name data with nouns, functions with verbs.** `Cart`, `calculateTotal`, never `total`. `is`/`has`/`can` predicates and `toX`/`fromX` conversions count as verbs. Exceptions: names a language or framework gives you (`hashCode()`), and DSLs (`from`, `where`, `given`). ([Axiom 2][A2])
- **A primitive with rules is a value object, parsed where it enters.** A private constructor and a `parse` that returns a `Result`. Code past the boundary takes the value object and never validates again. ([Axiom 19][A19])
- **A value object is a `final class`, never a record.** A record's constructor can't be private; write `equals` and `hashCode` by hand. ([Axiom 19][A19])
- **Cases with different data are a discriminated union.** A `sealed interface` parent, one `record` per case, each with only its own fields. Never a status enum plus nullable fields. Constants without data stay an `enum`. ([Axiom 22][A22], [Axiom 23][A23])

## Pure functions

- **A pure function is `static`, in a `final class` of `static` methods that acts as a module,** or a method on an immutable record. Never an instance method on a class with mutable fields or injected services. ([Axiom 6][A6])
- **It reads only its parameters.** No clock, randomness, static field, global, ambient context or service locator. ([Axiom 1][A1], [Axiom 4][A4])
- **It acts only through its return value.** No I/O, logging, changed parameters, or exceptions for expected outcomes. ([Axiom 4][A4], [Axiom 5][A5])
- **Every outcome is in the return type.** Absence is `Optional<T>`, failure is `Result<T, E>`, and nothing to return but the result flows on is `Result<Unit, E>`. No `null` for absence, no sentinel values. ([Axiom 7][A7], [Axiom 14][A14], [Axiom 16][A16], [Axiom 17][A17])
- **No `boolean` or enum parameter that switches the body.** Write two functions. ([Axiom 8][A8])
- **Behavior passed in is a function.** A `Function`, `Supplier` or `Consumer` parameter, not a one-method interface or a strategy class. ([Axiom 10][A10], [Axiom 11][A11])
- **Collections are transformed, not looped over.** `map`, `filter`, `reduce` on a stream; no mutable accumulators. ([Axiom 11][A11])

## Matching

- **A `switch` over a sealed type has no `default`.** The compiler checks every case; a `default` would hide a new one. A `default` stays only over a type that was never closed (`Object`), or where it is a real branch. ([Axiom 12][A12m])
- **`match` when every branch returns a value, `handle` when every branch only acts.** ([Axiom 12][A12h])
- **A pure call gets its own line, into a named value.** `var decision = decide(…);` on one line, the match or the impure call on the next. Never `switch (decide(…))`, never `save(decide(…))`. ([Axiom 12][A12c])

## Failures

- **Expected failures are returned, unexpected ones are thrown.** A failure that is a normal outcome is a `Result`; a bug or a broken invariant throws. Where you wrap an API that throws, catch its expected exceptions there, once, and return them as a `Result`. ([Axiom 17][A17l])
- **`Result`s are composed, not checked.** `map`, `flatMap` and `mapError`, never nested `if (result instanceof Success)`. Steps that can fail form a railway: the first failure skips the rest. ([Axiom 18][A18], [Axiom 20][A20])
- **Independent validation errors are accumulated** with `combine`, not stopped at the first. ([Axiom 21][A21])

## Core and shell

- **A unit of work is rounds of gather, decide, act.** Impure reads, then pure calls, then impure writes, with no effect between the pure calls. When a read depends on a decision, run another round. ([Axiom 13][A13])
- **The framework shapes the shell's entry points; these rules shape what runs inside them.** The shell is ordinary object-oriented code: classes, constructor injection, and state where state is needed. ([Axiom 13][A13])
- **A decision about what should happen returns an action union;** the shell carries it out. ([Axiom 24][A24])
- **A lifecycle with more than two states is a finite state machine:** a pure `transition(state, command)` returning the event. A repeated command returns `NoChange`, not an error. ([Axiom 25][A25])
- **A long-running process is a loop around `transition`:** read the state, carry out its effect, wait for the event, transition, repeat. ([Axiom 27][A27])
- **A session's working memory is a context object, passed explicitly.** Owned by the shell, never seen by the core, never static, ambient or `ThreadLocal`. ([Axiom 26][A26])

## Judgment calls

These can't be checked from the code alone. Whoever writes the code, a person or an agent, weighs them and applies them.

- **One name per domain concept,** taken from the domain and used unchanged in code, tests and conversation. ([Axiom 0][A0])
- **One reason to change per function.** ([Axiom 8][A8])
- **Share only pure business rules, from the third repetition.** Orchestration may repeat. ([Axiom 8][A8])
- **Prefer what the compiler checks** over meanings, positions and call order that only a convention carries. ([Axiom 9][A9])
- **Eliminate an error before you return it.** If a narrower type can make it impossible, it isn't an outcome. ([Axiom 17][A17l])
- **An error is a `String` until a caller branches on it.** Then it gets a named case. ([Axiom 19][A19])
- **Use typestate only when a wrong call order does real harm.** ([Axiom 28][A28])
- **Hide only a decision likely to change,** behind a small surface in domain words. Never hide inputs, effects or failures. ([Axiom 1][A1])

[A0]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-00-ubiquitous-language.md
[A1]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-01-explicit-over-implicit.md
[A2]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-02-data-is-not-behavior.md
[A3]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-03-immutability.md
[A4]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-04-side-effects.md
[A5]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-05-impure-functions.md
[A6]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-06-pure-functions.md
[A7]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-07-honest-total-signatures.md
[A8]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-08-cohesion.md
[A9]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-09-connascence.md
[A10]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-10-first-class-functions.md
[A11]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-11-higher-order-functions.md
[A12c]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-12-pattern-matching.md#convention-match-on-a-named-value-never-on-an-inline-call
[A12m]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-12-pattern-matching.md#switch-or-match
[A12h]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-12-pattern-matching.md#when-the-branches-only-act-handle
[A13]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-13-impureim.md
[A14]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-14-maybe.md
[A16]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-16-unit.md
[A17]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-17-result.md
[A17l]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-17-result.md#the-ladder-eliminate-then-return-then-fail-fast
[A18]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-18-result-combinators.md
[A19]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-19-value-objects.md
[A20]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-20-railway.md
[A21]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-21-validation.md
[A22]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-22-discriminated-unions.md
[A23]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-23-illegal-states.md
[A24]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-24-pure-functions-returning-actions.md
[A25]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-25-state-machines.md
[A26]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-26-session-context.md
[A27]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-27-stateful-shell.md
[A28]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-28-typestate.md

---

← [Chapter 2 Contents](https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/README.md)
