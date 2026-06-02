# Axiom 23 — Pure functions returning actions

**A pure function decides *what should happen* and returns a discriminated union of actions; the impure shell pattern-matches on the returned action and executes the side effect it names — the sandwich from [Axiom 12](axiom-12-impureheim.md) delivered in full.**

- The pure core's return type is a sealed DU of actions — `AddLine`, `IncreaseLine`, `Rejected`, and so on.
- Each variant is an immutable record carrying exactly the data the shell needs to execute that arm.
- The shell is a per-arm dispatcher: one pattern match, one effect per arm, no further decisions.
- Decision is data; execution is the boundary.
- Decisions are business logic. Effects are infrastructure.

[Axiom 21](axiom-21-discriminated-unions.md) named the general sealed-DU shape — N honest outcomes, one variant per outcome, exhaustively pattern-matched. [Axiom 12](axiom-12-impureheim.md) sketched the sandwich — effects at the edges, pure logic in the middle. This axiom is the meeting point: when the pure middle's job is to decide *what the shell should do next*, the most honest return type is a DU whose variants are the things the shell is allowed to do. The structural foreshadowing in [Axiom 5](axiom-05-pure-functions.md) — `DecideAdd(cart, product, quantity) -> CartDecision` with `AddLine | IncreaseLine | Rejected` — was this axiom. Now the pattern has its name.

Through [Axiom 8](axiom-08-connascence.md)'s lens, this axiom weakens a [Connascence of Meaning](axiom-08-connascence.md#connascence-of-meaning-com) — the status string or flag the shell must decode back into *what to do* — into a Connascence of Type.

---

## Definitions

An **action** is:

- A variant of a sealed DU whose only purpose is to *describe an effect for the shell to execute*.
- A plain immutable record carrying exactly the data needed to perform that effect — no more.
- Itself a value: composable, serialisable, loggable. The action *is* the description; running it lives somewhere else.

A **pure function returning actions** is:

- A function whose body is pure ([Axiom 5](axiom-05-pure-functions.md)) — no clock reads, no I/O, no mutation, no `throw`.
- All required context (the current state, looked-up entities, the wall clock, configuration) is passed in as parameters.
- The returned value is not the result of an effect — it is the *description* of the effect.

The shell is then a per-variant dispatcher: pattern-match ([Axiom 11](axiom-11-pattern-matching.md)) on the returned action and run the matching effect. Each match arm contains one kind of work — `Insert`, `Update`, `Respond` — never *another decision*.

The split makes a previously-tangled choice explicit:

- *What* should happen lives in the pure core.
- *That it happens* lives at the boundary.

A method that did both — read context, decide, act — has split in two: this is **Command–Query Separation** ([Axiom 12](axiom-12-impureheim.md)) carried to its conclusion — rather than keep one method honest, the query (`DecideAdd`, which returns a value) and the command (the shell's execute, which returns nothing) become *different functions*. The two halves now have different colours (pure / impure), different testability, and different reasons to change. The type system holds the seam: every variant the core can produce is a variant the shell must handle, and the compiler refuses anything else.

This split is the precise inversion of the OO maxim **Tell, Don't Ask** — [Axiom 1](axiom-01-data-vs-behaviour.md)'s road not taken. Tell-Don't-Ask *fuses* deciding and acting into one call: `account.withdraw(amount)` decides whether the withdrawal is allowed *and* performs it, and the whole point is that the caller never sees the decision. This axiom does the opposite on purpose — the decision (`DecideAdd`, a pure query returning a value) and the act (the shell's execute, an impure command returning nothing) become *different functions*. What Tell-Don't-Ask brands as the smell — pull the state out, decide outside the object — is here the deliberate first half of the sandwich: the gather-and-decide that produces an action value. The two are not really in conflict; they answer different premises. Tell-Don't-Ask protects *mutable* state by never letting a caller get between a read and a write; this axiom has no such gap to protect, because the gathered state is an immutable value and the only write is the shell executing the returned action. Splitting the decision back out is what makes it a value you can log, replay, and test without a database — exactly what fusing it into a self-mutating method forecloses.

---

## Example

