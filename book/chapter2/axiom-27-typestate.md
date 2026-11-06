# Axiom 27 — Typestate

**When operations must run in a set order, give each state its own immutable type, put each operation only on the type of the state where it is valid, and make every transition return the type of the next state. A call made in the wrong order then doesn't compile: the method isn't there on the value the caller holds.**

[Axiom 18](axiom-18-value-objects.md) made illegal *values* unrepresentable, [Axiom 22](axiom-22-illegal-states.md) a record's illegal *shapes*, and [Axiom 24](axiom-24-state-machines.md) put the legal *transitions* into one pure function. Typestate does the same for *call order*. A caller holding an `AuthenticationService` can't ask whether the user is an admin, because `HasRole` only exists on `AuthenticatedSession`, and the only way to get one is to authenticate.

Through [Axiom 8](axiom-08-connascence.md)'s lens, typestate turns a dynamic [Connascence of Execution](axiom-08-connascence.md#connascence-of-execution-coe) (callers must remember the order, what Hunt and Thomas call *temporal coupling* [2]) into a static [Connascence of Type](axiom-08-connascence.md#connascence-of-type-cot) the compiler checks.

This axiom comes last because most code doesn't need it. Every status field is a state machine, and [Axiom 24](axiom-24-state-machines.md)'s value-level `Transition` is usually enough. Typestate costs one named type per state. It pays off where a wrong-order call does real harm: an authorization hole, a leaked resource, a half-built object.

---

## Definitions

A **typestate** has four properties:

- **One immutable type per state.** A record ([Axiom 2](axiom-02-immutability.md)). A linear lifecycle (open, then closed) gets one record per step. When a step has several variants, they form a sealed hierarchy ([Axiom 21](axiom-21-discriminated-unions.md)), and each variant is a typestate of its own.
- **A transition returns the next type.** `S₁ → S₂`: calling it builds a new value of the next state and leaves the input untouched. When it can fail, it returns `Result<S₂, string>` ([Axiom 16](axiom-16-result.md)).
- **Each operation lives on the type that allows it**, never on a shared base. Whether a call compiles depends only on the type the caller holds.
- **The transition is the only way in.** If callers can build a state directly, `new AuthenticatedSession(admin)` skips authentication and the guarantee is gone. So the state's constructor is not public, the same construction control [Axiom 18](axiom-18-value-objects.md) asks of value objects:
  - **C#:** an `internal` constructor on the record.
  - **Java:** a `public final class` with a package-private constructor, because a public record's canonical constructor must be public.

  `private` is too strict: the transition that builds `S₂` is a method on `S₁`, a different type.

---

## Example

A login service keeps the logged-in user in a nullable field. Calling `HasRole` before `Login` compiles and quietly returns `false`.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public class AuthenticationService
{
    private User? user;  // null until login

    public void Login(string token)
    {
        var payload = Jwt.TryDecode(token);  // Payload?
        if (payload is not null)
            user = new User(payload.Subject, payload.Role);
    }

    public bool HasRole(string role) =>
        user?.Role == role;  // false when not logged in
}

// Wrong order, compiles, quietly misbehaves:
var auth = new AuthenticationService();
if (auth.HasRole("admin"))
    PerformAdminAction();  // never runs; nobody notices
                           // the missing Login
```

</td>
<td>

```java
public final class AuthenticationService {
    private User user;  // null until login

    public void login(String token) {
        Jwt.tryDecode(token)  // Optional<Payload>
           .ifPresent(p -> user = new User(p.subject(), p.role()));
    }

    public boolean hasRole(String role) {
        return user != null && user.role().equals(role);
    }
}

// Wrong order, compiles, quietly misbehaves:
var auth = new AuthenticationService();
if (auth.hasRole("admin"))
    performAdminAction();  // never runs; nobody notices
                           // the missing login
```

</td>
</tr>
</table>

`HasRole` isn't wrong. The bug is that the type system lets anyone call it before `Login`. The fix moves the precondition into a type:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public class AuthenticationService
{
    public Result<AuthenticatedSession, string>
        Authenticate(string token)
    {
        var payload = Jwt.TryDecode(token);
        if (payload is null)
            return new Failure<AuthenticatedSession, string>(
                "invalid token");
        var user = new User(payload.Subject, payload.Role);
        return new Success<AuthenticatedSession, string>(
            new AuthenticatedSession(user));
    }
}

public sealed record AuthenticatedSession
{
    public User User { get; }

    // internal: only code in this assembly
    // (Authenticate) can build one
    internal AuthenticatedSession(User user) => User = user;

    public bool HasRole(string role) => User.Role == role;
}

// Caller:
var auth = new AuthenticationService();
// auth.HasRole("admin");  // doesn't compile

var result = auth.Authenticate(token);
var response = result.Match(
    success: session => session.HasRole("admin")
        ? PerformAdminAction(session)
        : new HttpResponse(403, "forbidden"),
    failure: error => new HttpResponse(401, error));
```

