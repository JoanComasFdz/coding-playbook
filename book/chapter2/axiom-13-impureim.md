# Axiom 13 — Impureim

**Effects at the edges, decisions in the middle: read the world, decide with one pure function, then write the world.**

- The **shell** is the impure part. It *gathers* values from the world before the decision and *acts* on the result after it.
- The **core** is the pure part. It *decides*, and touches nothing outside its parameters and its return value.
- The picture is a sandwich: impure, pure, impure. One sandwich per request, message or job.

[Axiom 4](axiom-04-side-effects.md) named the effects, [Axiom 5](axiom-05-impure-functions.md) the functions that carry them, [Axiom 6](axiom-06-pure-functions.md) their opposite, and [Axiom 7](axiom-07-honest-total-signatures.md) the signature the core must have. This axiom puts those pieces into one shape. It is a concept, not a construct: it shows the target the rest of this chapter builds toward, so it stays short.

The name is Mark Seemann's: *impureim* is his contraction of impure/pure/impure [1]. Gary Bernhardt calls the same split *functional core, imperative shell* [2], and Eric Normand draws it as actions around calculations [3].

Through [Axiom 9](axiom-09-connascence.md)'s lens, the sandwich improves the *locality* of a [Connascence of Execution](axiom-09-connascence.md#connascence-of-execution-coe). The gather → decide → act order, which would otherwise be scattered through a call tree, gets one visible home. A wrong order can still be written, but a reader sees the whole order in one place.

---

## Definitions

> For each unit of work (one request, one message, one job), every effect happens either before or after a single pure call, and that call is where the decisions are made.

A unit of work that fits the shape runs three steps, in this order:

- **Gather (impure).** Read what the world holds right now: the database row, the queued message, the HTTP request body, the current time, the configuration. Each read returns a value. Nothing is decided yet.
- **Decide (pure).** Turn those values into a result: validate, apply the rules, work out what should change. No I/O, no clock, no logging, and no `throw` on bad input: every outcome is named in the return type ([Axiom 7](axiom-07-honest-total-signatures.md)).
- **Act (impure).** Carry out the decision: save the row, publish the message, write the response, log. Nothing is left to decide.

Either end of the shell can be empty. A query reads, decides and returns, with nothing to write. A scheduled cleanup may have nothing to read. The rule is "effects at the edges, decisions in the middle"; the full sandwich is the common case, not the only one.

You recognize the shape by the core's signature: its parameters are the gathered values, and its return value is everything the act step needs. If the core reads the clock, logs, or throws on bad input, the sandwich collapses back into a mixed function.

**The core and the shell use classes differently.** The core is `static` functions over immutable data ([Axiom 6](axiom-06-pure-functions.md)), grouped in static classes that work as modules ([Axiom 2](axiom-02-data-is-not-behavior.md)). The shell is ordinary object-oriented code: a handler is a class, its dependencies (a `DbContext`, an HTTP client) arrive through its constructor, and it holds state where state is needed, such as a cache or a connection. Nothing in this book takes classes, dependency injection or state away from the shell. They just stay out of the core.

