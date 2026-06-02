# Axiom 15 — Unit

**A type with a single value, for "nothing meaningful to return."**

- Treat "no meaningful answer" as a value, not as the absence of one. A function with nothing useful to give back still returns *something* — the one value of a type whose only job is to be returned.

> Unit is a *structural* primitive — small, plain, almost invisible. It earns its keep wherever a slot that wants a type wants the answer "no information here."

[Axiom 1](axiom-01-data-vs-behaviour.md) says data is a value; [Axiom 6](axiom-06-honest-total-signatures.md) says every outcome belongs in the return type; [Axiom 14](axiom-14-either.md) says distinct outcomes belong there as values. This axiom adds the smallest case: when there is *one* outcome and it carries no information, it still belongs in the return type as a value — and `Unit` is the minimum way to spell that.

Through [Axiom 8](axiom-08-connascence.md)'s lens, `Unit` *eliminates* a [Connascence of Meaning](axiom-08-connascence.md#connascence-of-meaning-com): a function with nothing useful to say otherwise hands back a dummy — a `bool` that is always `true`, a `0`, a `null` — and the caller has to know by convention that the value means "succeeded, ignore me." `Unit` removes the thing to agree on; there is exactly one value, it carries no information, and so there is nothing left to misread.

---

## Definitions

A *Unit*:

- **Has exactly one value.** Every expression of type `Unit` evaluates to the same value. There is nothing to inspect, nothing to compare, nothing to branch on.
- **Carries no information.** Knowing a function returned `Unit` tells you that the function returned. That is all.
- **Is an ordinary type.** A function returning `Unit` is a function in the same sense as a function returning `int`: its return value can be stored in a variable, passed to another function, held in a generic slot, returned from a lambda.

The third bullet is the whole point. Mainstream `void` is *not* a type — it is a marker that says "this function does not return," and the language gives `void`-returning functions a different shape from everything else. `Unit` is a type, and a function returning `Unit` is a function like any other.

A signature `T -> Unit` makes one more promise worth naming explicitly: **the function always returns and always with the same answer**. There is no failure case hiding in the return type. Unit is the return type of **functions that cannot fail**; when failure is possible, that outcome must live in the return type too ([Axiom 6](axiom-06-honest-total-signatures.md)).

---

## Example

A function that does some work and has nothing meaningful to give back. With `Unit`, it returns *the* Unit value, like any other function returns its result.

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

var done = Greet("Joan");
// `done` is a value of type Unit.
// It can be stored, passed, returned,
// or held in a generic slot like any other value.
```

</td>
<td>

```java
public enum Unit { INSTANCE }

Unit greet(String name) {
    System.out.println("Hello, " + name + "!");
    return Unit.INSTANCE;
}

