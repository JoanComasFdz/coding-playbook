# Axiom 7 — Connascence

**Two units are connascent when a change to one forces a matching change to the other to keep the system correct. Connascence is the metric for that inter-unit dependency, graded on three axes — strength (how hard it is to find and change safely), degree (how many units are bound), locality (how far apart they sit) — and ordered from weakest to strongest forms. The work is to weaken strong connascence into weak, shrink its degree, and pull connascent units closer together.**

- Weaker is better than stronger: a dependency the compiler can see (name, type) beats one carried by convention (meaning, execution order).
- Closer is better than farther: two units that must change together should be near enough that the reader finds the second when changing the first.
- Fewer is better than more: a convention three units share is worse than the same convention shared by two.

[Axiom 6](axiom-06-cohesion.md) named the metric *inside* a unit: a cohesive function has one reason to change. This axiom names the matching metric *between* units: when a change to one forces a change to another, they are connascent, and the question is no longer "does this hold together?" but "what is bound to what, and how strongly?" The two are the same question — *what changes together?* — answered from the inside and from the outside. Cohesion asks what belongs in one unit; connascence asks what survives being split across two. Where Axiom 6 warned about a "shared blast radius" without naming the shrapnel, this axiom supplies the taxonomy: every blast radius is a *kind* of connascence, and naming the kind tells you how to shrink it.

This is the playbook's second evaluative axiom, and its second lens. It builds nothing — no type, no construct comes out of it; what it gives you is vocabulary precise enough to argue about a dependency. And that vocabulary does most of its work *later*: much of the toolkit still to come is, read through this lens, one move — *turn a strong connascence into a weak one*.

---

## Definitions

**Connascence.** Two software units are connascent if a change in one requires a corresponding change in the other for the system to remain correct. It is the successor concept to *coupling* [5] — not a synonym, but a sharper instrument. "Coupling" tells you two things are connected; connascence tells you *in what way* and *how badly*, which is the part you can act on. The classic teaching pairs "low coupling" with "high cohesion" as two knobs in tension; this playbook keeps the pairing but changes the framing — cohesion is *one reason to change*, connascence is the *graded kind of cross-unit binding* — so the two read as inside and outside of one question, not as opposing dials.

**The three axes.** A given connascence is judged on three independent dimensions, and a refactor improves it by moving it along any of them:

- **Strength** — how hard the dependency is to discover and change safely. The deciding question is whether the *compiler* enforces the agreement or a *convention* does: a shared *name* or *type* breaks the build the moment it is violated, so a violation cannot ship; a shared *meaning*, *position*, *algorithm*, or *call order* is silent at compile time, and the mismatch surfaces only when something runs — a failing test, or a customer. The convention-carried forms are the strong ones.
- **Degree** — how many units share the dependency. The same convention agreed on by two units is a smaller liability than one agreed on by twelve; degree is the size of the blast radius once it goes off.
- **Locality** — how far apart the connascent units sit. Two fields in one record that must move together are trivially connascent and trivially fixed; the same dependency split across two services is the one that rots, because the reader changing one has no line of sight to the other. *High locality makes strong connascence tolerable* — this is the bridge back to Axiom 6: connascence read at reading-distance is just cohesion.

**The taxonomy, weakest to strongest.** Page-Jones splits the forms into *static* — found by reading the source, without running it — and *dynamic* — only manifest at runtime. Reading the source, weakest first:

- **Connascence of Name (CoN).** Units must agree on a name. A method and its callers agree on `getBalance`. The weakest form, and the one every program is full of: rename-aware tooling fixes it mechanically.
- **Connascence of Type (CoT).** Units must agree on a type. A function taking `Username` and the caller producing one agree on that type. Slightly stronger than name, still fully static — and, like name, the compiler is the enforcer.
- **Connascence of Meaning (CoM).** Units must agree on the *meaning* of a value with no type to carry it — a magic number, a sentinel, a status string. `0` means success and `1` means failure; `-1` means "not found"; `""` means "no name yet." Visible in the source, but invisible to the type checker: the agreement lives in heads and comments.
- **Connascence of Position (CoP).** Units must agree on the *order* of things — most commonly positional arguments. `transfer(from, to, amount)` binds every caller to that order; swap two same-typed parameters and nothing complains until money moves the wrong way.
- **Connascence of Algorithm (CoA).** Units must agree on a specific algorithm. Two ends of a channel must hash, checksum, or serialise the same way; change the algorithm on one side and the other silently rejects every message.

