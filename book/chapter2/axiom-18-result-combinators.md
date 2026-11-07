# Axiom 18 — Result combinators

**Reshape a `Result` by handing it the next step as a function. Three small higher-order functions cover the everyday moves: `Map` transforms the success, `MapError` transforms the failure, and `Bind` chains a step that can fail.**

- The step is a plain function: `T -> U`, `E -> F`, or `T -> Result<U, E>`.
- The combinator checks which side is present, applies the step to it, and wraps the answer again. The caller never does.

[Axiom 11](axiom-11-higher-order-functions.md) introduced functions that take functions, and [Axiom 17](axiom-17-result.md) introduced the value they work on here. Once a `Result` flows through more than one step, these are the verbs that move it along.

Through [Axiom 8](axiom-08-cohesion.md)'s lens, a combinator splits two ideas that every hand-written check fuses: the *propagation rule* ("on failure, pass it on"), which never changes, and the *step*, which changes every time. Each lives in one place.

---

## Definitions

A **Result combinator** takes a `Result<T, E>` and a step that works on one of its two sides, and returns a new `Result`:

- **`Map`**: `(Result<T, E>, T -> U) -> Result<U, E>`. Use it when the next step can't fail. It transforms the success; a failure passes through unchanged.
- **`MapError`**: `(Result<T, E>, E -> F) -> Result<T, F>`. Use it to translate the failure, usually where one error vocabulary meets another. A success passes through unchanged.
- **`Bind`**: `(Result<T, E>, T -> Result<U, E>) -> Result<U, E>`. Use it when the next step can fail too. On a failure, the step isn't called and the failure passes through; on a success, the step runs and *its* `Result` is the answer. Both sides must use the same error type `E`.

Pick the one whose signature fits the step.

**Names vary; the operations don't.** This book uses `Map` / `MapError` / `Bind` in C# (CSharpFunctionalExtensions' names [3]) and `map` / `mapError` / `flatMap` in Java. Rust calls them `map` / `map_err` / `and_then` [4]; F# `Result.map` / `Result.mapError` / `Result.bind` [2]; LINQ calls `Bind` `SelectMany`.

### Not only for `Result`

