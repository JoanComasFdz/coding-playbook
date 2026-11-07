# Axiom 23 — Make illegal states unrepresentable

**A thing that is always in exactly one of several states should be one record per state, gathered under a sealed parent, not one record full of nullable fields. Each field lives only on the states where it is always present, so an illegal combination can't be built.**

- Model each state as its own immutable record ([Axiom 3](axiom-03-immutability.md)) and gather them under one sealed parent: a discriminated union ([Axiom 22](axiom-22-discriminated-unions.md)).
- A field appears only where it is always set. If `Paid` has a payment reference, `Pending` doesn't have one at all; it isn't a nullable field on a shared record.
- Consumers use an exhaustive `switch` ([Axiom 12](axiom-12-pattern-matching.md)), so adding a state points at every consumer that must handle it.
- This axiom is about *data*: how a state is represented, not how it changes. How things move between states comes later in this chapter, and it is cheap precisely because the representation is honest first.

[Axiom 19](axiom-19-value-objects.md) made a single value honest: `Username.Parse("")` can't produce a `Username`. This axiom makes a *combination* of values honest: a `Paid` bill can't exist without its payment reference, and a `Pending` bill can't carry one. [Axiom 22](axiom-22-discriminated-unions.md) provided the mechanism and pointed it at the outcomes of a computation; this axiom points it at the lifecycle of a thing. It is the form of the idea you will reach for most often: long before anything heavier, you need to stop modeling something with five states as one record with nine nullable fields.

Through [Axiom 9](axiom-09-connascence.md)'s lens, it turns a [Connascence of Value](axiom-09-connascence.md#connascence-of-value-cov) among a record's nullable fields (the unwritten rule about which ones may be set together) into a [Connascence of Type](axiom-09-connascence.md#connascence-of-type-cot), so the illegal combinations can't be built.

The slogan comes from Yaron Minsky [1].

---

## Definitions

A record is a *product* type (all of its fields at once) and a DU is a *sum* type (exactly one of its cases), the two halves of an [algebraic data type](https://en.wikipedia.org/wiki/Algebraic_data_type) ([Axiom 22](axiom-22-discriminated-unions.md#definitions)). A lifecycle is an *or*: a bill is pending *or* paid *or* failed. Modeling it as a product and setting the fields that don't apply to `null` uses the wrong half, and every `if (x != null)` downstream is the interest paid on that choice.

The names are literal arithmetic, and the arithmetic is a useful smell detector:

- **Count what the type can represent.** A record with two booleans can hold 2 × 2 = 4 values. A record with *k* nullable fields can hold at least 2ᵏ combinations of set and unset.
- **Count what the domain allows.** If the concept has only 3 legal combinations, one of those 4 is nonsense the compiler still lets you build. The gap between *representable* and *legal* is the bug surface every downstream `if` pays for.
- **A sum closes the gap.** Three cases, each with only its own fields, can represent 1 + 1 + 1 = 3 values: representable equals legal.

The gap can also run the other way. When a type represents *fewer* states than the domain allows (a list capped at three because three was convenient, an enum missing a case the business already uses), a legal state has become unrepresentable. The fix is the opposite move: loosen the type until it matches, using a plain collection where the cap was invented. Where the limit is a real rule the business can name, put it in a value object ([Axiom 19](axiom-19-value-objects.md)) whose `Add` returns a `Failure` when the limit is exceeded. A number in a type is never the smell; an *unjustified* one is, and whether it is justified is a question for the domain, not the type.

**The refactoring.** Take the discriminator (a `Status` enum, or "which fields are set") and the fields that depend on it, and turn each case into its own record with exactly its fields. The enum becomes the record's type; each nullable field moves into the cases that always have it. Wlaschin walks through the same refactoring in F# [2].

---

## Example

A bill moves through `Pending → Processing → Processed → Sent → Paid`, or ends in `Failed`. First as one record with a status enum:

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
    DateTimeOffset? ProcessedAt, // set once Processed
    DateTimeOffset? SentAt,      // set once Sent
    string? PaymentRef,          // set once Paid
    string? FailureReason);      // set only when Failed

// Every illegal combination compiles:
var nonsense = new Bill(id, amount, BillStatus.Pending,
    ProcessedAt: null, SentAt: now,        // pending, but sent,
    PaymentRef: "ref-9", FailureReason: "oops"); // paid and failed
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
    @Nullable Instant processedAt, // set once PROCESSED
    @Nullable Instant sentAt,      // set once SENT
    @Nullable String paymentRef,   // set once PAID
    @Nullable String failureReason // set only when FAILED
) {}

// Every illegal combination compiles:
var nonsense = new Bill(id, amount, BillStatus.PENDING,
    null, now,                // pending, but sent,
    "ref-9", "oops");         // paid and failed
```

</td>
</tr>
</table>

Then with one record per state. The enum is gone, and every field is non-null and present only where it is real:

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
    BillId Id, Money Amount, DateTimeOffset ProcessedAt)
    : Bill(Id, Amount);
public sealed record Sent(
    BillId Id, Money Amount, DateTimeOffset SentAt)
    : Bill(Id, Amount);
public sealed record Paid(
    BillId Id, Money Amount, string PaymentRef)
    : Bill(Id, Amount);
public sealed record Failed(
    BillId Id, Money Amount, string Reason)
    : Bill(Id, Amount);

var line = bill switch
{
    Pending     => "awaiting processing",
    Processing  => "in progress",
    Processed p => $"processed {p.ProcessedAt:d}",
    Sent s      => $"sent {s.SentAt:d}",
    Paid p      => $"paid, ref {p.PaymentRef}",
    Failed f    => $"failed: {f.Reason}",
    _ => throw new UnreachableException()
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

var line = switch (bill) {
    case Pending p    -> "awaiting processing";
    case Processing p -> "in progress";
    case Processed p  -> "processed " + p.processedAt();
    case Sent s       -> "sent " + s.sentAt();
    case Paid p       -> "paid, ref " + p.paymentRef();
    case Failed f     -> "failed: " + f.reason();
};
```