Dynamic — invisible in the source, surfacing only at runtime, and stronger still. Weakest first:

- **Connascence of Execution (CoE).** Units must agree on the *order in which operations run*. You must authenticate before you fetch the profile; you must open before you read. Nothing in the types forbids the wrong order — the contract is temporal, and it is enforced, if at all, by a runtime guard.
- **Connascence of Timing (CoTiming).** Units must agree on the *timing* of operations — a deadline, a window, the interleaving of two threads. This is the concurrency-and-duration form, more about runtime scheduling than the anatomy of a module, so it falls outside this playbook's scope; it is named here only to keep the ordering honest, sitting between Execution and Value.
- **Connascence of Value (CoV).** Several values must *change together* to preserve an invariant that binds them. `Total` must equal `Subtotal + Tax`; a period's `Start` must not pass its `End`; the same constant copied into two files must match. No single type carries the rule, so the agreement lives among the values themselves, kept by whoever remembers to update all of them at once.
- **Connascence of Identity (CoI).** Two or more units must reference *the very same instance* — not merely equal values, but one shared entity: two views onto a cart, two handles on a connection, two readers of a cache. The compiler sees two references of the same type and cannot tell whether they point at one object or two, so the agreement is object identity, invisible until the two silently diverge at runtime. It is the **strongest** form of all.

The literature agrees on the static/dynamic split, on Name and Type as the two weakest, and on Identity as the strongest; it is looser about the exact rank of Meaning, Position, and Algorithm among the static forms, and treats the whole sequence as approximate — even Weirich declined to fix a precise order. That precise order matters less than the line drawn through the list next.

The line this playbook cares about most is not static-versus-dynamic but **compiler-enforced versus convention-carried**, and it falls right after Type. CoN and CoT are the only forms the compiler enforces — violate them and the build breaks. From CoM onward — and CoP whenever the swapped values share a type — the type system is blind, and the agreement is kept by humans, comments, and memory; the violation waits for a failing test, or a customer. That is the same line [Axiom 5](axiom-05-honest-total-signatures.md) draws between honest and dishonest signatures, now running *between* units instead of inside one. **Weakening** a connascence means moving it across that line — a magic value lifted into a type (CoM → CoT) is the canonical step. The other two moves fall out of the remaining axes: **reduce degree** (fewer units sharing the convention) and **localise** (bring connascent units close, ideally into one). Strength has the most leverage, because turning a runtime agreement into a compile-time one is the difference between a broken build and a broken production.

---

## Examples

One minimal example of each form (all but Timing, which is out of scope), in the taxonomy's weakest-to-strongest order. Each shows the *agreement itself* — what is bound to what — and where the compiler stands on it: holding the two sides to the agreement, or blind to it. None of them shows the cure; that is the rest of the chapter's job.

### Connascence of Name (CoN)

The method and its callers must agree on a name.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// On Account:
public decimal GetBalance() => _ledger.Total;

// Every caller spells the same name.
var balance = account.GetBalance();   // rename GetBalance, and this line stops compiling
```

</td>
<td>

```java
// On Account:
public BigDecimal getBalance() { return ledger.total(); }

