# Axiom 15 — Result combinators

**Reshape a `Result` by passing the next step as a function — three small higher-order operations cover the day-to-day moves: `Map` transforms the success, `MapError` transforms the failure, `Bind` chains a fallible step.**

- The *step* is written as a plain function (`T -> U`, `T -> Result<U, E>`, or `E -> F`); the combinator does the one-time unwrapping and rewrapping in its own body.
- Each combinator is a higher-order function ([Axiom 8](axiom-08-higher-order-functions.md)) whose first argument is the `Result<T, E>` being reshaped and whose second argument is the step.

[Axiom 8](axiom-08-higher-order-functions.md) named operations *over* function values; [Axiom 14](axiom-14-result.md) named the value being reshaped here. This axiom is the meeting point: the everyday verbs the playbook reaches for whenever a `Result` flows through more than one step. The caller writes the step; the combinator handles the bookkeeping.

---

## Definitions

A **Result combinator** is a function over `Result<T, E>` parameterised by a step that operates on one of the two sides. The combinator inspects which side is present, applies the step to that side, and produces a new Result. Three combinators cover the moves that show up over and over:

- **`Map`** — type `(Result<T, E>, T -> U) -> Result<U, E>`. Transforms the success value with a non-fallible function. Failures pass through unchanged.

- **`MapError`** — type `(Result<T, E>, E -> F) -> Result<T, F>`. Transforms the failure value. Successes pass through unchanged. Used at boundaries where the producer's error type doesn't match the caller's vocabulary.

- **`Bind`** — type `(Result<T, E>, T -> Result<U, E>) -> Result<U, E>`. Chains a fallible step. If the input is `Failure`, the next step is not called and the failure flows through. If the input is `Success`, the next step runs on the carried value and *its* Result becomes the answer. The two failure types must match — both sides of the chain agree on what `E` is.

**Naming.** This axiom uses `Map` / `Bind` / `MapError` for C# (the CSharpFunctionalExtensions convention) and `map` / `flatMap` / `mapError` for Java. Rust uses `map` / `and_then` / `map_err`; F# uses `Result.map` / `Result.bind` / `Result.mapError`; LINQ exposes `SelectMany` for Bind. The names vary by ecosystem; the three operations are the same.

The defining property of all three: **the caller never sees inside the Result**. The pattern match — "is this a Success or a Failure?" — happens once, in the combinator's body. Every call site writes the step alone. That is the contract that makes long chains readable instead of stairstepped.

### Disclaimer

