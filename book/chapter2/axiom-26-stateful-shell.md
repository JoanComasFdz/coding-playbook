# Axiom 26 — Stateful Shell

**A Stateful Shell is the long-running version of [Axiom 24](axiom-24-state-machines.md)'s shell. The pure `Transition` doesn't change. The shell does: instead of running once, it loops. Read the current state, carry out the effect that state implies, wait for the result as an event, call `Transition`, and repeat, until the machine reaches a final state or is cancelled.**

- **The core** is a `Transition(state, event) → state`, as in [Axiom 24](axiom-24-state-machines.md). Its state DU is split into the states the loop can act on and the final ones, so the loop never has to handle a final state ([Axiom 22](axiom-22-illegal-states.md)).
- **The state implies the effect.** Each state names one thing the shell does: `Connecting` tries to connect, `BackingOff` waits, `Connected` reads.
- **The result of that effect** (connected, failed, disconnected, time elapsed) comes back as an event and goes into `Transition`.
- **Working memory across iterations** (a message counter, the cancellation signal) lives in a [Session Context](axiom-25-session-context.md), held by the shell and never seen by `Transition`.

[Axiom 24](axiom-24-state-machines.md)'s shell ran once per request. Many programs don't: a queue subscriber reads forever, a client reconnects after every drop, a worker waits for the next job. The decision, *what state are we in next?*, keeps exactly the shape `Transition` always had. What grows is the shell around it: it carries out the right effect for the current state, waits for the event that effect produces, and does it again until the machine is done.

