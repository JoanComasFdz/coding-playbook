# Axiom 3 — Impure functions

**A function is impure when its execution performs, or depends on, any side effect.**

- One hidden read or write is enough. The label is binary; there is no "a bit impure."
- When the side effect is a *read* of external state, the function is also *non-deterministic*: same inputs in, different outputs out.

[Axiom 2](axiom-02-side-effects.md) named the side effects; this axiom names the functions that contain them. The split matters because side effects are how an application *gathers context* from the world (a database row, a clock tick, a configuration value, an incoming message) and *delivers the outcomes it decides on* (a saved record, a published event, a log line) — they are the program's plumbing. Everything else is business logic: the rules that turn gathered context into a decision. Once you can label a function impure, you can keep the two kinds of work apart.

---

## Definitions

It says one structural thing: **a function is impure if any single side effect from [Axiom 2](axiom-02-side-effects.md) appears anywhere reachable from its body — directly, transitively, in a constructor, in a captured reference, or behind an injected interface whose runtime implementation performs one.** When that effect is a *read* — the clock, a random source, a mutable singleton, the file system — the function is also *non-deterministic*: two calls with the same arguments can produce different results. The hidden read is the *cause*; the non-determinism is the *symptom* by which tests, parallel runs, and replays notice the impurity.

A function is impure when any of these is true:

- **A line in its body matches a category from Axiom 2** — a clock read, a logger call, a `throw`, a parameter mutation, a database hit, a singleton lookup.
- **A function it calls is impure** — impurity is deep. A function whose body is arithmetic plus a single `logger.info` is impure, and so is its caller, and so is the caller's caller.
- **A field or reference it captures is impure** — capturing a `DbContext`, an `HttpClient`, or a `Random` taints the function as much as constructing one inline.

This axiom rejects the mainstream default: treating "function" as a single category. In Java and C# the type system does not separate them. `int add(int, int)` and `Order placeOrder(string, List<string>)` are called the same way, declared with the same syntax, and both compile to the same kind of binding. Without a label that lives outside the type system, the question "can I cache this? parallelise this? test this without a fixture?" has no shorthand answer.

A `void` return type is the loudest tell — a function that returns nothing must be observable elsewhere — but it is not the only one. A value-returning function can carry effects too; the return value distracts from the writes happening on the side. 

Languages like C# and Java do not have a way to express in the signature of a function if it contains effects, unfortunately. so recognising impurity is therefore a *reading* discipline applied to the whole body, not a check against the signature.

---

## Example

A function whose every line touches the world:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public Guid RegisterUser(string email, string password)
{
    if (repository.ExistsByEmail(email))                        // I/O read
        throw new DuplicateEmailException(email);               // control-flow effect
    var user = new User(Guid.NewGuid(), email, hash(password)); // random read
    repository.Save(user);                                      // I/O write
    logger.LogInformation("registered {Email}", email);         // log write
    mailer.Send(new WelcomeEmail(user));                        // external message
    return user.Id;
}
```

</td>
<td>

```java
public UUID registerUser(String email, String password) {
    if (repository.existsByEmail(email))                           // I/O read
        throw new DuplicateEmailException(email);                  // control-flow effect
    var user = new User(UUID.randomUUID(), email, hash(password)); // random read
    repository.save(user);                                         // I/O write
    logger.info("registered {}", email);                           // log write
    mailer.send(new WelcomeEmail(user));                           // external message
    return user.id();
}
```

</td>
</tr>
</table>

Six distinct effects in seven lines, none of them named in the signature `(string, string) -> Guid`. The function is impure several times over; any one of those lines would be enough to earn the label.

And a function so quiet about its effects that the body reads like arithmetic:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public bool IsValid(Token token) =>
    token.ExpiresAt > DateTime.UtcNow;
```

</td>
<td>

```java
public boolean isValid(Token token) {
    return token.expiresAt().isAfter(Instant.now());
}
```

</td>
</tr>
</table>

