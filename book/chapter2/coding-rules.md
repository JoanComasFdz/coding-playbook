# Coding rules

The axioms of [Coding Playbook, Chapter 2](https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/README.md), condensed into rules. Each rule assumes you know the concept; the link after it is the why. Examples are C# and Java.

Copy this file into a repository to adopt the axioms as its baseline. Keep it as is, and add project-specific rules in a separate file.


## Naming

- **One name per domain concept.** Take it from the domain and use it unchanged in types, functions, tests and conversation. No synonyms, no homonyms. ([Axiom 0][A0])
- **Data is named with nouns, behavior with verbs.** Types, records and fields are nouns (`Cart`); every function name contains a verb (`CalculateTotal`, never `Total`). Exceptions: members a language or framework names for you (`ToString()`, `hashCode()`), and DSLs, which follow the language they imitate (`From`, `Where`, `Given`). ([Axiom 2][A2])

## Data

- **Data is a record, behavior is a function.** No logic in methods on mutable objects. ([Axiom 2][A2])
- **All data is immutable.** Records with no setters, immutable collections, all the way down. A change is a new value (`with`). ([Axiom 3][A3])
- **Wrap a primitive that has rules in a value object.** A non-public constructor and a `Parse` factory that returns a `Result`; once built, the value is valid. ([Axiom 19][A19])
- **Parse at the boundary, never validate inside.** Raw input becomes value objects where it enters; the core only sees valid values. ([Axiom 19][A19])
- **Three or more outcomes with different data are a discriminated union.** A sealed parent, one record per case, each with only its own fields. Data-less constants stay an `enum`. ([Axiom 22][A22])
- **Make illegal states unrepresentable.** No status enum plus nullable fields; each case carries exactly what it needs. ([Axiom 23][A23])

## Functions

- **Everything a function needs and does is in its signature.** No hidden inputs: no clock, static, global, ambient context or service locator. ([Axiom 1][A1])
- **Know the side effects.** Clock, randomness, I/O, logging, changing a parameter and throwing are all effects; a function with any of them is impure. ([Axiom 4][A4], [Axiom 5][A5])
- **Pure functions are `static`, grouped in static classes that act as modules.** A method on an immutable record is also fine. Never an instance method on a class with mutable fields or injected services. ([Axiom 6][A6], [Axiom 2][A2])
- **Every outcome is in the return type.** No `null` for absence, no sentinel values, no `out` parameters, no exceptions for expected outcomes. ([Axiom 7][A7])
- **Every function is total.** Narrow the input type or widen the output type until no input is an error. ([Axiom 7][A7])
- **One reason to change per function.** No `bool` or enum parameter that switches the body. ([Axiom 8][A8])
- **Share only pure business rules, and only from the third repetition.** Orchestration may repeat. ([Axiom 8][A8])
- **Prefer what the compiler checks over what convention carries.** Names and types over meanings, positions and call order. ([Axiom 9][A9])
- **Pass behavior as a function.** A `Func`/`Function` parameter instead of a one-method interface or a strategy class. ([Axiom 10][A10], [Axiom 11][A11])
- **Use `Select`/`map`, `Where`/`filter`, `Aggregate`/`reduce`** instead of loops with mutable accumulators. ([Axiom 11][A11])

## Matching

- **Pattern-match exhaustively over closed sets.** In C#, a `switch` over an abstract-record hierarchy ends with `_ => throw new UnreachableException()`; Java's sealed `switch` needs none. ([Axiom 12][A12])
- **Match on a named value, never on an inline call.** `var decision = Decide(…); switch (decision) { … }`. ([Axiom 12][A12c])
- **`Match` when every branch produces a value, `Handle` when every branch only acts.** ([Axiom 12][A12h])

## Outcomes

- **Absence is in the type.** `T?` with nullable reference types on (C#), `Optional<T>` (Java). ([Axiom 14][A14])
- **Success or failure is a `Result<T, E>`.** Use `Unit` as `T` when there is nothing to return but the result flows on. ([Axiom 16][A16], [Axiom 17][A17])
- **Eliminate the error, then return it, then fail fast.** Design it away if you can; return it as a value if it is an expected outcome; throw only for bugs and broken invariants. ([Axiom 17][A17l])
- **Compose `Result`s with `Map`, `Bind` and `MapError`,** never with nested `if` checks. ([Axiom 18][A18])
- **Chain steps that can fail into a railway.** The first failure short-circuits the rest. ([Axiom 20][A20])
- **Accumulate independent validation errors** with `Combine`, instead of stopping at the first. ([Axiom 21][A21])

## Core and shell

- **Every unit of work is gather, decide, act.** Impure reads, one pure call, impure writes. ([Axiom 13][A13])
- **Never mix a pure and an impure call in one statement.** The pure call goes on its own line, into a named value. ([Axiom 12][A12c])
- **A decision about what should happen returns an action union;** the shell executes it. ([Axiom 24][A24])
- **A lifecycle is a pure `Transition(state, command)`** returning the event; a repeated command returns `NoChange`, not an error. ([Axiom 25][A25])
- **The shell is ordinary object-oriented code.** Classes, constructor injection, and state where state is needed. ([Axiom 13][A13])
- **A session's working memory is a context object passed explicitly.** Owned by the shell, never seen by the core, never static, ambient or thread-local. ([Axiom 26][A26])
- **A long-running process is a loop around a pure `Transition`:** read the state, carry out its effect, wait for the event, transition, repeat. ([Axiom 27][A27])
- **Use typestate only when a wrong call order does real harm.** One type per state, non-public constructors, transitions return the next type. ([Axiom 28][A28])
- **Hide only decisions likely to change,** behind a small surface in domain words. Never hide inputs, effects or failures. ([Axiom 1][A1])

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
[A12]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-12-pattern-matching.md
[A12c]: https://github.com/JoanComasFdz/coding-playbook/blob/main/book/chapter2/axiom-12-pattern-matching.md#convention-match-on-a-named-value-never-on-an-inline-call
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