**`Map` and `Bind` are not unique to `Result`.** They have the same shape — and often the same name — on other wrappers the reader has already met: `Optional.map` and `Optional.flatMap` from [Axiom 11](axiom-11-maybe.md), `Stream.map` and `Stream.flatMap` in Java (or `Select` and `SelectMany` in C# LINQ), and the chaining primitives on `Task` / `CompletableFuture`. Anywhere a value sits inside a wrapper that decides whether and how the next step runs, `Map` and `Bind` are how the next step is handed in. `MapError` is the operation specific to `Result`: it transforms the *second* type parameter, and only a wrapper that *has* a typed second side — `Result`, or its structural parent [Either](axiom-12-either.md) — has that side to map. The rest of this axiom focuses on `Result`, since that is the slot in the sequence, but the muscle being built here is the broader one.

This axiom presents them as methods over Result to give the reader the full picture, without external dependencies, but in a real code base, Map and Bind would be generic.

---

## Example

The three combinators, each defined once, then used.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public static class ResultCombinators
{
    public static Result<U, E> Map<T, U, E>(
        this Result<T, E> r, Func<T, U> f) => r switch
    {
        Success<T, E> s => new Success<U, E>(f(s.Value)),
        Failure<T, E> e => new Failure<U, E>(e.Error)
    };

    public static Result<T, F> MapError<T, E, F>(
        this Result<T, E> r, Func<E, F> f) => r switch
    {
        Success<T, E> s => new Success<T, F>(s.Value),
        Failure<T, E> e => new Failure<T, F>(f(e.Error))
    };

    public static Result<U, E> Bind<T, U, E>(
        this Result<T, E> r, Func<T, Result<U, E>> f) => r switch
    {
        Success<T, E> s => f(s.Value),
        Failure<T, E> e => new Failure<U, E>(e.Error)
    };
}
```

</td>
<td>

```java
public sealed interface Result<T, E> permits Success, Failure {
    default <U> Result<U, E> map(Function<T, U> f) {
        return switch (this) {
            case Success<T, E> s -> new Success<>(f.apply(s.value()));
            case Failure<T, E> e -> new Failure<>(e.error());
        };
    }

    default <F> Result<T, F> mapError(Function<E, F> f) {
        return switch (this) {
            case Success<T, E> s -> new Success<>(s.value());
            case Failure<T, E> e -> new Failure<>(f.apply(e.error()));
        };
    }

    default <U> Result<U, E> flatMap(Function<T, Result<U, E>> f) {
        return switch (this) {
            case Success<T, E> s -> f.apply(s.value());
            case Failure<T, E> e -> new Failure<>(e.error());
        };
    }
}
```

</td>
</tr>
</table>

Three definitions, one pattern match each. From here on, the caller never writes that pattern match again.

The same three combinators in use, on a small pipeline — parse an integer, halve it if even, then re-tag the error with the original input.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed record ParseError(string Raw, string Reason);

Result<int, string> ParseInt(string s) =>
    int.TryParse(s, out var n)
        ? new Success<int, string>(n)
        : new Failure<int, string>($"'{s}' is not a number");

Result<int, string> HalveIfEven(int n) =>
    n % 2 == 0
        ? new Success<int, string>(n / 2)
        : new Failure<int, string>($"{n} is odd");

Result<int, ParseError> Process(string input) =>
    ParseInt(input)
        .Bind(HalveIfEven)            // chain a fallible step
        .Map(half => half * 10)       // transform the success
        .MapError(msg => new ParseError(input, msg));   // re-tag the failure
```

</td>
<td>

```java
public record ParseError(String raw, String reason) {}

Result<Integer, String> parseInt(String s) {
    try { return new Success<>(Integer.parseInt(s)); }
    catch (NumberFormatException e) {
        return new Failure<>("'" + s + "' is not a number");
    }
}

Result<Integer, String> halveIfEven(int n) {
    return n % 2 == 0
        ? new Success<>(n / 2)
        : new Failure<>(n + " is odd");
}

Result<Integer, ParseError> process(String input) {
    return parseInt(input)
        .flatMap(this::halveIfEven)           // chain a fallible step
        .map(half -> half * 10)               // transform the success
        .mapError(msg -> new ParseError(input, msg));  // re-tag the failure
}
```

</td>
</tr>
</table>

`Process` reads as four lines: the source, a fallible step, a non-fallible transform, an error-type adjustment at the boundary. There is no `if (result.IsFailure) return …` in sight — the combinators absorb that. If `ParseInt` fails, `HalveIfEven` is not called and the original error message flows through `MapError` to become the `ParseError`. If `HalveIfEven` fails on an odd number, the same path runs from there. If both succeed, the `Map` step runs and the answer is `Success`. The reader sees the pipeline.

---

## Problem / forces

Once `Result<T, E>` is in the codebase ([Axiom 14](axiom-14-result.md)), the question is how a sequence of Result-producing steps composes. The options on the trade-off curve:

- **Manual unwrap, check, rewrap at every step.** Pattern-match on the Result, return early on `Failure`, continue with the `Success` value. This is the right shape for a *single* step where the next action depends on the failure case in a non-uniform way — a different log, a fallback computation, a recovery. It becomes noise the moment three or four such steps run back-to-back, all doing the same "if `Failure`, propagate; if `Success`, continue" dance: every call site re-implements the dance, and the eye has to skim past the bookkeeping to find the step.

- **Throw inside a Result-returning function to escape the chain.** Once two or three manual pattern matches feel verbose, the temptation is to give up the value form and throw an exception to "skip" the rest. This re-introduces every problem [Axiom 14](axiom-14-result.md) named: the signature lies, the error is no longer a value, and the surrounding code now has a hidden control flow.

- **Wrap the chain in a `try` block around already-Result-returning code.** A subtler variant of the previous: keep returning Results, but defensively `try`/`catch` around the chain in case one of them "really" fails. The catch is dead code if the chain is honest; it is a band-aid if the chain is dishonest. Either way it does not belong.

- **Combinators.** A small fixed vocabulary — `Map`, `MapError`, `Bind` — that names each reshape once. The chain becomes a sequence of step names; the failure-propagation logic is invisible because it lives inside the combinators. This is the right shape for chains of two or more steps that share the same failure-propagation rule.

The first option is appropriate when one step is genuinely special. The last is appropriate when several steps are uniform. The combinators do not eliminate the manual pattern match; they let it appear only where the case-by-case handling is the actual point.

---

## Why

**1. The step is the only thing that varies; the combinator names the rest.**
Every "if `Failure`, propagate; if `Success`, run this and rewrap" block carries two ideas: the *propagation rule* (always the same) and the *step* (different every time). Manual pattern matching fuses them; the combinator separates them. The rule is named once, in the combinator's body; the step is named at the call site as a plain function. The reader sees the step alone.

**2. The combinator preserves the honest signature.**
A function returning `Result<T, E>` promises every outcome lives in the return type ([Axiom 5](axiom-05-honest-total-signatures.md)). A chain built with combinators preserves that promise — the type at every link is `Result<…, E>`, and the final answer is still `Result<…, E>`. There is no point in the chain where the failure case is hidden or postponed. Compare with a chain that *throws* in the middle: the function still nominally returns `Result`, but the control flow is no longer inside the type.

**3. Each combinator has a single job, and the three jobs cover what real code needs.**
`Map` is for "the next step cannot fail" — transform the value, leave the failure alone. `MapError` is for "I want to translate the failure" — usually at the boundary between a producer that speaks one error vocabulary and a caller that speaks another. `Bind` is for "the next step can fail too, with the same error type" — keep the chain going, short-circuiting on the first failure. Three operations, three intents; the right one to reach for is the one whose signature fits.

---

## Trade-offs

**Stack traces and step-through.** A failure produced deep inside a long combinator chain shows the combinator and a lambda in the stack trace, not the step's source location. For a short chain this is fine; for a long one, the same remedy as [Axiom 8](axiom-08-higher-order-functions.md) applies — extract the step to a named static method or local function, and the symbol shows up in the trace.

**Type-inference friction.** A chain of `.Map(…).Bind(…).MapError(…)` sometimes needs an explicit type argument when the compiler cannot infer the new type parameters from the lambda — most commonly when the first step in the chain is a generic call without enough context. The fix is local: annotate the offending lambda or assign it to a typed local.

**The failure type must agree to chain with `Bind`.** `Bind` requires both sides of the chain to use the same `E`. When the upstream and downstream errors are in different vocabularies, `MapError` is the seam: lift one side into the other's vocabulary first, then chain. That is the right *shape* — the alternative is a wider `E` (often `string`) that hides the categorisation in a message.

**Combinators are not free at the producer.** Defining `Map`, `MapError`, `Bind` on every Result-like type in the codebase is small bookkeeping; doing it consistently is the cost of entry for the chain-form. Most ecosystems have one library that does it once for you (Rust's standard library, F#'s `Result` module, CSharpFunctionalExtensions, Vavr); the playbook prefers picking one and reusing it over re-implementing.

---

## When NOT to

**A single Result, used once.** A function that produces a `Result<T, E>` and immediately pattern-matches on it to do two different things is *already* the right shape — there is no chain to compose. Adding `.Map(…)` or `.Bind(…)` to a one-step usage is noise. The combinators earn their keep when two or more steps run back-to-back.

**When the failure case needs case-by-case handling between steps.** If step 2 should *recover* from a particular failure of step 1 — fall back to a default, retry with different inputs, log and continue — the combinators don't fit that shape. The recovery is the point of the code; pattern-match on the Result and choose.

**When the steps don't share a failure type and shouldn't.** A pipeline that mixes "parse failed (a string)" and "permission denied (a typed enum)" without a deliberate translation is a sign the chain is wanting to be two chains, or a chain plus a `MapError` seam in the middle. Don't widen `E` to a union of unrelated things just to keep one fluent chain.

**For chaining impure steps.** The combinators are for transforming a `Result` built from *pure* fallible functions. The moment a step reads the clock, hits the database, or sends a request — even when it dutifully returns `Result<…, string>` — the chain stops being pure: the order of effects is now hidden inside `Bind`'s body, and the expression reads like a value but acts like a script. Keep effects on the arms of the final pattern match, after the chain has produced its final value ([Axiom 10](axiom-10-impureheim.md)). The chain stays a pure expression even when it is built inside an impure shell; what makes it pure is that every step is pure, not where the code lives on the page.

---

## References

[1] **John Hughes**, *Why Functional Programming Matters*, Research Topics in Functional Programming, Addison-Wesley, 1990. Cross-listed from [Axiom 8](axiom-08-higher-order-functions.md). The paper's central argument — that small higher-order operations are the *glue* that makes simple definitions compose into large programs — is the foundational case for combinators in general. The Result-shaped variants in this axiom are one specialisation of that glue.
<https://www.cs.kent.ac.uk/people/staff/dat/miranda/whyfp90.pdf>

[2] **Scott Wlaschin**, *Domain Modeling Made Functional*, Pragmatic Bookshelf, 2018. Cross-listed from [Axiom 14](axiom-14-result.md). The chapters that build up `Result.map`, `Result.mapError`, and `Result.bind` are the canonical OO-friendly introduction; the operation names this axiom uses match the F# treatment there.
<https://pragprog.com/titles/swdddf/domain-modeling-made-functional/>

[3] **Vladimir Khorikov**, *CSharpFunctionalExtensions* (v3.7.0, March 2026). Cross-listed from [Axiom 14](axiom-14-result.md). The library ships `Map`, `Bind`, and `MapError` on `Result<T, E>` as extension methods; the C# example above mirrors its conventions. Worth reading the source — the definitions are short, total, and consistent with the playbook's shape.
<https://github.com/vkhorikov/CSharpFunctionalExtensions>

[4] **Rust** `std::result::Result<T, E>` — `map`, `map_err`, `and_then`. The Rust standard library's three combinators are exactly the three this axiom names, with `and_then` standing in for `Bind`. A short, well-documented reference for the operations and their type signatures.
<https://doc.rust-lang.org/std/result/enum.Result.html#method.map>
