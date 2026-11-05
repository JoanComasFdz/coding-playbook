# Axiom 10 — Higher-order functions

**A function is [higher-order](https://en.wikipedia.org/wiki/Higher-order_function) (an HOF) when it takes a function as a parameter, returns a function as its result, or both.**

- The function being passed or returned is just a value of a function type, like any other value.
- Higher-order functions are how a program names a *shape* once and lets callers fill in the *step*.

[Axiom 9](axiom-09-first-class-functions.md) named the prerequisite: a function is a value the program can hold, store and pass. This axiom names what you *do* with that: write functions whose job is to combine, configure or apply other functions. They are where the everyday composition in this book actually happens.

Through [Axiom 8](axiom-08-connascence.md)'s lens, a higher-order function improves the *locality* of what varies: the shape is named once, in the function, and the step that varies is passed in as a typed value at the call site. A behavior each caller would otherwise reimplement by the same informal convention becomes one named, compiler-checked seam: a [Connascence of Type](axiom-08-connascence.md#connascence-of-type-cot) instead of an agreement at every call that the compiler can't see.

---

## Definitions

A function is **higher-order** when at least one of these is true:

- **It takes a function as a parameter.** The caller supplies a function value, and the body calls it as part of its work.
- **It returns a function as its result.** The body builds a new function value and hands it back, often capturing arguments from the call that built it.

In real code, this takes two forms:

- **Operations that take a function.** `Select`/`map`, `Where`/`filter`, `Aggregate`/`reduce`, `List.sort(comparator)`. The body is a fixed traversal; the caller plugs in the decision for each element.
- **Operations that build a function.** A factory that returns a function with its configuration built in: `Multiplier(factor)` from [Axiom 9](axiom-09-first-class-functions.md), a `Comparator` builder, a function that composes two others.

C# (`Func<>`, `Action<>`, delegates) and Java (`Function<T, R>`, `Predicate<T>`, `BiFunction<T, U, R>`) both support HOFs fully.

---

## Example

A function that *takes* a function: the function owns the traversal; the caller owns the step.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public static List<U> Map<T, U>(IReadOnlyList<T> source, Func<T, U> step)
{
    var result = new List<U>(source.Count);
    foreach (var item in source)
        result.Add(step(item));
    return result;
}

// Two callers, same shape, different steps.
var prices  = Map(items, item => item.UnitPrice);
var lengths = Map(words, word => word.Length);
```

</td>
<td>

```java
public static <T, U> List<U> map(List<T> source, Function<T, U> step) {
    var result = new ArrayList<U>(source.size());
    for (var item : source)
        result.add(step.apply(item));
    return result;
}

// Two callers, same shape, different steps.
var prices  = map(items, item -> item.unitPrice());
var lengths = map(words, word -> word.length());
```

</td>
</tr>
</table>

`Map` owns the traversal: walk every element, build a new list. Two callers reuse it with different steps, and neither writes the loop. The loop only has to be right once.

A function that *returns* a function: the result is a new function value, configured by the arguments of the call that built it.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public static Func<A, C> Compose<A, B, C>(Func<A, B> first, Func<B, C> second) =>
    input => second(first(input));

// Build a normalizer once.
Func<string, string> trim    = s => s.Trim();
Func<string, string> toLower = s => s.ToLowerInvariant();
var normalize = Compose(trim, toLower);

// Use it many places.
var clean = lines.Select(normalize).ToList();
```

</td>
<td>

```java
public static <A, B, C> Function<A, C> compose(Function<A, B> first,
                                               Function<B, C> second) {
    return input -> second.apply(first.apply(input));
}

// Build a normalizer once.
Function<String, String> trim    = String::strip;
Function<String, String> toLower = s -> s.toLowerCase(Locale.ROOT);
var normalize = compose(trim, toLower);

// Use it many places.
var clean = lines.stream().map(normalize).toList();
```

</td>
</tr>
</table>

`Compose` is higher-order on both counts: it takes two functions and returns one. The resulting `normalize` isn't a method anyone declared. It is a **closure**, as in [Axiom 9](axiom-09-first-class-functions.md): a function value that applies `trim` and then `toLower`, both captured from the call that built it. It can be passed anywhere a `Func<string, string>` is expected, and no caller has to spell out the chain again.

The clearest sign that an HOF wants to be extracted is code where the *same shape* repeats with a different *step* in the middle: walk and accumulate, filter then transform, group by a key, sort by a field. Pull the step into a parameter, and the shape goes from copy-pasted to written once.

---

## Problem / forces

The usual OO ways to say "this shape, with this step swapped in" each cost more than a parameter [2]:

- **[Template Method](https://en.wikipedia.org/wiki/Template_method_pattern):** an abstract base class with one method left for the subclass to fill in. The filled-in step is a function; inheritance is the long way to deliver it.
- **[Strategy](https://en.wikipedia.org/wiki/Strategy_pattern) as a one-method interface** (`IComparer<T>`, Java's `Comparator<T>`): structurally a function type. Right when the variation deserves a name and its own file; overhead when it is one lambda passed at one call site.
- **Hand-written loops with mutable accumulators:** a `for` loop that sums, finds or transforms reimplements `Aggregate`, `First` or `Select` inline, and names neither the traversal nor the step.

The first two cost a type per variation, a folder of small classes and a registration in the composition root. A function parameter gives the same separation, with the variation living at the call site instead of in a new file.

One force pulls the other way: **debugging**. A chain of anonymous lambdas is harder to step through and to find (see *Trade-offs*).

---

## Why

**1. Name the shape once.**
Every loop or traversal carries two ideas: the *shape* around the variation (walk every element, keep the ones that match, group by a key) and the *step* applied in the middle. A hand-written version mixes them in one block; an HOF separates them. The shape is named once, in the function; the step is named at the call site, where the variation lives. When the shape changes, the number of places that must be right goes from many to one. The standard library already names the most common shapes (`Select`/`map`, `Where`/`filter`, `Aggregate`/`reduce`, sorting with a comparator), so a hand-written loop only survives where the shape is unusual. Hughes calls higher-order functions the *glue* that lets small definitions combine into large programs [1].

These are shapes of *pure* code. Impure plumbing (open a transaction, acquire a lock, log entry and exit) is a different case: see *When NOT to*.

**2. Configuration travels inside the returned function.**
A function that returns a function can build its configuration into the result. `PriceFormatter(culture, currency)` returns a function from an amount to its display text, and the caller never passes `culture` or `currency` again. The returned function is the configuration *and* the behavior, packaged together.

---

## Trade-offs

- **Naming.** A stack trace through `Map(items, item => Compute(item))` shows `Map` and a lambda, not `Compute`; *Find Usages* doesn't find an inline lambda; a deep chain of unnamed steps becomes opaque when something needs investigating. The remedy is [Axiom 9](axiom-09-first-class-functions.md)'s rule: name a function when it deserves a name. A `static` method passed to an HOF shows up in stack traces and the symbol index like any other method.
- **Type inference.** A function that takes a `Func<T, U>` sometimes needs an explicit type argument at the call site, because the compiler can't infer `T` and `U` from a bare lambda. The fix is local (annotate the lambda, or assign it to a typed variable), but the friction is real in very generic helper APIs.

---

## When NOT to

Three cases where reaching for a function parameter is the wrong reflex:

- **Behavior that really has several methods.** `IEnumerator<T>` and `IObserver<T>` declare *several* operations that must be implemented together; their cohesion is the point of having a type. Collapsing them into one function loses something, so the interface is the right shape.
- **Behavior that needs a stable identity.** A plugin handler looked up by string key in a `Map<String, Function<...>>` works as long as the keys live inside the same program. A handler that has to survive serialization, be found by an annotation scanner, or be registered across processes needs a class: the same exception as in [Axiom 9](axiom-09-first-class-functions.md).
- **Wrapping impure plumbing.** Don't write reusable wrappers around impure steps, like a `WithTransaction(step)`, `WithLock(step)` or `Logged(step)` that every handler passes its work into. That hides impure code behind a reusable facade, and it is the generic handler with the business step passed in that [Axiom 7](axiom-07-cohesion.md#what-dry-is-for) warns against. Let each orchestration do its own transaction, locking and logging, in plain sight; where the framework already provides the wrapper, use it.

---

## References

[1] **John Hughes**, *Why Functional Programming Matters*, Research Topics in Functional Programming, Addison-Wesley, 1990. Already cited in earlier axioms. Listed again because its central argument, that higher-order functions (together with lazy evaluation) are the *glue* that lets small, simple definitions combine into large programs, is the classic case for this axiom. Its worked examples (`foldr`, `map`, numerical algorithms) are the standard demonstrations. <https://www.cs.kent.ac.uk/people/staff/dat/miranda/whyfp90.pdf>

[2] **Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides**, *Design Patterns: Elements of Reusable Object-Oriented Software*, Addison-Wesley, 1994. Template Method, Strategy and [Command](https://en.wikipedia.org/wiki/Command_pattern) are the OO forms that higher-order functions replace at a lower cost. Already cited in [Axiom 9](axiom-09-first-class-functions.md); listed again because HOFs are how this book expresses those patterns when the variation is one function.

---

← Previous: [Axiom 9 — First-class functions](axiom-09-first-class-functions.md) · Next: [Axiom 11 — Pattern matching](axiom-11-pattern-matching.md) →
