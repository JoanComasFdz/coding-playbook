# Information Hiding

[Axiom 1](../chapter2/axiom-01-explicit-over-implicit.md) says to make everything a reader needs visible, and to hide only one thing: a decision likely to change. This Play is about that one thing. Which decisions deserve hiding, where the boundary goes, and what stays explicit on both sides of it.

Like every Play, it adds no new principle. It is the "secrets" job of encapsulation from [Axiom 1](../chapter2/axiom-01-explicit-over-implicit.md#encapsulation-read-precisely), applied at the size of a module, and read through [Cohesion](../chapter2/axiom-08-cohesion.md) and [Connascence](../chapter2/axiom-09-connascence.md).

## Problem / forces

- **A decision leaks into its callers.** The format of an external feed, the vendor of a payment provider, the shape of a cache: when callers know any of these, changing the decision means changing every caller.
- **Explicitness pulls the other way.** [Axiom 1](../chapter2/axiom-01-explicit-over-implicit.md) wants inputs, effects and failures in the signature. Without a rule for what to hide, "be explicit" can turn into exposing every detail of how a module works.
- **Hiding is often done by reflex.** An interface per class, private fields everywhere, a wrapper around every library. That hides nothing that was likely to change, and adds ceremony.

## What I do today

- **Name the secret.** Every module in the shell states its secret in one sentence: "rates come from the ECB daily XML feed, cached per day". If I can't name a decision that is likely to change, the module has no secret, and it needs no boundary.
- **Keep the core fully explicit.** Pure decisions over immutable data ([Axiom 6](../chapter2/axiom-06-pure-functions.md), [Axiom 3](../chapter2/axiom-03-immutability.md)) hide nothing, because there is nothing a caller could break ([Axiom 2](../chapter2/axiom-02-data-is-not-behavior.md)). The secret lives in the impure shell, never in the core ([Axiom 13](../chapter2/axiom-13-impureim.md)).
- **Give the secret a small surface, in domain words.** The module exposes a few functions that take and return domain values ([Axiom 19](../chapter2/axiom-19-value-objects.md)) and `Result`s ([Axiom 17](../chapter2/axiom-17-result.md)). No feed types, no SDK types, no cache handles cross the boundary. Mapping from the outside representation to domain values happens inside.
- **Hide *how*, never *what*.** The caller doesn't learn where a rate came from, but it does learn everything that affects its own decision: the rate, its date, and that fetching it can fail. Those stay explicit.
- **No interface unless there is a second implementation.** A small public surface on a concrete class hides the secret just as well. An `IExchangeRates` next to its only `ExchangeRates` is the ceremony [Chapter 1](../chapter1/README.md#enforce-decisions-not-ceremony) warns about.
- **The test:** *if this decision changed, which files would change?* If the answer is "only this module", the secret is hidden. If callers change too, it leaked.

## Why

- **Parnas's criterion.** Decompose by the decisions likely to change, not by the steps of the processing. His 1972 comparison of two designs for the same program showed that the second kind survives changes the first kind spreads everywhere [1].
- **Leakage is the failure mode.** Ousterhout calls it *information leakage*: the same design decision reflected in several modules, so a change to it touches all of them [2].
- **Connascence, kept local.** Code that knows a secret is bound to it ([Axiom 9](../chapter2/axiom-09-connascence.md)). Hiding the secret doesn't remove that binding; it keeps it inside one module, where its degree is one and its locality is high.
- **Cohesion.** A module built around one secret has one reason to change: that decision ([Axiom 8](../chapter2/axiom-08-cohesion.md)).
- **Nothing important hides with it.** Because the core stays explicit and the surface speaks in domain values, hiding the secret costs the reader nothing they needed. This is the line [Axiom 1](../chapter2/axiom-01-explicit-over-implicit.md#encapsulation-read-precisely) draws: hide the secret, never the intent.

## C#/Java example

A price shown in the customer's currency needs today's exchange rate. The rates come from an external feed.

**Leaked:** the pure conversion knows the feed's format. Switch providers, and the core changes.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// ❌ the core knows the ECB feed's XML
public static Price ConvertPrice(
    Price price, XDocument ecbFeed)
{
    var rate = ecbFeed.Descendants("Cube")
        .Single(c => (string?)c.Attribute("currency")
            == price.Currency.Code);
    …
}
```

</td>
<td>

```java
// ❌ the core knows the ECB feed's XML
public static Price convertPrice(
        Price price, Document ecbFeed) {
    var cubes = ecbFeed.getElementsByTagName("Cube");
    …
}
```

</td>
</tr>
</table>

**Hidden:** one module holds the secret and speaks domain values. The core takes an `ExchangeRate`.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// The secret: rates come from the ECB
// daily XML feed, cached per day.
// Nothing outside this class knows that.
public sealed class ExchangeRates(HttpClient http)
{
    private readonly Dictionary<DateOnly, XDocument>
        feedsByDay = new();

    public Result<ExchangeRate, string> FindRate(
        Currency from, Currency to, DateOnly day)
    {
        … // fetch or reuse the day's feed,
          // read the rate, map it to ExchangeRate
    }
}

// What stays explicit: the rate and its date.
public sealed record ExchangeRate(
    Currency From, Currency To,
    decimal Factor, DateOnly AsOf);

// The core: pure, and ignorant of the source.
public static Price ConvertPrice(
    Price price, ExchangeRate rate) =>
    new(price.Amount * rate.Factor, rate.To);
```

</td>
<td>

```java
// The secret: rates come from the ECB
// daily XML feed, cached per day.
// Nothing outside this class knows that.
public final class ExchangeRates {
    private final HttpClient http;
    private final Map<LocalDate, Document> feedsByDay =
        new HashMap<>();

    public ExchangeRates(HttpClient http) {
        this.http = http;
    }

    public Result<ExchangeRate, String> findRate(
            Currency from, Currency to, LocalDate day) {
        … // fetch or reuse the day's feed,
          // read the rate, map it to ExchangeRate
    }
}

// What stays explicit: the rate and its date.
public record ExchangeRate(
    Currency from, Currency to,
    BigDecimal factor, LocalDate asOf) {}

// The core: pure, and ignorant of the source.
public static Price convertPrice(
        Price price, ExchangeRate rate) {
    return new Price(
        price.amount().multiply(rate.factor()),
        rate.to());
}
```

</td>
</tr>
</table>

The shell gathers the rate and passes it in ([Axiom 13](../chapter2/axiom-13-impureim.md)). Switching to another provider, or changing how long rates are cached, now changes one class. The cache is the stateful resource the shell owns ([Axiom 27](../chapter2/axiom-27-stateful-shell.md)); the core never sees it.

## Trade-offs & when NOT to

- **A boundary costs a mapping.** Every secret needs code that translates the outside representation into domain values. Worth it for a decision likely to change, not for one that won't.
- **Don't hide what isn't a secret.** Wrapping a stable library "in case we switch" hides nothing likely to change, and makes a shallow module: an interface as big as what it hides. Ousterhout's measure is functionality divided by interface cost [2]; a wrapper that only renames scores badly.
- **Some details can't stay hidden.** Every abstraction leaks a little [3]. When a hidden detail affects the caller's decision (a rate can be a day old), don't hide it: put it in the returned value, as `AsOf` does above.
- **The database is not a secret.** A layer that wraps the database so it can be swapped later promises a portability it rarely delivers. SQL Server, Oracle and PostgreSQL differ in dialect, locking, transactions and features; moving to a document store changes the data model itself. Khorikov calls database abstraction "the false myth" [4], and Zawodny named the same portability fallacy in 2004 [5]. And even where the swap would work, the layer is not free. Its interfaces, mappings and extra jumps are paid for on every feature, by every reader, from the first day. Fowler calls this the *cost of carry* of something built before it is needed: "this complexity makes it harder to modify and debug that software" [6]. So the question is not "could the database be swapped?" It is: would I rather pay every day for a swap that may never come, or keep thinner, more explicit code for the database I actually use? What this book keeps is the separation, not the disguise: persistence code lives in the shell, apart from the pure core ([Axiom 13](../chapter2/axiom-13-impureim.md)), and it uses the database it has, features included. If the database ever changes, that is a port, not a swap. ([Chapter 3](../chapter3/README.md), on testing, reaches the same conclusion from the testing side.)

## What might change tomorrow

- A product that must genuinely run on several databases, because each customer picks their own, makes the database a real secret. If that ever becomes the common case, this Play applies to it.
- Language support for small surfaces. C#'s `file`-scoped types and `internal`, and Java's module system and package-private access, already let a module hide more without an interface. If they get easier to use, the "concrete class, small surface" advice gets cheaper still.
- The pairing with the *Deep modules* Play, once that is written: a deep module is the shape a well-hidden secret usually takes.

## References

[1] **D.L. Parnas**, *On the Criteria To Be Used in Decomposing Systems into Modules*, Communications of the ACM 15(12), 1972. Two modularizations of the same program; the one built around decisions likely to change is the one that survives change.

[2] **John Ousterhout**, *A Philosophy of Software Design*, Yaknyam Press, 2018. The chapters on information hiding and leakage, and on deep modules.

[3] **Joel Spolsky**, *The Law of Leaky Abstractions*, 2002. "All non-trivial abstractions, to some degree, are leaky."
<https://www.joelonsoftware.com/2002/11/11/the-law-of-leaky-abstractions/>

[4] **Vladimir Khorikov**, *Should you abstract the database?*, Enterprise Craftsmanship, 2021. Abstracting the database to be able to switch is "the false myth": its costs are hidden, and it limits you to the features every database shares. Separating persistence from domain logic, on the other hand, is a must-have.
<https://enterprisecraftsmanship.com/posts/should-you-abstract-database/>

[5] **Jeremy Zawodny**, *Database Abstraction Layers Must Die!*, 2004. The portability fallacy: "If you use a good abstraction layer, it'll be easy to move from $this_database to $other_database down the road."
<http://jeremy.zawodny.com/blog/archives/002194.html>

[6] **Martin Fowler**, *Yagni*, martinfowler.com, 2015. The costs of building for a presumed future need: build, delay, carry and repair. Yagni "does not apply to effort to make the software easier to modify"; a layer that eases one predicted change and taxes every other one is not that.
<https://martinfowler.com/bliki/Yagni.html>
