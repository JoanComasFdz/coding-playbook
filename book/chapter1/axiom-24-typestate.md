# Axiom 24 — Typestate

**When a sequence of operations must be executed in a particular order, give each state its own immutable type and make each operation return the type of the next state. Each operation lives only on the type of the state where it is valid; a transition is the operation whose return type is the *next* state (`S₁ → S₂`, a new value, not a mutation). The compiler refuses any out-of-order call, because the function simply does not exist on the type the caller is holding. This makes illegal call sequences unrepresentable, the same way [Axiom 15](axiom-15-value-objects.md) made illegal values unrepresentable.**

- Each state is its own immutable type — a record, or a variant of a sealed hierarchy.
- Operations valid in state `S₁` live as methods on `S₁`'s type, **not** on a shared base. The compiler decides what's callable by which type the value currently has.
- A transition is a function whose signature is `S₁ → S₂` — the input is the state you're in, the output is the state you're in next. When the transition can fail, the return is `Result<S₂, string>` ([Axiom 13](axiom-13-result.md)).
- The runtime guard `if (state != X) throw ...` and the status-field switch `if (Status == Cancelled) { ... }` **disappear** because the call that would have failed them cannot be written.

[Axiom 15](axiom-15-value-objects.md) makes the *values* a domain accepts unrepresentable when they violate a rule — `Username.From("")` returns a `Failure`, not a `Username`. [Axiom 19](axiom-19-illegal-states.md) makes a record's *shape* unrepresentable when its fields combine illegally — a `Paid` bill without its payment reference cannot be constructed. [Axiom 21](axiom-21-state-machines.md) makes the *transitions* between states first-class — one pure `Transition(state, command) → event` over a sealed DU of states. This axiom completes the family by making *call sequences* unrepresentable: each state in the machine becomes its own type, and the operations that belong to that state live only on that type. A caller holding an `AuthenticationService` cannot ask "does this session have the admin role?" — the method `HasRole` does not exist on that type. The runtime guard the alternative spends every method enforcing is gone because the type system has done the work once.

This axiom comes last because most code does not need it. A chapter-one engineer reaches for the [Axiom 21](axiom-21-state-machines.md) shape constantly — every entity with a status field is a state machine. Typestate is the type-level escalation, paid for in extra named types and the discipline of returning a new value from every transition. The payoff is real where the consequence of a wrong-order call is severe — silent authorization holes, leaked resources, half-built mutable objects — but for most domain logic, the value-level state machine of [Axiom 21](axiom-21-state-machines.md) already encodes enough.

---

## Definitions

A typestate is a discipline with three properties:

- **One named immutable type per state.** A record or a sealed-hierarchy variant whose data is fixed at construction ([Axiom 1](axiom-01-immutability.md)). When the entity has a single linear progression — opened then closed, draft then submitted — the states are separate records. When the entity has multiple variants of the same condition, a sealed interface with one record per variant ([Axiom 18](axiom-18-discriminated-unions.md)) is the shape, and each variant is its own typestate.

- **Transitions return a new type, not the same one.** The shape `S₁.Operation() → S₂` is the pattern: invoking the transition produces a value of the next state, leaving the input untouched. When the transition can fail, the return is `Result<S₂, string>` ([Axiom 13](axiom-13-result.md)) — the success branch carries the next state, the failure branch carries the reason. Mutation is not a transition; the old type does not become the new type, it is replaced by it.

- **Operations live on the type that permits them.** An `AuthenticationService` does not have a method valid only after authentication is done; instead it has a `Result<AuthenticatedSession, string> Authenticate(...)` method, then `AuthenticatedSession` has a `bool HasRole(...)` function. The caller's value either has the method or does not, by virtue of its current type. The compiler decides which methods are callable; the engineer does not check.

