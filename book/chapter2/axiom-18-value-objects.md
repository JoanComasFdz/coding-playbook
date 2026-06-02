# Axiom 18 — Value objects

**A value object is an immutable type whose only constructor is a static factory returning `Result<T, string>` — invalid inputs become a `Failure` carrying the reason, valid inputs become a `Success` whose contents every downstream function may trust without rechecking.**

- The factory does the validation once; the type itself is the proof that the contained value satisfies the domain rule.
- **Invalid states are unrepresentable**: there is no path to a value of the type that bypasses the check.

[Axiom 6](axiom-06-honest-total-signatures.md) named two ways to reach a total signature — widen the output, or *narrow the input*. The narrowing path needed a type whose values were guaranteed valid by construction; `NonZeroInt` was the placeholder. This axiom is the toolkit for building those types. A value object is a small immutable record ([Axiom 2](axiom-02-immutability.md)) whose construction *is* the parse step — raw input checked once on the way in, producing either a value the rest of the code can trust or a `Failure` ([Axiom 16](axiom-16-result.md)) explaining why it couldn't.

This is also where [Axiom 0](axiom-00-ubiquitous-language.md)'s naming discipline gets teeth at the level of a single noun: the domain's word — `Username`, `Money`, `EmailAddress` — becomes a type the compiler enforces, not a bare `string` any other string can impersonate.

Through [Axiom 8](axiom-08-connascence.md)'s lens, this axiom weakens a [Connascence of Meaning](axiom-08-connascence.md#connascence-of-meaning-com) — every call site re-checking what a bare string *means* — into a Connascence of Type, retiring the same-typed [Connascence of Position](axiom-08-connascence.md#connascence-of-position-cop) behind swapped arguments along the way.

---

## Definitions

A value object is a type with three structural properties:

