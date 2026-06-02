# Axiom 20 — Validation

**When one value is built from many fallible parts, validation returns *every* failure at once — a `Result<T, IReadOnlyList<ValidationError>>` whose `Failure` case carries one entry per input that didn't pass, so the caller sees the complete error set in a single pass instead of discovering them one fix-and-resubmit cycle at a time.**

- All branches of the composite run; only when every branch succeeds does the composite succeed. Otherwise the failures are collected.
- Each value-object factory is upgraded from returning `Result<T, string>` ([Axiom 18](axiom-18-value-objects.md)) to returning `Result<T, ValidationError>` — the factory attaches the field name itself, so every result arrives at the composition site already located.

[Axiom 19](axiom-19-railway.md) chained fallible steps with `Bind` so the success values flowed through and the first `Failure` short-circuited the rest. That is the correct shape when each step *depends* on the previous one's success — when step *n + 1* literally cannot run without step *n*'s value. But when the steps are independent — every field of a record validated in parallel, every row of a CSV parsed before the import runs — short-circuiting hides errors the caller could have fixed in the same submission. This axiom is the accumulating combinator for that case: a `Validation.Combine(...).Map(build)` pair that collects the independent `Result`s and runs the composite constructor only when every branch succeeded, otherwise returning a `Failure` whose payload is the union of their reasons.

---

## Definitions

The shape rests on two pieces:

- **`ValidationError`** — a small immutable record carrying `Field` (a string locating the input — `"username"`, `"items[3].quantity"`, `"$.body.email"`) and `Message` (the human-readable reason). Both strings: the playbook stays with the cheapest convention. Each value object's `From` produces a `ValidationError` directly — the type knows its field name, so every `Result<T, ValidationError>` arrives at the composition site already located. Anything richer than two strings — a sealed hierarchy of error variants, an enum of categories — is an ADR-level decision, not part of this axiom.
- **`Validation.Combine`** — a static method on a `Validation` utility class. Takes N independent `Result<T, ValidationError>` values and returns a `Combined<…>` holder; the holder's `.Map(build)` method runs the composite constructor *if every branch succeeded*, otherwise returns `Failure(IReadOnlyList<ValidationError>)` carrying one entry per failed branch. The two-stage shape — *`Combine` collects, `.Map` builds* — keeps each step on its own line and matches the applicative-builder pattern from the FP literature without inheriting its jargon. Overloads cover 2-arity through 8-arity; beyond that, breaking the composite into smaller records is usually the right move.

The contrast with the railway from [Axiom 19](axiom-19-railway.md) is structural — same `Result` shape, different propagation rule:

| Combinator             | Failure mode                                             | Use when |
|------------------------|----------------------------------------------------------|------------------------------------------------------------------------|
| `Bind` (the railway)               | Stops at the first `Failure`; later steps never run.     | Each step depends on the previous one's success — `Token.From → Payload.Decode → CheckNotExpired → …` |
| `Combine` + `.Map` (validation)    | Runs all branches; merges every `Failure` into one list. | Branches are independent — N field validations on the same input record. |

---

## Example

The example builds a `CustomerProfile` from two raw strings — a username and an email. Each field has its own value object ([Axiom 18](axiom-18-value-objects.md)) whose `From` factory returns `Result<T, ValidationError>` directly: the type owns the field name, so every failure arrives already located.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed record ValidationError(string Field, string Message);

public sealed record Username
{
    public string Value { get; }
    private Username(string value) => Value = value;

    public static Result<Username, ValidationError> From(string raw) =>
        string.IsNullOrWhiteSpace(raw)
            ? new Failure<Username, ValidationError>(
                new ValidationError("username", "username is empty"))
            : raw.Length > 30
                ? new Failure<Username, ValidationError>(
                    new ValidationError("username", "username exceeds 30 characters"))
                : new Success<Username, ValidationError>(new Username(raw));
}

public sealed record EmailAddress
{
    public string Value { get; }
    private EmailAddress(string value) => Value = value;

    public static Result<EmailAddress, ValidationError> From(string raw) =>
        string.IsNullOrWhiteSpace(raw)
            ? new Failure<EmailAddress, ValidationError>(
                new ValidationError("email", "email is empty"))
            : !raw.Contains('@')
                ? new Failure<EmailAddress, ValidationError>(
                    new ValidationError("email", "email is missing '@'"))
                : new Success<EmailAddress, ValidationError>(new EmailAddress(raw));
}