- **Construction is controlled — the transition is the only way in.** The guarantee holds only if callers cannot *fabricate* a state directly: a public constructor on `AuthenticatedSession` lets `new AuthenticatedSession(adminUser)` skip `Authenticate` entirely, and the security the typestate bought is gone. Make the state's constructor non-public so the only path to it is the transition — in C# an `internal` constructor on the record; in Java, whose records force a public canonical constructor, a `public final class` with a package-private constructor. This is the same construction-control [Axiom 15](axiom-15-value-objects.md) requires of value objects, raised from values to states. `private` is too strict: the transition that builds `S₂` lives on `S₁` — a *different* type — so the constructor must stay reachable within the assembly/package, not only from the state itself.

This axiom replaces three mainstream defaults:

- **The runtime guard at the top of every method.** `if (state != Approved) throw new InvalidOperationException("not approved")` before every method that needs a particular state. The guard is honest about the precondition but lives in the body, not the signature; every caller pays the cost of remembering, every test pays the cost of constructing an entity in the right state, and the compiler enforces nothing. The transition `Approved.Refund() → Refunded` puts the precondition in the type — there is no `Refund` to call when you do not have an `Approved`.

- **The status field plus a switch on it.** An enum field on the entity (`Status status`) with methods that pattern-match on it before deciding what to do. The dishonesty hides better than the throw because the check is fused with the work, but the cost is the same — every method that needs a particular state carries its own discrimination, every refactor risks the table drifting out of sync across the methods. Typestate hoists the discrimination into the type system once; every downstream method is total over the state it lives on.

- **The nullable field as state flag.** `endTime == null` means "still open"; populating it means "closed." The state lives in whether a value is null rather than in the type system; the reader has to know the convention, the compiler enforces nothing, and the entity carries fields that are valid only in some states. Promote the two conditions to two records — `OpenIssue` and `ClosedIssue` — and the nullable field disappears along with every check on it.

---

## Example

A login service whose `HasRole` method silently returns `false` when called before authentication. The state lives in a nullable `user` field; the method has no way to refuse a wrong-order call.

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
        var payload = Jwt.TryDecode(token);
        if (payload is not null)
            user = new User(payload.Subject, payload.Role);
    }

    public bool HasRole(string role) =>
        user?.Role == role;  // silently false when not authenticated
}

// Caller — wrong-order call compiles and silently misbehaves:
var auth = new AuthenticationService();
if (auth.HasRole("admin")) AdminAction();   // false; the missing
                                            // Login goes unnoticed
```

</td>
<td>

```java
public final class AuthenticationService {
    private User user;  // null until login

    public void login(String token) {
        Payload p = Jwt.tryDecode(token);
        if (p != null) this.user = new User(p.subject(), p.role());
    }

    public boolean hasRole(String role) {
        return user != null && user.role().equals(role);
    }
}

// Caller — wrong-order call compiles and silently misbehaves:
AuthenticationService auth = new AuthenticationService();
if (auth.hasRole("admin")) adminAction();   // false; the missing
                                            // login goes unnoticed
```

</td>
</tr>
</table>

The bug is not that `HasRole` is wrong — it is that calling `HasRole` before `Login` is a silent authorization hole that the type system permits. The fix puts the precondition into the type:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public class AuthenticationService
{
    public Result<AuthenticatedSession, string> Authenticate(string token)
    {
        var payload = Jwt.TryDecode(token);
        return payload is null
            ? new Failure<AuthenticatedSession, string>("invalid token")
            : new Success<AuthenticatedSession, string>(
                new AuthenticatedSession(new User(payload.Subject, payload.Role)));
    }
}

public sealed record AuthenticatedSession
{
    public User User { get; }
    // internal — only Authenticate (same assembly) can build one;
    // `new AuthenticatedSession(...)` won't compile for outside callers
    internal AuthenticatedSession(User user) => User = user;
    public bool HasRole(string role) => User.Role == role;
}

// Caller — the wrong-order call is gone from the language:
var auth = new AuthenticationService();
// auth.HasRole("admin");  // compile error — HasRole is not on
                           // AuthenticationService

var result = auth.Authenticate(token);
var response = result.Match(
    success: s => s.HasRole("admin")        // HasRole reachable only here
        ? AdminAction(s)
        : new HttpResponse(403, "forbidden"),
    failure: e => new HttpResponse(401, e));
```

