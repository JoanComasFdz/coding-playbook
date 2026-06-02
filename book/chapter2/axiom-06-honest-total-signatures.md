# Axiom 6 — Honest, total signatures

**A signature is honest when every outcome the function can produce is named in its return type, and total when it is defined for every value of its input types.**

- Honesty rules out hidden outcomes: sentinel values, silent nulls, convention strings, throws-as-control-flow.
- Totality rules out forbidden inputs: zones where the function is "undefined" and the caller is expected to know.

[Axiom 5](axiom-05-pure-functions.md) named purity — the property that closes the back door between a function and the world. This axiom names a sister property that closes the front door: the signature must tell the whole truth about what the function does to *its own arguments*. Purity puts every input into the parameter list and every effect-free output into the return value; this axiom asks the next question — is *every* outcome actually represented by the return type, and is the function *actually defined* for every value the input types admit? A pure function can still lie, by returning a sentinel where the type system cannot help the caller see it, or by being silently undefined on inputs the type accepts but the body refuses.

Naming every outcome is also where [Axiom 0](axiom-00-ubiquitous-language.md) first gets teeth: a return type that spells out *what* happened — `NotFound`, `InsufficientFunds` — in the domain's words, where a bare `bool` or a sentinel leaves the outcome nameless.

---

## Definitions

Two properties of a function signature, both visible *without* running the program.

A signature is **honest** when:

- **Every outcome the function can produce is represented in the return type.** A function whose body says `if (notFound) return -1; else return realIndex;` is dishonest: the return type is `int`, but the return *value* is a tagged union the caller has to decode by convention. So is a function that "returns the user, or `null` if not found," or that returns an empty string to mean "no value." The smallest such case is a bare `bool`: returning `true`/`false` collapses the outcomes into a two-element tagged union whose cases have no names — *boolean blindness*[3], where the caller learns *that* something holds but never *what*, and is left with nothing valid to carry forward. Widening that `bool` into named cases is the same repair as widening the sentinel `int`, applied to the most degenerate return there is.
- **No outcome is delivered through a side channel.** Throwing to signal an expected outcome is dishonest in the same way: the type system says one thing, the runtime delivers another. (Purity already forbids this from the body of a pure function; honesty makes it explicit at the signature level.)
- **No `out` / `ref` parameters carry hidden return values.** `bool TryParse(string s, out int value)` is the canonical case: the signature pretends the function returns a `bool`, but two values come out and the caller has to wire both.

> The opposite of honest is dishonest.

A function is **total** when:

- **Every value of every parameter type produces a defined return value.** `decimal Divide(int a, int b)` is undefined for `b == 0`, `T Head<T>(List<T> xs)` is undefined for empty lists. The function is total only if the domain of every parameter is fully covered by the body.
- **Totality is a claim about the *declared types*, not about the values that happen to flow in.** A function that "only ever gets called with valid inputs" in production is still partial; the type system simply hasn't noticed yet.

> The opposite of total is partial.

The two properties are joined at the hip: most ways to make a partial function total also make it honest, by widening the return type to include the previously-undefined cases. Turn `int Divide(int, int)` into something whose return type distinguishes "the quotient" from "the divisor was zero" and you have repaired both holes at once.

This axiom rejects four mainstream defaults:

- **Sentinel values.** `IndexOf` returning `-1`; `parseInt` returning `0` on failure; "the empty string means absent." A magic value smuggles a second outcome through a type that has no room for it. The compiler cannot enforce that callers check; production finds the cases the test suite missed.
- **`null` as a silent second meaning.** A reference type `User` is "really" `User | null`, but the signature is silent about which methods return which. Every caller pays for that silence by either over-checking (defensive `?.`) or under-checking (`NullReferenceException` at 3am).
- **`out` / `ref` for "did it work."** `TryGetValue`, `int.TryParse(s, out var i)` — useful idioms before nullable references and richer return types landed, but each one is a function pretending the signature is `bool` while a second value comes out the side.
- **Implicit partiality.** A function whose body assumes some inputs "won't happen" — `denominator != 0`, list not empty, string is well-formed. The assumption is fine in someone's head; it does not exist in the type system, and the next caller has no way to know it.

---

## Example

A dishonest partial function:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public int FindOrderIndex(IReadOnlyList<Order> orders, Guid id)
{
    for (var i = 0; i < orders.Count; i++)
        if (orders[i].Id == id) return i;
    return -1; // not found — caller must know to check
}

public User GetUser(Guid id)
{
    return repository.FindById(id); // may be null; signature is silent
}
```

</td>
<td>

```java
public int findOrderIndex(List<Order> orders, UUID id) {
    for (var i = 0; i < orders.size(); i++)
        if (orders.get(i).id().equals(id)) return i;
    return -1; // not found — caller must know to check
}

