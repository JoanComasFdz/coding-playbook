# Axiom 19 — Railway

**Chain `Result`-returning steps with `Bind` so the success values flow through and the first `Failure` short-circuits the rest — the call site reads as the happy path, the failure path falls out of the types.**

- The visual metaphor: a track with two rails — *success* and *failure*. Each step has a switch on the success rail; the failure rail runs straight to the end. Once a value falls onto the failure rail it stays there.
- The mechanical content: a sequence of `.Bind(step)` calls, with `Map` for the non-fallible transforms in between.

[Axiom 17](axiom-17-result-combinators.md) named `Bind` as the combinator that chains a fallible step. [Axiom 18](axiom-18-value-objects.md) populated the domain with fallible steps — every `From` returns `Result<T, string>`. This axiom is what the call site looks like when those two land in the same function: a flat chain of `.Bind` and `.Map` calls, each step written as a plain function, the propagation rule named once inside the combinators and not again at any call site.

> Railway Oriented Programming is not limited to chaining Result types. But for now I restrict its use to be applied only for this purpose.

---

## Definitions

A **railway** is a `Result<T, E>` value threaded through a sequence of steps, where each step is a function that takes the previous step's success value as input, with the following properties:

- **Sequential.** Step *n + 1* sees only step *n*'s success. The order is the order on the page.
- **Short-circuiting.** A `Failure` produced by any step skips every subsequent step. The downstream functions are not called; their inputs would not type-check against the failure value, and the combinator's body refuses to invoke them.
- **Honest end-to-end.** Every intermediate type and the final type are `Result<…, E>`. There is no point in the chain where the failure case is hidden, postponed, or escapes into a side channel.
- **One error vocabulary per chain.** Every step's failure type is the same `E`. When two steps speak different error vocabularies, `MapError` is the seam that aligns them ([Axiom 17](axiom-17-result-combinators.md)).

The mental model is two rails running side by side. Each step is a switch on the success rail: if the inbound value is on the success rail, the switch routes it to the next step; if it is on the failure rail, the switch is bypassed and the value continues straight through. The chain ends with both rails meeting at a single output Result, which the caller pattern-matches on once.

The railway is not a new combinator. It is `Bind` and `Map` applied to a chain of fallible steps and read as one picture. The contribution of this axiom is the *picture* — the recognition that a fluent `.Bind(...).Bind(...).Map(...)` reads as a pipeline, and that this is the shape an Impureheim core takes when its inputs need parsing, its rules can fail, and its job is to produce one final value or one final reason.

---

## Example

A small pure pipeline: a registration-token verification that turns a raw token string into a verified user, with state (current time, user lookup table) passed in as values. Three fallible steps and a final non-fallible one.

The value objects come first — each is a record with a private constructor and a `From` returning `Result` ([Axiom 18](axiom-18-value-objects.md)):

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed record Token
{
    public string Value { get; }
    private Token(string v) => Value = v;

    public static Result<Token, string> From(string raw) =>
        string.IsNullOrWhiteSpace(raw)
            ? new Failure<Token, string>("token is empty")
            : raw.Length != 32
                ? new Failure<Token, string>("token must be 32 characters")
                : new Success<Token, string>(new Token(raw));
}

public sealed record Payload(UserId UserId, DateTime IssuedAt, DateTime ExpiresAt)
{
    public static Result<Payload, string> Decode(Token t) =>
        TryDecode(t.Value, out var p)
            ? new Success<Payload, string>(p)
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

    public static Result<Token, String> from(String raw) {
        if (raw == null || raw.isBlank())
            return new Failure<>("token is empty");
        if (raw.length() != 32)
            return new Failure<>("token must be 32 characters");
        return new Success<>(new Token(raw));
    }
    // equals / hashCode / toString as in Axiom 18
}

