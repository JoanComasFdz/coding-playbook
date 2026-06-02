# Axiom 21 — Discriminated unions

**A discriminated union is a sealed type whose permitted variants each carry their own payload — the same machinery as [Either](axiom-14-either.md) and [Result](axiom-16-result.md), generalized to three or more honest outcomes.**

- N case-types live under one sealed parent; each variant is its own record with its own fields.
- A value is exactly one variant at a time; the cases are disjoint by construction.
- Consumed by exhaustive pattern matching ([Axiom 11](axiom-11-pattern-matching.md)) — the compiler verifies that every case has a branch.

[Axiom 14](axiom-14-either.md) handled two-outcome computations with `Either<L, R>`; [Axiom 16](axiom-16-result.md) named the success/failure variant of that shape as `Result<T, E>`. Both were already sealed hierarchies — an abstract parent plus two case-records — consumed by a pattern match with two arms. Many real-world decisions produce more than two honest outcomes: a card authorization can be approved, declined, or require step-up verification; a parse can yield a valid value, a recoverable warning, or a fatal mismatch. Each outcome carries different data. The discriminated union is the data type that admits exactly those N cases and forbids any other combination of fields.

Through [Axiom 8](axiom-08-connascence.md)'s lens, this axiom weakens a [Connascence of Meaning](axiom-08-connascence.md#connascence-of-meaning-com) — magic codes and boolean flags every consumer decodes by convention — into a Connascence of Type the compiler exhausts.

---

## Definitions

A *discriminated union* (DU, also called a *sum type* or *tagged union*) is:

- **A sealed parent type** — the set of permitted variants is closed and known at compile time. In Java this is `sealed interface T permits A, B, C` (JEP 409); in C# it's an `abstract record` whose only descendants are `sealed record`s in the same file or module.
- **N case-types, one per variant** — each variant is its own record (or `final class`) declaring only the fields that variant carries. No optional fields, no nullable smuggling.
- **Disjoint by construction** — a value is one variant or another, never both, never neither.
- **Consumed by pattern matching** — narrowing and binding happen inside the arm, as in [Axiom 11](axiom-11-pattern-matching.md); exhaustiveness is a compile-time property over the sealed set.

The 2-case versions are already named: `Either<L, R>` and `Result<T, E>`. This axiom is the general form at any arity. The reveal is that the sealed-interface-plus-records pattern reused from [Axiom 11](axiom-11-pattern-matching.md) onward *is* the DU; the earlier axioms specialized it to the two-case shape because that case is common enough to deserve a name.

A DU is the *sum* half of an *algebraic data type*; the record ([Axiom 2](axiom-02-immutability.md)) is the *product* half — all of its fields at once, versus exactly one of its variants.

The compile-time guarantee is fully enforced on the Java side (a missing arm is a compile error). On the C# side it is partial — C# 14 cannot prove the hierarchy closed, so an exhaustive switch over a `sealed`-leaved hierarchy emits CS8509 if a case is missed rather than a hard error. The honesty gradient is the same one [Axiom 14](axiom-14-either.md) documented for `Either`.

---

## Example

A card authorization produces one of three honest outcomes. *Approved* carries the issuer's auth code. *Declined* carries the human-readable reason. *RequiresVerification* carries the URL of a step-up challenge (3-D Secure, SCA). Each variant carries only the fields that variant has.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public abstract record PaymentOutcome;
public sealed record Approved(string AuthCode)              : PaymentOutcome;
public sealed record Declined(string Reason)                : PaymentOutcome;
public sealed record RequiresVerification(string ChallengeUrl) : PaymentOutcome;

public static string Render(PaymentOutcome outcome) => outcome switch
{
    Approved a             => $"Charged. Auth: {a.AuthCode}",
    Declined d             => $"Declined: {d.Reason}",
    RequiresVerification r => $"Verify at {r.ChallengeUrl}"
};
```

</td>
<td>

```java
public sealed interface PaymentOutcome
    permits Approved, Declined, RequiresVerification {}

public record Approved(String authCode) implements PaymentOutcome {}
public record Declined(String reason) implements PaymentOutcome {}
public record RequiresVerification(String challengeUrl) implements PaymentOutcome {}