public User getUser(UUID id) {
    return repository.findById(id); // may be null; signature is silent
}
```

</td>
</tr>
</table>

Both functions are pure under [Axiom 5](axiom-05-pure-functions.md): no clock, no I/O, no captures. Both still lie. `FindOrderIndex` advertises `int` and delivers "an index *or* a sentinel"; `GetUser` advertises `User` and delivers "a user *or* nothing." The caller cannot tell from the signature that two outcomes exist, and the compiler cannot tell either. Every caller is responsible for remembering — and the bug is the call that forgets.

A signature that names every outcome and accepts every input:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public abstract record FindResult;
public sealed record Found(int Index) : FindResult;
public sealed record NotFound : FindResult;

public FindResult FindOrderIndex(IReadOnlyList<Order> orders, Guid id)
{
    for (var i = 0; i < orders.Count; i++)
        if (orders[i].Id == id) return new Found(i);
    return new NotFound();
}
```

</td>
<td>

```java
public sealed interface FindResult permits Found, NotFound {}
public record Found(int index) implements FindResult {}
public record NotFound() implements FindResult {}

public FindResult findOrderIndex(List<Order> orders, UUID id) {
    for (var i = 0; i < orders.size(); i++)
        if (orders.get(i).id().equals(id)) return new Found(i);
    return new NotFound();
}
```

</td>
</tr>
</table>

The return type now lists every outcome the function can produce. The caller cannot extract an `int` without first taking a branch that says which case they are in; the compiler tracks the obligation. The function went from partial-and-dishonest (returns `int`, but only when found) to total-and-honest (returns *something* for every input, and the *something* tells the caller what kind of thing it is).