// Every caller spells the same name.
var balance = account.getBalance();   // rename getBalance, and this line stops compiling
```

</td>
</tr>
</table>

`GetBalance` and every site that calls it are bound by that name. It is the weakest form and the one every program is saturated with: the agreement is *compiler-enforced*, so a rename breaks the build at each site that needed updating and rename-aware tooling fixes them all for you. (The one place it bites is a name carried as a *string* — a reflection key, a JSON field, a DI registration — where the compiler is no longer watching.)

### Connascence of Type (CoT)

Caller and callee must agree on a *type*.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public readonly record struct Amount(decimal Value);
public readonly record struct Fee(decimal Value);

// Transfer and its callers agree on the types Amount and Fee.
public Receipt Transfer(Account from, Account to, Amount amount, Fee fee) { ... }

var receipt = Transfer(payer, payee, new Amount(100.00m), new Fee(2.50m));
// Hand it a Fee where it wants an Amount and the build breaks:
// Transfer(payer, payee, new Fee(2.50m), new Amount(100.00m));   // ❌
```

</td>
<td>

```java
record Amount(BigDecimal value) {}
record Fee(BigDecimal value) {}

// transfer and its callers agree on the types Amount and Fee.
public Receipt transfer(Account from, Account to, Amount amount, Fee fee) { ... }

var receipt = transfer(payer, payee,
    new Amount(new BigDecimal("100.00")), new Fee(new BigDecimal("2.50")));
// Hand it a Fee where it wants an Amount and the build breaks:
// transfer(payer, payee, new Fee(...), new Amount(...));   // ❌
```

</td>
</tr>
</table>

The caller and `Transfer` are bound by the *types* of what crosses between them. Change a parameter's type, or pass the wrong one, and the compiler refuses the call. The agreement is a type and the compiler is its enforcer — which is why CoT, with CoN, sits at the benign end of the scale.

### Connascence of Meaning (CoM)

Two units must agree on the *meaning* of a value that no type carries.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// 0 means "ok", 1 means "failed" — by convention only.
int Charge(Card card) => _gateway.Try(card) ? 0 : 1;

if (Charge(card) == 0) Confirm(order);   // the caller must know 0 means ok
```

</td>
<td>

```java
// 0 means "ok", 1 means "failed" — by convention only.
int charge(Card card) { return gateway.tryCharge(card) ? 0 : 1; }

if (charge(card) == 0) confirm(order);   // the caller must know 0 means ok
```

</td>
</tr>
</table>

`Charge` and its caller must agree that `0` means success. Nothing in the `int` records that; the meaning lives in a comment and in the heads of whoever wrote both ends. Renumber the codes — make `1` the success case — and the compiler stays silent while the caller confirms every *failed* charge. This is the first *convention-carried* form: the first the type system cannot see.

### Connascence of Position (CoP)

Callers must agree on the *order* of things — most often positional arguments.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// Four positional arguments; the order is the contract.
public Receipt Transfer(
    Account from, Account to, decimal amount, decimal fee) { ... }

// This one looks fine...
var receipt = Transfer(payer, payee, 100.00m, 2.50m);

// ...and this one compiles just as happily, with amount and fee swapped.
var oops = Transfer(payer, payee, 2.50m, 100.00m);
```

</td>
<td>

```java
// Four positional arguments; the order is the contract.
public Receipt transfer(
    Account from, Account to, BigDecimal amount, BigDecimal fee) { ... }

// This one looks fine...
var receipt = transfer(payer, payee, new BigDecimal("100.00"),
                                     new BigDecimal("2.50"));

// ...and this one compiles just as happily, with amount and fee swapped.
var oops = transfer(payer, payee, new BigDecimal("2.50"),
                                  new BigDecimal("100.00"));
```

</td>
</tr>
</table>

Every caller is bound to the *order* of the arguments. It is worth grading on the three axes: its *strength* is high wherever two parameters share a type — the compiler cannot tell `amount` from `fee`, so a swap moves the wrong money with no complaint until runtime; its *degree* is every call site at once; its *locality* is poor, since those sites sit far from the signature that fixes the order. (Where two positions hold *different* types, the compiler does catch a swap, and the connascence is far milder.)

### Connascence of Algorithm (CoA)

