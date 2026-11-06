# Axiom 14 — Either

**When a computation has two possible outcomes, and each one carries its own data, return both in one type: `Either<L, R>`.**

- A value of that type holds exactly one side: a `Left<L>` or a `Right<R>`.
- The caller has to check which side it holds before reading it.

[Axiom 6](axiom-06-honest-total-signatures.md) said every outcome belongs in the return type, and [Axiom 13](axiom-13-maybe.md) gave the ready-made type for "a value or nothing". Either is the next shape: "this value *or* that value", where both sides carry data. A Maybe is an Either whose second side carries nothing.

In application code I rarely write `Either` itself. Its sides have no names, so I reach for a type whose cases say what they mean (see *When NOT to*). It is here because the types that follow are built on its shape.

Through [Axiom 8](axiom-08-connascence.md)'s lens, Either turns a [Connascence of Meaning](axiom-08-connascence.md#connascence-of-meaning-com) (an exception, a sentinel or an `out` flag whose meaning the type can't carry) into a [Connascence of Type](axiom-08-connascence.md#connascence-of-type-cot). Some meaning is left, though: which side is which is still a convention (see *Trade-offs*).

---

## Definitions

A type is an *Either* (a [sum type](https://en.wikipedia.org/wiki/Tagged_union) with two cases) when:

- **It has two cases.** One carries a value of type `L` (`Left`), the other a value of type `R` (`Right`).
- **The cases are disjoint.** A value is one or the other, never both and never neither.
- **There is no silent unwrap.** You can't read either side without first checking which one is present.

By convention the left side holds the error and the right side the result. Haskell's documentation puts it this way: "the Left constructor is used to hold an error value and the Right constructor is used to hold a correct value", with the mnemonic "'right' also means 'correct'" [1].

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
var message = result switch
{
    Left<string, int> l  => "Error: "  + l.Value,
    Right<string, int> r => "Result: " + r.Value,
    _ => throw new UnreachableException()
};
Console.WriteLine(message);
```

</td>
<td>

```java
public sealed interface Either<L, R> permits Left, Right {}
public record Left<L, R>(L value) implements Either<L, R> {}
public record Right<L, R>(R value) implements Either<L, R> {}

Either<String, Integer> divide(int numerator, int denominator) {
    return denominator == 0
        ? new Left<>("Cannot divide by zero")
        : new Right<>(numerator / denominator);
}

var result = divide(1, 0);
String message = switch (result) {
    case Left<String, Integer> l  -> "Error: "  + l.value();
    case Right<String, Integer> r -> "Result: " + r.value();
};
System.out.println(message);
```

</td>
</tr>
</table>

Both outcomes come back through the same return value, and the caller handles both in one `switch` ([Axiom 11](axiom-11-pattern-matching.md)). Java's sealed interface makes a missing branch a compile error. C# can't prove the hierarchy closed, so it needs the discard branch, and a missing case is only a warning (see [Axiom 11](axiom-11-pattern-matching.md#definitions)). C# 15's union types, shown in [Axiom 13](axiom-13-maybe.md#maybe-in-c-beyond-t), remove the need for the discard branch.

---

## Problem / forces

Two-outcome computations are everywhere: parse or explain why not, divide or report the zero, look up or say what went wrong. [Axiom 6](axiom-06-honest-total-signatures.md#definitions) listed the usual ways to hide the second outcome: throw it, encode it as a [sentinel value](https://en.wikipedia.org/wiki/Sentinel_value), or return it through an `out` parameter. Each one makes the signature lie.

What those defaults have in common is that they force the second outcome into a channel built for something else. Each fix so far has been specific: a hand-written `FindResult`, or a Maybe when the second outcome is "nothing". When the second outcome carries data of its own (an error message, a partial result, a reason), neither fits, and you need a general two-case type.

---

## Why

**1. One return value, two shapes.**
The function returns one value, and that value is either a `Left` or a `Right`. Both outcomes travel the same way: no stack unwinding, no flag to read before the result, no placeholder that looks like a real answer.

**2. Exactly two states.**
A sentinel adds a hidden third state: a real value and a fake one with the same type. `bool TryParse(string s, out int result)` returns a flag and a number, and nothing stops the caller from reading the number when the flag is `false`. On failure the number is `0`, which looks like a real answer. Either has only the two states its type declares, and the caller can't skip the check.

**3. It is a value, so it composes.**
An `Either` can be stored, returned, put in a list or passed to a higher-order function ([Axiom 10](axiom-10-higher-order-functions.md)), like any other value. A throwing function drags every caller into `try`/`catch`, and an `out` parameter can't even sit on the right-hand side of an assignment. This is what later lets two-outcome steps chain into a pipeline.

---

## Trade-offs

- **The sides have no names.** `Either<string, int>` doesn't say which side is the error; the reader relies on the left-is-error convention. That is a leftover [Connascence of Meaning](axiom-08-connascence.md#connascence-of-meaning-com), and it is the main reason I prefer named cases (see *When NOT to*).
- **More code at the producer.** `return new Left<>(...)` replaces `throw new ArgumentException(...)`, and the generic arguments are noisy in C#.
- **One small allocation per call.** Each result is wrapped in a `Left` or `Right`. In ordinary line-of-business code that cost doesn't matter; in a hot loop it can (see *When NOT to*).

---

## When NOT to

- **When the outcomes have domain names.** If the two sides mean *success or failure*, *parsed or raw*, *cached or fresh*, give them those names. A type whose cases say what they mean beats `Left` and `Right`; later axioms build exactly that.
- **For absence.** "A value or nothing" is a Maybe ([Axiom 13](axiom-13-maybe.md)). An Either whose left side carries nothing is a Maybe written the long way.
- **For three or more outcomes.** Use a type with one case per outcome, which a later axiom develops. Nesting `Either` inside `Either` works, but it becomes unreadable fast.
- **Hot paths where allocation matters.** `bool TryParse(string s, out int result)` allocates nothing, which is why .NET's parsers use it. The cost is honesty (see *Why*, point 2), so keep it inside the hot code and convert the result into an honest type once it leaves.

---

## References

[1] **Haskell `Data.Either`**, base library documentation. "The Either type represents values with two possibilities", and the left-is-error, right-is-correct convention quoted in *Definitions*. Scala's `Either` follows the same convention and has been right-biased (its `map` works on the right side) since Scala 2.12, 2016.
<https://hackage.haskell.org/package/base/docs/Data-Either.html>

---

← Previous: [Axiom 13 — Maybe](axiom-13-maybe.md) · Next: [Axiom 15 — Unit](axiom-15-unit.md) →