</td>
</tr>
</table>

The nonsense bill can no longer be written. A reader of `Paid` knows `PaymentRef` is there; a reader of `Pending` knows it isn't. `Id` and `Amount` repeat on every case, which is the honest cost of this shape (see *Trade-offs*).

---

## Problem / forces

When a thing goes through several states in its life, three shapes are common:

1. **One record with every field and a status enum.** The cheapest to write, and the shape ORMs and JSON nudge you toward. Which fields are valid in which status is a convention the compiler doesn't know ("`ProcessedAt` is set once the status reaches `Processed`"), so every consumer re-derives it from the status, and every nullable field invites a `NullReferenceException`.
2. **One record with nullable fields and no enum.** The state *is* the pattern of nulls: `endTime == null` means "still open". Worse than the first, because even the discriminator is implicit, and the reader reconstructs the state from which fields happen to be set. A comment like "only used when…" is the same thing: the comment is the spec, and the type says nothing.
3. **One record per state.** Each state is its own type with exactly its fields. What the type can represent equals what the domain allows. The cost is more types and some repeated fields.

The first two share one problem: the record can hold combinations the domain forbids, and only discipline keeps them out. The third makes them impossible to build. It is the trade [Axiom 19](axiom-19-value-objects.md) made for single values: a little more code in the types, paid back in every consumer that no longer re-checks [3].

---

## Why

**1. An impossible state can't be built.**
The 2ᵏ combinations of a record with *k* nullable fields shrink to the few states the domain allows. "Object in an impossible state" stops being a bug you can write.

**2. Every field is present where it appears.**
No `if (paymentRef != null)` guards a field that is only sometimes valid, and no comment explains when it is set. The field's nullability is gone because the field only exists where it always has a value.

**3. Changing state starts from solid ground.**
A thing that is provably in exactly one well-formed state is what any rule for *changing* state gets to assume. With a bag of nullable fields, every such rule first has to work out which combination it is looking at.

---

## Trade-offs

- **Shared fields repeat.** `Id` and `Amount` appear on all six cases. You can move them into a shared value (a `BillCore(Id, Amount)` held by each case) at the cost of one more level of indirection. For two or three shared fields the repetition usually reads better; beyond that, extract.
- **Persistence has to map states.** A database row arrives as columns, not as a `Paid` or a `Pending`. The code that reads it looks at a discriminator (a status column, or which columns are set) and builds the right case; writing does the reverse. It is the same boundary mapping as for value objects ([Axiom 19](axiom-19-value-objects.md#trade-offs)). EF Core supports a discriminator column through its table-per-hierarchy mapping; with jOOQ, the mapping code switches on the discriminator.
- **More states, more types.** Five states mean five records plus the parent. The cost grows with the lifecycle, and it pays back in every consumer that stops re-checking the status.
- **Moving between states still needs a home.** Splitting the data doesn't say how a `Pending` becomes `Processing`. Don't scatter those rules across the cases; a later axiom gives them one place. If what hurts today is scattered, untestable transition rules, this axiom is the necessary first step, not the whole answer.

---

## When NOT to

- **It really is a product.** When every field is always present and valid together (`Point(X, Y)`, `Money(Amount, Currency)`), there is no "one of" and nothing illegal to forbid. A record is the right tool.
- **There is only one state.** A thing with no lifecycle is one record. A single-case union is ceremony with no payoff.
- **One optional field, and no rule about it.** When the only difference is whether one field is set, and its absence harms nothing (a `nickname` that may be missing), an optional field ([Axiom 14](axiom-14-maybe.md)) on one record is lighter than two cases. Split into cases once *more than one* field varies with the state, or when the wrong combination does harm.

---

## References

[1] **Yaron Minsky**, *Effective ML*, talk for Harvard's first-year OCaml course, 2010, and *Effective ML Revisited*, Jane Street blog, 9 March 2011, where "Make illegal states unrepresentable" is one of the headings.
<https://blog.janestreet.com/effective-ml-revisited/>

[2] **Scott Wlaschin**, *Designing with Types: Making Illegal States Unrepresentable*, fsharpforfunandprofit.com, 2013. Also cited in [Axiom 7](axiom-07-honest-total-signatures.md). Replaces a contact record's optional email and address fields with a sum of the combinations the domain actually allows; the F# ports directly to C# records and Java sealed interfaces.
<https://fsharpforfunandprofit.com/posts/designing-with-types-making-illegal-states-unrepresentable/>

[3] **Alexis King**, *Parse, Don't Validate*, 2019. Also cited in [Axiom 7](axiom-07-honest-total-signatures.md) and [Axiom 19](axiom-19-value-objects.md). One record per state is "parse, don't validate" applied to a thing's state: read the row into the right case once, and every consumer downstream can trust the shape.
<https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/>

---

← Previous: [Axiom 22 — Discriminated unions](axiom-22-discriminated-unions.md) · Next: [Axiom 24 — Pure functions returning actions](axiom-24-pure-functions-returning-actions.md) →
