# Model 1 — Deterministic concurrency

**A parent starts several children that share nothing mutable, gives each one values, waits for all of them and combines the values they return. The children may run in any order, but the result is the same every time.**

- It is concurrency with no observable nondeterminism: Van Roy's *declarative concurrency* [1].
- It comes in three shapes: a parallel map over a pure function, independent reads run together, and independent units of work.
- It stays deterministic only while the children stay independent. Most bugs at this rung come from a child that quietly shares something, which moves the code up to [Model 3](04-shared-state.md) without anyone deciding to.

---

## Definitions

- **[Fork–join](https://en.wikipedia.org/wiki/Fork%E2%80%93join_model):** the parent *forks* children, then *joins* them: it waits until every child has finished before it goes on.
- **Child:** one piece of the work. It receives values, does its work and returns a value. It doesn't write to anything another child reads.
- **Scope:** the block of code that owns the children. The rules of [structured concurrency](https://en.wikipedia.org/wiki/Structured_concurrency) make the scope's ownership complete:
  1. **The scope ends only after every child has finished.** No child outlives it, so nothing the children do can interleave with the code after the scope.
  2. **A failure is not lost.** It reaches the parent, and the siblings of a failed child are cancelled when their work no longer has a use.
  3. **Cancellation and deadlines reach every child.** When the parent is cancelled or runs out of time, so do they.
  4. **The number of children is bounded.** A thousand items don't become a thousand threads.

  The first two rules are Smith's: "the nursery block doesn't exit until all the tasks inside it have exited", and "when an unhandled exception occurs in a child, Trio immediately cancels all the other tasks in the same nursery" [2]. A *nursery* is his library's name for the scope.

The three shapes split the work in the two ways parallel programming knows, which Mattson, Sanders and Massingill name the *Task Decomposition* and *Data Decomposition* patterns [3]: by **data** (the same function over many items) and by **task** (different pieces of work):

| Shape | Split by | Children do | Combine |
|---|---|---|---|
| **Parallel map** | data | the same pure function over different items | collect the results, or reduce them |
| **Concurrent gather** | task | different reads, no writes | one pure decision over all the values |
| **Independent units** | task | one whole sandwich each: gather, decide, act | collect each unit's outcome as a value |

---

## What can race

Nothing observable, as long as the children share nothing mutable. Each child depends only on the values it was given, so the order they run in can't show in the result.

These are the ways a child shares something without anyone deciding it should. Each one moves the code to [Model 3](04-shared-state.md):

- **A shared resource.** One database context or connection for all the children. These are built for one unit of work at a time.
- **A shared collection or counter.** Children that add their results to one list, or increment one total, instead of returning them. That includes a mutable local captured by a lambda ([Axiom 6](../chapter2/axiom-06-pure-functions.md#static-is-not-shared-state)).
- **A singleton with a field.** A service registered once and used by every child is one instance shared by all of them ([Axiom 6](../chapter2/axiom-06-pure-functions.md#static-is-not-shared-state)).
- **Overlapping data.** Two units that write the same row are not independent, whatever the code looks like.
- **A child that is never joined.** A task started and not awaited ("fire and forget") outlives the scope. Its effects interleave with whatever comes next, and its failure is lost.

And one that doesn't race but still breaks: **context that doesn't follow.** State kept per thread (a thread-local, a logging context) may not reach the children. Passing context explicitly ([Axiom 26](../chapter2/axiom-26-session-context.md)) avoids the question.

---

## Example

### Parallel map

A pure function over many items, run on several cores. Deciding to run it in parallel belongs to the shell: the function stays sequential, and the shell chooses how to run it.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
var scores = shipments
    .AsParallel()
    .Select(Risk.ScoreShipment)   // pure
    .ToList();
```

</td>
<td>

```java
var scores = shipments
    .parallelStream()
    .map(Risk::scoreShipment)     // pure
    .toList();
```

</td>
</tr>
</table>

`ScoreShipment` is pure, so the order in which the items run can't change any score. When the results are *reduced* to one value instead of collected, the combining function must be associative (`(a + b) + c` equals `a + (b + c)`), with a starting value that changes nothing. Then the runtime can group the work however it likes and still get one answer.

### Concurrent gather

Three independent reads, started together and joined before one pure decision:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public async Task<ShippingQuote> QuoteShippingAsync(
    OrderId id, CancellationToken ct)
{
    // gather: three reads, started together
    var orderRead = orderStore.GetAsync(id, ct);
    var ratesRead = carrier.GetRatesAsync(id, ct);
    var stockRead = warehouse.GetStockAsync(id, ct);
    await Task.WhenAll(orderRead, ratesRead, stockRead);

    var quote = Shipping.ChooseQuote(            // pure
        await orderRead, await ratesRead, await stockRead);
    return quote;
}
```

</td>
<td>

```java
public ShippingQuote quoteShipping(OrderId id)
        throws Exception {
    // close() waits for every child
    try (var scope = Executors
            .newVirtualThreadPerTaskExecutor()) {
        var orderRead = scope.submit(() -> orderStore.get(id));
        var ratesRead = scope.submit(() -> carrier.getRates(id));
        var stockRead = scope.submit(() -> warehouse.getStock(id));

        var quote = Shipping.chooseQuote(        // pure
            orderRead.get(), ratesRead.get(), stockRead.get());
        return quote;
    }
}
```

</td>
</tr>
</table>

The sandwich of [Axiom 13](../chapter2/axiom-13-impureim.md) is unchanged: the gather step has become concurrent, and `ChooseQuote` never sees a task. Both versions keep rule 1: every child is joined. The C# version also passes cancellation to every read (rule 3). Neither cancels the siblings when one read fails, and neither sets a deadline: that takes a few more lines, or a library built for structured concurrency. Which one to use is a choice for a Play or an ADR. The shape is what this model is about.

### Independent units

Each child is a whole sandwich: it gathers, decides and acts on data no other child touches. The tracking service of [Model 0](01-sequential.md#example), with one child per plan, is this shape. If it stays this way, every child needs:

- **its own resources:** its own database context, created inside the child;
- **disjoint data:** one tracker per plan and box, so no two children write the same row;
- **an outcome as a value:** each child returns a `Result` ([Axiom 17](../chapter2/axiom-17-result.md)) that the parent collects, instead of writing to a shared list or logging and carrying on;
- **idempotent transitions:** when one child fails and the event is delivered again, the children that already succeeded run again. Their `Decide` must answer `NoChange` for an event they have already applied ([Axiom 25](../chapter2/axiom-25-state-machines.md)).

[Model 0](01-sequential.md) is usually the better answer for this shape: one gather and one act for all the units, and the four requirements above disappear.

---

## Testing

Marlow names what this model buys for testing: "Deterministic parallel programming is the best of both worlds: Testing, debugging, and reasoning can be performed on the sequential program, but the program runs faster with the addition of more processors" [4].

Built on [Chapter 3](../chapter3/README.md#what-i-do-today):

- **Parallel map.** The function gets function tests, as always. A combining function gets one more: combining `a` with `b` and then `c` gives the same as `a` with the combination of `b` and `c`. That is the property the runtime relies on.
- **Concurrent gather.** The decision gets function tests. The scope gets a component test where a [simulator](../chapter3/README.md#simulators) is told to fail or to stall one read: the call fails or times out as designed, and nothing is left running.
- **Independent units.** Each unit's `Decide` gets function tests, including the `NoChange` case for a repeated event. A component test delivers the same event twice and checks that the second time changed nothing.

---

## When to step up, and when NOT to

Step up when the children must talk to each other while they run: one child's progress changes what another does. That is no longer fork–join. It is [Model 2](03-one-owner.md), with one owner of the shared state.

Don't use this model:

- **When the work is small.** Starting and joining children costs more than a pure function that runs in microseconds. Parallelize across requests or events (the host already does) before parallelizing inside one.
- **When the units can be merged.** If each child would query the same database, one gather and one act for all of them is simpler and faster ([Model 0](01-sequential.md)).
- **When the children's data overlap.** Two children writing the same row are at [Model 3](04-shared-state.md), whatever the code looks like. Merge them, or treat the row as shared state.

---

## References

[1] **Peter Van Roy**, *Programming Paradigms for Dummies: What Every Programmer Should Know*, 2009. Also cited in the [chapter introduction](README.md#references). Deterministic concurrency "is as easy as functional programming and it cannot have race conditions".
<https://webperso.info.ucl.ac.be/~pvr/VanRoyChapter.pdf>

[2] **Nathaniel J. Smith**, *Notes on structured concurrency, or: Go statement considered harmful*, njs blog, 25 April 2018. A scope (his *nursery*) that can't exit before its children, and an unstructured spawn as "a form of goto statement".
<https://vorpus.org/blog/notes-on-structured-concurrency-or-go-statement-considered-harmful/>

[3] **Timothy G. Mattson, Beverly A. Sanders and Berna L. Massingill**, *Patterns for Parallel Programming*, Addison-Wesley Software Patterns Series, 2004. The Finding Concurrency design space, whose first patterns decompose a problem by task and by data. Only read through the authors' companion site and its table of contents.
<https://www.cise.ufl.edu/research/ParallelPatterns/contents.htm>

[4] **Simon Marlow**, *Parallel and Concurrent Programming in Haskell*, O'Reilly, 2013, chapter 1. Also cited in the [chapter introduction](README.md#references). For parallel programming, deterministic models "if at all possible", because "concurrency sacrifices determinism".
<https://www.oreilly.com/library/view/parallel-and-concurrent/9781449335939/ch01.html>

---

← Previous: [Model 0 — Sequential](01-sequential.md) · Next: [Model 2 — One owner](03-one-owner.md) →
