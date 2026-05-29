# Axiom 21 — State machines

**A state machine in this playbook is a single pure function over immutable types: `Transition(state, command) → event` takes the entity's current state and an incoming command, and returns a sealed event DU whose successful variants carry the next state and whose `NoChange` variant carries the unchanged state when the command does not apply. The same shape as [Axiom 20](axiom-20-pure-functions-returning-actions.md), with the entity's state added to the inputs and threaded into each variant.**

- State is data — an immutable record, or a sealed DU of per-state records ([Axiom 18](axiom-18-discriminated-unions.md), [Axiom 19](axiom-19-illegal-states.md)) when the entity has variants.
- Command is data — a sealed DU naming the requests the machine can handle.
- Event is data — a sealed DU naming the outcomes; successful variants carry the *specific* next-state variant they produce (`Activated(Active)`, `Cancelled(Ended)`), so the transition table is enforced in the type system. A `NoChange` variant carries the unchanged state for the idempotent case.
- `Transition(state, command) → event` is pure and *total*: every `(state, command)` pair lands in some variant — a transition when one applies, `NoChange(state)` when it does not.
- The shell loads the state, calls `Transition`, pattern-matches the event, persists the new state from the successful variant, and decides how to respond to `NoChange` according to whether the domain treats the no-op as an idempotent success or a conflict.
- A multi-field state class — flags, timestamps, counters, durations that change together — is almost always a state machine hiding. Promoting the fields to a State DU ([Axiom 19](axiom-19-illegal-states.md)) and the rules to `Transition` is this axiom applied as a refactor: [Axiom 19](axiom-19-illegal-states.md) reshapes the data into a sum of per-state records, and this axiom adds the behaviour that moves between them.

[Axiom 20](axiom-20-pure-functions-returning-actions.md) returned an action describing what the shell should do — a pure function returning a sealed DU of variants the shell pattern-matches and executes. This axiom keeps that exact shape and adds two structural moves: the entity's state joins the inputs alongside the command, and each successful variant carries the next state. That single addition turns the one-shot decision into a continuous machine — the same function, called repeatedly with the current state in hand, drives the entity through its lifetime. This is what the chapter has been building toward: pure functions over immutable types, returning DUs; a single impure orchestrator is the only seam; stateful resources are held in the shell and fed in as values. The pattern applies as much to long-running infrastructure classes as to business entities — wherever state is spread across fields that change together, this axiom is the refactor that consolidates them.

> Most classes that have more than 1 data field (not depencies) area ctually hiding an implicit state machine behind several disconnected data points. This axiom should be use as the default way to represent state when there is more than 1 data field for state.

---

## Definitions

A state machine in this playbook rests on a small vocabulary and a single pure function.

The **vocabulary** — four words, each meaning exactly one thing:

- **State** — the entity's *condition* right now. A value, snapshot in time, immutable. A single record when the entity has one shape; a sealed DU of records when the entity has variants. The DU form is preferred when the legal commands differ by condition, because it lets the type system express *which commands are valid from which condition* by encoding each condition as its own variant.
- **Command** — a *request* to the machine. Future-tense intent: "please activate this subscription." A sealed DU; each variant is an immutable record carrying the data the command needs. Distinct from State (request vs condition) and from Event (intent vs fact). When the FSM is reacting to environmental occurrences rather than user requests — a stream of stimuli, a sequence of incoming messages — the same input slot is often named `Signal`, `Trigger`, or just `Event` instead of `Command`; the structural role in `Transition` is identical.
- **Event** — a *fact* about what happened in response to a command. Past-tense outcome: "this subscription was activated." A sealed DU; each variant is an immutable record. Successful variants carry the next state and any per-event payload. A `NoChange` variant carries the unchanged state for the idempotent case — when the command does not apply to the current state (a duplicate click, a stale request, a network re-send), the machine produces an honest no-op rather than a rejection. Whether the no-op is a problem or a normal idempotent outcome is a domain decision the shell makes when it pattern-matches `NoChange`; the FSM's job is to be honest about whether anything changed.
- **Transition** — the *act* of computing the next event from a `(state, command)` pair. A verb. The function name.

