# Axiom 24 — Pure functions returning actions

**A pure function decides *what should happen* and returns it as a discriminated union of actions. The impure shell matches on the action and carries out the effect it names. This is the sandwich of [Axiom 13](axiom-13-impureim.md), delivered in full [4].**

- The core returns a sealed DU of actions: `AddLine`, `IncreaseLine`, `Rejected`.
- Each action is an immutable record with exactly the data the shell needs to carry it out.
- The shell matches once and runs one effect per branch. It makes no further decisions.
- The decision is business logic; the effect is infrastructure.

[Axiom 13](axiom-13-impureim.md) sketched the shape: effects at the edges, decisions in the middle. [Axiom 22](axiom-22-discriminated-unions.md) gave the type for several outcomes. This axiom puts them together: when the core's job is to decide *what the shell should do next*, the most honest return type is a DU whose cases are the things the shell is allowed to do. [Axiom 6](axiom-06-pure-functions.md#example) already showed one: `DecideAdd(cart, product, quantity)` returning `AddLine`, `IncreaseLine` or `Rejected`. Now the pattern has a name.

Through [Axiom 9](axiom-09-connascence.md)'s lens, it turns a [Connascence of Meaning](axiom-09-connascence.md#connascence-of-meaning-com) (a status string or flag the shell must decode back into *what to do*) into a [Connascence of Type](axiom-09-connascence.md#connascence-of-type-cot).

---

## Definitions

