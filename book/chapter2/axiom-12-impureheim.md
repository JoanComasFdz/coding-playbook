# Axiom 12 — Impureheim

**Impureheim is the shape where every effect lives in a thin impure shell at the edges, and the work that decides lives in a pure core in the middle.**

- The shell reads the world, hands its values to the core, and writes the world back. The core touches nothing outside its parameters and return value.
- The picture is a sandwich: impure → pure → impure. One bite per request, transaction, or message.

[Axiom 3](axiom-03-side-effects.md) named the effects; [Axiom 4](axiom-04-impure-functions.md) named the functions that carry them; [Axiom 5](axiom-05-pure-functions.md) named their opposite; [Axiom 6](axiom-06-honest-total-signatures.md) set the bar for the signatures the core must wear. With those four pieces on the table, the shape they should compose into can finally be drawn. This axiom is *concept only* — it introduces the shape so the rest of the playbook has a destination to build toward. The pieces that fill the pure core are the subject of every axiom that follows; this is the picture they fit into.

This file is short on purpose. It names the shape and the reason for it — the machinery follows.

Through [Axiom 8](axiom-08-connascence.md)'s lens, the sandwich improves the *locality* of a [Connascence of Execution](axiom-08-connascence.md#connascence-of-execution-coe): the gather → decide → act order that would otherwise be scattered through a call tree is forced into one visible home at the seams. It does not make the wrong order unwriteable but it puts the order where a reader sees it in one frame.

---

## Definitions

It says one structural thing: **for any unit of work — a request, a message, a transaction — every effect happens before or after a single pure call. The pure call is where the work that decides lives.**

A unit of work that fits the shape has three layers, in this order:

- **Impure top — gather.** Read whatever the world holds right now: the row from the database, the message off the queue, the body of the HTTP request, the current time, the configuration. Each read returns a value; nothing is decided yet.
- **Pure middle — decide.** Take those values, compute the result. Validate inputs, apply rules, derive what should change. No I/O, no clock, no logging, no `throw`s on bad input — every outcome named in the return value, in the sense of [Axiom 6](axiom-06-honest-total-signatures.md).
- **Impure bottom — act.** Take the decision and carry it out. Save the row, publish the message, write the response, emit the log line. Each call has nothing to decide; it executes what the middle already chose.

The shell is allowed to be empty on either end. A query handler may read inputs, decide, and return — no write. A scheduled cleanup may start from no inputs at all — decide, then write. The shape is "I/O at the edges, decisions in the middle"; the literal sandwich is the most common case, not the only one.

This is an older rule promoted up a level. **Command–Query Separation** (Bertrand Meyer) asks each *method* to either return a value (a query) or change state (a command), never both. Impureheim moves that line from the method to the unit of work: the gather is all query, the act is all command, and the seam between them is a layer boundary rather than a per-method naming convention. The pure middle ([Axiom 5](axiom-05-pure-functions.md)) then sharpens the query half past what CQS asks — a CQS query may still read mutable state, where the middle reads nothing outside its parameters.

The shape is recognised by the *signature* of the middle: a pure function whose parameters are the gathered values and whose return value is everything the bottom needs to act. Anything that breaks that — the middle reaching for the clock, the middle deciding to log, the middle throwing on bad input — collapses the sandwich back into a mixed function.

---

## Example

A handler that prices an order. The shell reads inputs and writes outputs; the pure function in the middle does the deciding.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public async Task PriceOrderAsync(OrderId id)
{
    // Impure top — gather
    var cart  = await cartStore.GetAsync(id);
    var rules = await rulesStore.GetAsync(cart.CustomerId);
    var now   = clock.UtcNow;

    // Pure middle — decide
    var priced = Price(cart, rules, now);

    // Impure bottom — act
    await orderStore.SaveAsync(priced);
    logger.LogInformation("Priced order {Id} at {Total}", priced.Id, priced.Total);
}

private static PricedOrder Price(Cart cart, DiscountRules rules, DateTime now)
{
    var subtotal = cart.Lines.Sum(l => l.UnitPrice * l.Quantity);
    var discount = rules.For(now).Apply(subtotal);
    var tax      = (subtotal - discount) * rules.TaxRate;
    return new PricedOrder(cart.Id, subtotal, discount, tax, subtotal - discount + tax);
}
```

</td>
<td>

```java
public void priceOrder(OrderId id) {
    // Impure top — gather
    Cart cart = cartStore.get(id);
    DiscountRules rules = rulesStore.get(cart.customerId());
    Instant now = clock.instant();

    // Pure middle — decide
    PricedOrder priced = price(cart, rules, now);

    // Impure bottom — act
    orderStore.save(priced);
    logger.info("Priced order {} at {}", priced.id(), priced.total());
}