That was one path to honesty and totality: widen the *output* until every outcome the function can produce has a name. The other path is to narrow the *input* until every value the type admits is one the body is ready to handle.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// Using a type whose values are guaranteed non-zero by construction.
public decimal Divide(int numerator, NonZeroInt denominator)
{
    return (decimal)numerator / denominator.Value;
}
```

</td>
<td>

```java
// Using a type whose values are guaranteed non-zero.
public BigDecimal divide(int numerator, NonZeroInt denominator) {
    return BigDecimal.valueOf(numerator)
        .divide(BigDecimal.valueOf(denominator.value()));
}
```

</td>
</tr>
</table>

`Divide` now has no partial case of its own to report. The input type admits no zero, so the body has no value to refuse. The partial fact has been pushed upstream — to whoever constructs a `NonZeroInt` — and `Divide` is total without widening its output. Widen the output or narrow the input; both paths land on the same property, and most real fixes use a mix of the two.

There is a third route, blunter than either: **define the failing case out of existence** — redesign the operation so the input that used to be illegal now has a defined, sensible answer. A `Substring` that *clamps* an out-of-range length to what the string actually has, a delete that simply *succeeds* when the row is already gone (idempotent), a lookup that returns an empty list rather than refusing an empty query — each is total not because its output was widened or its input narrowed, but because the operation was *redefined* until no input is an error[4]. It is the most aggressive form of the axiom: the cheapest outcome to handle is the one that no longer exists. Its hazard mirrors its power, and *When NOT to* draws the line.

---

## Problem / forces

The competing force is **brevity in the small**. `return -1` is one character cheaper than wrapping the result in a tagged type; `return null` is even cheaper. In a method called from three places, all written by the same person in the same week, the dishonest signature works fine — the author and the callers remember the convention because they wrote it.

The cost lands later, in two places. First, **the next caller** — three months on, in a different file, copy-pasting the call from somewhere else — has no way to learn the convention from the type. The IDE shows `int`; the IDE does not show *"watch out, `-1` means not found."* Comments help once; they decay. Second, **refactoring**: when the function later needs to express a new outcome — a third case the body can produce — an honest signature forces every caller to handle it because the return type changed; a dishonest signature has nowhere to put the new outcome except by inventing another sentinel or silently folding it into the existing one. The bug ships.

There is also a force in the *other* direction worth naming: not every imaginable outcome belongs in the return type. A function that can "fail" because the universe is on fire (out of memory, network cable unplugged) is not obliged to put that in its return — those are the boundary effects [Axiom 4](axiom-04-impure-functions.md) concentrates in the impure shell. Honesty asks for the outcomes the function *can produce as part of its own logic*; it does not ask for the catalogue of external catastrophes.

---

## Why

**1. The signature is the only contract the next caller will read.**
Documentation rots; tests prove existence, not absence; comments are advisory. The signature is the one artefact every caller is forced to look at, and the compiler keeps it in sync with the body. Making the signature carry the function's actual behaviour — every outcome, every accepted input — is what turns "API documentation" from a chore into a side effect of writing the function. Every gap between signature and body is a gap the next caller has to learn somewhere other than the signature.

**2. Honest outcomes turn runtime bugs into compile errors.**
A function whose return type names every outcome forces the caller to handle every branch the function can produce, with the compiler tracking the obligation. Add a new case to the return type and the compiler points at every site that needs updating. A function that returns `int`-with-a-sentinel can absorb a second sentinel value without the type changing, and every site that was content with the old convention silently breaks on the new one. The honesty discipline is the cheapest static analysis the codebase will ever have, paid by the act of writing the signature once.

**3. Totality eliminates a whole category of "didn't expect that" bugs.**
The class of production crashes that look like *"the input was supposed to be valid"* is exactly the class totality forbids. If the function is defined for every value the input type admits, there is no input the body has not thought about. The way to *reach* totality, when the parameter types are too permissive, is to narrow the type — push validation upstream into the construction of the value, not into the body of every function that uses it. That work does not disappear; it relocates to a place where it is done *once*, where the rules around it are obvious from the type name, and where the rest of the code is freed from rechecking.

**4. Composition needs honesty.**
A pure function whose signature lies cannot compose: chaining two functions, each of which "might return `-1`," produces code that branches more times than it does work. Honest return types compose mechanically — once outcomes are in the type, the small operations that build chains of fallible computations have a shape to operate over. A fluent API like `step1().step2().step3()` is the simplest case: it reads cleanly only when each return value is something the next call can use directly; the moment any link returns "the answer *or* `null`," the chain has to break to decode the convention. The "structure, types, and proof" that [Axiom 5](axiom-05-pure-functions.md) promised live in the pure core depend on signatures that do not lie; this axiom is the precondition.

---

## Trade-offs

The real cost is **shape**. An honest, total signature is wider than its dishonest cousin: where `int FindIndex(...)` returned a primitive, the honest version returns a small named type, and the caller writes a branch instead of an `if (i == -1)`. In one call site, this looks like ceremony. Across a codebase, the ceremony goes the other way — every dishonest signature taxes every caller forever; the honest one taxes the author once.

A second cost is **the upstream push for totality**. Making a function total often means strengthening the input types — using a `NonZeroInt` instead of a raw `int` where division demands it, or a type whose values are guaranteed well-formed instead of a raw `string` where format matters. The work is real, and lands on whoever constructs those values. The trade is that the work happens *once*, at the boundary; partial functions distribute the same work across every caller and every test.

---

## When NOT to

Two cases where the criterion is wrong or harmful:

- **At the boundary, where the function is allowed to talk to the world.** An impure function from [Axiom 4](axiom-04-impure-functions.md) can fail because the database is gone, the network blinked, or the disk is full. Those outcomes are not part of the function's *own* logic; they belong to the shell and its retry / timeout / circuit-breaker discipline, not to the signature of a domain function. Honesty applies to outcomes the function *decides on*, not to the catalogue of plumbing failures.
- **When the proposed extra outcome is really input validation.** Honesty asks for outcomes the function *decides on*. "The input was malformed" is not such an outcome — it belongs to the type of the parameter, not to the return type of every function that takes one. Folding input validation into the return type re-creates the check at every call site instead of solving it once where the input is constructed.
- **When defining the error out of existence would mask a bug.** Totalizing by *absorbing* a bad input — clamping it, swallowing it, returning a default — is right only when the broadened behaviour is one the caller genuinely wants. When the bad input can arise only from a caller's mistake (a negative count, an index that *should* have been in range), silently absorbing it hides the defect at the exact spot it could have surfaced. There the honest move is the opposite: refuse loudly and let the bug fail fast, rather than define it out of existence and let it travel downstream as a plausible-looking value.

---

## References

[1] **Alexis King**, *Parse, Don't Validate*, lexi-lambda.github.io, 2019. The original essay arguing that the difference between a validating function (returns `bool`) and a parsing function (returns the validated type) is the difference between dishonest+partial and honest+total signatures.
<https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/>

[2] **Scott Wlaschin**, *Designing with Types: Making Illegal States Unrepresentable*, fsharpforfunandprofit.com, 2013. A practical demonstration of using rich return and parameter types to remove whole categories of bugs by construction — the application of this axiom across a domain model.
<https://fsharpforfunandprofit.com/posts/designing-with-types-making-illegal-states-unrepresentable/>

[3] **Robert Harper**, *Boolean Blindness*, Existential Type, 2011 (crediting Dan Licata for the term); **John A. De Goes**, *Destroy All Ifs*, degoes.net, 2015. Both name what a bare `bool` discards — that a value is one of two cases, with the cases left anonymous — and both prescribe the cure this playbook reaches for throughout: replace the boolean with a named type — a value object on the return, or a discriminated union for the cases.
<https://existentialtype.wordpress.com/2011/03/15/boolean-blindness/>
<http://degoes.net/articles/destroy-all-ifs>

[4] **John Ousterhout**, *A Philosophy of Software Design*, Yaknyam Press, 2018, ch. 10 ("Define Errors Out of Existence"). The argument that the cheapest exception to handle is the one designed away — redefine an operation's semantics so the formerly-erroneous case becomes a normal, defined outcome (`substring` clamps, deletion is idempotent). The counterweight in *When NOT to* — that absorbing a bug-signalling input masks the defect — is the boundary this playbook draws around the technique.

---

← Previous: [Axiom 5 — Pure functions](axiom-05-pure-functions.md) · Next: [Axiom 7 — Cohesion](axiom-07-cohesion.md) →
