# Axiom 9 — First-class functions

**A function is a value — it can be assigned to a variable, stored in a collection, passed as an argument, and returned as a result.**

- A function value is the same kind of thing as a number or a record: created somewhere, named, moved around, called when needed.

[Axiom 6](axiom-06-honest-total-signatures.md) set the criterion for a function worth keeping — every outcome named in the return, every input the type admits accepted by the body. This axiom names the property that lets two such functions be composed at all: a function is not only something a program *does* — it is a *value* the program can hold, store, move, and pass.

Through [Axiom 8](axiom-08-connascence.md)'s lens, this axiom weakens no connascence on its own — it is the *carrier* the later weakenings ride on. Once a function is a value, the operation that composes functions is a value too, and a dispatch once carried by a stringly-keyed `switch` (a [Connascence of Meaning](axiom-08-connascence.md#connascence-of-meaning-com)) can become a typed lookup the compiler checks. First-class functions don't make that move; they make it *available*.

---

## Definitions

A language has first-class functions when a function value is treated the same way as any other value. Concretely, a function can be:

- **assigned to a variable** — the function lives in a local or a field like any other value.
- **stored in a data structure** — a list, a map, a record field; the function value is what is held.
- **passed as an argument** — to another function that will call it when ready.
- **returned as a result** — built dynamically and handed back to the caller, often closing over local state.

A function value carries two things at once: the operation it performs and any state it has closed over from the scope that built it. A *lambda* is the most compact way to create one — an anonymous function expression that evaluates to a value of a function type — but a named static method or a method reference is the same kind of value. Whether it has a name or not, the thing being moved around is the function. Calling it is the only thing that *runs* it; until that call happens, the function value is just data, like any other.

Both C# (delegates, `Func<>`, `Action<>`, lambdas) and Java (functional interfaces — `Function<T, R>`, `Predicate<T>`, `Supplier<T>`, lambdas, method references) support all four uses natively. The capability is not in question; the discipline is whether the codebase *treats* functions as values, or only as declarations that happen to compile.

---

## Example

A function value can be named, called, passed, and stored — like a value of any other type.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// Create and name a function value.
Func<int, int> square = x => x * x;

// Apply it directly.
int nine = square(3);

// Pass it where another function is expected.
var squared = numbers.Select(square);

// Store it alongside others.
var operations = new List<Func<int, int>> { square, x => x + 1 };
```

</td>
<td>

```java
// Create and name a function value.
Function<Integer, Integer> square = x -> x * x;

// Apply it directly.
int nine = square.apply(3);

// Pass it where another function is expected.
var squared = numbers.stream().map(square);

// Store it alongside others.
List<Function<Integer, Integer>> operations = List.of(square, x -> x + 1);
```

</td>
</tr>
</table>

`square` is a value of type `Func<int, int>` / `Function<Integer, Integer>`. It can be applied immediately, given to a method that wants a function, or kept in a list. The type names what goes in and what comes out; the value is the function itself.

A more interesting case: a function that builds and returns a function, closing over state from the surrounding scope.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public static Func<decimal, decimal> Multiplier(decimal factor) =>
    amount => amount * factor;

// Two functions built from the same factory, each closing over its own factor.
var withVat    = Multiplier(1.20m);
var halfPrice  = Multiplier(0.50m);

// A third function built by hand, calling the first two in sequence.
Func<decimal, decimal> halfPriceWithVat = amount => halfPrice(withVat(amount));
```

</td>
<td>

```java
public static Function<BigDecimal, BigDecimal> multiplier(BigDecimal factor) {
    return amount -> amount.multiply(factor);
}

// Two functions built from the same factory, each closing over its own factor.
var withVat   = multiplier(new BigDecimal("1.20"));
var halfPrice = multiplier(new BigDecimal("0.50"));

// A third function built by hand, calling the first two in sequence.
Function<BigDecimal, BigDecimal> halfPriceWithVat =
    amount -> halfPrice.apply(withVat.apply(amount));
```

</td>
</tr>
</table>

`Multiplier` is a factory: each call returns a new function value whose body still refers to the `factor` from the call that built it. The `factor` is not stored in any object's field — it travels with the function value through the *closure*. Once those functions exist, building a third by composing two of them is as straightforward as any other value-level operation.

---

## Problem / forces

