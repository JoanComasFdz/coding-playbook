# Axiom 19 — Value objects

**A value object is a small immutable type whose only way in is a factory that checks the input and returns a `Result`: a `Success` holding a value the rest of the code can trust, or a `Failure` saying why not.**

- The check runs once, when the value is built. After that, the type itself is the proof that the rule holds.
- There is no other way to build one, so an invalid value can't exist.

[Axiom 7](axiom-07-honest-total-signatures.md#why) made functions total by narrowing their input types, with `NonZeroInt` as a placeholder. This axiom is how you build such types: a small immutable record ([Axiom 3](axiom-03-immutability.md)) whose construction *is* the check, and whose factory returns a `Result` ([Axiom 17](axiom-17-result.md)).

It is also where [Axiom 0](axiom-00-ubiquitous-language.md)'s names get teeth. The domain's word (`Username`, `EmailAddress`) becomes a type the compiler enforces, not a bare `string` that any other string can stand in for.

Through [Axiom 9](axiom-09-connascence.md)'s lens, a value object turns a [Connascence of Meaning](axiom-09-connascence.md#connascence-of-meaning-com) (every call site re-checking what a bare string means) into a [Connascence of Type](axiom-09-connascence.md#connascence-of-type-cot). It also removes the [Connascence of Position](axiom-09-connascence.md#connascence-of-position-cop) between two parameters of the same type (see *Why*, point 3).

---

## Definitions

A [value object](https://en.wikipedia.org/wiki/Value_object) has three properties [1]:

- **Immutable.** No setters and no mutable internals ([Axiom 3](axiom-03-immutability.md)).
- **Equal by value.** Two instances with the same data are equal; there is no identity beyond the data. Records give you this for free. A hand-written class has to override `Equals`/`GetHashCode` (`equals`/`hashCode` in Java) consistently.
- **Valid by construction.** The constructor is private. The only way in is a static factory, `Parse` in C# and `parse` in Java, that checks the input once and returns `Result<T, string>`. Functional programmers call this a [smart constructor](https://wiki.haskell.org/Smart_constructors).

> **In Java, a value object is a `final class`, never a record.** A record's canonical constructor is always as visible as the record itself, so it can't be made private, and any caller can skip `parse`. A `final class` with a private constructor is the only way to keep `parse` as the one way in. It costs hand-written `equals` and `hashCode`; the example below shows them. C# has no such limit: a `sealed record` can have a private constructor.

The first two properties come from earlier axioms. The third is what this axiom adds: it turns a record from "some fields" into "proof that these fields follow a rule". A function that takes a `Username` never checks whether it is empty, because `Username.Parse` already did.

This axiom departs from three common defaults:

- **Bare primitives for domain concepts.** `CustomerProfile(string Username, string Email)` accepts any two strings, in either order, empty or not. Every function downstream re-checks, or trusts that someone else did.
- **A constructor that throws.** It moves the failure out of the return type and into the call stack, the dishonesty [Axiom 17](axiom-17-result.md#problem--forces) already ruled out. Building a value is not a special case.
- **A separate validation step.** With `Validate(profile)` called after `new CustomerProfile(...)`, the object exists before it is checked, and the next caller can forget the check. The only way to guarantee the check is to make building and checking one step.

The examples use `string` as the error type: cheap, readable in logs, and enough when the caller only reports the reason. When callers need to branch on the reason, use a typed error ([Axiom 17](axiom-17-result.md#trade-offs)).

---

## Example

The problem first: a record built from raw strings.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed record CustomerProfile(string Username, string Email);

// All of these compile:
new CustomerProfile("", "joan@example.com");     // empty username
new CustomerProfile("joan", "not-an-email");     // malformed email
new CustomerProfile("joan@example.com", "joan"); // arguments swapped
```

</td>
<td>

```java
public record CustomerProfile(String username, String email) {}

// All of these compile:
new CustomerProfile("", "joan@example.com");     // empty username
new CustomerProfile("joan", "not-an-email");     // malformed email
new CustomerProfile("joan@example.com", "joan"); // arguments swapped
```

</td>
</tr>
</table>

Both arguments are strings, so the compiler has nothing to check: either order, either empty, either malformed.

The same record, built from value objects:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed record Username
{
    public string Value { get; }
    private Username(string value) => Value = value;

    public static Result<Username, string> Parse(string raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
            return new Failure<Username, string>("username is empty");
        if (raw.Length > 30)
            return new Failure<Username, string>("username is over 30 characters");
        return new Success<Username, string>(new Username(raw));
    }
}

public sealed record EmailAddress
{
    public string Value { get; }
    private EmailAddress(string value) => Value = value;

    public static Result<EmailAddress, string> Parse(string raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
            return new Failure<EmailAddress, string>("email is empty");
        if (!raw.Contains('@'))
            return new Failure<EmailAddress, string>("email has no '@'");
        if (raw.Length > 254)
            return new Failure<EmailAddress, string>("email is over 254 characters");
        return new Success<EmailAddress, string>(new EmailAddress(raw));
    }
}

public sealed record CustomerProfile(Username Username, EmailAddress Email);
```

</td>
<td>

```java
public final class Username {
    private final String value;
    private Username(String value) { this.value = value; }
    public String value() { return value; }

    public static Result<Username, String> parse(String raw) {
        if (raw == null || raw.isBlank())
            return new Failure<>("username is empty");
        if (raw.length() > 30)
            return new Failure<>("username is over 30 characters");
        return new Success<>(new Username(raw));
    }

    @Override public boolean equals(Object o) {
        return o instanceof Username u && value.equals(u.value);
    }
    @Override public int hashCode() { return value.hashCode(); }
    @Override public String toString() { return "Username[" + value + "]"; }
}

public final class EmailAddress {
    private final String value;
    private EmailAddress(String value) { this.value = value; }
    public String value() { return value; }

    public static Result<EmailAddress, String> parse(String raw) {
        if (raw == null || raw.isBlank())
            return new Failure<>("email is empty");
        if (!raw.contains("@"))
            return new Failure<>("email has no '@'");
        if (raw.length() > 254)
            return new Failure<>("email is over 254 characters");
        return new Success<>(new EmailAddress(raw));
    }

    // equals, hashCode and toString as in Username
}

public record CustomerProfile(Username username, EmailAddress email) {}
```

</td>
</tr>
</table>

`new Username("")` no longer compiles. The only way in is `Username.Parse(...)`, which returns a `Result`, so the caller has to handle the failure before it gets a `Username`.

The payoff is where the values are used:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public static string FormatContactLine(CustomerProfile profile) =>
    $"{profile.Username.Value} <{profile.Email.Value}>";
```

</td>
<td>

```java
public static String formatContactLine(CustomerProfile profile) {
    return profile.username().value()
        + " <" + profile.email().value() + ">";
}
```

</td>
</tr>
</table>

No null check, no length check, no `@` check. They ran once, where the raw strings entered the program. `FormatContactLine` is total ([Axiom 7](axiom-07-honest-total-signatures.md)) because of its parameter type, and so is every function below it that takes these types.

---

## Problem / forces

- **Boilerplate against scattered rules.** A value object is a small file: a private constructor, a field, a factory and, in Java, `equals` and `hashCode`. Libraries such as CSharpFunctionalExtensions ship a base class that removes some of it [7]. A bare `string` costs nothing to write, and in a program with no rules to enforce it is the right choice. The trade reverses as soon as a rule exists. Once two functions disagree about what makes a username valid, or one caller forgets to check, the costs pile up: "how did an empty username reach the database?", defensive checks in every layer, and copies of the rule that drift apart. The value object pays that cost once, where the value is built.
- **The boundary speaks primitives.** Input arrives as primitives (JSON, form fields, query strings, database rows), and output leaves the same way. Value objects don't remove primitives; they push them to the edge. `Parse` turns a primitive into a value object on the way in, and `.Value` turns it back on the way out. The pure core works with value objects; the impure shell ([Axiom 13](axiom-13-impureim.md)) speaks both.

---

## Why

**1. The type is the proof.**
Once an `EmailAddress` exists, no other code needs to check that it is well formed. The rule and the type are one thing. This is [*parse, don't validate*](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/) [2] at its smallest scale: a function that *validates* a string hands back a `bool` and the same string, and asks the caller to remember (the [boolean blindness of Axiom 7](axiom-07-honest-total-signatures.md#definitions)). A function that *parses* a string hands back the parsed type, so there is nothing to remember.

**2. The rule lives in one place.**
The same rule written at three call sites becomes three slightly different rules over time. Written in `Username.Parse`, it is one rule, and the type is the agreement. When it changes ("usernames can now be 50 characters"), you edit one file and its tests.

**3. Signatures say more.**
A parameter of type `Username` says the function expects a *valid* username, not any string. The reader learns the precondition without reading the body. And `Refund(Username, OrderId)` can't be called with its arguments swapped, because the two types differ: the compiler now does what code review used to do.

**4. Total functions become easy to write.**
[Axiom 7](axiom-07-honest-total-signatures.md#why) (point 3) reached totality by narrowing the input type. Value objects are how you narrow it. Once a precondition is a type, the body has nothing left to check, and every function written against value objects is shorter and about its actual job. It is also the job of encapsulation that [Axiom 1](axiom-01-explicit-over-implicit.md#encapsulation-read-precisely) keeps: the invariant is protected where the value is built, not by hiding its fields.

**Design by Contract, answered with types.** [Design by Contract](https://en.wikipedia.org/wiki/Design_by_contract) asks three things of a method: what must hold before it runs (the precondition), what it guarantees after (the postcondition), and what always stays true (the invariant) [3]. A value object answers two of them with types. Its factory is the invariant: a malformed `EmailAddress` can't exist. Taking one as a parameter discharges the precondition. The postcondition is the honest return type of [Axiom 7](axiom-07-honest-total-signatures.md). The difference from Eiffel is *when* the contract is checked: Eiffel's assertions run at runtime and can be turned off in production builds, while a type is checked by the compiler and can't be. Some contracts resist types, such as "the returned list is sorted" or a rule that spans several values. There, a runtime assertion or a property-based test still earns its place. Put into a type every contract a type can carry.

**Postel's law, reconciled.** The [robustness principle](https://en.wikipedia.org/wiki/Robustness_principle) says "be conservative in what you do, be liberal in what you accept from others" [4]. That sounds like the opposite of a strict factory, but the two apply to different things. Postel is about the *form* of the input; the factory is about its *meaning*. A `Parse` may accept several forms (trim whitespace, accept two date formats, ignore case), as long as it produces exactly one canonical value or a `Failure`. That is the part plain leniency was missing. The IETF has since reconsidered the principle [5]: accepting malformed input without normalizing it lets every consumer decide what it meant, and the format drifts toward whatever the most popular implementation accepts. Parsing at the boundary keeps the forgiving front door and stops the drift.

---

## Identity and typed IDs

Some things are not values. Two customers with the same name and email are still two customers (see *When NOT to*). Such things need identity, and the smallest building block for it comes from the same machinery.

- **A typed ID is a value object without the rule.** An `OrderId` wraps a `Guid`. Any `Guid` is a valid `OrderId`, so the factory doesn't need a `Result`. Its job is not checking but *telling types apart*, like Wlaschin's single-case union types [6]: `Refund(CustomerId, OrderId)` can't take its arguments swapped (see *Why*, point 3), where two bare `Guid`s could.
- **Things with identity are equal by key.** A value object is equal by all its data. A thing with identity is equal by one key field. Two snapshots of the same order, before and after shipping, differ in almost every field and are still the same order, because their `OrderId` matches. A value object needs no ID because its data *is* its identity.
- **The key has to live in the data.** [Axiom 9](axiom-09-connascence.md#connascence-of-identity-coi) called Connascence of Identity (two holders depending on *the same instance*) the strongest kind, and immutable values dissolve it: there is no shared mutable object to point at. The price is that "which thing is this?" can no longer be answered by the reference. Identity has to move into the data, as an explicit key field. That is what the typed ID is for.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public readonly record struct OrderId(Guid Value)
{
    public static OrderId Create() => new(Guid.NewGuid());
}

// Equal by Id (the key), not by the rest of the data.
public sealed record Order(OrderId Id, Money Total, OrderStatus Status)
{
    public bool Equals(Order? other) => other is not null && Id == other.Id;
    public override int GetHashCode() => Id.GetHashCode();
}
```

</td>
<td>

```java
public record OrderId(UUID value) {
    public static OrderId create() { return new OrderId(UUID.randomUUID()); }
}

// Equal by id (the key), not by the rest of the data.
public record Order(OrderId id, Money total, OrderStatus status) {
    @Override public boolean equals(Object o) {
        return o instanceof Order other && id.equals(other.id);
    }
    @Override public int hashCode() { return id.hashCode(); }
}
```

</td>
</tr>
</table>

Two `Order` values with the same `Id` are the same order, however their `Total` or `Status` has changed. Two with different `Id`s are different orders, however alike their data.

---

## Trade-offs

- **The Java `final class` is more code.** Hand-written `equals` and `hashCode` for every value object (see *Definitions*). The cheaper alternative, a record whose public constructor only review keeps callers away from, gives up the guarantee this axiom is about.
- **Mapping at the persistence boundary.** ORMs and serializers expect public constructors or settable properties. Map at the boundary instead (see *Problem / forces*): read the primitive, call `Parse`, and treat a `Failure` as an error, because it means the stored data breaks today's rule.
- **Several values, several Results.** A handler that builds three value objects has three `Result`s to handle. The combinators of [Axiom 18](axiom-18-result-combinators.md) apply directly: a factory is exactly the kind of step `Bind` chains. A later axiom builds on this to compose many.

---

## When NOT to

- **A primitive with no rule.** A field that can be any string gains nothing from a wrapper whose factory always succeeds. Use the primitive.
- **In the code that talks to the outside world.** The function that reads a JSON body or writes a database row speaks primitives (see *Problem / forces*). The value object lives one layer in; it doesn't belong inside the deserializer.
- **For things with identity.** A `Customer` is not a value object: two customers who share every field are still two customers. Use value objects for their attributes, and a typed ID for the identity (see *Identity and typed IDs*).
- **Throwaway code.** A one-off script or migration that lives for days doesn't pay back the cost. The benefit grows with reuse and with the number of callers that would otherwise re-check.

---

## References

[1] **Eric Evans**, *Domain-Driven Design: Tackling Complexity in the Heart of Software*, Addison-Wesley, 2003. The original Value Object: immutable, equal by value, no identity, as opposed to an Entity. The smart constructor returning a `Result` is not from Evans; the immutability and equality are.
<https://www.domainlanguage.com/ddd/>

[2] **Alexis King**, *Parse, Don't Validate*, 2019. Also cited in [Axiom 7](axiom-07-honest-total-signatures.md). A validating function returns a `bool` next to the original value; a parsing function returns a more precise type. This axiom is that essay applied to single values.
<https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/>

[3] **Bertrand Meyer**, *Object-Oriented Software Construction* (2nd ed.), Prentice Hall, 1997. Design by Contract: preconditions, postconditions and invariants, checked by assertions in Eiffel.

[4] **Jon Postel (ed.)**, *Transmission Control Protocol*, RFC 793, 1981, section 2.10: "be conservative in what you do, be liberal in what you accept from others". (RFC 760, 1980, states the same idea in other words.)
<https://www.rfc-editor.org/rfc/rfc793>

[5] **Martin Thomson and David Schinazi**, *Maintaining Robust Protocols*, RFC 9413, June 2023. Notes that the robustness principle "has been interpreted in a variety of ways", some of which "can negatively affect interoperability over time", and recommends active protocol maintenance instead.
<https://www.rfc-editor.org/rfc/rfc9413>

[6] **Scott Wlaschin**, *Designing with types: Single case union types*, fsharpforfunandprofit.com, 2013. Wraps a primitive in a one-case type with a smart constructor: the F# version of this axiom's records, part of a series that applies the idea to a whole domain model.
<https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/>

[7] **Vladimir Khorikov**, *CSharpFunctionalExtensions*. Also cited in [Axiom 17](axiom-17-result.md) and [Axiom 18](axiom-18-result-combinators.md). Its `ValueObject` base class handles equality for hand-written value objects in C#.
<https://github.com/vkhorikov/CSharpFunctionalExtensions>

---

← Previous: [Axiom 18 — Result combinators](axiom-18-result-combinators.md) · Next: [Axiom 20 — Railway](axiom-20-railway.md) →
