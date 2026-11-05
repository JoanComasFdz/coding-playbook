# Axiom 8 — Connascence

**Two units are connascent when a change to one forces a matching change to the other to keep the system correct. Connascence measures that dependency on three axes (strength, degree and locality) and orders its forms from weakest to strongest. The work is to weaken strong connascence, shrink its degree, and pull connascent units closer together.**

- **Weaker beats stronger.** A dependency the compiler can see (a name, a type) beats one carried by convention (a meaning, an execution order).
- **Closer beats farther.** Two units that must change together should be near enough that whoever changes the first finds the second.
- **Fewer beats more.** A convention shared by three units is worse than the same convention shared by two.

[Axiom 7](axiom-07-cohesion.md) named the metric *inside* a unit: a cohesive function has one reason to change. This axiom names the matching metric *between* units: when a change to one forces a change in another, they are connascent. The question is no longer "does this hold together?" but "what is bound to what, and how strongly?".

Both axioms ask the same question, *what changes together?*, one from the inside and one from the outside. Cohesion asks what belongs in one unit; connascence asks what survives being split across two. [Axiom 7](axiom-07-cohesion.md) talked about a "shared blast radius" without naming its parts. This axiom supplies the taxonomy: every blast radius is a *kind* of connascence, and naming the kind tells you how to shrink it.

This is the second evaluative axiom, the chapter's second lens. It builds nothing: no type or construct comes out of it. What it gives you is a vocabulary precise enough to argue about a dependency. And that vocabulary does most of its work *later*: much of the toolkit still to come is, through this lens, one move: *turn a strong connascence into a weak one*.

---

## Definitions