The **function**:

- **`Transition(state, command) → event`** — pure. Pattern-matches on the pair `(state, command)` ([Axiom 8](axiom-08-pattern-matching.md)) and returns the event variant naming what should happen. Each successful variant carries the specific next-state variant it produces — `Activated(Active)`, `Cancelled(Ended)` — so the transition table is enforced in the types: you cannot construct `Activated(new Trial(...))` because the variant's parameter type forbids it. The same insight as [Axiom 5](axiom-05-honest-total-signatures.md)'s "make illegal states unrepresentable" and [Axiom 15](axiom-15-value-objects.md)'s value-object constructors, lifted to the event level.

The shell — the impure orchestrator — is mechanical:

1. Load the current state for the entity.
2. Read any ambient values `Transition` needs as parameters (the clock, configuration, ID generators).
3. Call `Transition(state, command)` to produce an event.
4. Pattern-match on the event and execute the side effect each arm names — persist the new state, write a log entry, publish a downstream notification, return the HTTP response.

The shape of the shell varies — an HTTP endpoint that calls `Transition` once per request, a message handler that calls it once per message, a long-running loop that calls it once per environmental event — but the four steps are the same in all of them.

---

## Example

A subscription that moves between `Trial`, `Active`, and `Ended`. Three commands — `Activate`, `Renew`, `Cancel`. Four events — `Activated`, `Renewed`, `Cancelled`, `NoChange` — with the successful three strictly typed by the state variant they produce and `NoChange` carrying the unchanged state for the idempotent case.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public abstract record SubscriptionState;
public sealed record Trial(DateOnly StartedOn, DateOnly ExpiresOn) : SubscriptionState;
public sealed record Active(DateOnly RenewsOn)                     : SubscriptionState;
public sealed record Ended                                         : SubscriptionState;

public abstract record SubscriptionCommand;
public sealed record Activate : SubscriptionCommand;
public sealed record Renew    : SubscriptionCommand;
public sealed record Cancel   : SubscriptionCommand;

public abstract record SubscriptionEvent;
public sealed record Activated(Active NewState)        : SubscriptionEvent;
public sealed record Renewed(Active NewState)          : SubscriptionEvent;
public sealed record Cancelled(Ended NewState)         : SubscriptionEvent;
public sealed record NoChange(SubscriptionState State) : SubscriptionEvent;

public static SubscriptionEvent Transition(
    SubscriptionState state,
    SubscriptionCommand cmd,
    DateOnly today) => (state, cmd) switch
{
    (Trial,           Activate) => new Activated(new Active(today.AddMonths(1))),
    (_,               Activate) => new NoChange(state),
    (Active,          Renew)    => new Renewed(new Active(today.AddMonths(1))),
    (_,               Renew)    => new NoChange(state),
    (Trial or Active, Cancel)   => new Cancelled(new Ended()),
    (Ended,           Cancel)   => new NoChange(state)
};
```

</td>
<td>

```java
public sealed interface SubscriptionState
    permits Trial, Active, Ended {}
public record Trial(LocalDate startedOn, LocalDate expiresOn) implements SubscriptionState {}
public record Active(LocalDate renewsOn)                      implements SubscriptionState {}
public record Ended()                                          implements SubscriptionState {}

public sealed interface SubscriptionCommand
    permits Activate, Renew, Cancel {}
public record Activate() implements SubscriptionCommand {}
public record Renew()    implements SubscriptionCommand {}
public record Cancel()   implements SubscriptionCommand {}

public sealed interface SubscriptionEvent
    permits Activated, Renewed, Cancelled, NoChange {}
public record Activated(Active newState)        implements SubscriptionEvent {}
public record Renewed(Active newState)          implements SubscriptionEvent {}
public record Cancelled(Ended newState)         implements SubscriptionEvent {}
public record NoChange(SubscriptionState state) implements SubscriptionEvent {}

