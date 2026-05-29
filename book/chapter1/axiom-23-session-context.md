# Axiom 23 — Session Context

**A Session Context is a per-session mutable record, owned by the shell, threaded explicitly as a parameter to the functions that need it. It bundles the working memory of one session — accumulators, signals, flags, callbacks, identifiers — into one named, scoped place. This is the first axiom in the chapter that permits mutability; the discipline of scope, ownership, and explicit threading is the price the shape pays for the permission.**

- A Session Context is allocated at the shell's entry point and discarded when the session ends. It exists for one session and only for one session.
- It is *owned by the shell* — the impure orchestrator. The pure core never holds it, never reads it, never mutates it.
- It is *passed explicitly* as a parameter to every function that needs to read or accumulate into it. No ambient storage, no thread-local, no globals.
- It holds *data*: counters, lists, flags, identifiers, callbacks set up for this session — values that change as the session progresses or that the session captured at start.
- It is *not* the entity's state ([Axiom 22](axiom-22-state-machines.md)); it is *not* a dependency wired at construction; it is *not* a global. Each of those is a different thing, with its own home.

Every prior axiom has moved in one direction. Data is a value ([Axiom 0](axiom-00-data-vs-behaviour.md)), data does not change after creation ([Axiom 1](axiom-01-immutability.md)), decisions are pure ([Axiom 4](axiom-04-pure-functions.md)), the inputs and outputs of every function are immutable values ([Axioms 5](axiom-05-honest-total-signatures.md), [14](axiom-14-result.md), [19](axiom-19-discriminated-unions.md), [21](axiom-21-pure-functions-returning-actions.md), [22](axiom-22-state-machines.md)). State has existed — the FSM's state in [Axiom 22](axiom-22-state-machines.md) is the most explicit example — but it has always flowed *as an immutable value*: passed in, used to compute the next value, persisted by the shell. Twenty-two axioms of values being created, transformed, and returned. Never mutated. Stateless execution.

Most programs cannot live entirely on that diet. A batch importer needs to count rows as it goes. A multi-step orchestration needs somewhere to accumulate the errors it surfaces along the way. A session that lasts more than one call needs callbacks set up at start-time and an identifier the later steps can reference. None of this is the entity's state — the FSM is busy modelling the *thing being acted on*; this is the *shell's own* working memory while one session runs. Forcing it through "rebuild an immutable snapshot at every step" is a tax that buys nothing here: the data is not replayed, not compared between snapshots, not audited as history; it just needs to live for the session and be readable from the steps that need it.

Session Context is the named place for that data. It is mutable — deliberately. The discipline of scope is what makes the mutability safe: when the session ends the context is gone; nothing outside the session can reach into it; nothing inside the session reaches it implicitly. The pure core stays pure because the pure core never takes the Session Context as input — only the impure shell does.

This is not a new pattern. Mainstream frameworks already ship it under different names. In C#, ASP.NET Core's `HttpContext` is per-request, threaded explicitly to middleware (`InvokeAsync(HttpContext ctx, ...)`), with an `Items` dictionary for cross-handler accumulators; Entity Framework Core's `DbContext` is per-request, threaded to repositories, and accumulates pending entity changes that `SaveChanges()` flushes at session end. The Java siblings are Jakarta's `HttpServletRequest` (request-scoped attributes via `getAttribute` / `setAttribute`) and JPA's `EntityManager` (the persistence-context Unit of Work). All four are *typed* to be passed explicitly — the shape this axiom names — though each framework also offers an ambient accessor on top (`IHttpContextAccessor`, Spring's `RequestContextHolder`, JPA's `@PersistenceContext` field injection); those are the anti-pattern form the Problem/forces section below catalogues.

---

## Definitions

A **session** is one unit of work the shell drives end-to-end:

- A batch import that processes a file from open to close.
- An HTTP request handler that fans out across several sub-steps.
- An interactive run for one user, one job, one job-run.

Its start and end are bounded; the Session Context lives between those bounds and not beyond.

A **Session Context** is:

- A *mutable* record or class. In C# a `sealed class` with `{ get; set; }` properties (or a `record class` with mutable members); in Java a `final class` with non-`final` fields. Either way, the type's purpose is to *hold* and *be updated*.
- *Scoped* to one session — allocated at the shell entry, garbage-collected (or disposed) when the session ends.
- *Owned* by the shell — the only code that reads or writes the context is impure orchestrator code. Pure functions never receive it.
- *Threaded* explicitly — every shell function that needs to read or update it takes it as a parameter. Ambient storage (thread-locals, async-locals, statics) is not the shape this axiom names.

