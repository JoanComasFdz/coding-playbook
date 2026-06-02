# Axiom 10 — Higher-order functions

**A function is higher-order when it takes a function as a parameter, returns a function as its result, or both.**

- The function being passed or returned is just a value of a function type, like any other value.
- Higher-order functions are how a program names a *shape* once and lets callers fill in the *step*.

[Axiom 9](axiom-09-first-class-functions.md) named the prerequisite: a function is a value the program can hold, store, and pass. This axiom names what one *does* with that capability. Once functions fit through parameter slots and return types like any other value, a whole class of operations comes into reach — functions whose business is to combine, configure, or apply other functions. They are operations *over* function values, and they are where the day-to-day composition this playbook leans on actually lives.

Through [Axiom 8](axiom-08-connascence.md)'s lens, a higher-order function improves the *locality* of variation: the shape is named once in the function, and the step that varies is passed in as a typed value at the call site — where the variation actually lives. A behaviour each caller would otherwise re-implement by the same informal convention becomes one named, compiler-checked seam — a [Connascence of Type](axiom-08-connascence.md#connascence-of-type-cot) instead of a per-call agreement the compiler cannot see.

---

## Definitions

A function is **higher-order** when at least one of the following is true:

- **It accepts a function as a parameter.** The caller supplies a function value; the body invokes it as part of doing its work. The function value is one of the arguments — typed the same way any argument is typed.
- **It returns a function as its result.** The body produces a new function value and hands it back to the caller — often closing over arguments from the call that built it. The caller has a new function to apply later, somewhere else, on its own terms.

A function that does both — takes a function and returns one — is higher-order by either definition. The pattern appears at two distinct sizes in real code:

- **Operations that consume a function.** `Select`/`map`, `Where`/`filter`, `Aggregate`/`reduce`, `List.sort(comparator)`, `forEach`. The body is a fixed traversal; the caller plugs in the per-element decision. The library writes the traversal once; every call site writes only the variation.
- **Operations that produce a function.** A factory that, given some configuration, returns a function pre-bound to it: `Multiplier(factor)` from [Axiom 9](axiom-09-first-class-functions.md), a `Comparator` builder, a function-composition operator. The result is a value the program can hold and reuse, with the configuration already inside.

This axiom rejects three mainstream defaults that take on the same responsibility through other constructs:

- **Template Method.** An abstract base class with one method left abstract for the subclass to fill in. The "filled-in step" is a function; the inheritance hierarchy is the long way to deliver it. A method that takes the step directly is the same separation, with no class hierarchy to inherit through.
- **Strategy as a one-method interface.** A single-method interface (`IComparer<T>`, `Predicate<T>`) is, structurally, a function type. It is the right shape when the variation deserves a name and a directory entry. It is overhead when the variation is a single lambda passed at one call site and never named elsewhere.
- **Hand-rolled loops with mutable accumulators.** A `for` loop that walks a list to sum, find, or transform is the body of `Aggregate`, `First`, `Select` — re-implemented inline. The loop names neither the traversal nor the step; the higher-order version separates them so the call site reads as the step alone.

C# (delegates and `Func<>`/`Action<>`) and Java (functional interfaces — `Function<T, R>`, `Predicate<T>`, `BiFunction<T, U, R>`) provide first-class HOF support, but the discipline is the same in both: when the same *shape* of code appears around a different *step* every time it occurs, the shape becomes a function that takes the step as a parameter.

---

## Example

A function that *takes* a function — the traversal is owned by the function; the step is owned by the caller.

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

`Map` owns the traversal — walk every element, build a new list. Two callers reuse it with different steps; neither writes the loop. The loop only has to be right once.

A function that *returns* a function — the result is a new function value, configured by the arguments of the call that built it.

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

`Compose` is higher-order by both definitions at once: it takes two functions and returns one. The resulting `normalize` is not a method, not an object; it is a **closure** in the sense of [Axiom 9](axiom-09-first-class-functions.md) — the function value that applies `trim` and then `toLower`, with both captured from the call that built it. Ready to be passed anywhere a `Func<string, string>` is expected; the caller never needs to spell out the chain again.

The clearest sign that an HOF is wanting to be extracted is a piece of code where the *same shape* repeats with a different *step* in the middle: open and close a resource, walk and accumulate, retry on failure, time and report. Pull the step into a parameter; the shape goes from copy-pasted to written once.

---

## Problem / forces

The competing force is **the habit of expressing varying behaviour through inheritance or interface plumbing**. The dominant OO formulations for "this shape, with this step swapped in" are Template Method and Strategy-as-interface. Both work; both pay a tax — a type per variation, a directory of small classes, a wiring step in the composition root. A function-as-parameter delivers the same separation in one parameter slot, with the variation living at the call site instead of in a new file.