public record Payload(UserId userId, Instant issuedAt, Instant expiresAt) {
    public static Result<Payload, String> decode(Token t) {
        return tryDecode(t.value())
            .<Result<Payload, String>>map(Success::new)
            .orElseGet(() -> new Failure<>("token payload is malformed"));
    }
}
```

</td>
</tr>
</table>

The railway itself — four steps, no branching at the call site:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed record VerifiedUser(User User, DateTime VerifiedAt);

static Result<Payload, string> CheckNotExpired(Payload p, DateTime now) =>
    p.ExpiresAt > now
        ? new Success<Payload, string>(p)
        : new Failure<Payload, string>($"token expired at {p.ExpiresAt:O}");

static Result<User, string> LookupUser(IReadOnlyDictionary<UserId, User> users, UserId id) =>
    users.TryGetValue(id, out var u)
        ? new Success<User, string>(u)
        : new Failure<User, string>($"user {id} not found");

public static Result<VerifiedUser, string> Verify(
    string rawToken,
    DateTime now,
    IReadOnlyDictionary<UserId, User> users) =>
    Token.From(rawToken)                           // string  -> Result<Token, string>
        .Bind(Payload.Decode)                      // Token   -> Result<Payload, string>
        .Bind(p => CheckNotExpired(p, now))        // Payload -> Result<Payload, string>
        .Bind(p => LookupUser(users, p.UserId))    // Payload -> Result<User, string>
        .Map(u => new VerifiedUser(u, now));       // User    -> VerifiedUser
```

</td>
<td>

```java
public record VerifiedUser(User user, Instant verifiedAt) {}

static Result<Payload, String> checkNotExpired(Payload p, Instant now) {
    return p.expiresAt().isAfter(now)
        ? new Success<>(p)
        : new Failure<>("token expired at " + p.expiresAt());
}

static Result<User, String> lookupUser(Map<UserId, User> users, UserId id) {
    var u = users.get(id);
    return u != null
        ? new Success<>(u)
        : new Failure<>("user " + id + " not found");
}

public static Result<VerifiedUser, String> verify(
        String rawToken,
        Instant now,
        Map<UserId, User> users) {
    return Token.from(rawToken)                        // String  -> Result<Token,   String>
        .flatMap(Payload::decode)                      // Token   -> Result<Payload, String>
        .flatMap(p -> checkNotExpired(p, now))         // Payload -> Result<Payload, String>
        .flatMap(p -> lookupUser(users, p.userId()))   // Payload -> Result<User,    String>
        .map(u -> new VerifiedUser(u, now));           // User    -> VerifiedUser
}
```

</td>
</tr>
</table>

`Verify` reads as the happy path. Every line is what the function *does* when the previous step succeeded. The `if (failure) return` bookkeeping that this exact code would carry without `Bind` is nowhere on the page — the combinator handles it once and the call site never repeats it. If `Token.From` fails because the token is the wrong length, none of the downstream steps run; the failure reason `"token must be 32 characters"` flows straight to `Verify`'s return value. If decoding succeeds but the payload is expired, `LookupUser` is not called.

`now` and `users` are *passed in* as values rather than read inside `Verify`. That is what keeps `Verify` pure ([Axiom 5](axiom-05-pure-functions.md)): same `(rawToken, now, users)` in, same `Result<VerifiedUser, string>` out. The state that the railway runs *against* is the impure shell's responsibility to load and hand over.

---

## The synthesis

The railway is the first of the building blocks where the pure core becomes a recognisable picture rather than a single function. The call site — the impure shell that actually runs the railway — loads the inputs from the world, calls the chain, and pattern-matches on the result to shape the response. Below is the end-to-end shape every consumer of a railway will take.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed record HttpResponse(int Status, string Body);

public HttpResponse VerifyEndpoint(string rawToken)
{
    DateTime now                            = clock.Now;             // impure: clock read
    IReadOnlyDictionary<UserId, User> users = userStore.Snapshot();  // impure: DB snapshot

    var result = Token.From(rawToken)                                // pure: railway
        .Bind(Payload.Decode)
        .Bind(p => CheckNotExpired(p, now))
        .Bind(p => LookupUser(users, p.UserId))
        .Map(u => new VerifiedUser(u, now));

    // Using Match (Axiom 11) — the switch equivalent repeats <VerifiedUser, string> per arm:
    //   result switch
    //   {
    //       Success<VerifiedUser, string> s => new HttpResponse(200, $"verified {s.Value.User.Name}"),
    //       Failure<VerifiedUser, string> f => new HttpResponse(401, f.Error)
    //   }
    return result.Match(                                             // pure: pattern matching
        success: v => new HttpResponse(200, $"verified {v.User.Name}"),
        failure: e => new HttpResponse(401, e));
}
```

</td>
<td>

```java
public record HttpResponse(int status, String body) {}

