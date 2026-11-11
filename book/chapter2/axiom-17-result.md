# Axiom 17 — Result

**When a function can succeed or fail, return both outcomes as values: `Result<T, E>`, with a `Success<T>` or a `Failure<E>`. Never throw for an expected failure, and never hide it behind a sentinel.**

- `Success` carries the answer the caller wanted. `Failure` carries the reason it didn't get it.
- Rust calls the same pair `Ok` and `Err` [1].

[Axiom 15](axiom-15-either.md) gave two-outcome results a shape, and said that in practice I reach for a type whose cases have names. Result is that type for the most common pair: it worked, or it didn't. With [Axiom 16](axiom-16-unit.md) it covers every case: success with a value, success with nothing to return (`Result<Unit, E>`), or failure with a reason. It is [Axiom 1](axiom-01-explicit-over-implicit.md)'s explicitness applied to failure: the outcome a throwing signature hides.

Through [Axiom 9](axiom-09-connascence.md)'s lens, Result turns a [Connascence of Meaning](axiom-09-connascence.md#connascence-of-meaning-com) (error codes, sentinels and exceptions the caller must just *know* about) into a [Connascence of Type](axiom-09-connascence.md#connascence-of-type-cot). Unlike `Either`, the names leave no convention behind: nobody has to remember which side is the error.

---

## Definitions

