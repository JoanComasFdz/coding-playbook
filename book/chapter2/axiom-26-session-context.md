# Axiom 26 — Session Context

**A Session Context is a mutable object that holds the working memory of one session (counters, collected errors, flags, callbacks, identifiers). The shell owns it and passes it explicitly to the functions that need it. It is the first place in this chapter where mutation is allowed, and the price is strict scope, one owner, and explicit passing.**

- It is created when the session starts and dropped when it ends.
- Only the shell reads or changes it. The pure core never sees it.
- It is passed as a parameter, never reached through a global, a static or a thread-local.

Every axiom so far has pushed the same way. Data is a value ([Axiom 2](axiom-02-data-is-not-behavior.md)) that doesn't change ([Axiom 3](axiom-03-immutability.md)), decisions are pure ([Axiom 6](axiom-06-pure-functions.md)), and even a state machine's state ([Axiom 25](axiom-25-state-machines.md)) flows as an immutable value: passed in, used to compute the next one, saved by the shell.

Most programs can't live entirely on that. A batch import counts rows as it goes. A multi-step job collects the errors it finds along the way. A session that spans several steps needs callbacks set up at the start and an identifier later steps can read. None of this is the state being decided about; it is the *shell's own* working memory while one session runs. Rebuilding an immutable snapshot at every step would buy nothing: this data isn't replayed, compared or audited. It only needs to live for the session and be readable by the steps that use it.

Frameworks already ship this shape. ASP.NET Core's `HttpContext` is created per request and passed to middleware (`InvokeAsync(HttpContext context)`), with an `Items` dictionary for values shared between steps; EF Core's `DbContext` lives per request and collects pending changes until `SaveChanges()`. In Java, `HttpServletRequest` carries request-scoped attributes, and JPA's `EntityManager` is the persistence context of one unit of work. Each is designed to be passed explicitly, though each also offers an ambient way to reach it (`IHttpContextAccessor`, Spring's `RequestContextHolder`), the form this axiom rules out (see *Problem / forces*).

Through [Axiom 9](axiom-09-connascence.md)'s lens, ambient shared state is the strongest kind of coupling, a [Connascence of Identity](axiom-09-connascence.md#connascence-of-identity-coi): any function in the call tree may reach the one shared mutable object, and no signature says which do. Passing the context explicitly doesn't remove the sharing, but it makes it visible in every signature that needs it, and keeps it inside the shell. That is [Axiom 1](axiom-01-explicit-over-implicit.md) applied to the one piece of mutable state this chapter allows.

---

## Definitions

A **session** is one unit of work the shell drives from start to end: importing one file, handling one HTTP request across several steps, one run of a job. Its start and end are clear, and the Session Context lives between them.

A **Session Context** is:

- **Mutable on purpose.** In C#, a `sealed class` with settable properties; in Java, a `final class` with non-final fields. Its job is to hold values and be updated.
- **Scoped to one session**: created at the shell's entry point, discarded when the session ends.
- **Owned by the shell.** Only impure orchestration code reads or writes it. Pure functions never receive it. Vernon's application services play this role in DDD [2].
- **Passed explicitly** to every shell function that needs it. Thread-locals, async-locals and statics are not this shape.

**What goes in it:**

- **Accumulators**: counters, lists, totals updated as the session goes (`ProcessedCount`, `Errors`).
- **Flags**: values the shell sets so later steps know about a condition (`Cancelled`).
- **Callbacks** set up for *this* session, such as a progress reporter. They differ from dependencies by lifetime: a dependency (database, clock, logger) is wired once when the shell is built; a callback in the context is wired per session.
- **Identifiers** created at the start of the session, such as a correlation ID.

**What doesn't:**

- **The state being decided about.** A subscription's state belongs in [Axiom 25](axiom-25-state-machines.md)'s state DU, passed as a value through `Transition`. The context holds the *shell's* memory, not the domain's [3].
- **Dependencies.** Database access, the clock and the logger outlive any session; they are wired when the shell is built (see the *Example* for a database context that lives for one run).
- **State shared across sessions.** Connection pools, caches and queues outlive one session and belong at a higher level.

---

## Example

A CSV import. The shell reads the rows, calls a pure validator on each one, saves the valid ones, collects the errors, and reports progress through a per-session callback. The validator has the shape of [Axiom 17](axiom-17-result.md) (`string[] → Result<Customer, string>`) and never sees the context.

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
    public Action<int> ReportProgress { get; init; } = _ => { };
}