public static String render(PaymentOutcome outcome) {
    return switch (outcome) {
        case Approved a             -> "Charged. Auth: " + a.authCode();
        case Declined d             -> "Declined: " + d.reason();
        case RequiresVerification r -> "Verify at "  + r.challengeUrl();
    };
}
```

</td>
</tr>
</table>

There is no `PaymentOutcome` instance that carries both an auth code and a challenge URL. There is no fourth variant. The `Render` consumer covers all three cases; add a `Pending` variant and the compiler points at every match that doesn't yet handle it.

Now the reveal — the sealed-interface-plus-records shape this section just used is the same shape `Either` and `Result` were built from. Put them side by side:

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

Same machinery: sealed parent, case-records carrying per-variant payload, exhaustive consumption. The difference is the *arity*. `Either` and `Result` fix it at two and name the cases; `PaymentOutcome` fixes it at three and names them after what each one means in the domain.

---

## Problem / forces

When a function produces three or more honest outcomes, four shapes recur — only one keeps the per-variant payload honest:

1. **Boolean flags plus optional fields.** A `record PaymentResult(bool IsApproved, bool RequiresChallenge, string AuthCode, string Reason, string ChallengeUrl)` shoves every variant's data into one flat record. The valid combinations (`IsApproved == true` ⇒ `AuthCode` is set and the other two strings are empty) are a runtime convention the type cannot enforce. Downstream code carries the rule by hand. This is the multi-case form of return-side *boolean blindness* ([Axiom 6](axiom-06-honest-total-signatures.md)): each flag is an anonymous case-bit, `IsApproved && RequiresChallenge` is a combination the type permits but the domain forbids, and the DU restores the names the booleans erased.
2. **String discriminator plus nullable payload.** A `record PaymentResult(string Status, string? AuthCode, string? Reason, string? ChallengeUrl)` swaps the booleans for a status string and the payload for nullable fields. The compiler cannot tell that `AuthCode` is non-null precisely when `Status == "APPROVED"`. Every consumer either trusts the convention or null-checks defensively in each branch.
3. **Enum tag plus an optional-field record.** `enum PaymentStatus { Approved, Declined, RequiresVerification }` plus a record with three nullable payload fields. The tag is at least typed, but the per-variant payload is still nullable on the wrong side of the discriminator. Lighter than option 2, same fundamental problem.
4. **Discriminated union (sealed hierarchy of case-records).** Each variant *is* a type. Each variant declares only its own fields. Pattern matching over the sealed parent narrows the value and enforces exhaustiveness at the compile site. The shape this axiom names.

Options 1, 2 and 3 share a single dishonesty: the *combination of fields* that's valid for each outcome is a runtime contract, not a type-level property. The DU moves that contract into the type system. Each case carries exactly what that case has — and the compiler tells the consumer when a case is missed.

---

## Why

What the DU gets right that the flat-record / nullable-payload / enum-tag forms do not:

**1. The set of outcomes is closed and verified.**
Sealing declares the full set in one place. A pattern match consumes them exhaustively; omit a case and the toolchain complains (compile error on Java, CS8509 warning on C#). Adding a new variant turns "every place I need to update" into a list the compiler hands the engineer — the same enforcement gradient [Axiom 11](axiom-11-pattern-matching.md) names for sealed `Shape`.

**2. Each variant carries exactly its own payload.**
`Approved` has an `AuthCode` and nothing else. `Declined` has a `Reason` and nothing else. There is no `Approved` instance with a stray `ChallengeUrl` field — that record literally does not have one. Invalid combinations are not "guarded against"; they are *unrepresentable*, which is the operational form of the "make illegal states unrepresentable" principle from [Axiom 6](axiom-06-honest-total-signatures.md) at the variant level.

**3. Either and Result generalize to N cases without new machinery.**
The two-case sealed hierarchies from [Axiom 14](axiom-14-either.md) and [Axiom 16](axiom-16-result.md) used the exact same toolchain — sealed parent, case-records, pattern match — that this axiom uses at higher arity. The reader doesn't learn a new language feature for the three-case version; they apply the same shape with one more permitted leaf. The two named special cases earned their names because the *meaning* — left/right, success/failure — is reused across thousands of functions; everywhere else, the variants get domain names because the domain is what's specific.

**4. The consuming code reads as a table.**
A pattern match over a DU sits the cases side by side, one per line: shape on the left, work on the right. A reviewer counts variants against arms; a reader sees the full decision in one place. The flat-record / nullable-field forms distribute the same decision across `if`-ladders or scattered helper methods; the DU keeps it in one expression, and the type system keeps it complete.

---

## Trade-offs

**Variant explosion is a real risk.** A DU with fifteen cases is a signal that the data wants a redesign, not a celebration of expressive types. Sometimes the right move is grouping related variants under a nested DU (`PaymentOutcome = Settled(SettledKind) | Pending | Rejected`); sometimes it is splitting one function into several, each returning a smaller DU. The size of the DU mirrors the size of the decision — when both grow large, the decision is the thing to revisit.

**Allocation per result.** The sealed-hierarchy form requires the variants to be classes — a C# `record struct` can't inherit from an `abstract record`, and Java records are always reference types. Each variant is a heap allocation per call. For line-of-business code this is dust under the table; for inner loops on the JVM or in C# value-type-heavy paths it can matter. Struct-encoded unions (`OneOf<A, B, C>` libraries on the .NET side, hand-rolled struct discriminators with `[StructLayout(LayoutKind.Explicit)]`) trade the sealed-hierarchy encoding for zero allocation; the honesty cost of going back to a runtime tag is real, and the practice is to keep the DU for the boundary and pay the allocation cost there.

**Java records can't enforce smart-constructor invariants.** Same gotcha [Axiom 18](axiom-18-value-objects.md) named for value objects: `record Approved(String authCode) implements PaymentOutcome {}` accepts `null` and the empty string. When a variant carries invariants beyond its shape, the leaf has to be a `final class` with a private constructor and a `From` factory, or its invariants live in the value-object types it wraps.

**Some operations belong on the type, not in a consumer.** When the same operation has a per-variant definition that is intrinsic to each variant — *render a string for this payment outcome*, *is this terminal?* — a virtual method per leaf keeps the implementation next to its data. Pattern matching over the DU centralizes the same operation in the consumer. Both are valid; the choice between them is the same one [Axiom 11](axiom-11-pattern-matching.md) drew, applied to the consumption of a multi-case data type instead of a two-case one.

---

## When NOT to

**Two cases with one named answer.** When the two outcomes are *value or no value*, *one of two distinct things*, or *success or failure*, the named types [Axiom 13](axiom-13-maybe.md), [Axiom 14](axiom-14-either.md) and [Axiom 16](axiom-16-result.md) already provide are the right reach. Inventing a fresh sealed hierarchy when one of those fits is reinvention. The general DU shape pays off at arity three and above.

**The set of cases is open by design.** Plugin hosts, extension points, codebases where the variant list is expected to grow outside the module. Sealing requires every variant to live where the parent is declared; for an open set, a non-sealed interface with a virtual method per implementor — exactly the OO shape — is the right fit. The compile-time exhaustiveness guarantee of the DU is paid for in closure.

**The variants are values, not shapes.** Days of the week, log levels, colour codes, HTTP status — sets of distinguished constants where no variant carries different data. That is what `enum` is for. A DU with N case-types each carrying nothing is an enum spelled the long way around. The distinction: enums enumerate constants; DUs enumerate *typed* alternatives.

**Hot paths where the per-call allocation hurts.** When measurements show the variant allocation matters — tight inner loops, latency-critical code — a struct-encoded union or a tag-and-payload struct can be the right encoding for that path, with a DU lifted at the boundary once the value leaves the loop. Pay the cost only when the measurements demand it.

---

## References

[1] **Haskell** `data` declarations (Haskell 2010 Report), **Rust** `enum`, **F#** discriminated unions, **Scala** `sealed trait` / `enum`, **TypeScript** tagged unions. The DU is the shape these languages model the case-list as a first-class type — long before C# and Java arrived at the same shape via `sealed interface`/`abstract record` plus pattern matching.

[2] **OpenJDK**, *JEP 409: Sealed Classes*, finalised in Java 17 (2021). Cross-listed from [Axiom 11](axiom-11-pattern-matching.md) and [Axiom 14](axiom-14-either.md). The language feature that makes the closed-set guarantee a compile-time property: a sealed parent declares its permitted subtypes, and the compiler enforces both the closure and exhaustive consumption over it.
<https://openjdk.org/jeps/409>

[3] **Scott Wlaschin**, *Designing with Types: Discriminated unions*, F# for Fun and Profit. The canonical introduction to using DUs to model business outcomes — each variant is its own shape with only its own data, the consumer dispatches by case. The C# / Java sealed-hierarchy form is the direct translation of the F# original.
<https://fsharpforfunandprofit.com/posts/designing-with-types-discriminated-unions/>

[4] **Scott Wlaschin**, *Designing with Types: Making illegal states unrepresentable*, F# for Fun and Profit. Cross-listed from [Axiom 6](axiom-06-honest-total-signatures.md). The DU is the operational form of "illegal states unrepresentable" applied to multi-outcome data: each impossible combination of fields is not "checked against" but *literally not a type that exists*.
<https://fsharpforfunandprofit.com/posts/designing-with-types-making-illegal-states-unrepresentable/>

[5] **Yehonathan Sharvit**, *Data-Oriented Programming: Reduce software complexity*, Manning Publications, 2022. Cross-listed from [Axiom 1](axiom-01-data-vs-behaviour.md), [Axiom 2](axiom-02-immutability.md), [Axiom 13](axiom-13-maybe.md), and [Axiom 14](axiom-14-either.md). The broader case that distinct kinds-of-thing belong as distinct shapes of data — exactly the move from "one flat record with optional fields" to "a sealed hierarchy whose variants each declare only their own fields."
<https://www.manning.com/books/data-oriented-programming>
