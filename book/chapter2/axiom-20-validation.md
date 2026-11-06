# Axiom 20 — Validation

**When one value is built from several independent inputs that can each fail, check them all and return *every* failure at once: a `Result<T, IReadOnlyList<ValidationError>>`.**

- Every input is checked. The value is built only if all of them pass; otherwise the failures are collected into one list.
- The caller sees the whole list in one go, instead of finding the errors one fix-and-resubmit at a time.

[Axiom 19](axiom-19-railway.md) stopped at the first failure. That is right when each step needs the previous one's result. When the inputs are independent (every field of a form, every row of a CSV file), stopping early hides errors the caller could have fixed in the same attempt. This axiom is the other propagation rule: collect instead of stop.

---

## Definitions

Two pieces:

- **`ValidationError`**: a small record with a `Field` (where the input came from: `"username"`, `"items[3].quantity"`) and a `Message` (why it failed). Each value object's `Parse` returns a `ValidationError` directly, so every failure arrives already located. Anything richer than two strings is a contextual choice for an ADR, not part of this axiom.
- **`Validation.Combine(...).Map(build)`**: `Combine` takes several independent `Result`s; `Map` builds the value from their successes if every one succeeded, and otherwise returns a `Failure` with one `ValidationError` per input that failed. Functional programmers call this shape an [applicative functor](https://en.wikipedia.org/wiki/Applicative_functor) [1][2]; this book uses only the two calls.

The difference from the railway is only the propagation rule:

| Combinator | On failure | Use when |
|---|---|---|
| `Bind` (the railway) | Stops at the first failure; later steps never run. | Each step needs the previous one's result: `Token.Parse` → `Payload.Decode` → `CheckNotExpired`. |
| `Combine` + `Map` (validation) | Runs every check; collects every failure into one list. | The checks are independent: several fields of the same form. |

---

## Example

A `CustomerProfile` built from two raw strings. The value objects are the ones from [Axiom 18](axiom-18-value-objects.md), except that `Parse` now returns a `ValidationError` instead of a `string`:

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

    public static Result<Username, ValidationError> Parse(string raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
            return new Failure<Username, ValidationError>(
                new ValidationError("username", "username is empty"));
        if (raw.Length > 30)
            return new Failure<Username, ValidationError>(
                new ValidationError("username", "username is over 30 characters"));
        return new Success<Username, ValidationError>(new Username(raw));
    }
}

public sealed record EmailAddress
{
    public string Value { get; }
    private EmailAddress(string value) => Value = value;

    public static Result<EmailAddress, ValidationError> Parse(string raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
            return new Failure<EmailAddress, ValidationError>(
                new ValidationError("email", "email is empty"));
        if (!raw.Contains('@'))
            return new Failure<EmailAddress, ValidationError>(
                new ValidationError("email", "email has no '@'"));
        return new Success<EmailAddress, ValidationError>(new EmailAddress(raw));
    }
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

    public static Result<Username, ValidationError> parse(String raw) {
        if (raw == null || raw.isBlank())
            return new Failure<>(new ValidationError(
                "username", "username is empty"));
        if (raw.length() > 30)
            return new Failure<>(new ValidationError(
                "username", "username is over 30 characters"));
        return new Success<>(new Username(raw));
    }
    // equals, hashCode and toString as in Axiom 18
}

public final class EmailAddress {
    private final String value;
    private EmailAddress(String value) { this.value = value; }
    public String value() { return value; }

    public static Result<EmailAddress, ValidationError> parse(String raw) {
        if (raw == null || raw.isBlank())
            return new Failure<>(new ValidationError(
                "email", "email is empty"));
        if (!raw.contains("@"))
            return new Failure<>(new ValidationError(
                "email", "email has no '@'"));
        return new Success<>(new EmailAddress(raw));
    }
    // equals, hashCode and toString as in Axiom 18
}

public record CustomerProfile(Username username, EmailAddress email) {}
```

</td>
</tr>
</table>

First, the shape we *don't* want: the railway from [Axiom 19](axiom-19-railway.md).

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public static Result<CustomerProfile, ValidationError> Parse(
    string rawUsername, string rawEmail) =>
    Username.Parse(rawUsername)
        .Bind(u => EmailAddress.Parse(rawEmail)
            .Map(e => new CustomerProfile(u, e)));

// Input:  ("", "not-an-email")
// Result: Failure(ValidationError("username", "username is empty"))
// The email error stays hidden until the username is fixed.
```

</td>
<td>