The competing force is **the habit of seeing behaviour as something that requires a host**. In OO codebases the reflex is to express a piece of logic as a class — a strategy, a handler, a command — even when the logic is one line and has no state of its own. This axiom is the prior step that says behaviour is a *value* before it is anything else: a thing the program can name, hold, and pass around, just like a number or a record. The class becomes a choice the design makes when behaviour and the data it operates on form a thing worth naming together, not a default the language imposes.

A second force is **discoverability**. A function with a name shows up in the symbol index, in `Find Usages`, in the package list. An anonymous lambda inside an expression does not. The trade-off is real, but it bites only when the behaviour deserves a name — for a small transformation that the surrounding code already organises (a row in a map, a step in a pipeline), no extra name is owed.

---

## Why

**1. A behaviour can be named and reused at its actual size.**
The shortest expression of "multiply by 1.20" is `a => a * 1.20m` — one line, one expression. As a value, that line can be given a name (`var withVat = a => a * 1.20m;`) and reused in many places, or left anonymous inside a larger expression when it does not earn a name. The size of the unit no longer has a floor set by the host construct that carries it; behaviour can be as small as the work it does, and as named or unnamed as the surrounding code wants.

**2. A function value moves like data.**
Once a behaviour is a value, it lives wherever any other value can live: in a `Map<Key, Function<T, R>>`, in a record field, in a configuration object, in a queue. Dispatch becomes a lookup; registration becomes a put. Behaviour and data flow through the same shapes — there is no separate world of "things that do," running in parallel to the structures that hold "things that are."

**3. Closures carry state along with the function.**
A function value can capture variables from the scope that built it. In `Multiplier`, the returned lambda's body refers to `factor` — a value from the calling scope — and the function value remembers it for every later call, no matter where that call happens. The function value plus those captured bindings is what the language calls a **closure**. State and operation arrive at the call site together, as a single value; the function does not need to look anywhere outside itself to find the data it depends on.

The captured bindings have to be values in the sense of [Axiom 5](axiom-05-pure-functions.md) — themselves immutable, produced once, not aliased to mutable shared state — or the function value silently becomes impure. Closure is a mechanism for carrying data *into* a function value; it is not a license for the function value to reach *out*.

**4. It is the prerequisite for composition.**
Until a function can be passed as a value, composing two functions means calling one from the body of the other — a hard-coded chain. Once functions are values, the *composing operation itself* becomes a function: one that takes two functions and returns the function that applies them in sequence. Composition becomes something the program can express, not just something the programmer can write out by hand.

---

## Trade-offs

The honest cost is **navigability**. A lambda inside an expression is not a named declaration; it does not appear in the symbol index, and `Find Usages` does not point at it. For a single throwaway transformation, this is fine. For a function used in several places, it is usually time to give it a name — but a `static` method or a named local function is enough; the name is the point, not the host. The discipline is "name the function when it earns a name," not "always wrap it in something larger" and not "always inline a lambda."

---

## When NOT to

Two cases where the function-value reflex is the wrong reflex:

- **Behaviour that must be discoverable at runtime by name from outside the program.** A plugin system that loads handlers by string identifier needs each handler to be a thing the runtime can locate — a fully qualified class name, an `@Component`-scanned bean, an assembly export. A `Map<String, Function<...>>` works inside a single module; once a third party registers from outside, the runtime needs a handle the function value alone does not offer.
- **Behaviour whose framework integration needs the class as the unit.** Annotation/attribute-driven scanning (`@Transactional`, `[Authorize]`), AOP proxies, and lifecycle callbacks like `@PostConstruct` or `IDisposable` all key off a class. A function value can still be registered and resolved from a DI container (both .NET's `IServiceCollection` and Spring's `@Bean` machinery handle `Func<>` / `Function<T, R>` fine), but the framework's class-level hooks won't fire for it. Where those hooks are doing the work, the class is not optional.

---

## References

[1] **Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides**, *Design Patterns: Elements of Reusable Object-Oriented Software*, Addison-Wesley, 1994. The book whose Strategy, Command, and Visitor patterns are the ones first-class functions most directly collapse. Reading it today reveals how many of its patterns are workarounds for the absence of function values in early C++ and Smalltalk.

[2] **Peter Norvig**, *Design Patterns in Dynamic Languages*, OOPSLA tutorial, 1996. The classic talk that observed that 16 of the 23 GoF patterns become "invisible, simpler, or partly built into the language" once functions are first-class. The patterns that survive are the ones that organise *more than one* related behaviour.
<https://norvig.com/design-patterns/>