</td>
<td>

```java
public final class AuthenticationService {
    public Result<AuthenticatedSession, String>
            authenticate(String token) {
        Optional<Payload> payload = Jwt.tryDecode(token);
        if (payload.isEmpty())
            return new Failure<>("invalid token");
        Payload p = payload.get();
        var user = new User(p.subject(), p.role());
        return new Success<>(new AuthenticatedSession(user));
    }
}

public final class AuthenticatedSession {
    private final User user;

    // package-private: only code in this package
    // (authenticate) can build one
    AuthenticatedSession(User user) {
        this.user = user;
    }

    public boolean hasRole(String role) {
        return user.role().equals(role);
    }
}

// Caller:
var auth = new AuthenticationService();
// auth.hasRole("admin");  // doesn't compile

var result = auth.authenticate(token);
HttpResponse response = result.match(
    session -> session.hasRole("admin")
        ? performAdminAction(session)
        : new HttpResponse(403, "forbidden"),
    error -> new HttpResponse(401, error));
```

</td>
</tr>
</table>

The only way to get an `AuthenticatedSession` is the success branch of `Authenticate`. Asking about roles before that isn't a check that returns `false`; it is a call to a method the value doesn't have. The silent-`false` bug is gone, and so is every `if (user != null)` that guarded against it.

The same shape turns up elsewhere:

- **An issue tracker** where `endTime == null` means "open" becomes `OpenIssue` and `ClosedIssue`, with `OpenIssue.Close(timestamp) → ClosedIssue`. `ClosedIssue` has no `Close`.
- **A UI test page object** whose methods all start with `if (!rendered) throw` becomes `UnrenderedWidget` and `RenderedWidget`. Rendering is the transition, and every other operation lives on `RenderedWidget`.

Each time: two records, one transition, and a class of runtime errors that can no longer be written.

---

## Typestates that carry types