What goes inside a Session Context:

- **Accumulators** — counters, lists, sums incremented per step (`ProcessedCount`, `Errors`).
- **Flags / signals** — booleans the shell sets to communicate cross-cutting condition to later steps (`Cancelled`, `Aborted`).
- **Callbacks** — function references set up for *this* session (a progress reporter, a per-row hook). These are distinct from dependencies: a dependency is a stable service (DB, clock, logger) wired at the shell's *construction*; a callback in the context is wired at the *session's* construction and varies per session. Both are technically references; the lifecycle is what places them in different homes.
- **Identifiers** — a session ID, correlation token, trace ID — values minted at session start that later steps may read.

What does *not* belong in a Session Context:

- **Entity state.** The Subscription's state from [Axiom 22](axiom-22-state-machines.md) lives in the entity, not in the shell's working memory.
- **Dependencies.** The DB, the clock, the logger are wired at the shell's construction, not per session. They are *behaviour*; the Session Context is *data*.
- **Cross-session state.** Connection pools, in-memory caches, queues — anything that outlives one session belongs in a different layer.

---

## Example

A small CSV importer: the shell reads N rows, calls a pure validator per row, persists the valid ones, accumulates the errors, and reports progress through a per-session callback. The pure validator is unchanged from [Axiom 14](axiom-14-result.md)'s shape — `string[] -> Result<Customer, string>` — and never sees the context. The shell threads the context through the iteration and accumulates into it.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed record Customer(string Name, string Email);
public sealed record ImportError(int Row, string Reason);

public sealed class BatchContext
{
    public int ProcessedCount { get; set; }
    public List<ImportError> Errors { get; } = new();
    public Action<int> Progress { get; init; } = _ => { };
}

public void Import(IEnumerable<string[]> rows, BatchContext ctx)
{
    var rowIndex = 0;
    foreach (var row in rows)
    {
        rowIndex++;
        switch (ValidateRow(row))
        {
            case Success<Customer, string>(var customer):
                customers.Insert(customer);
                break;
            case Failure<Customer, string>(var reason):
                ctx.Errors.Add(new ImportError(rowIndex, reason));
                break;
        }
        ctx.ProcessedCount++;
        ctx.Progress(ctx.ProcessedCount);
    }
}
```

</td>
<td>

```java
public record Customer(String name, String email) {}
public record ImportError(int row, String reason) {}

public final class BatchContext {
    public int processedCount;
    public final List<ImportError> errors = new ArrayList<>();
    public final IntConsumer progress;

    public BatchContext(IntConsumer progress) {
        this.progress = progress;
    }
}