Two units must agree on a specific *algorithm*.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// Both ends must compute the digest the same way. Nothing checks that they do.
string tag = Sha256(payload);          // sender attaches a tag
bool ok    = Sha256(received) == tag;  // receiver re-derives it
```

</td>
<td>

```java
// Both ends must compute the digest the same way. Nothing checks that they do.
String tag = sha256(payload);            // sender attaches a tag
boolean ok = sha256(received).equals(tag);  // receiver re-derives it
```

</td>
</tr>
</table>

Sender and receiver are bound by the whole procedure. Switch one side from SHA-256 to SHA-1 and nothing fails to compile — every message simply fails verification at runtime, on the far side, long after the change was made. The agreement is an entire algorithm, carried by convention from end to end.

### Connascence of Execution (CoE)

Units must agree on the *order in which operations run*.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
var session = new Session();
session.FetchProfile();   // ❌ throws at runtime — Authenticate() must run first
session.Authenticate();   // nothing in the types forced this to come before the call above
```

</td>
<td>

```java
var session = new Session();
session.fetchProfile();   // ❌ throws at runtime — authenticate() must run first
session.authenticate();   // nothing in the types forced this to come before the call above
```

</td>
</tr>
</table>

The two calls are bound in time — authenticate, then fetch. The contract is temporal: no parameter and no return type expresses it, so the wrong order is fully writeable and is caught, if at all, by a runtime guard. It is the first purely *dynamic* form — invisible in the source, surfacing only when the program runs — and the two that follow are stronger still.

### Connascence of Value (CoV)

Several values must *change together* to keep an invariant that binds them.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// Total must always equal Subtotal + Tax — one invariant binding three values.
public readonly record struct Invoice(decimal Subtotal, decimal Tax, decimal Total);

var invoice = new Invoice(100.00m, 20.00m, 120.00m);   // consistent
// Change one value and the rest must change too — but nothing makes you:
var wrong = invoice with { Subtotal = 200.00m };       // compiles; Total still reads 120.00
```

</td>
<td>

```java
// total must always equal subtotal + tax — one invariant binding three values.
record Invoice(BigDecimal subtotal, BigDecimal tax, BigDecimal total) {}

var invoice = new Invoice(new BigDecimal("100.00"),
                          new BigDecimal("20.00"), new BigDecimal("120.00"));  // consistent
// Change one value and the rest must change too — but nothing makes you:
var wrong = new Invoice(new BigDecimal("200.00"),
                        invoice.tax(), invoice.total());   // compiles; total still reads 120.00
```

</td>
</tr>
</table>

`Subtotal`, `Tax`, and `Total` are bound by an arithmetic invariant: change one and the rest must follow, or the record quietly lies. No single type carries the rule — to the compiler they are three independent decimals — so the agreement lives *among the values*, kept by whoever remembers to touch all three. It is the dynamic cousin of Meaning: where CoM is one value whose *meaning* is conventional, CoV is several values whose *relationship* is conventional, caught (if at all) only when something reads them. It is also the precise shape [Axiom 21 — make illegal states unrepresentable](axiom-21-illegal-states.md) dissolves — store one value and derive the others, or refuse to construct the inconsistent combination, and there is nothing left to keep in sync.

### Connascence of Identity (CoI)

Two or more units must reference *the very same instance* — not merely equal values.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// summary and checkout must hold the SAME Cart instance, or they silently disagree.
var cart     = new Cart();
var summary  = new CartSummary(cart);   // holds a reference to cart
var checkout = new Checkout(cart);      // must hold that same reference

cart.Add(item);                         // both see the item — they share one instance
// Hand checkout its own equal-but-separate Cart and nothing complains — until they diverge:
var oops = new Checkout(new Cart());
```

</td>
<td>

```java
// summary and checkout must hold the SAME Cart instance, or they silently disagree.
var cart     = new Cart();
var summary  = new CartSummary(cart);   // holds a reference to cart
var checkout = new Checkout(cart);      // must hold that same reference

cart.add(item);                         // both see the item — they share one instance
// Hand checkout its own equal-but-separate Cart and nothing complains — until they diverge:
var oops = new Checkout(new Cart());
```

</td>
</tr>
</table>