public static SubscriptionEvent transition(
    SubscriptionState state,
    SubscriptionCommand cmd,
    LocalDate today) {
    return switch (state) {
        case Trial t -> switch (cmd) {
            case Activate a -> new Activated(new Active(today.plusMonths(1)));
            case Renew r    -> new NoChange(state);
            case Cancel c   -> new Cancelled(new Ended());
        };
        case Active a -> switch (cmd) {
            case Activate a2 -> new NoChange(state);
            case Renew r     -> new Renewed(new Active(today.plusMonths(1)));
            case Cancel c    -> new Cancelled(new Ended());
        };
        case Ended e -> switch (cmd) {
            case Activate a -> new NoChange(state);
            case Renew r    -> new NoChange(state);
            case Cancel c   -> new NoChange(state);
        };
    };
}
```

</td>
</tr>
</table>

`Transition` is the entire state machine — a single pure function whose body pattern-matches on the `(state, command)` pair and produces the event that says what happened. `today` is a parameter, not a field — the clock lives at the boundary ([Axiom 9](axiom-09-impureheim.md)) and is fed in as a value. The C# version uses tuple patterns to express the two-axis case analysis in one switch; the Java version nests one switch inside another, the outer on state and the inner on command — same logic, a few more lines because Java does not yet have native tuple patterns. Both surfaces are *total*: every `(state, command)` pair lands in one variant. When the pair has a legal transition the matching successful variant carries the new state; when it does not — the user clicks Cancel twice, a stale request arrives, a re-sent network packet — `Transition` returns `NoChange(state)` carrying the unchanged state. Idempotency is built into the function's shape.

The strict typing on successful variants — `Activated(Active)`, `Cancelled(Ended)` — is where the transition table moves from a runtime convention into a type-level guarantee. You cannot write `new Activated(new Trial(...))`; the variant's parameter type refuses it. Adding a new state, or wiring an existing state to a different event, requires the compiler's blessing.

---

## The synthesis

The full sandwich [Axiom 9](axiom-09-impureheim.md) sketched: the impure shell loads state and reads the clock, the pure core computes the event, the impure shell persists the new state and dispatches. A single `Handle` shell does this for every command — the rules and the next state are both inside `Transition`, the storage is in the shell, and the type system holds the seam.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed record HttpResponse(int Status, string Body);

public HttpResponse Handle(SubscriptionId id, SubscriptionCommand cmd)
{
    SubscriptionState state = subscriptions.Load(id);              // impure: DB read
    DateOnly          today = clock.TodayUtc();                    // impure: clock read

    SubscriptionEvent ev    = Transition(state, cmd, today);       // pure

    return ev switch                                                // impure: dispatch
    {
        Activated a => Persist(id, a),
        Renewed   r => Persist(id, r),
        Cancelled c => Persist(id, c),
        NoChange  n => new HttpResponse(200, "no change")
    };
}

private HttpResponse Persist(SubscriptionId id, Activated ev)
{
    subscriptions.Save(id, ev.NewState);
    return new HttpResponse(200, $"activated; renews {ev.NewState.RenewsOn}");
}

private HttpResponse Persist(SubscriptionId id, Renewed ev)
{
    subscriptions.Save(id, ev.NewState);
    return new HttpResponse(200, $"renewed; next renewal {ev.NewState.RenewsOn}");
}

private HttpResponse Persist(SubscriptionId id, Cancelled ev)
{
    subscriptions.Save(id, ev.NewState);
    return new HttpResponse(200, "cancelled");
}
```

</td>
<td>

```java
public record HttpResponse(int status, String body) {}

public HttpResponse handle(SubscriptionId id, SubscriptionCommand cmd) {
    SubscriptionState state = subscriptions.load(id);              // impure: DB read
    LocalDate         today = clock.todayUtc();                    // impure: clock read

    SubscriptionEvent ev    = transition(state, cmd, today);       // pure

    return switch (ev) {                                            // impure: dispatch
        case Activated a -> persist(id, a);
        case Renewed   r -> persist(id, r);
        case Cancelled c -> persist(id, c);
        case NoChange  n -> new HttpResponse(200, "no change");
    };
}

private HttpResponse persist(SubscriptionId id, Activated ev) {
    subscriptions.save(id, ev.newState());
    return new HttpResponse(200, "activated; renews " + ev.newState().renewsOn());
}

private HttpResponse persist(SubscriptionId id, Renewed ev) {
    subscriptions.save(id, ev.newState());
    return new HttpResponse(200, "renewed; next renewal " + ev.newState().renewsOn());
}

private HttpResponse persist(SubscriptionId id, Cancelled ev) {
    subscriptions.save(id, ev.newState());
    return new HttpResponse(200, "cancelled");
}
```

