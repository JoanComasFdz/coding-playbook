# Axiom 22 — Make illegal states unrepresentable

**A thing that is in exactly one of several states should be a *sum* of per-state records, not a *product* of optional fields. Each field lives only on the state where it is meaningful; the states collect under a sealed DU ([Axiom 21](axiom-21-discriminated-unions.md)). A record with *k* nullable flags admits 2ᵏ field combinations and most of them are illegal; the sum admits exactly the legal ones, and the compiler refuses to construct any other. This is [Axiom 18](axiom-18-value-objects.md)'s "make illegal *values* unrepresentable" raised from a single value to the *shape* of a whole record.**

- Model each state as its own immutable record ([Axiom 2](axiom-02-immutability.md)); gather the records under one sealed parent ([Axiom 21](axiom-21-discriminated-unions.md)).
- A field appears only in the variants where it is always present — never as a nullable "set once we reach state X." If it is non-null in `Paid`, it is *absent* from `Pending`, not nullable on a shared record.
- Consumers branch with exhaustive pattern matching ([Axiom 11](axiom-11-pattern-matching.md)); adding a state breaks every match until it is handled — a compile-time event, not a runtime surprise.
- This axiom is **data only** — it shapes how state is *represented*, not how it changes. The behaviour that moves between states comes later in the chapter; getting the representation honest first is what makes that behaviour cheap to add.

[Axiom 18](axiom-18-value-objects.md) made a *single value* honest — `Username.From("")` cannot exist. This axiom makes a *combination* of values honest: a `Paid` bill cannot exist without its payment reference, and a `Pending` bill cannot carry one. [Axiom 21](axiom-21-discriminated-unions.md) gave the mechanism — a sealed type whose variants each carry their own payload — with computation *outcomes* as the motivating example (approved / declined / step-up). This axiom points that same mechanism at the *persistent shape of a domain thing across its lifecycle*. It is the gentlest member of the family and the one reached for most: long before an engineer needs anything heavier, they need to stop modelling a five-state entity as one record with nine nullable fields.

Through [Axiom 8](axiom-08-connascence.md)'s lens, this axiom weakens a [Connascence of Value](axiom-08-connascence.md#connascence-of-value-cov) among a record's nullable fields — the unwritten invariant binding which combinations may co-occur — into a Connascence of Type, so the illegal combinations cannot be built.

The slogan is older than typed FP's adoption of it: a *product* type (a record) represents "A **and** B **and** C — all present at once"; a *sum* type (a DU) represents "A **or** B **or** C — exactly one at a time." A lifecycle is an *or*. Modelling it as a product and then nulling out the fields that do not apply to the current case is using the wrong half of the algebra, and every `if (x != null)` downstream is the interest paid on that mistake.

---

## Definitions

Records and DUs are the two constructors of an *algebraic data type* (ADT): a record is a **product type**, a sealed DU ([Axiom 21](axiom-21-discriminated-unions.md)) a **sum type**. The names are literal arithmetic, and that arithmetic — worked below — is the whole argument of this axiom.

- **Product type.** A record whose value is *all* of its fields at once — `Bill(Id, Amount, Status, ProcessedAt, SentAt, PaymentRef, FailureReason)`. Its set of representable values is the Cartesian product of its fields' value sets; making fields nullable multiplies that set, and the legal subset is a small island in a large sea of nonsense (`Pending` with a `PaymentRef`, `Paid` with a null one).

- **Sum type.** A sealed family whose value is *exactly one* of its variants — `Bill = Pending | Processing | Processed | Sent | Paid | Failed`. Its set of representable values is the *sum* of the variants' value sets. When each variant carries only the fields valid in that state, the representable set and the legal set coincide: there is no illegal value to construct.