A small pure decision: `DecideAdd(cart, productId, quantity) -> CartAction`. Three honest outcomes — add a new line, increase an existing line, reject — modeled as a sealed hierarchy ([Axiom 21](axiom-21-discriminated-unions.md)).

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed record CartLine(ProductId ProductId, int Quantity);
public sealed record Cart(IReadOnlyList<CartLine> Lines);

public abstract record CartAction;
public sealed record AddLine(ProductId ProductId, int Quantity)         : CartAction;
public sealed record IncreaseLine(ProductId ProductId, int NewQuantity) : CartAction;
public sealed record Rejected(string Reason)                            : CartAction;

public static CartAction DecideAdd(Cart cart, ProductId pid, int quantity)
{
    if (quantity <= 0)
        return new Rejected("quantity must be positive");

    return cart.Lines.FirstOrDefault(l => l.ProductId == pid) is { } existing
        ? new IncreaseLine(pid, existing.Quantity + quantity)
        : new AddLine(pid, quantity);
}
```

</td>
<td>

```java
public record CartLine(ProductId productId, int quantity) {}
public record Cart(List<CartLine> lines) {}

public sealed interface CartAction
    permits AddLine, IncreaseLine, Rejected {}

public record AddLine(ProductId productId, int quantity)         implements CartAction {}
public record IncreaseLine(ProductId productId, int newQuantity) implements CartAction {}
public record Rejected(String reason)                            implements CartAction {}

public static CartAction decideAdd(Cart cart, ProductId pid, int quantity) {
    if (quantity <= 0)
        return new Rejected("quantity must be positive");

    return cart.lines().stream()
        .filter(l -> l.productId().equals(pid))
        .findFirst()
        .<CartAction>map(l -> new IncreaseLine(pid, l.quantity() + quantity))
        .orElseGet(() -> new AddLine(pid, quantity));
}
```

</td>
</tr>
</table>

`DecideAdd` is pure — three inputs, one returned action; no DB read, no log, no `throw`. The returned action is a *value* the caller can hold, log, replay, or execute. The arms of `CartAction` declare what the caller is allowed to do; anything outside that set is unrepresentable. A reviewer looking at `DecideAdd` sees the rule; a reviewer looking at the shell will see the effect; the seam between them is the type `CartAction`.

The shell that executes it:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public void Execute(CartId id, CartAction action)
{
    Action effect = action switch
    {
        AddLine a      => () => db.InsertLine(id, a.ProductId, a.Quantity),
        IncreaseLine i => () => db.UpdateLineQuantity(id, i.ProductId, i.NewQuantity),
        Rejected r     => () => log.Warn("cart {Id} rejected: {Reason}", id, r.Reason)
    };
    effect();
}
```

</td>
<td>

```java
public void execute(CartId id, CartAction action) {
    switch (action) {
        case AddLine a      -> db.insertLine(id, a.productId(), a.quantity());
        case IncreaseLine i -> db.updateLineQuantity(id, i.productId(), i.newQuantity());
        case Rejected r     -> log.warn("cart {} rejected: {}", id, r.reason());
    }
}
```

</td>
</tr>
</table>

Three arms, three effects, one expression. No `if`-ladder, no nested decision, no second pure call hidden inside an effect. Pure decision → action value → impure dispatch.

---

## The synthesis

This is the sandwich [Axiom 12](axiom-12-impureheim.md) sketched, in full: the impure shell loads state from the world, the pure core decides on an action, the impure shell dispatches the action and responds.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed record HttpResponse(int Status, string Body);

public HttpResponse AddProductEndpoint(CartId id, ProductId pid, int quantity)
{
    Cart cart         = cartStore.Load(id);                   // impure: DB read

    CartAction action = DecideAdd(cart, pid, quantity);       // pure: decide

    return action switch                                      // impure: dispatch
    {
        AddLine a      => Persist(id, a),
        IncreaseLine i => Persist(id, i),
        Rejected r     => new HttpResponse(400, r.Reason)
    };
}

private HttpResponse Persist(CartId id, AddLine a)
{
    cartStore.InsertLine(id, a.ProductId, a.Quantity);
    return new HttpResponse(200, $"added {a.Quantity} × {a.ProductId}");
}