**[Connascence](https://en.wikipedia.org/wiki/Connascence).** Two units of code are connascent if a change in one requires a matching change in the other for the system to stay correct. Page-Jones introduced the term as a refinement of [*coupling*](https://en.wikipedia.org/wiki/Coupling_(computer_programming)) [1][5]: not a synonym, but a sharper tool. "Coupling" tells you two things are connected; connascence tells you *how* and *how badly*, which is the part you can act on.

The classic teaching names "low coupling" and "high cohesion" as two separate goals. This book keeps the pair but frames it differently: cohesion is *one reason to change*, connascence is the *graded kind of binding between units*. They are the inside and the outside of one question.

**The three axes.** Each connascence is judged on three independent dimensions, and a refactoring improves it by moving it along any of them [2]:

- **Strength:** how hard the dependency is to find and to change safely. The deciding question is whether the *compiler* enforces the agreement or a *convention* does. A shared *name* or *type* breaks the build the moment it is violated, so a violation can't ship. A shared *meaning*, *position* (of values with the same type), *algorithm* or *call order* is silent at compile time; the mismatch shows up only when something runs, in a failing test or for a customer. The forms carried by convention are the strong ones.
- **Degree:** how many units share the dependency. The same convention agreed by two units is a smaller risk than one agreed by twelve. Degree is the size of the blast radius when it goes off.
- **Locality:** how far apart the connascent units are. Two fields in one record that must change together are trivially connascent and trivially fixed. The same dependency split across two services is the one that rots, because whoever changes one side can't see the other. *High locality makes strong connascence tolerable* (see *Why*, point 4).

**The forms, weakest to strongest.** Page-Jones splits them into *static* forms, which you can find by reading the source, and *dynamic* forms, which only show up at runtime [1][2]. The static forms, weakest first:

- **Connascence of Name (CoN).** Units must agree on a name: a method and its callers agree on `getBalance`. The weakest form, and every program is full of it. Rename-aware tooling fixes it mechanically.
- **Connascence of Type (CoT).** Units must agree on a type: a function that takes a `Username` and its caller agree on that type. Slightly stronger than name, still fully static, and the compiler enforces it.
- **Connascence of Meaning (CoM).** Units must agree on the *meaning* of a value that no type carries: a magic number, a sentinel, a status string. `0` means success and `1` means failure; `-1` means "not found"; `""` means "no name yet". Visible in the source, but invisible to the type checker: the agreement lives in heads and comments.
- **Connascence of Position (CoP).** Units must agree on the *order* of things, most often positional arguments. `transfer(from, to, amount)` binds every caller to that order; swap two parameters of the same type and nothing complains until money moves the wrong way.
- **Connascence of Algorithm (CoA).** Units must agree on a specific algorithm. Both ends of a channel must hash, checksum or serialize the same way; change the algorithm on one side and the other silently rejects every message.

The dynamic forms are invisible in the source, show up only at runtime, and are stronger still. Weakest first:

- **Connascence of Execution (CoE).** Units must agree on the *order in which operations run*: authenticate before fetching the profile, open before reading. Nothing in the types forbids the wrong order. The contract is about time, and it is enforced, if at all, by a runtime check.
- **Connascence of Timing (CoTiming).** Units must agree on the *timing* of operations: a deadline, a time window, how two threads interleave. This is about runtime scheduling more than the structure of a module, so it is out of scope for this book. It is named here only to keep the order complete; it sits between Execution and Value.
- **Connascence of Value (CoV).** Several values must *change together* to keep a rule that binds them. `Total` must equal `Subtotal + Tax`; a period's `Start` must not pass its `End`; the same constant copied into two files must match. No single type carries the rule, so the agreement lives among the values themselves, kept by whoever remembers to update all of them.
- **Connascence of Identity (CoI).** Two or more units must refer to *the very same instance*, not just equal values: two views onto one cart, two handles on one connection, two readers of one cache. The compiler sees two references of the same type and can't tell whether they point to one object or two, so the agreement is invisible until the two silently drift apart at runtime. It is the **strongest** form.

Sources agree on the static/dynamic split, on Name and Type as the two weakest forms, and on Identity as the strongest. They are looser about the exact order of Meaning, Position and Algorithm, and treat the whole sequence as approximate. The precise order matters less than the line drawn through the list next.

The line this book cares about most is not static versus dynamic, but **enforced by the compiler versus carried by convention**, and it falls right after Type:

- **CoN and CoT** are the only forms the compiler enforces. Violate them and the build breaks.
- **From CoM onward**, the type system is blind (for CoP, only when the swapped values share a type). The agreement is kept by people, comments and memory, and a violation waits for a failing test or a customer.

That is the same line [Axiom 6](axiom-06-honest-total-signatures.md) draws between honest and dishonest signatures, now running *between* units instead of inside one. There are three ways to improve a connascence:

- **Weaken it:** move it across that line. Lifting a magic value into a type (CoM → CoT) is the classic step.
- **Reduce its degree:** fewer units sharing the convention.
- **Localize it:** bring the connascent units close together, ideally into one.

Weakening has the most leverage, because turning a runtime agreement into a compile-time one is the difference between a broken build and a broken production system.

---

## Examples

One minimal example of each form (except Timing, which is out of scope), from weakest to strongest. Each shows the *agreement itself*, what is bound to what, and where the compiler stands: holding both sides to the agreement, or blind to it. None of them shows the cure; that is the job of the rest of the chapter.

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

`GetBalance` and every call site are bound by that name. It is the weakest form, and every program is full of it. The agreement is *compiler-enforced*: a rename breaks the build at every site that needs updating, and rename-aware tooling fixes them all for you. (The one place it bites is a name carried as a *string*, such as a reflection key, a JSON field or a DI registration, where the compiler is no longer watching.)

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

The caller and `Transfer` are bound by the *types* of what passes between them. Change a parameter's type, or pass the wrong one, and the compiler refuses the call. The agreement is a type and the compiler enforces it, which is why CoT, like CoN, sits at the harmless end of the scale.

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

`Charge` and its caller must agree that `0` means success. Nothing in the `int` says so; the meaning lives in a comment and in the heads of whoever wrote both ends. Renumber the codes (make `1` the success case) and the compiler stays silent while the caller confirms every *failed* charge. This is the first form *carried by convention*: the first one the type system can't see.

### Connascence of Position (CoP)

Callers must agree on the *order* of things, most often positional arguments.

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

Every caller is bound to the *order* of the arguments. It is worth grading on the three axes:

- **strength** is high wherever two parameters share a type: the compiler can't tell `amount` from `fee`, so a swap moves the wrong money with no complaint until runtime;
- **degree** is every call site at once;
- **locality** is poor, since those sites sit far from the signature that fixes the order.

(Where two positions hold *different* types, the compiler does catch a swap, and the connascence is much milder.)

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

Sender and receiver are bound by the whole procedure. Switch one side from SHA-256 to SHA-1 and nothing fails to compile; every message simply fails verification at runtime, on the other side, long after the change was made. The agreement is an entire algorithm, carried by convention from end to end.

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

The two calls are bound in time: authenticate, then fetch. No parameter or return type expresses that, so the wrong order can be written freely and is caught, if at all, by a runtime check. It is the first purely *dynamic* form (invisible in the source, showing up only when the program runs), and the two that follow are stronger still.

### Connascence of Value (CoV)

Several values must *change together* to keep a rule that binds them.

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

`Subtotal`, `Tax` and `Total` are bound by an arithmetic rule: change one and the others must follow, or the record quietly lies. No single type carries the rule (to the compiler they are three independent decimals), so the agreement lives *among the values*, kept by whoever remembers to update all three. It is the dynamic cousin of Meaning: CoM is one value whose *meaning* is a convention; CoV is several values whose *relationship* is a convention, caught (if at all) only when something reads them. Store one value and derive the others, or refuse to build the inconsistent combination, and there is nothing left to keep in sync.

### Connascence of Identity (CoI)

Two or more units must refer to *the very same instance*, not just equal values.

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

`summary` and `checkout` are bound by *identity*: they must hold the same `Cart`, not two carts that merely compare equal. The compiler sees two `Cart` references and can't tell whether they point to one object or two. Hand `checkout` a separate-but-equal cart and it compiles, and the two drift apart at runtime with nothing to flag it. That invisibility is why Identity is the strongest form.

It is also the one this book is built to *remove* rather than weaken. Immutable values ([Axiom 2](axiom-02-immutability.md)) have no shared mutable cell to point at, so passing a value leaves no identity for a second holder to depend on. Where real shared identity can't be avoided (a connection, a cache, a session), it lives at the edges of the program, held in one place and passed into the pure code as a value. The sharing then has one visible home instead of being spread across the call tree. Later axioms come back to that home.

---

## Problem / forces

Strong connascence is **invisible when you create it**. Only CoN and CoT break the build when violated (see the compiler line in *Definitions*). The others compile, the happy path passes, and the dependency only speaks up when a future change touches one unit and not its partner.

The competing force is that **strong connascence is the easy path, and it works**, until it doesn't:

- returning an `int` status code is faster than giving each outcome its own type;
- passing four positional arguments is faster than giving each its own type;
- relying on "everyone knows you call `init()` first" is faster than making the wrong order impossible to write.

Each shortcut buys speed now, against a debt paid later by whoever changes one side of the agreement and discovers (at runtime, or never) that the other side needed changing too.

A second force is **over-correction**. Not every connascence is a problem. Most code is held together by large amounts of CoN and CoT, and that's fine: those are the *weak* forms, the ones tooling manages for you. The goal is not "remove all connascence"; that is impossible, and trying produces its own tangle of indirection. The goal is: *don't pay in strong forms what you could pay in weak ones*, and keep connascent units close (see *When NOT to*).

---

## Why

**1. It turns "this feels coupled" into something you can act on.**
"These two classes are too coupled" is a feeling. "These two classes share a Connascence of Meaning on the status codes, with degree six, spread across three packages" is a diagnosis with a treatment. The taxonomy turns a vague unease into a named kind with a known way to weaken it, the same way [Axiom 7](axiom-07-cohesion.md) turned "this function does too much" into "this function has two reasons to change". A lens you can name is a lens you can teach, review against and argue with. Weirich's talks made exactly this case: improve a system by weakening its connascence [3].

**2. Weakening connascence moves failures from runtime to compile time.**
Every move from strong to weak (a magic value lifted into a type, a wrong-order call made impossible to write) moves a failure from runtime to compile time: the compiler starts enforcing an agreement that people were enforcing from memory.

**3. It is the thread that ties the coming tools together.**
Read ahead, and this chapter keeps making one move under different names:

- a value whose meaning everyone re-checks becomes a type that is checked once;
- a record whose fields must agree on a convention becomes a shape where only the valid combinations can be built;
- an order of operations enforced by a runtime check becomes a contract the wrong call can't break.

Each tool is introduced for its own reasons and stands on its own. But through this lens they are one idea, *weaken the connascence*, applied to values, to the shape of data and to the order of calls.

**4. Locality connects it to cohesion instead of competing with it.**
The locality axis is the hinge between the two lenses: connascence at reading distance is just [cohesion](axiom-07-cohesion.md). Strong connascence inside one cohesive unit is cheap, because the unit is read as a whole: the agreement and both of its sides are in view at once. Strong connascence *across* units is expensive, because nothing shows both sides together. So "high cohesion" and "weak, local connascence" are not two goals to trade off. They are the same goal, *keep what changes together where it can be read together*, stated from the inside and from the outside.

**5. The lens scales past the module, but this axiom stops at the code.**
Point connascence at services instead of functions and it still holds: two systems that must agree on a message format are connascent, and the same three moves apply. That is a real and useful reading, but it is *system topology*, which is out of scope for this book. This axiom covers only connascence in code: between signatures, records, call sites, the meanings of values, and the order of calls *within a module*. The cross-service distances mentioned under *locality* mark the far end of the scale; they are not an invitation to design systems with this lens.

---

## Trade-offs

- **Connascence is a judgment call, like cohesion.** The compiler only sees the weak forms (see *Definitions*); the strong ones, the ones worth hunting, are exactly what it can't see, because to the compiler an `int` status code is just an `int`. This axiom gives you the categories; spotting an instance in your own code is still up to you. A compact reference helps once the vocabulary is familiar [4].
- **Weakening isn't free.** Lifting a magic value into a type means writing the type. Giving two same-typed arguments distinct types means writing those types. Making a wrong-order call impossible means a type per state and a transition between them. Every step up the strength axis costs code that didn't exist before. For a strong connascence between two distant, often-changed units, the cost is clearly worth it. Locality decides: the farther apart and the more numerous the connascent units, the more a weakening pays for itself.

---

## When NOT to

- **When the connascence is already weak and local.** Two positional arguments of different types, passed one line apart, form a Connascence of Position you should leave alone. The types make a swap a compile error, and the locality makes it visible anyway. Wrapping them in a new type only solves a problem you don't have. Spend the effort where strength *and* distance are both high.
- **When the strong form can't be removed.** Some Connascence of Algorithm can't be weakened: both ends of a wire protocol really must agree on the framing, and no type in your code reaches across the network to enforce it on the other side. The move there is not to eliminate it but to localize and isolate it: put the shared algorithm in one place both sides depend on, so the agreement has one home instead of being reimplemented at each end. Calling it CoA tells you it can't be deleted, only contained, which is itself a useful answer.
- **When chasing connascence would scatter one thought.** This mirrors [Axiom 7](axiom-07-cohesion.md)'s warning. Splitting a unit to break an internal connascence can scatter one thought across a swarm of indirection, trading a cheap local dependency for an expensive spread-out one. Internal connascence in a cohesive unit is paying its rent; don't evict it into three files to satisfy a metric.

---

## References

[1] **Meilir Page-Jones**, *What Every Programmer Should Know About Object-Oriented Design*, Dorset House, 1995. Introduced connascence and its forms, explicitly as a measure that refines the older idea of coupling.

[2] **Meilir Page-Jones**, *Fundamentals of Object-Oriented Design in UML*, Addison-Wesley, 1999. The later, more accessible treatment, where the strength / degree / locality axes and the static/dynamic order of the forms are set out as a working vocabulary.

[3] **Jim Weirich**, conference talks including *Connascence Examined* (2012). They brought connascence back to a working audience and recast it as a practical refactoring guide ("improve a system by weakening its connascence") instead of an academic taxonomy.

[4] **connascence.io**, *Connascence*. A compact online reference for the forms and the rules of thumb: a useful lookup table once the vocabulary is familiar. <https://connascence.io>

[5] **Wayne Stevens, Glenford Myers & Larry Constantine**, *Structured Design*, IBM Systems Journal, 1974. The origin of *coupling* and *cohesion* as design measures; connascence refines coupling into the graded, named taxonomy this axiom uses.

---

← Previous: [Axiom 7 — Cohesion](axiom-07-cohesion.md) · Next: [Axiom 9 — First-class functions](axiom-09-first-class-functions.md) →