The shape is an older rule, lifted one level. **[Command–query separation](https://en.wikipedia.org/wiki/Command%E2%80%93query_separation)** (CQS) asks each *method* to either return a value (a query) or change state (a command), never both [4]. Impureim draws the same line around the whole unit of work: gather is all query, act is all command, and the line between them is a step boundary rather than a naming convention per method. The core goes further than CQS asks: a CQS query may still read mutable state, while the core reads nothing outside its parameters.

---

## Example

A handler that prices an order. The shell gathers and acts; the pure function in the middle decides.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public async Task PriceOrderAsync(OrderId id)
{
    // Impure — gather
    var cart  = await cartStore.GetAsync(id);
    var rules = await rulesStore.GetAsync(cart.CustomerId);
    var now   = clock.GetUtcNow();

    // Pure — decide
    var priced = CalculatePrice(cart, rules, now);

    // Impure — act
    await orderStore.SaveAsync(priced);
    logger.LogInformation("Priced order {Id} at {Total}", priced.Id, priced.Total);
}

private static PricedOrder CalculatePrice(
    Cart cart, DiscountRules rules, DateTimeOffset now)
{
    var subtotal = cart.Lines.Sum(l => l.UnitPrice * l.Quantity);
    var discount = rules.ActiveAt(now).Apply(subtotal);
    var net      = subtotal - discount;
    var tax      = net * rules.TaxRate;
    return new PricedOrder(cart.Id, subtotal, discount, tax, net + tax);
}
```

</td>
<td>

```java
public void priceOrder(OrderId id) {
    // Impure — gather
    Cart cart = cartStore.get(id);
    DiscountRules rules = rulesStore.get(cart.customerId());
    Instant now = clock.instant();

    // Pure — decide
    PricedOrder priced = calculatePrice(cart, rules, now);

    // Impure — act
    orderStore.save(priced);
    logger.info("Priced order {} at {}", priced.id(), priced.total());
}

private static PricedOrder calculatePrice(
        Cart cart, DiscountRules rules, Instant now) {
    BigDecimal subtotal = cart.lines().stream()
        .map(l -> l.unitPrice().multiply(BigDecimal.valueOf(l.quantity())))
        .reduce(BigDecimal.ZERO, BigDecimal::add);
    BigDecimal discount = rules.activeAt(now).apply(subtotal);
    BigDecimal net = subtotal.subtract(discount);
    BigDecimal tax = net.multiply(rules.taxRate());
    return new PricedOrder(cart.id(), subtotal, discount, tax, net.add(tax));
}
```

</td>
</tr>
</table>

The handler has six lines that matter: three reads, one pure call, two writes. Move the clock read into `CalculatePrice`, or an eligibility check into the handler, and the steps stop being separable: either the core is no longer pure, or the shell starts deciding.

---

## Problem / forces

Most line-of-business handlers interleave: read a value, decide something, call a service, read another value, decide again. Each step is simple, and the body reads fine from top to bottom.

The cost shows up as soon as you do anything with the handler other than run it:

- **Testing** means stubbing every effect, in the right order, with the right return values. The test mirrors the runtime environment.
- **Reusing a decision** means pulling it out of the interleaving first, which is the same work as building the sandwich.
- **Retries, replays and concurrency** have to be thought through again for every line that touches the world.

Impureim removes none of the effects. The program still reads the cart, prices it and saves the order. It rearranges them so the decisions sit in one place and the effects in another. The price is paid at the seams (see *Trade-offs*).

---

## Why

**1. The core's signature is its whole contract.**
With no hidden inputs and no hidden outputs, the signature says everything the function does. Every richer tool this book builds from here on (types that name every outcome, values that can't be invalid) depends on that, so all of them go into the core. None of them can be applied to a function that mixes effects with logic.

**2. The core is tested with values, and the shell has nothing left to decide.**
The core gets the plain tests of [Axiom 6](axiom-06-pure-functions.md#why) (point 3): inputs in, output checked. The shell only moves values between the world and the core, so it is covered by tests of the whole service against real dependencies, not by stubbing each call. Case coverage and effect simulation end up in different tests, and each can be done well.

**3. Each question has one place to look.**
"Where does this time come from?" The gather. "What happens if this save fails?" The act. "Does this decision handle an empty cart?" The core. In an interleaved body, every question means scanning the whole body.

**4. The cores compose.**
Two pure decisions combine into one larger pure decision, and the shell around them is still one gather and one act. Shells don't compose that way: chaining them interleaves effects again. So grow the core and keep the shell thin; chain shells only when a read depends on a decision (see *Trade-offs*).

---

## Trade-offs

- **The shell gathers up front.** It has to read everything the core might need before the core runs. A mixed handler reads the discount rules only when the cart turns out to be non-empty. The sandwich either reads them every time, sometimes for nothing, or moves the emptiness check into the shell, where it is a decision in the wrong place. When a read really depends on a decision, run two sandwiches in a row: gather, decide, gather more, decide again, act.
- **A long-running process is many sandwiches.** One request fits one sandwich. A process that consumes a stream of events and keeps state between them runs one sandwich per event, and the state between events lives in the shell. The shape still holds; it just no longer fits in one diagram.

---

## When NOT to

Two cases where the shape would be ceremony (see the [decisions-vs-ceremony test](../chapter1/README.md#enforce-decisions-not-ceremony) in [Chapter 1](../chapter1/README.md)):

- **Code that decides nothing.** Some handlers only move things around: forward a request, copy a value, fan a message out to N subscribers. The whole body is shell. Don't invent an empty core to satisfy the shape.
- **A tiny script.** A throwaway tool that reads one file, prints one summary and exits gains nothing from three steps. The shape pays off where reuse, testing and reasoning matter; below that, write the three lines.

---

## References

[1] **Mark Seemann**, *Impureim Sandwich*, ploeh blog, 2 March 2020. Names the shape: gather data from impure sources, call a pure function, then act on its result through impure code.
<https://blog.ploeh.dk/2020/03/02/impureim-sandwich/>

[2] **Gary Bernhardt**, *Functional Core, Imperative Shell*, Destroy All Software screencast, 12 July 2012. The same split under the name most people know: "This functional core is surrounded by a shell of imperative code."
<https://www.destroyallsoftware.com/screencasts/catalog/functional-core-imperative-shell>

[3] **Eric Normand**, *Grokking Simplicity*, Manning Publications, 2021. Also cited in [Axiom 5](axiom-05-impure-functions.md) and [Axiom 6](axiom-06-pure-functions.md). Its recurring picture of actions at the edges and calculations in the middle, with data flowing between them, is the same shape.
<https://www.manning.com/books/grokking-simplicity>

[4] **Bertrand Meyer**, *Object-Oriented Software Construction* (2nd ed.), Prentice Hall, 1997. The source of **command–query separation**: a method either returns a value or changes observable state, never both.

---

← Previous: [Axiom 12 — Pattern matching](axiom-12-pattern-matching.md) · Next: [Axiom 14 — Maybe](axiom-14-maybe.md) →
