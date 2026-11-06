# Axiom 24 — State machines

**A state machine is one pure function: `Transition(state, command) → event`. It takes the entity's current state and a command, and returns an event that carries the next state, or `NoChange` with the same state when the command doesn't apply. It is the shape of [Axiom 23](axiom-23-pure-functions-returning-actions.md) with the entity's state added to the inputs.**

- **State, command and event are data**: each is a sealed DU of immutable records ([Axiom 21](axiom-21-discriminated-unions.md)), and the state has one record per condition ([Axiom 22](axiom-22-illegal-states.md)).
- **Each successful event carries the specific next state it produces** (`Activated(Active)`, `Cancelled(Ended)`), so the transition table is checked by the type system.
- **`Transition` is pure and total**: every pair of state and command lands in some event, a real transition or `NoChange(state)`.
- **The shell** loads the state, calls `Transition`, matches on the event and saves the new state. How it answers `NoChange` is its decision.

[Axiom 23](axiom-23-pure-functions-returning-actions.md) returned an action describing what the shell should do. This axiom keeps that shape and adds two things: the entity's state joins the inputs, and each successful event carries the next state. That turns a one-shot decision into a machine: the same function, called again and again with the current state, drives the entity through its whole life. It is what this chapter has been building toward: pure functions over immutable types returning DUs, with one impure shell as the only seam [4][5].

Through [Axiom 8](axiom-08-connascence.md)'s lens, it turns a [Connascence of Execution](axiom-08-connascence.md#connascence-of-execution-coe) (the legal order of transitions, otherwise scattered across methods and checked at runtime) into a [Connascence of Type](axiom-08-connascence.md#connascence-of-type-cot).

> Most classes with more than one data field (not counting dependencies) are hiding a state machine behind several disconnected fields. I use this axiom as the default way to represent state whenever there is more than one field of it.

---

## Definitions

Four words, each with one meaning:

- **State**: the entity's *condition* right now. An immutable value: one record when the entity has one shape, a sealed DU of records when it has several. The DU form is the one to prefer when the allowed commands differ by condition.
- **Command**: a *request* to the machine, in the future tense: "activate this subscription". A sealed DU, each case carrying the data it needs. When the machine reacts to things that happen rather than to requests, the same slot is often called a signal or a trigger; its role is identical.
- **Event**: a *fact* about what happened, in the past tense: "this subscription was activated". A sealed DU. Successful events carry the next state. `NoChange` carries the unchanged state when the command doesn't apply (a second click, a stale request, a resent message): the machine reports an honest no-op instead of an error.
- **Transition**: the function that computes the event from a state and a command.

