# Axiom 13 — Either

**A computation with two possible outcomes must surface both in the return type.**

- Model both outcomes as values in a single return slot — no thrown exception, no tombstone, no `out` parameter splitting the answer across two channels.

> Either is the *structural* primitive; named necessay to understand further axioms. Do not use this, but make an effort to understand it.

[Axiom 0](axiom-00-data-vs-behaviour.md) says data is a value; [Axiom 1](axiom-01-immutability.md) says values do not change; [Axiom 12](axiom-12-maybe.md) says absence is itself a value. This axiom adds the next honest thing data does: when a computation can produce one of two distinct outcomes, *both* belong in the return type — and `Either<L, R>` is the minimum way to spell that.

This file is short on purpose. The rest of it is about what Either replaces — the three mainstream patterns that *pretend* a two-outcome function has one outcome.

---

## Definitions

It says one structural thing: **a function whose result is one of two distinct shapes must declare both in its return type, and the caller must acknowledge which one is present before reading it.**

A type is an *Either* (also called a *sum type* or *disjoint union of two*) when:

- **Two cases, by construction** — exactly one carries a value of type `L` (`Left<L>`), exactly one carries a value of type `R` (`Right<R>`).
- **The cases are disjoint** — a value cannot be both at once; it is one or the other.
- **No silent unwrap** — there is no public operation that reads either side without making the caller acknowledge which is present.

This is the unnamed, parametric form: two cases both visible in the return type, neither side reachable without acknowledging the other.

---

## Example

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public abstract record Either<L, R>;
public sealed record Left<L, R>(L Value) : Either<L, R>;
public sealed record Right<L, R>(R Value) : Either<L, R>;

Either<string, int> Divide(int numerator, int denominator) =>
    denominator == 0
        ? new Left<string, int>("Cannot divide by zero")
        : new Right<string, int>(numerator / denominator);

var result = Divide(1, 0);
Console.WriteLine(result switch
{
    Left<string, int> l  => "Error: "  + l.Value,
    Right<string, int> r => "Result: " + r.Value
});
```

</td>
<td>

```java
public sealed interface Either<L, R> permits Left<L, R>, Right<L, R> {}
public record Left<L, R>(L value) implements Either<L, R> {}
public record Right<L, R>(R value) implements Either<L, R> {}

Either<String, Integer> divide(int numerator, int denominator) {
    return denominator == 0
        ? new Left<>("Cannot divide by zero")
        : new Right<>(numerator / denominator);
}

