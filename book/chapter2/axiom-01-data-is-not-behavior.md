# Axiom 1 — Data is not Behavior

**Data is inert fact. Behavior is transformation. Keep them apart.**

- Model facts as plain, immutable data.
- Put business logic in functions whose result depends only on the data handed to them.

[Axiom 0](axiom-00-ubiquitous-language.md) gave each concept one name. The first thing the code decides about a named concept is what it fundamentally is, and the answer is inert data, not behavior. Most of the axioms that follow build on this one.

---

## Definitions

> "Separate code from data in a way that the code resides in functions whose behavior does not depend on data that is encapsulated in the function's context."
>
> — Yehonathan Sharvit, Principle #1 of Data-Oriented Programming [5]

It says one structural thing: **do not hide state behind behavior.**

- **Data** is a *value*: a representation of something that is true, like a name, a set of line items or a timestamp. It *is* a fact; it does not act.
- **Behavior** is an *operation*: data goes in, and data may come out. It *acts*; it holds no state of its own.

This axiom departs from the common OO default of **fusing** the two: an object that owns mutable state *and* the methods that quietly change it.

---

## Example

A shopping cart, first fused, then separated:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// ❌ fused: the state is hidden,
// and Add changes it in place
class Cart
{
    private readonly List<Line> _lines = new();

    public void Add(Line line) => _lines.Add(line);

    public decimal Total() =>
        _lines.Sum(l => l.Price * l.Quantity);
}
```

</td>
<td>

```java
// ❌ fused: the state is hidden,
// and Add changes it in place
class Cart {
    private final List<Line> lines = new ArrayList<>();

    public void add(Line line) { lines.add(line); }

    public BigDecimal total() {
        var sum = BigDecimal.ZERO;
        for (var l : lines)
            sum = sum.add(l.price().multiply(BigDecimal.valueOf(l.quantity())));
        return sum;
    }
}
```

</td>
</tr>
<tr>
<td>

```csharp
// ✅ separate: the data is a plain fact...
sealed record Line(string Product, decimal Price, int Quantity);
sealed record Cart(ImmutableList<Line> Lines);

// ...and the behavior is a function over it
static class Pricing
{
    public static decimal Total(Cart cart) =>
        cart.Lines.Sum(l => l.Price * l.Quantity);
}
```

</td>
<td>

```java
// ✅ separate: the data is a plain fact...
record Line(String product, BigDecimal price, int quantity) {}
record Cart(List<Line> lines) {
    Cart { lines = List.copyOf(lines); }
}

