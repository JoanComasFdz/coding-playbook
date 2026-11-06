# Axiom 16 — Result

**When a function can succeed or fail, return both outcomes as values: `Result<T, E>`, with a `Success<T>` or a `Failure<E>`. Never throw for an expected failure, and never hide it behind a sentinel.**

- `Success` carries the answer the caller wanted. `Failure` carries the reason it didn't get it.
- Rust calls the same pair `Ok` and `Err` [1].

[Axiom 14](axiom-14-either.md) gave two-outcome results a shape, and said that in practice I reach for a type whose cases have names. Result is that type for the most common pair: it worked, or it didn't. With [Axiom 15](axiom-15-unit.md) it covers every case: success with a value, success with nothing to return (`Result<Unit, E>`), or failure with a reason.

Through [Axiom 8](axiom-08-connascence.md)'s lens, Result turns a [Connascence of Meaning](axiom-08-connascence.md#connascence-of-meaning-com) (error codes, sentinels and exceptions the caller must just *know* about) into a [Connascence of Type](axiom-08-connascence.md#connascence-of-type-cot). Unlike `Either`, the names leave no convention behind: nobody has to remember which side is the error.

---

## Definitions

A Result is an [Either](axiom-14-either.md#definitions) with two changes:

- **The cases have names.** `Success` holds the answer and `Failure` holds the reason, so the left-is-error convention disappears.
- **The error is a value.** `E` is data the caller can read, compare, store, log or transform, not an event that unwinds the stack.

`E` can be anything the caller needs to act on: a `string` ("user not found"), a record, or a closed set of named failure cases. Which one to use is a contextual choice, not a principle (see *Trade-offs*).

---

## Example

The type, with a `Match` method ([Axiom 11](axiom-11-pattern-matching.md#the-method-form)) so callers don't repeat the generic arguments on every branch:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public abstract record Result<T, E>
{
    public TOut Match<TOut>(
        Func<T, TOut> success, Func<E, TOut> failure) =>
        this switch
        {
            Success<T, E> s => success(s.Value),
            Failure<T, E> f => failure(f.Error),
            _ => throw new UnreachableException()
        };
}
public sealed record Success<T, E>(T Value) : Result<T, E>;
public sealed record Failure<T, E>(E Error) : Result<T, E>;
```

</td>
<td>

```java
public sealed interface Result<T, E> permits Success, Failure {
    default <R> R match(
            Function<T, R> success, Function<E, R> failure) {
        return switch (this) {
            case Success<T, E> s -> success.apply(s.value());
            case Failure<T, E> f -> failure.apply(f.error());
        };
    }
}
public record Success<T, E>(T value) implements Result<T, E> {}
public record Failure<T, E>(E error) implements Result<T, E> {}
```

</td>
</tr>
</table>

A function that can fail in two ways, and a caller that handles both outcomes:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
Result<int, string> ParseAge(string input)
{
    if (!int.TryParse(input, out var age))
        return new Failure<int, string>("not a number");
    if (age < 0)
        return new Failure<int, string>("negative");
    return new Success<int, string>(age);
}

var result = ParseAge("42");
var message = result.Match(
    success: age   => $"Age {age}",
    failure: error => $"Invalid age: {error}");
```

</td>
<td>

```java
Result<Integer, String> parseAge(String input) {
    int age;
    try {
        age = Integer.parseInt(input);
    } catch (NumberFormatException e) {
        return new Failure<>("not a number");
    }
    if (age < 0)
        return new Failure<>("negative");
    return new Success<>(age);
}

var result = parseAge("42");
String message = result.match(
    age   -> "Age " + age,
    error -> "Invalid age: " + error);
```

</td>
</tr>
</table>

Both failures are in the return type. The C# version turns `TryParse`'s flag into a value; the Java version catches `parseInt`'s exception and turns it into one. Either way, the conversion happens once, inside `ParseAge`, and no caller sees a flag or an exception.

---

## The first synthesis

Result is the first point where most of the axioms so far fit into one piece of code. Here is a login, end to end, using the `Result` type above:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// ── Data: immutable records ──
public sealed record Credentials(
    string Username, string Password);
public sealed record User(
    string Username, string PasswordHash,
    DateTimeOffset? LockedUntil);

// ── Pure core: same inputs, same output ──
Result<User, string> Decide(
    User? found, string password, DateTimeOffset now) =>
    found switch
    {
        null => new Failure<User, string>("user not found"),
        User { LockedUntil: { } until } when until > now
            => new Failure<User, string>($"locked until {until}"),
        User u when !Verify(password, u.PasswordHash)
            => new Failure<User, string>("wrong password"),
        User u => new Success<User, string>(u)
    };

// ── Impure shell: effects at the edges ──
Unit Login(Credentials credentials)
{
    var found = users.Find(credentials.Username); // gather
    var now   = clock.GetUtcNow();                // gather

    var decision = Decide(found, credentials.Password, now);

    return decision.Match(                        // act
        success: user  => sessions.Start(user),
        failure: error => audit.LoginFailed(
                              credentials.Username, error));
}
```

</td>
<td>

```java
// ── Data: immutable records ──
public record Credentials(
    String username, String password) {}
public record User(
    String username, String passwordHash,
    @Nullable Instant lockedUntil) {}

// ── Pure core: same inputs, same output ──
Result<User, String> decide(
        @Nullable User found, String password, Instant now) {
    return switch (found) {
        case null -> new Failure<>("user not found");
        case User u when u.lockedUntil() != null
                      && u.lockedUntil().isAfter(now)
            -> new Failure<>("locked until " + u.lockedUntil());
        case User u when !verify(password, u.passwordHash())
            -> new Failure<>("wrong password");
        case User u -> new Success<>(u);
    };
}

// ── Impure shell: effects at the edges ──
Unit login(Credentials credentials) {
    User found = users.find(credentials.username())
                      .orElse(null);              // gather
    Instant now = clock.instant();                // gather

    var decision = decide(found, credentials.password(), now);

    return decision.match(                        // act
        user  -> sessions.start(user),
        error -> audit.loginFailed(
                     credentials.username(), error));
}
```

</td>
</tr>
</table>

Read it from top to bottom, and the earlier axioms are all visible:

- **Data apart from behavior, and immutable** ([Axiom 1](axiom-01-data-is-not-behavior.md), [Axiom 2](axiom-02-immutability.md)): `Credentials` and `User` are records; the functions live elsewhere.
- **Effects named and kept at the edges** ([Axiom 3](axiom-03-side-effects.md), [Axiom 4](axiom-04-impure-functions.md)): the database read, the clock, the session start and the audit write are the only effects, and all of them are in `Login`.
- **A pure decision** ([Axiom 5](axiom-05-pure-functions.md)): the clock comes in as a value, so `Decide` is tested with plain values. Starting the session (which issues a random token) stays in the shell.
- **An honest, total signature** ([Axiom 6](axiom-06-honest-total-signatures.md)): every outcome of `Decide` is in its return type.
- **One reason to change** ([Axiom 7](axiom-07-cohesion.md)): `Decide` changes when the login rules change; `Login` changes when the plumbing does.
- **Functions as arguments** ([Axiom 9](axiom-09-first-class-functions.md), [Axiom 10](axiom-10-higher-order-functions.md)): `Match` takes one function per outcome.
- **Pattern matching** ([Axiom 11](axiom-11-pattern-matching.md)): the core uses a `switch` on the lookup, and the shell uses `Match` on the decision (see [`switch` or `Match`?](axiom-11-pattern-matching.md#switch-or-match)).
- **The Impureim sandwich** ([Axiom 12](axiom-12-impureim.md)): gather, decide, act.
- **Absence as a value** ([Axiom 13](axiom-13-maybe.md)): the missing user reaches the core as a nullable value, and the `switch` has to handle it. (In Java the repository returns an `Optional`, and the shell unwraps it, because `Optional` stays out of parameters.)
- **Either with names** ([Axiom 14](axiom-14-either.md)): `Success` and `Failure` say what `Right` and `Left` only imply.
- **Unit** ([Axiom 15](axiom-15-unit.md)): `Match` needs both branches to return the same type. Starting a session and writing an audit entry have nothing to return, so both return `Unit`.

Every failure is a value, every decision is a function, and every effect sits at a named edge. To know why a login failed, you read `Decide`.

---

## Problem / forces

[Axiom 6](axiom-06-honest-total-signatures.md#definitions) already covers why throwing for an expected outcome makes the signature lie. For success-or-failure that lie is the default, so it is worth seeing why.

Throwing is the shortest path to working code. `throw` is one keyword. The success path stays straight, and the error path seems to disappear by unwinding the stack. Several layers deep, "I'll just throw" makes the code in front of you work, and every caller inherits a control flow the types don't name. The cost shows up later:

- **"Wrong password" is not exceptional.** Like "no user found" in [Axiom 13](axiom-13-maybe.md#24--an-exception-for-not-found), it is a normal answer to the question the function was asked. Delivering it by unwinding the stack is slow (the exception captures a stack trace) and noisy (every layer in between sees a failure that isn't its concern).
- **Checked exceptions only help in Java, and only partly.** They put the failure in the signature, but most code uses unchecked exceptions, and C# has no checked exceptions at all.
- **Mixed channels.** When some failures are thrown and others come back as a `bool`, a sentinel or a `null`, the caller has two error channels to read for one function, and the compiler enforces neither.

---

## Why

**1. The names carry the meaning.**
`Result<Token, AuthFailure>` reads as "a `Token`, or an `AuthFailure`". The same type written as an `Either` makes every reader remember which side is which. Naming the cases moves that knowledge from the reader's head into the type.

**2. The error is information the caller can use.**
A typed error lets the caller branch on `UserNotFound`, `WrongPassword` or `AccountLocked` as values, with the same pattern matching it uses for everything else [2]. The thrown alternative either puts all three into one `AuthenticationException` (and callers branch on its message) or invents one exception type per case (and every caller writes three `catch` blocks).

**3. It composes like any value.**
A function that returns a `Result` can be stored, passed, put in a list and chained, like the `Either` in [Axiom 14](axiom-14-either.md) (see its *Why*, point 3). A throwing function behaves differently depending on which `try`/`catch` surrounds it.

---

## The ladder: eliminate, then return, then fail fast

Result is the *second* move, not the first. This book's north star (as simple as possible, then as honest as possible, then as robust as possible) gives three rungs for any possible error, and Result is the middle one:

1. **Eliminate it.** First ask whether the error can be designed away. Make the function total ([Axiom 6](axiom-06-honest-total-signatures.md)): narrow the input until the bad value can't be built, or widen the operation until every input has an answer. An error that can't happen needs no `Result`, no handler and no test. (Later in this chapter, the same move works on whole values, on the shape of records, and on the order of calls.)
2. **Return it honestly.** When the failure is a normal outcome of the function's own logic (a wrong password, a missing row, malformed input, a transient network failure), it belongs in the return type as a value. This is the rung for `Result`.
3. **Fail fast.** When the "failure" can only mean a bug or a broken runtime (a violated invariant, an impossible state, out of memory), throw and stop, as close to the cause as possible [4]. Let a higher layer log it. Wrapping a bug in a `Result` lets a caller handle it and carry on, which hides it.

Go down the rungs in order. Wrapping in a `Result` something you could have eliminated still works, so stopping one rung early is fine. The mistakes are skipping rung 1, and jumping to rung 3 to throw what rung 2 should have returned.

Where the line between rungs 2 and 3 falls depends on the context. "The database is unreachable" is fatal for a batch job that will simply be retried, and a normal outcome for a web service that wants to answer with a 503. Decide it per module, not per function.

---

## Trade-offs

- **What should `E` be?** A `string` is cheapest and reads well in small code, but the caller can't branch on it without parsing it. A record or a closed set of named failures is honest about the cases, but ties the producer to what its callers need to branch on. Pick one convention per module and record it in an ADR, rather than deciding again for every function.
- **The rest of the world throws.** The standard library, ORMs, HTTP clients and JSON parsers all throw. Result doesn't remove exceptions; it contains them. Catch them at the lowest layer that wraps a throwing API, turn the expected cases into a `Failure`, and let everything above it work with Results. Libraries such as CSharpFunctionalExtensions ship a ready-made `Result` for C# [3].
- **The costs of Either.** More code at the producer, and one small allocation per call (see [Axiom 14](axiom-14-either.md#trade-offs)).

---

## When NOT to

- **When the failure is a bug.** Programmer errors, broken invariants and a runtime that can't be trusted are what exceptions are for (see *The ladder*, rung 3). A `Result` whose error is "out of memory" pretends the program can carry on.
- **Inside a helper that can't fail.** A private function whose only caller already guarantees its inputs doesn't need a `Result`. Adding one "for consistency" is noise.
- **At a framework boundary that expects exceptions.** Some frameworks turn exceptions into HTTP responses or retries. Keep `Result` inside your own code and convert it into whatever the framework expects at that one seam.

---

## References

[1] **Rust** `std::result::Result<T, E>`. Rust made a named pair, `Ok` and `Err`, its standard error-handling type. Haskell expresses the same idea with `Either` and the left-is-error convention ([Axiom 14](axiom-14-either.md)).
<https://doc.rust-lang.org/std/result/enum.Result.html>

[2] **Scott Wlaschin**, *Domain Modeling Made Functional*, Pragmatic Bookshelf, 2018. Its chapter on working with errors makes the case for errors as values, with each failure case named in the domain's words.
<https://pragprog.com/titles/swdddf/domain-modeling-made-functional/>

[3] **Vladimir Khorikov**, *CSharpFunctionalExtensions*. A small C# library whose `Result` and `Result<T, E>` types are close to the ones in this book's examples.
<https://github.com/vkhorikov/CSharpFunctionalExtensions>

[4] **James Shore**, *Fail Fast*, IEEE Software 21(5), 2004. Stop immediately on a programmer error or a broken invariant, so the defect shows up where it starts instead of several frames later disguised as a normal value.

---

← Previous: [Axiom 15 — Unit](axiom-15-unit.md) · Next: [Axiom 17 — Result combinators](axiom-17-result-combinators.md) →
