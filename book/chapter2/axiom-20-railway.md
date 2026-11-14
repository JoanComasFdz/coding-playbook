# Axiom 20 — Railway

**Chain `Result`-returning steps with `Bind`, so the success value flows from step to step and the first `Failure` skips the rest. The code reads as the happy path; the failure path is handled by the types.**

- The picture: a track with two rails, *success* and *failure*. Each step is a switch on the success rail. Once a value drops onto the failure rail, it stays there until the end.
- The code: a flat chain of `.Bind(step)` calls, with `.Map(step)` for the steps that can't fail.

[Axiom 18](axiom-18-result-combinators.md) gave us `Bind`, and [Axiom 19](axiom-19-value-objects.md) filled the domain with steps that can fail: every `Parse` returns a `Result`. This axiom is what a function looks like when it puts the two together. Scott Wlaschin named it *railway-oriented programming* [1].

Railway-oriented programming applies to more than `Result` chains, and Wlaschin himself warns against taking it too far [2]. In this book, I use it only for chaining `Result`s.

---

## Definitions

A **railway** is a `Result<T, E>` passed through a sequence of steps, where each step takes the previous step's success value. It is `Bind` and `Map` from [Axiom 18](axiom-18-result-combinators.md#definitions), the small "glue" functions Hughes describes [4], nothing more: the steps run in the order they appear, the first `Failure` skips every step after it, and every step shares one error type.

What this axiom adds is the *picture*: a fluent `.Bind(…).Bind(…).Map(…)` reads as a pipeline. It is the shape the pure core takes when its input needs parsing, its rules can fail, and its job is to produce one final value or one reason why not [3].

---

## Example

Verifying an email-confirmation link: the link carries a user id and a token. The value objects come first ([Axiom 19](axiom-19-value-objects.md)):

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed record Token
{
    public string Value { get; }
    private Token(string value) => Value = value;

    public static Result<Token, string> Parse(string raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
            return new Failure<Token, string>("token is empty");
        if (raw.Length != 32)
            return new Failure<Token, string>("token must be 32 characters");
        return new Success<Token, string>(new Token(raw));
    }
}

public sealed record Payload(
    UserId UserId, DateTimeOffset ExpiresAt)
{
    public static Result<Payload, string> Decode(Token token) =>
        TryDecode(token.Value, out var payload)
            ? new Success<Payload, string>(payload)
            : new Failure<Payload, string>("token payload is malformed");
}
```

</td>
<td>

```java
public final class Token {
    private final String value;
    private Token(String value) { this.value = value; }
    public String value() { return value; }

    public static Result<Token, String> parse(String raw) {
        if (raw == null || raw.isBlank())
            return new Failure<>("token is empty");
        if (raw.length() != 32)
            return new Failure<>("token must be 32 characters");
        return new Success<>(new Token(raw));
    }
    // equals, hashCode and toString as in Axiom 19
}

public record Payload(UserId userId, Instant expiresAt) {
    public static Result<Payload, String> decode(Token token) {
        return tryDecode(token.value())
            .<Result<Payload, String>>map(Success::new)
            .orElseGet(() -> new Failure<>("token payload is malformed"));
    }
}
```

</td>
</tr>
</table>

The railway: four steps, no branching in between.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed record VerifiedUser(User User, DateTimeOffset VerifiedAt);

static Result<Payload, string> CheckNotExpired(
    Payload p, DateTimeOffset now) =>
    p.ExpiresAt > now
        ? new Success<Payload, string>(p)
        : new Failure<Payload, string>($"token expired at {p.ExpiresAt:O}");

static Result<User, string> ConfirmOwner(Payload p, User? found)
{
    if (found is null)
        return new Failure<User, string>("user not found");
    if (found.Id != p.UserId)
        return new Failure<User, string>("token belongs to another user");
    return new Success<User, string>(found);
}

public static Result<VerifiedUser, string> Verify(
    string rawToken, User? found, DateTimeOffset now) =>
    Token.Parse(rawToken)
        .Bind(Payload.Decode)
        .Bind(p => CheckNotExpired(p, now))
        .Bind(p => ConfirmOwner(p, found))
        .Map(u => new VerifiedUser(u, now));
```