public HttpResponse verifyEndpoint(String rawToken) {
    Instant now             = clock.now();           // impure: clock read
    Map<UserId, User> users = userStore.snapshot();  // impure: DB snapshot

    var result = Token.from(rawToken)                // pure: railway
        .flatMap(Payload::decode)
        .flatMap(p -> checkNotExpired(p, now))
        .flatMap(p -> lookupUser(users, p.userId()))
        .map(u -> new VerifiedUser(u, now));

    // Using match (Axiom 11) — the switch equivalent repeats <VerifiedUser, String> per arm:
    //   switch (result) {
    //       case Success<VerifiedUser, String>(var v) -> new HttpResponse(200, "verified " + v.user().name());
    //       case Failure<VerifiedUser, String>(var e) -> new HttpResponse(401, e);
    //   }
    return result.match(                             // pure: pattern matching
        v -> new HttpResponse(200, "verified " + v.user().name()),
        e -> new HttpResponse(401, e));
}
```

</td>
</tr>
</table>

Read the picture from top to bottom and every prior axiom is visible at its post:

- **Data, immutable, separate from behaviour** ([Axiom 1](axiom-01-data-vs-behaviour.md), [Axiom 2](axiom-02-immutability.md)). `Token`, `Payload`, `VerifiedUser`, `HttpResponse`, and the user dictionary are all immutable records or read-only views; none of the functions on the page own and mutate their own state.
- **Effects are named and contained** ([Axiom 3](axiom-03-side-effects.md), [Axiom 4](axiom-04-impure-functions.md)). The clock read and the user-store snapshot are the only effects in the listing — both at the top of `VerifyEndpoint`, both marked. The rest of the function is structurally pure; the `HttpResponse` it returns is a value the framework will turn into a real response somewhere outside this file.
- **The decision is pure** ([Axiom 5](axiom-05-pure-functions.md)). The railway expression that builds `result` is a function of `rawToken`, `now`, and `users` only. Same triple in, same `Result` out. No clock read inside the chain, no I/O — the shell *hands* the chain every value it needs.
- **The signature is honest and total** ([Axiom 6](axiom-06-honest-total-signatures.md)). The chain's type is `Result<VerifiedUser, string>`. Every outcome lives in the return type as a value: the verified user, or the first reason a step refused.
- **Functions are values; functions over functions are the glue** ([Axiom 9](axiom-09-first-class-functions.md), [Axiom 10](axiom-10-higher-order-functions.md)). Each `.Bind(...)` and `.Map(...)` is a higher-order operation whose second argument is the next step written as a function. `Payload::decode` is the step itself, passed as a value.
- **Pattern matching consumes the final shape** ([Axiom 11](axiom-11-pattern-matching.md)). The shell uses `Match` on `Result<VerifiedUser, string>` rather than `switch` — same operation, the method form when the generic types would otherwise repeat on every arm. Both arms are present; the compiler refuses to compile the shell until every case is acknowledged.
- **The whole function is an Impureheim sandwich** ([Axiom 12](axiom-12-impureheim.md)). I/O on the way in, pure decision in the middle, the response value on the way out. The pure middle is where the rules live; nothing else is.
- **Absence reaches the core as a value, not as `null`** ([Axiom 13](axiom-13-maybe.md)). The user lookup inside `LookupUser` is the same shape: a missing user becomes a `Failure` carrying the reason, not a `null` the core has to guess at.
- **Result is Either with names** ([Axiom 14](axiom-14-either.md), [Axiom 16](axiom-16-result.md)). The two cases live in the same return slot; `Success` and `Failure` carry the convention that one side is the answer the caller wanted and the other is the reason it didn't get it.
- **Unit is the shape when there's no value to return** ([Axiom 15](axiom-15-unit.md)). Here the shell *does* have a value to return — the `HttpResponse` — so it returns one. The same overall shape applies to shells whose only job is to write a row or log a reason; those return `Unit`.
- **`Bind` and `Map` are the bookkeeping** ([Axiom 17](axiom-17-result-combinators.md)). Four composed steps, zero `if (failure) return` blocks. The propagation rule is named once, inside the combinators; the call site is the steps in order.
- **Each fallible step is a smart constructor or its equivalent** ([Axiom 18](axiom-18-value-objects.md)). `Token.From` is the canonical smart constructor; `Payload.Decode`, `CheckNotExpired`, and `LookupUser` are all "parse, don't validate" steps — they return either a value the rest of the program can trust or a reason it couldn't be built.

The payoff: when something goes wrong the reader finds out *what* by reading the chain. The first refused step is the first reason. The downstream steps did not run; their preconditions were never violated because they were never reached. The shell has a single Result to look at and two arms to write. The business logic and the wiring are on the same page, in the same shape they will keep across the rest of the codebase.

---

## Problem / forces

Once a domain has fallible constructors ([Axiom 18](axiom-18-value-objects.md)) and the `Bind` combinator ([Axiom 17](axiom-17-result-combinators.md)) is available, the question is how a *handler* composes them. The options on the trade-off curve:

- **A ladder of `if (result.IsFailure) return result; …` blocks.** Pattern-match on every step, return early on `Failure`, continue on `Success`. This is the right shape when one step in the middle needs a *different* response than the rest — a fallback, a retry, a log-and-continue. It is the wrong shape when every step is doing the same "if failed, propagate; if succeeded, run the next" dance. The ladder repeats the dance once per step; the railway names it once.

- **Nested `switch` / `match` expressions, one per step.** A more compact form of the same ladder. It still pushes the propagation logic into every call site, and the further indentation each step adds is exactly what the chain form flattens.

- **Throw an exception from the middle to escape the chain.** Two or three pattern matches feel verbose, so the temptation is to give up and `throw`. This re-introduces every cost [Axiom 16](axiom-16-result.md) named — the signature lies, the failure is no longer a value, and the surrounding code carries a control flow the types do not name.

- **Manually nest `Bind` calls without naming intermediates.** The chain reaches three or four steps deep and the closures start nesting; a less disciplined version stops extracting steps and writes one giant lambda. The combinators are still doing their job, but the *picture* is gone. Extract steps to named functions and the picture comes back.

- **The railway.** Each step is a named function; the chain is a flat sequence of `.Bind(...)` and `.Map(...)` calls. The propagation rule lives in `Bind`'s body, written once; the call site reads as the happy path. This is the right shape when two or more fallible steps share the same failure-propagation rule — which is *most* handlers in a domain built on value objects.

The ladder fits when one step is genuinely special. The railway fits when several steps are uniform. The two coexist — a handler may be a railway with one ladder step in the middle when the recovery is the point — but the *default* should be the railway, and the ladder should appear when the recovery earns it.

---

## Why

**1. The first failure stops the work.**
A handler that has refused step 2 has no reason to run step 3. The downstream steps' preconditions are not satisfied; running them is at best wasted work and at worst undefined behaviour. The railway gives the short-circuit for free — the combinators stop calling forward as soon as a `Failure` appears. The handwritten alternative has to write that short-circuit at every layer and remember to write it the same way each time.

**2. The chain reads as the happy path.**
A reader scanning `Decide` sees four named steps in the order they happen. The failure path is implied by the types — every step returns `Result<…, string>`, and the chain's final type is `Result<NewCustomer, string>` — but the *prose* on the page is the success path. That is the shape pure cores want: the rule the code enforces is what the reader sees, and the bookkeeping is below the surface. Compare with the ladder form, where the eye has to skip past `if (failure) return` to find the next step.

**3. The chain composes freely.**
A railway is a value. The result of `Decide(...)` can be `Bind`ed into another step, `Map`ped into another type, or `MapError`ed at a boundary. Two handlers can share a sub-chain by extracting it as a named function returning `Result<…, string>` and calling it from both. The throwing alternative cannot do this — a function that throws to escape is not a value that can be deferred, lifted, or stored; it is a control-flow event tied to a `catch` somewhere up the stack. Errors-as-values composed; thrown errors did not.

**4. The pure core stays pure.**
Every step in `Decide` is a pure function — same inputs, same `Result`. The chain itself is pure: it is a sequence of pure function applications and pure combinator calls. The clock, the user store, and the taken-email set are *parameters*; they arrived from the shell as values. That is what makes `Decide` trivially testable: pass the four inputs, assert the `Result`. No mocks, no clock fakes, no test database — just function calls with arguments.

---

## Trade-offs

**One error type per chain.** `Bind` requires every step to use the same `E`. A railway whose first step fails with a parsing message and whose third step fails with a typed business-rule error cannot chain directly. The right shape is to choose one vocabulary for the chain — `string` is the playbook's default ([Axiom 18](axiom-18-value-objects.md)) — and lift outliers in at the seams via `MapError` ([Axiom 17](axiom-17-result-combinators.md)). Widening `E` to a union of unrelated things just to keep one fluent chain is a smell; it usually means the chain wants to be two chains with a `MapError` between them.

**Short-circuit is the choice, not the only option.** The railway stops at the first failure on purpose. That is the right shape when the downstream steps need the upstream success to be meaningful. It is the wrong shape when several checks are *independent* and the caller wants to know about all the failures at once — a form whose handling is a separate concern covered in a later axiom.

**Long chains can drift into fluent soup.** A `.Bind(…).Bind(…).Map(…).Bind(…).MapError(…)` chain with seven steps and three closures starts to lose its picture. The remedy is the same as [Axiom 10](axiom-10-higher-order-functions.md)'s remedy for HOFs in general: extract each step to a named static method or local function. The chain becomes a sequence of *names* — `Decode`, `CheckNotExpired`, `LookupUser` — and the picture returns. Anonymous lambdas in a railway are a sign the step deserves a name.

**Debuggers and stack traces show the combinator, not the step.** A failure deep in a chain shows `Bind` and a lambda in the trace, not the source location of the step that produced the failure. Two answers: (1) extract steps to named functions so they appear by name in the trace; (2) when the failure value itself carries enough information (a reason string that says which step refused), the trace matters less — the failure has already told you which switch threw it.

**Closure capture is allowed; closure overuse is the smell.** A `Bind` that captures `now` once to pass to a step is fine. A `Bind` whose lambda captures four locals and three reference types is a sign the step is doing too much work — it has become a domain function in disguise. Extract the lambda to a named function with explicit parameters and the chain reads cleaner.

---

## When NOT to

**When a single step needs case-by-case recovery.** Step 2 should *fall back* to a default on a specific failure of step 1, not propagate. The recovery is the point of the code, and the propagation rule the railway names is exactly what you do *not* want there. Use manual pattern matching at that step; let the surrounding shape stay railway-ish around it if there is anything left to chain.

**When the steps don't share a failure vocabulary.** Two chains with different `E` types should be two chains, joined at a seam where one is lifted into the other's vocabulary. Forcing them into one fluent call so the file reads as a railway hides the seam; making the seam explicit with a `MapError` (or a small named adapter) keeps the picture honest.

**When you need every failure surfaced, not just the first.** A registration form where the user has *both* an invalid username and an invalid email should arguably tell the user about both at once, not refuse one, send them back, and refuse the other on resubmit. The railway's short-circuit is the wrong shape for that requirement. The handling of that requirement is a separate concern from the railway and lives outside this axiom.

**For chaining impure steps.** The railway inherits the combinators' rule: only pure fallible functions belong in the chain. A `Bind` step that reads the clock, hits the DB, or sends a request smuggles effects into what reads as a pure expression — see [Axiom 17](axiom-17-result-combinators.md) for the full discussion. Effects belong on the arms of the final pattern match, not inside the chain.

**For a one-step function.** A function that produces a single `Result` and is consumed immediately has no chain to compose. Wrapping it in `.Map(x => x)` or routing it through a combinator to "look uniform" is noise. The railway earns its keep at two steps; below that, the direct return reads better.

---

## References

[1] **Scott Wlaschin**, *Railway-Oriented Programming*, NDC Oslo 2014 and fsharpforfunandprofit.com. The talk and the companion essay that named the metaphor and turned it into a teaching tool — two rails, switches, the picture of `Bind` as the switch the success rail flows through. The .NET / OO-friendly explanation of why composing `Result`-returning functions into one fluent chain is the right default for handlers built on value objects.
<https://fsharpforfunandprofit.com/rop/>

[2] **Scott Wlaschin**, *Domain Modeling Made Functional*, Pragmatic Bookshelf, 2018. Cross-listed from [Axiom 16](axiom-16-result.md) and [Axiom 17](axiom-17-result-combinators.md). The chapters on workflows compose smart constructors into pipelines exactly in the shape of the synthesis example above; the F# treatment is the canonical worked example for the OO reader to mirror.
<https://pragprog.com/titles/swdddf/domain-modeling-made-functional/>

[3] **Vladimir Khorikov**, *CSharpFunctionalExtensions* (v3.7.0, March 2026). Cross-listed from [Axiom 16](axiom-16-result.md), [Axiom 17](axiom-17-result-combinators.md), and [Axiom 18](axiom-18-value-objects.md). The library's `Result.Bind` extension methods and Khorikov's writing on "functional C#" make the fluent-chain form idiomatic in .NET; the C# example above mirrors that shape.
<https://github.com/vkhorikov/CSharpFunctionalExtensions>

[4] **John Hughes**, *Why Functional Programming Matters*, Research Topics in Functional Programming, Addison-Wesley, 1990. Cross-listed from [Axiom 10](axiom-10-higher-order-functions.md) and [Axiom 17](axiom-17-result-combinators.md). The "small combinators are the glue" argument is the foundational case for the railway: each step is a small definition; the combinators are the glue; the composed program is what you get for free.
<https://www.cs.kent.ac.uk/people/staff/dat/miranda/whyfp90.pdf>