An **action** is a case of a sealed DU whose only purpose is to *describe* an effect for the shell to carry out. It is an immutable record with exactly the data that effect needs, and it is a value: it can be logged, stored, compared or sent elsewhere. Describing and doing are separate [1][5]. An action is the imperative sibling of a [domain event](https://martinfowler.com/eaaDev/DomainEvent.html) [3]: `AddLine` says what to do; `LineAdded` would say what happened.

A **pure function returning actions** is pure ([Axiom 6](axiom-06-pure-functions.md)): everything it needs (the current state, looked-up data, the time, configuration) arrives as parameters, and what it returns is not the result of an effect but its *description*.

This is [command–query separation](axiom-13-impureim.md#definitions) taken to its end. The query (`DecideAdd`, which returns a value) and the command (the shell's execution, which returns nothing meaningful) become *different functions*, with different testability and different reasons to change. The type holds the seam between them: every action the core can return is one the shell must handle.

**The road not taken.** Tell, Don't Ask ([Axiom 2](axiom-02-data-is-not-behavior.md#tell-dont-ask-the-road-not-taken)) does the opposite on purpose: `account.Withdraw(amount)` decides whether the withdrawal is allowed *and* performs it, so the caller never sees the decision. The two answer different situations. Tell, Don't Ask protects *mutable* state by never letting a caller get between a read and a write. Here there is no such gap to protect: the gathered state is an immutable value, and the only write is the shell carrying out the returned action. Taking the decision out is what makes it a value you can log, replay and test without a database, which a self-mutating method rules out.

---

## Example

`DecideAdd(cart, productId, quantity)` with three outcomes: add a new line, increase an existing line, or reject. It applies the same rules as [Axiom 6](axiom-06-pure-functions.md#example). Wlaschin's F# workflows have the same shape [6].

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed record CartLine(ProductId ProductId, int Quantity);
public sealed record Cart(IReadOnlyList<CartLine> Lines);

public abstract record CartAction;
public sealed record AddLine(ProductId ProductId, int Quantity)
    : CartAction;
public sealed record IncreaseLine(ProductId ProductId, int NewQuantity)
    : CartAction;
public sealed record Rejected(string Reason) : CartAction;

public static CartAction DecideAdd(
    Cart cart, ProductId productId, int quantity)
{
    if (quantity <= 0)
        return new Rejected("quantity must be positive");

    var existing = cart.Lines.FirstOrDefault(l => l.ProductId == productId);
    if (existing is not null)
        return new IncreaseLine(productId, existing.Quantity + quantity);
    if (cart.Lines.Count >= MaxLines)
        return new Rejected("cart is full");
    return new AddLine(productId, quantity);
}
```

</td>
<td>

```java
public record CartLine(ProductId productId, int quantity) {}
public record Cart(List<CartLine> lines) {}

public sealed interface CartAction
    permits AddLine, IncreaseLine, Rejected {}
public record AddLine(ProductId productId, int quantity)
    implements CartAction {}
public record IncreaseLine(ProductId productId, int newQuantity)
    implements CartAction {}
public record Rejected(String reason) implements CartAction {}

public static CartAction decideAdd(
        Cart cart, ProductId productId, int quantity) {
    if (quantity <= 0)
        return new Rejected("quantity must be positive");

    Optional<CartLine> existing = cart.lines().stream()
        .filter(l -> l.productId().equals(productId))
        .findFirst();
    if (existing.isPresent())
        return new IncreaseLine(
            productId, existing.orElseThrow().quantity() + quantity);
    if (cart.lines().size() >= MAX_LINES)
        return new Rejected("cart is full");
    return new AddLine(productId, quantity);
}
```

</td>
</tr>
</table>

`DecideAdd` is pure: three inputs, one returned action, no database, no log, no `throw`. The action is a value the caller can hold, log or carry out. A reviewer reads the rule in `DecideAdd` and the effect in the shell; the seam between them is the type `CartAction`.

The shell, as the sandwich of [Axiom 13](axiom-13-impureim.md):

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public HttpResponse HandleAddProduct(
    CartId id, ProductId productId, int quantity)
{
    var cart = carts.Load(id);                           // gather

    var action = DecideAdd(cart, productId, quantity);   // decide

    return action switch                                 // act
    {
        AddLine a      => InsertLine(id, a),
        IncreaseLine i => UpdateLine(id, i),
        Rejected r     => new HttpResponse(400, r.Reason),
        _ => throw new UnreachableException()
    };
}

private HttpResponse InsertLine(CartId id, AddLine a)
{
    carts.InsertLine(id, a.ProductId, a.Quantity);
    return new HttpResponse(200, $"added {a.Quantity} × {a.ProductId}");
}

private HttpResponse UpdateLine(CartId id, IncreaseLine i)
{
    carts.UpdateLineQuantity(id, i.ProductId, i.NewQuantity);
    return new HttpResponse(200, $"{i.ProductId} now {i.NewQuantity}");
}
```

</td>
<td>

```java
public HttpResponse handleAddProduct(
        CartId id, ProductId productId, int quantity) {
    var cart = carts.load(id);                           // gather

    var action = decideAdd(cart, productId, quantity);   // decide

    return switch (action) {                             // act
        case AddLine a      -> insertLine(id, a);
        case IncreaseLine i -> updateLine(id, i);
        case Rejected r     -> new HttpResponse(400, r.reason());
    };
}

private HttpResponse insertLine(CartId id, AddLine a) {
    carts.insertLine(id, a.productId(), a.quantity());
    return new HttpResponse(200,
        "added " + a.quantity() + " × " + a.productId());
}

private HttpResponse updateLine(CartId id, IncreaseLine i) {
    carts.updateLineQuantity(id, i.productId(), i.newQuantity());
    return new HttpResponse(200,
        i.productId() + " now " + i.newQuantity());
}
```

</td>
</tr>
</table>

Everything [Axiom 17's synthesis](axiom-17-result.md#the-first-synthesis) showed still holds. What is new is what the core returns. In [Axiom 20](axiom-20-railway.md#in-the-shell), the core returned a `Result`, and the shell did the same thing with different data (a 200 or a 401). Here the core returns *what to do*, and each branch of the shell does a different thing: insert a row, update a row, or respond with an error.

---

## Problem / forces

When a function has to work out *what should happen* and then *make it happen*, five shapes are common:

1. **Effects inline.** One method reads from the database, applies the rule, writes back and logs. It reads naturally, but it pays every cost of [Axiom 5](axiom-05-impure-functions.md): impure throughout, tests need a database, and the signature hides every effect.
2. **Return a status string.** The method decides and returns `"added"`, `"increased"` or `"rejected: cart is full"`, and the caller switches on the string. The decision is partly extracted, but the seam is a [magic string (Axiom 7)](axiom-07-honest-total-signatures.md#definitions) the caller has to parse back into what to do.
3. **Return a status plus optional fields.** Closer: the outcomes are structured. But each outcome's data sits in a field that is only valid for certain statuses, the problem [Axiom 22](axiom-22-discriminated-unions.md#problem--forces) describes.
4. **The [Command pattern](https://en.wikipedia.org/wiki/Command_pattern).** An object that holds the work and has an `Execute()` method [2]. The implementation lives next to the description, so adding a command doesn't touch a central dispatcher.
5. **An action DU.** The function returns one case of a sealed DU; the shell matches once and carries it out.

Options 1 to 3 tangle deciding with doing: literally in 1, through a string in 2, through a record of optional fields in 3. Options 4 and 5 both separate *describing* from *doing*; the choice between them is the one [Axiom 22](axiom-22-discriminated-unions.md#trade-offs) describes, a method on each case or a `switch` in each consumer. This book defaults to the action DU, because the actions are data and the shells that consume them often differ (an HTTP handler, a queue worker, a console command).

---

## Why

**1. Each half is tested the way it should be.**
`DecideAdd` is tested with a table: given this cart and quantity, expect this action. No database, no mocks. The shell has no decisions left, so it is covered by tests of the whole service against real dependencies. The action DU is what lets the two be tested differently.

**2. Rules and plumbing change in different places.**
A new rule ("reject if the customer is suspended") adds an `if` to `DecideAdd` and maybe a `Rejected` reason; the shell's branches still fit. A new database changes the shell's insert and update and nothing else; `DecideAdd` doesn't know storage exists. Two reasons to change, two places to edit, as [Axiom 8](axiom-08-cohesion.md) asks.

**3. The decision is a value.**
An action can be logged ("here is what the cart decided"), replayed against another store, put on a queue for a worker to carry out, or serialized and sent elsewhere. None of that works when the effect is inline.

---

## Trade-offs

- **More types.** Each decision now has an output DU with its cases, plus a shell that matches on it. For one handler that is real overhead; by the tenth, it is habit.
- **Keep presentation out of the actions.** An `HttpResponse` is not an action; it is an output format. Putting it in the DU ties the decision to one boundary. Actions describe the work in the program's own terms (insert a row, publish an event); each shell maps them to its boundary's format, as the example does in its branches.
- **Several effects need a list, not nesting.** When a decision means "insert a row *and* publish an event", return a list of actions and let the shell run each one. That keeps every branch "do one thing", however many actions arrive.
- **The core grows with the rules.** Fifteen rules make `DecideAdd` long. The fix is not to make it impure, but to split it into smaller pure functions that `DecideAdd` combines.

---

## When NOT to

- **One value, one trivial use.** `TotalWithTax(items, rate)` from [Axiom 6](axiom-06-pure-functions.md) returns a number the caller writes into a response. With no second case, an action DU would only wrap the number.
- **The result *is* the answer.** When the core returns a domain value (an `Order`, an `Invoice`) and the shell always does the same thing with it, there is nothing to discriminate. Action DUs are for when the shell must do one of *several different* things.
- **The set of actions is open.** Actions that arrive from plugins can't live in one sealed type; use a command interface with `Execute()` (see [Axiom 22](axiom-22-discriminated-unions.md#when-not-to)).
- **A one-rule script.** A small job that loads one row, applies one rule and writes one row may not earn the split. It pays off as the rules grow.

---

## References

[1] **Yehonathan Sharvit**, *Data-Oriented Programming: Reduce software complexity*, Manning Publications, 2022. Also cited in [Axiom 2](axiom-02-data-is-not-behavior.md), [Axiom 3](axiom-03-immutability.md) and [Axiom 22](axiom-22-discriminated-unions.md). Its first principle, separating code from data, applied to a decision: the decision becomes data, and the code that acts on it lives at the boundary.
<https://www.manning.com/books/data-oriented-programming>

[2] **Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides**, *Design Patterns: Elements of Reusable Object-Oriented Software*, Addison-Wesley, 1994. Also cited in [Axiom 10](axiom-10-first-class-functions.md) and [Axiom 12](axiom-12-pattern-matching.md). The Command pattern: an object holds the parameters of the work and exposes an `Execute()` method. An action DU is its data-oriented sibling: the same separation, with the description as a value matched in one place.

[3] **Martin Fowler**, *Domain Event*, martinfowler.com, 2005. A domain event records something that happened as an object of its own. An action is its imperative sibling; the difference is tense.
<https://martinfowler.com/eaaDev/DomainEvent.html>

[4] **Mark Seemann**, *Impureim Sandwich*, ploeh blog, 2020. Also cited in [Axiom 13](axiom-13-impureim.md). The impure, pure, impure shape that this axiom fills in, with the pure part returning the action the impure part carries out.
<https://blog.ploeh.dk/2020/03/02/impureim-sandwich/>

[5] **Eric Normand**, *Grokking Simplicity*, Manning Publications, 2021. Also cited in [Axiom 5](axiom-05-impure-functions.md), [Axiom 6](axiom-06-pure-functions.md) and [Axiom 13](axiom-13-impureim.md). Its actions, calculations and data in one sentence: a calculation produces data that describes an action, and the action carries it out.
<https://www.manning.com/books/grokking-simplicity>

[6] **Scott Wlaschin**, *Domain Modeling Made Functional*, Pragmatic Bookshelf, 2018. Also cited in [Axiom 17](axiom-17-result.md), [Axiom 18](axiom-18-result-combinators.md), [Axiom 20](axiom-20-railway.md) and [Axiom 21](axiom-21-validation.md). Its workflows end with a pure function returning a typed outcome and an outer layer handling each case: the F# original of this axiom.
<https://pragprog.com/titles/swdddf/domain-modeling-made-functional/>

---

← Previous: [Axiom 23 — Make illegal states unrepresentable](axiom-23-illegal-states.md) · Next: [Axiom 25 — State machines](axiom-25-state-machines.md) →
