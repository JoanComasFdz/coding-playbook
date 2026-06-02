# Axiom 26 — Stateful Shell

**A Stateful Shell is the long-running counterpart of [Axiom 24](axiom-24-state-machines.md)'s one-shot shell. The pure `Transition` is unchanged. What changes is the shell: instead of running once per request, it runs in a loop — read the current state, dispatch the side effect that state implies, await the environmental result as an event, call `Transition`, repeat — until the FSM reaches a terminal state or external cancellation fires.**

- The pure core is the same `Transition(state, event) → state` shape from [Axiom 24](axiom-24-state-machines.md), refined so the state DU splits into a running subset (variants the dispatch can see) and a terminal subset (the exits) — *illegal states unrepresentable* ([Axiom 6](axiom-06-honest-total-signatures.md)) at the FSM-state level, so the dispatch never needs a defensive arm against the terminal.
- The loop body pattern-matches on the *current state* to decide what side effect to perform — *the state implies the effect*. Each state names one natural action the shell takes: Connecting tries to connect; BackingOff sleeps; Connected reads.
- The environmental result of that side effect — a connection succeeded, a packet arrived, a timer elapsed, a cancellation fired — arrives as an event and is fed into `Transition` to produce the next state.
- The loop exits when the next state is *terminal* (no further action is meaningful) or when an external cancellation signal arrives.
- Cross-tick working memory — message counters, the cancellation token, captured callbacks — lives in a [Session Context (Axiom 25)](axiom-25-session-context.md), held by the shell, never seen by `Transition`.

[Axiom 24](axiom-24-state-machines.md) closed with a one-shot shell: an HTTP endpoint loaded state, called `Transition` once, persisted the new state, returned a response. Many programs are not one-shot. A message queue subscriber reads forever. A reconnecting client reconnects after every drop. A background worker waits for the next job, processes it, waits for the next. The pure decision — *what state are we in next?* — keeps the exact shape `Transition` always had. What grows is what the shell does *between* and *around* those decisions: it dispatches the right effect for the current state, awaits the environmental event the effect produces, and does so over and over until the machine is done. This axiom names that long-running shell — the **Stateful Shell**.

Through [Axiom 8](axiom-08-connascence.md)'s lens, this axiom does not weaken so much as *localise* a [Connascence of Execution](axiom-08-connascence.md#connascence-of-execution-coe): the temporal contract a callback-driven shell scatters is gathered into one explicit loop.

> **A note on the name.** This shape has an older name from the language-runtime world: the **Interpreter Loop**. A bytecode VM or a CPU interprets one instruction at a time — fetch the next instruction, decode it, execute the corresponding effect, advance, repeat — and that is exactly what this shell does, with FSM states standing in for instructions: fetch the current state, decode it (pattern-match), execute the side effect that state implies, take the resulting event, advance the state via `Transition`, repeat. *Stateful Shell* is the name this playbook prefers — it points straight at the relationship to [Axiom 24](axiom-24-state-machines.md)'s shell, now grown stateful across many calls — but anyone who has written a bytecode VM, a REPL, or a `gen_statem` callback module will recognise the shape on sight under its older name.

---

## Definitions

A **Stateful Shell** is an impure orchestrator that drives a state machine over its lifetime. Its body is a `while` (or equivalent) whose iteration is the FSM step:

1. **Read the current state** — held in a local variable that the loop updates each tick.
2. **Dispatch the effect that state demands** — pattern-match on the state and perform the impure work each state implies (open a socket, sleep for a delay, read the next message, send a packet).
3. **Await the environmental event** — the result of the dispatched effect arrives as an event (connection succeeded, connection failed, message received, timer elapsed, cancellation requested).
4. **Call `Transition(state, event)`** — pure ([Axiom 24](axiom-24-state-machines.md)); produces the next state.
5. **Repeat** until the next state is *terminal* or external cancellation arrives.

A few terms the loop relies on:

