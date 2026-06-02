# Axiom 16 — Result

**A function that can succeed or fail must return both outcomes as values — never as a thrown exception nor sentinel.**

- Reach for the named pair `Success<T>` / `Failure<E>` (also called `Ok`/`Err`) when the two outcomes carry domain meaning: the operation worked and produced a `T`, or it didn't and the reason is an `E`.

> Result is the *named* form of [Axiom 14](axiom-14-either.md): when the two outcomes are "it worked" and "it didn't," the names earn their keep. This is the form domain code should reach for; `Either` is the structural primitive it specializes.

[Axiom 6](axiom-06-honest-total-signatures.md) says every outcome belongs in the return type; [Axiom 14](axiom-14-either.md) says distinct outcomes belong there *as values*. Result is the everyday named pair where the two outcomes are *success* and *failure*. Combined with [Axiom 15](axiom-15-unit.md), it covers the full grid: success carrying a value, success carrying nothing meaningful (`Result<Unit, E>`), or failure carrying an error.

Through [Axiom 8](axiom-08-connascence.md)'s lens, this axiom weakens a [Connascence of Meaning](axiom-08-connascence.md#connascence-of-meaning-com) — the error codes, sentinels, and exception channels a caller must just *know* — into a Connascence of Type.

---

## Definitions

A type is a *Result* when:

- **Two cases, by construction** — exactly one carries a value of type `T` (`Success<T>`), exactly one carries an error of type `E` (`Failure<E>`).
- **The cases are disjoint** — a value is one or the other, never both.
- **The error is a value, not a thrown event** — `E` is data the caller can read, equal-compare, store, log, or transform like any other value.
- **No silent unwrap** — there is no public operation that reads either side without making the caller acknowledge which is present.

Structurally Result *is* [Either](axiom-14-either.md): two cases, both visible in the return type, neither side reachable without acknowledging the other. The contribution this axiom makes is the *names*: `Success` and `Failure` (or `Ok` and `Err`) carry the convention that one side is the answer the caller wanted and the other is the reason it didn't get it. The naming is what makes Result a domain primitive rather than a structural one.

The error type `E` is open. It can be a `string` ("user not found"), a typed record, an enum of named failure cases — whatever the caller needs to act on. The axiom is silent on which to pick; that convention is an ADR-level decision, not a principle-level one.

---

## Example

A login operation: it either authenticates the user, or it doesn't and the caller needs to know why.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public abstract record Result<T, E>;
public sealed record Success<T, E>(T Value) : Result<T, E>;
public sealed record Failure<T, E>(E Error) : Result<T, E>;

public sealed record Token(string Value);

Result<Token, string> Authenticate(string username, string password)
{
    if (!users.TryGetValue(username, out var user))
        return new Failure<Token, string>("User not found");
    if (!Verify(password, user.PasswordHash))
        return new Failure<Token, string>("Wrong password");
    return new Success<Token, string>(IssueToken(user));
}

var result = Authenticate("joan", "entrecote");

// Using Match (Axiom 11) — the switch equivalent repeats <Token, string> on every arm:
//   result switch
//   {
//       Success<Token, string> s => $"Welcome, token={s.Value.Value}",
//       Failure<Token, string> f => $"Login failed: {f.Error}"
//   }
Console.WriteLine(result.Match(
    success: t => $"Welcome, token={t.Value}",
    failure: e => $"Login failed: {e}"));
```

</td>
<td>

```java
public sealed interface Result<T, E> permits Success, Failure {}
public record Success<T, E>(T value) implements Result<T, E> {}
public record Failure<T, E>(E error) implements Result<T, E> {}

public record Token(String value) {}

Result<Token, String> authenticate(String username, String password) {
    var user = users.get(username);
    if (user == null)
        return new Failure<>("User not found");
    if (!verify(password, user.passwordHash()))
        return new Failure<>("Wrong password");
    return new Success<>(issueToken(user));
}