</td>
<td>

```java
public record VerifiedUser(User user, Instant verifiedAt) {}

static Result<Payload, String> checkNotExpired(
        Payload p, Instant now) {
    return p.expiresAt().isAfter(now)
        ? new Success<>(p)
        : new Failure<>("token expired at " + p.expiresAt());
}

static Result<User, String> confirmOwner(
        Payload p, Optional<User> found) {
    Objects.requireNonNull(found);
    if (found.isEmpty())
        return new Failure<>("user not found");
    User u = found.orElseThrow();
    if (!u.id().equals(p.userId()))
        return new Failure<>("token belongs to another user");
    return new Success<>(u);
}

public static Result<VerifiedUser, String> verify(
        String rawToken, Optional<User> found, Instant now) {
    return Token.parse(rawToken)
        .flatMap(Payload::decode)
        .flatMap(p -> checkNotExpired(p, now))
        .flatMap(p -> confirmOwner(p, found))
        .map(u -> new VerifiedUser(u, now));
}
```

</td>
</tr>
</table>

`Verify` reads as what happens when everything works. If `Token.Parse` fails because the token is the wrong length, no later step runs, and "token must be 32 characters" comes out as the result. If the token has expired, `ConfirmOwner` never runs.

`now` and `found` are passed in as values, not read inside `Verify`, which keeps it pure ([Axiom 6](axiom-06-pure-functions.md)). (Java takes the `Optional` the lookup returns, for the reasons in [Axiom 17](axiom-17-result.md#why-optional-as-a-parameter).)

### In the shell

The use case that runs the railway is the sandwich from [Axiom 13](axiom-13-impureim.md): gather, decide, act.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed record HttpResponse(int Status, string Body);

public HttpResponse HandleVerify(UserId userId, string rawToken)
{
    var found = users.Find(userId);   // gather
    var now   = clock.GetUtcNow();    // gather

    var result = Verify(rawToken, found, now);   // decide

    return result.Match(              // act: shape the response
        success: v => new HttpResponse(200, $"verified {v.User.Name}"),
        failure: e => new HttpResponse(401, e));
}
```

</td>
<td>

```java
public record HttpResponse(int status, String body) {}

public HttpResponse handleVerify(UserId userId, String rawToken) {
    Optional<User> found = users.find(userId);   // gather
    Instant now = clock.instant();               // gather

    var result = verify(rawToken, found, now);   // decide

    return result.match(                         // act: shape the response
        v -> new HttpResponse(200, "verified " + v.user().name()),
        e -> new HttpResponse(401, e));
}
```

</td>
</tr>
</table>

Everything [Axiom 17's synthesis](axiom-17-result.md#the-first-synthesis) showed still holds here. What is new is the middle: the decision is now a chain of named steps, each one a parse-don't-validate step from [Axiom 19](axiom-19-value-objects.md), joined by `Bind` and `Map` from [Axiom 18](axiom-18-result-combinators.md). The shell has one `Result` to look at and two branches to write.

---

## Problem / forces

[Axiom 18](axiom-18-result-combinators.md#problem--forces) compared checking each step by hand with throwing and with combinators. At the scale of a whole use case, two more ways to lose the picture appear:

- **Nested matches, one per step.** Each step adds a level of indentation (the [arrow anti-pattern](https://blog.codinghorror.com/flattening-arrow-code/)), and the propagation rule is written again at every level.
- **One giant lambda.** The chain stays technically correct, but the steps are never extracted, so the closures nest and the pipeline disappears inside them. Extract each step into a named function and the picture comes back.

Checking by hand still has its place when one step genuinely needs different handling (see *When NOT to*). For runs of steps that all follow the same rule, which is most use cases in a domain built on value objects, the railway is the default.

---

## Why

**1. The code reads as the happy path.**
A reader scanning `Verify` sees four named steps in the order they happen. The failure path is in the types (every step returns a `Result`), but the text on the page is the success path. The rule the code enforces is what the reader sees; the bookkeeping stays below the surface.

**2. The first failure is the reason.**
The chain stops at the first step that refuses, so the error it returns names that step: "token expired", not a generic failure somewhere in the middle. The steps after it never ran, so they never had to cope with input that was already wrong.

---

## Trade-offs

- **Stopping at the first failure is a choice.** It is right when each step needs the previous step's success to mean anything. It is wrong when several checks are *independent* and the caller wants to hear about all the failures at once. That is a different shape, which a later axiom develops.
- **The costs of combinators.** One error type per chain, stack traces that show a lambda, and type inference that sometimes needs help: see [Axiom 18](axiom-18-result-combinators.md#trade-offs). In a railway, a clear error message offsets the stack-trace cost, because it already says which step refused.
- **Long chains drift into soup.** Seven steps with three inline lambdas lose the picture. Give each step a name: the chain becomes `Decode`, `CheckNotExpired`, `ConfirmOwner`, and reads again. A lambda that captures one value (like `now`) is fine; one that captures four is a step that wants to be a function with parameters.

---

## When NOT to

- **When the caller needs every failure, not just the first.** A form with both a bad username and a bad email should report both at once, instead of refusing one, sending the user back, and refusing the other on the next submit. A railway can't do that (see *Trade-offs*).
- **When the failure is not an expected outcome.** `Result` is for the normal "no" answers of the domain. Bugs, broken invariants and most I/O failures belong to the exceptions and the fail-fast rung of [Axiom 17's ladder](axiom-17-result.md#the-ladder-eliminate-then-return-then-fail-fast). Wlaschin makes the same point: "It's only for expected control-flow, not for unexpected situations." [2]
- **The combinators' own limits.** A single step, a step that needs to recover from a specific failure, and impure steps don't belong in a chain either (see [Axiom 18](axiom-18-result-combinators.md#when-not-to)).

---

## References

[1] **Scott Wlaschin**, *Railway Oriented Programming*, talk and slides, NDC Oslo and NDC London, 2014. Names the metaphor: two rails, with `Bind` as the switch on the success rail.
<https://fsharpforfunandprofit.com/rop/>

[2] **Scott Wlaschin**, *Against Railway-Oriented Programming (when used thoughtlessly)*, fsharpforfunandprofit.com, 2019. When not to use `Result`: diagnostics, I/O, failing fast, performance, and errors nobody cares about. "Result is a tool for domain modeling, so if the domain model doesn't need it, don't use it."
<https://fsharpforfunandprofit.com/posts/against-railway-oriented-programming/>

[3] **Scott Wlaschin**, *Domain Modeling Made Functional*, Pragmatic Bookshelf, 2018. Also cited in [Axiom 17](axiom-17-result.md) and [Axiom 18](axiom-18-result-combinators.md). Its workflows chain smart constructors into pipelines of this shape.
<https://pragprog.com/titles/swdddf/domain-modeling-made-functional/>

[4] **John Hughes**, *Why Functional Programming Matters*, in *Research Topics in Functional Programming*, Addison-Wesley, 1990. Also cited in [Axiom 11](axiom-11-higher-order-functions.md) and [Axiom 18](axiom-18-result-combinators.md). Small steps, with combinators as the glue: the railway is that argument applied to steps that can fail.
<https://www.cs.kent.ac.uk/people/staff/dat/miranda/whyfp90.pdf>

---

← Previous: [Axiom 19 — Value objects](axiom-19-value-objects.md) · Next: [Axiom 21 — Validation](axiom-21-validation.md) →
