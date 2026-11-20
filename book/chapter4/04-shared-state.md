# Model 3 — Shared state

**Several timelines read and write one mutable place. This is the only rung where updates can be lost, so it is the one to keep smallest. In memory, the place is one reference to an immutable value, swapped by a pure function. In the database, it is a row whose write checks that nothing changed since the read.**

- In line-of-business code, this is the rung you are most often on without choosing it: two requests that write the same row (see *Who starts it* in the [chapter introduction](README.md#who-starts-it)).
- The fix is the same shape in both places. Read a value, decide purely, write only if the value is still the one you read, and otherwise decide again. Purity is what makes deciding again safe ([Axiom 6](../chapter2/axiom-06-pure-functions.md#why)).

---

## Definitions

- **Shared place:** a field, a static or a row that more than one timeline can write.
- **Lost update:** two timelines read the same value, each decides from it, and each writes. In Kleppmann's words, "one of the modifications can be lost, because the second write does not include the first modification" [5]. It is the race of [Axiom 2](../chapter2/axiom-02-data-is-not-behavior.md#tell-dont-ask-the-road-not-taken)'s "gap between the read and the write".
- **[Compare-and-swap](https://en.wikipedia.org/wiki/Compare-and-swap):** write a new value only if the place still holds the value you read; otherwise report that it changed. Run in a loop, it never loses an update: on a change, read again and recompute.
- **[Optimistic concurrency](https://en.wikipedia.org/wiki/Optimistic_concurrency_control):** compare-and-swap for rows. Each row carries a version. The write succeeds only if the version is still the one read, and moves it on.
- **Conflict:** the answer when the place changed between the read and the write. It is an expected outcome, not a bug, so it is returned as a value ([Axiom 17](../chapter2/axiom-17-result.md)).
- **[Idempotent](https://en.wikipedia.org/wiki/Idempotence) transition:** applying the same event twice changes the state once. Retries and redelivered messages depend on it.

---

## What can race

Everything that touches the shared place. The ways it goes wrong:

- **Read, decide, write as three separate steps.** Read a field, compute, assign; or load a row, change it, save it without a version check. This is the lost update, and Kleppmann warns that "ORM frameworks make it easy to accidentally write code that performs unsafe read-modify-write cycles" [5].
- **An update function with an effect.** A compare-and-swap loop may run the function more than once. If it logs, sends or writes, that happens more than once too.
- **State split across two places.** Two references, or two rows, can't be swapped together with one compare-and-swap. A rule that spans both can be broken by two timelines that each change one of them. In memory, put both in one value. In the database, this is the hard case (see *When to step up, and when NOT to*).
- **A check that isn't the write.** "No tracker exists, so insert one" run by two timelines inserts two. Kleppmann calls the cause a *phantom*: a write in one transaction changes the result of a search in another [5]. The check must be the write itself: for a rule like this one, "a uniqueness constraint is a simple solution" [5].

---

## Example

### In memory: one reference, pure updates

The tracking plans are loaded once and changed by an admin endpoint, while every event handler reads them. All the plans live in one immutable value, `PlanSet`, held by one reference:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed class PlanCatalog               // shell
{
    private PlanSet current = PlanSet.Empty;

    public PlanSet ReadPlans() =>
        Volatile.Read(ref current);

    public void ApplyChange(PlanChange change) =>
        ImmutableInterlocked.Update(
            ref current,
            plans => Plans.ApplyChange(plans, change)); // pure
}
```

</td>
<td>

```java
public final class PlanCatalog {              // shell
    private final AtomicReference<PlanSet> current =
        new AtomicReference<>(PlanSet.EMPTY);

    public PlanSet readPlans() {
        return current.get();
    }

    public void applyChange(PlanChange change) {
        current.updateAndGet(
            plans -> Plans.applyChange(plans, change)); // pure
    }
}
```

</td>
</tr>
</table>

Both runtimes say the same thing about the update function. Java's documentation: "The function should be side-effect-free, since it may be re-applied when attempted updates fail due to contention among threads" [1]. .NET's: "This function should be side-effect free, as it may run multiple times when races occur with other threads" [2]. A pure function from [Chapter 2](../chapter2/README.md) is exactly what they ask for: `ApplyChange` can run twice and nothing shows.

A reader gets a `PlanSet` that can't change under it. A handler that reads the plans once at the start of its sandwich works with one consistent set, even if an admin changes them halfway through.

This is Hickey's model of identity. `current` is the identity, "a stable logical entity associated with a series of different values over time" (emphasis removed), and each `PlanSet` is one of those values: "a value is something that doesn’t change" [4].

### In the database: version-checked writes

A box tracker row carries a version. Every write checks it:

```sql
UPDATE box_tracker
SET    stage = @stage, version = version + 1
WHERE  id = @id
AND    version = @readVersion;   -- 0 rows: another timeline wrote first
```

Kleppmann calls this a conditional write: "you could also use a version number column that you increment on every update and apply the update only if the current version number hasn’t changed. This approach is sometimes called optimistic locking" [5]. He also warns that such a write "may or may not be safe, depending on the database implementation" [5]: under [multiversion concurrency control](https://en.wikipedia.org/wiki/Multiversion_concurrency_control), the `WHERE` clause must see the other transaction's committed write, which many implementations allow as an exception to their visibility rules. Check that your database does.

The shell turns "0 rows" into a `Conflict` value. On a conflict it runs the **whole sandwich again**: a fresh gather reads the new row and version, the pure `Decide` runs on it, and the act tries once more, up to a small limit. That retry is only safe because the decision is pure and the act is the only effect: nothing was done the first time that must be undone.

Two companions close the other gaps:

- **A unique constraint** on `(plan_id, box_id)`. Two timelines that both find no tracker and both insert: the database refuses the second, and that is a `Conflict` too.
- **An idempotent `Decide`.** The tracker records the last event it applied. The same event again gives `NoChange` ([Axiom 25](../chapter2/axiom-25-state-machines.md)), so a retry or a redelivered message changes nothing twice.

The version check is one of the four ways Kleppmann lists [5]:

- **An atomic write**, when the change fits in one statement (`SET count = count + 1`). He calls these "usually the best choice" where they can be used. A decision made by a pure function in application code rarely fits.
- **An explicit lock**: read the row with `SELECT … FOR UPDATE`, so the second timeline waits instead of retrying.
- **Automatic detection**: some isolation levels detect the lost update themselves and abort one transaction, which the application then retries. The retry is the same whole-sandwich retry as above.
- **A conditional write**: the version check shown here.

Between the version check and the explicit lock, the choice is contextual: retries cost little when conflicts are rare, waits cost little when they're common and the lock is short. A pure `Decide` keeps the lock short either way. How EF and jOOQ express both is for the persistence Play in [Chapter 5](../chapter5/README.md), and the choice is an ADR.

---

## Testing

Built on [Chapter 3](../chapter3/README.md#what-i-do-today):

- **The update function and `Decide` get function tests**, including `NoChange` for an event already applied.
- **The conflict gets a component test.** Two writes to the same tracker through the component's API must end in the same state as running them one after the other, with no tracker created twice.
- **Make the conflict deterministic where you can.** Two requests sent "at the same time" collide only sometimes. When the component's API carries the version (an HTTP `ETag` checked through `If-Match`, or a version field in a command), a test can send two writes with the same version and know that exactly one must be refused.

---

## When to step up, and when NOT to

There is no rung above this one, and it is the hardest to reason about [3]. The question is how to stay off it:

- **Merge the timelines.** Several units that write related rows, inside one event, can often be one sandwich with one transaction ([Model 0](01-sequential.md)).
- **Give the state one owner.** In-memory state that many timelines update is often simpler with one owner and a mailbox ([Model 2](03-one-owner.md)).
- **Reach for a lock last.** A lock in application code is the right tool when the change can't be one pure function of the old value. It protects nothing across two instances of the service, and it brings back what this chapter's other rungs avoid: ordering between locks, and waits that depend on timing.

Where this model reaches its limits:

- **Rules that span several rows.** A version on one row can't protect a rule over many: two timelines can each read the same rows, each change a different one, and together break the rule. Kleppmann calls this *write skew*, and notes that "Automatically preventing write skew requires true serializable isolation" [5]. Serializable isolation, or a lock on a row that represents the whole group, can protect it. Until the aggregate Play exists, this book has no worked answer ([Chapter 6](../chapter6/README.md#when-to-use-hex-ddd-instead) lists it).
- **The write and the message.** Saving a row and publishing an event are two effects; a crash between them loses one. The usual answer, the outbox, is system topology and out of scope for this book.

---

## References

[1] **Oracle**, `AtomicReference.updateAndGet`, Java SE 25 API documentation.
<https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/atomic/AtomicReference.html>

[2] **Microsoft**, `ImmutableInterlocked.Update`, .NET API documentation. The transformer parameter.
<https://learn.microsoft.com/en-us/dotnet/api/system.collections.immutable.immutableinterlocked.update>

[3] **Peter Van Roy**, *Programming Paradigms for Dummies: What Every Programmer Should Know*, 2009. Also cited in the [chapter introduction](README.md#references). Named state together with concurrency is what lets a program express observable nondeterminism; message passing, not shared state, should be the default.
<https://webperso.info.ucl.ac.be/~pvr/VanRoyChapter.pdf>

[4] **Rich Hickey**, *Values and Change: Clojure's approach to Identity and State*, clojure.org. The written form of his keynote *Are We There Yet?*, JVM Languages Summit, 2009: an identity is a series of values over time, and each state is an immutable value.
<https://clojure.org/about/state> · <https://www.infoq.com/presentations/Are-We-There-Yet-Rich-Hickey/>

[5] **Martin Kleppmann**, *Designing Data-Intensive Applications*, 2nd edition, O'Reilly, chapter 8, *Transactions*: the sections *Preventing Lost Updates* and *Write Skew and Phantoms*. Four ways to prevent a lost update (atomic writes, explicit locks, automatic detection, conditional writes), and the races a single-row check can't catch.
<https://dataintensive.net/>

---

← Previous: [Model 2 — One owner](03-one-owner.md) · Next: [Chapter 5 — Plays](../chapter5/README.md) →