- **Terminal state** — a state for which no further dispatch is meaningful. The FSM either reached its goal (`Done`) or gave up (`Failed`). Modelled as one or more variants of the State DU; the loop's exit condition pattern-matches on them.
- **Cancellation** — an external signal (a `CancellationToken`, an `AtomicBoolean`, a closed channel) the shell honours by exiting the loop. Long-running dispatch helpers thread the signal in too, so a `Sleep` wakes early and a `Read` aborts cleanly.
- **Environmental event** — an occurrence the loop can observe but does not control: a packet arrived, the socket dropped, the timer elapsed, the user pressed Ctrl-C. Distinct from a command in [Axiom 24](axiom-24-state-machines.md)'s sense — a command is a request *to* the machine; an environmental event is a fact *from* the world. The structural role inside `Transition` is the same; [Axiom 24](axiom-24-state-machines.md) already noted that this input slot is also called `Signal`, `Trigger`, or `Event` when the FSM is reacting rather than answering requests.

The Moore-style signature **`Transition(state, event) → state`** — the function returns the next state directly — is the natural fit for a Stateful Shell because the loop never pattern-matches on the event after handing it to `Transition`; it only needs the next state to decide what to do on the next tick. The example below refines this slightly: the input is the *running-state subset* and the output is the *full state space* (including the terminal), so the "are we done?" decision lives in `Transition`'s output type and the dispatch's input type stays terminal-free. [Axiom 24](axiom-24-state-machines.md)'s Mealy-style shape (events carry strict-typed next state as their payload) still works here too, and is preferable when downstream consumers — an audit log, a metrics exporter, an observer — also need the event variant. The example below uses the refined Moore shape.

---

## Example

A small message-queue subscriber that connects to a broker, reads messages until the connection drops, reconnects with bounded retries and exponential backoff, and gives up after too many failures or when cancelled.

- **State DU**, split per [Axiom 6](axiom-06-honest-total-signatures.md) and [Axiom 21](axiom-21-discriminated-unions.md): `RunningState = Connecting(attempt) | Connected(connection) | BackingOff(nextAttempt)` (the variants the loop can actively dispatch from) and `ConnState = Running(RunningState) | Failed(reason)` (the full state space, with `Failed` as the terminal exit).
- **Event DU**: `ConnectSucceeded(connection)`, `ConnectFailed(reason)`, `Disconnected`, `BackoffElapsed`.
- **Pure `Transition`** — `RunningState × ConnEvent → ConnState`. Five arms plus an idempotent catch-all. The input is a `RunningState` (you cannot transition out of `Failed`); the output is a `ConnState` whose two variants carry whether the loop continues (`Running`) or stops (`Failed`).
- **Loop body**: the dispatch is exhaustive over `RunningState` — three arms, no `Failed` case, no defensive guard — because the local variable's type cannot be `Failed`. After each `Transition` call the result pattern-matches once: `Running` updates the local and continues; `Failed` returns it.
- **Session Context**: a `SubscriberContext` with `ProcessedCount` (accumulator) and `Cancellation` (the external signal).

`IConnection` is whatever connection handle the underlying broker library returns; the dispatch helpers `TryConnect`, `Sleep`, `ConsumeUntilDropped`, and `BackoffDelay` are impure shell helpers omitted for brevity — the axiom is teaching the loop shape, not the helper bodies.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public abstract record RunningState
{
    public abstract T Match<T>(
        Func<Connecting, T> onConnecting,
        Func<Connected,  T> onConnected,
        Func<BackingOff, T> onBackingOff);
}
public sealed record Connecting(int Attempt) : RunningState
{
    public override T Match<T>(
        Func<Connecting, T> onConnecting,
        Func<Connected,  T> onConnected,
        Func<BackingOff, T> onBackingOff) => onConnecting(this);
}
public sealed record Connected(IConnection Conn) : RunningState
{
    public override T Match<T>(
        Func<Connecting, T> onConnecting,
        Func<Connected,  T> onConnected,
        Func<BackingOff, T> onBackingOff) => onConnected(this);
}
public sealed record BackingOff(int NextAttempt) : RunningState
{
    public override T Match<T>(
        Func<Connecting, T> onConnecting,
        Func<Connected,  T> onConnected,
        Func<BackingOff, T> onBackingOff) => onBackingOff(this);
}