`summary` and `checkout` are bound by *identity*: they must hold one and the same `Cart`, not two carts that merely compare equal. The compiler sees two `Cart` references and cannot tell whether they alias one object or two, so handing `checkout` a separate-but-equal cart compiles and the two drift apart at runtime with nothing to flag it. That invisibility is why Identity is the strongest form on the scale — and it is the one this playbook's central model is built to *dissolve* rather than weaken: immutable values have no shared mutable cell to alias, so passing a value leaves no identity for a second holder to depend on. Where genuine shared identity is unavoidable — a connection, a cache, a session — it lives in the impure shell, held in one place and fed into the pure core as a value, so the aliasing has a single visible home instead of being smeared across the call tree ([Axiom 24 — Session Context](axiom-24-session-context.md), [Axiom 25 — Stateful Shell](axiom-25-stateful-shell.md)).

---

## Problem / forces

The competing force is that **strong connascence is the path of least resistance, and it works** — right up until it doesn't. Returning an `int` status code is faster to write than giving each outcome its own type. Passing four positional arguments is faster than giving each its own type. Relying on "everyone knows you call `init()` first" is faster than encoding the order so the wrong call cannot be written. Each strong-connascence shortcut buys speed now against a debt paid later, by whoever changes one side of the agreement and discovers — at runtime, or never — that the other side needed changing too.

The trap is that strong connascence is **invisible at the moment you create it**. CoN and CoT announce themselves: the build breaks the instant they are violated, so you cannot ship a violation. CoM, a same-typed CoP, CoA, CoE, CoV, and CoI are silent — the program compiles, the happy path passes, and the dependency only speaks when a future change touches one unit and not its partner. This is the same asymmetry [Axiom 5](axiom-05-honest-total-signatures.md) draws between honest and dishonest signatures, now generalised across units: a dependency the type system can see is a dependency you cannot forget.

The second force is **over-correction**. Not every connascence is a problem to be eliminated; most code is held together by oceans of CoN and CoT, and that is fine — those are the *weak* forms, the ones tooling manages for you. The discipline is not "remove all connascence" — impossible, and the attempt produces its own tangle of indirection. It is "*don't pay in the strong forms what you could pay in the weak ones*," and "keep connascent units close." Locality is the release valve: a strong connascence between two adjacent lines is not worth a type to fix, because the reader changing one sees the other for free.

---

## Why

**1. It turns "this feels coupled" into a claim you can act on.**
"These two classes are too coupled" is a feeling; "these two classes share a Connascence of Meaning on the status codes, degree six, spread across three packages" is a diagnosis with a treatment. The taxonomy converts a vague unease into a named kind with a known weakening move, the same way [Axiom 6](axiom-06-cohesion.md) converted "this function does too much" into "this function has two reasons to change." A lens you can name is a lens you can teach, review against, and argue with.

**2. Weakening connascence moves failures from runtime to compile time.**
The strength axis is, underneath, the same axis [Axiom 5](axiom-05-honest-total-signatures.md) runs on: a dependency carried by a type fails when you build; a dependency carried by a convention fails when you run. Every strong-to-weak transformation — a magic value lifted into a type, a wrong-order call made impossible to write — buys the same thing: the compiler starts enforcing an agreement that humans were enforcing by memory.

**3. It is the unifying thread under the tools still to come.**
Read forward, the chapter keeps making one move under different names: a value whose meaning everyone re-checks becomes a type checked once; a record whose fields must agree on a convention becomes a shape where only the valid combinations can be built; an operation order enforced by a runtime guard becomes a contract the wrong call cannot violate. Each is introduced for its own reasons and stands on its own. But seen through this lens they are one idea — *weaken the connascence* — applied to values, to the shape of data, and to the order of calls.

**4. Locality reconciles it with cohesion instead of competing with it.**
The locality axis is the hinge between the two evaluative lenses. Strong connascence inside one cohesive unit is cheap, because the unit is read as a whole — the agreement and both sides of it sit in one frame. Strong connascence *across* units is expensive, because no single frame contains it. So "high cohesion" and "weak, local connascence" are not two goals to trade off; they are the same goal — *keep what changes together within one readable frame* — stated from the inside and the outside. Pulling connascent units closer (improving locality) and giving a unit one reason to change (improving cohesion) are the same hand on the same dial.

