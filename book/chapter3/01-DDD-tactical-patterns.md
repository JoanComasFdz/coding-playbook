# DDD Tactical Patterns

The tactical patterns of Domain-Driven Design were designed for mutable, object-oriented code. In that world an object protects its own state. It hides its fields and exposes methods that guard the rules.

Chapter 2 makes a different bet. Data is immutable. Behaviour lives in pure functions, not in methods on the data. Bad states are removed by the shape of the type, not by checks at runtime. So the patterns do not disappear, but the way they work changes. The goal of each pattern stays the same. The mechanism is new.

This chapter shows the immutable version and where it fits.

Each pattern below is one of two things. Some are already a Chapter 2 axiom with a DDD name on top. For those we link and move on. Some need new material that lives above a single function. For those we write it here.

## Value Object

This is exactly [Axiom 18](../chapter2/axiom-18-value-objects.md). `Money`, `EmailAddress`, and `Quantity` are value objects. There is nothing to add here.

## Entity

An entity is a thing with identity that changes over time. A `Customer` stays the same customer even after its email changes. You build it from three pieces you already have:

- An immutable record for its data ([Axiom 2](../chapter2/axiom-02-immutability.md)).
- A typed ID for its identity, with equality by key, not by contents ([Axiom 18, Identity and typed IDs](../chapter2/axiom-18-value-objects.md#identity-and-typed-ids)).
- A pure transition function for its lifecycle ([Axiom 24](../chapter2/axiom-24-state-machines.md)).

The only new idea is how they fit together. An entity does not change itself. To "change" it, a pure function takes the old value and returns a new value with the same ID. The ID is fixed. Everything else can move. Two values with the same ID are the same entity, seen at two moments.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public readonly record struct CustomerId(Guid Value);

public sealed record Customer(CustomerId Id, EmailAddress Email);

// "Change" is a pure function: old value in, new value out, same Id.
public static Customer ChangeEmail(Customer c, EmailAddress newEmail) =>
    c with { Email = newEmail };
```

</td>
<td>

```java
public record CustomerId(UUID value) {}

public record Customer(CustomerId id, EmailAddress email) {}

// "Change" is a pure function: old value in, new value out, same id.
public static Customer changeEmail(Customer c, EmailAddress newEmail) {
    return new Customer(c.id(), newEmail);
}
```

</td>
</tr>
</table>

## Aggregate

An aggregate is a group of entities and value objects that you treat as one unit, with rules that must always hold across the whole group. An `Order` with its lines is the classic example: "the order total equals the sum of its lines" is a rule about the group, not about one line.

In the immutable world an aggregate is two things:

1. **One immutable value:** a root record that holds its children. The `Order` record holds its `OrderLine` records.
2. **A set of pure functions** that take the whole aggregate value and return a new one, or a failure. These functions are the only home for the group's rules.

There are no methods on the data, so the aggregate does not guard itself the way an OOP object does. Every change goes through one of these functions, and the function is what checks the rules. If a change would break a rule, the function returns a failure instead of a new value. So any `Order` value that exists is already valid. This is [Axiom 22](../chapter2/axiom-22-illegal-states.md) and the smart constructor from [Axiom 18](../chapter2/axiom-18-value-objects.md), now at the scale of the whole group.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed record OrderLine(ProductId Product, int Quantity, Money UnitPrice);
public sealed record Order(OrderId Id, CustomerId Customer, IReadOnlyList<OrderLine> Lines);

// The only way to "change" an Order: whole value in, whole value out (or a failure).
public static Result<Order, string> AddLine(Order order, OrderLine line)
{
    if (line.Quantity <= 0)
        return new Failure<Order, string>("quantity must be positive");
    if (order.Lines.Count >= 100)
        return new Failure<Order, string>("an order cannot have more than 100 lines");

    return new Success<Order, string>(order with { Lines = [.. order.Lines, line] });
}
```

</td>
<td>

```java
public record OrderLine(ProductId product, int quantity, Money unitPrice) {}
public record Order(OrderId id, CustomerId customer, List<OrderLine> lines) {}

// The only way to "change" an Order: whole value in, whole value out (or a failure).
public static Result<Order, String> addLine(Order order, OrderLine line) {
    if (line.quantity() <= 0)
        return new Failure<>("quantity must be positive");
    if (order.lines().size() >= 100)
        return new Failure<>("an order cannot have more than 100 lines");

    var newLines = Stream.concat(order.lines().stream(), Stream.of(line)).toList();
    return new Success<>(new Order(order.id(), order.customer(), newLines));
}
```

</td>
</tr>
</table>

For a richer lifecycle, the function returns events instead of the new value, and a second function folds those events back into the next state. That is the Decider and state machine from [Axiom 23](../chapter2/axiom-23-pure-functions-returning-actions.md) and [Axiom 24](../chapter2/axiom-24-state-machines.md).

The boundary rules complete the picture. They are the part Chapter 2 does not give you:

- **Change the whole value, never a child alone.** You do not build a changed `OrderLine` and slot it back into the `Order` yourself, because that skips the function where the group's rules live. You call the aggregate's function, which takes the whole `Order` and returns the whole new `Order`. This is what "go through the root" means once there are no methods: the root is the top record, plus the functions that own its changes.
- **The aggregate is the consistency boundary.** The function sees the whole value at once, so it can check rules that span several children before it returns. The shell loads the whole `Order`, calls one function, and saves the whole result as one transaction. The aggregate boundary is the transaction boundary.
- **Point at other aggregates by ID.** An `Order` holds a `CustomerId`, not a whole `Customer`. This keeps each aggregate small and independent.
- **Keep aggregates small.** A large aggregate is slow to load and easy to conflict on. If two rules do not need to be true in the same instant, split them into two aggregates.

## Domain Event

A domain event is a fact that already happened, named in the past tense: `OrderPlaced`, `SubscriptionCancelled`. It is an immutable record, and a set of events is a discriminated union. A pure transition function returns the events it produced.

This is the Event DU from [Axiom 24](../chapter2/axiom-24-state-machines.md). The only thing DDD adds is a naming habit: name events as past-tense facts, in the domain's own words ([Axiom 0](../chapter2/axiom-00-ubiquitous-language.md)).

## Domain Service

Some behaviour does not belong to any single entity. In OOP this becomes a "service" class, because behaviour has to live on an object and this behaviour has no object to live on.

In our world that problem never appears: no behaviour lives on the data in the first place ([Axiom 1](../chapter2/axiom-01-data-vs-behaviour.md)). So the pattern splits in two, and the old advice ("reach for a service when an operation spans more than one entity") does not survive the move.

- **A pure decision over several values is just a function.** `Transfer(from, to, amount)` takes two accounts and returns the two new accounts, or a failure. It needs no label. It is an ordinary pure function ([Axiom 5](../chapter2/axiom-05-pure-functions.md)) that returns a value or an action ([Axiom 23](../chapter2/axiom-23-pure-functions-returning-actions.md)). Spanning entities adds nothing: a function can take as many inputs as it needs.
- **Loading and saving those entities is orchestration, not domain logic.** Load the accounts, call the pure function, save the result. That is the Impureheim shell ([Axiom 12](../chapter2/axiom-12-impureheim.md)): gather, decide, act. The decision inside it is still the pure function above.

So you rarely write a thing called a "domain service." You write a pure function for the decision and let the shell do the I/O around it. There is no special construct to show. One caveat: if the entities are separate aggregates, saving them together is the consistency question from the Aggregate section. Use one transaction only if they truly must agree at the same instant; otherwise it becomes a saga or process manager, which stays out of scope.

## Repository

A repository is the boundary where you load and save aggregates. The domain knows nothing about storage. This is called persistence ignorance, and it comes for free because the domain is pure data and pure functions.

In the immutable world a repository is two functions at the edge: one loads an aggregate by ID, one saves it. Both touch storage, so both can fail, and that failure belongs in the return type as a value, not behind a bare `Task` that can only throw. So each returns a `Result` ([Axiom 16](../chapter2/axiom-16-result.md)). Load has a second outcome that is not a failure: the row may simply not exist. That is absence, not an error, so it is a `Maybe` ([Axiom 13](../chapter2/axiom-13-maybe.md)) inside the `Result`, which keeps the three cases separate: storage failed, no such order, here is the order. Save has nothing to return on success, so it returns `Unit` ([Axiom 15](../chapter2/axiom-15-unit.md)).

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public delegate Task<Result<Order?, RepoError>> LoadOrder(OrderId id);
public delegate Task<Result<Unit, RepoError>>   SaveOrder(Order order);
```

</td>
<td>

```java
@FunctionalInterface public interface LoadOrder { Result<Optional<Order>, RepoError> load(OrderId id); }
@FunctionalInterface public interface SaveOrder { Result<Unit, RepoError>            save(Order order); }
```

</td>
</tr>
</table>

These functions live in the impure shell ([Axiom 12](../chapter2/axiom-12-impureheim.md)). The pure core never calls them. It receives the loaded value and returns the new value, or actions for the shell to save.

`RepoError` is a placeholder. Use a plain `string` when the caller only logs it, and a typed error when the caller must branch on the cause (a concurrency conflict, a transient timeout).

How load and save actually work, reading rows straight into immutable records instead of using a tracking ORM, and how a concurrency conflict becomes one of these failures, is the subject of the immutable persistence Play later in this chapter.

## Factory

A factory hides creation that is complex or can fail. When it can fail, it returns a `Result`. In the immutable world this is the same smart constructor as [Axiom 18](../chapter2/axiom-18-value-objects.md). There is rarely a separate factory, because every type already owns its only way in.

## Make illegal states unrepresentable

OOP protects its rules with encapsulation: hide the state, guard it with methods. The immutable world replaces that with two ideas. This is the first.

Model the type so a bad state cannot be built at all. A draft order and a placed order are different types, not one type with nullable fields and a status flag. The check moves from runtime into the shape of the type. This is [Axiom 22](../chapter2/axiom-22-illegal-states.md).

## Railway-oriented programming

This is the second idea that replaces encapsulation. A workflow is a chain of steps, each of which can succeed or fail. Chain them so the first failure stops the rest and lands on the error track. This is `Result` plus its combinators ([Axiom 16](../chapter2/axiom-16-result.md), [Axiom 17](../chapter2/axiom-17-result-combinators.md), [Axiom 19](../chapter2/axiom-19-railway.md)). When you want to collect every error instead of stopping at the first, use accumulating validation ([Axiom 20](../chapter2/axiom-20-validation.md)).

## What stays out of scope

Some patterns sit on top of these building blocks but are not building blocks themselves. This chapter does not cover them:

- Domain events used to talk between bounded contexts or separate services.
- Event sourcing, where the stored events are the source of truth.
- Sagas, process managers, the outbox pattern, and retries.

These are system topology and operations. They consume the patterns above. They belong to architecture, not to the code-shaped tactical layer this chapter stays inside.
