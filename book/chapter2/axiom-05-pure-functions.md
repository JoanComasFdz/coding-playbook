# Axiom 5 — Pure functions

**A function is pure when it has no side effects and is deterministic — its output depends entirely on its inputs.**

- Same inputs in, same output out — every call, every thread, every time.
- The signature is the whole truth: every input named in the parameters, every output in the return value.

[Axiom 4](axiom-04-impure-functions.md) named the impure category so this axiom can name its opposite. Where impure functions are the program's *plumbing* — context gathered from the world, outcomes delivered back to it — pure functions are the program's *reasoning*: data in, decision out, no conversation with anything else. The two together compose every interesting program; this axiom is about the half that the rest of the playbook treats as the place where structure, types, and proof live.

---

## Definitions

It says one structural thing: **a function is pure when no side effect from [Axiom 3](axiom-03-side-effects.md) appears anywhere reachable from its body. By construction, this also makes the function *deterministic*: its return value depends only on its parameters.**

A function is pure when all of these are true:

- **No effects in its body.** No clock or random read, no I/O, no logging, no parameter mutation, no `throw` on bad input — a thrown exception is an output channel that bypasses the return value. The categories from Axiom 3 are absent.
- **No effects through its calls.** Purity is deep the same way impurity is. A function whose body is arithmetic plus one call into an impure helper is impure; every function in the transitive call graph must itself be pure.
- **No hidden inputs through captures.** A captured field or reference that holds a `DbContext`, a `Random`, a settable singleton, or any mutable shared state turns the function impure. Captures are allowed, but they must be values — themselves immutable, produced once, and not aliased to anything that changes.
- **Deterministic.** Same inputs in, same output out: two calls with arguments equal under the domain's equality must produce results equal under it. Determinism is a property of *behaviour*, not just of *the body* — a function whose body looks effect-free but reads a mutable field is not pure. This is where purity outruns the older **Command–Query Separation** rule (Bertrand Meyer): CQS asks a *query* to change nothing but still lets it *read* mutable state, so a getter that reads a mutable field is a legal CQS query and an illegal pure function — purity forbids the hidden read too, which is what keeps the signature the whole contract.

This axiom rejects two mainstream defaults that quietly muddle the line. The first is the "helper" function that threads a single clock read, a config lookup, or one diagnostic log line through what otherwise looks like arithmetic — the signature lies about what the function does, and every caller inherits the lie. The second is the "stateless service" object whose every method takes the same parameters as a plain function but reads a mutable field on `this` — the function pretends to be a function while `this` smuggles in a hidden input.

The signature `(InputA, InputB) -> Output` is, on a pure function, *a complete description* of the conversation the function has with the rest of the program. Nothing hidden goes in; nothing hidden comes out. This is the property known as **referential transparency**: because the signature is the whole contract, a call and its returned value are interchangeable in any context. That is the structural property the rest of the playbook depends on.

Languages like C# and Java cannot express purity in the signature. Recognising it is a *reading* discipline applied to the whole body and the transitive call graph — the same skill from Axiom 4, used to label the opposite category.

---

## Example

A function whose every line is determined by its parameters:

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

Two parameters in, one value out. No clock, no field reads, no logging, no throws — the inputs are already typed, so invalid baskets are unrepresentable. Call this with the same basket and the same rate at any time, on any thread, on any machine, and you get the same number. The signature `(items, taxRate) -> total` is the whole truth.

And a richer pure function — one that *decides* what should happen rather than just computing a number:

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

The decision is more interesting than arithmetic, but the discipline is the same. Three inputs, one returned decision; no `throw` on rejection — the rejection is *part of the return type*; no log of why; no save to a database. The caller takes the returned `CartDecision` and acts on it, and the *acting* lives somewhere else — in the impure shell from [Axiom 4](axiom-04-impure-functions.md). The pure function decides; the impure caller executes.

---

## Problem / forces

The competing force is **gravity** — every effect the program ultimately needs (the saved record, the published event, the log line, the response) really does have to happen *somewhere*. The mainstream default is to put each effect where it is needed, inline, right next to the rule it serves. A function that needs the customer's tier reads the database for it; a function that needs to record an outcome writes the log line for it; a function that needs to reject bad input throws. The code reads naturally line by line, and each function carries everything it needs.

The cost is paid the moment you try to do anything with one of those functions other than execute it in production: the test needs the database, the parallel run needs to coordinate the writes, the replay needs to suppress the side effects, the cache needs to know which calls were idempotent. None of these is hard *per function*; the cost is that every function pays it.