The examples above change the type at each step and nothing more. Two variants also carry *generic type parameters* from one step to the next, so a later step can be checked against an earlier choice. You have likely used both in libraries without naming them. Their extra cost is in [*Trade-offs*](#trade-offs).

These [fluent interfaces](https://en.wikipedia.org/wiki/Fluent_interface) are [DSLs](https://en.wikipedia.org/wiki/Domain-specific_language), so their steps take the keywords of the language they imitate (`From`, `Where`, `Given`, `When`), not verbs: one of the exceptions to [Axiom 1](axiom-01-data-is-not-behavior.md#definitions)'s naming rule.

### Carrying a type forward

A SQL builder whose row type is fixed at the first step and travels through every step to the final query:

```csharp
public static class Sql
{
    public static SelectStep<TRow> Select<TRow>(params string[] columns) =>
        new(columns);
}

public sealed record SelectStep<TRow>(IReadOnlyList<string> Columns)
{
    public FromStep<TRow> From(string table) => new(Columns, table);
}

public sealed record FromStep<TRow>(IReadOnlyList<string> Columns, string Table)
{
    public WhereStep<TRow> Where(string predicate) =>
        new(Columns, Table, predicate);
    public Query<TRow> Build() => new(Columns, Table, Predicate: null);
}

public sealed record WhereStep<TRow>(
    IReadOnlyList<string> Columns, string Table, string Predicate)
{
    public Query<TRow> Build() => new(Columns, Table, Predicate);
}

public sealed record Query<TRow>(
    IReadOnlyList<string> Columns, string Table, string? Predicate);

var query = Sql.Select<(int Id, string Name)>("Id", "Name")
    .From("Users")
    .Where("Active = 1")
    .Build();
// query is a Query<(int Id, string Name)>
// Where() before From() doesn't compile.
```

In this sketch nothing checks `TRow` against the column names. jOOQ [6] closes that gap by giving each column its own type: `select(A, B).from(T).fetch()` returns a jOOQ `Result<Record2<A, B>>`, so the columns you selected are in the type you get back.

### Stacking types

Here each step *adds* a type parameter, and the last step sees all of them. A Given/When/Then test builder:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public static class Scenario
{
    public static ArrangedScenario<TSut> Given<TSut>(
        Func<TSut> arrange) => new(arrange());
}

public sealed record ArrangedScenario<TSut>(TSut Sut)
{
    public ActedScenario<TSut, TResult> When<TResult>(
        Func<TSut, TResult> act) => new(Sut, act(Sut));
}

public sealed record ActedScenario<TSut, TResult>(
    TSut Sut, TResult Result)
{
    public void Then(Action<TSut, TResult> assert) =>
        assert(Sut, Result);
}

Scenario.Given(() => new Calculator())  // ArrangedScenario<Calculator>
    .When(c => c.Add(2, 3))             // ActedScenario<Calculator, int>
    .Then((sut, result) =>              // both in scope
        Assert.Equal(5, result));
```

</td>
<td>

```java
public final class Scenario {
    public static <TSut> ArrangedScenario<TSut> given(
            Supplier<TSut> arrange) {
        return new ArrangedScenario<>(arrange.get());
    }
}

public record ArrangedScenario<TSut>(TSut sut) {
    public <TResult> ActedScenario<TSut, TResult> when(
            Function<TSut, TResult> act) {
        return new ActedScenario<>(sut, act.apply(sut));
    }
}

public record ActedScenario<TSut, TResult>(
        TSut sut, TResult result) {
    public void then(BiConsumer<TSut, TResult> assertion) {
        assertion.accept(sut, result);
    }
}

Scenario.given(() -> new Calculator())  // ArrangedScenario<Calculator>
    .when(c -> c.add(2, 3))             // ActedScenario<Calculator, Integer>
    .then((sut, result) ->              // both in scope
        assertEquals(5, result));
```

</td>
</tr>
</table>

`When` doesn't exist before `Given`, and `Then` doesn't exist before `When`. Unlike jOOQ's `Record1` to `Record22`, there is no open-ended arity to declare in advance: a scenario has three steps, so it needs three types. One type per step is only for clarity; a step can add several.

Two everyday libraries use this shape:

- **[FluentValidation](https://docs.fluentvalidation.net/) (C#)** [7]. `RuleFor(x => x.Age)` captures the property's type (`int`), and the rules after it must fit: `.GreaterThan(0)` compiles, `.Length(1, 5)` (a string rule) doesn't.
- **Moq (C#) and Mockito (Java).** `mock.Setup(x => x.Parse("a"))` and `when(mock.parse("a"))` capture the method's return type, and the `.Returns(...)` or `.thenReturn(...)` that follows doesn't compile unless the value matches it.

Both variants belong in libraries, DSLs and test helpers, where a later step really needs checking against an earlier one. In domain code, the plain typestate is enough.

---

## Problem / forces

When a class has methods that are only valid after certain other calls, five shapes recur:

1. **A runtime guard at the top of each method.** `if (state != Approved) throw new InvalidOperationException(...)`. Honest, but the precondition lives in the body, not the signature. Every caller has to remember it, every test has to build the object in the right state, and the guards copied into N methods drift apart.
2. **A status field and a `switch` on it in each method.** The check is fused with the work, so it hides better than a throw. Each method is a small transition table of its own, and nothing checks that those tables agree.
3. **A nullable field as a state flag.** `endTime == null` means open. The rule is a convention the reader has to know, the compiler checks nothing, and fields that only make sense in one state sit in all of them.
4. **A value-level state machine** ([Axiom 24](axiom-24-state-machines.md)). One sealed union of states and one pure `Transition`. The rule is in one place, but the state is still one type, and each operation still asks which case it holds.
5. **A typestate.** One type per state; each operation lives only where it is valid; nothing left to check.

Shapes 1–3 leave the rule to convention. Shape 4 puts it in one pure function. Shape 5 puts it in the types.

Both 4 and 5 are state machines. The choice between them is whether operations belong to *one* type that checks its state, or to *separate* types that never need to:

- **Shape 4** fits when most operations are valid in most states.
- **Shape 5** fits when each state has its own set of operations and a wrong-order call does real harm.

---

## Why

**1. A wrong-order call doesn't compile.**
There is no path to `HasRole` except through the success branch of `Authenticate`. The guard every method used to repeat is gone, because the call it guarded against can't be written.

**2. The signature states the precondition.**
A function that takes an `AuthenticatedSession` says, in its signature, that it needs an authenticated user. A function that takes an `AuthenticationService` can't. This is the [Design by Contract](https://en.wikipedia.org/wiki/Design_by_contract) precondition that [Axiom 18](axiom-18-value-objects.md) carried in a type, now applied to call order: checked by the compiler instead of asserted at runtime.

**3. The rule lives in one place.**
Guards copied into N methods drift into N slightly different guards. A transition whose return type is the next state holds the rule once. Tests for the impossible cases go away, and so do the reviews that hunted for them.

**4. The shell holds a typed state, not a nullable one.**
A long-running shell ([Axiom 26](axiom-26-stateful-shell.md)) that holds an `AuthenticatedSession` instead of a `User?` field gives the rest of the program less to misuse. What it passes to the pure core ([Axiom 12](axiom-12-impureim.md)) is typed by what it is, not by what it might be.

---

## Trade-offs

**The old reference stays usable.** After `var submitted = draft.Submit()`, the caller still holds `draft`, and `draft.Submit()` compiles a second time. Rust's ownership consumes the old value on a transition [4]; C# and Java can't. The mitigation: keep each state's type small, with little on it beyond its transitions, so the stale reference can do little harm. If the old value truly must become unusable, typestate alone isn't enough.

**Loading from a database needs care.** A stored state arrives as a row, not as an `OpenIssue` or a `ClosedIssue`. The code that loads it reads a discriminator (a status column, or whether `end_time` is set) and builds the matching type. If it skips that step, values enter the program as the wrong type and the guarantee is gone. That loader is the one place outside the transitions allowed to call the constructor, which is why the constructor is `internal` or package-private rather than `private`: the loader lives in the same assembly or package. It is the same boundary [Axiom 18](axiom-18-value-objects.md) draws for value objects.

**One type per state.** A lifecycle with five states needs five types and the transitions between them. In return, every operation is total over the state it lives on. It is the same deal as [Axiom 18](axiom-18-value-objects.md) and [Axiom 24](axiom-24-state-machines.md): a few more named types now, simpler code wherever they are used.

**The carrying variants are heavier.** When types travel through the chain ([*Typestates that carry types*](#typestates-that-carry-types)), signatures grow long, IDE tooltips get hard to read, and the arity hits limits (jOOQ's typed records stop at `Record22`). Worth it in a library or DSL; rarely in domain code.

---

## When NOT to

**Required fields.** If the rule is "the caller must supply A, B and C," use a constructor or a record that takes all three (or, in C# 11+, `required` members). A step-by-step builder just to force three fields is ceremony. Typestate is for *order*, not for *completeness*.

**Two states and little harm.** A builder with only "not built" and "built" earns a type pair only if building twice, or using it unbuilt, actually hurts. If a second `Build` does nothing, leave it.

**Lifecycles a framework owns.** A Web Component's `connectedCallback` is called by the browser, not by you, so no type can stop a method from running before it. The usual fix is at runtime: queue the early calls and run them when the lifecycle event arrives.

**Rules about a tree.** A React hook that must run inside a `Provider` depends on the component tree, which the type system can't see. The runtime error ("useX must be used within an XProvider") is the established idiom. Typestate constrains a value, not how values sit in a tree.

**When a value-level state machine is enough.** If most operations are valid in most states and a wrong-order call is mild (a no-op, a 409, a logged warning), [Axiom 24](axiom-24-state-machines.md) is cheaper. Move to typestate only when splitting operations by state actually helps the reader.

---

## References

[1] **Robert E. Strom & Shaula Yemini**, *Typestate: A Programming Language Concept for Enhancing Software Reliability*, IEEE Transactions on Software Engineering SE-12(1):157–171, 1986. The original typestate: the compiler tracks each variable's state (such as whether it has been initialized) and rejects operations invalid in that state. It grew out of Strom's work on IBM's NIL language in 1983.

[2] **David Thomas & Andrew Hunt**, *The Pragmatic Programmer*, 20th anniversary edition, Addison-Wesley, 2019, topic "Breaking Temporal Coupling" (first edition 1999, "Temporal Coupling"). Names the smell: an order that callers must respect but nothing enforces. Typestate is a type-level answer to it.
<https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/>

[3] **Yaron Minsky**, *Effective ML*, 2010, and *Effective ML Revisited*, Jane Street blog, 2011. Cross-listed from [Axiom 22](axiom-22-illegal-states.md). "Make illegal states unrepresentable," which this axiom applies to call order.

[4] **Cliff Biffle**, *The Typestate Pattern in Rust*, 2019. The modern treatment in a language where ownership consumes the old state on each transition, the guarantee C# and Java lack (see [*Trade-offs*](#trade-offs)).
<https://cliffle.com/blog/rust-typestate/>

[5] **Adam Rodger**, *The Typestate Pattern in C# - Redesigning PactNet*, 2021. A C# typestate in a real library: each state is an interface, each step returns the next one, and invalid calls aren't on the interface you hold.
<https://adamrodger.com/post/2021-10-13-typestate-pattern-in-csharp/>

[6] **Lukas Eder et al.**, *jOOQ*. The carrying variant at scale: each fluent step's generic parameters carry the selected columns' types to the final `Result<RecordN<…>>`.
<https://www.jooq.org/>

[7] **Jeremy Skinner et al.**, *FluentValidation*. The stacking variant in everyday C#: `RuleFor` captures the property's type, and the rules after it are checked against it.
<https://docs.fluentvalidation.net/>

---

← Previous: [Axiom 26 — Stateful Shell](axiom-26-stateful-shell.md) · [Chapter 2 Contents](README.md)
