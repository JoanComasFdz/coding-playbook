# Axiom 7 — Honest, total signatures

**A signature is honest when every outcome the function can produce is named in its return type. It is total when the function is defined for every value of its input types.**

- Honesty rules out hidden outcomes: sentinel values, silent nulls, magic strings, exceptions used as control flow.
- Totality rules out forbidden inputs: values the function is "undefined" for, where the caller is just expected to know.

[Axiom 6](axiom-06-pure-functions.md) named purity, which closes the back door between a function and the world: no hidden inputs or outputs. This axiom closes the front door. Both are [Axiom 1](axiom-01-explicit-over-implicit.md)'s explicitness, applied: purity to inputs and effects, this axiom to outcomes. A pure function can still lie through its signature:

- by returning a sentinel the type system can't help the caller see;
- by being silently undefined on inputs the type accepts but the body refuses.

So this axiom asks the next two questions: is *every* outcome represented in the return type, and is the function *actually defined* for every value its input types allow?

Naming every outcome is also where [Axiom 0](axiom-00-ubiquitous-language.md) first gets enforced: a return type that spells out *what* happened (`NotFound`, `InsufficientFunds`) uses the domain's words, where a bare `bool` or a sentinel leaves the outcome without a name.

---

## Definitions

Two properties of a signature, both visible *without* running the program.

A signature is **honest** when:

- **Every outcome is represented in the return type.** A value that really means one of two things, decoded by the caller by convention, is dishonest (see the sentinels and nulls below).
- **No outcome comes through a side channel.** Throwing to signal an *expected* outcome is dishonest in the same way: the type says one thing, the runtime delivers another. (Purity already rules this out inside a pure function; honesty makes it explicit in the signature.)
- **No hidden return values in parameters.** An `out` or `ref` parameter is a second return value the signature doesn't admit to.

The smallest dishonest case is a bare `bool`. Returning `true`/`false` collapses the outcomes into two cases with no names. This is called *boolean blindness* [3]: the caller learns *that* something holds, but not *what*, and has nothing useful to carry forward. Replacing that `bool` with named cases is the same fix as replacing a sentinel `int` (below).

A function is **total** when:

- **Every value of every parameter type produces a defined result.** `decimal Divide(int a, int b)` is undefined for `b == 0`. `T Head<T>(List<T> xs)` is undefined for an empty list.
- **Totality is about the *declared types*, not the values that happen to arrive.** A function that "only ever gets valid inputs" in production is still partial. The type system just hasn't noticed yet.

A function that isn't total is [*partial*](https://en.wikipedia.org/wiki/Partial_function).

The two properties go together. Most ways to make a partial function total also make it honest, by widening the return type to include the cases that used to be undefined. Turn `decimal Divide(int, int)` into something whose return type distinguishes "the quotient" from "the divisor was zero", and you fix both at once.

This axiom departs from four common defaults:

- **[Sentinel values](https://en.wikipedia.org/wiki/Sentinel_value).** `IndexOf` returning `-1`; `Array.BinarySearch` returning a negative number; "the empty string means absent". A magic value smuggles a second outcome through a type that has no room for it. The compiler can't make callers check, and production finds the cases the tests missed.
- **`null` as a silent second meaning.** A `User` is "really" `User` or `null`, but the signature doesn't say which methods return which. Every caller pays for that silence, either by checking too much (defensive `?.` everywhere) or too little (a `NullReferenceException` at 3 a.m.).
- **`out` / `ref` for "did it work".** `TryGetValue`, `int.TryParse(s, out var i)`. These were useful idioms before nullable references and richer return types, but each one pretends the result is a `bool` while a second value comes out on the side. (Java has no `out` parameters, but a mutable "holder" argument does the same.)
- **Implicit partiality.** A body that assumes some inputs "won't happen", like the zero divisor or the empty list above, or a malformed string. The assumption lives in someone's head, not in the type system, and the next caller has no way to know it.

---

## Example

Two dishonest functions:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public static int FindOrderIndex(IReadOnlyList<Order> orders, Guid id)
{
    for (var i = 0; i < orders.Count; i++)
        if (orders[i].Id == id) return i;
    return -1; // not found: the caller must know to check
}

public User GetUser(Guid id)
{
    return repository.FindById(id); // may be null; the signature is silent
}
```

</td>
<td>

```java
public static int findOrderIndex(List<Order> orders, UUID id) {
    for (var i = 0; i < orders.size(); i++)
        if (orders.get(i).id().equals(id)) return i;
    return -1; // not found: the caller must know to check
}

public User getUser(UUID id) {
    return repository.findById(id); // may be null; the signature is silent
}
```

</td>
</tr>
</table>

`FindOrderIndex` is pure under [Axiom 6](axiom-06-pure-functions.md): no clock, no I/O, no captures. `GetUser` isn't, since it reads from the repository, but purity isn't the point here. Both lie:

- `FindOrderIndex` promises an `int` and delivers "an index *or* a sentinel".
- `GetUser` promises a `User` and delivers "a user *or* nothing".

Neither the caller nor the compiler can tell from the signature that there are two outcomes. Every caller has to remember, and the bug is the call that forgets.

A signature that names every outcome:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public abstract record FindResult;
public sealed record Found(int Index) : FindResult;
public sealed record NotFound : FindResult;

public static FindResult FindOrderIndex(IReadOnlyList<Order> orders, Guid id)
{
    for (var i = 0; i < orders.Count; i++)
        if (orders[i].Id == id) return new Found(i);
    return new NotFound();
}
```

</td>
<td>

```java
public sealed interface FindResult permits Found, NotFound {}
public record Found(int index) implements FindResult {}
public record NotFound() implements FindResult {}

public static FindResult findOrderIndex(List<Order> orders, UUID id) {
    for (var i = 0; i < orders.size(); i++)
        if (orders.get(i).id().equals(id)) return new Found(i);
    return new NotFound();
}
```

</td>
</tr>
</table>

The return type now lists every outcome. The caller can't get an `int` out without first checking which case it has. In Java, the `sealed` interface lets the compiler check that a `switch` handles both cases; in C#, the caller still has to branch on the type before it can reach `Index`. The function went from a dishonest `int` to an honest `FindResult` that tells the caller what happened.

That was one path to honesty and totality: widen the *output* until every outcome has a name. The other path is to narrow the *input* until every value the type allows is one the body can handle.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// NonZeroInt can only hold values that aren't zero.
public static decimal Divide(int numerator, NonZeroInt denominator)
{
    return (decimal)numerator / denominator.Value;
}
```

</td>
<td>

```java
// NonZeroInt can only hold values that aren't zero.
public static BigDecimal divide(int numerator, NonZeroInt denominator) {
    return BigDecimal.valueOf(numerator)
        .divide(BigDecimal.valueOf(denominator.value()),
                MathContext.DECIMAL128);
}
```

</td>
</tr>
</table>

`Divide` no longer has a bad case to report. The input type can't hold a zero, so the body has no value to refuse. The check has moved upstream, to whoever creates the `NonZeroInt`, and `Divide` is total without widening its output. (The Java version passes a `MathContext` because `BigDecimal.divide` without one throws on results like 1/3, which would make the function partial again.)

Widen the output or narrow the input: both lead to the same property, and most real fixes use a mix of the two.

There is a third, blunter route: **define the failing case out of existence**. Redesign the operation so the input that used to be illegal now has a sensible, defined answer:

- a `Substring` that *clamps* an out-of-range length to what the string actually has;
- a delete that simply *succeeds* when the row is already gone ([idempotent](https://en.wikipedia.org/wiki/Idempotence));
- a lookup that returns an empty list for an empty query, instead of refusing it.

Each is total not because its output was widened or its input narrowed, but because the operation was *redefined* until no input is an error [4]. It is the most aggressive form of this axiom: the cheapest outcome to handle is the one that no longer exists. Its danger matches its power, and *When NOT to* draws the line.

---

## Problem / forces

A dishonest signature costs you later, in two places:

- **The next caller.** Three months on, in another file, copying the call from somewhere else, they can't learn the convention from the type. The IDE shows `int`; it doesn't show "careful, `-1` means not found" (see *Why*, point 1).
- **Refactoring.** When the function later needs a new outcome, a dishonest signature has nowhere to put it except another sentinel, and the bug ships (see *Why*, point 2).

One force pulls the other way: **brevity in the small**. `return -1` is shorter than wrapping the result in a named type, and `return null` is shorter still. In a method called from three places, all written by the same person in the same week, the dishonest signature works fine: everyone remembers the convention because they just wrote it.

Not every possible outcome belongs in the return type, though. Honesty asks for the outcomes the function *produces as part of its own logic*, not for every way the world can fail (see *When NOT to*).

---

## Why

**1. The signature is the only contract the next caller will read.**
Documentation goes stale, tests prove what exists but not what's missing, and comments are only advice. The signature is the one thing every caller is forced to look at, and the compiler checks the body against it. When the signature carries the function's real behavior (every outcome, every accepted input), the API documents itself as you write it. Every gap between the signature and the body is something the next caller has to learn somewhere else.

**2. Honest outcomes turn runtime bugs into compile errors.**
When the return type names every outcome, the caller has to handle every case, and with exhaustive checks the compiler tracks it. Add a new case and the compiler points at every place that needs updating. A function that returns an `int` with a sentinel can take on a second sentinel without its type changing, and every caller that relied on the old convention silently breaks. Honesty is one of the cheapest forms of static analysis a codebase can have, and you pay for it once, by writing the signature.

**3. Totality removes a whole kind of "didn't expect that" bug.**
Production crashes that come down to *"the input was supposed to be valid"* are exactly what totality rules out. If the function is defined for every value its input type allows, there's no input the body hasn't thought about. When the parameter types are too loose, the way to get there is to narrow them: move the checking upstream, into the creation of the value, instead of repeating it in every function that uses it [1][2]. That work doesn't disappear. It moves to one place, where it is done *once*, where the type name makes the rules obvious, and where the rest of the code no longer has to recheck.

**4. Composing needs honesty.**
Chaining functions that each "might return `-1`" produces code that branches more often than it does work. Honest return types compose mechanically: once the outcomes are in the type, small helpers can chain fallible steps without decoding conventions. A fluent API like `step1().step2().step3()` is the simplest case. It reads cleanly only when each return value is something the next call can use directly; the moment one link returns "the answer *or* `null`", the chain has to stop and check. The structure and types that [Axiom 6](axiom-06-pure-functions.md) said live in pure functions depend on signatures that don't lie.

---

## Trade-offs

- **Shape.** An honest, total signature is wider than its dishonest version. Where `int FindIndex(...)` returned a primitive, the honest version returns a small named type, and the caller writes a branch instead of `if (i == -1)`. At one call site, that looks like ceremony. Across a codebase it goes the other way: a dishonest signature taxes every caller forever; an honest one taxes the author once.
- **Pushing checks upstream.** Making a function total often means using stronger input types: a `NonZeroInt` instead of an `int` where division needs it, or a type whose values are guaranteed well-formed instead of a raw `string` where the format matters. That work is real, and it falls on whoever creates those values (the benefit is in *Why*, point 3).

---

## When NOT to

Three cases where the criterion is wrong or harmful:

- **At the edges, where the function talks to the world.** An impure function from [Axiom 5](axiom-05-impure-functions.md) can fail because the database is gone, the network blinked or the disk is full. Those failures aren't part of the function's *own* logic. They belong to the impure code at the edges, not to the signature of a domain function. Honesty applies to outcomes the function *decides on*, not to every plumbing failure.
- **When the "extra outcome" is really input validation.** "The input was malformed" isn't an outcome the function decides on; it belongs in the *parameter's* type, not in the return type of every function that takes one. Folding validation into the return type repeats the check at every call site, instead of solving it once where the input is created.
- **When defining the error out of existence would hide a bug.** Making a function total by *absorbing* a bad input (clamping it, swallowing it, returning a default) is only right when the broader behavior is what the caller actually wants. When the bad input can only come from a caller's mistake (a negative count, an index that *should* have been in range), silently absorbing it hides the bug at the exact spot it could have surfaced. There, the honest move is the opposite: fail loudly and early, instead of letting the bug travel downstream as a plausible-looking value.

---

## References

[1] **Alexis King**, *Parse, Don't Validate*, lexi-lambda.github.io, 2019. Argues that a function that only checks its input (returning `bool`) and a function that turns it into a stronger type are the difference between a dishonest, partial signature and an honest, total one. <https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/>

[2] **Scott Wlaschin**, *Designing with Types: Making Illegal States Unrepresentable*, fsharpforfunandprofit.com, 2013. A practical demonstration of using richer return and parameter types to remove whole categories of bugs by construction. <https://fsharpforfunandprofit.com/posts/designing-with-types-making-illegal-states-unrepresentable/>

[3] **Robert Harper**, *Boolean Blindness*, Existential Type, 2011 (crediting Dan Licata for the term); **John A. De Goes**, *Destroy All Ifs*, degoes.net, 2015. Both name what a bare `bool` throws away (which of two cases holds, with the cases left anonymous) and both prescribe the cure this book reaches for: replace the boolean with a named type. <https://existentialtype.wordpress.com/2011/03/15/boolean-blindness/> · <http://degoes.net/articles/destroy-all-ifs>

[4] **John Ousterhout**, *A Philosophy of Software Design*, Yaknyam Press, 2018, ch. 10 ("Define Errors Out of Existence"). Argues that the cheapest exception to handle is the one designed away: redefine an operation so the formerly erroneous case becomes a normal, defined outcome (`substring` clamps, deletion is idempotent). The limit in *When NOT to*, that absorbing a bug-signaling input hides the defect, is where this book draws the line around the technique.

---

← Previous: [Axiom 6 — Pure functions](axiom-06-pure-functions.md) · Next: [Axiom 8 — Cohesion](axiom-08-cohesion.md) →