Through [Axiom 8](axiom-08-connascence.md)'s lens, the loop doesn't weaken a [Connascence of Execution](axiom-08-connascence.md#connascence-of-execution-coe) so much as *gather* it: the order of steps that callbacks would scatter across files sits in one visible loop.

> **A note on the name.** This shape has an older name from language runtimes: the *interpreter loop*. A bytecode VM fetches the next instruction, decodes it, executes its effect and moves on; this shell fetches the current state, matches on it, executes the effect that state implies, and moves on through `Transition`. I call it a Stateful Shell because that points straight at [Axiom 24](axiom-24-state-machines.md)'s shell, now kept alive across many steps. Anyone who has written a REPL or a `gen_statem` module [4] will recognize it.

---

## Definitions

A **Stateful Shell** is an impure orchestrator that drives a state machine through its whole life. Each iteration of its loop is one step of the machine:

1. **Read the current state**, kept in a local variable the loop updates.
2. **Carry out the effect that state implies**: match on the state and do its impure work (open a socket, wait, read the next message).
3. **Wait for the event** that effect produces (connected, failed, message read, time elapsed).
4. **Call `Transition(state, event)`**, which is pure and returns the next state.
5. **Repeat** until the next state is final or the loop is cancelled.

Each iteration is one sandwich of [Axiom 12](axiom-12-impureim.md) [3], and the four-step shell of [Axiom 24](axiom-24-state-machines.md#definitions), repeated.

The terms it relies on:

- **Final state**: a state where nothing more can happen. The machine reached its goal or gave up (`Failed`). It is a case of the state DU, and the loop stops when `Transition` returns it.
- **Cancellation**: an outside signal (a `CancellationToken` in C#, an `AtomicBoolean` in Java) that stops the loop. Long-running effects receive it too, so a wait ends early and a read stops cleanly.
- **Event**: something that happens in the world, which the loop observes but doesn't control (a packet arrived, the socket dropped, the timer fired). It fills the slot [Axiom 24](axiom-24-state-machines.md#definitions) calls a command; there, a request to the machine, here a fact from the world.

**Moore, not Mealy.** [Axiom 24](axiom-24-state-machines.md)'s `Transition` returns an event that carries the next state: a [Mealy machine](https://en.wikipedia.org/wiki/Mealy_machine). Here `Transition` returns the next state directly, and the effect depends only on the state: a [Moore machine](https://en.wikipedia.org/wiki/Moore_machine), whose output depends only on its current state [2]. That fits a loop, which only needs the next state to decide its next effect. The Mealy shape still works, and is the better choice when something else (an audit log, metrics) also needs the events. Pick one per machine and stay with it.

---

## Example

A message-queue subscriber. It connects to a broker, reads messages until the connection drops, reconnects with a growing delay, and gives up after too many failed attempts or when cancelled.

- **States**, split in two: `RunningState = Connecting(attempt) | Connected(connection) | BackingOff(nextAttempt)` are the states the loop acts on; `ConnState = Running(RunningState) | Failed(reason)` adds the final state.
- **Events**: `ConnectSucceeded(connection)`, `ConnectFailed(reason)`, `Disconnected`, `BackoffElapsed`.
- **`Transition`**: `RunningState × ConnEvent → ConnState`. It takes a running state (nothing transitions out of `Failed`) and returns either `Running`, to continue, or `Failed`, to stop.
- **Session Context**: `SubscriberContext`, with a message counter and the cancellation signal.

`BrokerConnection` stands for whatever the broker library returns. The effect helpers (`TryConnect`, `WaitFor`, `ConsumeUntilDropped`) are left out; the axiom is about the loop, not their bodies.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public abstract record RunningState;
public sealed record Connecting(int Attempt) : RunningState;
public sealed record Connected(BrokerConnection Connection)
    : RunningState;
public sealed record BackingOff(int NextAttempt) : RunningState;

public abstract record ConnState;
public sealed record Running(RunningState State) : ConnState;
public sealed record Failed(string Reason)       : ConnState;

public abstract record ConnEvent;
public sealed record ConnectSucceeded(BrokerConnection Connection)
    : ConnEvent;
public sealed record ConnectFailed(string Reason) : ConnEvent;
public sealed record Disconnected   : ConnEvent;
public sealed record BackoffElapsed : ConnEvent;

public sealed class SubscriberContext
{
    public int ProcessedCount { get; set; }
    public CancellationToken Cancellation { get; init; }
}

private const int MaxAttempts = 5;

public static ConnState Transition(RunningState state, ConnEvent ev) =>
    (state, ev) switch
    {
        (Connecting, ConnectSucceeded s) =>
            new Running(new Connected(s.Connection)),
        (Connecting(var attempt), ConnectFailed)
            when attempt < MaxAttempts =>
            new Running(new BackingOff(attempt + 1)),
        (Connecting, ConnectFailed f) =>
            new Failed(f.Reason),
        (Connected, Disconnected) =>
            new Running(new BackingOff(1)),
        (BackingOff(var next), BackoffElapsed) =>
            new Running(new Connecting(next)),
        _ => new Running(state)   // event doesn't apply: no change
    };

public Failed Run(SubscriberContext context)
{
    RunningState state = new Connecting(1);
    while (!context.Cancellation.IsCancellationRequested)
    {
        ConnEvent ev = state switch                     // act
        {
            Connecting   => TryConnect(),
            Connected c  => ConsumeUntilDropped(c.Connection, context),
            BackingOff b => WaitFor(
                CalculateBackoffDelay(b.NextAttempt), context.Cancellation),
            _ => throw new UnreachableException()
        };

        var next = Transition(state, ev);               // decide

        switch (next)
        {
            case Running r: state = r.State; break;
            case Failed f:  return f;
            default:        throw new UnreachableException();
        }
    }
    return new Failed("cancelled");
}
```

</td>
<td>

```java
public sealed interface RunningState
    permits Connecting, Connected, BackingOff {}
public record Connecting(int attempt) implements RunningState {}
public record Connected(BrokerConnection connection)
    implements RunningState {}
public record BackingOff(int nextAttempt) implements RunningState {}

public sealed interface ConnState permits Running, Failed {}
public record Running(RunningState state) implements ConnState {}
public record Failed(String reason)       implements ConnState {}

public sealed interface ConnEvent
    permits ConnectSucceeded, ConnectFailed, Disconnected, BackoffElapsed {}
public record ConnectSucceeded(BrokerConnection connection)
    implements ConnEvent {}
public record ConnectFailed(String reason) implements ConnEvent {}
public record Disconnected()   implements ConnEvent {}
public record BackoffElapsed() implements ConnEvent {}

public static final class SubscriberContext {
    public int processedCount;
    public final AtomicBoolean cancelled;
    public SubscriberContext(AtomicBoolean cancelled) {
        this.cancelled = cancelled;
    }
}

private static final int MAX_ATTEMPTS = 5;

public static ConnState transition(RunningState state, ConnEvent ev) {
    return switch (state) {
        case Connecting c -> switch (ev) {
            case ConnectSucceeded s -> new Running(new Connected(s.connection()));
            case ConnectFailed f    -> c.attempt() < MAX_ATTEMPTS
                ? new Running(new BackingOff(c.attempt() + 1))
                : new Failed(f.reason());
            default -> new Running(state);   // event doesn't apply
        };
        case Connected c -> switch (ev) {
            case Disconnected d -> new Running(new BackingOff(1));
            default             -> new Running(state);
        };
        case BackingOff b -> switch (ev) {
            case BackoffElapsed e -> new Running(new Connecting(b.nextAttempt()));
            default               -> new Running(state);
        };
    };
}

public Failed run(SubscriberContext context) {
    RunningState state = new Connecting(1);
    while (!context.cancelled.get()) {
        ConnEvent ev = switch (state) {                 // act
            case Connecting c -> tryConnect();
            case Connected c  -> consumeUntilDropped(c.connection(), context);
            case BackingOff b -> waitFor(
                calculateBackoffDelay(b.nextAttempt()), context.cancelled);
        };

        var next = transition(state, ev);               // decide

        switch (next) {
            case Running r -> state = r.state();
            case Failed f  -> { return f; }
        }
    }
    return new Failed("cancelled");
}
```

</td>
</tr>
</table>

`Transition` never sees the connection, the clock, the cancellation signal or the counter. It is pure ([Axiom 5](axiom-05-pure-functions.md)) and tested as a table of (state, event, expected) rows. The loop matches on the running state, and there is no `Failed` branch to write, because the variable's type can't hold a `Failed`: the final state lives only in `Transition`'s return type. (The C# discard branch is the usual limitation of [Axiom 11](axiom-11-pattern-matching.md#definitions), not a real case; C# 15's union types would remove it.)

`ConsumeUntilDropped` is the one effect that touches the Session Context. Message processing lives inside it, not as events of the machine, because the machine models only the connection's life:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// inside ConsumeUntilDropped
while (!connection.IsDropped
       && !context.Cancellation.IsCancellationRequested)
{
    ProcessMessage(connection.Read());
    context.ProcessedCount++;   // the only write to the context
}
return new Disconnected();
```

</td>
<td>

```java
// inside consumeUntilDropped
while (!connection.isDropped() && !context.cancelled.get()) {
    processMessage(connection.read());
    context.processedCount++;   // the only write to the context
}
return new Disconnected();
```

</td>
</tr>
</table>

That counter is the whole reason `SubscriberContext` exists here: a per-session accumulator, owned by the shell, written in exactly one place and never seen by `Transition` ([Axiom 25](axiom-25-session-context.md)). The cancellation check inside this inner loop is the other half of the contract: the shell honors the signal wherever a long-running effect could otherwise hang, not only at the outer `while`.

---

## Problem / forces

When something lives across many events and must act differently in each condition, four shapes are common:

1. **A `while (true)` with rules and effects mixed.** The body connects, reads, checks flags, waits and retries inline. The state hides in local variables and in *where* the code is; to know what the loop is doing, you read all of it. It is the tangle [Axiom 24](axiom-24-state-machines.md#problem--forces) describes, now in a loop.
2. **Nested callbacks.** Each effect registers a callback for its result, which starts the next effect. The state lives in a chain of closures, with no single place that says "we are connecting right now". Testing a decision means building the whole callback graph.
3. **An actor framework or workflow engine** (Akka, Spring Statemachine, Erlang's `gen_statem`, Temporal, Camunda). A runtime drives a declared graph of states. A good fit when what the runtime provides (supervision, persistence, distribution, durable timers) is itself a requirement. The rules sit in configuration rather than in the types, the runtime is a dependency, and testing involves it.
4. **A Stateful Shell around a pure `Transition`.** A small loop that reads the state, carries out its effect, waits for the event, calls `Transition`, and repeats. The rules live in `Transition`; the runtime is whatever the host provides (a thread, an async task, a virtual thread).

Options 1 and 2 never name the state machine the program really is. Options 3 and 4 both separate describing the machine from running it; the choice between them is the one [Axiom 24](axiom-24-state-machines.md#problem--forces) describes for libraries. This book defaults to the Stateful Shell when the host already gives you the runtime you need and the rules fit in one pure function.

---

## Why

**1. The core is unchanged, and each iteration is a known shape.**
`Transition` is still pure and total; reviewing what the machine does still means reading one function. Each iteration of the loop is the shell of [Axiom 24](axiom-24-state-machines.md), so the loop adds only the repetition [1].

**2. The state implies the effect.**
To learn what the program does in state X, read the one branch of the loop's `switch` for X. There is no other place where an effect might fire, and no callback registered elsewhere.

**3. Both exits are visible.**
The loop ends when `Transition` returns a final state or when cancellation arrives, and both checks are in plain sight. In a `while (true)`, exits hide as `break`s and `return`s scattered through the body.

**4. The host doesn't matter.**
The same loop runs on a dedicated thread, an async task, a virtual thread or a command-line program's main thread. Moving from blocking to async changes the effect helpers' signatures, not the loop.

> **Where Tell, Don't Ask belongs.** [Axiom 1](axiom-01-data-is-not-behavior.md#tell-dont-ask-the-road-not-taken) set *Tell, Don't Ask* aside for the pure core, where data is pulled out as values and decisions are made outside any object. The Stateful Shell is where that maxim comes back. A connection, a socket or a broker handle is a real *place*, not a value: you can't freeze a live connection into a fact, and you shouldn't reach inside it to drive it by hand. So the shell *tells* it (`TryConnect()`, `connection.Read()`) and never asks for its internals to decide outside. Tell, Don't Ask was never wrong; it has a location. It is the right rule on the stateful side of the seam, around resources that really hold state, and the wrong rule on the pure side, where [Axiom 23](axiom-23-pure-functions-returning-actions.md) takes the decision out as a value.

---

## Trade-offs

- **The loop's `switch` grows with the states.** Fifteen states mean fifteen branches. As with `Transition` ([Axiom 24](axiom-24-state-machines.md#trade-offs)), split the work into one helper per state, which the loop calls.
- **The final state needs its own place in the types.** Splitting `RunningState` from `ConnState` keeps the loop's `switch` free of a `Failed` branch. A single flat DU is simpler for a tiny machine, but then every `switch` in the loop needs a branch for a state it can never see. Either way, *have* a final state: a Stateful Shell without one runs forever.
- **Cancellation is part of the contract.** A long-running loop that can't be stopped is a leak. The signal goes into the loop condition *and* into every long-running effect, so a wait ends early and a read stops. The one-shot shell of [Axiom 24](axiom-24-state-machines.md) never paid this cost.
- **Inner loops are a design choice.** The example processes messages inside `ConsumeUntilDropped`. The alternative is to make each message an event (`MessageReceived`) that `Transition` mostly ignores. Keep the inner loop while messages don't change the machine's state; promote a message to an event when it does (a message that means "this session is ending").
- **Batching, back-pressure and bad messages belong to the effect.** How `ConsumeUntilDropped` acknowledges messages in batches, slows down, or treats a malformed message is about *how* the `Connected` effect works; the machine only cares about the event it returns. Split those concerns into named helpers rather than into the machine.

---

## When NOT to

- **One-shot work.** A request handler that loads a state, calls `Transition` once, saves and responds ([Axiom 24](axiom-24-state-machines.md)) has no loop. Neither does a handler where each message is independent: the web server or queue listener is the loop, and each handling is a one-shot shell.
- **Plain batch processing.** A program that runs a pure function over each item of a stream and exits has no state beyond its position in the stream: it is `foreach`, not a state machine. The Stateful Shell earns its vocabulary when the *next* step depends on the *current* state of something long-lived, such as a connection.
- **A workflow engine already runs it.** Temporal, Camunda or AWS Step Functions are Stateful Shells with persistence built in; a hand-written loop on top would duplicate them ([Axiom 24](axiom-24-state-machines.md#when-not-to)).

---

## References

[1] **Scott Wlaschin**, *Domain Modeling Made Functional*, Pragmatic Bookshelf, 2018. Also cited in [Axiom 16](axiom-16-result.md), [Axiom 17](axiom-17-result-combinators.md), [Axiom 19](axiom-19-railway.md), [Axiom 20](axiom-20-validation.md), [Axiom 23](axiom-23-pure-functions-returning-actions.md) and [Axiom 24](axiom-24-state-machines.md). Pure transitions with impure orchestration around them, the shape this loop repeats.
<https://pragprog.com/titles/swdddf/domain-modeling-made-functional/>

[2] **Edward F. Moore**, *Gedanken-experiments on Sequential Machines*, in *Automata Studies* (Annals of Mathematics Studies 34), Princeton University Press, 1956, pp. 129–153. The Moore machine, whose output depends only on its current state: `Transition` is its next-state function, and the loop's per-state effect is its output.

[3] **Mark Seemann**, *Impureim Sandwich*, ploeh blog, 2020. Also cited in [Axiom 12](axiom-12-impureim.md) and [Axiom 23](axiom-23-pure-functions-returning-actions.md). Each iteration of the loop is one sandwich: an impure effect, the pure `Transition`, then the next state.
<https://blog.ploeh.dk/2020/03/02/impureim-sandwich/>

[4] **Erlang/OTP**, *gen_statem* documentation. The framework form of this shape: OTP runs the loop, and the programmer supplies the per-state callbacks.
<https://www.erlang.org/doc/apps/stdlib/gen_statem.html>

---

← Previous: [Axiom 25 — Session Context](axiom-25-session-context.md) · Next: [Axiom 27 — Typestate](axiom-27-typestate.md) →