`Transition` matches on the *pair* of state and command ([Axiom 11](axiom-11-pattern-matching.md)). In automata theory this is a [Mealy machine](https://en.wikipedia.org/wiki/Mealy_machine), whose output depends on both the current state and the input [1]. Because each successful event names the specific state it produces, `new Activated(new Trial(...))` doesn't compile: [Axiom 22](axiom-22-illegal-states.md)'s idea, applied to the relationship between an event and its next state.

The shell is the sandwich of [Axiom 12](axiom-12-impureim.md), in four steps:

1. Load the current state.
2. Read anything else `Transition` needs as a value, such as today's date.
3. Call `Transition`.
4. Match on the event and carry out its effect: save the new state, respond.

Its form varies (an HTTP handler, a message handler, a long-running loop), but those steps don't. In Normand's terms, `Transition` is a calculation and the shell's response is the action [6].

Jérémie Chassaing describes a closely related shape, the *Decider*, as two functions: `decide`, from a command and a state to a list of events, and `evolve`, from a state and an event to the next state [2]. Here the next state rides inside the event, so one function does both jobs.

---

## Example

A subscription that is in `Trial`, `Active` or `Ended`. Three commands: `Activate`, `Renew`, `Cancel`. Four events: `Activated`, `Renewed`, `Cancelled` and `NoChange`.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public abstract record SubscriptionState;
public sealed record Trial(DateOnly StartedOn, DateOnly ExpiresOn)
    : SubscriptionState;
public sealed record Active(DateOnly RenewsOn) : SubscriptionState;
public sealed record Ended : SubscriptionState;

public abstract record SubscriptionCommand;
public sealed record Activate : SubscriptionCommand;
public sealed record Renew    : SubscriptionCommand;
public sealed record Cancel   : SubscriptionCommand;

public abstract record SubscriptionEvent;
public sealed record Activated(Active NewState) : SubscriptionEvent;
public sealed record Renewed(Active NewState)   : SubscriptionEvent;
public sealed record Cancelled(Ended NewState)  : SubscriptionEvent;
public sealed record NoChange(SubscriptionState State)
    : SubscriptionEvent;

public static SubscriptionEvent Transition(
    SubscriptionState state, SubscriptionCommand command,
    DateOnly today) =>
    (state, command) switch
    {
        (Trial, Activate) =>
            new Activated(new Active(today.AddMonths(1))),
        (Active, Renew) =>
            new Renewed(new Active(today.AddMonths(1))),
        (Trial or Active, Cancel) =>
            new Cancelled(new Ended()),
        (_, Activate or Renew or Cancel) =>
            new NoChange(state),
        _ => throw new UnreachableException()
    };
```

</td>
<td>

```java
public sealed interface SubscriptionState
    permits Trial, Active, Ended {}
public record Trial(LocalDate startedOn, LocalDate expiresOn)
    implements SubscriptionState {}
public record Active(LocalDate renewsOn) implements SubscriptionState {}
public record Ended() implements SubscriptionState {}

public sealed interface SubscriptionCommand
    permits Activate, Renew, Cancel {}
public record Activate() implements SubscriptionCommand {}
public record Renew()    implements SubscriptionCommand {}
public record Cancel()   implements SubscriptionCommand {}

public sealed interface SubscriptionEvent
    permits Activated, Renewed, Cancelled, NoChange {}
public record Activated(Active newState) implements SubscriptionEvent {}
public record Renewed(Active newState)   implements SubscriptionEvent {}
public record Cancelled(Ended newState)  implements SubscriptionEvent {}
public record NoChange(SubscriptionState state)
    implements SubscriptionEvent {}

public static SubscriptionEvent transition(
        SubscriptionState state, SubscriptionCommand command,
        LocalDate today) {
    return switch (state) {
        case Trial t -> switch (command) {
            case Activate a -> new Activated(new Active(today.plusMonths(1)));
            case Renew r    -> new NoChange(state);
            case Cancel c   -> new Cancelled(new Ended());
        };
        case Active a -> switch (command) {
            case Activate x -> new NoChange(state);
            case Renew r    -> new Renewed(new Active(today.plusMonths(1)));
            case Cancel c   -> new Cancelled(new Ended());
        };
        case Ended e -> new NoChange(state);
    };
}
```

</td>
</tr>
</table>

`Transition` is the whole state machine. `today` is a parameter, not a clock read, so the function stays pure ([Axiom 5](axiom-05-pure-functions.md)). C# matches on the pair with tuple patterns; Java, which has no tuple patterns, switches on the state and then on the command. Both are total: a double-clicked Cancel or a resent message gets `NoChange(state)` instead of an error, so idempotency is built into the shape.

The shell:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public HttpResponse HandleCommand(
    SubscriptionId id, SubscriptionCommand command)
{
    var state = subscriptions.Load(id);                    // gather
    var today = DateOnly.FromDateTime(
        clock.GetUtcNow().UtcDateTime);                    // gather

    var ev = Transition(state, command, today);            // decide

    return ev switch                                       // act
    {
        Activated a => SaveAndRespond(id, a.NewState,
            $"activated; renews {a.NewState.RenewsOn}"),
        Renewed r   => SaveAndRespond(id, r.NewState,
            $"renewed; next renewal {r.NewState.RenewsOn}"),
        Cancelled c => SaveAndRespond(id, c.NewState, "cancelled"),
        NoChange    => new HttpResponse(200, "no change"),
        _ => throw new UnreachableException()
    };
}

private HttpResponse SaveAndRespond(
    SubscriptionId id, SubscriptionState newState, string message)
{
    subscriptions.Save(id, newState);
    return new HttpResponse(200, message);
}
```

</td>
<td>

```java
public HttpResponse handleCommand(
        SubscriptionId id, SubscriptionCommand command) {
    var state = subscriptions.load(id);                    // gather
    var today = LocalDate.now(clock);                      // gather

    var ev = transition(state, command, today);            // decide

    return switch (ev) {                                   // act
        case Activated a -> saveAndRespond(id, a.newState(),
            "activated; renews " + a.newState().renewsOn());
        case Renewed r   -> saveAndRespond(id, r.newState(),
            "renewed; next renewal " + r.newState().renewsOn());
        case Cancelled c -> saveAndRespond(id, c.newState(), "cancelled");
        case NoChange n  -> new HttpResponse(200, "no change");
    };
}

private HttpResponse saveAndRespond(
        SubscriptionId id, SubscriptionState newState, String message) {
    subscriptions.save(id, newState);
    return new HttpResponse(200, message);
}
```

</td>
</tr>
</table>

Everything [Axiom 16's synthesis](axiom-16-result.md#the-first-synthesis) showed still holds, and the shell is [Axiom 23](axiom-23-pure-functions-returning-actions.md)'s, one branch per event. What is new is that the entity's state is now a value in the pure core, passed in and handed back, instead of a field inside an object.

**`NoChange` is reported, not judged.** The shell above answers it with `200 OK`, the convention when a repeated command should quietly succeed. Another domain might answer `409 Conflict`, because a command that doesn't apply means a bug or a race the caller should hear about. A third might decide per state: `NoChange` holding an `Ended` after `Cancel` is harmless, but after `Renew` it is a conflict. All three are valid. The machine's job is to say honestly whether anything changed; turning that into a status code is a policy for the shell.

---

## Problem / forces

When an entity changes condition over time and answers commands differently in each condition, six shapes are common:

1. **A mutable object whose methods change it.** `subscription.Cancel()` flips a `status` field. The legal transitions are an unwritten rule spread across methods, and the same call means different things from different starting states, with nothing in the signature to say so ([Axiom 5](axiom-05-pure-functions.md)).
2. **The same, with `if` checks on the status.** `if (status == Active) status = Cancelled;`. The rules are visible inside each method, but still only checked at runtime.
3. **A status enum and methods that throw.** Illegal transitions throw `InvalidOperationException`, the cost [Axiom 16](axiom-16-result.md#problem--forces) ruled out: the caller is pushed into `try`/`catch`, and nothing checks that every case was handled.
4. **The [State pattern](https://en.wikipedia.org/wiki/State_pattern).** One class per state, one method per command; a transition is `state = state.Cancel()` [3]. A good fit when each command's behavior genuinely belongs with the state it starts from. The rules are spread across the state classes, and a new command means editing every one of them.
5. **A state-machine library** (Stateless in .NET, Spring Statemachine, Akka FSM, Erlang's `gen_statem`). The states and transitions are declared as a graph that a runtime drives. A good fit when you need what the runtime provides, such as persistence or retries. The rules sit in one place, but in configuration rather than in the types, and testing involves the runtime.
6. **One pure `Transition` function.** The legal transitions are in one `switch`, the event types enforce which state each produces, and the function is tested as a table. The runtime is whatever shell wraps it.

Options 1 to 3 keep state inside an object and change it through methods, so the compiler can't help. Options 4 to 6 all separate *describing* the machine from *running* it. Between 4 and 6, the choice is the one [Axiom 21](axiom-21-discriminated-unions.md#trade-offs) describes: behavior on each case, or one `switch` in a consumer. Between 5 and 6, the question is whether what the library's runtime gives you is worth the dependency. This book defaults to the single function, because the rules become values the type system can check.

---

## Why

**1. Every rule is in one place.**
To learn what an entity is allowed to do, read `Transition`: one `switch`, one branch per legal pair plus the no-ops, each with its next state. There is no second file, no subclass and no configuration to check.

**2. Every trigger uses the same rules.**
An entity is usually reachable in several ways: an HTTP endpoint, a queue consumer, a scheduled job, a webhook. Without a state machine, each grows its own copy of the rules: the endpoint checks "is it still in trial?" with an `if`, the consumer re-implements the check slightly differently, the scheduled job filters states in its own query. Three copies drift apart. With `Transition`, every trigger has the same shape (load, transition, act on the event), and the rules live in one function that can be read, reasoned about and tested as a table. That is [Axiom 7](axiom-07-cohesion.md)'s one reason to change, kept in one place.

**3. It is the most common legacy refactoring.**
Many classes spread their state across fields like `_isStarted`, `_lastEventAt`, `_retryCount` and `_currentDelay`, which change together by rules buried in the methods that change them. Those fields are pieces of one state; those methods are unwritten branches of `Transition`. Turn the fields into a state DU ([Axiom 22](axiom-22-illegal-states.md)), move the rules into a pure `Transition`, and the class shrinks to a thin shell holding one value. The signal is the field list (flags, timestamps, counters and durations that change together), not the domain: the same refactoring applies to business entities and to long-running infrastructure classes.

**4. An illegal transition doesn't compile.**
Because `Activated` can only hold an `Active`, the transition table is in the types. Making an event produce a different state, or adding a state, needs the compiler's agreement. The other benefits of [Axiom 23](axiom-23-pure-functions-returning-actions.md#why) carry over: `Transition` is tested as a table, and every state and event is a value you can log, store or replay.

---

## Trade-offs

- **More types.** Each entity declares three DUs and one function. For one entity that is real overhead; for the tenth it is habit. Simple CRUD records don't earn it (see *When NOT to*).
- **State and event types change together.** A new state usually needs an event that produces it, and a new event a branch in `Transition`. The compiler points at each place, so the cost is mechanical, not subtle.
- **One command, several events, is usually a smell.** Check first whether one event should be a field of the other (`LoanApproved(rate)` rather than `LoanApproved` plus `RateLocked`), or whether the "second event" is really an effect the shell performs in response to the first. The rare cases that survive that check are beyond this chapter.
- **Strict typing fixes each event's next state.** `Activated(Active)` says *every* activation produces an `Active`. That is usually exactly right. When an event can produce different states under different conditions, fall back to `Activated(SubscriptionState)`, which moves that part of the rule from the types back into the function.
- **The function grows with the rules.** A machine with twelve states and ten commands has a long `Transition`. Split it into one pure helper per command (`TransitionOnActivate(state, today)`), and keep `Transition` as the dispatcher.

---

## When NOT to

- **CRUD with no rules.** A `Country` with a `Code` and a `Name` has no conditions and no transitions: read and write the row. A state machine is for entities whose *legal next step depends on what came before*. If it depends only on the input, it is a plain function ([Axiom 5](axiom-05-pure-functions.md)) or a one-shot action ([Axiom 23](axiom-23-pure-functions-returning-actions.md)).
- **One-rule scripts.** The same threshold as [Axiom 23](axiom-23-pure-functions-returning-actions.md#when-not-to): a job that loads one row, applies one rule and writes one row may not earn the vocabulary.
- **Workflows across several entities.** One `Transition` can't enforce "the customer must have a valid payment method", because the customer is a different machine. Coordinating several machines (sagas, process managers) is system topology, out of scope for this book. Each machine stays pure and local; the shell reads one and feeds the next.
- **A workflow engine already runs the machine.** When Temporal, Camunda or AWS Step Functions already drive the entity, with retries and persisted state, configure the engine directly: its primitives *are* a state machine, and a `Transition` on top would duplicate it. The single function is at its best when you own the runtime.

---

## References

[1] **George H. Mealy**, *A Method for Synthesizing Sequential Circuits*, Bell System Technical Journal 34(5), 1955. The Mealy machine: a finite-state machine "whose output values are determined both by its current state and the current inputs". `Transition` is that idea in types: the output is the event, and the next state rides inside it.
<https://doi.org/10.1002/j.1538-7305.1955.tb03788.x>

[2] **Jérémie Chassaing**, *Functional Event Sourcing Decider*, thinkbeforecoding.com, 17 December 2021. Defines the Decider: `decide: Command -> State -> Event list` and `evolve: State -> Event -> State`, plus an initial state and an `isTerminal` check.
<https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider>

[3] **Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides**, *Design Patterns: Elements of Reusable Object-Oriented Software*, Addison-Wesley, 1994. Also cited in [Axiom 9](axiom-09-first-class-functions.md), [Axiom 11](axiom-11-pattern-matching.md) and [Axiom 23](axiom-23-pure-functions-returning-actions.md). The State pattern: one class per state, one method per command, the alternative where the rules live with each state.

[4] **Scott Wlaschin**, *Domain Modeling Made Functional*, Pragmatic Bookshelf, 2018. Also cited in [Axiom 16](axiom-16-result.md), [Axiom 17](axiom-17-result-combinators.md), [Axiom 19](axiom-19-railway.md), [Axiom 20](axiom-20-validation.md) and [Axiom 23](axiom-23-pure-functions-returning-actions.md). Models states as F# unions and transitions as pure functions; the C# and Java here follow the same shape.
<https://pragprog.com/titles/swdddf/domain-modeling-made-functional/>

[5] **Yehonathan Sharvit**, *Data-Oriented Programming: Reduce software complexity*, Manning Publications, 2022. Also cited in [Axiom 1](axiom-01-data-is-not-behavior.md), [Axiom 2](axiom-02-immutability.md), [Axiom 21](axiom-21-discriminated-unions.md) and [Axiom 23](axiom-23-pure-functions-returning-actions.md). Manages a system's state as one immutable value, changed only by pure functions: the data-oriented form of this axiom.
<https://www.manning.com/books/data-oriented-programming>

[6] **Eric Normand**, *Grokking Simplicity*, Manning Publications, 2021. Also cited in [Axiom 4](axiom-04-impure-functions.md), [Axiom 5](axiom-05-pure-functions.md), [Axiom 12](axiom-12-impureim.md) and [Axiom 23](axiom-23-pure-functions-returning-actions.md). In its terms, `Transition` is a calculation that produces data; the shell's response to the event is the action.
<https://www.manning.com/books/grokking-simplicity>

---

← Previous: [Axiom 23 — Pure functions returning actions](axiom-23-pure-functions-returning-actions.md) · Next: [Axiom 25 — Session Context](axiom-25-session-context.md) →