public abstract record ConnState;
public sealed record Running(RunningState RunningState) : ConnState;
public sealed record Failed(string Reason)       : ConnState;

public abstract record ConnEvent;
public sealed record ConnectSucceeded(IConnection Conn) : ConnEvent;
public sealed record ConnectFailed(string Reason)       : ConnEvent;
public sealed record Disconnected                       : ConnEvent;
public sealed record BackoffElapsed                     : ConnEvent;

public sealed class SubscriberContext
{
    public int ProcessedCount { get; set; }
    public CancellationToken Cancellation { get; init; }
}

private const int MaxAttempts = 5;

public static ConnState Transition(RunningState state, ConnEvent ev) => (state, ev) switch
{
    (Connecting,        ConnectSucceeded s)                 => new Running(new Connected(s.Conn)),
    (Connecting(var a), ConnectFailed) when a < MaxAttempts => new Running(new BackingOff(a + 1)),
    (Connecting,        ConnectFailed f)                    => new Failed(f.Reason),
    (Connected,         Disconnected)                       => new Running(new BackingOff(1)),
    (BackingOff(var n), BackoffElapsed)                     => new Running(new Connecting(n)),
    _                                                       => new Running(state)
};

public Failed Run(SubscriberContext ctx)
{
    RunningState currentRunningState = new Connecting(1);
    while (!ctx.Cancellation.IsCancellationRequested)
    {
        ConnEvent ev = currentRunningState.Match(                                  // impure dispatch, exhaustive by signature
            onConnecting:  _ => TryConnect(),
            onConnected:   c => ConsumeUntilDropped(c.Conn, ctx),
            onBackingOff:  b => Sleep(BackoffDelay(b.NextAttempt), ctx.Cancellation)
        );
        var connState = Transition(currentRunningState, ev);                       // pure call
        switch (connState)                                                         // match on the result
        {
            case Running r: currentRunningState = r.RunningState; break;
            case Failed  f: return f;
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
public record Connecting(int attempt)     implements RunningState {}
public record Connected(IConnection conn) implements RunningState {}
public record BackingOff(int nextAttempt) implements RunningState {}

public sealed interface ConnState permits Running, Failed {}
public record Running(RunningState runningState) implements ConnState {}
public record Failed(String reason)       implements ConnState {}

public sealed interface ConnEvent
    permits ConnectSucceeded, ConnectFailed, Disconnected, BackoffElapsed {}
public record ConnectSucceeded(IConnection conn) implements ConnEvent {}
public record ConnectFailed(String reason)       implements ConnEvent {}
public record Disconnected()                     implements ConnEvent {}
public record BackoffElapsed()                   implements ConnEvent {}

public static final class SubscriberContext {
    public int processedCount;
    public final AtomicBoolean cancelled;
    public SubscriberContext(AtomicBoolean cancelled) { this.cancelled = cancelled; }
}

private static final int MAX_ATTEMPTS = 5;

public static ConnState transition(RunningState state, ConnEvent ev) {
    return switch (state) {
        case Connecting c -> switch (ev) {
            case ConnectSucceeded s -> new Running(new Connected(s.conn()));
            case ConnectFailed f    -> c.attempt() < MAX_ATTEMPTS
                                        ? new Running(new BackingOff(c.attempt() + 1))
                                        : new Failed(f.reason());
            default                 -> new Running(state);
        };
        case Connected co -> switch (ev) {
            case Disconnected d -> new Running(new BackingOff(1));
            default             -> new Running(state);
        };
        case BackingOff b -> switch (ev) {
            case BackoffElapsed e -> new Running(new Connecting(b.nextAttempt()));
            default               -> new Running(state);
        };
    };
}

public Failed run(SubscriberContext ctx) {
    RunningState currentRunningState = new Connecting(1);
    while (!ctx.cancelled.get()) {
        ConnEvent ev = switch (currentRunningState) {                                // impure: exhaustive over RunningState
            case Connecting c -> tryConnect();
            case BackingOff b -> sleep(backoffDelay(b.nextAttempt()), ctx.cancelled);
            case Connected co -> consumeUntilDropped(co.conn(), ctx);
        };
        var connState = transition(currentRunningState, ev);                        // pure call
        switch (connState) {                                                         // match on the result
            case Running r -> { currentRunningState = r.runningState(); }
            case Failed  f -> { return f; }
        }
    }
    return new Failed("cancelled");
}
```

</td>
</tr>
</table>

`Transition` never sees the connection, the clock, the cancellation token, or the message counter — it is pure ([Axiom 5](axiom-05-pure-functions.md)) and tested as a table of `(state, event, expected)` rows. The loop dispatches on the current running state: each `RunningState` variant names one natural side effect the shell performs and awaits, and the dispatch is *exhaustive over `RunningState`* — there is no `Failed` arm because the local variable's type cannot be `Failed`. That is [Axiom 6](axiom-06-honest-total-signatures.md) / [Axiom 18](axiom-18-value-objects.md)'s *illegal states unrepresentable*, applied at the FSM-state level: the type system, not a runtime guard, keeps the terminal out of the dispatch. `Transition`'s return type carries the "are we done?" decision — `Running` to continue, `Failed` to exit — which the loop pattern-matches once per tick. `ConsumeUntilDropped` is itself a tight inner loop that reads messages, increments `ctx.ProcessedCount`, and returns `Disconnected` when the connection drops — message processing lives inside the Connected dispatch, not as FSM events, because the FSM here models only the connection lifecycle. The whole tick is one Impureheim sandwich from [Axiom 12](axiom-12-impureheim.md) — impure dispatch, pure `Transition`, impure update — and the loop is that sandwich repeated.

`ConsumeUntilDropped` is the one helper that touches the Session Context — every other dispatch helper (`TryConnect`, `Sleep`, `BackoffDelay`) just produces an event without mutating ctx. Its body, schematically:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// schematic — ConsumeUntilDropped
while (!conn.IsDropped && !ctx.Cancellation.IsCancellationRequested)
{
    Process(conn.Read());
    ctx.ProcessedCount++;     // session accumulator — only writer in the program
}
return new Disconnected();
```

</td>
<td>

```java
// schematic — consumeUntilDropped
while (!conn.isDropped() && !ctx.cancelled.get()) {
    process(conn.read());
    ctx.processedCount++;     // session accumulator — only writer in the program
}
return new Disconnected();
```

</td>
</tr>
</table>

That `ctx.ProcessedCount++` is the entire reason `SubscriberContext` exists in this example. It demonstrates [Axiom 25](axiom-25-session-context.md)'s shape concretely: a per-session accumulator, owned by the shell, written by exactly one site, never seen by `Transition`. The cancellation check inside the inner loop is the other half of the contract — the shell honours the external signal not just at the outer `while` but everywhere a long-running effect could otherwise stall.

Both versions of the dispatch are honestly exhaustive — no `default` arm, no throw, no defensive guard against an unreachable case. The C# version uses the **Match method form** from [Axiom 11](axiom-11-pattern-matching.md): `currentRunningState.Match(onConnecting: ..., onConnected: ..., onBackingOff: ...)`. Match's parameter list enumerates every variant, so the C# compiler refuses any call site that omits one — no `switch` expression, no CS8509 over `abstract record` hierarchies, no `_ =>` arm to fill with `throw new UnreachableException()`. The Java version takes the other surface from [Axiom 11](axiom-11-pattern-matching.md) — a pattern-matching `switch` over a `sealed interface` (JEP 441) — which is also exhaustive at compile-time. Both surfaces deliver the same property: an unreachable defensive arm in the dispatch cannot exist by construction. The cost C# pays for Match is per-tick closure allocation for the three lambda arms; in a hot-path loop where allocation pressure matters, the `switch` expression form remains an option, with its `_ => throw new UnreachableException()` understood as a CS8509 tooling artifact (a known platform limitation, not a guard against a real case) — that trade-off is the one [Axiom 11](axiom-11-pattern-matching.md) already drew between the two surfaces.

---

## Problem / forces

When a program needs an entity that lives across many events and must do something different in each condition over time, four shapes recur:

1. **A `while (true)` with the rules and the effects interleaved.** The body opens a socket, reads, checks status flags, sleeps, retries — all inline. The "state" is implicit in local variables and the position in the body; there is no name for any condition the loop is in; reasoning about "what is the loop doing right now?" means reading the entire body. The cost is the one [Axiom 24](axiom-24-state-machines.md) named: the decision and the effect are tangled, and the decision is not testable without standing the effect up.
2. **Callback hell / nested response handlers.** Each effect registers a callback for its result; the result callback registers the next effect; the next effect registers a callback for its result. The state lives in the closure chain; there is no central place that says "we are in `Connecting` right now." Following the flow means tracing handlers across files; testing the decision means standing up the entire callback graph.
3. **A configured actor framework or workflow runtime.** Akka FSM, Spring StateMachine, `gen_statem`, Temporal, Camunda. A declarative graph of states and transitions registered with a runtime that drives the machine. A long-standing option appropriate when the runtime's concerns — supervision, persistence, distribution, retries with circuit-breaking, observability, durable timers — are themselves part of the requirement; the framework solves problems that would otherwise be re-implemented by hand around the loop. Trade-off: the rules live in declarative configuration next to the type system rather than inside it, the runtime is a dependency, and testing involves standing the runtime up.
4. **A Stateful Shell calling [Axiom 24](axiom-24-state-machines.md)'s pure `Transition`.** The loop is a small impure shell that reads state, dispatches the per-state effect, awaits the event, calls `Transition`, repeats. The rules live inside `Transition`. The runtime is whatever the host process provides — a thread, an `async` task, a virtual thread.

Options 1 and 2 share one cost: state and effects are entangled, and the FSM that the program *is* never gets named. Options 3 and 4 are both honest separations of *describing* the machine from *running* it. The choice between 3 and 4 is the same one [Axiom 24](axiom-24-state-machines.md)'s Problem / forces drew for the one-shot case — whether the runtime concerns the framework solves earn its presence as a dependency. The Stateful Shell is the playbook's default when the host process already gives you the needed runtime — a thread, an async loop — and the rules are simple enough to express as one pure function.

---

## Why

**1. The pure core is unchanged.**
`Transition` is the same function from [Axiom 24](axiom-24-state-machines.md), pure and total. Reviewing what the machine does means reading `Transition`; running it over a real connection means wrapping it in this loop. The two concerns stay separate: rules in one place, runtime in another.

**2. Every tick is the one-shot shell from Axiom 24, iterated.**
Read state, dispatch effect, get event, call `Transition`, take the new state. The four-step shape [Axiom 24](axiom-24-state-machines.md) named is one tick of this loop. The loop adds *only* the iteration; the per-tick structure is already understood.

**3. The state implies the effect.**
A reviewer who wants to know "what does this program do when it's in state X?" pattern-matches on the loop's dispatch — one arm per state — and reads the body. There is no second place where effects might fire, no callback registered elsewhere, no implicit "after the previous step." The loop dispatches on the current state and only on the current state.

**4. Terminal states and cancellation are the exit conditions, both visible.**
The `while` condition is a pattern check on the state (`is not Failed`) plus an external cancellation check. Both exits live in one line. Compare with `while (true)` shells where exits live as scattered `break`s and `return`s buried in the body.

**5. Cross-tick working memory has a named home.**
Counters, the cancellation token, captured callbacks — anything the loop needs to read or accumulate between ticks — lives in a [Session Context (Axiom 25)](axiom-25-session-context.md) that the shell owns and threads through. The pure `Transition` never sees it; the loop and its dispatched effects do.

**6. The loop is host-agnostic.**
The same shape runs on a dedicated thread, an `async` task, a virtual thread, a goroutine, or the main thread of a CLI program. The host provides the runtime; the loop is the shape that uses it. Moving from a blocking thread to `async` swaps the `await` keyword and the dispatch helpers' signatures; the loop's structure does not change.

> **A note on Tell, Don't Ask.** [Axiom 1](axiom-01-data-vs-behaviour.md) set the OO maxim *Tell, Don't Ask* aside as the road not taken: in the pure core you pull data out as values and decide *outside* the object — the deliberate opposite of pushing behaviour into the state. The Stateful Shell is where that maxim comes back into its own. A connection, a socket, a pool, a broker handle is a genuine *place*, not a value — you cannot freeze a live connection into an immutable fact, and you should not reach into its insides to drive it by hand. So the shell *tells* them — `TryConnect()`, `conn.Read()`, `ConsumeUntilDropped(conn, ctx)` — and never asks for their internal state in order to decide externally. Tell-Don't-Ask was never wrong; it was *located*. It is the right rule on the stateful side of the seam — here, in the shell, around the resources that legitimately hold state — and the wrong rule on the pure side, where [Axiom 23](axiom-23-pure-functions-returning-actions.md) splits the decision back out as a value. The Impureheim seam between core and shell is exactly the line where the maxim flips.

---

## Trade-offs

**The loop's dispatch grows with the state count.** A four-state FSM has a four-arm dispatch; a fifteen-state FSM has a fifteen-arm one. The remedy is the same one [Axiom 24](axiom-24-state-machines.md) named for `Transition`: decompose into per-state helpers — `DispatchConnecting(...)`, `DispatchConnected(...)` — that the top-level dispatch delegates to. Both axes (states and the per-state effects) compose because both are values, and the helpers are unit-testable on their own.

**Terminal states earn their own seam in the type system.** The example splits the state DU into a `RunningState` (variants the loop dispatches from) and a `ConnState = Running(RunningState) | Failed(reason)` outer DU. The split makes the dispatch exhaustive without a `Failed` arm — the terminal lives in `Transition`'s output, not as a runtime-guarded case in the dispatch. A flatter single-DU shape (all variants in one hierarchy) is sometimes simpler when the FSM is tiny; it pays for the simplicity with an unreachable arm in every per-state dispatch. Either way, modelling the terminal at all is the part not to forget — a Stateful Shell without an explicit terminal spins forever.

**Cancellation is part of the contract.** A long-running loop without an honest cancellation path is a process leak — when the host wants to stop, the loop must too. The shell threads a `CancellationToken` (C#), an `AtomicBoolean` (Java), or an equivalent signal into both the loop condition and the long-running dispatch helpers (so `Sleep` exits early on cancellation and `ConsumeUntilDropped` aborts the read). This is a cost the one-shot shell from [Axiom 24](axiom-24-state-machines.md) did not pay.

**Moore vs Mealy is a choose-once decision.** The Moore-style `Transition(state, event) → state` used above is the simplest fit when the loop's dispatch is purely state-driven. [Axiom 24](axiom-24-state-machines.md)'s Mealy-style shape — events carrying the strict-typed next state — is the better fit when *downstream consumers* (an audit log, a metrics exporter, an observer) also need the event variant. Both shapes are honest; choose per codebase and stay consistent within the FSM.

**Inner loops inside a dispatch are a real engineering choice.** The example puts message processing inside `ConsumeUntilDropped` — an inner loop that reads, increments `ctx.ProcessedCount`, and returns `Disconnected` when the connection drops. The alternative is to surface every message as an FSM event (`MessageReceived(body)`) the outer loop pattern-matches with a `NoChange` arm. Both work; the inner-loop form keeps the outer FSM focused on connection lifecycle and avoids `Transition` arms that do nothing structural. When the message itself can drive a state transition — a protocol where one message type means "session is ending" — promote it to an FSM event; otherwise inline it in the dispatch.

**Backpressure, batching, and partial-failure recovery live in the dispatch.** A real `ConsumeUntilDropped` would batch acks, honour backpressure, and decide whether to surface a malformed message as a parse-error-logged-and-continue or as a `Disconnected` event that drops the connection. These concerns are about *how* the Connected dispatch does its work; the FSM only cares about the resulting event. Pile them all into the FSM and the FSM stops being an FSM; pile them all into one dispatch helper and that helper grows; the practical answer is the same as [Axiom 24](axiom-24-state-machines.md)'s — decompose into smaller pure or impure helpers, each named after the concern it solves.

---

## When NOT to

**One-shot shells.** When the program loads state once, calls `Transition` once, persists, and returns — the synthesis from [Axiom 24](axiom-24-state-machines.md) — there is no loop. The Stateful Shell is for entities that live across many events and must keep deciding what to do next. A request handler, a fire-and-forget command, a `main` that runs one batch and exits — none of these need this shape.

**Pure batch processors with no FSM.** A program that reads a stream of items, runs a pure function on each, writes the output, and exits has no "current state" beyond the iteration cursor — that's just `items.foreach(processOne)`. The Stateful Shell earns its vocabulary when the *next* iteration's behaviour depends on the *current* state of a stateful resource (a connection, a session, a long-running job). If every item is independent, the loop is just a loop, and the FSM machinery is dead weight.

**Heavy infrastructure that already runs the machine.** Temporal, Camunda, Step Functions, Akka Persistence, durable execution platforms — these are themselves Stateful Shells with persistence and supervision baked in. Building this axiom's shape on top of them duplicates the loop. The Stateful Shell is the playbook's answer when *you* own the host process; when a workflow engine owns it, configure the engine and let it drive the FSM directly.

**Single-event reactive handlers.** When the program reacts to one event at a time with no continuity between handlings — a webhook receiver, a queue consumer where each message is independent and there is no per-session state to carry across messages — there is no loop in the Stateful-Shell sense. Each handling is a one-shot shell ([Axiom 24](axiom-24-state-machines.md)); the host's dispatcher (the HTTP server, the queue listener framework) is what loops on the outside, and that is a fine division of labour.

---

## References

[1] **Scott Wlaschin**, *Domain Modeling Made Functional*, Pragmatic Bookshelf, 2018. Cross-listed from [Axiom 16](axiom-16-result.md), [Axiom 17](axiom-17-result-combinators.md), [Axiom 18](axiom-18-value-objects.md), [Axiom 19](axiom-19-railway.md), [Axiom 20](axiom-20-validation.md), [Axiom 23](axiom-23-pure-functions-returning-actions.md), and [Axiom 24](axiom-24-state-machines.md). The state-machine chapter shows the one-shot shell; the closing chapter on long-running workflows is the F# precedent for the loop shape this axiom names — pure transitions, impure orchestration, repeated.
<https://pragprog.com/titles/swdddf/domain-modeling-made-functional/>

[2] **John Hopcroft, Rajeev Motwani, Jeffrey Ullman**, *Introduction to Automata Theory, Languages, and Computation*, Addison-Wesley, 3rd ed. 2006. Cross-listed from [Axiom 24](axiom-24-state-machines.md). The Moore machine — `(Q, Σ, δ, λ, q0)` with transition function `δ: Q × Σ → Q` and output function `λ: Q → Λ` (output per state, not per transition) — is the mathematical ancestor of this axiom's shape: `Transition(state, event) → state` is exactly `δ`, and the loop's per-state dispatch is `λ`, the output function that fires the side effect implied by the current state. Axiom 24's Mealy form combines δ and λ on the transition; this axiom's Moore form separates them — δ inside `Transition`, λ inside the dispatch.

[3] **Mark Seemann**, *The Impureim Sandwich*, 2020. Cross-listed from [Axiom 5](axiom-05-pure-functions.md), [Axiom 12](axiom-12-impureheim.md), and [Axiom 23](axiom-23-pure-functions-returning-actions.md). Each tick of the Stateful Shell is one sandwich: impure dispatch → pure `Transition` → impure assignment of the next state. The loop is the iterated form of the sandwich, repeated until the FSM terminates.
<https://blog.ploeh.dk/2020/03/02/impureim-sandwich/>

[4] **Joe Armstrong**, *Programming Erlang* (2nd ed.), Pragmatic Bookshelf, 2013 — the chapters on `gen_server` and `gen_statem`. The OTP behaviours are the canonical reference for the framework form of this axiom (option 3 on the trade-off curve): the loop lives in the framework, the user supplies the per-state callback functions and a transition function. The Stateful Shell here is the hand-rolled equivalent — same shape, runtime owned by the host process rather than by OTP.
<https://pragprog.com/titles/jaerlang2/programming-erlang/>

---

← Previous: [Axiom 25 — Session Context](axiom-25-session-context.md) · Next: [Axiom 27 — Typestate](axiom-27-typestate.md) →