// ...and the behavior is a function over it
final class Pricing {
    static BigDecimal total(Cart cart) {
        var sum = BigDecimal.ZERO;
        for (var l : cart.lines())
            sum = sum.add(l.price().multiply(BigDecimal.valueOf(l.quantity())));
        return sum;
    }
}
```

</td>
</tr>
</table>

In the second version, `Cart` says what a cart *is*, and `Total` says what you *do* with one. You can read a `Cart` without tracing its history, test `Total` by handing it a value, and change either one without touching the other.

---

## Problem / forces

When modeling a domain, engineers keep having to do things with it: reason about it, test it, reuse logic, serialize it, send it across a wire, store it for years, run it on many threads, and change it when requirements change.

The usual tool, an object that bundles mutable state with the methods that change it, works against most of those forces:

- You cannot tell what an object *is* by looking at it. You have to trace the history of changes that led to its current state.
- The logic is welded to one data shape and one lifecycle, so it is hard to reuse and hard to test on its own.
- The state is hidden, so concurrency means locks, and serialization means ceremony.

One force pulls the other way: keeping a fact and the operations on it physically together ("keep the things that change together, together"). That force is real, and this axiom does not deny it. It moves it somewhere else (see *When NOT to*).

The OO practice built on that force has a name, **Tell, Don't Ask**, and it is the deliberate opposite of this axiom (see *Tell, Don't Ask: the road not taken*).

---

## Why

**1. It reduces complexity.**
Fusing code and data produces something harder to understand than its parts. Separating them lets code be reused in different contexts and tested in isolation, and tends to make systems less complex overall. In my experience it is one of the cheapest large reductions in complexity available, which is why it comes first.

**2. Data is the durable half; behavior is the volatile half.**
The data model *is* the design:

- Brooks, fifty years ago: show me your tables, and your flowcharts become obvious [1].
- Pike: "Data dominates" [2].
- Torvalds: good programmers worry about data structures and their relationships, not the code [3].

And the data model changes far more slowly than the logic does. So let the stable part drive, and keep the volatile part separate and replaceable.

**3. Values, not places (Hickey).**
The deeper reason data should not carry behavior is that data should be an *immutable value*, and values are inert. Fusing data with behavior comes from what Hickey calls *place-oriented programming* [4]: treating a fact as a mutable cell, where new information overwrites old. It is a habit from an era when memory was scarce.

A value means the same thing everywhere, forever, with no coordination. That is exactly what makes concurrency and distribution manageable. Once your data is a value, behavior that changes it *cannot* live inside it; the separation comes for free.

**4. Only data crosses boundaries.**
A value can travel between services, between languages, and across years of storage. An in-process method cannot travel at all. Welding behavior onto data ties the one thing that can travel (data) to the one thing that can't (in-process behavior).

---

## Trade-offs

Sharvit is upfront about the costs [5]:

- **No access control.** Nothing stops any code from reading any data.
- **No packaging.** The data and the logic that belongs to it no longer sit together in one unit.
- **More entities.** A system ends up with more named things to keep track of: the data types *and* the modules of functions over them.

---

## When NOT to

- **When the code is built around mutable objects, Tell, Don't Ask is the right tool.** In that world, its rules are sound (see below). This axiom changes the premise; it does not claim the maxim is wrong.
- **Mutable resources.** Where mutable state legitimately lives (a connection, a cache, a stream), *telling* the resource what to do, instead of asking for its insides, stays exactly right.
- **Performance-driven layouts.** Mike Acton's **Data-Oriented *Design*** [6] uses the same slogan for a *performance* argument (cache locality, memory layout). That is a different problem, and out of scope for this book (see the [playbook scope](../../README.md#scope)).

### Tell, Don't Ask: the road not taken

This axiom gives up keeping a fact and its logic in one place. *Tell, Don't Ask* [7] keeps them together by the opposite move. Both answer the same question, *a decision needs data, so where do the two meet?*, with opposite answers:

- **Tell, Don't Ask:** move the decision to the data. Hide the state in private mutable fields and put the behavior beside it, so `account.Withdraw(amount)` decides internally and the caller never sees the balance.
- **This axiom:** move the data to the decision. Pull the state out as an inert value and hand it to a function that decides outside.

Tell, Don't Ask is right *under its premise*: that objects hold mutable state. In a mutable world, a getter that lets a caller decide and then mutate is a real hazard:

- the rule gets copied into every caller;
- the gap between the read and the write is a race.

The maxim closes both by welding the decision to the state.

This book removes the premise instead. Once the data is an *immutable value*, there is nothing to hide: exposing a value can't be abused, because there is no setter to pair with the getter. And the rule still lives once, inside the function, not copied across callers.

Same benefits (one home for the rule, no reaching into objects), different mechanism (freeze the data instead of hiding it behind behavior). Keeping things together is not lost, only moved:

- **to the module**, where a function and the types it transforms sit side by side without being fused;
- **to the one place where mutable state still lives** (see *Mutable resources* above).

---

## References

[1] **Fred Brooks**, *The Mythical Man-Month: Essays on Software Engineering*, Addison-Wesley (1975; Anniversary Edition 1995), ch. 9, p. 102:
> "Show me your flowcharts and conceal your tables, and I shall continue to be mystified. Show me your tables, and I won't usually need your flowcharts; they'll be obvious."

[2] **Rob Pike**, *Notes on Programming in C*, AT&T Bell Laboratories, February 21, 1989, Rule 5 ("Data dominates"):
> "Data dominates. If you've chosen the right data structures and organized things well, the algorithms will almost always be self-evident. Data structures, not algorithms, are central to programming."
>
> <http://doc.cat-v.org/bell_labs/pikestyle>

[3] **Linus Torvalds**, message to the Git mailing list, 27 June 2006 (archived at <https://lwn.net/Articles/193245/>):
> "I will, in fact, claim that the difference between a bad programmer and a good one is whether he considers his code or his data structures more important. Bad programmers worry about the code. Good programmers worry about data structures and their relationships."

[4] **Rich Hickey**, *The Value of Values*, keynote at JaxConf 2012 (also delivered at GOTO Copenhagen 2012). Recording on InfoQ, published 14 August 2012: <https://www.infoq.com/presentations/Value-Values/>. Coined "place-oriented programming (PLOP)" for the habit of treating a memory cell as the location of a fact, and argued that values (immutable, location-independent) are what make concurrency and distribution manageable.

[5] **Yehonathan Sharvit**, *Data-Oriented Programming: Reduce software complexity*, Manning Publications, 2022. The four-principle codification of DOP. Principle #1 and its costs ("There is no control on what code can access what data", "There is no packaging", "Our systems are made from more entities") are covered in the chapters on Principle #1 and summarized in Appendix A. <https://www.manning.com/books/data-oriented-programming>. The principle and its costs are also excerpted on the author's blog: <https://blog.klipse.tech/databook/2022/06/22/separate-code-from-data.html>

[6] **Mike Acton**, *Data-Oriented Design and C++*, keynote at CppCon 2014: <https://www.youtube.com/watch?v=rX0ItVEVjHc>. Argues for designing code around the data, its transformations, and the hardware that runs them (cache locality, structure-of-arrays). Same slogan as Sharvit's DOP, different argument: this branch is about *performance*, not complexity.

[7] **Andrew Hunt & David Thomas**, *The Pragmatic Programmer*, Addison-Wesley, 1999 (20th-anniversary ed. 2019). Hunt and Thomas popularized the *Tell, Don't Ask* maxim. See also **Martin Fowler**, *TellDontAsk*, martinfowler.com (bliki), which frames it as bundling data with the functions that operate on it and is careful to call it a reminder, not a rule to apply dogmatically. <https://martinfowler.com/bliki/TellDontAsk.html>

---

← Previous: [Axiom 0 — Ubiquitous Language](axiom-00-ubiquitous-language.md) · Next: [Axiom 2 — Immutability](axiom-02-immutability.md) →
