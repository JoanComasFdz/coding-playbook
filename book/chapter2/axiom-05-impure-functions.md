# Axiom 5 — Impure functions

**A function is impure when its execution performs, or depends on, any side effect.**

- One hidden read or write is enough. The label is binary: there is no "a bit impure".
- When the side effect is a *read* of outside state, the function is also *non-deterministic*: same inputs in, different outputs out.

[Axiom 4](axiom-04-side-effects.md) named the side effects; this axiom names the functions that contain them. The split matters because side effects are how an application:

- **gathers context** from the world: a database row, a clock tick, a configuration value, an incoming message;
- **delivers the outcomes it decides on**: a saved record, a published event, a log line.

They are the program's plumbing. Everything else is business logic: the rules that turn the gathered context into a decision. Once you can label a function impure, you can keep the two kinds of work apart.

---

## Definitions

In one sentence: **a function is impure if any side effect from [Axiom 4](axiom-04-side-effects.md) is reachable from its body.** "Reachable" means anywhere:

- **directly in the body:** a line matches a category from [Axiom 4](axiom-04-side-effects.md#the-categories), such as a clock read, a logger call, a `throw`, a parameter change, a database call or a singleton lookup;
- **in a function it calls, however deep:** impurity spreads upward. A function that does arithmetic plus a single `logger.info` is impure, and so is its caller, and so is the caller's caller;
- **in a constructor it runs;**
- **in a field or reference it captures:** capturing a `DbContext`, an `HttpClient` or a `Random` taints the function as much as creating one inline;
- **behind an injected interface** whose implementation, at runtime, performs one.

When that effect is a *read* (the clock, a random source, a mutable singleton, the file system), the function is also *non-deterministic*: two calls with the same arguments can give different results. The hidden read is the *cause*; the non-determinism is the *symptom* that tests, parallel runs and replays notice.

Normand draws the same line with different words: an impure function is an *action*, whose outcome depends on when or how often it runs [1].

This axiom departs from a common default: treating every function as the same kind of thing. In C# and Java, the type system doesn't separate them. `int Add(int, int)` and `Order PlaceOrder(string, List<string>)` are declared the same way and called the same way. Without a label that lives outside the type system, questions like "can I cache this? run it in parallel? test it without setup?" have no quick answer.

---

## Example

A function where almost every line touches the world:

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

Six effects in seven lines, and none of them is named in the signature `(string, string) -> Guid`. The function is impure several times over; any one of those lines would be enough.

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

One line, one comparison, nothing that announces *I touch the world*. The function is impure all the same: `DateTime.UtcNow` / `Instant.now()` reads the system clock ([Axiom 4](axiom-04-side-effects.md#time-randomness-and-environment)'s *Reading the clock*), so two calls with the same `token` will eventually disagree. Spotting this case is the reason the category needs a name. The loud function is easy to recognize; the quiet one is what the skill is for.

---

## Problem / forces

Most code talks to the world somewhere, and most engineers don't draw a line between "the function that totals a basket" and "the function that places the order". Both are *functions*, both pass tests, both compile. Mixing them costs you twice:

- **Right away:** domain rules and plumbing tangle in the same function, and neither can be read on its own.
- **Later:** when one of them needs to run in parallel, be replayed in a test, be cached, be retried or move to another process.

One force pulls the other way: **convenience**. Writing the rule and the I/O in one place is the fastest thing to type.

This axiom doesn't claim impure functions are bad. It claims the label matters: until you can point at a function and say "this one is impure", you can't tell which functions are safe to do those things with. The point is to *separate* them, not to *eliminate* them.

---

## Why

**1. Side effects are plumbing; the rest is the domain.**
Impure functions do a different kind of work from the rest of the program: as the introduction says, they gather context and deliver outcomes. Between those reads and writes sit the rules of the domain: the code that takes the gathered context, applies the rules and decides what should happen. That middle part has nothing to do with the world: data in, decision out.

Without the label, the two kinds of work look the same in the source, and the default is to weave them together line by line. With the label, the seam becomes visible. Hughes' classic case for functional programming rests on the same separation: functions with no hidden inputs or outputs are the ones you can compose [2].

**2. The label belongs to functions, not lines.**
As *Definitions* shows, impurity spreads to everything that calls an impure function, however deep the effect sits. So you can't ask "is this impure?" of a single statement, only of a function, and that is where the label belongs.

**3. Tests split cleanly along this line.**
An impure function needs the world it depends on, set up the way it expects, plus cleanup of the writes it makes. Take those needs away, so the function depends only on its parameters, and the test becomes *given these inputs, expect this output*. The difference in effort between the two kinds of test is large, and this label is exactly where it appears.

**4. The compiler won't draw the line for you.**
Java's checked exceptions put one effect (throwing) in the signature and miss the rest. C# has no way to track effects in a signature at all. So recognizing impurity is a *reading* skill, applied to the whole body (and everything it reaches), not to the signature. You can only practice it once the category has a name.

---

## Trade-offs

*Labeling* a function impure costs nothing: recognizing it is a reading skill. The real trade-offs come in the axioms that follow, the ones that say where in a program impure functions should and shouldn't live. This axiom only asks that, given a function, you can say which kind it is.

---

## When NOT to

There is no case where you shouldn't label a function. But two cases make the label look awkward:

- **The memoized function.** A function whose body is deterministic arithmetic, with its result [memoized](https://en.wikipedia.org/wiki/Memoization) behind the scenes, looks effect-free from outside: same input, same output. But the cache is mutable shared state. As in [Axiom 4](axiom-04-side-effects.md): the cache is impure, and the memoized function is a value-returning front for it. Useful in production; just don't pretend the cache isn't there.
- **The "one tiny effect" function.** A function that computes deterministically but logs once for diagnostics is impure. There is no "mostly safe" category. The line is binary because the consequences are binary: you can either cache, parallelize and replay it, or you can't.

---

## References

[1] **Eric Normand**, *Grokking Simplicity*, Manning Publications, 2021. Chapters 2 and 3 introduce the categories *action*, *calculation* and *data*. An action is a function whose outcome depends on when or how often it is called (this axiom's *impure function*); a calculation is a function whose outcome depends only on its inputs. The same line, drawn with different words. <https://www.manning.com/books/grokking-simplicity>

[2] **John Hughes**, *Why Functional Programming Matters*, in *Research Topics in Functional Programming*, Addison-Wesley, 1990. Already cited in [Axiom 4](axiom-04-side-effects.md) as reference [3]. Listed again here because Hughes' argument relies on functions having no hidden inputs or outputs, that is, on being able to separate the kind of function this axiom names from its opposite.

---

← Previous: [Axiom 4 — Side effects](axiom-04-side-effects.md) · Next: [Axiom 6 — Pure functions](axiom-06-pure-functions.md) →
