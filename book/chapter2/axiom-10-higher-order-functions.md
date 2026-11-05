# Axiom 10 — Higher-order functions

**A function is [higher-order](https://en.wikipedia.org/wiki/Higher-order_function) (an HOF) when it takes a function as a parameter, returns a function as its result, or both.**

- The function being passed or returned is just a value of a function type, like any other value.
- Higher-order functions are how a program names a *shape* once and lets callers fill in the *step*.

[Axiom 9](axiom-09-first-class-functions.md) named the prerequisite: a function is a value the program can hold, store and pass. This axiom names what you *do* with that. Once functions fit through parameters and return types like any other value, a whole kind of operation becomes possible: functions whose job is to combine, configure or apply other functions. They are operations *over* function values, and they are where the everyday composition in this book actually happens.

Through [Axiom 8](axiom-08-connascence.md)'s lens, a higher-order function improves the *locality* of what varies: the shape is named once, in the function, and the step that varies is passed in as a typed value at the call site, where the variation actually lives. A behavior each caller would otherwise reimplement by the same informal convention becomes one named, compiler-checked seam: a [Connascence of Type](axiom-08-connascence.md#connascence-of-type-cot) instead of an agreement at every call that the compiler can't see.

---

## Definitions

A function is **higher-order** when at least one of the following is true:

- **It takes a function as a parameter.** The caller supplies a function value, and the body calls it as part of its work. The function value is just one of the arguments, typed like any other.
- **It returns a function as its result.** The body builds a new function value and hands it back, often capturing arguments from the call that built it. The caller can apply it later, somewhere else.

A function that does both is higher-order on both counts. In real code, the pattern takes two forms:

- **Operations that take a function.** `Select`/`map`, `Where`/`filter`, `Aggregate`/`reduce`, `List.sort(comparator)`, `forEach`. The body is a fixed traversal; the caller plugs in the decision for each element. The library writes the traversal once; every call site writes only what varies.
- **Operations that build a function.** A factory that, given some configuration, returns a function with that configuration built in: `Multiplier(factor)` from [Axiom 9](axiom-09-first-class-functions.md), a `Comparator` builder, a function that composes two others. The result is a value the program can hold and reuse.

This axiom departs from three common defaults that do the same job with other constructs [2]:

- **Template Method.** An abstract base class with one method left for the subclass to fill in. The filled-in step is a function; inheritance is the long way to deliver it. A method that takes the step directly gives the same separation, without a class hierarchy.
- **Strategy as a one-method interface.** A single-method interface (`IComparer<T>`, Java's `Comparator<T>`) is, structurally, a function type. It is the right shape when the variation deserves a name and its own file. It is overhead when the variation is one lambda, passed at one call site and never named anywhere else.
- **Hand-written loops with mutable accumulators.** A `for` loop that walks a list to sum, find or transform reimplements the body of `Aggregate`, `First` or `Select` inline. The loop names neither the traversal nor the step; the higher-order version separates them, so the call site reads as the step alone.

C# (delegates, `Func<>`, `Action<>`) and Java (functional interfaces such as `Function<T, R>`, `Predicate<T>`, `BiFunction<T, U, R>`) both support HOFs fully. The rule is the same in both: when the same *shape* of code keeps appearing around a different *step*, the shape becomes a function that takes the step as a parameter.

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

The usual OO ways to say "this shape, with this step swapped in" are Template Method and Strategy as an interface. Both work, and both have a cost: a type per variation, a folder of small classes, a registration in the composition root. A function as a parameter gives the same separation in one parameter, with the variation living at the call site instead of in a new file.

One force pulls the other way: **debugging**. Chains of HOFs can be harder to step through, and the stack trace shows the wrapper while the lambda inside it is anonymous. A long pipeline of unnamed steps becomes opaque as soon as something needs investigating. The remedy is the rule from [Axiom 9](axiom-09-first-class-functions.md): name a function when it deserves a name. A `static` method passed to an HOF is as easy to find as any other method.

Not every place that "takes some behavior" should become a function. When the behavior really has several methods (open, read, close), the interface is the right shape (see *When NOT to*). This axiom is about the case where an interface exists only to wrap one operation.

---

## Why

**1. Shape and step become independently named.**
Every loop, wrapper and dispatch carries two ideas: the *shape* around the variation (walk every element, keep the ones that match, group by a key) and the *step* applied in the middle. A hand-written version mixes them in one block; an HOF separates them. The shape is named once, in the function definition; the step is named at the call site, where the variation actually lives. Two ideas, two names, one call, and the call site reads as the step alone. Hughes calls higher-order functions the *glue* that lets small definitions combine into large programs [1].

**2. A pure shape collapses to one definition.**
"Walk the list and keep a running total." "Check every field and collect the errors." "Group the items by a key." Without HOFs, each of these *shapes* gets rewritten around every *step*. With them, the shape is a function that takes the step as a parameter, and the number of places that must be right when the shape changes goes from many to one.

These are shapes of *pure* code. Impure plumbing (open a transaction, acquire a lock, log entry and exit) is a different case: see *When NOT to*.

**3. Configuration travels inside the returned function.**
A function that *returns* a function can build its configuration into the result. `PriceFormatter(culture, currency)` returns a function from an amount to its display text; the caller never passes `culture` or `currency` again. The factory's parameters disappear from the call site and reappear, unchanged, inside every later call of the value it produced. The returned function is the configuration *and* the behavior, packaged together.

**4. Collections lose the manual loop.**
With the standard library's higher-order operations (`Select`/`map`, `Where`/`filter`, `Aggregate`/`reduce`, `Sort` with a comparator), the common shapes of list traversal already have names. What varies per call is the function passed in; the call site says *what* it wants done, not *how* the loop should walk. A hand-written loop only survives where the shape is unusual enough that no library version expresses it, and that is rarer than the habit of writing `for` suggests.

---

## Trade-offs

- **Debugging.** A stack trace through `Map(items, item => Compute(item))` shows `Map` and a lambda; it doesn't show `Compute` by name. Stepping through is similar: the debugger enters the wrapper, then the lambda. For a shallow wrapper this is fine; for a deep chain of wrappers, the stack gets in the way. Name the inner functions when the chain gets deep enough to matter; anonymous lambdas are for cases where a name would add noise.
- **Type inference.** A function that takes a `Func<T, U>` sometimes needs an explicit type argument at the call site, because the compiler can't infer `T` and `U` from a bare lambda. The fix is local (annotate the lambda, or assign it to a typed variable), but the friction is real, especially in very generic helper APIs.
- **Discoverability.** A class implementing `IComparer<Order>` appears in *Find Usages*; a lambda passed inline doesn't. The remedy is the same as in [Axiom 9](axiom-09-first-class-functions.md): name the function when it deserves a name. A `static` method handed to an HOF shows up in the symbol index like any other method.

---

## When NOT to

Three cases where reaching for a function parameter is the wrong reflex:

- **Behavior that really has several methods.** `IEnumerator<T>` and `IObserver<T>` declare *several* operations that must be implemented together; their cohesion is the point of having a type. Collapsing them into one function loses something, so the interface is the right shape.
- **Behavior that needs a stable identity.** A plugin handler looked up by string key in a `Map<String, Function<...>>` works as long as the keys live inside the same program. A handler that has to survive serialization, be found by an annotation scanner, or be registered across processes needs a class: the same exception as in [Axiom 9](axiom-09-first-class-functions.md).
- **Wrapping impure plumbing.** Don't write reusable wrappers around impure steps, like a `WithTransaction(step)`, `WithLock(step)` or `Logged(step)` that every handler passes its work into. That hides impure code behind a reusable facade, and it is the generic handler with the business step passed in that [Axiom 7](axiom-07-cohesion.md#what-dry-is-for) warns against. Let each orchestration do its own transaction, locking and logging, in plain sight; where the framework already provides the wrapper, use it.

---

## References

[1] **John Hughes**, *Why Functional Programming Matters*, Research Topics in Functional Programming, Addison-Wesley, 1990. Already cited in earlier axioms. Listed again because its central argument, that higher-order functions (together with lazy evaluation) are the *glue* that lets small, simple definitions combine into large programs, is the classic case for this axiom. Its worked examples (`foldr`, `map`, numerical algorithms) are the standard demonstrations. <https://www.cs.kent.ac.uk/people/staff/dat/miranda/whyfp90.pdf>

[2] **Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides**, *Design Patterns: Elements of Reusable Object-Oriented Software*, Addison-Wesley, 1994. Template Method, Strategy and Command are the OO forms that higher-order functions replace at a lower cost. Already cited in [Axiom 9](axiom-09-first-class-functions.md); listed again because HOFs are how this book expresses those patterns when the variation is one function.

---

← Previous: [Axiom 9 — First-class functions](axiom-09-first-class-functions.md) · Next: [Axiom 11 — Pattern matching](axiom-11-pattern-matching.md) →