</td>
</tr>
</table>

The `NoChange` arm above returns `200 OK` — the convention when the domain treats the no-op as an idempotent retry that should succeed silently (the user clicked Cancel twice, a stale request arrived, the network re-sent the same packet). Some domains want the opposite — `409 Conflict` when the command arrived against a state where it doesn't apply (a UI bug, a race condition the API should surface, a misuse the caller needs to learn about). Some want a hybrid: pattern-match the state inside `NoChange` further — `NoChange(Ended)` after `Cancel` is harmless (200), `NoChange(Trial)` after `Renew` is a conflict (409). All three are valid stances. The shell decides; the FSM's job is to be honest about whether anything changed; mapping "nothing changed" to a status code is policy that lives at the boundary, not in the pure core.

Read the picture top to bottom and every prior axiom is visible at its post:

- **Data, immutable, separate from behaviour** ([Axiom 0](axiom-00-data-vs-behaviour.md), [Axiom 1](axiom-01-immutability.md)). `SubscriptionState`, `SubscriptionCommand`, `SubscriptionEvent` and every variant are immutable records. The subscription does not own `Cancel`; the function `Transition` operates on the subscription.
- **Effects are named and contained** ([Axiom 2](axiom-02-side-effects.md), [Axiom 3](axiom-03-impure-functions.md)). The `subscriptions.Load`, `clock.TodayUtc`, `subscriptions.Save` calls are the only effects in the listing — read at the top, write at the bottom. The middle is structurally pure.
- **The decision is pure** ([Axiom 4](axiom-04-pure-functions.md)). `Transition(state, cmd, today)` has no effects, no hidden inputs, no `throw`. The same `(state, command, today)` always produces the same event. Tests are tables.
- **The signature is honest and total** ([Axiom 5](axiom-05-honest-total-signatures.md)). `Transition` returns one of four named outcomes; the successful variants are typed by their *specific* next state — `Activated(Active)`, not `Activated(SubscriptionState)` — so the transition table moves into the type system. There is no `null`, no exception, no out-parameter; the no-op case is *part of the return type*, surfaced as `NoChange` for the shell to interpret.
- **Functions are values; functions over functions are the glue** ([Axiom 6](axiom-06-first-class-functions.md), [Axiom 7](axiom-07-higher-order-functions.md)). `Transition` is a first-class value — it can be passed to a generic shell, registered in a router, or invoked from a test harness with a table of `(state, command)` pairs.
- **Pattern matching consumes both axes** ([Axiom 8](axiom-08-pattern-matching.md)). `Transition` matches on `(state, command)` — two axes at once. The shell matches on the event for dispatch. Two matches, both exhaustive; add a variant on any axis and the compiler points at every site that has to handle it.
- **The whole function is the Impureheim sandwich** ([Axiom 9](axiom-09-impureheim.md)). Load → transition → execute. The pure middle is what changes between business decisions; the impure top and bottom stay the same. Across the whole chapter this was the goal — Axiom 9 sketched it, Axioms 13, 16, 17, 19 each delivered a piece, and Axiom 21 closes the loop because state itself has now joined the pure middle as a value.
- **Absence and 2-case outcomes have their named container types** ([Axiom 10](axiom-10-maybe.md), [Axiom 11](axiom-11-either.md), [Axiom 13](axiom-13-result.md)). `subscriptions.Load(id)` returning a `SubscriptionState` assumes the entity exists; in a real codebase the shell would handle the missing case with a `Maybe`/`Optional` before calling `Transition`. The event DU `Activated | Renewed | Cancelled | NoChange` is the same sum-type machinery as `Result<T, E>` generalised to N variants — though none of these is a "failure" in `Result`'s sense; `NoChange` is an honest no-op surfaced as a named outcome rather than a thrown exception or a tombstone.
- **Unit is the shape when nothing meaningful is returned** ([Axiom 12](axiom-12-unit.md)). Here the shell produces an `HttpResponse`; a fire-and-forget message handler would call `Handle` and discard the response, returning `Unit`.
- **Combinators glue Result-shaped pipelines** ([Axiom 14](axiom-14-result-combinators.md), [Axiom 16](axiom-16-railway.md)). A railway returned a `Result<T, string>` and the shell did a 2-arm match. This axiom returns a `SubscriptionEvent` and the shell does a 4-arm dispatch. Structurally the same shape — pure core returns a sum type; impure shell dispatches each arm — generalised to N events.
- **Each fallible step is still a smart constructor when one applies** ([Axiom 15](axiom-15-value-objects.md)). `SubscriptionId` is a value object with a `From` factory; here it arrives as a typed value, already constructed. Each event's *specific*-state-variant typing — `Activated(Active)` — is the same "make illegal states unrepresentable" principle, lifted from one value to the relationship between two.
- **Validation accumulates many failures when many fields are validated** ([Axiom 17](axiom-17-validation.md)). When a command's payload carries multiple independent fields, the shell would run the accumulating combinator on the raw input first and only call `Transition` with an already-validated command record. Validation feeds the state machine; the state machine is downstream of it.
- **The state, command, and event types are all instances of the same shape** ([Axiom 18](axiom-18-discriminated-unions.md)). Each is a sealed hierarchy of named variants with one record per outcome. Same machinery, three different intents: shape of the entity, shape of the request, shape of the outcome.
- **The state machine is Axiom 20 with state added** ([Axiom 20](axiom-20-pure-functions-returning-actions.md)). `Transition` is exactly the pure-function-returning-an-action of Axiom 20, with the entity's state joining the inputs and threaded into each successful event variant. The Axiom 20 cart was a one-shot decision; the same shape called repeatedly with the current state in hand is a state machine.