```java
public static Result<CustomerProfile, ValidationError> parse(
        String rawUsername, String rawEmail) {
    return Username.parse(rawUsername)
        .flatMap(u -> EmailAddress.parse(rawEmail)
            .map(e -> new CustomerProfile(u, e)));
}

// Input:  ("", "not-an-email")
// Result: Failure(ValidationError("username", "username is empty"))
// The email error stays hidden until the username is fixed.
```

</td>
</tr>
</table>

The chain is honest, but it stops too early. Checking the email doesn't need the username to be valid, so there is no reason to stop, and a good reason not to: the user needs one round trip per invalid field.

Now `Combine` and `Map`, written by hand to show there is nothing hidden inside:

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

    // Combine for 3 to 8 results follows the same pattern
}

public readonly record struct Combined<A, B>(
    Result<A, ValidationError> Ra,
    Result<B, ValidationError> Rb)
{
    public Result<R, IReadOnlyList<ValidationError>> Map<R>(
        Func<A, B, R> build)
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

    // Java has no Function3..Function8; declare them as needed:
    @FunctionalInterface
    public interface Function3<A, B, C, R> { R apply(A a, B b, C c); }

    public static <A, B> Combined2<A, B> combine(
            Result<A, ValidationError> ra,
            Result<B, ValidationError> rb) {
        return new Combined2<>(ra, rb);
    }

    // combine for 3 to 8 results follows the same pattern

    public record Combined2<A, B>(
            Result<A, ValidationError> ra,
            Result<B, ValidationError> rb) {
        public <R> Result<R, List<ValidationError>> map(
                BiFunction<A, B, R> build) {
            var errors = new ArrayList<ValidationError>();
            if (ra instanceof Failure<A, ValidationError>(var e)) errors.add(e);
            if (rb instanceof Failure<B, ValidationError>(var e)) errors.add(e);

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

And the composite. The value objects already return `ValidationError`, so there is nothing to translate in between:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public static Result<CustomerProfile, IReadOnlyList<ValidationError>> Parse(
    string rawUsername, string rawEmail) =>
    Validation
        .Combine(
            Username.Parse(rawUsername),
            EmailAddress.Parse(rawEmail))
        .Map((u, e) => new CustomerProfile(u, e));

// Input:  ("", "not-an-email")
// Result: Failure([
//     ValidationError("username", "username is empty"),
//     ValidationError("email",    "email has no '@'")
// ])
```

</td>
<td>

```java
public static Result<CustomerProfile, List<ValidationError>> parse(
        String rawUsername, String rawEmail) {
    return Validation
        .combine(
            Username.parse(rawUsername),
            EmailAddress.parse(rawEmail))
        .map(CustomerProfile::new);
}

// Input:  ("", "not-an-email")
// Result: Failure([
//     ValidationError("username", "username is empty"),
//     ValidationError("email",    "email has no '@'")
// ])
```

</td>
</tr>
</table>

Two failures, two entries, one round trip. A record with five fields uses the five-argument `Combine` and a five-parameter lambda; the call site reads the same.

---

## Problem / forces

When a value is built from several independent inputs, four shapes come up:

1. **Throw on the first invalid input.** One error per response, so N invalid fields take N round trips. The failure is also outside the return type, the problem [Axiom 16](axiom-16-result.md#problem--forces) already ruled out.
2. **A separate accumulator.** A `Validate(profile)` method appends messages to a list. It collects everything, but nothing forces the caller to read the list, and `new CustomerProfile(...)` still accepts invalid input: the separate validation step [Axiom 18](axiom-18-value-objects.md#definitions) rejected.
3. **The railway.** Honest, but it stops at the first failure: right for dependent steps, wrong for independent ones.
4. **An accumulating combinator.** Every input is checked, every failure is a value in the return type, and the caller can't reach the built value without handling the list.

Options 1 and 2 break rules already in this book. The real choice is between 3 and 4, and the question that decides it is: does a later check need an earlier one to have passed? If yes, `Bind`. If no, `Combine`.

---

## Why

**1. One round trip per attempt.**
Two invalid fields produce two entries in one response. The user's mental model ("here is the form, tell me everything that's wrong") matches what comes back. Web frameworks already do this for form binding [5]; this moves it into the domain.

**2. Every error says where it came from.**
`ValidationError.Field` names the input that failed. The client can highlight the right form field, and the log can say which CSV row was wrong. A bare string like "username is empty" loses that location as soon as several messages are joined.

**3. It combines with the railway.**
`Combine` doesn't replace `Bind`; one function can use both. `Combine` collects every failure from the independent fields, then `Bind` chains a check that genuinely needs the built value, such as a uniqueness lookup or a rule that compares two fields. This also covers checks that are only *partly* independent: if the email may be empty only for system accounts, check the unconditional rules with `Combine` and the conditional one with `Bind` afterwards.

---

## Trade-offs

- **`Field` is a plain string.** The literal `"username"` written in two places breaks silently in a refactor. Through [Axiom 8](axiom-08-connascence.md)'s lens it is a [Connascence of Meaning](axiom-08-connascence.md#connascence-of-meaning-com): the factory that writes it and every reader that matches on it must agree on what it means. An `enum` turns it into a Connascence of Type, at the cost of one more type per codebase. Plain strings are the default here; the alternatives are an ADR decision.
- **No variadic generics.** C# and Java can't express "any number of differently typed `Result`s", so `Combine` needs one overload per arity, typically 2 to 8. Java also needs its own `Function3` to `Function8`. Beyond eight independent fields, splitting the record into smaller parts is usually better anyway. Libraries ship this ready-made: Vavr's `Validation.combine(...).ap(...)` in Java [3], and helpers such as `Result.Combine` in CSharpFunctionalExtensions [4].
- **Each value object owns its field name.** `Username.Parse` always reports `"username"`. That keeps the composition site clean, but when the same type fills two fields (a billing and a shipping `EmailAddress`), you need either a `Parse(raw, field)` overload or two distinct types. The other direction, returning a `string` as in [Axiom 18](axiom-18-value-objects.md) and adding the field with `MapError` at each composition site, keeps the type reusable but repeats a line at every call.
- **The boundary changes shape.** An HTTP layer that turned one error string into a 400 now turns a list into a 400 with an array. Written once per boundary, it covers every endpoint, and front ends usually expect that shape anyway.

---

## When NOT to

- **One check.** A single `Result` from [Axiom 16](axiom-16-result.md) has nothing to collect. Wrap it in a one-item list only if the response format demands it.
- **Dependent steps.** When step 2 can't run without step 1's result, use the railway; `Combine` would need placeholders for steps that never ran. There is nothing useful to say about a token's expiry when the token didn't even parse.
- **Internal construction.** A private factory whose caller has already checked the input doesn't need field-located errors; nobody will render a form from them. A `Result<T, string>` is enough. Field-located lists are for the boundary, where the list *is* the answer.
- **One-off scripts.** If the operator's loop is "fix and rerun", stopping at the first bad row with a clear message is simpler.

---

## References

[1] **Scott Wlaschin**, *Domain Modeling Made Functional*, Pragmatic Bookshelf, 2018. Also cited in [Axiom 16](axiom-16-result.md), [Axiom 17](axiom-17-result-combinators.md) and [Axiom 19](axiom-19-railway.md). Composes validation the same way in F#: each smart constructor returns a structured error, the call site combines them, and a final function builds the record.
<https://pragprog.com/titles/swdddf/domain-modeling-made-functional/>

[2] **Philip Wadler**, *How to Replace Failure by a List of Successes*, FPCA 1985, LNCS 201. An early paper on returning a *list* of outcomes instead of a single one. Its setting is a parser that returns every possible parse, but the technique (the result carries a list, the combinator merges) is the one this axiom applies to errors.
<https://doi.org/10.1007/3-540-15975-4_33>

[3] **Vavr**, `io.vavr.control.Validation`. Java's off-the-shelf version of this axiom: `Validation.combine(validateName(name), validateAge(age)).ap(Person::new)`, which, unlike chaining, "will continue processing the combining functions, accumulating all errors".
<https://docs.vavr.io/#_validation>

[4] **Vladimir Khorikov**, *CSharpFunctionalExtensions*. Also cited in [Axiom 16](axiom-16-result.md), [Axiom 17](axiom-17-result-combinators.md) and [Axiom 18](axiom-18-value-objects.md). Ships `Result.Combine`, which merges several results into one.
<https://github.com/vkhorikov/CSharpFunctionalExtensions>

[5] **Spring Framework**, *Validation, Data Binding, and Type Conversion* (`BindingResult`), and **ASP.NET Core**, *Model validation* (`ModelStateDictionary`). Both web frameworks collect every field error before calling the controller, because one error per round trip is unacceptable for forms. This axiom moves the same idea into the domain, so one error shape flows from the value object to the response.
<https://docs.spring.io/spring-framework/reference/core/validation.html> · <https://learn.microsoft.com/en-us/aspnet/core/mvc/models/validation>

---

← Previous: [Axiom 19 — Railway](axiom-19-railway.md) · Next: [Axiom 21 — Discriminated unions](axiom-21-discriminated-unions.md) →