private HttpResponse Persist(CartId id, IncreaseLine i)
{
    cartStore.UpdateLineQuantity(id, i.ProductId, i.NewQuantity);
    return new HttpResponse(200, $"line {i.ProductId} now {i.NewQuantity}");
}
```

</td>
<td>

```java
public record HttpResponse(int status, String body) {}

public HttpResponse addProductEndpoint(CartId id, ProductId pid, int quantity) {
    Cart cart         = cartStore.load(id);                   // impure: DB read
    
    CartAction action = decideAdd(cart, pid, quantity);       // pure: decide

    return switch (action) {                                  // impure: dispatch
        case AddLine a      -> persist(id, a);
        case IncreaseLine i -> persist(id, i);
        case Rejected r     -> new HttpResponse(400, r.reason());
    };
}

private HttpResponse persist(CartId id, AddLine a) {
    cartStore.insertLine(id, a.productId(), a.quantity());
    return new HttpResponse(200, "added " + a.quantity() + " × " + a.productId());
}

private HttpResponse persist(CartId id, IncreaseLine i) {
    cartStore.updateLineQuantity(id, i.productId(), i.newQuantity());
    return new HttpResponse(200, "line " + i.productId() + " now " + i.newQuantity());
}
```

</td>
</tr>
</table>

Read the picture from top to bottom and every prior axiom is visible at its post:

- **Data, immutable, separate from behaviour** ([Axiom 1](axiom-01-data-vs-behaviour.md), [Axiom 2](axiom-02-immutability.md)). `Cart`, `CartLine`, `CartAction` and every variant are immutable records. The cart does not own `AddProduct`; the function `DecideAdd` operates on the cart.
- **Effects are named and contained** ([Axiom 3](axiom-03-side-effects.md), [Axiom 4](axiom-04-impure-functions.md)). The `cartStore.Load` and `cartStore.Insert/Update` calls are the only effects in the listing — one at the top, two at the bottom. The middle is structurally pure.
- **The decision is pure** ([Axiom 5](axiom-05-pure-functions.md)). `DecideAdd(cart, pid, quantity)` is the same function the structural foreshadowing in Axiom 5 promised. Three inputs, one returned action; same triple in, same value out.
- **The signature is honest and total** ([Axiom 6](axiom-06-honest-total-signatures.md)). `DecideAdd` returns one of three named outcomes. There is no `null`, no exception, no out-parameter; the rejected case is *part of the return type*.
- **Functions are values; functions over functions are the glue** ([Axiom 9](axiom-09-first-class-functions.md), [Axiom 10](axiom-10-higher-order-functions.md)). The shell's dispatch is a pattern match — equivalently, a higher-order operation that selects which effect-function to run based on the action's shape. The Java `findFirst` and C# `FirstOrDefault` used inside `DecideAdd` are HOFs over the lines.
- **Pattern matching consumes the action** ([Axiom 11](axiom-11-pattern-matching.md)). One match, three arms; add a variant and the compiler points at every shell that does not yet handle it.
- **The whole function is the Impureheim sandwich** ([Axiom 12](axiom-12-impureheim.md)). Load → decide → execute. The pure middle is what changes between business decisions; the impure top and bottom stay the same.
- **Absence and 2-case outcomes have their named container types** ([Axiom 13](axiom-13-maybe.md), [Axiom 14](axiom-14-either.md), [Axiom 16](axiom-16-result.md)). Java's `Optional.findFirst` inside `DecideAdd` is exactly the Maybe shape — a missing line is a value, not `null`. The action DU is the same machinery generalised: where `Result<T, E>` discriminates two cases (success / failure), `CartAction` discriminates three (and could discriminate seven).
- **Unit is the shape when nothing meaningful is returned** ([Axiom 15](axiom-15-unit.md)). Here the shell produces an `HttpResponse`; a fire-and-forget message handler would return `Unit` and the dispatcher's arms would just execute their effects.
- **Combinators glue Result-shaped pipelines** ([Axiom 17](axiom-17-result-combinators.md), [Axiom 19](axiom-19-railway.md)). A railway returned a `Result<T, string>` and the shell did a 2-arm match: write a row, or log the reason. This axiom returns a `CartAction` and the shell does a 3-arm dispatch: insert, update, or respond. Structurally the same shape — pure core returns a sum type; impure shell dispatches each arm — just at higher arity, with each arm naming a different *effect* rather than the same effect with different data.
- **Each fallible step is still a smart constructor when one applies** ([Axiom 18](axiom-18-value-objects.md)). `ProductId` is a value object with a `From` factory; here it arrives as a typed value, already constructed. The pure core can rely on its invariants.
- **Validation accumulates many failures when many fields are validated** ([Axiom 20](axiom-20-validation.md)). When a command has multiple independent fields, the shell would run the accumulating combinator first and only call `DecideAdd` with already-validated inputs. Validation feeds the action DU; the action DU is downstream of it.
- **The action DU is the general N-outcome shape** ([Axiom 21](axiom-21-discriminated-unions.md)). `CartAction = AddLine | IncreaseLine | Rejected` is the operational form of Axiom 21 in its action role: the variants are not facts about an outcome (as `PaymentOutcome` was), but *instructions* for the next step. Same machinery, different intent.

The payoff: the file reads as the rule it enforces. *DecideAdd decides; the shell does.* When the rules change, you edit `DecideAdd` and `CartAction` — the shell stays where it is, because its job is dispatch, not decision. When the effects change (the DB driver, the response format), you edit the shell — `DecideAdd` stays where it is, because its job is rules, not execution. The two halves change for different reasons and the type system holds the seam between them.

---

## Problem / forces

When a function's job is to figure out *what should happen* and then *make it happen*, five shapes recur:

1. **Inline effects.** The method reads from the DB, applies the rule, writes back, and logs all in one body. The dominant transaction-script shape — reads naturally line by line, and each method is "complete" on its own. Pays the costs [Axiom 5](axiom-05-pure-functions.md) named: the function is impure throughout, its tests need the DB, and the signature lies about every effect the body triggers.
2. **Return a boolean or status string and let the caller execute.** The method does the read, decides, and returns `"added"`/`"increased"`/`"rejected: cart is full"` as a string; the caller switches on the string. The decision is partly extracted, but the *interface* between core and shell carries the stringly-typed dishonesty [Axiom 16](axiom-16-result.md) named — the caller parses what to do back out of a string.
3. **Return a tuple `(status, payload, reason)` with optional fields.** Closer to the goal — the caller now has structured outcomes — but each per-variant payload sits in an optional field that is valid only when `status` is set the right way. The per-combination contract is a runtime convention, exactly the dishonesty [Axiom 21](axiom-21-discriminated-unions.md) catalogued.
4. **The Command pattern (the GoF object form).** An object encapsulating "the work to do" with an `Execute()` method that the caller invokes. The OO encoding of "behaviour as a value" ([Axiom 9](axiom-09-first-class-functions.md)) at the *imperative* side: each command type holds its own effect and runs itself. A long-standing option that is appropriate when the work belongs to the variant — the implementation of "what to do" lives next to the description, and the dispatcher does not need to grow when a new command type appears.
5. **The action DU.** The function returns one variant of a sealed DU; each variant carries exactly the data the shell needs to execute its arm. The shell pattern-matches once and dispatches. Pure decision, structured handoff, impure execution.

Options 1–3 share one cost: the *decision* is entangled with *execution*. In 1 they are literally interleaved; in 2 they communicate through a string; in 3 they communicate through an optional-field-soup record. The action DU separates them by typing the seam: the description of what to do *is* the return value, and the type system enforces that every arm of the shell handles every variant.

Options 4 and 5 are both honest separations of *describing* from *doing*. The choice between them is the one [Axiom 11](axiom-11-pattern-matching.md) and [Axiom 21](axiom-21-discriminated-unions.md) drew: the Command pattern keeps the implementation next to the variant (a virtual `Execute` per command class); the action DU centralises the dispatch in the consumer (a pattern match per shell). Both are right in their setting — the action DU is the playbook's default because the variants are *data*, the shells that consume them often differ (HTTP, queue, console), and a value composes more freely than an object with a non-overridable method.

---

## Why

What the action-DU shape gets right that inline effects, the stringly-typed status, and the optional-field tuple do not:

**1. Decision and execution have different testability requirements.**
A pure `DecideAdd` is tested by a table: given a cart and a quantity, expect this action variant with these fields. No DB, no clock, no mocks. The shell is tested by *integration* — given an action variant, the right SQL ran. The two tests live in different suites because their cost profiles are different; the action DU is what lets them be different.

**2. Adding a business rule does not touch the shell.**
A new rule — "reject if the customer is suspended" — adds an `if` to `DecideAdd` and possibly one constructor call for an existing or new `Rejected` variant. The shell's arms still fit; no SQL changes, no shell tests rewritten. The rule lives where rules live.

**3. Changing the storage backend does not touch the rules.**
Swap PostgreSQL for SQLite, swap synchronous writes for an outbox table — these touch the `Persist` methods and nothing else. `DecideAdd` does not know that storage exists. Two reasons to change, two places to edit, no third place that has to be touched for both.

**4. The action becomes a value.**
Actions can be logged ("here is what the cart engine decided"), replayed (apply the same action against a different store), enqueued (write the action to a queue and let a worker dispatch it), or sent over the wire (serialise to JSON). None of this works on inline-effect code; all of it works on an action DU for free.

**5. The shell's job becomes mechanical.**
A pattern match over a DU is some of the most predictable code in the codebase: one arm per variant, each arm doing one thing. The shell stops being a place where logic hides and becomes a place where wiring lives. That is exactly the inversion the sandwich from [Axiom 12](axiom-12-impureheim.md) asked for — thin shell, fat core.

---

## Trade-offs

**The action DU adds vocabulary.** Each business decision now declares two types: the input shape (a command record, or the parameters of `Decide`) and the output DU. A handler that did one thing inline now declares `CartAction`, three variants, and a dispatcher. For one such handler the cost is real; for the tenth, the pattern is grooved and the cost is muscle memory.

**Boundary-only data sneaks in.** An `HttpResponse` is *not* an action — it is an output-format detail. Putting it inside the action DU couples the decision to its presentation. The discipline is: actions describe *the work the shell does in the program's domain* (insert the row, update the field, publish the event); the shell then maps each arm to the boundary's representation (HTTP body, queue payload, console line). The synthesis above keeps the boundary mapping in the shell's match arms, not in `CartAction`.

**Multi-effect actions need a list, not nesting.** Sometimes a decision means "insert a row and publish an event." Two reasonable shapes: a `Compound(IReadOnlyList<CartAction>)` variant that the shell flattens, or `IReadOnlyList<CartAction>` from `Decide` and the shell iterates. Both are fine; the second composes more cleanly because the shell's match-arm body is "do one thing" regardless of how many actions arrived. Prefer the list when this shape is common.

**Some operations belong on the variant, not the shell.** Same trade-off [Axiom 11](axiom-11-pattern-matching.md) drew and [Axiom 21](axiom-21-discriminated-unions.md) inherited. If every shell that handles `CartAction` does the same per-variant rendering — *render* is intrinsic to the action — a virtual method per variant keeps the implementation next to its data. Pattern matching centralises; virtual methods distribute. Each is right in its setting; the playbook's default is pattern matching because the *consumers* usually differ even when the actions do not.

**The pure core grows with the rule set.** When a domain has fifteen rules and four overlapping action types, `DecideAdd` becomes a long function. The remedy is not to make it impure — it is to factor the decision into smaller pure helpers, each returning `CartAction` or a partial classification, that the top-level `Decide` combines. Pure functions compose; long pure functions decompose into shorter pure functions.

---

## When NOT to

**The function produces one value and the shell is trivial.** A pure `TotalWithTax(items, rate) -> decimal` is consumed by code that does one thing with the number (write it into a response). Wrapping the decimal in `Compute(amount)` ceremony — there is no second case for the action DU to discriminate.

**The "effect" is a return value the caller already needed.** When `Decide` returns a domain object — `Order`, `Invoice` — and the shell's job is to *use* that object, the object is the answer, not an action. The action DU is for the case where the shell needs to *do* one of several different things; if the shell does the same thing every time with the returned value, the action DU is just a relabelled `T`.

**The variants are open.** Same constraint [Axiom 21](axiom-21-discriminated-unions.md) named: the action DU requires the full set of variants to live in one place. A plugin host where actions arrive from external modules wants polymorphism (a `Command` interface with `Execute()`), not a sealed hierarchy — the trade-off-curve choice from Problem / forces, swung the other way by the openness requirement.

**Tightly-coupled single-rule scripts.** A 200-line cron job that loads one row, runs one rule, and writes one row may not earn the action-DU keep. The split between core and shell pays off as the rule set grows; for a single-rule script the inline form is simpler and the cost is bounded.

---

## References

[1] **Yehonathan Sharvit**, *Data-Oriented Programming: Reduce software complexity*, Manning Publications, 2022. Cross-listed from [Axiom 1](axiom-01-data-vs-behaviour.md), [Axiom 2](axiom-02-immutability.md), [Axiom 13](axiom-13-maybe.md), [Axiom 14](axiom-14-either.md), and [Axiom 21](axiom-21-discriminated-unions.md). The core DOP principle "represent code as data" is the ancestor of returning actions as values; Sharvit's chapters on representing operations as immutable maps and dispatching them at the boundary are the data-oriented form of this axiom.
<https://www.manning.com/books/data-oriented-programming>

[2] **Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides**, *Design Patterns: Elements of Reusable Object-Oriented Software*, Addison-Wesley, 1994 — the **Command** pattern. Cross-listed from [Axiom 9](axiom-09-first-class-functions.md) and [Axiom 11](axiom-11-pattern-matching.md). The canonical OO reference for separating *describing* the work from *executing* it: a command object holds the parameters of the work and exposes an `Execute()` method that the caller invokes. The action DU is the data-oriented sibling — same separation, with the description as a value pattern-matched at one site rather than an object with a virtual method dispatched per instance.

[3] **Eric Evans**, *Domain-Driven Design: Tackling Complexity in the Heart of Software*, Addison-Wesley, 2003. Domain events as first-class values: when the domain names *the things that happen*, those things deserve to be types. An action is the imperative-tense sibling of an event (the past tense): `AddLine` describes what to do; `LineAdded` describes what just happened. Both are values; the difference is tense.
<https://www.domainlanguage.com/ddd/>

[4] **Mark Seemann**, *An Impureim Sandwich*, blog.ploeh.dk, 2020. Cross-listed from [Axiom 12](axiom-12-impureheim.md). The sandwich shape — impure / pure / impure — is the architectural form this axiom inhabits. The synthesis example above is the sandwich in its most type-driven form: the impure shell loads, the pure core decides, the impure shell dispatches an action whose type was authored by the pure core.
<https://blog.ploeh.dk/2020/03/02/impureim-sandwich/>

[5] **Eric Normand**, *Grokking Simplicity*, Manning Publications, 2021. Cross-listed from [Axiom 4](axiom-04-impure-functions.md) and [Axiom 5](axiom-05-pure-functions.md). Normand's *action / calculation / data* taxonomy puts the same split in three words: a calculation produces data; an action consumes it. The pure-functions-returning-actions axiom is the structural form of that taxonomy — the calculation produces a piece of *data describing an action*, and the action consumes it.
<https://www.manning.com/books/grokking-simplicity>

[6] **Scott Wlaschin**, *Domain Modeling Made Functional*, Pragmatic Bookshelf, 2018. Cross-listed from [Axiom 16](axiom-16-result.md), [Axiom 17](axiom-17-result-combinators.md), [Axiom 18](axiom-18-value-objects.md), [Axiom 19](axiom-19-railway.md), and [Axiom 20](axiom-20-validation.md). The book's *workflow* chapters end with a pure function returning a typed outcome and an outer shell dispatching by case — the F# original of this axiom's C# / Java treatment.
<https://pragprog.com/titles/swdddf/domain-modeling-made-functional/>

---

← Previous: [Axiom 22 — Make illegal states unrepresentable](axiom-22-illegal-states.md) · Next: [Axiom 24 — State machines](axiom-24-state-machines.md) →