The payoff: the file reads as the rule it enforces. *`Transition` decides what happens and what state we're now in; the shell dispatches and persists.* When the rules change, you edit `Transition` and possibly `SubscriptionEvent` or `SubscriptionState`. When storage changes, you edit the shell. Two reasons to change, two places to edit, and the type system holds every seam.

---

## Problem / forces

When a program needs an entity that changes condition over time and answers commands differently in each condition, six shapes recur:

1. **Mutable object with self-mutating methods.** The OO default. `subscription.Cancel()` flips an internal `status` field. Pays the cost [Axiom 4](axiom-04-pure-functions.md) named: the function is impure (it mutates), the legal transitions are an unwritten rule scattered across methods, and two calls to the same method from different starting states produce different outcomes with no signal in the signature.
2. **Mutable object guarded by `if`-ladders on the current status.** `if (this.status == Active) { this.status = Cancelled; }`. The legal transitions are now visible inside the method body, but they remain a runtime convention rather than a type-level property. Testing still needs to construct the object in each status by hand.
3. **A status enum + methods that throw on illegal transitions.** Same as 2 but signals illegal transitions through `throw new InvalidOperationException(...)`. Pays the cost [Axiom 13](axiom-13-result.md) named: business rules thrown as exceptions force the caller into try/catch and remove the type-level enforcement that the caller has handled every case.
4. **The GoF State pattern — one class per state with virtual methods per command.** Each state is a class implementing a common `IState` interface; commands are virtual methods; a transition is `currentState = currentState.Cancel()`. A long-standing option appropriate when the implementation of each command belongs *with* the state it acts from — the rule for "what does `Cancel` mean from `Trial`?" lives on the `Trial` class. Trade-off: behaviour is distributed across N state classes (the same trade-off [Axiom 8](axiom-08-pattern-matching.md) and [Axiom 18](axiom-18-discriminated-unions.md) drew between operations-on-the-type and operations-on-the-consumer), and adding a new command means editing every state class instead of one place.
5. **A configured state-machine library (Stateless, Spring StateMachine, Akka FSM, `gen_statem`).** A declarative graph of states and transitions registered with a runtime that drives the machine on command arrival. A long-standing option appropriate when transitions need persistence, retries, supervisors, and other runtime concerns the library already solves — the configuration captures the legal transitions in one place, even if not in the type system. Trade-off: the rules live next to the type system, not inside it; the runtime is now a dependency; testing involves standing up the runtime.
6. **The single pure `Transition` function.** `Transition(state, command) → event`, with event variants strictly typed by the state they produce. The legal transitions are spelled out in `Transition`'s pattern match; the type system enforces the state-to-event correspondence; the function is tested as a table. The runtime is whatever the shell wraps it in.

