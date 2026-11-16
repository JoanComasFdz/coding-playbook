# Model 2 — One owner

**One timeline owns a piece of state. Every other timeline sends it messages and never touches the state. The owner takes the messages one at a time and applies each with a pure function. Only the order in which messages arrive can vary.**

- It is Van Roy's *message-passing concurrency*, which he calls "the correct default for general-purpose concurrent programming instead of shared-state concurrency" [1].
- In code it is a [Stateful Shell](../chapter2/axiom-27-stateful-shell.md) whose events come from a mailbox: the loop is the owner, and its pure transition is the only thing that changes the state.
- Use it for in-memory state that many timelines update: a live board, a running total, a cache that a background job refreshes.

---

## Definitions

- **Owner:** the one timeline allowed to change the state. It runs a loop: take the next message, apply it, repeat ([Axiom 27](../chapter2/axiom-27-stateful-shell.md#definitions)).
- **Message:** an immutable value ([Axiom 3](../chapter2/axiom-03-immutability.md)) that says what happened or what is asked. A closed set of messages is a [discriminated union](../chapter2/axiom-22-discriminated-unions.md).
- **Mailbox:** the queue between senders and owner. Any timeline can put a message in; only the owner takes them out.
- **Transition:** the pure function `Apply(state, message) → state` ([Axiom 25](../chapter2/axiom-25-state-machines.md)). The owner calls it; no one else does.
- **Snapshot:** the owner can publish its latest state as an immutable value for others to read. Many readers, one writer: a reader holds a value that can't change, even while the owner moves on.

The shape is old: it is the [actor model](https://en.wikipedia.org/wiki/Actor_model) [2], and Erlang builds whole systems out of it [3]. What this book takes from it is the minimum: one owner, a mailbox, a pure transition.

---

## What can race

The state can't: only the owner changes it, one message at a time. What can still vary:

- **The order of messages from different senders.** Two senders, two messages: either may arrive first. That matters only when `Apply` gives a different state for a different order. When it does, the message must carry what it depends on, or the sender must wait for a reply before sending the next one.
- **What a reader sees.** A snapshot can be one message behind. A sender that reads right after sending may not see its own message applied yet. When it must, the message carries a reply that the owner completes after applying it.
- **The mailbox's size.** Senders faster than the owner grow the mailbox without limit. A bounded mailbox makes senders wait instead: [back-pressure](https://en.wikipedia.org/wiki/Back_pressure).

And two limits that aren't races but decide whether this model fits:

- **The state lives in memory.** A restart loses it. It must be rebuildable (from the database, from replayed events) or not worth keeping.
- **One owner per process.** Two instances of the service have two owners and two different states. For state that must agree across instances, the shared place is the database: [Model 3](04-shared-state.md).

---

## Example

A live board shows how many boxes are at each depot. Events from many request threads change the counts; a dashboard endpoint reads them.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public abstract record BoardMessage
{
    // Match, as in Axiom 22
}
public sealed record BoxArrived(DepotId Depot)
    : BoardMessage;
public sealed record BoxLeft(DepotId Depot)
    : BoardMessage;

public static class Boards                    // pure
{
    public static DepotBoard ApplyMessage(
        DepotBoard board, BoardMessage message) =>
        message.Match(
            boxArrived: m => board.WithCount(
                m.Depot, board.CountAt(m.Depot) + 1),
            boxLeft: m => board.WithCount(
                m.Depot, board.CountAt(m.Depot) - 1));
}
```

</td>
<td>

```java
public sealed interface BoardMessage
    permits BoxArrived, BoxLeft {}
public record BoxArrived(DepotId depot)
    implements BoardMessage {}
public record BoxLeft(DepotId depot)
    implements BoardMessage {}

public final class Boards {                   // pure
    public static DepotBoard applyMessage(
            DepotBoard board, BoardMessage message) {
        return switch (message) {
            case BoxArrived m -> board.withCount(
                m.depot(), board.countAt(m.depot()) + 1);
            case BoxLeft m -> board.withCount(
                m.depot(), board.countAt(m.depot()) - 1);
        };
    }
}
```

</td>
</tr>
</table>

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed class BoardOwner                // shell
{
    private readonly Channel<BoardMessage> inbox =
        Channel.CreateBounded<BoardMessage>(10_000);
    private volatile DepotBoard current =
        DepotBoard.Empty;

    // any timeline: send a message, read a snapshot
    public ValueTask SendAsync(
        BoardMessage message, CancellationToken ct) =>
        inbox.Writer.WriteAsync(message, ct);
    public DepotBoard ReadBoard() => current;

    // one timeline: the owner
    public async Task RunAsync(CancellationToken ct)
    {
        await foreach (var message
            in inbox.Reader.ReadAllAsync(ct))
        {
            var next = Boards.ApplyMessage(
                current, message);           // pure
            current = next;                  // the only write
        }
    }
}
```

</td>
<td>

```java
public final class BoardOwner {               // shell
    private final BlockingQueue<BoardMessage> inbox =
        new ArrayBlockingQueue<>(10_000);
    private volatile DepotBoard current =
        DepotBoard.EMPTY;

    // any timeline: send a message, read a snapshot
    public void send(BoardMessage message)
            throws InterruptedException {
        inbox.put(message);
    }
    public DepotBoard readBoard() { return current; }

    // one timeline: the owner
    public void run() throws InterruptedException {
        while (!Thread.currentThread().isInterrupted()) {
            var message = inbox.take();
            var next = Boards.applyMessage(
                current, message);           // pure
            current = next;                  // the only write
        }
    }
}
```

</td>
</tr>
</table>

Three things to see:

- **`ApplyMessage` is the whole logic, and it is pure.** It never sees the mailbox, the thread or the field.
- **There is one write, in one place.** `current` is a shared field, but only the owner's loop assigns it. One writer can't lose an update.
- **Readers get a value.** `ReadBoard` returns an immutable `DepotBoard`. The field is `volatile` so readers on other threads see each new snapshot. Why that keyword is needed is a question for the memory model, below this chapter's scope.

The two counts here are commutative: `BoxArrived` then `BoxLeft` gives the same board as the reverse. So the order of messages from different senders doesn't show. If a message depended on the order (say, "close the depot"), the case would need its own thought (see *What can race*).

---

## Testing

Built on [Chapter 3](../chapter3/README.md#what-i-do-today):

- **`ApplyMessage` gets function tests:** a table of board, message and expected board.
- **Where the order of messages is meant not to matter, test that too:** applying two messages in either order gives the same board. That is the claim the model rests on, and a function test can check it.
- **The owner gets a component test:** send a burst of messages through the component's API, then read the board through it. The loop itself has nothing to decide, so a few component tests cover it.

---

## When to step up, and when NOT to

Step up to [Model 3](04-shared-state.md) when:

- **The state must survive a restart or agree across instances.** It belongs in the database, and the database is shared state.
- **A reader must see its own write at once, and a reply is too slow.** A reference updated in place by compare-and-swap gives that, at Model 3's price.

Don't use this model:

- **For state that belongs to one request or one run.** That is a [Session Context](../chapter2/axiom-26-session-context.md), passed explicitly and never shared.
- **When nothing is shared over time.** Work that is split, done and joined is [Model 1](02-deterministic-concurrency.md). An owner adds a loop, a mailbox and a lifetime to manage.
- **When an actor framework is already the runtime.** If supervision, distribution or durable mailboxes are requirements, a framework that provides them is the owner ([Axiom 27](../chapter2/axiom-27-stateful-shell.md#problem--forces) weighs the same choice).

---

## References

[1] **Peter Van Roy**, *Programming Paradigms for Dummies: What Every Programmer Should Know*, 2009. Also cited in the [chapter introduction](README.md#references). Message passing as the default for concurrent programming, ahead of shared state.
<https://webperso.info.ucl.ac.be/~pvr/VanRoyChapter.pdf>

[2] **Carl Hewitt, Peter Bishop and Richard Steiger**, *A Universal Modular ACTOR Formalism for Artificial Intelligence*, IJCAI, 1973. The origin of the actor model: independent agents that communicate only by messages.

[3] **Joe Armstrong**, *Making reliable distributed systems in the presence of software errors*, PhD thesis, Royal Institute of Technology, Stockholm, 2003. Erlang's design: isolated processes that share nothing and own their state.

---

← Previous: [Model 1 — Deterministic concurrency](02-deterministic-concurrency.md) · Next: [Model 3 — Shared state](04-shared-state.md) →