void main(String[] args) {
    var done = greet("Joan");
    // `done` is a value of type Unit.
    // It can be stored, passed, returned,
    // or held in a generic slot like any other value.
}
```

</td>
</tr>
</table>

The same function written `void Greet(string)` works at the call site but its result is unreachable: it cannot be assigned to a variable, returned from a lambda, or held in a collection of "functions from `string` to *something*." Unit closes that gap by being *something*.

---

## Problem / forces

Mainstream code has three ways to spell "this function has nothing meaningful to return," and all three break composition:

- **`void`.** The canonical signal for "no return." It is, however, not a type — you cannot write `List<Function<T, void>>`, you cannot return a `void`-returning lambda from another function, and you cannot pass a `void`-returning function into a generic slot that expects "some function from `T` to *something*." `void` is a hole punched in the type system: every place in the codebase that operates on functions generically has to either special-case it or refuse to handle it. The duplication mainstream APIs accept — separate `Action`/`Func`, separate `Task`/`Task<T>`, separate `Consumer`/`Function`, separate overloads for the no-result case — is the cost of `void` being outside the type system.

- **A dummy return value.** A `bool` that always returns `true`, an `int` that always returns `0`, a useless string. The signature now lies twice: it says "I return a `bool`" when there is nothing to say, and it tempts the caller to read the meaningless byte. The compiler cannot tell which return values are real signal and which are decorative; the next caller cannot either.

- **`null` as "I did the thing, nothing to give back."** The signature says `Object` or `T`; the actual answer is "operation completed." The same `null` that means "I have nothing for you" elsewhere now means "I succeeded." Conflating those meanings is exactly what [Axiom 13](axiom-13-maybe.md) calls out — and reusing `null` to fill a different gap is the same lie in different clothing.

Unit fixes all three by being a real type with a real (single) value. The function returns it; the caller can ignore it, store it, or pass it on. Every place that operates on "a function returning *something*" includes Unit-returning functions without a special case.

---

## Why

**1. "No meaningful return" is still a value.**
A function with no useful answer to give still ran. The honest way to spell "it ran" is a value the caller can receive — not a hole in the type system. `Unit` is that value: one value, one type, no information, no decisions to make about it. The fact that there is *exactly one* of it is the point — knowing you received a `Unit` carries no information beyond "you received it," which is the same information the void-returning version was trying to convey by *not* returning.

**2. Uniform shape across every function.**
Once "no meaningful return" is a type, every function in the codebase has the same shape: it takes some inputs, it returns some output. Generic code over functions ([Axiom 10](axiom-10-higher-order-functions.md)) does not need a parallel implementation for the void case. A pipeline whose stages are typed `T -> U` works whether the final `U` carries information or is `Unit`. The special-casing collapses.

**3. The single-value rule preserves honesty.**
A `Unit` carries no payload, so there is nothing for a caller to misinterpret. Compare with the dummy-`bool` form: a caller staring at `bool DoTheThing()` is right to wonder whether the bool means anything, and may write defensive code around it. A caller staring at `Unit DoTheThing()` cannot wonder — the type itself promises there is no information.

---

## Trade-offs

Unit costs **a small piece of typing ceremony** at every site that returns it: `return Unit.Value` instead of falling off the end of a `void` method. In a codebase that lives inside the type system end-to-end, that is bookkeeping — the trade is that every function fits in the same machinery, which is what makes composition cheap. In a codebase that uses `void` heavily at boundaries (UI handlers, framework callbacks, JUnit tests), Unit does *not* replace `void` everywhere; it earns its keep in code that wants to be composed.

Languages without a built-in `Unit` (mainstream C# and Java both) require you to define one. The standard shape is a singleton type — a struct or record or enum with no fields and a single value. C# borrows the name from Rx (`System.Reactive.Unit`) and from MediatR; Java codebases commonly define a `Unit` enum with a single constant, or pull it in from a small library.

---

## When NOT to

**When the function can fail.** Unit names *one* outcome carrying no information — the signature asserts the function always returns successfully. A function that can succeed or fail has *two* outcomes; both belong in the return type ([Axiom 6](axiom-06-honest-total-signatures.md), [Axiom 14](axiom-14-either.md)). Returning `Unit` from a fallible function — and throwing on the bad case, or letting the caller guess — is the same dishonesty as returning `void` while throwing: the failure case has nowhere to live.

**At framework-defined `void` boundaries.** A `void OnButtonClicked()` handler that the framework calls is not yours to redesign; the signature is fixed and the framework discards anything you return. Use `void` there and let the next layer in lift to `Unit` if the rest of the code wants uniformity.

**For an async operation with no result.** `Task` already plays the role of "the async version of `Unit`" in idiomatic C#; introducing `Task<Unit>` is noise unless you are writing generic infrastructure that cannot special-case `Task`. Java's `CompletableFuture<Void>` is the equivalent and the same rule applies.

**When the function does have a useful answer.** Reaching for `Unit` to "simplify" a signature whose function does have something to report is the wrong direction — give the function its honest, total return type ([Axiom 6](axiom-06-honest-total-signatures.md)).

---

## References

[1] **Robin Milner, Mads Tofte, Robert Harper, David MacQueen**, *The Definition of Standard ML (Revised)*, MIT Press, 1997. The type `unit` and its sole value `()` are core ML, and the convention for "no meaningful return" in every ML-family language descends from there.
<https://mitpress.mit.edu/9780262631815/the-definition-of-standard-ml/>

[2] **Haskell** `Data.Void` and the unit type `()`. Worth distinguishing the two by name: *Unit* (one inhabitant — "no information") and *Void* (zero inhabitants — "this function does not return at all") are different types that both replace the C-family `void` keyword, for different reasons.
<https://hackage.haskell.org/package/base/docs/Data-Void.html>

---

← Previous: [Axiom 14 — Either](axiom-14-either.md) · Next: [Axiom 16 — Result](axiom-16-result.md) →