- **Counting the states.** The arithmetic is a smell detector. A record of two booleans is a product — 2 × 2 = **4** representable values. If the concept it models has only **3** legal combinations, one of the four is nonsense the compiler still lets you construct; that gap — *representable minus legal* — is the bug surface every downstream `if` pays for. A sum of three single-case variants is 1 + 1 + 1 = **3**: representable equals legal, the gap is zero. The move is mechanical — count what the type can represent, count what the domain allows, and when the product can say more than the domain permits, a sum collapses it to exactly the legal count. The gap runs the other way too. When a type represents *fewer* states than the domain allows — a list capped at three because three was convenient, an enum missing a case the business already uses — a **legal** state has been made unrepresentable: the same arithmetic, mirrored. The cure is the opposite move, loosen until representable meets legal — a plain (possibly empty) collection where the cap was invented, or, where the bound is a *real* rule the business can name, a value object ([Axiom 18](axiom-18-value-objects.md)) whose `Add` returns a `Result` failure when the bound is exceeded. The number is never the smell; an *unjustified* number is — and whether a bound is justified is a domain question the type can only record, not decide.

- **The refactor.** Take the discriminator (a `Status` enum, or "which fields are non-null") and the fields gated behind it, and promote each discriminator case to its own record carrying exactly its fields. The enum disappears into the variant *type*; the nullable fields disappear into the variants that own them.

This axiom replaces three mainstream defaults:

- **The bag-of-optionals record.** One class with every field any state might need, most of them nullable, plus a `Status` enum to say which are "currently valid." The convention "`ProcessedAt` is set once `Status >= Processed`" lives in comments and tribal knowledge; the compiler enforces none of it, and every method that touches `ProcessedAt` either re-checks the status or risks a `NullReferenceException`.

- **The nullable field as state flag.** `endTime == null` means "open." State-by-absence: the reader must know the convention, the type says nothing, and a field valid in one state is a nullable trap in another.

- **The "this is only used when…" comment.** A field documented as conditionally meaningful. The comment is the spec; the type is silent. Promote the condition to a variant and the comment becomes a type the compiler reads.

---

## Example

A bill that moves `Pending → Processing → Processed → Sent → Paid`, with a `Failed` branch. First as one record with a status enum and the fields each later state needs — every field nullable, every illegal combination representable:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public enum BillStatus
{ Pending, Processing, Processed, Sent, Paid, Failed }

public sealed record Bill(
    BillId Id,
    Money Amount,
    BillStatus Status,
    DateTime? ProcessedAt,   // set once Processed
    DateTime? SentAt,        // set once Sent
    string? PaymentRef,      // set once Paid
    string? FailureReason);  // set only when Failed

// Every illegal shape compiles:
var nonsense = new Bill(id, amount, BillStatus.Pending,
    ProcessedAt: null, SentAt: DateTime.UtcNow,   // sent but
    PaymentRef: "ref-9", FailureReason: "oops");  // also pending,
                                                  // paid, and failed
```

</td>
<td>

```java
enum BillStatus
{ PENDING, PROCESSING, PROCESSED, SENT, PAID, FAILED }

public record Bill(
    BillId id,
    Money amount,
    BillStatus status,
    Instant processedAt,   // set once PROCESSED
    Instant sentAt,        // set once SENT
    String paymentRef,     // set once PAID
    String failureReason   // set only when FAILED
) {}

// Every illegal shape compiles:
var nonsense = new Bill(id, amount, BillStatus.PENDING,
    null, Instant.now(),         // sent but also pending,
    "ref-9", "oops");            // paid, and failed
```

</td>
</tr>
</table>

The fix promotes each status to its own record carrying exactly its fields. The enum is gone; every field is non-null and present only where it is real:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public abstract record Bill(BillId Id, Money Amount);

public sealed record Pending(BillId Id, Money Amount)
    : Bill(Id, Amount);
public sealed record Processing(BillId Id, Money Amount)
    : Bill(Id, Amount);
public sealed record Processed(
    BillId Id, Money Amount, DateTime ProcessedAt)
    : Bill(Id, Amount);
public sealed record Sent(
    BillId Id, Money Amount, DateTime SentAt)
    : Bill(Id, Amount);
public sealed record Paid(
    BillId Id, Money Amount, string PaymentRef)
    : Bill(Id, Amount);
public sealed record Failed(
    BillId Id, Money Amount, string Reason)
    : Bill(Id, Amount);

// The nonsense above is no longer expressible. A reader of
// `Paid` knows PaymentRef is there; a reader of `Pending`
// knows it is not. Consumption is exhaustive:
var line = bill switch
{
    Pending          => "awaiting processing",
    Processing       => "in flight",
    Processed p      => $"processed {p.ProcessedAt:d}",
    Sent s           => $"sent {s.SentAt:d}",
    Paid p           => $"paid, ref {p.PaymentRef}",
    Failed f         => $"failed: {f.Reason}",
};
```