Options 1–3 share one cost: state lives inside an object and changes through method calls. The compiler cannot help — the legal transitions are an unwritten rule, and the only way to find them is to read the methods. The single-`Transition` shape keeps everything in types: state, command, and event are DUs; the function is a total function over them; the shell wires it.

Options 4–6 are all honest separations of *describing* the machine from *running* it. The State pattern distributes the rules across the state classes; configured libraries put the rules in declarative configuration; the `Transition` function centralises them in one pure function. The choice between 4 and 6 is the same one [Axiom 18](axiom-18-discriminated-unions.md) drew between operations-on-the-type and operations-on-the-consumer; between 5 and 6, the trade-off is whether the runtime concerns the library solves outweigh the dependency it introduces. `Transition` is the playbook's default because the rules become *values* the type system can check and the shell stays mechanical.

---

## Why

What the single-`Transition` shape gets right that mutable objects and exception-based status checks do not:

**1. Every transition is in one place — `Transition` is the law book.**
A reviewer who wants to know *what this entity is allowed to do* opens `Transition`. The body is a single pattern match whose arms enumerate every legal `(state, command)` pair plus every no-op pair and the next state. There is no second file to check, no derived class to find, no configuration to consult.

**2. The same rules drive every trigger.**
Entities usually have multiple ways into them — an HTTP endpoint, a queue consumer, a scheduled job, a webhook, a CLI command. Without a state machine, each trigger grows its own copy of the rules: the HTTP handler checks "is the subscription still in Trial?" with an inline `if`, the queue consumer reimplements the same check a slightly different way because the message arrived from a different system, the cron job filters states with its own `where` clause. Three triggers, three near-copies of the same decisions, three places to update when a rule changes, three opportunities to drift apart. With `Transition`, every trigger collapses to the same shape — load state, call `Transition`, dispatch the event — and the rules live in exactly one pure function. The complexity that used to live in the triggers' `if`-ladders is gone, gathered into one place that can be reviewed, reasoned about, and tested as a table (5.).

**3. It is also the most common legacy refactor.**
Most OO codebases have at least one class whose state is spread across `_isStarted: bool`, `_lastEventAt: DateTime?`, `_retryCount: int`, `_currentDelay: TimeSpan` — fields that move together by implicit rules buried in the methods that mutate them. The fields are fragments of one `State`; the mutating methods are unwritten `Transition` arms; the legal combinations live as scattered `if`s. Promote the fields to a State DU, extract the rules into a pure `Transition`, and the class collapses into a thin shell holding the value. The diagnostic is the field list — flags, timestamps, counters, durations that change together — not the domain; the same refactor applies whether the class is a domain entity or a long-running infrastructure object.

**4. Illegal transitions cannot compile.**
With successful variants strictly typed by the state they produce — `Activated(Active)`, `Cancelled(Ended)` — the transition table is in the type system. You cannot write `new Activated(new Trial(...))`; the variant's parameter type refuses it. Adding a new state, or wiring an existing state to a different event, requires the compiler's blessing.

**5. Every state and every event is a value.**
A `SubscriptionState` instance can be logged, serialised, sent over the wire, snapshotted. An event can be appended to a log, inspected, or passed to another process. The audit trail is not a separate subsystem — it is just the events the machine already produces. None of this works on mutable objects whose state lives in private fields; all of it works on the pure-`Transition` machine for free.

**6. Testing is a table.**
`Transition` is tested by listing rows: state, command, expected event. No DB, no clock (the clock arrives as a parameter), no mock framework. The shell is tested separately with integration tests because its job is integration; the pure function never enters that suite.