public sealed record CustomerProfile(Username Username, EmailAddress Email);
```

</td>
<td>

```java
public record ValidationError(String field, String message) {}

public final class Username {
    private final String value;
    private Username(String value) { this.value = value; }
    public String value() { return value; }

    public static Result<Username, ValidationError> from(String raw) {
        if (raw == null || raw.isBlank())
            return new Failure<>(new ValidationError("username", "username is empty"));
        if (raw.length() > 30)
            return new Failure<>(new ValidationError("username", "username exceeds 30 characters"));
        return new Success<>(new Username(raw));
    }

    // equals / hashCode / toString as in Axiom 18
}

public final class EmailAddress {
    private final String value;
    private EmailAddress(String value) { this.value = value; }
    public String value() { return value; }

    public static Result<EmailAddress, ValidationError> from(String raw) {
        if (raw == null || raw.isBlank())
            return new Failure<>(new ValidationError("email", "email is empty"));
        if (!raw.contains("@"))
            return new Failure<>(new ValidationError("email", "email is missing '@'"));
        return new Success<>(new EmailAddress(raw));
    }

    // equals / hashCode / toString as in Axiom 18
}

public record CustomerProfile(Username username, EmailAddress email) {}
```

</td>
</tr>
</table>

The shape we *don't* want first — composing the two value objects with the railway from [Axiom 19](axiom-19-railway.md):

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public static Result<CustomerProfile, ValidationError> From(string rawUsername, string rawEmail) =>
    Username.From(rawUsername)
        .Bind(u => EmailAddress.From(rawEmail)
            .Map(e => new CustomerProfile(u, e)));

// Input: ("", "not-an-email")
// Result: Failure(ValidationError("username", "username is empty"))
// — the email problem is invisible until the user fixes the username and resubmits.
```

</td>
<td>

```java
public static Result<CustomerProfile, ValidationError> from(String rawUsername, String rawEmail) {
    return Username.from(rawUsername)
        .flatMap(u -> EmailAddress.from(rawEmail)
            .map(e -> new CustomerProfile(u, e)));
}

// Input: ("", "not-an-email")
// Result: Failure(ValidationError("username", "username is empty"))
// — the email problem is invisible until the user fixes the username and resubmits.
```

</td>
</tr>
</table>

The chain composes correctly — the type system has remembered that any step may fail — but the *semantics* are wrong for this scenario. The two field validations are independent: `EmailAddress.From("not-an-email")` does not need `Username.From("")` to have succeeded. There is no reason to stop after the first failure, and a meaningful reason not to: the user round-trips once per invalid field.

Now the accumulating shape. `Validation.Combine(...)` collects the independent results into a `Combined<…>` holder; `.Map(build)` runs the composite constructor when every branch succeeded, or returns the merged failure list otherwise:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public static class Validation
{
    public static Combined<A, B> Combine<A, B>(
        Result<A, ValidationError> ra,
        Result<B, ValidationError> rb) =>
        new Combined<A, B>(ra, rb);

    // …Combine for 3 through 8 results follows the same pattern
}

public readonly record struct Combined<A, B>(
    Result<A, ValidationError> Ra,
    Result<B, ValidationError> Rb)
{
    public Result<R, IReadOnlyList<ValidationError>> Map<R>(Func<A, B, R> build)
    {
        var errors = new List<ValidationError>();
        if (Ra is Failure<A, ValidationError> fa) errors.Add(fa.Error);
        if (Rb is Failure<B, ValidationError> fb) errors.Add(fb.Error);

        if (errors.Count > 0)
            return new Failure<R, IReadOnlyList<ValidationError>>(errors);

        var a = ((Success<A, ValidationError>)Ra).Value;
        var b = ((Success<B, ValidationError>)Rb).Value;
        return new Success<R, IReadOnlyList<ValidationError>>(build(a, b));
    }
}
```

</td>
<td>

```java
public final class Validation {
    private Validation() {}

    @FunctionalInterface public interface Function3<A, B, C, R>    { R apply(A a, B b, C c); }
    @FunctionalInterface public interface Function4<A, B, C, D, R> { R apply(A a, B b, C c, D d); }
    // …Function5..Function8

    public static <A, B> Combined2<A, B> combine(
            Result<A, ValidationError> ra,
            Result<B, ValidationError> rb) {
        return new Combined2<>(ra, rb);
    }