There is a real force in the other direction. HOF chains can be harder to step through in a debugger; the stack trace shows the wrapper but the lambda inside it is anonymous. A deeply chained pipeline of unnamed steps becomes opaque the moment something needs investigating. The remedy is the discipline from [Axiom 9](axiom-09-first-class-functions.md): name the function when it earns a name. A `static` method passed to an HOF is exactly as discoverable as a regular method.

Not every place that "takes a piece of behaviour" benefits from collapsing to a function. Where the behaviour is genuinely multi-method (open / read / close), the interface is the right shape and its cohesion is the point. The axiom is about the case where the interface exists only to wrap a single operation — that case is the function-shaped one.

---

## Why

**1. Shape and step become independently named.**
Every loop, every wrapper, every dispatch carries two ideas: the *shape* of what happens around the variation (walk every element, retry up to N times, log entry and exit, open a transaction), and the *step* applied at the variable spot. A hand-written version fuses them in one block of code; an HOF separates them. The shape is named once, in the function definition; the step is named at the call site, where the variation actually lives. Two ideas, two names, one call — the call site reads as the step alone.

**2. Boilerplate around an operation collapses to one definition.**
"Open transaction, run, commit on success, roll back on failure." "Acquire lock, run, release." "Log entry, run, log exit." Each is a *shape* that, without HOFs, ends up copy-pasted around every *step*. With them, the shape is a function that takes the step as a parameter. The number of places that have to be right when the shape changes goes from many to one.

**3. Configuration travels inside the returned function.**
A function that *returns* a function can pre-bind its configuration into the result. `RateLimiter(perSecond: 10)` returns the wrapped operation; the caller never sees `perSecond` again. The factory's parameters disappear from the call site and reappear, intact, inside every later call of the value it produced. The returned function is the configuration *and* the behaviour, packaged together.

**4. Collections lose the manual loop.**
Once the standard library's higher-order operations are available — `Select`/`map`, `Where`/`filter`, `Aggregate`/`reduce`, `Sort` with a comparator — the dominant shapes of list traversal already have names. The per-call variation is the function passed in; the call site says *what* it wants done, not *how* the loop should walk. A hand-written loop survives only where the shape is unusual enough that no library version expresses it — and that case is rarer than the habit of writing `for` suggests.

---

## Trade-offs

The first cost is **debugging shape**. A stack trace through `Map(items, item => Compute(item))` shows `Map` and a lambda; it does not show `Compute` by name. Step-through is similar — the debugger enters the wrapper and the lambda, in that order. For a shallow wrapper this is fine; for a deep chain of wrappers, the stack feels like an obstacle course. Name the inner functions when the chain gets deep enough to matter; an anonymous lambda is for cases where naming would add noise.

The second cost is **type-inference friction in some languages.** A function that takes a `Func<T, U>` parameter sometimes needs an explicit type argument at the call site because the compiler cannot infer `T` and `U` from a bare lambda. The fix is local — annotate the lambda, or assign it to a typed local — but the friction is real, especially in deeply generic helper APIs.

The third cost, in disciplined codebases, is **discoverability**. A class implementing `IComparer<Order>` appears in `Find Usages`; a lambda passed inline does not. The remedy is the same as in [Axiom 9](axiom-09-first-class-functions.md): name the function when it earns a name. A `static` method handed to an HOF participates in symbol indexing exactly as any other method.

---

## When NOT to

Two cases where the function-as-parameter reflex is the wrong reflex:

- **Behaviour that is genuinely multi-method.** An `IDisposable`, an `IEnumerator<T>`, an `IObserver<T>` declare *several* operations that have to be implemented together; their cohesion is the point of having a type. Collapsing to a single function is a degradation; the interface is the right shape.
- **Behaviour that needs a stable identity.** A plugin handler resolved by string key from a `Map<String, Function<...>>` works as long as the keys live inside the same program. A handler that has to survive serialization, scanning by an annotation processor, or registration across processes needs a class — the same exception called out in [Axiom 9](axiom-09-first-class-functions.md).

---

## References

[1] **John Hughes**, *Why Functional Programming Matters*, Research Topics in Functional Programming, Addison-Wesley, 1990. Already cited in earlier axioms; cross-listed here because its central argument — that higher-order functions are the *glue* that makes small, simple definitions compose into large programs — is the formal case for this axiom. The paper's worked examples (`foldr`, `map`, numerical algorithms parameterised by their step) are the canonical demonstrations.
<https://www.cs.kent.ac.uk/people/staff/dat/miranda/whyfp90.pdf>

[2] **Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides**, *Design Patterns: Elements of Reusable Object-Oriented Software*, Addison-Wesley, 1994. Template Method, Strategy, and Command are the OO formulations that higher-order functions replace at smaller cost. Already cited in [Axiom 9](axiom-09-first-class-functions.md); included again because this is where those patterns *resolve* — HOFs are how the playbook expresses them when the variation is one function.
