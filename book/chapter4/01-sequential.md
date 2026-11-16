# Model 0 — Sequential

**One timeline per unit of work. Its steps run one after the other, so nothing inside it can race. This is the default, and the rung to come back to before climbing.**

- Most handlers belong here: gather, decide, act ([Axiom 13](../chapter2/axiom-13-impureim.md)), each step finished before the next starts.
- A loop over many items is still sequential. Move the loop into the pure core and the shell does each kind of I/O once: **gather once, decide for all, act once**.

---

## Definitions

- **Unit of work:** what one call of a handler does, from the first read to the last write. In [Axiom 13](../chapter2/axiom-13-impureim.md)'s terms, one sandwich [1].
- **Sequential:** each step of the unit starts after the previous one has finished. The order of effects is the order of the lines.
- **Gather once, decide for all, act once:** when a unit has many items to handle (several plans for one event, several lines for one order), the shell reads all their data in one gather, calls one pure function that decides for every item, and writes every outcome in one act. The loop over the items lives in the pure core, where it costs nothing.

---

## What can race

Nothing inside the unit: there is one timeline, and a value it reads can't change under it.

Two things are still open:

- **Other units.** Two units that run at the same time and touch the same row are at [Model 3](04-shared-state.md), even if each one is sequential (see *Who starts it* in the [chapter introduction](README.md#who-starts-it)).
- **The host's guarantee.** A service that handles one event at a time is sequential across events too. That guarantee comes from the deployment. Write it down next to the handler, because a second instance takes it away.

---

## Example

A service tracks boxes. A **tracking plan** is a set of settings that says how to follow a box. For each plan that follows a box, a **box tracker** row in the database records where that box is in the plan's journey. When an event about a box arrives, each plan triggered by it may start, advance or stop its tracker, and may publish an event.

A common first version handles each plan on its own thread: each thread loads its tracker, decides, saves and publishes. That is [Model 1](02-deterministic-concurrency.md)'s third shape, with all its rules to follow. The same work fits in one sequential sandwich:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public async Task HandleAsync(
    BoxEvent boxEvent, CancellationToken ct)
{
    var plans = await planStore
        .GetAllAsync(ct);                     // gather
    var triggered = BoxTracking
        .SelectTriggeredPlans(plans, boxEvent); // pure
    var trackers = await trackerStore
        .GetForBoxAsync(
            boxEvent.BoxId, triggered, ct);   // gather
    var decisions = BoxTracking
        .DecideAll(triggered, trackers, boxEvent); // pure
    await trackerStore
        .ApplyAsync(decisions, ct);           // act
    await publisher.PublishAsync(
        BoxTracking.CollectEvents(decisions), ct); // act
}
```

</td>
<td>

```java
public void handle(BoxEvent boxEvent) {
    var plans = planStore.getAll();           // gather
    var triggered = BoxTracking
        .selectTriggeredPlans(plans, boxEvent); // pure
    var trackers = trackerStore
        .getForBox(
            boxEvent.boxId(), triggered);     // gather
    var decisions = BoxTracking
        .decideAll(triggered, trackers, boxEvent); // pure
    trackerStore.apply(decisions);            // act
    publisher.publish(
        BoxTracking.collectEvents(decisions)); // act
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
public static class BoxTracking
{
    public static IReadOnlyList<TrackingPlan>
        SelectTriggeredPlans(
            IReadOnlyList<TrackingPlan> plans,
            BoxEvent boxEvent) =>
        plans.Where(plan => plan.IsTriggeredBy(boxEvent))
             .ToList();

    public static IReadOnlyList<TrackerDecision>
        DecideAll(
            IReadOnlyList<TrackingPlan> plans,
            IReadOnlyList<BoxTracker> trackers,
            BoxEvent boxEvent) =>
        plans.Select(plan => Decide(
                 plan,
                 FindTracker(trackers, plan.Id),
                 boxEvent))
             .ToList();

    // One plan's state machine (Axiom 25):
    // Start | Advance | Stop | NoChange
    public static TrackerDecision Decide(
        TrackingPlan plan,
        BoxTracker? tracker,
        BoxEvent boxEvent) => ...;
}
```

</td>
<td>

```java
public final class BoxTracking {
    public static List<TrackingPlan>
        selectTriggeredPlans(
            List<TrackingPlan> plans,
            BoxEvent boxEvent) {
        return plans.stream()
            .filter(plan -> plan.isTriggeredBy(boxEvent))
            .toList();
    }

    public static List<TrackerDecision>
        decideAll(
            List<TrackingPlan> plans,
            List<BoxTracker> trackers,
            BoxEvent boxEvent) {
        return plans.stream()
            .map(plan -> decide(
                plan,
                findTracker(trackers, plan.id()),
                boxEvent))
            .toList();
    }

    // One plan's state machine (Axiom 25):
    // Start | Advance | Stop | NoChange
    public static TrackerDecision decide(
        TrackingPlan plan,
        Optional<BoxTracker> tracker,
        BoxEvent boxEvent) { ... }
}
```

</td>
</tr>
</table>

What moved, and what it bought:

- **The loop over the plans moved into the core.** `DecideAll` is a pure map over `Decide`, the state machine of [Axiom 25](../chapter2/axiom-25-state-machines.md). Its decisions are actions ([Axiom 24](../chapter2/axiom-24-pure-functions-returning-actions.md)): start a tracker, advance it, stop it, or leave it.
- **No threads, so nothing to control.** No child to join, cancel or bound, and no database context shared between threads.
- **Two reads and one write instead of N of each.** The trackers for every triggered plan arrive in one query; every decision is applied in one transaction.
- **All or nothing.** If the transaction fails, no tracker changed. In the threaded version, plans 1 to 4 could save while plan 5 failed, and a redelivered event would run 1 to 4 again.

---

## Testing

Nothing new beyond [Chapter 3](../chapter3/README.md#what-i-do-today):

- `Decide` and `DecideAll` get **function tests**: a table of plans, trackers and an event, and the decisions expected.
- The handler gets **component tests**: send an event through the component's API, read the trackers back through it.

There is no interleaving to test, because there is none.

---

## When to step up, and when NOT to

Stay here by default. Climb only when you measure a cost this rung can't fix:

- **The unit waits on several independent reads** (another service, a second database), and the waits add up to latency that matters. Overlapping them is [Model 1](02-deterministic-concurrency.md), second shape.
- **A pure step is heavy on CPU** over a large input, and one core is too slow. A parallel map is [Model 1](02-deterministic-concurrency.md), first shape.
- **The units are slow, independent and can't be merged** into one gather and one act, because each needs its own call to a system owned by someone else. Running them together is [Model 1](02-deterministic-concurrency.md), third shape.

And when this rung is not enough even without a measurement:

- **One transaction is too large.** Thousands of items in one write hold locks for a long time. Split them into chunks, still sequential, before reaching for threads.
- **One item's failure must not block the others.** Return a `Result` per item from the core ([Axiom 17](../chapter2/axiom-17-result.md)) and write the ones that succeeded. That is still sequential.

---

## References

[1] **Mark Seemann**, *Impureim Sandwich*, ploeh blog, 2020. Also cited in [Axiom 13](../chapter2/axiom-13-impureim.md). The sandwich this model keeps whole: impure gather, pure decision, impure act.
<https://blog.ploeh.dk/2020/03/02/impureim-sandwich/>

---

← Previous: [Chapter 4 — Concurrency](README.md) · Next: [Model 1 — Deterministic concurrency](02-deterministic-concurrency.md) →