    // …combine for 3 through 8 results follows the same pattern

    public record Combined2<A, B>(
            Result<A, ValidationError> ra,
            Result<B, ValidationError> rb) {
        public <R> Result<R, List<ValidationError>> map(BiFunction<A, B, R> build) {
            var errors = new ArrayList<ValidationError>();
            if (ra instanceof Failure<A, ValidationError>(ValidationError e)) errors.add(e);
            if (rb instanceof Failure<B, ValidationError>(ValidationError e)) errors.add(e);

            if (!errors.isEmpty())
                return new Failure<>(List.copyOf(errors));

            var a = ((Success<A, ValidationError>) ra).value();
            var b = ((Success<B, ValidationError>) rb).value();
            return new Success<>(build.apply(a, b));
        }
    }
}
```

</td>
</tr>
</table>

And the composite — the value objects already speak `ValidationError`, so the composition site is `Validation.Combine(...)` followed by `.Map(build)` with no bookkeeping in between:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public static Result<CustomerProfile, IReadOnlyList<ValidationError>> From(
    string rawUsername,
    string rawEmail) => Validation
        .Combine(
            Username.From(rawUsername),
            EmailAddress.From(rawEmail))
        .Map((u, e) => new CustomerProfile(u, e));

// Input: ("", "not-an-email")
// Result: Failure([
//     ValidationError("username", "username is empty"),
//     ValidationError("email",    "email is missing '@'")
// ])
```

</td>
<td>

```java
public static Result<CustomerProfile, List<ValidationError>> from(
        String rawUsername,
        String rawEmail) {
    return Validation
        .combine(
            Username.from(rawUsername),
            EmailAddress.from(rawEmail))
        .map(CustomerProfile::new);
}

// Input: ("", "not-an-email")
// Result: Failure([
//     ValidationError("username", "username is empty"),
//     ValidationError("email",    "email is missing '@'")
// ])
```

</td>
</tr>
</table>

Two failures, two list entries, one round trip. The composition site has no bookkeeping — the value objects already speak `ValidationError`, and the staged API splits *collecting the results* from *building the composite* so each step reads clearly on its own line. Higher-arity composites add one more `Result` argument to `Combine` and one more parameter to the `Map` lambda; the call site rhythm is the same at 2 fields, 5 fields, or 8.

---

## Problem / forces

When a composite is built from many independent fallible inputs, four shapes recur:

1. **Throw on the first invalid input.** A controller does `if (rawUsername.IsEmpty()) throw new ValidationException("username")` and returns a 400 with one error. The user fixes it, resubmits, sees the next error, fixes it, resubmits. N invalid fields mean N round trips. The dishonesty is the one [Axiom 16](axiom-16-result.md) named — the failure mode is outside the return type — plus a UX cost specific to validation.
2. **Imperative accumulator.** A `Validate(profile)` method walks each field, appends to a `List<string> errors`, and returns it. Works in practice, but the accumulator lives outside the type system — nothing forces the caller to look at the list before using the profile, and `new CustomerProfile(...)` can still be constructed from invalid input. Detached validation: the same dishonesty as the throwing constructor [Axiom 18](axiom-18-value-objects.md) rejected, one step removed.
3. **Railway / single-failure `Bind` chain.** The railway from [Axiom 19](axiom-19-railway.md) returns a `Result<T, E>` honestly — the failure mode is in the signature — but stops at the first `Failure`. The right shape for sequential dependencies; the wrong shape for independent parts.
4. **Accumulating combinator.** Each input runs independently; the combinator merges every failure into one list. All errors are values, all errors are in the signature, and the caller is forced to pattern-match on the list before reaching the constructed value. The pick for independent branches.

The four are not all on the same trade-off curve. Throwing and the imperative accumulator both violate principles already established. The honest options are 3 and 4, and the choice between them is the dependency question: do later steps need the earlier ones to have succeeded? If yes, `Bind`. If no, `Combine`.

---

## Why

What the accumulating shape gets right that the single-failure chain and the detached accumulator do not:

**1. One round trip per submission.**
Two invalid fields produce two list entries in one response. The user's mental model — *"I filled the form, here is everything I got wrong"* — matches what the server returns. The railway is honest about *that one error* but quiet about the next two; the user only learns about the second after fixing the first. Validation gives the whole picture per attempt.