`Map` and `Bind` have the same shape, and often the same names, on other wrappers you have already met: `Optional.map` and `Optional.flatMap` ([Axiom 14](axiom-14-maybe.md#why)), `Stream.map` and `Stream.flatMap` in Java (`Select` and `SelectMany` in LINQ), and the chaining methods on `Task` and `CompletableFuture`. Wherever a wrapper decides whether the next step runs, `Map` and `Bind` are how you hand that step in. `MapError` is the one that belongs to `Result`: only a type with a typed second side (`Result`, or [Either](axiom-15-either.md)) has a failure to map.

---

## Example

The three combinators, written once each over the `Result` type from [Axiom 17](axiom-17-result.md#example):

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public static class ResultCombinators
{
    public static Result<U, E> Map<T, U, E>(
        this Result<T, E> r, Func<T, U> step) => r switch
    {
        Success<T, E> s => new Success<U, E>(step(s.Value)),
        Failure<T, E> f => new Failure<U, E>(f.Error),
        _ => throw new UnreachableException()
    };

    public static Result<T, F> MapError<T, E, F>(
        this Result<T, E> r, Func<E, F> step) => r switch
    {
        Success<T, E> s => new Success<T, F>(s.Value),
        Failure<T, E> f => new Failure<T, F>(step(f.Error)),
        _ => throw new UnreachableException()
    };

    public static Result<U, E> Bind<T, U, E>(
        this Result<T, E> r, Func<T, Result<U, E>> step) => r switch
    {
        Success<T, E> s => step(s.Value),
        Failure<T, E> f => new Failure<U, E>(f.Error),
        _ => throw new UnreachableException()
    };
}
```

</td>
<td>

```java
// Java has no extension methods, so these go
// inside the Result interface, next to match.
public sealed interface Result<T, E> permits Success, Failure {
    default <U> Result<U, E> map(Function<T, U> step) {
        return switch (this) {
            case Success<T, E> s -> new Success<>(step.apply(s.value()));
            case Failure<T, E> f -> new Failure<>(f.error());
        };
    }

    default <F> Result<T, F> mapError(Function<E, F> step) {
        return switch (this) {
            case Success<T, E> s -> new Success<>(s.value());
            case Failure<T, E> f -> new Failure<>(step.apply(f.error()));
        };
    }

    default <U> Result<U, E> flatMap(Function<T, Result<U, E>> step) {
        return switch (this) {
            case Success<T, E> s -> step.apply(s.value());
            case Failure<T, E> f -> new Failure<>(f.error());
        };
    }
}
```

</td>
</tr>
</table>

In use: `ParseAge` from [Axiom 17](axiom-17-result.md#example), one more step that can fail, one that can't, and an error translated for the form that sent the input.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed record FormError(string Field, string Reason);

Result<int, string> RequireAdult(int age) =>
    age >= 18
        ? new Success<int, string>(age)
        : new Failure<int, string>("under 18");

Result<string, FormError> ChooseTicketType(string ageInput) =>
    ParseAge(ageInput)
        .Bind(RequireAdult)                       // can fail
        .Map(age => age >= 65 ? "senior" : "adult") // can't fail
        .MapError(reason => new FormError("age", reason));
```

</td>
<td>

```java
public record FormError(String field, String reason) {}

Result<Integer, String> requireAdult(int age) {
    return age >= 18
        ? new Success<>(age)
        : new Failure<>("under 18");
}

Result<String, FormError> chooseTicketType(String ageInput) {
    return parseAge(ageInput)
        .flatMap(this::requireAdult)                // can fail
        .map(age -> age >= 65 ? "senior" : "adult") // can't fail
        .mapError(reason -> new FormError("age", reason));
}
```

</td>
</tr>
</table>

`ChooseTicketType` reads as its steps, with no `if (failed) return …` in between. If `ParseAge` fails, `RequireAdult` and the `Map` step never run, and the parse error comes out as a `FormError`. The same happens if `RequireAdult` fails. If both succeed, the `Map` step runs and the result is a `Success`.

---

## Problem / forces

Once steps return `Result`, the question is how to chain them. The options:

- **Check by hand at every step.** Match on the `Result`, return early on a failure, continue with the value. That is the right shape for a single step whose failure needs special handling. For three or four steps in a row it is the same few lines each time, and the steps disappear behind them; nested, it becomes the [arrow anti-pattern](https://blog.codinghorror.com/flattening-arrow-code/).
- **Throw to escape the chain.** When the hand-written checks feel verbose, the temptation is to throw and "skip the rest". That brings back everything [Axiom 17](axiom-17-result.md#problem--forces) removed: the signature lies again, and the failure is no longer a value. A `try` around a chain of honest `Result`s is the same mistake in a different place: dead code if the chain is honest, a bandage if it isn't.
- **Combinators.** Name each kind of reshaping once, and let every chain be a list of steps.

Checking by hand still has its place: where one step is genuinely special (see *When NOT to*). Combinators are for runs of steps that all follow the same rule.

---

## Why

**1. Only the step varies, so only the step is written.**
"On failure, pass it on; on success, run this and wrap the answer" contains two ideas. The rule is always the same; the step never is. The combinator holds the rule once, so each call site shows the step and nothing else.

**2. The chain stays honest end to end.**
Every link in the chain is a `Result<…, E>`, and so is the answer. No failure is hidden or postponed along the way, so the promise of [Axiom 7](axiom-07-honest-total-signatures.md) holds for the whole chain, not just for each function in it.

---

## Trade-offs

- **The usual costs of higher-order functions.** A stack trace shows the combinator and a lambda instead of the step's name, and the compiler sometimes needs an explicit type argument. Both have the fixes listed in [Axiom 11](axiom-11-higher-order-functions.md#trade-offs), such as naming the step as a method.
- **`Bind` needs one error type.** When two steps use different error types, translate one with `MapError` first, then chain. Widening `E` to a `string` (or to a union of unrelated things) just to keep one fluent chain hides the categories in a message; the chain probably wants to be two chains, joined by a `MapError`.
- **Someone has to write them.** Defining the three combinators for every result-like type is small, but it has to be done consistently. In real code, take them from one library rather than writing your own: Rust and F# have them built in; C# has CSharpFunctionalExtensions [3]; Java has no standard `Result`, but Vavr's `Either` has `map`, `mapLeft` and `flatMap`. This axiom writes them by hand only to show there is nothing hidden inside.

---

## When NOT to

- **One `Result`, used once.** A function that gets a `Result` and immediately matches on it to do two different things already has the right shape. There is no chain to compose.
- **When a failure needs handling between steps.** If step 2 should *recover* from a particular failure of step 1 (fall back to a default, try other inputs, log and carry on), the recovery is the point of the code. Match on the `Result` and decide.
- **For impure steps.** The combinators chain *pure* steps. Once a step reads the clock, queries the database or sends a request, the order of effects hides inside `Bind`, and an expression that reads like a value behaves like a script. Keep effects in the branches of the final match, after the chain has produced its value ([Axiom 13](axiom-13-impureim.md)). The chain can be built inside the impure shell and still be pure: what matters is that every step is pure, not where the code sits.

---

## References

[1] **John Hughes**, *Why Functional Programming Matters*, in *Research Topics in Functional Programming*, Addison-Wesley, 1990. Also cited in [Axiom 11](axiom-11-higher-order-functions.md). Small higher-order functions are the "glue" that lets simple definitions compose into large programs; the Result combinators are one case of that glue.
<https://www.cs.kent.ac.uk/people/staff/dat/miranda/whyfp90.pdf>

[2] **Scott Wlaschin**, *Domain Modeling Made Functional*, Pragmatic Bookshelf, 2018. Also cited in [Axiom 17](axiom-17-result.md). Builds up `Result.map`, `Result.mapError` and `Result.bind` in F#, step by step.
<https://pragprog.com/titles/swdddf/domain-modeling-made-functional/>

[3] **Vladimir Khorikov**, *CSharpFunctionalExtensions*. Also cited in [Axiom 17](axiom-17-result.md). Ships `Map`, `Bind` and `MapError` on `Result<T, E>` as extension methods; the C# above follows its names.
<https://github.com/vkhorikov/CSharpFunctionalExtensions>

[4] **Rust** `std::result::Result<T, E>`: `map`, `map_err` and `and_then`, the same three operations under Rust's names.
<https://doc.rust-lang.org/std/result/enum.Result.html#method.map>

---

← Previous: [Axiom 17 — Result](axiom-17-result.md) · Next: [Axiom 19 — Value objects](axiom-19-value-objects.md) →