A Result is an [Either](axiom-15-either.md#definitions) with two changes:

- **The cases have names.** `Success` holds the answer and `Failure` holds the reason, so the left-is-error convention disappears.
- **The error is a value.** `E` is data the caller can read, compare, store, log or transform, not an event that unwinds the stack.

`E` can be anything the caller needs to act on: a `string` ("user not found"), a record, or a closed set of named failure cases. Which one to use is a contextual choice, not a principle (see *Trade-offs*).

---

## Example

The type, and a function that can fail in two ways:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public abstract record Result<T, E>;
public sealed record Success<T, E>(T Value) : Result<T, E>;
public sealed record Failure<T, E>(E Error) : Result<T, E>;

Result<int, string> ParseAge(string input)
{
    if (!int.TryParse(input, out var age))
        return new Failure<int, string>("not a number");
    if (age < 0)
        return new Failure<int, string>("negative");
    return new Success<int, string>(age);
}

var result = ParseAge("42");
var message = result switch
{
    Success<int, string> s => $"Age {s.Value}",
    Failure<int, string> f => $"Invalid age: {f.Error}",
    _ => throw new UnreachableException()
};
```

</td>
<td>

```java
public sealed interface Result<T, E> permits Success, Failure {}
public record Success<T, E>(T value) implements Result<T, E> {}
public record Failure<T, E>(E error) implements Result<T, E> {}

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
String message = switch (result) {
    case Success<Integer, String> s -> "Age " + s.value();
    case Failure<Integer, String> f -> "Invalid age: " + f.error();
};
```

</td>
</tr>
</table>

Both failures are in the return type. The C# version turns `TryParse`'s flag into a value; the Java version catches `parseInt`'s exception and turns it into one. Either way, the conversion happens once, inside `ParseAge`, and no caller sees a flag or an exception. The caller handles both outcomes in one `switch` ([Axiom 12](axiom-12-pattern-matching.md)).

### With `Match`

Every branch of that `switch` repeats the generic arguments (`Success<int, string>`), which gets tiresome as the types grow. [Axiom 12](axiom-12-pattern-matching.md#the-method-form) showed the alternative: put the case analysis on the type as a `Match` method, and let each caller pass one function per case. For `Result`:

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

var message = result.Match(
    success: age   => $"Age {age}",
    failure: error => $"Invalid age: {error}");
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

String message = result.match(
    age   -> "Age " + age,
    error -> "Invalid age: " + error);
```

</td>
</tr>
</table>

Same caller, same result. Which form to use is the choice in [switch or Match?](axiom-12-pattern-matching.md#switch-or-match).

### With `Handle`

`Match` returns a value, so both branches must produce one. That is right when the result flows on: it is returned, chained or combined, and when there is nothing to say, the value is `Unit` ([Axiom 16](axiom-16-unit.md)). But often a branch is where the work ends: write the row, record the error. Nothing flows on, and a `return Unit.Value;` in each branch would say nothing. For that case, `Result` gets a second method that takes one action per case and returns nothing:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public abstract record Result<T, E>
{
    // Match as above, plus:
    public void Handle(
        Action<T> success, Action<E> failure)
    {
        switch (this)
        {
            case Success<T, E> s: success(s.Value); break;
            case Failure<T, E> f: failure(f.Error); break;
            default: throw new UnreachableException();
        }
    }
}

result.Handle(
    success: age   => Console.WriteLine($"Age {age}"),
    failure: error => Console.WriteLine($"Invalid age: {error}"));
```

</td>
<td>

```java
public sealed interface Result<T, E> permits Success, Failure {
    // match as above, plus:
    default void handle(
            Consumer<T> success, Consumer<E> failure) {
        switch (this) {
            case Success<T, E> s -> success.accept(s.value());
            case Failure<T, E> f -> failure.accept(f.error());
        }
    }
}

result.handle(
    age   -> System.out.println("Age " + age),
    error -> System.out.println("Invalid age: " + error));
```

</td>
</tr>
</table>

The rule: **`Match` when the result flows on, `Handle` when the branch ends the work.** It is a separate name on purpose, not a `Match` overload: a lambda like `c => list.Add(c)` fits both a function and an action, so C# would pick the function version and Java would refuse to choose.

The pair is not new. C# libraries such as OneOf [7] and ErrorOr [8] offer `Match` for values and `Switch` for actions, and Java's `Optional` has `ifPresentOrElse` for the same job [5]. This book names the void form `Handle`, because `switch` is a reserved word in Java and one name should work in both languages.

---

## The first synthesis

Result is the first point where most of the axioms so far fit into one piece of code. Here is a login, end to end, using the `Result` type above (with `Handle`):

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
void Login(Credentials credentials)
{
    var found = users.Find(credentials.Username); // gather
    var now   = clock.GetUtcNow();                // gather

    var decision = Decide(found, credentials.Password, now);

    decision.Handle(                              // act
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
        Optional<User> found, String password, Instant now) {
    Objects.requireNonNull(found);
    if (found.isEmpty())
        return new Failure<>("user not found");
    User u = found.orElseThrow();
    if (u.lockedUntil() != null && u.lockedUntil().isAfter(now))
        return new Failure<>("locked until " + u.lockedUntil());
    if (!verify(password, u.passwordHash()))
        return new Failure<>("wrong password");
    return new Success<>(u);
}

// ── Impure shell: effects at the edges ──
void login(Credentials credentials) {
    Optional<User> found =
        users.find(credentials.username());       // gather
    Instant now = clock.instant();                // gather

    var decision = decide(found, credentials.password(), now);

    decision.handle(                              // act
        user  -> sessions.start(user),
        error -> audit.loginFailed(
                     credentials.username(), error));
}
```

</td>
</tr>
</table>

Read it from top to bottom, and the earlier axioms are all visible:

- **Data apart from behavior, and immutable** ([Axiom 2](axiom-02-data-is-not-behavior.md), [Axiom 3](axiom-03-immutability.md)): `Credentials` and `User` are records; the functions live elsewhere.
- **Effects named and kept at the edges** ([Axiom 4](axiom-04-side-effects.md), [Axiom 5](axiom-05-impure-functions.md)): the database read, the clock, the session start and the audit write are the only effects, and all of them are in `Login`.
- **A pure decision** ([Axiom 6](axiom-06-pure-functions.md)): the clock comes in as a value, so `Decide` is tested with plain values. Starting the session (which issues a random token) stays in the shell.
- **An honest, total signature** ([Axiom 7](axiom-07-honest-total-signatures.md)): every outcome of `Decide` is in its return type.
- **One reason to change** ([Axiom 8](axiom-08-cohesion.md)): `Decide` changes when the login rules change; `Login` changes when the plumbing does.
- **Functions as arguments** ([Axiom 10](axiom-10-first-class-functions.md), [Axiom 11](axiom-11-higher-order-functions.md)): `Handle` takes one action per outcome.
- **Pattern matching** ([Axiom 12](axiom-12-pattern-matching.md)): the C# core uses a `switch` on the lookup, and the shell uses `Handle` on the decision (see [switch or Match?](axiom-12-pattern-matching.md#switch-or-match)).
- **The Impureim sandwich** ([Axiom 13](axiom-13-impureim.md)): gather, decide, act.
- **Absence as a value** ([Axiom 14](axiom-14-maybe.md)): the missing user reaches the core as a value it has to handle: `User?` in C#, `Optional<User>` in Java (see *Why `Optional` as a parameter* below).
- **Either with names** ([Axiom 15](axiom-15-either.md)): `Success` and `Failure` say what `Right` and `Left` only imply.

Every failure is a value, every decision is a function, and every effect sits at a named edge. To know why a login failed, you read `Decide`.

### Why `Optional` as a parameter

[Axiom 14](axiom-14-maybe.md#when-not-to) keeps `Optional` out of parameters, following Java's own guidance: it is "primarily intended for use as a method return type" [5]. The Java `decide` takes one anyway:

- **The caller already has one.** `users.find` returns an `Optional`. Unwrapping it to `null` just to pass it on turns an honest value back into a dishonest one.
- **`javac` checks it.** `@Nullable` is only checked by outside tools; `Optional` is checked by the compiler ([Axiom 14](axiom-14-maybe.md#definitions)). In the pure core, where honesty matters most, take the stronger check.
- **The usual objections are about public APIs.** Callers having to wrap values they already hold, and overloads being cleaner, don't apply to a core function whose only caller is its own shell.
- **The strongest objection has a fix.** A caller can pass a `null` `Optional`, which gives three states instead of two. `Objects.requireNonNull(found)` closes that, at the cost of one line [6]. It throws, and that is correct: a `null` `Optional` can only be a bug, which is [rung 3 of the ladder](#the-ladder-eliminate-then-return-then-fail-fast), not an outcome to return.

The trade-off, for now: the code is a little longer. Java can't `switch` on what's inside an `Optional`, so the core uses an early return and `orElseThrow()` instead of the `case null` switch that mirrors C#. C# needs none of this: `User?` already is its Maybe.

---

## Problem / forces

[Axiom 7](axiom-07-honest-total-signatures.md#definitions) already covers why throwing for an expected outcome makes the signature lie. For success-or-failure that lie is the default, so it is worth seeing why.

Throwing is the shortest path to working code. `throw` is one keyword. The success path stays straight, and the error path seems to disappear by unwinding the stack. Several layers deep, "I'll just throw" makes the code in front of you work, and every caller inherits a control flow the types don't name. The cost shows up later:

- **"Wrong password" is not exceptional.** Like "no user found" in [Axiom 14](axiom-14-maybe.md#24--an-exception-for-not-found), it is a normal answer to the question the function was asked. Delivering it by unwinding the stack is slow (the exception captures a stack trace) and noisy (every layer in between sees a failure that isn't its concern).
- **Checked exceptions only help in Java, and only partly.** They put the failure in the signature, but most code uses unchecked exceptions, and C# has no checked exceptions at all.
- **Mixed channels.** When some failures are thrown and others come back as a `bool`, a sentinel or a `null`, the caller has two error channels to read for one function, and the compiler enforces neither.

---

## Why

**1. The names carry the meaning.**
`Result<Token, AuthFailure>` reads as "a `Token`, or an `AuthFailure`". The same type written as an `Either` makes every reader remember which side is which. Naming the cases moves that knowledge from the reader's head into the type.

**2. The error is information the caller can use.**
A typed error lets the caller branch on `UserNotFound`, `WrongPassword` or `AccountLocked` as values, with the same pattern matching it uses for everything else [2]. The thrown alternative either puts all three into one `AuthenticationException` (and callers branch on its message) or invents one exception type per case (and every caller writes three `catch` blocks).

**3. It composes like any value.**
A function that returns a `Result` can be stored, passed, put in a list and chained, like the `Either` in [Axiom 15](axiom-15-either.md) (see its *Why*, point 3). A throwing function behaves differently depending on which `try`/`catch` surrounds it.

---

## The ladder: eliminate, then return, then fail fast

Result is the *second* move, not the first. This book's north star (as simple as possible, then as honest as possible, then as robust as possible) gives three rungs for any possible error, and Result is the middle one:

1. **Eliminate it.** First ask whether the error can be designed away. Make the function total ([Axiom 7](axiom-07-honest-total-signatures.md)): narrow the input until the bad value can't be built, or widen the operation until every input has an answer. An error that can't happen needs no `Result`, no handler and no test. (Later in this chapter, the same move works on whole values, on the shape of records, and on the order of calls.)
2. **Return it honestly.** When the failure is a normal outcome of the function's own logic (a wrong password, a missing row, malformed input, a transient network failure), it belongs in the return type as a value. This is the rung for `Result`.
3. **Fail fast.** When the "failure" can only mean a bug or a broken runtime (a violated invariant, an impossible state, out of memory), throw and stop, as close to the cause as possible [4]. Let a higher layer log it. Wrapping a bug in a `Result` lets a caller handle it and carry on, which hides it.

Go down the rungs in order. Wrapping in a `Result` something you could have eliminated still works, so stopping one rung early is fine. The mistakes are skipping rung 1, and jumping to rung 3 to throw what rung 2 should have returned.

Where the line between rungs 2 and 3 falls depends on the context. "The database is unreachable" is fatal for a batch job that will simply be retried, and a normal outcome for a web service that wants to answer with a 503. Decide it per module, not per function.

---

## Trade-offs

- **What should `E` be?** A `string` is cheapest and reads well in small code, but the caller can't branch on it without parsing it. A record or a closed set of named failures is honest about the cases, but ties the producer to what its callers need to branch on. Pick one convention per module and record it in an ADR, rather than deciding again for every function.
- **The rest of the world throws.** The standard library, ORMs, HTTP clients and JSON parsers all throw. Result doesn't remove exceptions; it contains them. Catch them at the lowest layer that wraps a throwing API, turn the expected cases into a `Failure`, and let everything above it work with Results. Libraries such as CSharpFunctionalExtensions ship a ready-made `Result` for C# [3].
- **The costs of Either.** More code at the producer, and one small allocation per call (see [Axiom 15](axiom-15-either.md#trade-offs)).

---

## When NOT to

- **When the failure is a bug.** Programmer errors, broken invariants and a runtime that can't be trusted are what exceptions are for (see *The ladder*, rung 3). A `Result` whose error is "out of memory" pretends the program can carry on.
- **Inside a helper that can't fail.** A private function whose only caller already guarantees its inputs doesn't need a `Result`. Adding one "for consistency" is noise.
- **At a framework boundary that expects exceptions.** Some frameworks turn exceptions into HTTP responses or retries. Keep `Result` inside your own code and convert it into whatever the framework expects at that one seam.

---

## References

[1] **Rust** `std::result::Result<T, E>`. Rust made a named pair, `Ok` and `Err`, its standard error-handling type. Haskell expresses the same idea with `Either` and the left-is-error convention ([Axiom 15](axiom-15-either.md)).
<https://doc.rust-lang.org/std/result/enum.Result.html>

[2] **Scott Wlaschin**, *Domain Modeling Made Functional*, Pragmatic Bookshelf, 2018. Its chapter on working with errors makes the case for errors as values, with each failure case named in the domain's words.
<https://pragprog.com/titles/swdddf/domain-modeling-made-functional/>

[3] **Vladimir Khorikov**, *CSharpFunctionalExtensions*. A small C# library whose `Result` and `Result<T, E>` types are close to the ones in this book's examples.
<https://github.com/vkhorikov/CSharpFunctionalExtensions>

[4] **James Shore**, *Fail Fast*, IEEE Software 21(5), 2004. Stop immediately on a programmer error or a broken invariant, so the defect shows up where it starts instead of several frames later disguised as a normal value.

[5] **`java.util.Optional` API note**, Java SE 21 documentation. Also cited in [Axiom 14](axiom-14-maybe.md). Brian Goetz puts it more strongly, as quoted by Nicolai Parlog: "You should almost never use it as a field of something or a method parameter." The same page documents `ifPresentOrElse` (since Java 9), which "performs the given action with the value, otherwise performs the given empty-based action": the void form beside `map` and `orElse`.
<https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Optional.html> · <https://nipafx.dev/stephen-colebourne-java-optional-strict-approach/>

[6] **Nicolai Parlog**, *Java 8 SE Optional, a strict approach* and *Where to use Optional* (Inside Java Newscast #19). Parlog, a Java developer advocate at Oracle, is "decidedly in the Optional-everywhere camp", accepts `Optional` parameters, and rejects a `null` `Optional` with `requireNonNull`. He also lists the camps that disagree, and calls "return values only" a sound default for teams that need one shared rule.
<https://nipafx.dev/stephen-colebourne-java-optional-strict-approach/> · <https://nipafx.dev/inside-java-newscast-19/>

[7] **OneOf** (C#). "You use the `TOut Match(Func<T0, TOut> f0, ... Func<Tn,TOut> fn)` method to get a value out", and "There is also a .Switch method, for when you aren't returning a value."
<https://github.com/mcintyre321/OneOf>

[8] **ErrorOr** (C#), a Result-style library. "The `Match` method receives two functions, `onValue` and `onError`", and "The `Switch` method receives two actions, `onValue` and `onError`."
<https://github.com/amantinband/error-or>

---

← Previous: [Axiom 16 — Unit](axiom-16-unit.md) · Next: [Axiom 18 — Result combinators](axiom-18-result-combinators.md) →