</td>
<td>

```java
public sealed interface Bill
    permits Pending, Processing, Processed, Sent, Paid, Failed {
    BillId id();
    Money amount();
}

public record Pending(BillId id, Money amount)
    implements Bill {}
public record Processing(BillId id, Money amount)
    implements Bill {}
public record Processed(
    BillId id, Money amount, Instant processedAt)
    implements Bill {}
public record Sent(
    BillId id, Money amount, Instant sentAt)
    implements Bill {}
public record Paid(
    BillId id, Money amount, String paymentRef)
    implements Bill {}
public record Failed(
    BillId id, Money amount, String reason)
    implements Bill {}

// The nonsense above is no longer expressible.
// Consumption is exhaustive:
var line = switch (bill) {
    case Pending p     -> "awaiting processing";
    case Processing p  -> "in flight";
    case Processed p   -> "processed " + p.processedAt();
    case Sent s        -> "sent " + s.sentAt();
    case Paid p        -> "paid, ref " + p.paymentRef();
    case Failed f      -> "failed: " + f.reason();
};
```

</td>
</tr>
</table>

`Id` and `Amount` repeat on every variant — the honest cost of the shape, named in the trade-offs below. In return, no method downstream null-checks `PaymentRef`, no comment explains when `ProcessedAt` is set, and adding a `Refunded` state turns the `switch` into a compile error at every site until it is handled.

---

## Problem / forces

When a thing occupies one of several states over its lifetime, three shapes recur:

1. **One record, all fields, a status enum.** Cheapest to write and the default an ORM or a JSON shape nudges you toward. The legal field combinations are a convention the compiler does not know; every consumer re-derives "which fields are valid now" from the status, and the nullable fields are a standing invitation to `NullReferenceException`.

2. **One record, fields nullable, no enum** (state-by-absence). The status *is* the null-pattern. Worse than 1, because now even the discriminator is implicit — the reader reconstructs the state by reading which fields happen to be set.

3. **A sum of per-state records.** Each state is its own type carrying exactly its fields. The representable set equals the legal set; the discriminator is the variant; the nullable fields are gone. The cost is more named types and repetition of the fields shared across states.

Options 1 and 2 share one disease: the record can hold field combinations the domain forbids, and nothing but discipline keeps them out. Option 3 makes the forbidden combinations unconstructable. The trade is the same one [Axiom 18](axiom-18-value-objects.md) drew for single values — a little more ceremony at the type level, paid back in every consumer that no longer re-validates.

---

## Why

**1. Illegal combinations cannot be constructed.** The 2ᵏ-shape matrix of a *k*-nullable record collapses to the handful of variants the domain actually allows. The bug class "object in an impossible state" stops being expressible, the way [Axiom 18](axiom-18-value-objects.md) made "value that breaks its rule" unconstructable.

**2. Every field is non-null where it appears.** A reader of `Paid` knows `PaymentRef` is present without a guard; a reader of `Pending` knows it is absent without a comment. The `if (x != null)` that defends a conditionally-valid field disappears along with the field's nullability.

**3. New states are a compile-time event.** Because consumers match exhaustively ([Axiom 11](axiom-11-pattern-matching.md)), adding a variant breaks every `switch` that does not yet handle it. The compiler hands you the to-do list; a status enum hands you a silent default branch.

