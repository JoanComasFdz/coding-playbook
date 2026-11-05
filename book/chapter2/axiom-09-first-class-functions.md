# Axiom 9 — First-class functions

**A function is a value: it can be assigned to a variable, stored in a collection, passed as an argument and returned as a result.**

- A function value is the same kind of thing as a number or a record: created somewhere, named, moved around, called when needed.

Axioms [5](axiom-05-pure-functions.md) to [8](axiom-08-connascence.md) set the criteria for a well-formed function: pure, honest, total, cohesive and weakly coupled. This axiom names the property that lets the program itself combine such functions, instead of only the programmer, by hand: a function is not only something a program *does*. It is a *value* the program can hold, store, move and pass.

Through [Axiom 8](axiom-08-connascence.md)'s lens, this axiom weakens no connascence on its own. It is the *carrier* that later weakenings ride on. Once a function is a value, a dispatch carried by a `switch` on strings (a [Connascence of Meaning](axiom-08-connascence.md#connascence-of-meaning-com)) can become a lookup keyed by a type, such as an enum, that the compiler checks. First-class functions don't make that move; they make it *possible*.

---

## Definitions

A language has first-class functions when a function value is treated the same way as any other value. Concretely, a function can be:

- **assigned to a variable:** the function lives in a local variable or a field, like any other value;
- **stored in a data structure:** a list, a map, a record field;
- **passed as an argument:** to another function that calls it when ready;
- **returned as a result:** built at runtime and handed back to the caller, often capturing values from the scope that built it.

A function value carries two things: the operation it performs, and any values it captured from the scope that built it (a [*closure*](https://en.wikipedia.org/wiki/Closure_(computer_programming))). A [*lambda*](https://en.wikipedia.org/wiki/Anonymous_function) is the most compact way to create one: an anonymous function expression that evaluates to a value of a function type. But a reference to a named method (a method group in C#, a method reference such as `Pricing::total` in Java) is the same kind of value. Named or not, the thing being moved around is the function. Only calling it *runs* it; until then, the function value is just data, like any other.

C# (delegates, `Func<>`, `Action<>`, lambdas) and Java (functional interfaces such as `Function<T, R>`, `Predicate<T>` and `Supplier<T>`, lambdas, method references) both support all four uses. The capability isn't in question. The question is whether the codebase *treats* functions as values, or only as declarations that happen to compile.

---

## Example

A function value can be named, called, passed and stored, like a value of any other type.

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

A more interesting case: a function that builds and returns a function, capturing a value from the surrounding scope.

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

`Multiplier` is a factory: each call returns a new function value whose body still refers to the `factor` from the call that built it. The `factor` isn't stored in any object's field; it travels with the function value, in its closure. Once those functions exist, building a third from two of them is as simple as any other operation on values.

---

## Problem / forces

In OO codebases, the reflex is to express a piece of logic as a class (a strategy, a handler, a command) even when the logic is one line and has no state of its own. Many classic design patterns become simpler, or disappear, in languages with function values [1][2]. The result is a class, an interface and a registration for what could be one expression.

This axiom is the step before that: behavior is a *value* first, something the program can name, hold and pass around, like a number or a record. A class becomes a choice you make when the behavior and its data form something worth naming together, not a default the language imposes.

One force pulls the other way: **discoverability**. A named function shows up in the symbol index and in *Find Usages*; a lambda inside an expression doesn't (see *Trade-offs*).

---

## Why

**1. Behavior can be named and reused at its actual size.**
The shortest way to say "multiply by 1.20" is `a => a * 1.20m`: one line, one expression. As a value, that line can be given a name (`Func<decimal, decimal> withVat = a => a * 1.20m;`) and reused in many places, or left anonymous inside a larger expression (when to name it is in *Trade-offs*). The unit no longer has a minimum size set by the class that hosts it: behavior can be as small as the work it does.

**2. A function value moves like data.**
Once behavior is a value, it can live wherever any other value can: in a `Map<Key, Function<T, R>>`, in a record field, in a configuration object, in a queue. Dispatch becomes a lookup; registration becomes adding an entry. Behavior and data flow through the same shapes; there is no separate world of "things that do" next to the structures that hold "things that are".

**3. Closures carry data along with the function.**
As `Multiplier` shows in the *Example*, a closure brings its data and its operation to the call site together, as one value. The function doesn't need to look anywhere outside itself for the data it depends on.

The captured values have to be values in the sense of [Axiom 5](axiom-05-pure-functions.md): immutable, created once, and not shared with anything mutable. Otherwise the function value silently becomes impure. A closure is a way to carry data *into* a function value; it isn't a license for the function to reach *out*.

**4. It is the prerequisite for composition.**
Until a function can be passed as a value, combining two functions means calling one from the body of the other: a hard-coded chain. Once functions are values, the *combining itself* can be a function: one that takes two functions and returns a function that applies them in sequence. Composition becomes something the program can express, not just something the programmer writes out by hand.

---

## Trade-offs

- **Navigability.** A lambda inside an expression isn't a named declaration: it doesn't appear in the symbol index, and *Find Usages* doesn't point at it. For a one-off transformation, that's fine. For a function used in several places, it is usually time to give it a name. A `static` method or a named local function is enough; the name is the point, not a class around it. The rule is "name a function when it deserves a name", not "always wrap it in something bigger" and not "always inline a lambda".

---

## When NOT to

Two cases where reaching for a function value is the wrong reflex:

- **Behavior that must be found at runtime, by name, from outside the program.** A plugin system that loads handlers by a string identifier needs each handler to be something the runtime can locate: a fully qualified class name, an `@Component`-scanned bean, an assembly export. A `Map<String, Function<...>>` works inside one module; once a third party registers from outside, the runtime needs a handle that a function value alone doesn't provide.
- **Behavior whose framework integration needs a class.** Annotation- and attribute-driven scanning (`@Transactional`, `[Authorize]`), AOP proxies and lifecycle callbacks like `@PostConstruct` or `IDisposable` all work on classes. A function value can still be registered in and resolved from a DI container (both .NET's `IServiceCollection` and Spring's `@Bean` handle `Func<>` / `Function<T, R>` fine), but the framework's class-level hooks won't fire for it. Where those hooks do the work, the class isn't optional.

---

## References

[1] **Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides**, *Design Patterns: Elements of Reusable Object-Oriented Software*, Addison-Wesley, 1994. Its Strategy, Command and Visitor patterns are the ones first-class functions most directly replace. Many of its examples are in C++, which at the time had no lambdas, and several patterns work around exactly that.

[2] **Peter Norvig**, *Design Patterns in Dynamic Languages*, OOPSLA tutorial, 1996. The classic talk observing that 16 of the 23 GoF patterns become invisible or simpler in languages with features like first-class functions. <https://norvig.com/design-patterns/>

---

← Previous: [Axiom 8 — Connascence](axiom-08-connascence.md) · Next: [Axiom 10 — Higher-order functions](axiom-10-higher-order-functions.md) →
