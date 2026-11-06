# Axiom 15 — Unit

**When a function has nothing meaningful to return, return `Unit`: a type with exactly one value.**

- "Nothing to say" is still a value. The function returns *the* `Unit` value, the way another function returns its `int`.
- Unlike `void`, `Unit` is a real type, so it fits anywhere a type fits: a variable, a generic argument, a lambda's return type, one side of an `Either`.

[Axiom 6](axiom-06-honest-total-signatures.md) put every outcome in the return type, and [Axiom 14](axiom-14-either.md) gave two-outcome results a shape. This axiom covers the smallest case: one outcome that carries no information. It still deserves a type, and `Unit` (the [unit type](https://en.wikipedia.org/wiki/Unit_type), which ML-family languages have always had [1]) is the smallest one there is.

Through [Axiom 8](axiom-08-connascence.md)'s lens, `Unit` removes a [Connascence of Meaning](axiom-08-connascence.md#connascence-of-meaning-com). A dummy return value (a `bool` that is always `true`, a `0`, a `null`) needs every caller to know, by convention, that it means "done, ignore me". `Unit` has one value and carries no information, so there is nothing to agree on and nothing to misread.

---

## Definitions

A *Unit*:

- **Has exactly one value.** Every expression of type `Unit` gives the same value. There is nothing to inspect, compare or branch on.
- **Carries no information.** Getting a `Unit` back tells you the function returned. Nothing more.
- **Is an ordinary type.** A `Unit` can be stored, passed, returned from a lambda and used as a generic argument, like an `int`.

The third point is what matters. `void` is not a type: it marks a method that returns no value, and the language treats such methods differently from everything else. (It does *not* mean "never returns": that is a different type, the [bottom type](https://en.wikipedia.org/wiki/Bottom_type), with no values at all [2].) A method returning `Unit` is a function like any other.

---

## Example

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public readonly struct Unit
{
    public static readonly Unit Value = default;
}

Unit Greet(string name)
{
    Console.WriteLine($"Hello, {name}!");
    return Unit.Value;
}

Func<string, Unit> step = Greet;    // ✅
// Func<string, void> step = ...;   // ❌ doesn't compile
```

</td>
<td>

```java
public enum Unit { INSTANCE }

Unit greet(String name) {
    System.out.println("Hello, " + name + "!");
    return Unit.INSTANCE;
}

Function<String, Unit> step = this::greet;   // ✅
// Function<String, void> step = ...;        // ❌ doesn't compile
```

</td>
</tr>
</table>

`Greet` written as `void` works fine at the call site, but its result can't be named: it can't be assigned, returned from a lambda, or fit a slot typed "a function from `string` to *something*". `Unit` fills that gap by being *something*.

---

## Problem / forces

Mainstream code has three ways to say "this function has nothing to return", and each one breaks something:

- **`void`.** It isn't a type, so it can't fill a generic slot. That is why the standard libraries come in pairs: `Action` and `Func`, `Task` and `Task<T>` in C#; `Consumer` and `Function`, `Runnable` and `Callable` in Java. Every piece of code that works on functions generically has to handle the `void` case separately, or not at all.
- **A dummy return value.** A `bool` that is always `true`, an `int` that is always `0`. The signature claims there is an answer when there isn't, and the next caller can't tell whether the value means anything (see the [Axiom 8](axiom-08-connascence.md) note above).
- **`null` as "done".** Java's own `Void` is "an uninstantiable placeholder class" [3], so a `Function<T, Void>` can only return `null`. That gives `null` yet another meaning on top of the ones [Axiom 13](axiom-13-maybe.md#problem--forces) already lists.

---

## Why

**1. Every function has the same shape.**
With `Unit`, every function takes inputs and returns a value. Code that works on functions ([Axiom 10](axiom-10-higher-order-functions.md)) needs no separate version for the no-result case, and a pipeline of `T -> U` steps works whether the last `U` carries information or is `Unit`.

**2. It fills an empty side.**
A two-outcome type needs a type on each side. An operation that can fail but has nothing to return when it succeeds is an `Either<string, Unit>`: an error message, or "done". Without `Unit` there is nothing to put on the success side, short of `void` (not allowed) or `null` (dishonest).

---

## Trade-offs

- **A little ceremony.** Every `Unit` function ends with `return Unit.Value;` where a `void` method would just end. That is the price for every function fitting the same machinery.
- **You define it yourself.** Neither C# nor Java has a built-in `Unit`. The usual shape is a single-value type: a field-less `struct` in C#, a one-constant `enum` in Java. Some C# libraries ship one (Rx's `System.Reactive.Unit`, MediatR's `Unit`), so check before adding another.

---

## When NOT to

- **When the function can fail.** A plain `Unit` return type says the function always succeeds. If it can fail, there are two outcomes, and both belong in the return type ([Axiom 6](axiom-06-honest-total-signatures.md)). Put `Unit` on the success side of a two-outcome type instead (see *Why*, point 2). Returning a plain `Unit` and throwing on failure is as dishonest as `void` and throwing.
- **At a framework's `void` boundary.** A `void OnButtonClicked()` handler that the framework calls isn't yours to change, and the framework would ignore the return value anyway. Use `void` there, and switch to `Unit` one layer in if the rest of the code wants it.
- **For an async operation with no result.** In C#, `Task` already is "an async `Unit`". `Task<Unit>` is noise unless you are writing generic code that can't special-case `Task`. The same goes for `CompletableFuture<Void>` in Java.
- **When the function does have an answer.** Don't reach for `Unit` to simplify a function that has something to report. Give it its honest return type ([Axiom 6](axiom-06-honest-total-signatures.md)).

---

## References

[1] **Robin Milner, Mads Tofte, Robert Harper, David MacQueen**, *The Definition of Standard ML (Revised)*, MIT Press, 1997. The type `unit` and its single value `()` are core ML; the "no meaningful return" convention in ML-family languages comes from there.
<https://mitpress.mit.edu/9780262631815/the-definition-of-standard-ml/>

[2] **Haskell** `Data.Void` and the unit type `()`. Haskell names both types that C-family `void` blurs together: *unit* (one value: "no information") and *Void* (no values: "never returns").
<https://hackage.haskell.org/package/base/docs/Data-Void.html>

[3] **`java.lang.Void`**, Java SE 21 documentation: "The `Void` class is an uninstantiable placeholder class to hold a reference to the `Class` object representing the Java keyword void."
<https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/Void.html>

---

← Previous: [Axiom 14 — Either](axiom-14-either.md) · Next: [Axiom 16 — Result](axiom-16-result.md) →