- **Immutable.** A record or final class with no setters and no mutable internals; the carried data is fixed at construction. ([Axiom 2](axiom-02-immutability.md))
- **Equality by value.** Two instances with equal data are equal. There is no identity beyond the data — no surrogate key, no reference comparison that survives serialisation. Records provide this for free in modern C# and Java; hand-rolled classes must override `equals` and `GetHashCode` consistently.
- **Validity by construction.** The public constructor is hidden. The *only* entry point is a static factory — conventionally `From` (C#) or `from` (Java) — that returns `Result<T, string>`. The factory runs the validation once. If the input is invalid, it returns `Failure` carrying the reason; otherwise it returns `Success` wrapping the constructed instance.

The first two properties already live in earlier axioms. The third is what this axiom adds: it converts a record from "a tuple of fields" into "a proof that those fields satisfy a domain rule."

The body of every function that takes a value object can treat the contained data as already-valid. There is no `if (string.IsNullOrEmpty(name))` inside `Display(name)` — that check happened once, in `Username.From`, and the type system has remembered the answer ever since.

This axiom rejects three mainstream defaults:

- **Primitive obsession.** `CustomerProfile(string Username, string Email)` accepts any pair of strings — the type system has no opinion on which is which, whether either is non-empty, or whether the second contains an `@`. Every function downstream pays the cost of re-checking; every domain rule is scattered across the call sites that happen to remember it.
- **The throwing constructor.** A constructor that throws on bad input pushes the failure case outside the return type and into the call stack — exactly the dishonesty [Axiom 16](axiom-16-result.md) named for any other success-or-failure operation. Construction is not a special case; the failure mode belongs in the signature as a value.
- **The detached validation step.** A `Validate(profile)` called separately from `new CustomerProfile(...)` lets the constructed object exist *before* validation runs — and lets validation be forgotten on the next call site. The only way to guarantee that validation happened is to make construction and validation the same operation.

Note the chosen error type: `string`. A failure-reason as a human-readable string is the cheapest convention, reads well in logs, and is enough when the caller's only job is to surface or record the reason. Typed failure values become worth the cost when callers need to *branch* on different failure cases; that escalation is an ADR-level decision, not a principle-level one. This axiom uses strings throughout.

---

## Example

The problem first — a record built from raw strings:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public record CustomerProfile(string Username, string Email);

// All of these compile; none are caught at construction:
new CustomerProfile("", "joan@example.com");        // empty username
new CustomerProfile("joan", "not-an-email");        // malformed email
new CustomerProfile("joan@example.com", "joan");    // arguments swapped
```

</td>
<td>

```java
public record CustomerProfile(String username, String email) {}

// All of these compile; none are caught at construction:
new CustomerProfile("", "joan@example.com");        // empty username
new CustomerProfile("joan", "not-an-email");        // malformed email
new CustomerProfile("joan@example.com", "joan");    // arguments swapped
```

</td>
</tr>
</table>

Every constructor argument is a `String`. The compiler has nothing to enforce: the two arguments could be in either order, either could be empty, either could be malformed — the type allows the lot. Every function downstream that uses `CustomerProfile` either trusts that earlier code checked (which earlier code? checked what?) or re-checks itself.

Now the same record, built from value objects. Each constituent is its own type with a smart constructor:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed record Username
{
    public string Value { get; }
    private Username(string value) => Value = value;

    public static Result<Username, string> From(string raw) =>
        string.IsNullOrWhiteSpace(raw)
            ? new Failure<Username, string>("username is empty")
            : raw.Length > 30
                ? new Failure<Username, string>("username exceeds 30 characters")
                : new Success<Username, string>(new Username(raw));
}

public sealed record EmailAddress
{
    public string Value { get; }
    private EmailAddress(string value) => Value = value;

    public static Result<EmailAddress, string> From(string raw) =>
        string.IsNullOrWhiteSpace(raw)
            ? new Failure<EmailAddress, string>("email is empty")
            : !raw.Contains('@')
                ? new Failure<EmailAddress, string>("email is missing '@'")
                : raw.Length > 254
                    ? new Failure<EmailAddress, string>("email exceeds 254 characters")
                    : new Success<EmailAddress, string>(new EmailAddress(raw));
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

    public static Result<Username, String> from(String raw) {
        if (raw == null || raw.isBlank())
            return new Failure<>("username is empty");
        if (raw.length() > 30)
            return new Failure<>("username exceeds 30 characters");
        return new Success<>(new Username(raw));
    }

    @Override public boolean equals(Object o) {
        return o instanceof Username u && Objects.equals(value, u.value);
    }
    @Override public int hashCode() { return Objects.hash(value); }
    @Override public String toString() { return "Username[" + value + "]"; }
}

public final class EmailAddress {
    private final String value;
    private EmailAddress(String value) { this.value = value; }
    public String value() { return value; }

    public static Result<EmailAddress, String> from(String raw) {
        if (raw == null || raw.isBlank())
            return new Failure<>("email is empty");
        if (!raw.contains("@"))
            return new Failure<>("email is missing '@'");
        if (raw.length() > 254)
            return new Failure<>("email exceeds 254 characters");
        return new Success<>(new EmailAddress(raw));
    }

    // equals/hashCode/toString as above
}

public record CustomerProfile(Username username, EmailAddress email) {}
```

</td>
</tr>
</table>

The constructors are hidden. There is no `new Username("")` and no `new EmailAddress("not-an-email")` — those call sites do not compile. The only way in is `Username.From(...)`, which returns a `Result`. The compiler refuses to let the caller use the success branch without acknowledging the failure branch.

The payoff lands at the *use* site. A downstream function takes the value object, not the primitive:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public string DisplayLine(CustomerProfile profile) =>
    $"{profile.Username.Value} <{profile.Email.Value}>";
```

</td>
<td>

```java
public String displayLine(CustomerProfile profile) {
    return profile.username().value() + " <" + profile.email().value() + ">";
}
```

</td>
</tr>
</table>

No null check, no length check, no `@` check. Those checks ran once, at the boundary where the raw strings entered the program; the types have carried the answer ever since. `DisplayLine` is total ([Axiom 6](axiom-06-honest-total-signatures.md)) by virtue of its parameter type, not by re-validating its input. The same property propagates to every function downstream — every layer below the boundary inherits the guarantee for free.

---

## Problem / forces

The competing force is **boilerplate**. A value object is a small file: a private constructor, a single field, a factory, and — in Java — manual `equals` / `hashCode`. A codebase with thirty value objects has thirty such files. The mainstream `string` everywhere has zero. In a small program with no domain rules to enforce, the value-object discipline is pure tax.

The trade reverses as soon as the rules show up. The moment any two functions disagree about what makes a username valid, or any one caller forgets to validate, the cost of the primitive form starts compounding: bugs that look like *"how did an empty username reach the database?"*, defensive checks scattered across layers, and validation rules duplicated in places that drift out of sync. The boilerplate of the value object is the price of *paying that cost once* — at the point of construction — instead of paying it everywhere.

There is a second force worth naming: the **shape of the boundary**. Inputs to the program arrive as primitives — JSON strings, form fields, query parameters, database rows. Outputs go back the same way. The value-object discipline does not eliminate primitives; it concentrates them at the edge. The `From` factory is the seam where a primitive becomes a value object on the way in, and an accessor like `.Value` is the seam where it becomes a primitive on the way out. The pure core of the program traffics in value objects; the impure shell ([Axiom 4](axiom-04-impure-functions.md)) speaks both languages.

---

## Why

**1. The type is the proof.**
Once an `EmailAddress` exists, no further code in the program needs to check that it's a well-formed email. The validation rule and the type are one artefact; the rule cannot be forgotten without the type being unconstructable. This is the *parse, don't validate*[1] discipline applied at the lowest level — a function that "validates" a string returns the same string and asks the caller to remember; a function that "parses" a string returns a `Result<ValidatedType, …>` and the type system stops the caller from forgetting. The validating form is return-side *boolean blindness* ([Axiom 6](axiom-06-honest-total-signatures.md)) in its commonest dress — a `bool` handed back beside the unchanged primitive, telling the caller *that* the string is valid while giving them nothing valid to hold; the smart constructor cures it by returning the parsed type itself.

**2. Validation lives once, at the construction site.**
The same rule expressed in three call sites drifts into three slightly different rules over time. The same rule expressed in `Username.From` lives in one place. Every caller agrees on what makes a username valid because the *type* is the agreement. When the rule changes — *"usernames now allow up to 50 characters"* — there is one file to edit and one set of tests to update; the rest of the codebase inherits the change without modification.

**3. The signature gets richer for free.**
A function whose parameter is `Username` instead of `string` is honest in a way that the `string` version cannot be: the signature documents that the function expects a *validated* username, not any string. The reader does not have to read the body to discover the precondition. Add a third value object — say, `OrderId` — and the signature `Refund(Username, OrderId)` rules out the swapped-arguments class of bugs entirely. The compiler is doing the work that documentation and code review used to do alone.

**4. Total functions become buildable.**
[Axiom 6](axiom-06-honest-total-signatures.md) used `Divide(int, NonZeroInt)` as a sketch — totality reached by narrowing the input type. Value objects are the general form of that sketch. Once any function's preconditions can be expressed as a type, the function's body has no precondition left to check. The branching that *was* "if the input is bad, do something other than the work" disappears, because the type system has refused that input long before the body runs. Every function written against value objects is shorter, more total, and more directly about its actual job.

**Design by Contract, answered with types.** Meyer's *Design by Contract* asks three questions of every method: what must hold before it runs (the *precondition*), what it guarantees on return (the *postcondition*), and what stays true of the object throughout (the *invariant*). A value object answers two at once — its smart constructor *is* the invariant (a malformed `EmailAddress` cannot be constructed), and taking one as a parameter discharges the *precondition*. The *postcondition* is the honest return type from [Axiom 6](axiom-06-honest-total-signatures.md): a `Result`, `Option`, or DU, never "returns X *or* throws." The difference from Meyer's Eiffel is *where the contract is enforced* — Eiffel's `require` / `ensure` assertions run at runtime and can be compiled out in production (`-assertions=no`), whereas a type is checked at compile time and cannot be switched off; the contract stops being something the program *checks* and becomes something it *cannot violate*. The honest limit: a postcondition like *"the returned list is sorted,"* or an invariant spanning several values, can resist typing, and there a runtime assertion or property-based test still earns its keep — the rule is to carry in the type every contract a type *can* carry.

**Postel's Law, reconciled.** Jon Postel's *Robustness Principle* — *"be conservative in what you do, be liberal in what you accept from others"* (RFC 760, 1980) — reads at first as the opposite of this axiom: be *liberal* about input, where the smart constructor is *strict*. The contradiction is only apparent; the two govern different layers. Postel speaks to *surface form* — the syntax arriving on the wire — while the smart constructor speaks to *meaning* — the value that crosses into the domain. The reconciliation is **lenient lexer, strict parser**: a `From` factory may be generous about the shapes it accepts (trim whitespace, take either date format, normalise casing) but must be uncompromising about what it *emits* — exactly one canonical value or a `Failure` — and the leniency stops at that step. Far from a rival, the smart constructor does the very job the protocol world learned that leniency *needs*: the IETF has since recanted the principle (Thomson & Schinazi, *Maintaining Robust Protocols*, RFC 9413, 2023), because accepting malformed input *without* normalising it lets each consumer decide for itself what the input meant — the spec drifts to "whatever the popular parser accepts," and the format ossifies. Parsing at the boundary keeps the forgiving front door while killing the drift: the many tolerated forms collapse to one internal representation immediately, and nothing downstream re-litigates the question.

---

## Identity and typed IDs

The definitions above drew the line at equality-by-value, and the *When NOT to* below marks its far side: a `Customer` is not a value object, because two customers who share every field are still two customers. That far side has its own smallest primitive, and it is built from the very same machinery — dialled all the way down to one field.

**The typed ID is a value object with the validation removed.** An `OrderId` wraps a single `Guid`; a `CustomerId` wraps another. Same shape as the value objects above — hidden constructor, equality-by-value, immutable — but the invariant is trivial or absent: any `Guid` is a fine `OrderId`, so the factory may not even return a `Result`. The point is not validation; it is *type-distinction*. This is Wlaschin's "single-case union"[2] at its purest — a one-case wrapper that carries no rule, only a name. And it pays the same dividend as Why #3 above: a `Refund(CustomerId, OrderId)` signature cannot take its arguments in the wrong order, because `CustomerId` and `OrderId` are different types. The swapped-argument bug that two bare `Guid`s would compile away is gone — the compiler retires that [Connascence of Position](axiom-08-connascence.md#connascence-of-position-cop) the same way it did for `Username` and `EmailAddress`.

**Equality-by-key is the complement of equality-by-value.** A value object is equal by its full contents; an identity-bearing thing is equal by a single *key field*. Two snapshots of the same order — one before shipping, one after — differ in nearly every field and are still the *same order*, because their `OrderId` matches. Two orders with byte-for-byte identical contents but different `OrderId`s are *different orders*. That is the exact mirror of the equality-by-value rule from the Definitions: where a value object asks *"is all the data the same?"*, an identified thing asks *"is the key the same?"* — and it is precisely why a value object needs no ID (its data *is* its identity) while an identified thing needs one (its data is not).

**Why the ID has to be carried in the data — the immutability bridge.** This is the load-bearing point, and it follows from a decision made three axioms back. [Axiom 8](axiom-08-connascence.md) named [Connascence of Identity](axiom-08-connascence.md#connascence-of-identity-coi) the strongest binding on its scale — two holders depending on referencing *the same instance* — and noted that this playbook's immutable-value model is built to *dissolve* it: an immutable value has no mutable cell to alias, so two holders of "equal" values can never silently diverge, because there is nothing to mutate. But dissolving reference-identity has a consequence. Once a reference no longer carries identity, the question *"which thing is this?"* can no longer ride on the object reference the way it does in a mutable, reference-tracked model. Identity has to go *somewhere* — and the only honest place left is *inside the data*, as an explicit key field. So the typed ID is not decoration: it is where identity lives once we have taken it off the reference. A value object needs no ID because it has no identity to carry; an identity-bearing thing — one that persists and changes across a lifetime while staying the same thing — needs an explicit one for exactly that reason.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public readonly record struct OrderId(Guid Value)
{
    public static OrderId New() => new(Guid.NewGuid());
}

// Equal by Value (the key), not by the rest of the contents.
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
    public static OrderId newId() { return new OrderId(UUID.randomUUID()); }
}

// Equal by id (the key), not by the rest of the contents.
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

`OrderId` is the value object's machinery with the rule subtracted; `Order` is the same immutable record, but its equality is overridden to read the key alone. Two `Order` values with the same `Id` are the same order regardless of how their `Total` or `Status` has moved; two with different `Id`s are different orders however alike their contents.

---

## Trade-offs

**Boilerplate.** A value object is irreducibly more code than a primitive. C# softens this with positional records and expression-bodied factories; Java is more verbose, particularly the `equals` / `hashCode` / `toString` triple a `final class` requires. The cost is real and proportional to the number of domain types; the answer is to make value objects only for the rules that *exist*, not for every conceivable primitive.

**Java records cannot enforce private construction.** A `public record` has a public canonical constructor by language rule. The two options are: declare the value object as a `final class` (shown in the example above) and write `equals` / `hashCode` by hand, or accept the public canonical constructor as a soft convention and rely on code review to prevent direct use. The playbook prefers `final class` for true value objects; lean teams sometimes use the public-constructor convention for the cheapest wins. Either choice should be made once per codebase, not per type.

**Mapping at the persistence boundary.** ORMs and serialisers expect public constructors or settable properties; value objects with private constructors do not fit by default. The discipline is to map *at the boundary* — a converter that reads a row into the primitive, calls `From`, and surfaces a `Failure` as a startup error if the database somehow holds a value the current type refuses. This is the same boundary work the impure shell does for every other primitive coming in; the value object simply joins the queue.

**One Result per construction; composing many is the next concern.** A handler that builds three value objects from three raw strings has three `Result` values to handle. Manual early-return on each one works and is the right shape for a single value; with several it becomes mechanical. The combinators from [Axiom 17](axiom-17-result-combinators.md) apply directly — value-object factories are exactly the fallible step `Bind` was designed for — and a later axiom develops the pattern for composing many. For now the building block is the lone smart constructor.

---

## When NOT to

**A primitive with no invariant.** A field that is "any string, even empty, even arbitrary length" gains nothing from being wrapped in a `SomeString` value object whose factory always returns `Success`. The boilerplate is pure cost. Use the primitive. The discipline earns its keep when there is a *rule* to enforce.

**At the I/O boundary, where primitives are mandatory.** The function that reads a JSON body, the one that writes a database row, the one that constructs an outgoing HTTP request — these speak the wire format, which is primitives. The conversion is the boundary's job ([Axiom 12](axiom-12-impureheim.md)); the value object lives one layer in. Pushing value objects *into* the JSON deserialiser is not the point of this axiom.

**Entities with identity.** A `Customer` whose two instances are different even when their data is identical — because they refer to different rows, different aggregates, different things in the world — is not a value object. Two `EmailAddress("a@b.com")` are the same email; two `Customer` instances representing two customers who happen to share a name are not the same customer. Equality-by-value is the wrong relation for identity-bearing types; force-fitting it produces subtle bugs. Value objects are for the *attributes* of those entities, not the entities themselves — and the entities get their own smallest primitive, the typed ID, with equality by key rather than by contents (see *Identity and typed IDs* above).

**Single-use throwaways.** A short script, a one-off migration, a one-page tool whose lifetime is measured in days. The cost of writing the value object is fixed; the benefit accrues with reuse and with the number of callers that would otherwise re-check. A program with three call sites and a one-week lifetime does not amortise the cost.

---

## References

[1] **Alexis King**, *Parse, Don't Validate*, lexi-lambda.github.io, 2019. Cross-listed from [Axiom 6](axiom-06-honest-total-signatures.md). The essay's central claim — that the difference between a validating function (returns a `bool` next to the original primitive) and a parsing function (returns a validated type or a structured failure) is the difference between dishonest and honest signatures — is *the* foundational argument for value objects with smart constructors. This axiom is the operational form of that essay.
<https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/>

[2] **Scott Wlaschin**, *Designing with Types: Making Illegal States Unrepresentable*, fsharpforfunandprofit.com, 2013. Cross-listed from [Axiom 6](axiom-06-honest-total-signatures.md). The "single-case union" pattern in the series — wrapping a primitive in a one-case discriminated union with a smart constructor — is the F# equivalent of the C# / Java records here, and the series develops the discipline across a whole domain model.
<https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/>

[3] **Eric Evans**, *Domain-Driven Design: Tackling Complexity in the Heart of Software*, Addison-Wesley, 2003. The original treatment of "Value Object" as a domain modelling pattern — immutable, equality-by-value, no identity — distinguished from "Entity." Evans does not specify the smart-constructor-returning-Result shape (DDD predates the mainstream FP-in-OO renaissance); the equality-and-immutability half of this axiom's definition is his.
<https://www.domainlanguage.com/ddd/>

[4] **Vladimir Khorikov**, *CSharpFunctionalExtensions* (v3.7.0, March 2026). Cross-listed from [Axiom 16](axiom-16-result.md) and [Axiom 17](axiom-17-result-combinators.md). The library's `ValueObject` base class and the recipes in Khorikov's writing on the smart-constructor pattern are the practical .NET reference the C# example here is shaped after.
<https://github.com/vkhorikov/CSharpFunctionalExtensions>

---

← Previous: [Axiom 17 — Result combinators](axiom-17-result-combinators.md) · Next: [Axiom 19 — Railway](axiom-19-railway.md) →
