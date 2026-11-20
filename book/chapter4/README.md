# Chapter 4 — Concurrency: code in time

> "Concurrency is about dealing with lots of things at once. Parallelism is about doing lots of things at once."
> — Rob Pike [1]

> "Threads, as a model of computation, are wildly nondeterministic, and the job of the programmer becomes one of pruning that nondeterminism."
> — Edward A. Lee [2]

> "[O]bservable nondeterminism should be supported only if its expressive power is needed. This is especially true for concurrent programming."
> — Peter Van Roy [3]

[Chapter 2](../chapter2/README.md) is about the *shape* of code: what data is, what a function receives and returns, how functions compose. This chapter is about a second dimension, **time**: which steps of a program may overlap, and what can go wrong when they do.

[Chapter 3](../chapter3/README.md) said how to test code shaped that way. Most of it still holds here. Each model below says what time adds on top.

> **Draft.** The ladder, its why and the four models are here. Some examples and sources are still to do (see *Open questions*).

---

## Two dimensions

Chapter 2 already brushed against time twice:

- **The pure/impure split is a split in time.** A pure function ([Axiom 6](../chapter2/axiom-06-pure-functions.md)) gives the same result whenever, however often and on whichever thread it runs: it is timeless. An impure one ([Axiom 5](../chapter2/axiom-05-impure-functions.md)) depends on *when* it runs and on what ran before it. Normand calls such a sequence of actions a *timeline* [4].
- **[Connascence of Timing](../chapter2/axiom-09-connascence.md#definitions)** is the coupling Chapter 2 named and set aside: two units that must agree on how their steps interleave. This chapter is where it lands.

Two words get mixed up here, and the difference matters:

- **[Parallelism](https://en.wikipedia.org/wiki/Parallel_computing)** is about *running*: more cores, the same answer, sooner. It is a property of execution. A program that is only parallel means the same thing as its sequential version.
- **[Concurrency](https://en.wikipedia.org/wiki/Concurrency_(computer_science))** is about *structure*: several timelines of control whose steps can interleave. It is a property of the program, and it brings [nondeterminism](https://en.wikipedia.org/wiki/Nondeterministic_algorithm): the specification no longer says which step comes first.

Marlow states both halves [8]:

- "A parallel program is one that uses a multiplicity of computational hardware (e.g., several processor cores) to perform a computation more quickly."
- "Concurrent programming models are necessarily nondeterministic because they must interact with external agents that cause events at unpredictable times."

Harper draws the same line: "Concurrency is concerned with *nondeterministic composition* of programs (or their components)", while "Parallelism is concerned with *asymptotic efficiency* of programs with *deterministic* behavior" (emphasis in the original) [7].

Parallelism is an execution choice, made for speed. Concurrency is where the bugs come from. This chapter is mostly about the second.

---

## What can race

Nondeterminism alone is harmless. Two independent timelines can run in any order and still give one answer. It turns into a bug when the order *shows*. Van Roy calls this **observable nondeterminism**, and gives it its everyday name: "Observable nondeterminism is sometimes called a race condition" [3].

A race needs three things at once, as [Axiom 3](../chapter2/axiom-03-immutability.md#why) says: data **shared** between timelines, data that is **mutable**, and at least one timeline **writing** it. Every model in this chapter is a way to remove one of the three, or to confine it to one small, visible place.

---

## The ladder

Van Roy orders the ways to write concurrent code by how much observable nondeterminism they allow [3]. I use four rungs:

| Model | What is shared | What can race | Typical code |
|---|---|---|---|
| **0. [Sequential](01-sequential.md)** | nothing: one timeline | nothing | a handler that gathers, decides and acts, one step after the other |
| **1. [Deterministic concurrency](02-deterministic-concurrency.md)** | nothing mutable: children get values and return values | nothing, while the children stay independent | a parallel map over a pure function; independent reads run together; independent units of work |
| **2. [One owner](03-one-owner.md)** | messages, sent to the one timeline that owns the state | only the order messages arrive in | an in-memory state that one loop updates and everyone else sends requests to |
| **3. [Shared state](04-shared-state.md)** | a mutable place: a field, a row | anything that touches that place | a reference swapped by several threads; two requests writing the same row |

**Use the lowest rung that does the job.** It is Van Roy's rule in the quote above, and it is this book's north star applied to time: each rung up admits more orderings, and every ordering is one more case to reason about.

The rungs are not an invention. Van Roy reports that four unrelated language projects, Erlang among them, ended with the same layers: "a strict functional core, followed by declarative concurrency, then asynchronous message passing, and finally global named state" [3]. The strict functional core is [Chapter 2](../chapter2/README.md). This chapter is the three layers above it.

Each rung is a **model**, not an axiom. An axiom is a building block used always. A model is chosen per situation, and the best choice is usually the lowest.

---

## Who starts it

The ladder says *how much* can race. A second question says *who decides*:

- **Rungs 0 to 2 are chosen by your code.** You spawn the children, or you don't. You start the owning loop, or you don't.
- **Rung 3 can be forced on you by the host.** A web server runs requests concurrently. A queue consumer with more than one message in flight, or a second instance of the service, does the same with events. Two of them that touch the same row are at rung 3, even if every line of your code is sequential.

This is the rung most line-of-business code lives on without noticing: the shared state is a database row, and the timelines are requests.

The host can also push you back *down*. A single consumer that handles one event at a time turns the whole service into rung 0 at the level of events. That is a real guarantee, but it comes from the deployment, not from the code: scale out to a second instance, and it is gone without a line changing. When you rely on it, write it down next to the handler.

This axis is mine. I haven't found it named in the sources below.

---

## Testing

Testing here sits on [Chapter 3](../chapter3/README.md). The levels don't change; what changes is how much of the code depends on time.

- **The lower the rung, the more of the code is tested without time.** At rungs 0 and 1, every decision is a pure function with function tests ([Chapter 3](../chapter3/README.md#what-i-do-today)). Their results can't depend on scheduling, so they can't flake.
- **What time adds is tested at component level.** The behavior of a scope (a failure cancels the siblings), the conflict between two writers, an owner's response to a burst of messages: these run through the component's API, with its real dependencies.
- **A passing test can show a race, never its absence.** The interleaving that breaks the code may not happen in a thousand runs. That is the strongest reason to design down the ladder instead of testing up: at rungs 0 and 1 there is nothing to catch.

Each model has its own *Testing* section with what that rung adds.

---

## Scope

In scope: which rung a piece of code is on, what can race there, when to step up, and how to test it.

Out of scope:

- **Runtimes and libraries.** The models apply to any language. How .NET or the JVM spell them (`Task.WhenAll`, `StructuredTaskScope`, EF concurrency tokens, jOOQ optimistic locking) belongs in the [Plays](../chapter5/README.md) and in ADRs. The examples use only the basics of each language.
- **Below the models:** memory models and safe publication, lock-free data structures, thread-pool sizing, schedulers.
- **Above them:** distributed locks, sagas, the outbox, consensus. These are system topology, out of scope for the whole book.

### Where the ladder stops

Every rung assumes one place that holds the truth: one process, one owner, one row. Some programs keep several copies of the same data instead, each changed on its own and merged later: a collaborative editor, an offline-first mobile app, a database that accepts writes in several regions. There is no single place to compare-and-swap against. Two families of techniques handle that case:

- **[Conflict-free replicated data types](https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type)** (CRDTs): data types whose copies always merge to the same result. A state-based CRDT merges with a function that is commutative, associative and idempotent; an operation-based one requires its operations to commute [5]. Shapiro et al. say their model, Strong Eventual Consistency, "avoids the complexity of conflict resolution and of roll-back" [5].
- **[Operational transformation](https://en.wikipedia.org/wiki/Operational_transformation)** (OT): each operation is adjusted against the concurrent ones before it is applied, so every copy ends in the same state [6]. It is the classic technique behind collaborative text editors.

Replication is system topology, so this book stops here. Both techniques are usually reached through a library or a database feature, which is a choice for an ADR. What carries over is their central idea, and the ladder already uses it: an update whose order can't show. An associative combine in [Model 1](02-deterministic-concurrency.md#parallel-map), commutative messages in [Model 2](03-one-owner.md#example), idempotent transitions in [Model 3](04-shared-state.md#in-the-database-version-checked-writes). A CRDT is that idea applied across machines.

---

## Open questions

- **Testing beyond component tests.** Deterministic schedulers, stress tests and model checkers try to find races that component tests miss. To research: what they cost, and whether any belongs in this book.
- **Sources to verify before citing:**
  - Brian Goetz et al., *Java Concurrency in Practice*, Addison-Wesley, 2006, chapter 2: the three fixes for shared mutable state (don't share it, make it immutable, or synchronize every access). Only read through third-party notes; the publisher's free sample is chapter 6.
  - Martin Kleppmann, *Designing Data-Intensive Applications*, O'Reilly, 2017, chapter 7: lost updates and how databases prevent them. Only read through third-party notes; the table of contents is behind a paywall.

---

## References

[1] **Rob Pike**, *Concurrency is not Parallelism*, talk at Heroku's Waza conference, 2012. Concurrency is the composition of independently executing processes; parallelism is their simultaneous execution.
<https://go.dev/talks/2012/waza.slide>

[2] **Edward A. Lee**, *The Problem with Threads*, Technical Report UCB/EECS-2006-1, University of California, Berkeley, January 2006; also in IEEE Computer 39(5), 2006. Instead of pruning the nondeterminism of threads, build from deterministic, composable parts and add nondeterminism only where it is needed.
<https://www2.eecs.berkeley.edu/Pubs/TechRpts/2006/EECS-2006-1.html>

[3] **Peter Van Roy**, *Programming Paradigms for Dummies: What Every Programmer Should Know*, 2009. Paradigms ordered by whether they can express observable nondeterminism and named state; message passing as the right default over shared state. The full treatment is in Van Roy and Haridi, *Concepts, Techniques, and Models of Computer Programming*, MIT Press, 2004, chapters 4, 5 and 8.
<https://webperso.info.ucl.ac.be/~pvr/VanRoyChapter.pdf>

[4] **Eric Normand**, *Grokking Simplicity*, Manning Publications, 2021. Also cited in [Axiom 5](../chapter2/axiom-05-impure-functions.md) and [Axiom 6](../chapter2/axiom-06-pure-functions.md). Chapters 15 to 17 draw actions on timelines, and work through isolating them, sharing resources between them and coordinating them.
<https://www.manning.com/books/grokking-simplicity>

[5] **Marc Shapiro, Nuno Preguiça, Carlos Baquero and Marek Zawirski**, *Conflict-free Replicated Data Types*, SSS 2011, LNCS 6976, pp. 386–400; extended as INRIA research report RR-7687, 2011. Strong Eventual Consistency, and the two sufficient conditions for it: a merge that is a least upper bound in a semilattice (commutative, idempotent, associative), or operations that commute.
<https://doi.org/10.1007/978-3-642-24550-3_29>

[6] **Clarence A. Ellis and Simon J. Gibbs**, *Concurrency Control in Groupware Systems*, SIGMOD 1989, pp. 399–407. The origin of operational transformation: each operation runs at once where it was made, and is transformed against concurrent ones where it arrives. Only read through its abstract.

[7] **Robert Harper**, *Parallelism Is Not Concurrency*, Existential Type blog, 17 March 2011. Concurrency is nondeterministic composition; parallelism is the efficiency of deterministic programs, and "has nothing to do with concurrency".
<https://existentialtype.wordpress.com/2011/03/17/parallelism-is-not-concurrency/>

[8] **Simon Marlow**, *Parallel and Concurrent Programming in Haskell*, O'Reilly, 2013, chapter 1, *Terminology: Parallelism and Concurrency*. Parallelism is concerned only with efficiency; concurrency is a way to structure a program with several threads of control, and is necessarily nondeterministic.
<https://www.oreilly.com/library/view/parallel-and-concurrent/9781449335939/ch01.html>

---

← Previous: [Chapter 3 — Testing](../chapter3/README.md) · Next: [Model 0 — Sequential](01-sequential.md) →