private static PricedOrder price(Cart cart, DiscountRules rules, Instant now) {
    BigDecimal subtotal = cart.lines().stream()
        .map(l -> l.unitPrice().multiply(BigDecimal.valueOf(l.quantity())))
        .reduce(BigDecimal.ZERO, BigDecimal::add);
    BigDecimal discount = rules.forInstant(now).apply(subtotal);
    BigDecimal tax = subtotal.subtract(discount).multiply(rules.taxRate());
    return new PricedOrder(cart.id(), subtotal, discount, tax,
                           subtotal.subtract(discount).add(tax));
}
```

</td>
</tr>
</table>

The handler is six lines of substance. The first three are reads, no decisions. The middle is one pure call: `price(cart, rules, now)`. The last two are writes, no decisions. Move the clock read inside `price`, or move an eligibility check inside `priceOrder`, and the sandwich is gone — the layers stop being separable. Keeping the layers separable is the whole point.

---

## Problem / forces

The competing default is what most line-of-business code looks like: a handler that, line by line, reads a value, decides what to do with it, calls a service, reads another value, decides again, and so on. Effects and decisions are *interleaved* — every few lines hands off to I/O, then comes back to a small piece of logic, then hands off again. The body reads naturally if you walk through it once; nothing in it is by itself complicated.

The cost shows up the moment you try to do something with that handler beyond running it. Testing means stubbing every effect along the body, in the right order, with the right return values — the shape of the test mirrors the shape of the runtime environment. Reusing the decision means lifting it out of the interleaving, which is the same work as building the sandwich in the first place. Reasoning about retries, replays, and parallelism becomes a question to be re-answered for every line that touches the world.

Impureheim does not eliminate any of these effects; the program still reads the cart, computes the price, saves the order. It rearranges them so the deciding sits in one place and the effects sit in another. The cost is paid at the seams between the layers — the gather has to fetch everything the middle will need up front; the act has to take the middle's output as input. The benefit is that everything inside each layer is uniform: the middle is provably free of effects, the shell is the only place effects live.

---

## Why

**1. The pure middle becomes the place where structure earns its keep.**
A function with no hidden inputs and no hidden outputs is a function whose signature is the whole contract. That property is the precondition for everything richer the playbook will build over it — types that name all outcomes, values that name all inputs, decisions that compose into larger decisions. None of that can be applied to a function that interleaves effects with logic; all of it applies cleanly to a pure middle.

**2. The shell becomes the only thing the test environment has to model.**
If effects only happen in the shell, then the test for the middle is a pure-function test — pick inputs, check the output. The test for the shell is "does it call the right things in the right order with the right values" — a thin integration test that does not have to know how the decision was made. The hard part of testing (effect simulation) and the hard part of validating the logic (case coverage) end up in different files, with different shapes, and each can be done well.

**3. Reasoning is localised at the seams.**
"Where does this clock value come from?" — the top of the shell. "What happens if this save fails?" — the bottom of the shell. "Does this decision handle the case where the cart is empty?" — the middle. Each question has one place to look. In a body where effects and decisions are interleaved, every question has to scan the whole body.

**4. The shape composes.**
A larger handler that fits the shape is composed of smaller handlers that also fit. A workflow that reads three sources, decides, and writes two results is the same picture at a different scale. The shape survives composition — a program made entirely of Impureheim shells with pure cores has a single property, "effects at the edges," that holds at every level.

---

## Trade-offs

The first cost is **eager gathering**. The shell has to fetch everything the middle might need *before* the middle runs. A handler that, in the mixed form, only reads the discount rules when the cart turned out to be non-empty must, in the sandwich form, either read them every time or push the emptiness check into the shell. Sometimes the eager read is wasted work; sometimes it forces an extra round-trip. The shape pays for clarity by giving up the freedom to interleave the order of effects.

The second cost is **the long-lived workflow**. A handler that processes one request at a time fits the sandwich neatly. A process that consumes a stream of events, holds state between them, and emits more events as it goes is not one sandwich but many — each event handled by its own shell-middle-shell, with the long-lived state itself owned by the shell. That works, but the picture is no longer a single bite; it is a stack of bites with a shared kitchen. The shape still applies; it just no longer fits in one diagram.

---

## When NOT to

Two cases where the shape would be ceremony for its own sake:

- **A handler that is itself nothing but effect orchestration.** Some code legitimately does no deciding — it forwards a request, copies a value from one place to another, fans out a message to N subscribers. There is no middle to extract; the whole body is shell. Do not invent a pure no-op to satisfy the shape.
- **A small script with one effect and one branch.** A throwaway tool that reads one file, prints one summary, and exits has nothing to gain from splitting its three lines into three layers. The shape pays for itself at the scale where reuse, testing, and reasoning become first-order concerns; below that, write the three lines.

---

## References

[1] **Mark Seemann**, *Impureim Sandwich*, blog post, 2020. Names the impure–pure–impure shape and argues that as much as possible of a unit of work should be expressed as a single pure function bracketed by I/O. The naming convention this axiom borrows ("impureim" / "impureheim") is from Seemann.
<https://blog.ploeh.dk/2020/03/02/impureim-sandwich/>

[2] **Eric Normand**, *Grokking Simplicity*, Manning Publications, 2021. Cross-listed from [Axiom 4](axiom-04-impure-functions.md) and [Axiom 5](axiom-05-pure-functions.md). The book's recurring picture — actions at the edges, calculations in the middle, data flowing between them — is the same shape this axiom names, framed for a working-engineer audience.
<https://www.manning.com/books/grokking-simplicity>

[3] **Bertrand Meyer**, *Object-Oriented Software Construction* (2nd ed.), Prentice Hall, 1997 — **Command–Query Separation**. The principle that a method should either return a value or change observable state, never both. Impureheim is that rule lifted from the method to the unit of work: query (gather) and command (act) become separate layers, and the pure middle ([Axiom 5](axiom-05-pure-functions.md)) makes the query half absolute rather than conventional.

---

← Previous: [Axiom 11 — Pattern matching](axiom-11-pattern-matching.md) · Next: [Axiom 13 — Maybe](axiom-13-maybe.md) →
