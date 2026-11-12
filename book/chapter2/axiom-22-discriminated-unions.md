# Axiom 22 — Discriminated unions

**When a function has three or more possible outcomes, and each carries different data, model them as a discriminated union: one sealed parent type, and one record per outcome with only that outcome's fields.**

- A value is exactly one of the cases at a time.
- It is consumed with an exhaustive pattern match ([Axiom 12](axiom-12-pattern-matching.md)): the compiler checks that every case has a branch.

[Axiom 15](axiom-15-either.md) and [Axiom 17](axiom-17-result.md) handled two outcomes, and both were already built the same way: a sealed parent with two case records, consumed by a `switch` with two branches. Many real decisions have more than two outcomes. A card payment can be approved, declined, or need extra verification, and each outcome carries different data. A discriminated union is that shape for any number of cases. It is [Axiom 1](axiom-01-explicit-over-implicit.md)'s explicitness applied to cases: each outcome named, instead of encoded in flags.

Through [Axiom 9](axiom-09-connascence.md)'s lens, it turns a [Connascence of Meaning](axiom-09-connascence.md#connascence-of-meaning-com) (status codes and boolean flags every consumer decodes by convention) into a [Connascence of Type](axiom-09-connascence.md#connascence-of-type-cot) the compiler checks. It is also [Axiom 0](axiom-00-ubiquitous-language.md) at the level of a case: `Approved`, `Declined` and `RequiresVerification` are the domain's own words, each one a type.

---

## Definitions