**2. Errors stay values.**
A list of `ValidationError` flows through the same type system as any other return value — log it, serialize it, attach it to an HTTP response body. No exception unwinds the stack; no `Validate` step can be skipped. The honesty argument from [Axiom 16](axiom-16-result.md) extends straight through: the *plural* failure case is in the signature, not just the singular one.

**3. The failure case is forced into the signature.**
Just like single-failure `Result`, the composite cannot be reached without pattern-matching on `Failure` — there is no path to a `CustomerProfile` that bypassed the validation. The list-shaped failure does not weaken this; it strengthens it, because the caller now also cannot assume "if the first failure is fine, the rest are fine."

**4. The error type carries provenance.**
`ValidationError.Field` says *which* input produced the entry. The client can highlight the right form field; the logs say which row in the CSV failed; the message is the reason, the field is the location. A bare string failure lost the location as soon as the chain joined the messages — `"username is empty"` could have come from any function that ever produced that string. With the `Field` attached, the error is self-locating.

**5. The combinator scales.**
N independent inputs become an N-arity `Combine` overload returning a `Combined<…>` holder with one `.Map` method. The composing shape does not change as the composite grows — only the arity does. A handler that builds a 5-field record uses the 5-arity `Combine`; the call site reads the same as the 2-arity one, just with three more lines and three more parameters in the `Map` lambda. Same `Validation.Combine(...).Map(build)` rhythm regardless of how wide the composite is.

`Combine` does not replace `Bind`. They cover different scenarios, and a single function may use both — `Combine` to collect every parsing failure across a record's fields, then `Bind` to chain one further check that genuinely depends on the constructed record (a uniqueness lookup, a cross-field comparison). The choice per step is the dependency question; both combinators are tools.

---

## Trade-offs

**`ValidationError.Field` is stringly typed.** A literal `"username"` written in two places is brittle to refactors. An `enum FieldName` removes the magic strings but is one more decision per codebase; a JSONPath-style path type (`"$.items[3].quantity"`) is more expressive but heavier. The default is plain strings; the structured-field alternatives are ADR territory. Through [Axiom 8](axiom-08-connascence.md)'s lens this is a [Connascence of Meaning](axiom-08-connascence.md#connascence-of-meaning-com) — the factory that emits `"username"` and every reader that matches on it must agree on what the string denotes — and the `enum` is the lift to a Connascence of Type; that lift is the whole of why the choice is a real trade and not a free win.

**Variadic `Combine` is awkward in static languages.** C# and Java do not have heterogeneous variadic generics. The N-arity ceiling is a real cost; in practice a 2-through-8 overload family of `Combine` (each paired with its `Combined<…>` holder) covers the realistic record sizes — beyond eight independent fallible fields, breaking the record into smaller composites is usually the better move. F# and Haskell express the same idea via a single applicative operator that scales without overloads; C# and Java pay a small overload-table tax — and on the Java side, an extra family of `Function3..Function8` interfaces that the standard library doesn't ship.

**VO factories own their field name.** Each `From` hard-codes the `Field` for its own type — `Username.From` always emits `ValidationError(Field: "username", …)`. The composition site stays clean (no per-branch `MapError` to lift a `string` failure into a structured one), but the VO is now coupled to one field name. When the same type fills two fields of one record — `BillingEmail` and `ShippingEmail` both holding an `EmailAddress` — the escape is either an overloaded `From(raw, field)` that takes the field path as a parameter, or two distinct VO types (a wrapper per role). One-VO-per-field is the simpler default; the parameter form is the escape hatch when the same VO needs to appear twice. The alternative direction — VOs return `Result<T, string>` per [Axiom 18](axiom-18-value-objects.md)'s default and the composition site lifts each one with `MapError(m => new ValidationError(field, m))` — keeps the VO reusable but pushes a line of bookkeeping into every composition site.

**Independence is sometimes a lie.** "Validate every field in parallel" assumes each check is truly independent. If `email` is allowed to be empty *only* when `username` matches a system account, the parallel form runs both checks anyway, which is harmless but reports an `"email is empty"` error that turns out not to be one. For genuinely conditional checks, fold a `Bind` into the chain after `Combine` resolves the unconditional ones.