public void importRows(Iterable<String[]> rows, BatchContext ctx) {
    int rowIndex = 0;
    for (String[] row : rows) {
        rowIndex++;
        switch (validateRow(row)) {
            case Success<Customer, String> s ->
                customers.insert(s.value());
            case Failure<Customer, String> f ->
                ctx.errors.add(new ImportError(rowIndex, f.error()));
        }
        ctx.processedCount++;
        ctx.progress.accept(ctx.processedCount);
    }
}
```

</td>
</tr>
</table>

The caller — the composition root, an outer handler — allocates the context, hands it to `Import`, and reads the accumulated state when the call returns:

```csharp
var ctx = new BatchContext { Progress = n => Console.WriteLine($"row {n}") };
Import(rows, ctx);
Report(ctx.ProcessedCount, ctx.Errors);   // outside the session
```

`ValidateRow` is unchanged from [Axiom 14](axiom-14-result.md) — pure, takes a row, returns a `Result`. It does not know `BatchContext` exists. The mutation lives only in the shell: `ctx.Errors.Add(...)`, `ctx.ProcessedCount++`, `ctx.Progress(...)`. The `Progress` callback was captured at session start by the *caller* — a closure in the sense of [Axiom 7](axiom-07-first-class-functions.md), built outside the importer and handed in — not hard-coded into the shell. That's the point of putting it in the context rather than on the importer class.

---

## Problem / forces

When a shell needs to keep working state across multiple steps of one session, four shapes recur:

1. **Fields on a long-lived class.** The importer is a class with `private int _processedCount`, `private List<ImportError> _errors`, `private Action<int> _progress` fields. The fields *are* the session's working memory. The cost is the one [Axiom 22](axiom-22-state-machines.md) named: multi-field state on a long-lived object is almost always an implicit state machine — except here the fields are not an entity's condition, they are *session-scoped accumulators*. Promoting them to an FSM is the wrong refactor; the right one is to lift them off the long-lived class entirely. The class also has to be reconstructed per session, or its fields reset between sessions; concurrent sessions sharing the same instance corrupt each other.
2. **Globals or statics.** A `static int ProcessedCount`, a `static List<ImportError> Errors`. Solves the multi-session reset problem by being shared across all sessions — which is also the failure: every session contends, two concurrent imports interleave their counts, and tests cannot run in parallel. The data has no scope.
3. **Ambient context — thread-locals, async-locals, MDC, ambient containers.** A `ThreadLocal<BatchContext>` (Java), `AsyncLocal<BatchContext>` (C#), `ScopedContext` (Spring), or the SLF4J MDC. Scoped per execution context rather than globally — better than 2 — but *implicit*: any code anywhere in the call tree can reach in and read or write. The compiler does not show which functions depend on the context; following the flow of state means reading every function the call tree might touch.
4. **A named Session Context passed explicitly.** A mutable record allocated by the shell at session start and passed as a parameter to every function that reads or updates it. Scope is the lifetime of the session; ownership is the shell; the dependency is visible in every signature that needs it.

The first three each cost something the playbook has already named:

- Option 1 puts session-scoped data inside a long-lived object, conflating per-session and per-instance lifetimes. Either every session shares the same accumulators (corrupting concurrent sessions) or the class has to reset its fields between sessions (an unwritten convention).
- Option 2 has no scope at all — every consumer shares one piece of state.
- Option 3 has scope but no visibility — the dependency on the ambient context is invisible in the function signature, and the only way to know which functions depend on it is to read every body.

Option 4 — the Session Context — pays explicit parameter-passing in exchange for *named, scoped, visible* mutable state. The mutation is real; the discipline that contains it is the named scope and the explicit hand-off.

---

## Why

**1. Mutability earns a controlled, justified return.**
Twenty-two axioms have treated mutation as forbidden. This axiom does not relax that default for the pure core — the pure core stays pure. It opens *one specific place* where mutation is appropriate: the shell's own working memory for one session. Because the scope is bounded and the owner is named, mutation here does not cascade into the dangers [Axiom 1](axiom-01-immutability.md) named — there is no aliasing across the boundary, no hidden share with another caller, no surprise mutation during iteration that the rest of the program can observe.

**2. The dependency is visible in every signature that needs it.**
A function that reads or updates the Session Context takes it as a parameter. A reviewer looking at `Import(rows, ctx)` knows the function depends on `ctx`; a reviewer looking at `ValidateRow(row)` knows it does not. Compare with the ambient-context shape, where neither signature reveals the dependency. The compiler cannot help when the dependency is implicit; it helps perfectly when the dependency is a parameter.

**3. The pure core stays pure.**
`ValidateRow` does not take the context, does not see it, cannot mutate it. Its signature is the same one [Axiom 14](axiom-14-result.md) introduced — `string[] -> Result<Customer, string>` — testable as a table with no orchestration setup. The session's accumulator lives one layer out, in the shell, where mutation is allowed.

**4. The session is testable.**
Tests for `Import` allocate a `BatchContext`, run a sequence of rows through it, and assert on the accumulated state — `ctx.ProcessedCount == N`, `ctx.Errors` matches expected list. No mock framework, no thread-local cleanup between tests, no shared state to reset. Two tests running in parallel each have their own context.

**5. Per-session behaviour is per-session data.**
A progress callback set up by *this* run of the importer is part of *this* session — not part of the importer's stable wiring. The Session Context is the natural home: declared once, captured at session start, available to every step. A new session gets a fresh callback without rewiring the importer class.

---

## Trade-offs

**Mutability is now permitted at one named point — discipline carries the rest.** The scope is small (one session, one shell, one explicit parameter), but the moment mutation is allowed it can be misused. Hand the context to a pure function and the pure function stops being pure. Capture a reference to the context's internal list and read it from another thread mid-session — race. Cache the context past the session's end — leak. The discipline this axiom asks for is not a tax on cleverness; it is the *only* reason the mutability is safe.

**Explicit threading is visible noise.** Every shell function that needs the context grows a parameter. In a deep call tree this can feel like ambient context would be tidier — and it would be, at the cost of [Why 2.](#why). The visible parameter is the playbook's choice; in a small shell the cost is bounded, and the visibility pays off the first time someone has to trace where the accumulator changes.

**Mutable fields in a record-leaning codebase look out of place.** A C# `sealed class` with `{ get; set; }` properties, or a Java `final class` with non-`final` fields, sits awkwardly next to a codebase otherwise built on immutable records ([Axiom 1](axiom-01-immutability.md)). Calling out the type as a *Session Context* in its name (e.g. `BatchContext`, `SessionContext`, `RunContext`) — and keeping it in the shell layer — is the convention that makes the exception legible: this type is *meant* to be mutable; the surrounding records are not.

**The boundary between Session Context and entity state can blur.** A long-running session for one entity tempts the developer to put the entity's state into the Session Context "while we're here." Don't — those concerns belong in [Axiom 22](axiom-22-state-machines.md), modelled as a State DU and threaded as a *value* through `Transition`. The Session Context holds the *shell's* working memory; the entity's condition holds the *entity's* condition. Mixing them collapses the seam.

**Cross-session shared state is a different problem.** A connection pool, an in-memory cache, a job queue — these outlive any one session and do not belong in the Session Context. The Session Context's scope is *one* session; resources that span many sessions are owned at a higher layer.

---

## When NOT to

**One-shot shells with no accumulated state.** An HTTP endpoint that loads one entity, calls `Transition` once, persists, responds — the synthesis from [Axiom 22](axiom-22-state-machines.md) — has no session-scoped working memory. There is nothing to accumulate, no progress to report, no flag to carry across steps. The Session Context is dead weight here; the four-line shell is already the shape.

**Pure-function tests and table-driven checks.** Tests for `Transition`, `Decide`, `ValidateRow`, `Map`/`Bind`/`MapError` do not need a Session Context — those functions never take one. Reaching for a context "for consistency" adds vocabulary without changing what the test asserts.

**Entity state.** When the working memory is *the entity's condition* — flags, timestamps, counters that move together because the entity is moving through states — the right home is [Axiom 22](axiom-22-state-machines.md): promote the fields to a State DU and the rules to `Transition`. The Session Context is *not* a shortcut for that refactor; the smells the two axioms address are different.

**Dependencies and behaviour.** A DB, a clock, a logger — services wired at the shell's construction — belong in the shell's constructor (Dependency Injection / module-level statics / function parameters at construction), not in the Session Context. The lifecycle distinguishes them: a dependency is stable across many sessions, the Session Context lives for one.

**Cross-session shared state.** Connection pools, caches, queues — anything whose lifetime exceeds one session — lives at a higher layer than the Session Context. Where exactly is its own concern, outside this axiom.

---

## References

[1] **Mark Seemann, Steven van Deursen**, *Dependency Injection Principles, Practices, and Patterns*, Manning Publications, 2019. The book's chapters on *Ambient Context as an anti-pattern* and *Method Injection as the alternative* are the closest mainstream precedent for this axiom: state that varies per call (or per session) is passed explicitly, not stored ambiently. The Session Context is the per-session, mutable analogue of method-injected request-scoped state.
<https://www.manning.com/books/dependency-injection-principles-practices-patterns>

[2] **Yehonathan Sharvit**, *Data-Oriented Programming: Reduce software complexity*, Manning Publications, 2022. Cross-listed from [Axiom 0](axiom-00-data-vs-behaviour.md), [Axiom 1](axiom-01-immutability.md), [Axiom 11](axiom-11-maybe.md), [Axiom 12](axiom-12-either.md), [Axiom 19](axiom-19-discriminated-unions.md), [Axiom 21](axiom-21-pure-functions-returning-actions.md), and [Axiom 22](axiom-22-state-machines.md). Sharvit's distinction between *system state* (the long-lived, shared value the application is "about") and *transient state* held by the orchestration layer is the data-oriented framing of the same separation: entity state belongs in one place, the shell's own session-scoped data in another.
<https://www.manning.com/books/data-oriented-programming>

[3] **Vaughn Vernon**, *Implementing Domain-Driven Design*, Addison-Wesley, 2013. The book's chapters on *Application Services* describe the per-request coordinator that owns the session's working state — transactional boundary, identifiers, accumulators — and hands the entity's state through pure operations. The Application Service is the architectural sibling of this axiom's "shell holds the Session Context"; the names differ but the lifecycle and ownership match.
<https://www.informit.com/store/implementing-domain-driven-design-9780321834577>
