# Axiom 6 — Pure functions

**A function is pure when it has no side effects and is deterministic: its output depends only on its inputs.**

- Same inputs in, same output out: every call, every thread, every time.
- Nothing is hidden: every input is in the parameters, and every output is in the return value.

[Axiom 5](axiom-05-impure-functions.md) named the impure kind so this axiom can name its opposite. Impure functions are the program's *plumbing*: they gather context from the world and deliver outcomes back to it. Pure functions are the program's *reasoning*: data in, decision out, no conversation with anything else. Every useful program needs both. This axiom is about the half where the rest of this book puts structure and types.

---

## Definitions

In one sentence: **a function is pure when no side effect from [Axiom 4](axiom-04-side-effects.md) is reachable from its body.** That also makes it *deterministic*: its return value depends only on its parameters.

A function is pure when all of these are true:

- **No effects in its body.** No clock or random read, no I/O, no logging, no parameter changes, and no `throw` on bad input: an exception is an output that bypasses the return value. None of [Axiom 4](axiom-04-side-effects.md#the-categories)'s categories appear.
- **No effects through its calls.** Purity is deep, just like impurity in [Axiom 5](axiom-05-impure-functions.md). A function that does arithmetic plus one call to an impure helper is impure. Every function it calls, all the way down, must be pure too.
- **No hidden inputs through captures.** A captured field or reference that holds a `DbContext`, a `Random`, a settable singleton or any other mutable shared state makes the function impure. Captures are allowed, but they must be values: immutable, created once, and not shared with anything that changes.
- **Deterministic.** Same inputs in, same output out: two calls with equal arguments must give equal results. Determinism is about *behavior*, not just *the body*: a body that looks effect-free can still read mutable state (see the CQS getter below).

That last point is where purity goes further than Meyer's older **Command–Query Separation** rule [3]. CQS asks a *query* not to change anything, but still lets it *read* mutable state. So a getter that reads a mutable field is a valid CQS query, but not a pure function. Purity forbids the hidden read too, so nothing hidden goes in.

This axiom departs from two common defaults that blur the line:

- **The "helper"** that slips one clock read, one config lookup or one diagnostic log line into what otherwise looks like arithmetic. Its signature hides what it does, and every caller inherits that.
- **The "stateless service"** whose methods take the same parameters as plain functions but read a mutable field on `this`. It looks like a function, while `this` smuggles in a hidden input.

On a pure function, the signature `(InputA, InputB) -> Output` describes *everything* the function exchanges with the rest of the program. Nothing hidden goes in; nothing hidden comes out. This is called [**referential transparency**](https://en.wikipedia.org/wiki/Referential_transparency): a call and the value it returns are interchangeable anywhere. The rest of this book depends on that property.

The return type itself can still be vague about *which* outcomes are possible. That is a separate problem from purity: purity only guarantees there is no other channel.

C# and Java can't express purity in a signature. So recognizing it is a *reading* skill, applied to the whole body and everything it calls: the same skill as in [Axiom 5](axiom-05-impure-functions.md), used to spot the opposite kind.

---

## Example

A function where every line depends only on its parameters:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public decimal TotalWithTax(IReadOnlyList<LineItem> items, decimal taxRate)
{
    var subtotal = items.Sum(item => item.UnitPrice * item.Quantity);
    return subtotal * (1 + taxRate);
}
```

</td>
<td>

```java
public BigDecimal totalWithTax(List<LineItem> items, BigDecimal taxRate) {
    var subtotal = items.stream()
        .map(item -> item.unitPrice().multiply(BigDecimal.valueOf(item.quantity())))
        .reduce(BigDecimal.ZERO, BigDecimal::add);
    return subtotal.multiply(BigDecimal.ONE.add(taxRate));
}
```

</td>
</tr>
</table>

Two parameters in, one value out. No clock, no field reads, no logging, no throws. Call it with the same basket and the same rate at any time, on any thread, on any machine, and you get the same number. Nothing outside `(items, taxRate)` goes in, and nothing besides `total` comes out.

And a richer pure function, one that *decides* what should happen instead of just computing a number:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public CartDecision DecideAdd(Cart cart, Product product, int quantity)
{
    if (quantity <= 0)
        return new CartDecision.Rejected("quantity must be positive");
    if (cart.Lines.Count >= MaxLines && !cart.Contains(product))
        return new CartDecision.Rejected("cart is full");
    if (cart.Contains(product))
        return new CartDecision.IncreaseLine(product.Id, quantity);
    return new CartDecision.AddLine(product, quantity);
}
```

</td>
<td>

```java
public CartDecision decideAdd(Cart cart, Product product, int quantity) {
    if (quantity <= 0)
        return new CartDecision.Rejected("quantity must be positive");
    if (cart.lines().size() >= MAX_LINES && !cart.contains(product))
        return new CartDecision.Rejected("cart is full");
    if (cart.contains(product))
        return new CartDecision.IncreaseLine(product.id(), quantity);
    return new CartDecision.AddLine(product, quantity);
}
```

</td>
</tr>
</table>

The decision is more interesting than arithmetic, but the rules are the same:

- three inputs, one returned decision;
- no `throw` on rejection: the rejection is *part of the return type*;
- no log of why, no save to a database.

The caller takes the returned `CartDecision` and acts on it. The *acting* happens somewhere else, in an impure function like the ones in [Axiom 5](axiom-05-impure-functions.md). The pure function decides; the impure caller executes.

---

## Problem / forces

The usual way to write code is to put each effect right where it's needed, next to the rule it serves:

- a function that needs the customer's tier reads it from the database;
- a function that needs to record an outcome writes the log line;
- a function that needs to reject bad input throws.

The code reads naturally line by line, and each function carries everything it needs.

The cost appears as soon as you want to do anything with such a function other than run it in production: the test needs the database, a parallel run needs to coordinate the writes, a replay needs to suppress the effects, a cache needs to know which calls are safe to repeat. None of this is hard *for one function*. The cost is that every function pays it.

One force pulls the other way, and it is real: every effect the program needs (the saved record, the published event, the log line, the response) does have to happen *somewhere*.

Purity means paying that cost in one place, at the edges of the program, and getting the benefits everywhere else (see *Why*, point 4). This axiom doesn't claim every function should be pure. It claims that pure functions are where the program's *reasoning* lives, and that the rest of this book builds its structure and types there.

---

## Why

**1. Nothing hidden goes in or out.**
Because every input is a parameter and every output is the return value (see *Definitions*), the signature shows every channel the function uses. That is what makes the rest of this book possible: a richer type can only describe *all* of a function's inputs and outcomes when the function has no other inputs or outcomes. Purity comes first; better types come after.

**2. The call and its value are interchangeable.**
Caching, running in parallel, retrying and replaying all rely on referential transparency (see *Definitions*). None of these are tricks you add to pure functions. They simply work on pure functions, and can break on impure ones. The label isn't an optimization; it is what makes those optimizations safe. Hughes' classic case for functional programming, that small functions can be glued together freely, rests on the same property [1].

**3. Tests become a table.**
Testing a pure function is as simple as tests get: pick inputs, state the expected output, run, compare. No setup, no clock to freeze, no database to seed, no mock to verify, no cleanup. The same property that makes pure functions easy to think about makes them easy to test, to specify and to keep correct over time. Normand's book is a long worked example of how separating calculations from actions changes the cost of testing and reasoning [2].

**4. The hard work moves to the edges.**
The impure work (I/O, the clock, the database) is exactly the work that should be *concentrated*, not scattered. A program with a thin layer of impure code at its edges and a large pure core has one place to mock, one place to retry, one place to log, one place to make safe to repeat. The core is left as plain functions over plain data. A program with effects in every layer has none of those single points; every change has to consider every effect everywhere.

---

## Trade-offs

- **You lose the convenience of inline effects.**
  - A function that needs the current time has to receive it as a parameter.
  - A function that needs to log has to return something the caller logs.
  - A function that needs the database has to be split: an impure query, and a pure decision that takes the query's result as input.

  In a small program this looks like ceremony: a longer parameter list and an awkward seam where there used to be one method call. The seam stops feeling awkward as the program grows. A 500-line module with three effects scattered through it is fine; a 50,000-line system with effects in every layer is what this book is trying to prevent. The cost shows up early; the benefit shows up later, and bigger.
- **More arguments and intermediate values.** Pure functions over immutable data sometimes carry more arguments and produce more intermediate values than the imperative version. Modern garbage collectors absorb most of this, but in tight loops it is a real cost. The same caveat as in [Axiom 3](axiom-03-immutability.md)'s *When NOT to* applies.

---

## When NOT to

- **At the edges, where effects are the whole point.** The function that talks to the database, the one that publishes the event, the one that handles the incoming HTTP request: these can't be pure. Don't pretend they are. Keep them together at the edges, name them clearly, and let the pure core be richer for it. This book never asks for an all-pure program. It asks for a pure *core*.
- **The "diagnostic" helper.** A function that returns a value and also logs once for diagnostics is impure (see [Axiom 5](axiom-05-impure-functions.md)'s *When NOT to*). Calling it "pure enough" is exactly what the binary label is meant to prevent. If you need diagnostics, return enough information for the caller to log.

---

## References

[1] **John Hughes**, *Why Functional Programming Matters*, in *Research Topics in Functional Programming*, Addison-Wesley, 1990. Already cited in [Axiom 4](axiom-04-side-effects.md) and [Axiom 5](axiom-05-impure-functions.md). Hughes argues that the real strength of functional programming is modularity: gluing small functions together with higher-order functions and lazy evaluation. That glue only works because the functions have no side effects. <https://www.cs.kent.ac.uk/people/staff/dat/miranda/whyfp90.pdf>

[2] **Eric Normand**, *Grokking Simplicity*, Manning Publications, 2021. Introduces the *action / calculation / data* taxonomy: a calculation is this axiom's pure function. Most of the book is a worked example of how separating calculations from actions changes the cost of testing, refactoring and reasoning. Already cited in [Axiom 5](axiom-05-impure-functions.md). <https://www.manning.com/books/grokking-simplicity>

[3] **Bertrand Meyer**, *Object-Oriented Software Construction*, Prentice Hall (1988; 2nd ed. 1997). The source of the *Command–Query Separation* principle: a method should either change state (a command) or return a value (a query), not both.

---

← Previous: [Axiom 5 — Impure functions](axiom-05-impure-functions.md) · Next: [Axiom 7 — Honest, total signatures](axiom-07-honest-total-signatures.md) →