**7. The shell becomes mechanical.**
A pattern match on the event variant, one arm per effect, plus a `Save` call inside each successful arm. That is the entire shell. Add a new entity and a new shell, but the new shell is the same shape as the old one. The shell stops being a place where logic hides and becomes a place where wiring lives — the inversion the sandwich from [Axiom 9](axiom-09-impureheim.md) asked for, now extended past one decision to an entity's whole lifetime.

---

## Trade-offs

**The state machine adds vocabulary.** Each business entity declares three sealed DUs (state, command, event) and one pure function (`Transition`). A handler that used to be a method on a mutable class now spreads across three type declarations and one static function. For one such entity the cost is real; for the tenth, the pattern is grooved and the cost is muscle memory. Non-trivial entities earn the trade; trivial CRUD records do not (see "When NOT to").

**The state DU and the event DU evolve together.** Adding a state usually means adding at least one event that produces it; adding an event usually means adding at least one corresponding `Transition` arm. Two files change for one feature, predictably. The compiler catches the omissions — strict variant typing forces the change to be visible — so the cost is mechanical, not subtle.

**"Compound" transitions are usually a smell, not a case to plumb for.** When a single command appears to need multiple events for the same aggregate, three things are usually true: the events are at different abstraction levels and one should be a field of the other (`LoanApproved(rate)` rather than `LoanApproved + RateLocked`); what looked compound was really cross-aggregate coordination handled at the shell, not nested inside one `Transition`; or the "second event" is a side effect the shell does in response to the first, not a separate fact the FSM decides. Before reaching for a list return or a wrapper variant, check whether the second event has any state-machine meaning of its own. The rare cases that survive that check are outside this chapter's scope.

