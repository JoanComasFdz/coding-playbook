# Axiom 1 — Explicit over implicit

**Everything a reader needs to know about what a piece of code needs and does should be visible where it is used: its inputs, its dependencies, what it changes, and how it can fail. Hide a decision that is likely to change; never hide the intent.**

- Read a call site and its signature, and you should know what the call depends on and what it can do. Nothing important arrives through a back door: a global, a static, the clock, a locator.
- Hiding is still allowed, for one thing: a *decision likely to change*, kept behind a boundary so its callers don't have to change with it.

This axiom builds nothing on its own, like [Axiom 0](axiom-00-ubiquitous-language.md). Axiom 0 gives each concept one name. This one makes sure that what the code does with those concepts can be seen. Most of the axioms that follow make one more thing explicit. The [search oracle](../chapter1/README.md#the-goal-a-codebase-that-is-a-search-oracle) of Chapter 1 depends on it: a compiler can only check what the code states.

---

## Definitions

> Code is **explicit** when what it needs and what it does are visible at the point of use. It is **implicit** when you can only learn them by reading somewhere else, or by knowing a convention.

Five things are commonly left implicit:

- **Inputs.** A value read from the clock, a static, a global configuration, an ambient context.
- **Dependencies.** A collaborator fetched from a service locator instead of passed in. A class is *dishonest* with its callers when it "will only function properly if certain global or infrastructure components are in place" [7].
- **Effects.** What a call changes in the world: a row written, a message sent, a field mutated.
- **Outcomes.** How a call can fail, when the signature only shows the success.
- **Concepts.** A rule buried in an `if`, with no name a reader could look up. Evans calls this *making implicit concepts explicit*: giving the rule a name and a home [3].

### Encapsulation, read precisely

Explicitness seems to clash with encapsulation, because encapsulation is often taught as "make everything private". But the word bundles three jobs, and only one of them clashes:

| What gets hidden | Verdict |
|---|---|
| **Invariants.** Callers must not be able to build an invalid value. | **Keep.** Seemann: "Encapsulation is not about hiding complexity, but conversely exposing complexity in a fail-safe manner" [4]. The invariant can be enforced where the value is built, not by hiding its fields. |
| **Secrets.** A design decision likely to change: which database, which protocol, which cache [2]. | **Keep,** at a module boundary. A caller shouldn't depend on a decision that will change. |
| **State, effects and dependencies hidden behind a method.** | **Drop.** This is what makes intent invisible. A method that reads three hidden things and changes a fourth looks the same from outside as one that does nothing of the kind. |

In one line: **be explicit about intent, hide only secrets.** Data that can't be changed after it is built can be shown to anyone: there is nothing a reader could break by looking. What remains worth hiding is a decision, not data.

---

## Example

A discount calculation, written implicitly and explicitly:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// ❌ implicit: the signature says "an order in,
//    a number out"
public class DiscountCalculator
{
    public decimal CalculateDiscount(Order order)
    {
        var today = DateTime.Today;               // the clock
        var rules = AppConfig.Current.Discounts;  // a global
        var customer = ServiceLocator
            .Get<ICustomerRepository>()           // a hidden
            .FindById(order.CustomerId)           // database
            ?? throw new InvalidOperationException(
                "unknown customer");              // a hidden
                                                  // failure
        var isLoyal = customer.Since
            <= today.AddYears(-rules.LoyaltyYears);
        return isLoyal ? order.Total * rules.LoyaltyRate : 0m;
    }
}
```

</td>
<td>

```java
// ❌ implicit: the signature says "an order in,
//    a number out"
public final class DiscountCalculator {
    public BigDecimal calculateDiscount(Order order) {
        var today = LocalDate.now();              // the clock
        var rules = AppConfig.current().discounts(); // a global
        var customer = ServiceLocator
            .get(CustomerRepository.class)        // a hidden
            .findById(order.customerId())         // database
            .orElseThrow();                       // a hidden
                                                  // failure
        var isLoyal = !customer.since()
            .isAfter(today.minusYears(rules.loyaltyYears()));
        return isLoyal
            ? order.total().multiply(rules.loyaltyRate())
            : BigDecimal.ZERO;
    }
}
```

</td>
</tr>
</table>

The signature promises "give me an order, get a number". The truth is that the call needs the clock, a global configuration and a database, and it can throw. None of that is visible to the caller, a reviewer, a test, or the compiler.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// ✅ explicit: the signature tells the whole story
public static decimal CalculateDiscount(
    Order order, Customer customer,
    DiscountRules rules, DateOnly today)
{
    var isLoyal = customer.Since
        <= today.AddYears(-rules.LoyaltyYears);
    return isLoyal ? order.Total * rules.LoyaltyRate : 0m;
}
```

</td>
<td>

```java
// ✅ explicit: the signature tells the whole story
public static BigDecimal calculateDiscount(
        Order order, Customer customer,
        DiscountRules rules, LocalDate today) {
    var isLoyal = !customer.since()
        .isAfter(today.minusYears(rules.loyaltyYears()));
    return isLoyal
        ? order.total().multiply(rules.loyaltyRate())
        : BigDecimal.ZERO;
}
```

</td>
</tr>
</table>

The rule is the same two lines. What changed is where the reading happens: the caller now fetches the customer, the rules and the date, and decides what to do when the customer is missing. The function can be read, tested and checked from its signature alone. Later axioms go further, making the failure itself and the effects part of what a signature shows.

---

## Problem / forces

Implicit code is usually the default, for understandable reasons:

- **Shorter call sites.** `CalculateDiscount(order)` is less to type than four arguments, and the hidden reads seem free when you write them.
- **Frameworks that reach for you.** Service locators, ambient contexts, static configuration and attribute-driven behavior make it easy to get what you need without asking for it.
- **Encapsulation taught as hiding.** "The caller doesn't need to know" is often right for a secret, and wrong for an input or an effect. The two get mixed up.
- **Local convenience, global cost.** Each hidden read saves its author a minute. Every later reader, test and change pays for it.

---

## Why

**1. The intent is readable where you stand.**
A reader shouldn't have to open five files to learn what one call does. Gross calls this *locality of behavior*: the behavior of a unit should be as obvious as possible from that unit alone [6]. Ousterhout traces most complexity to two causes, dependencies and obscurity [5]. Implicit code produces both: dependencies nobody can see.

**2. Only what is explicit can be checked.**
A compiler checks signatures, not conventions. A dependency passed as a parameter breaks the build when it is missing; one fetched from a locator breaks at runtime. This is what makes a codebase a [search oracle](../chapter1/README.md#the-goal-a-codebase-that-is-a-search-oracle): every explicit fact is one more thing the compiler can reject before anything runs.

**3. Tests need no setup.**
To test the explicit `CalculateDiscount`, pass four values and compare the result. To test the implicit one, freeze the clock, replace the global configuration and register a fake repository in the locator, and remember to undo all three.

**4. A change shows up where it lands.**
When the explicit function starts to need something new, its signature changes, and every caller is told by the compiler. When the implicit one starts to read a new global, nothing tells anyone.

**5. Machines read it better too.**
Practitioners working with coding agents report the same pattern: agents do well on code whose dependencies are explicit and local, and badly on indirection and hidden magic [8]. That is opinion and experience, not a measured result, but it points the same way as everything above.

---

## Trade-offs

- **Longer signatures.** Four parameters instead of one. When a group of values always travels together, give it a name and a type of its own, which makes it a concept rather than a list.
- **Values have to be passed through.** Something has to read the clock and the configuration and hand them over. That work moves to the edge of the program, to the code that wires it together, where it is done once.
- **Explicit is not the same as clear.** Badly organized code stays hard to read even when every input is visible. Explicitness removes surprises; it doesn't create structure.
- **Explicit code still doesn't say *why*.** It shows what the code needs and does, not the reasoning behind a decision. That belongs in a decision record, not in the signature.

---

## When NOT to

- **A real secret.** Which database, which protocol, which caching strategy: these are decisions likely to change, and callers should not depend on them [2]. Hide them behind a small interface. That is the deep module Ousterhout argues for [5], and the subject of a Chapter 3 Play ([Chapter 3](../chapter3/README.md)). Hiding *how* is fine; hiding *what the call needs and does* is not.
- **Plumbing nobody decides per call.** A logging scope or a correlation ID that every call carries the same way can live in infrastructure. If a function's behavior depends on it, it is an input, not plumbing.
- **When the explicit form only adds noise.** Inside a small private function whose context the reader already has in view, passing everything again can repeat what is on screen. The rule is about what a reader can't see, not about spelling out what they can.

---

## References

[1] **Tim Peters**, *The Zen of Python*, PEP 20, 2004. "Explicit is better than implicit." The best-known statement of the slogan.
<https://peps.python.org/pep-0020/>

[2] **David L. Parnas**, *On the Criteria To Be Used in Decomposing Systems into Modules*, Communications of the ACM 15(12), 1972. A module hides a design decision that is likely to change. The source of *information hiding*: hiding a secret, not hiding data.

[3] **Eric Evans**, *Domain-Driven Design: Tackling Complexity in the Heart of Software*, Addison-Wesley, 2003, ch. 9, "Making Implicit Concepts Explicit". Also cited in [Axiom 0](axiom-00-ubiquitous-language.md).

[4] **Mark Seemann**, *Poka-yoke Design: From Smell to Fragrance*, ploeh.dk, 2011, and *Code That Fits in Your Head*, Addison-Wesley, 2021. Encapsulation as protecting invariants through a contract: "Encapsulation is not about hiding complexity, but conversely exposing complexity in a fail-safe manner."
<https://blog.ploeh.dk/2011/05/24/Poka-yokeDesignFromSmelltoFragrance/>

[5] **John Ousterhout**, *A Philosophy of Software Design*, Yaknyam Press, 2018. Complexity comes from dependencies and obscurity; the chapters "Information Hiding (and Leakage)" and "Code Should be Obvious" hold both halves of this axiom: hide secrets, and make everything else obvious.

[6] **Carson Gross**, *Locality of Behaviour (LoB)*, htmx.org, 2020.
<https://htmx.org/essays/locality-of-behaviour/>

[7] **Microsoft**, *Architectural principles*, in *Architect Modern Web Applications with ASP.NET Core and Azure*, "Explicit dependencies": "Methods and classes should explicitly require any collaborating objects they need in order to function correctly."
<https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/architectural-principles>

[8] Practitioner essays on coding agents, 2025–2026, for example *AI Agents Reward Boring Code. Stop Being Clever.* (HackerNoon) and *Designing Architectures That Play Nice with AI Coding Agents*. Opinion pieces, not studies.
<https://hackernoon.com/ai-agents-reward-boring-code-stop-being-clever>
<https://architecttocto.substack.com/p/designing-architectures-that-play>

---

← Previous: [Axiom 0 — Ubiquitous Language](axiom-00-ubiquitous-language.md) · Next: [Axiom 2 — Data is not Behavior](axiom-02-data-is-not-behavior.md) →