</td>
<td>

```java
public final class AuthenticationService {
    public Result<AuthenticatedSession, String> authenticate(String token) {
        Payload p = Jwt.tryDecode(token);
        return p == null
            ? new Failure<>("invalid token")
            : new Success<>(new AuthenticatedSession(
                new User(p.subject(), p.role())));
    }
}

// A class, not a record: a public record's canonical constructor
// must be public, so it cannot block fabrication. A package-private
// constructor on a public final class can.
public final class AuthenticatedSession {
    private final User user;
    AuthenticatedSession(User user) {   // package-private — only
        this.user = user;               // authenticate() can build one
    }
    public boolean hasRole(String role) {
        return user.role().equals(role);
    }
}

// Caller — the wrong-order call is gone from the language:
AuthenticationService auth = new AuthenticationService();
// auth.hasRole("admin");  // compile error — hasRole is not on
                           // AuthenticationService

var result = auth.authenticate(token);
HttpResponse response = result.match(
    s -> s.hasRole("admin")                 // hasRole reachable only here
        ? adminAction(s)
        : new HttpResponse(403, "forbidden"),
    e -> new HttpResponse(401, e));
```

</td>
</tr>
</table>

`HasRole` no longer lives on `AuthenticationService`. The only way to obtain an `AuthenticatedSession` is `Authenticate`, which returns a `Result` ([Axiom 13](axiom-13-result.md)). Asking about roles before the result has been unwrapped on the success branch is not a runtime check that returns false — it is a method that does not exist on the value the caller is holding. The silent-false-from-the-bug class is gone, and so is every `if (user != null)` guard that used to defend against it.

The pattern recurs across domains. A connectivity issue with `endTime == null` meaning "open" is the same shape — two records (`OpenIssue` and `ClosedIssue`), each exposing only the operations valid for that condition: `OpenIssue.Close(timestamp) → ClosedIssue`, with the closing operation absent from `ClosedIssue` because it is already closed. A widget test page object whose methods all start with `if (!rendered) throw` is the same shape — two records, `UnrenderedWidget` and `RenderedWidget`, with the render call as the transition that produces the second and every other operation living on the second. In both cases the change collapses to two records and one transition function, and a class of runtime errors stops being expressible.

---

## Stacking parameters

A second shape worth naming. When each transition not only changes the type but also *carries information forward* in its generic parameters, you can build a fluent API whose final type encodes the entire sequence of choices made along the way. A SQL builder where `SELECT` returns a type carrying the column shape, `FROM` returns a type carrying that shape plus the table, `WHERE` returns a type carrying both plus the predicate, and the terminal `Build()` produces a query typed by the row shape:

```csharp
public sealed record Select<TRow>(IReadOnlyList<string> Columns)
{
    public From<TRow> FROM(string table) => new(Columns, table);
}

public sealed record From<TRow>(IReadOnlyList<string> Columns, string Table)
{
    public Where<TRow> WHERE(string predicate) => new(Columns, Table, predicate);
    public Query<TRow> Build() => new(Columns, Table, Predicate: null);
}

public sealed record Where<TRow>(
    IReadOnlyList<string> Columns, string Table, string Predicate)
{
    public Query<TRow> Build() => new(Columns, Table, Predicate);
}

public sealed record Query<TRow>(
    IReadOnlyList<string> Columns, string Table, string? Predicate);

// Caller — the row shape (int Id, string Name) flows through every step
// and is recoverable from the terminal type:
var q = new Select<(int Id, string Name)>(new[] { "Id", "Name" })
    .FROM("Users")
    .WHERE("Active = 1")
    .Build();
// q is Query<(int Id, string Name)> — the row shape is in the type.
```