**Cross-aggregate decisions do not fit one Transition.** A subscription state machine cannot enforce "the customer must have an active payment method" because the customer aggregate is a different state machine. Coordinating multiple state machines is an architectural concern that belongs outside this axiom (the CLAUDE.md scope note puts sagas, process managers, and outboxes outside the playbook's chapter-1 scope). Within the playbook, the answer is: each state machine stays pure and local; a process at the shell level reads one machine and feeds the next.

**The pure function grows with the rule set.** A machine with twelve states, ten commands, and twenty rules has a long `Transition`. The remedy is not to make it impure; it is to factor the decision into smaller pure helpers — `TransitionActivate(state, today)`, `TransitionRenew(state, today)` — that the top-level `Transition` delegates to one per command. The helpers compose because both inputs and outputs are values.

**Strict variant typing locks the event-to-state mapping.** With `Activated(Active)`, the type system says *every* `Activated` produces an `Active`. When this is true — and for most domain machines it is, by design — this is exactly the constraint you want. When it isn't (an event that might produce different state variants under different conditions), the loose form `Activated(SubscriptionState)` is the fallback, at the cost of moving that part of the rule back from the type system into the function body.

**`NoChange` is the tool, not the policy.** The FSM returning `NoChange(state)` does not pre-decide whether the no-op is OK. Both stances are valid and the choice belongs to the consumer: an idempotent API treats every `NoChange` as `200 OK`; a strict API surfaces it as `409 Conflict`; a hybrid pattern-matches the state inside `NoChange` and picks per case. The FSM's responsibility is to answer "did anything change?" honestly; the response policy lives in the shell. The cost is one extra variant in the event DU compared to a partial FSM that only enumerates legal transitions — paid back the first time a duplicate click, a stale request, or a re-sent network packet arrives.

---

## When NOT to

**Pure CRUD entities with no rules.** A `Country` record with `Code` and `Name` does not need a state machine — there is no condition, no transition, no rule. Read/write the row directly. The state machine is for entities whose *legal next step depends on what came before*; if the next step depends only on the input, you have a function ([Axiom 4](axiom-04-pure-functions.md)) or a one-shot action DU ([Axiom 20](axiom-20-pure-functions-returning-actions.md)), not a state machine.

**Single-rule scripts.** A 200-line cron job that loads one row, runs one rule, and writes one row may not earn the state-machine vocabulary. The split between core and shell pays off as the rule set grows; for a single-rule script the inline form is simpler and the cost is bounded. Same threshold [Axiom 20](axiom-20-pure-functions-returning-actions.md) named for action DUs.

**Workflows that span multiple aggregates.** Coordinating "the order state machine triggers the inventory state machine triggers the shipping state machine" is process orchestration — sagas, process managers, choreographed events. These are architectural patterns outside the playbook's chapter-1 scope. The state machine is the building block such patterns *consume*; the patterns themselves belong elsewhere.

**Heavy infrastructure already runs the machine.** When a workflow engine (Temporal, Camunda, Step Functions, Akka Persistence) already drives the entity with retries, supervisors, and persisted state, configuring it directly is honest — the engine's primitives are themselves a state machine. Rebuilding a `Transition` on top would duplicate the machine. The single-`Transition` shape is at its best when *you* own the runtime; when the runtime is a third party, the configured form (option 5 in Problem / forces) usually fits better.

---

## References

[1] **Scott Wlaschin**, *Domain Modeling Made Functional*, Pragmatic Bookshelf, 2018. Cross-listed from [Axiom 13](axiom-13-result.md), [Axiom 14](axiom-14-result-combinators.md), [Axiom 15](axiom-15-value-objects.md), [Axiom 16](axiom-16-railway.md), [Axiom 17](axiom-17-validation.md), and [Axiom 20](axiom-20-pure-functions-returning-actions.md). The book's state-machine chapter is the F# original of this axiom: sealed DUs for state, pure functions per transition, pattern matching driving the dispatch. The C# / Java treatment above is a transcription of the same shape into mainstream OO languages.
<https://pragprog.com/titles/swdddf/domain-modeling-made-functional/>

[2] **Yehonathan Sharvit**, *Data-Oriented Programming: Reduce software complexity*, Manning Publications, 2022. Cross-listed from [Axiom 0](axiom-00-data-vs-behaviour.md), [Axiom 1](axiom-01-immutability.md), [Axiom 10](axiom-10-maybe.md), [Axiom 11](axiom-11-either.md), [Axiom 18](axiom-18-discriminated-unions.md), and [Axiom 20](axiom-20-pure-functions-returning-actions.md). DOP's central move — represent state as a value, transitions as transformations of that value — is the data-oriented form of this axiom. Sharvit's chapters on representing system state as an immutable map and updating it through pure functions are the closest non-FP precedent.
<https://www.manning.com/books/data-oriented-programming>

[3] **Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides**, *Design Patterns: Elements of Reusable Object-Oriented Software*, Addison-Wesley, 1994 — the **State** pattern. Cross-listed from [Axiom 6](axiom-06-first-class-functions.md), [Axiom 8](axiom-08-pattern-matching.md), and [Axiom 20](axiom-20-pure-functions-returning-actions.md). The canonical OO reference for "one class per state with virtual methods per command" — the alternative on the trade-off curve where the rules are distributed across state classes instead of centralised in one pure function. Operations on the type, rather than operations on the consumer; appropriate when the implementation of each command genuinely belongs with the state it acts from.

[4] **Eric Normand**, *Grokking Simplicity*, Manning Publications, 2021. Cross-listed from [Axiom 3](axiom-03-impure-functions.md), [Axiom 4](axiom-04-pure-functions.md), and [Axiom 20](axiom-20-pure-functions-returning-actions.md). Normand's *action / calculation / data* taxonomy puts the same split in three words: `Transition` is a calculation producing data; the shell's dispatch is the action. The state machine is the calculation, not the actions it produces.
<https://www.manning.com/books/grokking-simplicity>

[5] **John Hopcroft, Rajeev Motwani, Jeffrey Ullman**, *Introduction to Automata Theory, Languages, and Computation*, Addison-Wesley, 3rd ed. 2006. The mathematical ancestor — a Mealy machine, a finite automaton with output, formalised as `(Q, Σ, Λ, δ, λ, q0)` with transition function `δ: Q × Σ → Q` and output function `λ: Q × Σ → Λ`. The `Transition` function in this axiom is exactly the combined Mealy form `δ × λ: Q × Σ → (Q × Λ)` — same mathematics, expressed in types instead of set notation, with the output `Λ` widened to a DU of named event variants and the next-state component carried inside each successful variant.