One line, one comparison, no method that screams *I touch the world*. The function is impure all the same: `DateTime.UtcNow` / `Instant.now()` is a read of the system clock from Axiom 2's *Reading the clock* category, and two calls with the same `token` will eventually disagree. The cost of recognising this case is the whole reason the category needs a name — the loud one is easy; the quiet one is what the discipline buys you.

---

## Problem / forces

The competing force is **convenience**: most code talks to the world somewhere, and most engineers do not draw a line between "the function that totals a basket" and "the function that places the order." Both are *functions*; both pass tests; both compile. The cost of conflating them is paid immediately — domain rules and plumbing tangle in the same function, and neither is readable as itself — and again later, when one of them needs to run in parallel, replayed under test, cached, retried, or moved to a different process. The line between *trivial* and *impossible* runs straight through this label.

The axiom does not claim impure functions are bad. It claims the label is load-bearing: until you can point at a function and say "this one is impure," you cannot reason about which functions are safe to move, parallelise, cache, retry, or test in isolation. The point is to *separate*, not to *eliminate*.

---

## Why

**1. Side effects are plumbing; the rest is the domain.**
The deepest reason to label impure functions is that they do categorically different work from the rest of the program. Impure functions *gather context* — read the database, read the clock, read configuration, receive the incoming message — and *deliver outcomes* — save the record, publish the event, send the response, write the log line. Between those reads and writes sits the rules of the domain: the code that takes the gathered context, applies the rules, and decides what should happen. That middle part has nothing to do with the world; it is data-in, decision-out. Without the label, the two kinds of work are indistinguishable in source, and the default shape is to weave them together line by line. With it, the seam becomes visible — and the rest of the reasons below are consequences of being able to see it.

From that split, three concrete consequences follow.

**2. Effects are deep, not shallow.**
Impurity is a property of the whole call graph reachable from a function, not of one line. A function that calls a logger is impure for the same reason a function that writes to a database is — once the effect happens anywhere downstream, the function as a whole carries it. Naming the category at the function level gives the discipline somewhere to live: you cannot ask "is this function impure?" of a single statement, only of a function.

**3. Tests separate cleanly along this line.**
An impure function needs the world it depends on, set up the way it expects, and the cleanup of the writes it performs. Take those needs away — let the function be a closed expression over its parameters — and the test reduces to *given these inputs, expect this output*. The difficulty curve between the two is roughly an order of magnitude; the line between them is where that curve breaks.

**4. The compiler will not draw the line for you.**
Java's checked exceptions surface one effect (throwing) in the signature and miss the rest. C# has no signature-level effect tracking at all. Recognising impurity is therefore a *reading* discipline, and the only way to make it operational is to give the category a name.

---

## Trade-offs

There is no cost to *labelling* a function impure; recognition is a reading skill. The real trade-offs appear in the axioms that follow — those that prescribe where in a program the impure functions should and should not live. This axiom only asks that, given a function, you can name which category it is in.

---

## When NOT to

Two edge cases where the label looks awkward:

- **The memoised function.** A function whose body is deterministic arithmetic but whose result is cached behind the scenes looks effect-free from outside — same input, same output — yet the cache itself is mutable shared state. The honest read is "the cache is impure; the memoised function is a value-returning façade over it." Useful in production; do not pretend the cache is not there.
- **The "one tiny effect" function.** A function that computes deterministically but logs once for diagnostics is impure. There is no "mostly safe" category — the line is binary because the consequences are binary. You can or cannot cache, parallelise, or replay.

---

## References

[1] **Eric Normand**, *Grokking Simplicity*, Manning Publications, 2021. Chapters 2 and 3 introduce the categories *action*, *calculation*, and *data*: an action is a function whose outcome depends on when or how often it is called (this axiom's *impure function*); a calculation is a function whose outcome depends only on its inputs. The same line drawn with different vocabulary.
<https://www.manning.com/books/grokking-simplicity>

[2] **John Hughes**, *Why Functional Programming Matters*, Research Topics in Functional Programming, Addison-Wesley, 1990. Already cited in [Axiom 2](axiom-02-side-effects.md) as reference [3]; cross-listed here because Hughes' argument turns on functions being free of hidden inputs and hidden outputs — i.e., on the category this axiom names being separable from its opposite.