The mechanics are identical to the headline pattern — each transition returns a new type — with the addition that the generic parameters accumulate. The same shape composes in Java with generics on records and sealed interfaces; the canonical large-scale example is jOOQ's DSL, where every fluent step is generic on the row type and the final `fetch()` returns a `Result<Record_N<…>>` whose parameters spell out the columns selected. The variant is heavier to write than the linear typestate (the type signatures grow loud, the IDE's hover tooltips become hard to read for callers, and static-language generic arity ceilings appear) but pays off when the carrier needs to *prove a structural property* about its accumulated data — that the columns selected match the columns the consumer expects, that the parameters bound match the parameters declared. In domain code the linear typestate without parameter accumulation is usually enough; the accumulating form lives in library and DSL territory.

---

## Stacking generic types

A third shape — and the one most readers have already used without naming it. The variant above carries a *fixed* type set (`TRow`) forward through the chain. This shape instead **stacks** type parameters: each transition produces a state with a *wider* generic signature than the last, and the terminal operation is generic over everything stacked along the way. The Given/When/Then test builder is the canonical instance — each rung adds to the arity:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public static class Scenario
{
    public static Arranged<TSut> Given<TSut>(Func<TSut> arrange)
        => new(arrange());
}

public sealed record Arranged<TSut>(TSut Sut)
{
    public Acted<TSut, TResult> When<TResult>(
        Func<TSut, TResult> act) => new(Sut, act(Sut));
}

public sealed record Acted<TSut, TResult>(TSut Sut, TResult Result)
{
    public void Then(Action<TSut, TResult> assert)
        => assert(Sut, Result);
}

// Each call adds a type; the terminal sees all of them:
Scenario.Given(() => new Calculator())  // Arranged<Calculator>
    .When(c => c.Add(2, 3))             // Acted<Calculator, int>
    .Then((sut, result) =>              // both in scope
        Assert.Equal(5, result));
```

</td>
<td>

```java
public final class Scenario {
    public static <TSut> Arranged<TSut> given(
            Supplier<TSut> arrange) {
        return new Arranged<>(arrange.get());
    }
}

public record Arranged<TSut>(TSut sut) {
    public <TResult> Acted<TSut, TResult> when(
            Function<TSut, TResult> act) {
        return new Acted<>(sut, act.apply(sut));
    }
}

public record Acted<TSut, TResult>(TSut sut, TResult result) {
    public void then(BiConsumer<TSut, TResult> assertion) {
        assertion.accept(sut, result);
    }
}

// Each call adds a type; the terminal sees all of them:
Scenario.given(() -> new Calculator())  // Arranged<Calculator>
    .when(c -> c.add(2, 3))             // Acted<Calculator, Integer>
    .then((sut, result) ->             // both in scope
        assertEquals(5, result));