**List-failure types at the boundary.** An HTTP layer that mapped `Result<T, string>` to a 400 with one body line now needs to map `Result<T, IReadOnlyList<ValidationError>>` to a 400 with an array. The mapping is a one-time cost per boundary; once written it covers every endpoint, and the response shape is the one front-ends already expect (`{ "errors": [{ "field": "...", "message": "..." }, ...] }`).

---

## When NOT to

**One fallible step.** A `Result<Token, string>` from a single check ([Axiom 16](axiom-16-result.md)) has nothing to accumulate. Wrap the single string in a list-of-one only when the boundary's response format demands it; otherwise leave it as is.

**Sequential dependencies.** When step 2 cannot meaningfully run without step 1's result, the railway from [Axiom 19](axiom-19-railway.md) is the right shape and `Combine` would force you to invent dummy "valid" cases for steps that did not run. Parsing a JWT, for instance: there is no useful "validation" of the signature when the header didn't parse.

**Internal-only construction.** A private factory inside the impure shell, called by code already known to have validated its inputs, does not need to return a structured `ValidationError` — its caller is not going to render a form. A bare `Result<T, string>` is enough; structured validation is for the *boundary*, where the error list is the deliverable to a user or another system.

**Single-shot scripts and migrations.** When a one-shot run can afford to stop at the first bad row and demand the operator fix it, `Bind` plus a clear log line is simpler than building the full list. The accumulating shape pays off when the list of errors is the deliverable, not when the operator's loop is "fix-and-rerun."

---

## References

[1] **Scott Wlaschin**, *Domain Modeling Made Functional*, Pragmatic Bookshelf, 2018. Cross-listed from [Axiom 16](axiom-16-result.md), [Axiom 17](axiom-17-result-combinators.md), and [Axiom 18](axiom-18-value-objects.md). The chapter on composing validation walks through the same accumulate-every-failure pattern on F# value objects: each smart constructor produces a structured error, the call site combines them, and a final builder function lifts the success values into the composite. The C# / Java staged shape here is the direct translation. The book is the closest single source for the playbook's whole error-handling stack.
<https://pragprog.com/titles/swdddf/domain-modeling-made-functional/>

[2] **Vladimir Khorikov**, *CSharpFunctionalExtensions* (v3.7.0, March 2026). Cross-listed from [Axiom 16](axiom-16-result.md), [Axiom 17](axiom-17-result-combinators.md), and [Axiom 18](axiom-18-value-objects.md). The library ships `Result.Combine` (which returns the first failure for `Result<string>` and supports a `Result.Combine` overload that concatenates failure messages) and the building blocks for richer accumulating forms; the C# example above is shaped after the conventions used in the library and Khorikov's writing.
<https://github.com/vkhorikov/CSharpFunctionalExtensions>

[3] **Philip Wadler**, *How to Replace Failure by a List of Successes*, FPCA, 1985. The early functional-programming paper on returning a *collection* of outcomes rather than a single value — the structural ancestor of accumulating combinators. Wadler's setting is non-determinism (a parser returning every possible parse), but the technique — let the result type carry a list, let the combinator merge — is the same one this axiom applies to error accumulation.
<https://homepages.inf.ed.ac.uk/wadler/papers/list-of-successes/list-of-successes.pdf>

[4] **Spring Framework**, *Validation, Data Binding, and Type Conversion* — `BindingResult` / `Errors` (Java). The framework built the accumulating shape into its model-binding layer because the round-trip cost of returning one error at a time was unacceptable for web forms. The playbook reproduces the same pattern at the domain layer so the controller does not have to translate between two error shapes.
<https://docs.spring.io/spring-framework/reference/core/validation.html>

[5] **ASP.NET Core**, *Model state validation* — `ModelStateDictionary` (C#). The .NET equivalent of `BindingResult`: model binders accumulate errors per field and the framework hands the controller the full set. Pulling the accumulating shape into the domain layer lets a single representation flow from the value-object constructor through the controller to the response body unchanged.
<https://learn.microsoft.com/en-us/aspnet/core/mvc/models/validation>

[6] **Vavr** — `io.vavr.control.Validation`. The off-the-shelf Java library shipping this axiom's exact staged shape: `Validation.combine(v1, v2, …).ap(builder)` accumulates up to eight validations (Vavr's `ap` is this axiom's `.map`). Same 8-arity ceiling, same accumulating behaviour. If a Java codebase already pulls in Vavr, this axiom's `Validation` utility class collapses into the library's existing type.
<https://docs.vavr.io/#_validation>