public sealed class CustomerImporter(
    IDbContextFactory<ImportDbContext> dbFactory)     // dependency: wired once
{
    public void ImportRows(
        IEnumerable<string[]> rows,
        BatchContext context)                         // session: passed per call
    {
        using var db = dbFactory.CreateDbContext();   // one unit of work per run
        var rowNumber = 0;
        foreach (var row in rows)
        {
            rowNumber++;
            var validation = ValidateRow(row);        // pure
            switch (validation)
            {
                case Success<Customer, string>(var customer):
                    db.Customers.Add(customer);
                    break;
                case Failure<Customer, string>(var reason):
                    context.Errors.Add(new ImportError(rowNumber, reason));
                    break;
                default:
                    throw new UnreachableException();
            }
            context.ProcessedCount++;
            context.ReportProgress(context.ProcessedCount);
        }
        db.SaveChanges();
    }
}

// The importer is built once; each run gets a fresh context:
var importer = new CustomerImporter(dbFactory);

var context = new BatchContext
{
    ReportProgress = n => Console.WriteLine($"row {n}")
};
importer.ImportRows(rows, context);
WriteSummary(context.ProcessedCount, context.Errors);
```

</td>
<td>

```java
public record Customer(String name, String email) {}
public record ImportError(int row, String reason) {}

public final class BatchContext {
    public int processedCount;
    public final List<ImportError> errors = new ArrayList<>();
    public final IntConsumer reportProgress;

    public BatchContext(IntConsumer reportProgress) {
        this.reportProgress = reportProgress;
    }
}

public final class CustomerImporter {
    private final DSLContext dsl;                    // dependency: wired once

    public CustomerImporter(DSLContext dsl) {
        this.dsl = dsl;
    }

    public void importRows(
            Iterable<String[]> rows,
            BatchContext context) {                  // session: passed per call
        int rowNumber = 0;
        for (String[] row : rows) {
            rowNumber++;
            var validation = validateRow(row);       // pure
            switch (validation) {
                case Success<Customer, String> s -> dsl
                    .insertInto(CUSTOMER)
                    .set(CUSTOMER.NAME, s.value().name())
                    .set(CUSTOMER.EMAIL, s.value().email())
                    .execute();
                case Failure<Customer, String> f ->
                    context.errors.add(
                        new ImportError(rowNumber, f.error()));
            }
            context.processedCount++;
            context.reportProgress.accept(context.processedCount);
        }
    }
}

// The importer is built once; each run gets a fresh context:
var importer = new CustomerImporter(dsl);

var context = new BatchContext(
    n -> System.out.println("row " + n));