**4. It is the groundwork behaviour is built on.** A thing that is provably in exactly one well-formed state is what any later rule for *changing* state gets to assume. Such rules stay cheap precisely because the states are already honest and exhaustive; a bag of nullable fields forces every rule to first re-establish which field combination is even valid before it can act.

---

## Trade-offs

**Shared fields repeat across variants.** `Id` and `Amount` appear on all six records. The mitigation is to factor the invariant core into its own value — a `BillCore(Id, Amount)` carried by each variant, or an abstract record holding the common fields — at the cost of one more indirection. For two or three shared fields the repetition usually reads more clearly than the extraction; past that, extract.

**Persistence requires materialisation discipline** (the same boundary [Axiom 18](axiom-18-value-objects.md) names for value objects). A row from the database arrives as columns, not as a typed `Paid` or `Pending`. The repository reads a discriminator — a status column, or which columns are non-null — and constructs the right variant; the reverse maps each variant back to a row. Without that step the database punches values into the program as the wrong shape and the guarantee is gone. EF Core models this as a discriminator column on a TPH mapping; jOOQ reads the row and the mapping code switches on the discriminator.

**The number of types grows with the number of states.** Five states is five records plus the parent. The investment is real and proportional to the lifecycle; it pays back in every consumer that stops re-checking the status. When a thing has exactly one state, this is pure overhead — see *When NOT to*.

**Transitions still need a home.** Splitting the data does not say how to move between states. Left alone, a sum of records is inert; the wiring that turns `Pending` into `Processing` is a separate concern the chapter takes up later — not something to scatter across the variants. This axiom gets the *representation* right and stops there.

---

## When NOT to

**It is genuinely a product.** When every field is always present and always valid together — a `Point(X, Y)`, a `Money(Amount, Currency)` — there is no "exactly one of" and no illegal combination to forbid. A record is the right tool; do not invent states that do not exist.

**There is only one state.** A thing with no lifecycle is one record. Splitting it into a single-variant sum is ceremony with no payoff.

**Two states differing by one optional field, no invariant.** When the only difference between states is whether a single field is set, and a null carries no risk — a `nickname` that may or may not be present — an `Option`/`Maybe` ([Axiom 13](axiom-13-maybe.md)) on one record is lighter than two variants. Promote to a sum when *more than one* field co-varies with the state, or when the wrong combination is harmful.

**What you actually need is behaviour, not shape.** If the pain is "the rules for moving between states are scattered and untestable," then reshaping the data is only half the job; the other half is the *behaviour* that drives the moves, which a later axiom covers (and which starts from exactly this shape). Reach for this axiom when the problem is representation; when it is behaviour, this is the necessary first step, not the whole answer.

---

## References

[1] **Scott Wlaschin**, *Designing with Types: Making Illegal States Unrepresentable*, fsharpforfunandprofit.com, 2013. The canonical modern treatment in a typed-FP idiom that ports directly to C# records and Java sealed interfaces — replacing a contact record's nullable email/address fields with a sum of the combinations the domain actually allows.
<https://fsharpforfunandprofit.com/posts/designing-with-types-making-illegal-states-unrepresentable/>

[2] **Yaron Minsky**, *Effective ML*, Jane Street, 2010. The "make illegal states unrepresentable" slogan. Cross-listed with [Axiom 6](axiom-06-honest-total-signatures.md), [Axiom 18](axiom-18-value-objects.md), and [Axiom 21](axiom-21-discriminated-unions.md): the principle applied to a single value is [Axiom 18](axiom-18-value-objects.md), to a record's *shape* is this axiom, and to a computation's outcomes is [Axiom 21](axiom-21-discriminated-unions.md); it recurs again later in the chapter for other facets.

[3] **Alexis King**, *Parse, Don't Validate*, lexi-lambda.github.io, 2019. The adjacent discipline: push validity into the type at the boundary so the interior never re-checks it. A sum of per-state records is "parse, don't validate" applied to a thing's *state* — parse the row into the variant once, and every consumer downstream trusts the shape.
<https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/>