void main(String[] args) {
    var result = divide(1, 0);
    switch (result) {
        case Left<String, Integer> l  -> System.out.println("Error: "  + l.value());
        case Right<String, Integer> r -> System.out.println("Result: " + r.value());
    }
}
```

</td>
</tr>
</table>

The caller has to handle both sides — the toolchain refuses or warns on the switch otherwise (Java's sealed hierarchy makes it a compile error; C# 14 cannot prove the hierarchy closed, so it emits a CS8509 warning instead — the same enforcement gradient [Axiom 12](axiom-12-maybe.md) describes). Both outcomes live in the same return slot. There is no exception unwinding the stack, no sentinel value masquerading as a real one, and no `out` parameter the caller has to declare a holder for. The rest of this axiom is about why those three alternatives fail and what `Either` buys you in their place.

---

## Problem / forces

Two-outcome computations are everywhere: parse-or-don't, divide-or-error, lookup-or-miss, validate-or-explain. Three patterns compete in mainstream code, and all three are dishonest about the fact that there *are* two outcomes:

- **Throw on the bad case, return the good case.** The signature lies — `int divide(int, int)` reads as "returns an int"; in practice it sometimes does not return at all. The caller either remembers to wrap in `try`/`catch` or eats a runtime crash, and the compiler will not remind the careless one. Exceptions also turn a normal "didn't divide" / "didn't find" / "didn't parse" into a control-flow event with a stack trace — both expensive and noisy when the "bad case" is a normal answer to the question the function was asked.
- **Return a tombstone** (`-1` for "no index", `""` for "bad input", `new User("", "")` for "user not found"). The signature still lies — `int` says "an int"; one of the ints it can return is "I did not find your answer, but I'm handing you something int-shaped anyway." Downstream code silently operates on the sentinel, and the bug surfaces several frames away from the producer. See [Axiom 12](axiom-12-maybe.md) for the long form of why this is the worst of both worlds.
- **Split the answer across two channels.** The C# Try-pattern is the canonical example: `bool TryParse(string s, out int result)`. The success-flag lives in the return value; the *actual answer* lives in a mutable `out` parameter. The caller has to declare a holder before the call, read the flag *before* reading the holder, and trust a convention (the holder is undefined on failure) that the type system does not enforce. The signature acknowledges that there are two outcomes — but it inverts the natural shape (the answer is the byproduct, the flag is the return) and the result is no longer a value that flows through an expression. You cannot put `TryParse(...)` on the right-hand side of `var x = ...`; you cannot chain it; you cannot pass it through `Stream.map`. Java does not have first-class `out` parameters, but the same anti-pattern shows up as a pair return through a mutable holder, or as a method that mutates one of its arguments and returns a status code.

Either fixes all three by surfacing both outcomes as values in *one* return slot. The success path and the failure path are the same shape: a value the caller has to read by acknowledging which case it is. There is no exception unwinding, no sentinel masquerading as a real value, and no second channel.

---

## Why

**1. Both outcomes belong in the return type, as values.**
If a function can produce two distinct outcomes, the honest signature carries both — *in the return type*, not in a `throws` clause, not as a sentinel value of the success type, and not in an `out` parameter the caller has to plumb. Either is the minimum implementation: one return slot, two parametric cases, exactly one of them carries a value at any given moment, both reachable only by pattern-matching.

**2. Values compose; exceptions and out parameters do not.**
A function returning `Either<L, R>` is just a function — it slots into a pipeline (`parse → validate → enrich → save`), a `map`, a comprehension, a list of results. A function that *throws* drags every caller into `try`/`catch` territory and is silently a different function depending on whether the surrounding code wraps it. A function with an `out` parameter cannot be the right-hand side of an expression at all; the caller must pre-declare the variable, call, then read the flag, then maybe read the holder. Two-outcome computations are the building blocks of pipelines, and only the value-returning form chains cleanly through one.

**3. No hidden third state.**
Tombstones invent a third state: "a real `User`" vs "the empty-string sentinel `User`" — same type, different meaning, the compiler cannot tell them apart. The Try-pattern invents four: success-with-out-set, success-with-out-ignored, failure-with-out-meaningful, failure-with-out-garbage — again, the compiler cannot tell them apart. Either has only the two states declared in the type — `Left` or `Right`, never both, never neither — and the call site is forced to read which one it has before it can do anything with it.

---

## Trade-offs

Either costs you **verbosity at the producer**: instead of `throw new ArgumentException(...)` you write `return new Left<>(...)`; instead of an `out` parameter you wrap two distinct outcome types into a single return. It also costs **a small allocation per call** — a `Left` or `Right` wrapper around each result, where the throw/tombstone/out forms allocate nothing on the value path. For ordinary line-of-business code that is dust under the table; for inner loops it can matter (see *When NOT to* below).

What Either does *not* cost you is honesty: the return type names what the function actually returns. The compiler — fully on the Java side, with a CS8509 warning on the C# 14 side — holds the caller to it.

---

## When NOT to

**When a named variant exists.** Either is the parametric primitive; when the two outcomes carry domain meaning (*success vs failure*, *parsed vs raw*, *cached vs fresh*), reach for the named type instead. Those are the subject of later axioms.

**For absence.** "Value or no value" is *one* outcome and a missing one, not two outcomes of distinct kinds — that is [Axiom 12](axiom-12-maybe.md), not this one. `Either<Unit, T>` is structurally `Optional<T>` written the long way around.

**Beyond two cases.** Three or more honest outcomes call for another axiom (discriminated unions reference here). Nesting `Either` is technically possible and always wrong.

**Hot paths where allocation matters.** The C# Try-pattern (`bool TryParse(string s, out T result)`) is allocation-free and is the standard for the int/double/`Guid` parsers in `System.*` exactly because the surrounding code is hot. The honesty trade is real — the `out` is undefined on failure, the compiler will not enforce the flag check — but in inner loops it earns its keep. Wrap once at the boundary into an Either-shaped value when the result leaves the hot path.

---

## References

[1] **Haskell** `Data.Either` (Haskell 2010 Report) and **Scala** `scala.util.Either` (right-biased since 2.12, 2016). `Either` predates the language-specific named success/failure types in both ecosystems; the convention "right = success" comes from Haskell and was inherited.
<https://hackage.haskell.org/package/base/docs/Data-Either.html>

[2] **Yehonathan Sharvit**, *Data-Oriented Programming: Reduce software complexity*, Manning Publications, 2022. Cited in [Axiom 0](axiom-00-data-vs-behaviour.md), [Axiom 1](axiom-01-immutability.md), and [Axiom 12](axiom-12-maybe.md); relevant here for the broader case that distinct outcomes belong in the data, not in the control flow.
<https://www.manning.com/books/data-oriented-programming>