```

</td>
</tr>
</table>

`Given` captures `TSut`; `When` adds `TResult`; `Then` is total over both — and, exactly as in the headline pattern, `When` does not exist before `Given` and `Then` does not exist before `When`. The crucial difference from the `RecordN` family that ends the SQL note: there is **no open-ended arity to pre-declare**. The number of states is fixed by the domain — a scenario has three rungs — so you write exactly the types you need, and the generic arity ceiling never enters the picture.

The example stacks **one** type per step only for clarity; the technique imposes no such limit. A single transition can add several at once — a `Where<TSut, TResult, TError>` rung that introduces two new parameters in one move is just as valid. Each state declares whatever generic signature its data and operations require; "stacking" is about the arity *growing* down the chain, not about the size of any one step.

The payoff is sharpest when a *later* step must be **type-checked against an earlier step's capture**, and two mainstream C#/Java libraries show it without leaving the languages this playbook targets:

- **FluentValidation (C#).** `RuleFor(x => x.Age)` returns an `IRuleBuilder<TModel, int>` — the property type is captured from the selector — and the rules that follow are checked against it: `.GreaterThan(0)` compiles, while `.Length(1, 5)` (a string-only rule) on an `int` property does not. The named first stage fixes a type the rest of the chain must respect.
- **Moq (C#) / Mockito (Java).** `mock.Setup(x => x.Parse("a"))` / `when(mock.parse("a"))` captures the method's return type into `ISetup<T, int>` / `OngoingStubbing<Integer>`, and the following `.Returns(...)` / `.thenReturn(...)` will not compile unless the value matches what was captured. `Setup`/`when` and `Returns`/`thenReturn` are different states, and the captured type carries from the first to the second.

As with the carry-forward variant above, this lives in library, DSL, and test-harness territory — reach for it when a later operation genuinely needs to be checked against an earlier choice. In ordinary domain lifecycle code the linear typestate, with no generics to stack, is enough.

---

## Problem / forces

When a class has methods whose validity depends on prior calls, five shapes recur:

1. **Runtime guard at the top of every method.** `if (state != Open) throw ...`. The precondition is honest but lives in the body. Every caller pays the cost of remembering; every test pays the cost of constructing the entity in the right state; refactoring drift accumulates because the guards live in N methods instead of one place.

2. **Status field with switch-on-status method bodies.** Same as 1, but the discrimination is fused into each method's body. Reads as a centralised state machine without being one — every method is a tiny `Transition` over the field, with no compiler enforcement that the table is total.

3. **Nullable field as state flag.** `endTime == null` for open, populated for closed. The fields valid in one state are nullable in others; the convention is documentation, not type. The pattern is sometimes called a *tombstone field* or *state-by-absence*, and one such field accumulates per state distinction.

4. **A value-level state machine** ([Axiom 21](axiom-21-state-machines.md)). One sealed DU of states, one pure `Transition` function. The legal transitions move into the type system at the *event* level; the methods on the entity become a thin shell over `Transition`. This is the playbook's default for entities whose state changes through named commands.

5. **A typestate.** Each state is its own type; transitions return the next type; operations valid in one state live only on that state's type. The runtime guards disappear because the calls that would have failed them cannot be written.

Options 1–3 share one cost: the rule lives in conventions the compiler does not check, and every method pays the cost of enforcing it. Option 4 hoists the rule into a pure function but the entity remains a single type with internal discrimination on the state field. Option 5 hoists the rule into the type system itself; the discrimination disappears because each operation lives on the type that permits it.

The trade-off curve between 4 and 5 is not "use one for state machines and the other for typestate" — both encode state machines. It is "do the operations valid in each state belong to *one* type with internal discrimination, or to *separate* types with no discrimination needed?" The single-type form (4) reads naturally when most operations are valid in most states (the discrimination is the exception, not the rule). The separate-type form (5) reads naturally when each state has a *different* set of legal operations and the cost of the wrong-order call is severe — silent security holes, leaked resources, half-built mutable objects.

---

## Why

**1. Illegal sequences cannot compile.**
The `HasRole` method does not exist on `AuthenticationService`. There is no path to calling it without first calling `Authenticate` and pattern-matching the `Success` branch. The runtime guard the alternative spends every method enforcing is gone because the call that would have triggered it is not in the language.

**2. The signature documents the precondition.**
A function whose parameter type is `AuthenticatedSession` is honest in a way a function whose parameter is `AuthenticationService` cannot be — the signature documents that the function expects an authenticated session. The reader does not have to read the body to discover the precondition; the type carries it. The same property [Axiom 15](axiom-15-value-objects.md) gave to values, applied to call sequences.

**3. The runtime guards disappear, and with them their drift.**
A guard in N methods drifts into N slightly different guards over time. A single transition function whose return type carries the new state has one place where the rule lives. Test suites shrink because the no-longer-possible cases stop being worth testing; review surfaces shrink because the no-longer-possible classes of bug stop being worth scanning for.

**4. The composition root holds the typestate value.**
A long-lived shell ([Axiom 23](axiom-23-stateful-shell.md)) that holds an `AuthenticatedSession` instead of a nullable `User?` field has a smaller surface for the rest of the program to misuse. Stateful resources held in the shell are typed by what they are, not by what they might be — and the shell's seams to the pure core ([Axiom 9](axiom-09-impureheim.md)) carry the same guarantee.

---

## Trade-offs

**The old reference does not vanish.** In C# and Java, when a transition `s.Submit() → Submitted` is called, the caller still holds the original `s`. The compiler does not erase the pre-transition reference the way Rust's ownership does — `s.Submit(); s.Submit();` compiles and runs both calls. The mitigation is structural: make the pre-transition types behaviour-light (a record with no methods to misuse beyond the transition itself) so that holding the old reference does no work. When the requirement is "the old reference must not be usable," typestate alone is not enough — the operation has to physically destroy the source, which neither C# nor Java offers as a language feature.

**Persistence requires materialisation discipline.** An entity loaded from a database arrives as a row, not as a typed `OpenIssue` or `ClosedIssue`. The repository's job is to read the row, inspect a discriminator (a status column, or the presence of an `end_time`), and return the right subtype. Without that discipline, persistence punches a hole through the typestate — values arrive into the program as the wrong type and the guarantee is gone. The boundary is the same one [Axiom 15](axiom-15-value-objects.md) named for value objects; typestate joins the queue of types whose construction must be controlled at the boundary. This is also why the controlled constructor is `internal` / package-private rather than fully sealed away: the repository is the one place outside the transitions allowed to build a state, so it has to live in the same assembly/package as the states it materialises.

**Vocabulary cost grows with the number of states.** Each state is a separate type. An entity with five states declares five types and the transition functions between them. The investment is real and proportional to the entity's lifecycle; in return, every method below the type boundary is total over the state it lives on, with no internal discrimination. The trade-off is the same one [Axiom 15](axiom-15-value-objects.md) and [Axiom 21](axiom-21-state-machines.md) drew at the value and machine levels — small immediate cost in named types, ongoing payoff in the methods that consume them.

**The accumulating-generics variant is heavier.** When each transition also accumulates type parameters (the SQL-DSL shape), the type signatures grow long and the IDE's hover tooltips become hard for the consumer to read. Static languages also impose arity ceilings on generics (Java's `Function` interfaces top out at a handful of parameters; nested forms take over above that). The variant earns its keep in library and DSL territory; in domain code, the linear typestate without parameter accumulation is usually enough.

---

## When NOT to

**Required-fields-only construction.** When the goal is "the caller must supply A, B, and C before the object can be used," the answer is a constructor that takes all three, or a record with mandatory components, or — in C# 11+ — the `required` modifier. Spinning up a step-builder chain just to enforce the three fields are set is ceremony around a problem the type system can solve in one line. This axiom is for *ordering*, not for required initialisation. The two smells feel similar — "the compiler doesn't catch this" — but their fixes diverge: required init is a constructor concern, ordering is a transition concern.

**Two-state machines with low blast radius.** A widget builder where the only states are "not built" and "built" earns the typestate refactor only if the wrong-order call is harmful. A double-build that idempotently does nothing is not worth a new type pair to prevent.

**Framework-controlled lifecycles.** A Web Component's `connectedCallback` is invoked by the browser; the framework owns the lifecycle. A typestate that gates "do not call this before connectedCallback" cannot help because the framework, not the engineer, decides when methods run. The right fix is to *queue* the calls that arrive too early and *flush* them when the lifecycle event arrives — a runtime concern the framework expects.

**Tree-structural constraints.** A React hook that must be called inside a `Provider` is constrained by the React tree, not by the value's type. The runtime throw — "useX must be used within an XProvider" — is the established idiom because the type system has no view of the component tree. Typestate's reach stops at the boundary of the value's identity; it cannot enforce relationships between values in a tree.

**A value-level state machine suffices.** When most operations are valid in most states and the wrong-order call is mild (a no-op, a 409, a logged warning), [Axiom 21](axiom-21-state-machines.md) is the cheaper tool. The single-`Transition` function gives you the state-to-state mapping in the type system at the *event* level already, and the methods on the entity stay on one type. Promote to typestate only when separating the operations by state genuinely helps the reader.

---

## References

[1] **Robert E. Strom & Shaula Yemini**, *Typestate: A Programming Language Concept for Enhancing Software Reliability*, IEEE Transactions on Software Engineering 12(1):157–171, 1986 — formalising work first done in IBM's Network Implementation Language (NIL), 1983. The original treatment of typestate as "an instance of a type's lifecycle progression that the language checks at compile time, ensuring operations are applied only to properly initialised data." The technique predates "make illegal states unrepresentable" by over twenty years and the OO renaissance of typed FP by nearly as long.

[2] **Andrew Hunt & David Thomas**, *The Pragmatic Programmer: From Journeyman to Master*, Addison-Wesley, 1999 — chapter "Breaking Temporal Coupling." Names the smell — when ordering exists in convention but not in the type system, it is *temporal coupling*. The book frames the fix as "design for sequence to be obvious or eliminated"; this axiom is the type-level form of that prescription.
<https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/>

[3] **Yaron Minsky**, *Effective ML*, Jane Street technical talks and writing, 2010. Cross-listed from [Axiom 5](axiom-05-honest-total-signatures.md), [Axiom 15](axiom-15-value-objects.md), [Axiom 18](axiom-18-discriminated-unions.md), and [Axiom 19](axiom-19-illegal-states.md). The "make illegal states unrepresentable" slogan as applied to *call sequences* is this axiom; as applied to values is [Axiom 15](axiom-15-value-objects.md); as applied to a record's *shape* is [Axiom 19](axiom-19-illegal-states.md); as applied to outcomes is [Axiom 18](axiom-18-discriminated-unions.md). Slices of the same principle.

[4] **Cliff Biffle**, *The Typestate Pattern in Rust*, cliffle.com, 2019. The canonical modern treatment in a language that gives typestate native support through ownership. Cross-listed for honesty: the linearity property Rust gives for free is the gap C#/Java carry, named in the Trade-offs section above. The axiom's idea is the same — types per state, transitions consume input — minus the consumption.
<https://cliffle.com/blog/rust-typestate/>

[5] **Adam Rodger**, *The Typestate Pattern in C# (PactNet)*, adamrodger.com, 2021. A reference implementation in C# of a multi-step interface-chained typestate: each interface represents a valid state, transitions return the next interface, and methods invalid from the current state simply do not exist on it. The shape this axiom's headline example draws on, transposed from chained interfaces to records.
<https://adamrodger.com/post/2021-10-13-typestate-pattern-in-csharp/>

[6] **Lukas Eder et al.**, *jOOQ — The Easiest Way to Write SQL in Java*. The reference implementation of the accumulating-generics variant at scale: each fluent step returns a step-typed result whose generic parameters carry the column shape forward, so `select(A, B).from(T).where(...).fetch()` returns a `Result<Record2<A, B>>` rather than a `Result<Object[]>`. The shape the SQL-DSL sketch above derives from.
<https://www.jooq.org/>

[7] **Jeremy Skinner et al.**, *FluentValidation*. A mainstream C# reference implementation of the stacking-generic-types variant: `RuleFor(x => x.Property)` returns an `IRuleBuilder<T, TProperty>` that captures the selected property's type, and the rule methods chained after it are constrained against that captured type — a string rule on a numeric property does not compile. The everyday face of the variant, alongside Moq's and Mockito's `Setup`/`when` → `Returns`/`thenReturn` chains.
<https://docs.fluentvalidation.net/>