void main(String[] args) {
    var result = authenticate("joan", "entrecote");

    // Using match (Axiom 11) — the switch equivalent repeats <Token, String> per arm:
    //   switch (result) {
    //       case Success<Token, String> s -> System.out.println("Welcome, token=" + s.value().value());
    //       case Failure<Token, String> f -> System.out.println("Login failed: " + f.error());
    //   }
    System.out.println(result.match(
        t -> "Welcome, token=" + t.value(),
        e -> "Login failed: " + e));
}
```

</td>
</tr>
</table>

Both failure modes — "user not found" and "wrong password" — live in the return type as values. There is no exception unwinding the stack on a wrong password; the caller treats the two outcomes symmetrically. Compare with the thrown-on-failure alternative: a signature `Token Authenticate(string, string)` that throws `AuthenticationException` is structurally lying — the type system says "you get a `Token`," and the failure mode is a different control flow the caller has to discover by reading the function's documentation.

---

## The first synthesis

Thirteen axioms in, Result is the first place all the pieces fit into one diagram. The sketch above shows the shape of the type; the worked example below shows the shape those thirteen axioms together push the *code* into.

A login endpoint, end to end — `Result` definitions from the example above are reused as-is:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// ── Data — immutable records ──────────────────────────────────────
public sealed record Credentials(string Username, string Password);
public sealed record User(string Username, string PasswordHash, DateTime? LockedUntil);

// ── Pure core — same inputs, same outputs, no I/O ─────────────────
// Every outcome lives in the return type. The lookup arrives from
// the boundary as a nullable reference; pattern matching creates a
// cohesive decision block; Result carries the decision back out as a value.
Result<Token, string> Decide(User? lookup, string submitted, DateTime now) =>
    lookup switch
    {
        null                                                  => new Failure<Token, string>("user not found"),
        User u when u.LockedUntil is { } until && until > now => new Failure<Token, string>($"account locked until {until}"),
        User u when u.PasswordHash != Hash(submitted)         => new Failure<Token, string>("wrong password"),
        User u                                                => new Success<Token, string>(IssueToken(u))
    };

// ── Impure shell — effects at the edges, no decisions inside ──────
Unit Login(Credentials creds)
{
    User? lookup = users.Find(creds.Username);           // impure: DB read
    DateTime now = clock.Now;                            // impure: clock read

    var decision = Decide(lookup, creds.Password, now);  // pure: tells us what to do

    // Using Match (Axiom 11) — the switch equivalent repeats <Token, string> per arm:
    //   decision switch
    //   {
    //       Success<Token, string> s => sessions.Store(s.Value),
    //       Failure<Token, string> f => log.Warn(f.Error)
    //   }
    return decision.Match(                               // impure: pattern matching to execute the decision
        success: t => sessions.Store(t),
        failure: e => log.Warn(e));
}
```

</td>
<td>

```java
// ── Data — immutable records ──────────────────────────────────────
public record Credentials(String username, String password) {}
public record User(String username, String passwordHash, Optional<Instant> lockedUntil) {}

// ── Pure core ─────────────────────────────────────────────────────
Result<Token, String> decide(Optional<User> lookup, String submitted, Instant now) {
    return lookup
        .<Result<Token, String>>map(u -> {
            if (u.lockedUntil().isPresent() && u.lockedUntil().get().isAfter(now))
                return new Failure<>("account locked until " + u.lockedUntil().get());
            if (!u.passwordHash().equals(hash(submitted)))
                return new Failure<>("wrong password");
            return new Success<>(issueToken(u));
        })
        .orElseGet(() -> new Failure<>("user not found"));
}

// ── Impure shell ──────────────────────────────────────────────────
Unit login(Credentials creds) {
    Optional<User> lookup = users.find(creds.username());  // impure: DB read
    Instant now           = clock.now();                   // impure: clock read

    var decision = decide(lookup, creds.password(), now);  // pure: tells us what to do

    // Using match (Axiom 11) — the switch equivalent repeats <Token, String> per arm:
    //   switch (decision) {
    //       case Success<Token, String>(var t) -> sessions.store(t);
    //       case Failure<Token, String>(var e) -> log.warn(e);
    //   }
    return decision.match(                                 // impure: pattern matching to execute the decision
        t -> sessions.store(t),
        e -> log.warn(e));
}
```

</td>
</tr>
</table>

Read the picture from top to bottom and every prior axiom is in plain sight:

- **Data, immutable, separate from behaviour** ([Axiom 1](axiom-01-data-vs-behaviour.md), [Axiom 2](axiom-02-immutability.md)). `Credentials`, `User`, `Token` — all records, all immutable, all distinct from the functions that operate on them.
- **Effects are named and contained** ([Axiom 3](axiom-03-side-effects.md), [Axiom 4](axiom-04-impure-functions.md)). The DB lookup, the clock read, the log write, and the session write are the only effects in the listing, and every one of them is in `Login`. The comment markers — *impure: DB read* — exist because the rest of the code earned the right not to need them.
- **The decision is pure** ([Axiom 5](axiom-05-pure-functions.md)). `Decide(lookup, submitted, now)` is a function of its inputs and nothing else. Same triple in, same `Result` out. No clock read inside; the clock value is *passed in*. That single discipline is what makes `Decide` trivially testable — no mocks, no clock fakes, just call it.
- **The signature is honest and total** ([Axiom 6](axiom-06-honest-total-signatures.md)). `Decide` returns `Result<Token, string>` — the success carries a `Token`, the failure carries a reason. Every outcome the function can produce lives in the return type as a value. There is no thrown exception, no nullable success, no side channel.
- **Higher-order machinery glues the impure boundary to the pure core** ([Axiom 9](axiom-09-first-class-functions.md), [Axiom 10](axiom-10-higher-order-functions.md)). The Java version reaches for `Optional.map` and `orElseGet` to lift the present-case handler into the absent-case world; both arguments are functions passed as values. The C# version inlines the same shape in the switch expression.
- **Pattern matching consumes the shapes** ([Axiom 11](axiom-11-pattern-matching.md)). The pure core uses `switch` on `User?` / `Optional<User>` to inspect the lookup; the impure shell uses `Match` on the `Result` to dispatch the decision. Same operation, two surfaces — `switch` when the case type is short, `Match` when the generic types would otherwise repeat on every arm. Both are exhaustive: the compiler refuses to compile until both arms are present.
- **The whole function is an Impureheim sandwich** ([Axiom 12](axiom-12-impureheim.md)). I/O on the way in, pure decision in the middle, I/O on the way out. The pure middle is the only part of this code that has any business logic.
- **Maybe carries absence at the boundary** ([Axiom 13](axiom-13-maybe.md)). The lookup may or may not find a user; that absence reaches the core as a value, not as a `null` that the core has to guess at.
- **Result is Either with names** ([Axiom 14](axiom-14-either.md)). The two cases live in the same return slot; the names `Success` and `Failure` are exactly the convention `Left`/`Right` lacks — and the reason string the failure carries is exactly the information a thrown `AuthenticationException` would have buried in a stack trace.
- **Unit closes the shell** ([Axiom 15](axiom-15-unit.md)). `Login` returns `Unit`: it ran. The impure side doesn't pretend to have a meaningful answer to give back.

The payoff: every failure is a value, every value is a record, every decision is a function, every effect sits at a named edge. When something goes wrong, you find out *what* by reading `Decide` — there is no thrown exception unwinding through layers, no nullable smuggling failure as success, no side channel carrying error state.

---

## Problem / forces

[Axiom 14](axiom-14-either.md) framed the three dishonest patterns for any two-outcome computation: **throw / tombstone / `out`-parameter**. Result inherits all three critiques because Result *is* an Either; the names just specialize the type. But the *dominant* mainstream form for success-or-failure specifically is throw — and it earns its own treatment here, because the temptation to throw on a failed login or a bad parse is much stronger than the temptation to throw on a divide-by-zero.

The reason throw wins by default is cultural, not technical. Languages give you `throw` as one keyword and `catch` as one statement. The success path stays linear, the error path gets out of the way "for free" by unwinding the stack. For a function several layers deep, "I'll just throw" is the shortest path to *making the immediate code work* — at the cost of every caller now living with a control flow the type system does not name.

The cost shows up later, in three predictable shapes:

- **The signature lies.** `Token Authenticate(string, string)` reads as "returns a `Token`." It also throws on bad password, missing user, and locked account, and the signature mentions none of those. Callers have to read the function body — or the documentation, if it exists — to know which exceptions to handle. Checked exceptions (Java) push some of this back into the type system; unchecked exceptions (the C# and Java norm in practice) do not.

- **Exceptions are for *exceptional* cases, and "wrong password" is not exceptional.** This is the same framing [Axiom 13](axiom-13-maybe.md) uses for "no user found": it is a normal answer to the question the function was asked. Treating the normal answer as a stack-unwinding event is expensive (exception construction captures a stack trace) and noisy (every layer between the producer and the catcher sees a transient failure that is not its concern).

- **Mixed exception/return-code is a third channel.** When some failures are exceptions and some are return values (a `bool` flag, a sentinel, a nullable), the caller now reads *two* error channels for the same function. The compiler can enforce neither one. The next maintainer cannot tell, from the signature alone, which failures live where.

Result fixes the same problem [Either](axiom-14-either.md) fixes — both outcomes in the return type, as values — and adds two things: the names `Success` and `Failure` carry the domain semantics, and the error side `E` is a real value the caller can hold and act on rather than an exception the runtime is unwinding around them.

---

## Why

**1. The names carry the convention.**
A function returning `Result<Token, AuthFailure>` reads as "returns a `Token`, or an `AuthFailure`." The structurally identical `Either<Token, AuthFailure>` reads against the grain — the reader has to remember which side is the answer they wanted. Naming the cases removes that convention work from every call site. The right-biased convention Haskell and Scala built around `Either` is exactly this work, done by community agreement rather than by the type.

**2. The error side `E` carries information the runtime threw away.**
A typed `Failure<AuthFailure>` lets the caller branch on `UserNotFound` vs `WrongPassword` vs `AccountLocked` *as values*. The throwing alternative either lumps them into one `AuthenticationException` (and callers branch on a message string) or invents an exception per case (and every caller now has three `catch` blocks). The value form lets the caller use the same pattern-matching tool ([Axiom 11](axiom-11-pattern-matching.md)) used for any other Either-shaped value in the codebase.

**3. Errors-as-values compose; thrown exceptions do not.**
A `Result<T, E>`-returning function is a function — it slots into pipelines, holds in collections, returns from lambdas, and lets the caller decide what to do with each outcome. A throwing function changes shape with the surrounding `try`/`catch`: caller A sees one function, caller B sees another. The composition cost was the same point [Axiom 14](axiom-14-either.md) made for Either in general; it bites harder for Result because success-or-failure is *exactly* the case mainstream code reaches for `throw` on.

---

## The ladder: eliminate, then return, then fail fast

Result is the *second* move, not the first. Simplicity-first — *as simple as possible, then as honest as possible, then as robust as possible* — resolves into three rungs for any would-be error, and Result owns the middle one:

1. **Eliminate it.** Before reporting a failure, ask whether the case can be designed away. Make the function total ([Axiom 6](axiom-06-honest-total-signatures.md)) — narrow the input until the bad value cannot be constructed, or broaden the operation until every input has a defined answer. An error defined out of existence needs no `Result`, no handler, no test; it is the simplest code there is, because it is the code that isn't there. (Later in the chapter the same move scales up — to a whole value, to the shape of a record, to the legal order of calls.)
2. **Return it honestly.** When the failure is a real outcome of the function's own logic — wrong password, row not found, malformed input — it belongs in the return type as a value. This axiom is that rung: `Result` carries the outcome the runtime would otherwise have unwound the stack to deliver.
3. **Fail fast.** When the "failure" can only mean a bug or an untrustworthy runtime — a violated invariant, an impossible state, out of memory — throw, halt, and let a higher layer log. *When NOT to* below is this rung.

The rungs are ordered, and the order is the north star. Sliding *down* a rung is always allowed — you can `Result`-wrap something you might have eliminated, and the code still works. The mistakes are sideways and up: skipping rung 1 to handle an error you could have erased, or jumping to rung 3 to *throw* an outcome that was really rung 2's to return.

---

## Trade-offs

Result costs the same things [Either](axiom-14-either.md) costs — verbosity at the producer, a small allocation per call — plus one decision Either didn't make: **what should `E` be?** A string is cheapest and reads well at small scale, but the caller cannot branch on it without parsing. A typed enum or named failure record is honest about the cases but couples the producer to its callers' branching needs. There is no universally right answer; pick one per bounded slice of the codebase, and put the choice in an ADR rather than re-deciding it per function.

The other Result-specific cost is **interoperability with code that throws**. The standard library throws. ORMs throw. HTTP clients throw. JSON parsers throw. Result does not eliminate exceptions from the codebase; it *contains* them. The rule of thumb: catch the exception at the lowest reasonable layer, lift the relevant failure cases into a `Failure<E>`, and let the rest of the codebase traffic in Results from there on. Boundary code is allowed to handle exceptions; domain code is not.

The deeper question hiding behind these trade-offs is **what counts as an error?** Two heuristics, both context-dependent:

- *Expected and recoverable* — a wrong password, a malformed input, a row not found, a transient HTTP failure. These are normal answers; they belong in Result.
- *Unexpected and unrecoverable* — an out-of-memory, a broken invariant, a corrupted runtime, a contract the type system was supposed to make impossible. These belong in exceptions, where the program fails fast and a higher layer logs and shuts down.

The line between them shifts by context. "Database is unreachable" is exceptional in a batch job that retries on its own and recoverable in a long-lived web service that wants to return a 503. Decide per bounded context, not per function.

---

## When NOT to

**When the failure case is genuinely exceptional.** Programmer errors (null where the type system can't catch it, a precondition the caller was supposed to satisfy), system-level failures (out of memory, stack overflow), and "the runtime is no longer trustworthy" cases are what exceptions are *for*. Reaching for `Result<T, "OutOfMemory">` is the same dishonesty as throw-on-normal-failure, in reverse: the type pretends the program can keep going. Throw and *fail fast*[4] — halt loudly at the source rather than let a bug travel as a `Result` value a caller might handle and continue past — and let the surrounding system catch and report.

**At the lowest layer of a wrapper.** Code that wraps a throwing API (JDBC, `HttpClient`, file IO) is the *one* place where catching an exception and lifting it into a `Failure<E>` belongs. Pushing Result *into* that wrapper — replacing the throw inside the standard library — is not the point of this axiom. Wrap once, lift, and let the rest of the code traffic in Result from there on.

**For internal helpers where failure cannot happen.** A private function whose preconditions are enforced by its only caller doesn't need to thread Result through. The type system has already removed the failure case; adding a Result wrapper to "be consistent" is noise.

**At framework boundaries that expect a thrown exception.** An MVC action that signals a 404 with `throw new HttpException(...)` is talking to the framework's protocol, not to your domain. Let Result stay inside the domain; unwrap into the framework's expected throw at the seam.

---

## References

[1] **Rust** `std::result::Result<T, E>` and **Haskell** `Data.Either` (right-biased). Rust adopted a named pair (`Ok`/`Err`) as the standard library's canonical error-handling type; Haskell uses the structural `Either` with a community convention that the right side is success. Most modern languages that ship a named Result type follow the Rust convention more closely — `Ok`/`Err` reads as the intended answer first.
<https://doc.rust-lang.org/std/result/enum.Result.html>

[2] **Scott Wlaschin**, *Domain Modeling Made Functional*, Pragmatic Bookshelf, 2018. The chapters on "Errors as Values" make the canonical OO/imperative-friendly argument for `Result` in F#; the framing here borrows from that treatment.
<https://pragprog.com/titles/swdddf/domain-modeling-made-functional/>

[3] **Vladimir Khorikov**, *CSharpFunctionalExtensions* (active, v3.7.0, March 2026) and the "Functional C#" course. The library's `Result` and `Result<T, E>` types are the pragmatic .NET answer the playbook's examples are shaped after; the docs discuss when to reach for Result and when exceptions still belong.
<https://github.com/vkhorikov/CSharpFunctionalExtensions>

[4] **James Shore**, *Fail Fast*, IEEE Software 21(5), 2004. The discipline of halting immediately on a programmer error or broken invariant, so the defect surfaces at its origin instead of several frames downstream disguised as a recoverable value. Its complement is *offensive programming* — declining to write defensive handling for conditions that can only arise from a bug, on the grounds that silently tolerating them hides the defect rather than containing it.