**5. The lens scales past the module — but the axiom stops at the code.**
Point connascence at services instead of functions and it still reads true: two systems that must agree on a message format are connascent, and the same *weaken / reduce degree / localise* moves apply. That is a real and useful reading — but it is *topology*, and this is a coding playbook. The axiom claims only the code-level form: connascence between signatures, records, call sites, the meanings of values, and the order of calls *within a module*. Connascence across services or processes is the same idea at architectural altitude — noted here, and left out of scope as a consumer of these building blocks rather than one of them. The cross-service distances mentioned under *locality* mark the far end of the scale; they are not an invitation to architect with the lens.

---

## Trade-offs

The real cost is that **connascence is a judgment call, like cohesion, and the compiler will not grade it for you on the axes that matter most.** It will tell you a CoN or CoT exists — those are symbols and types it tracks — but it cannot tell you that a CoM is lurking in your status codes, because to the compiler an `int` is just an `int`. The strong forms, the ones worth hunting, are exactly the convention-carried ones the type system is blind to. The axiom hands you the categories; spotting an instance in your own code is still on you.

The second cost is **the weakening is not free**. Lifting a magic value into a type means writing the type; giving two same-typed arguments distinct types means writing those types; making a wrong-order call impossible means a type per state and a transition between them. Every move up the strength axis is paid for in code that did not exist before. For a strong connascence between two distant, much-changed units, the price is obviously worth it. For one between two adjacent lines that have not changed in a year, it is ceremony. Locality is how you decide: the farther apart and the more numerous the connascent units, the more a weakening earns its keep.

---

## When NOT to

- **When the connascence is already weak and local.** Two positional arguments of different types, passed one line apart, are a Connascence of Position you should leave alone — the types make a swap a compile error, and the locality makes it visible anyway. Wrapping them in a type here only dodges a problem you do not have. Spend the weakening effort where strength *and* distance are both high.
- **When the strong form is irreducible.** Some Connascence of Algorithm cannot be weakened away — the two ends of a wire protocol genuinely must agree on the framing, and no type in your codebase reaches across the network to enforce it on the other party. The move there is not "eliminate it" but "localise and isolate it": put the shared algorithm in one place both sides depend on, so the agreement has a single home rather than being re-implemented at each end. Naming it CoA tells you it cannot be deleted, only contained — which is itself the useful answer.
- **When chasing connascence would shred locality.** The mirror of [Axiom 6](axiom-06-cohesion.md)'s warning: decomposing a unit to break an internal connascence can scatter one thought across a swarm of indirection, trading a cheap local dependency for an expensive distributed one. Internal connascence in a cohesive unit is paying rent; do not evict it into three files to satisfy a metric.

---

## References

[1] **Meilir Page-Jones**, *What Every Programmer Should Know About Object-Oriented Design*, Dorset House, 1995. The book that introduced connascence and its taxonomy, framing it explicitly as a measure that refines and subsumes the older notion of coupling.

[2] **Meilir Page-Jones**, *Fundamentals of Object-Oriented Design in UML*, Addison-Wesley, 1999. The later, more accessible treatment, where the strength / degree / locality axes and the static/dynamic ordering of the forms are laid out as the working vocabulary.

[3] **Jim Weirich**, *Connascence Examined* / *The Building Blocks of Modularity*, conference talks, 2009–2012. The talks that revived connascence for a working audience and reframed it as a practical refactoring guide — "improve a system by weakening its connascence" — rather than an academic taxonomy.

[4] **connascence.io**, *Connascence Reference*. A compact online reference for the forms and the guiding rules — useful as a lookup table once the vocabulary is in hand.
<https://connascence.io>

[5] **Wayne Stevens, Glenford Myers & Larry Constantine**, *Structured Design*, IBM Systems Journal, 1974. The origin of *coupling* and *cohesion* as design measures; connascence refines coupling into the graded, named taxonomy this axiom uses.