A *discriminated union* (DU, also called a [tagged union](https://en.wikipedia.org/wiki/Tagged_union) or sum type) [1] has:

- **A sealed parent.** The set of cases is closed and known at compile time. In Java: `sealed interface T permits A, B, C` [2]. In C#: an `abstract record` with `sealed record` cases, which the compiler does *not* treat as closed (see below).
- **One record per case**, declaring only the fields that case carries. No optional fields, no nullable fields that only some cases use.
- **Disjoint cases.** A value is one case, never two and never none.
- **Pattern matching to consume it**, with the narrowing and binding of [Axiom 12](axiom-12-pattern-matching.md).

A DU is the *sum* half of an [algebraic data type](https://en.wikipedia.org/wiki/Algebraic_data_type): exactly one of its cases. The record ([Axiom 3](axiom-03-immutability.md)) is the *product* half: all of its fields at once.

How much the compiler checks differs (see [Axiom 12](axiom-12-pattern-matching.md#definitions)). Java makes a missing case a compile error. C# can't prove an `abstract record` hierarchy closed, so the discard branch goes inside the type's `Match`, once, and callers use `Match` instead of a `switch`. C# 15's `union` types ([Axiom 14](axiom-14-maybe.md#maybe-in-c-beyond-t)) close that gap: `public union PaymentOutcome(Approved, Declined, RequiresVerification);` is a closed set, and a `switch` over it needs no discard branch, only a `null` arm where the union can be `default`.

---

## Example

A card payment has three outcomes. *Approved* carries the issuer's authorization code. *Declined* carries the reason. *RequiresVerification* carries the URL of an extra verification step (such as 3-D Secure). The shape follows Wlaschin's F# examples [3].

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public abstract record PaymentOutcome
{
    public R Match<R>(
        Func<Approved, R>             approved,
        Func<Declined, R>             declined,
        Func<RequiresVerification, R> requiresVerification) =>
        this switch
        {
            Approved a             => approved(a),
            Declined d             => declined(d),
            RequiresVerification r => requiresVerification(r),
            _ => throw new UnreachableException()
        };
}
public sealed record Approved(string AuthCode) : PaymentOutcome;
public sealed record Declined(string Reason) : PaymentOutcome;
public sealed record RequiresVerification(string ChallengeUrl)
    : PaymentOutcome;

public static string Describe(PaymentOutcome outcome) => outcome.Match(
    approved:             a => $"Charged. Auth: {a.AuthCode}",
    declined:             d => $"Declined: {d.Reason}",
    requiresVerification: r => $"Verify at {r.ChallengeUrl}");
```

</td>
<td>

```java
public sealed interface PaymentOutcome
    permits Approved, Declined, RequiresVerification {}

public record Approved(String authCode) implements PaymentOutcome {}
public record Declined(String reason) implements PaymentOutcome {}
public record RequiresVerification(String challengeUrl)
    implements PaymentOutcome {}

public static String describe(PaymentOutcome outcome) {
    return switch (outcome) {
        case Approved a             -> "Charged. Auth: " + a.authCode();
        case Declined d             -> "Declined: " + d.reason();
        case RequiresVerification r -> "Verify at " + r.challengeUrl();
    };
}
```

</td>
</tr>
</table>

No `PaymentOutcome` can carry both an authorization code and a verification URL, and there is no fourth case. Add a `Pending` case, and the compiler points at every consumer that doesn't handle it yet: every `switch` in Java, and in C# every `Match` call, once `Match` gets its fourth parameter. In C#, every union in this book has a `Match` like this one, and a `Handle` where branches only act ([Axiom 12](axiom-12-pattern-matching.md#switch-or-match)); later examples leave them out.

Now put `Either` and `Result` next to it:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public abstract record Either<L, R>;
public sealed record Left<L, R>(L Value)  : Either<L, R>;
public sealed record Right<L, R>(R Value) : Either<L, R>;

public abstract record Result<T, E>;
public sealed record Success<T, E>(T Value) : Result<T, E>;
public sealed record Failure<T, E>(E Error) : Result<T, E>;
```

</td>
<td>

```java
public sealed interface Either<L, R> permits Left, Right {}
public record Left<L, R>(L value)  implements Either<L, R> {}
public record Right<L, R>(R value) implements Either<L, R> {}

public sealed interface Result<T, E> permits Success, Failure {}
public record Success<T, E>(T value) implements Result<T, E> {}
public record Failure<T, E>(E error) implements Result<T, E> {}
```

</td>
</tr>
</table>

The same shape: a sealed parent, case records with their own data, consumed exhaustively. `Either` and `Result` were DUs all along. They fix the number of cases at two and name them in general terms, because those two meanings are reused everywhere. `PaymentOutcome` has three cases, named after what each one means in its domain.

---

## Problem / forces

Three common ways to return several outcomes put all of the outcomes' data into one flat record:

- **Boolean flags plus fields.** `PaymentResult(bool IsApproved, bool RequiresChallenge, string AuthCode, string Reason, string ChallengeUrl)`. Which fields are set for which flags is a convention the type can't enforce. It is the many-case form of the [boolean blindness of Axiom 7](axiom-07-honest-total-signatures.md#definitions): `IsApproved && RequiresChallenge` is allowed by the type and forbidden by the domain.
- **A status string plus nullable fields.** `PaymentResult(string Status, string? AuthCode, string? Reason, string? ChallengeUrl)`. The compiler can't know that `AuthCode` is set exactly when `Status == "APPROVED"`, so every consumer trusts the convention or checks for `null` defensively.
- **An enum tag plus nullable fields.** The tag is at least typed, but the problem is the same: the data for each case is still nullable and still decoded by convention.

All three share one dishonesty: which fields belong to which outcome is a runtime agreement, not a property of the type. A DU moves it into the type: each case *is* a type, and declares only its own fields [4].

---

## Why

**1. Each case carries exactly its own data.**
`Approved` has an `AuthCode` and nothing else; `Declined` has a `Reason` and nothing else. An `Approved` with a stray verification URL can't be written, because that record has no such field. Invalid combinations are not guarded against; they simply have no type.

**2. The set of outcomes is closed, and the consumer can't miss one.**
Sealing declares every case in one place, and an exhaustive match makes the compiler point at every consumer when a case is added, the guarantee of [Axiom 12](axiom-12-pattern-matching.md#why) (point 3), now for outcomes of any number. No new language feature is needed beyond what `Either` and `Result` already used: one more case record.

---

## Trade-offs

- **Too many cases.** A DU with fifteen cases usually means the data wants redesigning (see [Axiom 12](axiom-12-pattern-matching.md#trade-offs)). Group related cases in a nested DU (`Settled(SettledKind) | Pending | Rejected`), or split the function into smaller decisions.
- **One allocation per result.** The cases are classes: a C# `record struct` can't inherit from an `abstract record`, Java records are always reference types, and C# 15 unions box value types. In ordinary code this doesn't matter. Where measurements say it does, a struct-based union library (`OneOf` in .NET) avoids the allocation, at the cost of a weaker check; keep the DU everywhere else.
- **Java records can't hide their constructor.** As in [Axiom 19](axiom-19-value-objects.md#definitions), `record Approved(String authCode)` accepts `null` and the empty string. When a case has rules beyond its shape, make it a `final class` with a `Parse` factory, or give its fields value-object types that carry the rules.

---

## When NOT to

- **Two cases that already have a name.** "Value or nothing", "one of two things" and "success or failure" are [Axiom 14](axiom-14-maybe.md), [Axiom 15](axiom-15-either.md) and [Axiom 17](axiom-17-result.md). A new sealed hierarchy for one of those is reinvention. The general DU pays off from three cases up.
- **A set that is open by design.** Plugins and extension points need cases added outside the module, which sealing forbids, so a sealed DU is the wrong tool (see [Axiom 12](axiom-12-pattern-matching.md#when-not-to)).
- **Cases that carry no data.** Days of the week, log levels, colors: a set of constants where no case carries its own data is an `enum`. A DU of empty records is an enum written the long way.

---

## References

[1] **Haskell** `data` declarations, **Rust** `enum`, **F#** discriminated unions, **Scala** `sealed trait` and `enum`, **TypeScript** tagged unions. These languages had the DU as a first-class type long before C# and Java reached the same shape through sealed types and pattern matching.

[2] **OpenJDK**, *JEP 409: Sealed Classes*, final in Java 17 (2021). A sealed parent declares its permitted subtypes, which makes the closed set a compile-time property and lets `switch` check exhaustiveness.
<https://openjdk.org/jeps/409>

[3] **Scott Wlaschin**, *Discriminated Unions*, F# for Fun and Profit. An introduction to using DUs to model outcomes: each case has only its own data, and the consumer handles each case. The C# and Java sealed hierarchies here translate the F# original.
<https://fsharpforfunandprofit.com/posts/discriminated-unions/>

[4] **Yehonathan Sharvit**, *Data-Oriented Programming: Reduce software complexity*, Manning Publications, 2022. Also cited in [Axiom 2](axiom-02-data-is-not-behavior.md) and [Axiom 3](axiom-03-immutability.md). Different kinds of things belong in different shapes of data, which is the move from one flat record with optional fields to one record per case.
<https://www.manning.com/books/data-oriented-programming>

---

← Previous: [Axiom 21 — Validation](axiom-21-validation.md) · Next: [Axiom 23 — Make illegal states unrepresentable](axiom-23-illegal-states.md) →