importer.importRows(rows, context);
writeSummary(context.processedCount, context.errors);
```

</td>
</tr>
</table>

The inputs have different lifetimes, and the code shows it:

- **The database access is a dependency.** It outlives every run, so it arrives once, through the constructor, and is used directly: `CustomerImporter` is the ordinary shell class of [Axiom 13](axiom-13-impureim.md#definitions). In Java that is jOOQ's `DSLContext`, whose configuration is designed to be shared [4]. In C# it is EF Core's `IDbContextFactory`, because a `DbContext` itself is "designed to be used for a *single* unit-of-work" and is not thread-safe [5]: each run creates one, saves once at the end, and disposes it.
- **`BatchContext` belongs to one run**, so it arrives as a parameter of each call.

`ValidateRow` is pure: it takes a row and returns a `Result`, and doesn't know `BatchContext` exists. All the mutation is in the shell: adding an error, incrementing the count, reporting progress. The progress callback was built by the *caller*, a closure in the sense of [Axiom 10](axiom-10-first-class-functions.md), and handed in, so a new session can report progress differently without changing the importer.

---

## Problem / forces

When a shell needs working state across the steps of one session, four shapes are common:

1. **Fields on a long-lived class.** The importer keeps `_processedCount`, `_errors` and `_progress` as fields. Session data now lives as long as the object, so either every session shares the same counters (and concurrent sessions corrupt each other), or the class must reset its fields between sessions, an unwritten convention. Turning those fields into a state machine ([Axiom 25](axiom-25-state-machines.md#why), point 3) is the wrong fix here: they aren't the condition of anything, just the session's scratch space.
2. **Globals or statics.** Shared by every session at once: two concurrent imports mix their counts, and tests can't run in parallel. The data has no scope.
3. **Ambient context**: a `ThreadLocal` in Java, an `AsyncLocal` in C#, or a logging MDC. Scoped per execution, which is better than a global, but *implicit*: any function in the call tree can read or write it, and no signature shows which ones do. Seemann and van Deursen describe this as the Ambient Context anti-pattern [1].
4. **A named Session Context, passed explicitly.** Created by the shell at the start of the session and passed as a parameter to each function that uses it. The scope is the session, the owner is the shell, and the dependency is visible in every signature that needs it.

The first three cost something already named in this book: the wrong lifetime, no scope, or an invisible dependency. The Session Context pays with an extra parameter, in exchange for mutable state that is named, scoped and visible.

---

## Why

**1. Mutation comes back in one bounded place.**
The pure core stays pure. Mutation is allowed in exactly one place: the shell's working memory for one session. Because the scope is bounded and the owner is named, the dangers of [Axiom 3](axiom-03-immutability.md) don't spread: nothing outside the session holds a reference, and nothing else can see a change half-way through.

**2. The dependency is in the signature.**
`ImportRows(rows, context)` tells the reader it uses the context; `ValidateRow(row)` tells them it doesn't. With ambient state, neither signature would say. The compiler can only help with a dependency that is a parameter.

**3. A session is easy to test.**
A test creates a `BatchContext`, runs rows through `ImportRows`, and checks what the context collected: the count, the list of errors. No mocks, no thread-local cleanup between tests, and two tests running in parallel each have their own context.

---

## Trade-offs

- **Allowing mutation means it can be misused.** Pass the context to a pure function, and that function stops being pure. Hand its error list to another thread mid-session, and you have a race. Keep a reference after the session ends, and you have a leak. The discipline this axiom asks for is the *only* thing that makes the mutation safe.
- **Explicit passing adds a parameter.** In a deep call tree, an ambient context can look tidier, at the cost of *Why*, point 2. In a shell of reasonable size the cost is small, and the visible parameter pays off the first time someone has to find where a counter changes.
- **A mutable class looks out of place.** A class with settable properties stands out in a codebase built on immutable records. Name it as what it is (`BatchContext`, `RunContext`) and keep it in the shell, so the exception reads as deliberate.

---

## When NOT to

- **A one-shot shell with nothing to collect.** An HTTP handler that loads a state, calls `Transition` once, saves and responds ([Axiom 25](axiom-25-state-machines.md#example)) has no working memory across steps. A context there is dead weight.
- **Tests of pure functions.** `Transition`, `DecideAdd` and `ValidateRow` never take a context, so their tests don't need one.
- **Anything listed under *What doesn't* in *Definitions*.** State that changes as the domain moves through conditions belongs in a state DU ([Axiom 25](axiom-25-state-machines.md#why), point 3). Dependencies belong in the shell's construction, and cross-session resources at a higher level. The context is not a shortcut around any of them.

---

## References

[1] **Mark Seemann, Steven van Deursen**, *Dependency Injection Principles, Practices, and Patterns*, Manning Publications, 2019. Describes Ambient Context as an anti-pattern and Method Injection as the alternative: values that vary per call are passed explicitly, not stored ambiently. A Session Context is the per-session, mutable form of that advice.
<https://www.manning.com/books/dependency-injection-principles-practices-patterns>

[2] **Vaughn Vernon**, *Implementing Domain-Driven Design*, Addison-Wesley, 2013. Its Application Services coordinate one request: they own the transaction and the request's working data, and hand the domain its state. That is this axiom's shell holding its Session Context, under another name.
<https://www.informit.com/store/implementing-domain-driven-design-9780321834577>

[3] **Yehonathan Sharvit**, *Data-Oriented Programming: Reduce software complexity*, Manning Publications, 2022. Also cited in [Axiom 2](axiom-02-data-is-not-behavior.md), [Axiom 3](axiom-03-immutability.md), [Axiom 22](axiom-22-discriminated-unions.md), [Axiom 24](axiom-24-pure-functions-returning-actions.md) and [Axiom 25](axiom-25-state-machines.md). Keeps the system's state as one immutable value, apart from the code that orchestrates changes to it: the same split as the domain's state versus the shell's working memory.
<https://www.manning.com/books/data-oriented-programming>

[4] **jOOQ manual**, *Thread safety* (DSLContext). Configuration objects make "no thread safety guarantees", but "Configuration was designed to work in a thread safe way", and the manual encourages sharing them, "because they contain caches for work not worth repeating".
<https://www.jooq.org/doc/latest/manual/sql-building/dsl-context/thread-safety/>

[5] **Microsoft**, *DbContext Lifetime, Configuration, and Initialization*, EF Core documentation. "A `DbContext` instance is designed to be used for a *single* unit-of-work", it is "Not thread-safe", and `IDbContextFactory` is the documented way to create one per unit of work when the surrounding scope doesn't match.
<https://learn.microsoft.com/en-us/ef/core/dbcontext-configuration/>

---

← Previous: [Axiom 25 — State machines](axiom-25-state-machines.md) · Next: [Axiom 27 — Stateful Shell](axiom-27-stateful-shell.md) →
