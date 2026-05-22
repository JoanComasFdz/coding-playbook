# Axiom 1 — Data is not Behaviour

**Data is inert fact. Behaviour is transformation. Keep them apart.**

- Model facts as plain, immutable data.
- Put business logic in functions whose result depends only on the data handed to them.

Most of the other axioms are derived from it.

---

## Definitions

> Behaviour should reside in functions whose behaviour does **not** depend on data that is
> encapsulated in the function's context.
Yehonathan Sharvit's Principle #1

It says one structural thing: **do not hide state behind behaviour.**

- **Data** is a *value*: a representation of something that is true — a name, a set
  of line items, a timestamp. It *is* a fact; it does not act.
- **Behaviour** is an *operation*: data goes in; data may come out. It *acts*;
  it holds no state of its own.

This axiom rejects the mainstream default of **fusing** the two: the object
that owns mutable state *and* the methods that quietly operate on that state.

---

## Problem / forces

When modeling a domain, engineers have to keep doing things to it: reason about it, test it,
reuse logic, serialise it, send it across a wire, store it for years, run it on many threads,
and change it when requirements change.

The default tool the industry reaches for — an object that bundles mutable state with the
methods that mutate it — quietly works against most of those forces:

- You cannot tell what an object *is* by looking at it; you have to trace the history of
  mutations that led to its current state.
- The logic is welded to one data shape and one lifecycle, so it is hard to reuse and hard to
  test in isolation.
- The state is hidden, so concurrency means locks, and serialisation means ceremony.

The competing force pulling the other way is **cohesion** — "keep the things that change
together, together." That force is real, and the axiom does not deny it; it relocates it (see
*when NOT to*).

---

## Why

**1. Complexity — the tiebreaker.**
Fusing code and data produces an entity that is harder to understand than its parts. Separating
them lets code be reused in different contexts, tested in isolation, and tends to make systems
less complex overall. This is the cheapest large reduction in complexity available, which is
why it is Axiom 1.

**2. Data is the durable half; behaviour is the volatile half.**
The data model *is* the design — Brooks' fifty-year-old observation that, given the tables, the
flowcharts become obvious[1]; Pike's "data dominates"[2]; Torvalds ranking data structures and
their relationships above the code[3]. And the data model changes far more slowly than the logic
does. So let the stable thing drive and keep the volatile thing separate and replaceable. (This
is the durable-vs-volatile split, applied inside a single module.)

**3. Values, not places (Hickey).**
The deeper reason data should not carry behaviour is that data should be an *immutable value*,
and values are inert. Conflating data with behaviour is downstream of *place-oriented
programming*[4] — treating a fact as a mutable cell where new information overwrites old, a habit
inherited from an era when memory was scarce. A value means the same thing everywhere, forever,
with no coordination — and that is precisely the property that makes concurrency and distribution
tractable. Once your data is a value, behaviour *cannot* live inside it; the separation falls out
for free.

**4. Only data crosses boundaries.**
A value travels between services, between languages, and across years of cold storage. An
in-process method cannot travel at all. Welding behaviour onto data chains the one transmissible
thing (data) to the one parochial thing (in-process behaviour). At the system level, the only
thing that actually moves between the parts is data.

---

## Trade-offs

Sharvit is upfront about the costs[5]: separating code from data costs you **access control**
(nothing stops any code from touching any data), some **cohesion** (the data and the logic that
belongs to it no longer sit physically together), and **more named entities** to keep track of.

---

## When NOT to

Bundling state with behaviour earns its keep in one main case: when you must enforce an invariant
**atomically across mutations** — a genuine entity with identity and a lifecycle, a DDD aggregate
guarding a consistency rule that several fields must satisfy together[6]. Even there, the modern
move is to keep the *inside* of that boundary as plain immutable data transformed by pure
functions, and reserve the object boundary purely for the consistency seam — not as a general
excuse to fuse.

**Naming guard.** Do not confuse this with Mike Acton's **Data-Oriented *Design***[7], which
uses the same slogan for a *performance* argument (cache locality, memory layout) — a different
problem from the one Axiom 1 addresses, and out of scope for this playbook (see the
[playbook scope](../../README.md#scope)).

---

## References

[1] **Fred Brooks**, *The Mythical Man-Month: Essays on Software Engineering*, Addison-Wesley
(1975; Anniversary Edition 1995), ch. 9, p. 102:
> "Show me your flowcharts and conceal your tables, and I shall continue to be mystified.
> Show me your tables, and I won't usually need your flowcharts; they'll be obvious."

[2] **Rob Pike**, *Notes on Programming in C*, AT&T Bell Laboratories, February 21, 1989 —
Rule 5 ("Data dominates"):
> "Data dominates. If you've chosen the right data structures and organized things well,
> the algorithms will almost always be self-evident. Data structures, not algorithms, are
> central to programming."
>
> <http://doc.cat-v.org/bell_labs/pikestyle>

[3] **Linus Torvalds**, message to the Git mailing list, 27 June 2006 (archived at
<https://lwn.net/Articles/193245/>):
> "I will, in fact, claim that the difference between a bad programmer and a good one is
> whether he considers his code or his data structures more important. Bad programmers worry
> about the code. Good programmers worry about data structures and their relationships."

[4] **Rich Hickey**, *The Value of Values*, keynote at JaxConf 2012 (also delivered at
GOTO Copenhagen 2012). Recording on InfoQ, published 14 August 2012:
<https://www.infoq.com/presentations/Value-Values/>. Coined "place-oriented programming
(PLOP)" for the habit of treating a memory cell as the location of a fact, and argued that
values — immutable, location-independent — are what make concurrency and distribution tractable.

[5] **Yehonathan Sharvit**, *Data-Oriented Programming: Reduce software complexity*, Manning
Publications, 2022. The four-principle codification of DOP; the costs of separating code from
data (no access control by language, weaker cohesion, more named entities) are spelled out in
the chapters on Principle #1 (Separate code from data) and summarised in Appendix A.
<https://www.manning.com/books/data-oriented-programming>

[6] **Eric Evans**, *Domain-Driven Design: Tackling Complexity in the Heart of Software*,
Addison-Wesley, 2003 — Chapter 6 introduces the **Aggregate** as a consistency boundary: a
cluster of associated objects treated as a unit for the purpose of data changes, with one
entity chosen as the root through which the boundary's invariants are enforced.

[7] **Mike Acton**, *Data-Oriented Design and C++*, keynote at CppCon 2014:
<https://www.youtube.com/watch?v=rX0ItVEVjHc>. Argues for designing code around the data, its
transformations, and the hardware that runs them (cache locality, structure-of-arrays). Same
slogan as Sharvit's DOP, different argument: this branch is about *performance*, not complexity.