Purity is the discipline of paying the cost in one place — the shell — and inheriting the benefits everywhere else. The axiom does not claim every function should be pure; it claims that the pure functions are where the program's *reasoning* lives, and that the rest of the playbook treats them as the place where structure, types, and composition belong. Without the label, the program has no "place where reasoning lives" — only a mass of methods that happen to compile.

---

## Why

**1. The signature is the whole contract.**
The deepest property of a pure function is that its signature *cannot lie*. Every input it depends on is named in the parameter list; every output it produces is the return value. Reading a pure function's signature is, in principle, reading its full external behaviour. This is what makes the rest of the playbook possible: a richer type can only describe *all* of a function's inputs and *all* of its outcomes when the function has no other inputs and no other outcomes to describe. Purity is the precondition; the types come after.

**2. Referential transparency: the call and its value are interchangeable.**
A pure function call can be replaced by its return value without changing the program's behaviour, and the return value can be replaced by the call. This is *referential transparency*[1] — the formal name for the "complete description" property above — and it is what every form of equational reasoning, memoisation, parallelisation, retry, and replay quietly depends on. None of these are tricks you apply to pure functions; they all *just work* on pure functions and *all break* on impure ones. The label is not an optimisation — it is the precondition for the optimisations to be sound.

**3. Tests reduce to a table.**
A pure function's test is the simplest test in the universe: pick inputs, expect output, run, compare. No fixture, no clock to freeze, no database to seed, no mock to verify, no cleanup. The same property that makes pure functions cheap to think about — that the inputs uniquely determine the output — makes them cheap to test, cheap to specify, and cheap to keep correct over time. The difference in test cost between a pure and impure function is, again, roughly an order of magnitude[2], and once you feel it once you stop conflating them.

**4. The hard work moves to the boundary, where it belongs.**
The reason this discipline is worth its ergonomics tax is that the impure work — the I/O, the clock, the database — is exactly the work that ought to be *concentrated*, not scattered. A program with a thin impure shell and a fat pure core has one place to mock out, one place to retry, one place to log, one place to make idempotent; the core is left to be plain functions over plain data. A program with effects sprinkled through every layer has none of those leverage points; every change has to think about every effect everywhere.

---

## Trade-offs

Pure functions cost you the convenience of inline effects. A function that needs the current time has to receive it as a parameter; a function that needs to log has to return a value the caller logs, or return a description of the log line the caller emits; a function that needs to read the database has to be split into a query (impure) and a decision (pure) that takes the query's result as input. In small programs, this looks like ceremony — a long parameter list and an awkward seam where there used to be a single method call.

The trade is that the seam stops being awkward at roughly the size where the program would otherwise stop being tractable. A 500-line module with three effects scattered through it is fine; a 50,000-line system with effects scattered through every layer is the shape the playbook is trying to prevent. The cost shows up early; the benefit shows up later, and bigger.

A second cost is **shape** — pure functions over immutable data sometimes mean carrying more arguments and producing more intermediate values than the imperative version. Modern GCs absorb most of this, but it is a real cost in tight loops. The same caveat as [Axiom 2](axiom-02-immutability.md)'s *When NOT to* applies.

---

## When NOT to

Two cases where the label does not earn its keep:

- **At the boundary, where effects are the entire point.** The function that talks to the database, the one that publishes the event, the one that handles the inbound HTTP request — these are pure-impossible by construction. Do not pretend; concentrate them in the impure shell, name them clearly, and let the pure core be all the richer for it. The playbook never asks for an all-pure program — it asks for a pure *core*.
- **The "diagnostic" helper.** A function that returns a value and also logs once for diagnostics is impure (see [Axiom 4](axiom-04-impure-functions.md)'s *When NOT to*). The temptation to call it "pure enough" is exactly what the binary label was designed to resist. If you need diagnostics, return enough information for the caller to log; do not blur the category.

---

## References

[1] **John Hughes**, *Why Functional Programming Matters*, Research Topics in Functional Programming, Addison-Wesley, 1990. Already cited in [Axiom 3](axiom-03-side-effects.md) and [Axiom 4](axiom-04-impure-functions.md); cross-listed here because Hughes' core argument — that referential transparency is what makes equational reasoning, optimisation, and composition possible — is the formal underpinning of this axiom.
<https://www.cs.kent.ac.uk/people/staff/dat/miranda/whyfp90.pdf>

[2] **Eric Normand**, *Grokking Simplicity*, Manning Publications, 2021. Chapters 2–4 introduce the *action / calculation / data* taxonomy: a calculation is this axiom's pure function. The book is a 300-page worked example of how separating calculations from actions changes the cost of testing, refactoring, and reasoning across a codebase. Already cited in [Axiom 4](axiom-04-impure-functions.md); cross-listed here as the practical companion to Hughes' formal argument.
<https://www.manning.com/books/grokking-simplicity>
