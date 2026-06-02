# Axiom 13 — Maybe

**A function whose result might be absent must say so in its return type.**

- Wrap absence in a value — `Optional<T>` in Java, `T?` in C# with nullable reference types — so the caller has to handle it.
- Never use `null`, a tombstone, or an exception to mean "no value."

[Axiom 1](axiom-01-data-vs-behaviour.md) says data is a value; [Axiom 2](axiom-02-immutability.md) says values do not change. This axiom adds a third honest thing data does: when there is no value, the type still says so.

Through [Axiom 8](axiom-08-connascence.md)'s lens, this axiom weakens a [Connascence of Meaning](axiom-08-connascence.md#connascence-of-meaning-com) — every caller agreeing by convention that `null` means *absent* — into a Connascence of Type.


> **A note on the C# examples below.** This axiom uses C# nullable reference types (`T?`) because they are the language's built-in answer. Their enforcement is *compile-time-only and advisory* — the build passes on a warning — which makes them a structurally weaker implementation of this axiom than Java's `Optional<T>`. See [Maybe in C# beyond `T?`](#maybe-in-c-beyond-t) for the .NET ecosystem's structural alternatives.

---

## Definitions

> I call it my billion-dollar mistake. … It was the invention of the null reference in 1965.
Tony Hoare, *Null References: The Billion Dollar Mistake*, QCon London 2009

It says one structural thing: **a function whose result might be absent must say so in its return type, and the caller must acknowledge the empty case before reading the inner value.**

A type is a *Maybe* (also called *Option*) when:

- **Two cases, by construction** — exactly one carries a value (`Some<T>` / `Optional.of(t)`), exactly one does not (`None` / `Optional.empty()`).
- **The empty case is itself a value** — it is not `null`, not a sentinel object, not a thrown exception. You can store it, pass it, equal-compare it, and serialise it like any other value.
- **No silent unwrap** — there is no public operation that reads the inner value without making the caller handle the empty case.

This axiom rejects the mainstream default: `null` as the universal stand-in for absence. `null` is a bottom value assignable to every reference type[1], so a signature `User findByEmail(String email)` can return `null` while *claiming* to return a `User`. The type system asks the caller no questions, and the cost of forgetting to ask is paid at runtime — often somewhere far from the function that returned the null.

It also rejects the related defaults: returning a *tombstone* (`new User("", "")` to mean "no user"), throwing an exception when "no match" is a normal outcome of an honest query, and using a primitive sentinel (`-1` for "no index", `""` for "no string").

C# takes a different syntactic route to the same end: *nullable reference types* (`string?`, `User?`) extend the type system so the compiler distinguishes "a value of T" from "a value of T-or-absent" without introducing a wrapper. There is no `Option<T>` in the standard library, but the discipline this axiom demands — make absence honest at the type level, force the caller to handle it — is the same. The trade-off is discussed below and in the references[5].

---

## Recognizing Maybe

The five short quizzes below apply the rule. Each row pairs a small C# example with its Java counterpart; ask whether the pair forces the caller to acknowledge the empty case before reading the value.

### Is this honest about absence? (1/5) — the null lie

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public User FindByEmail(string email) =>
    repository.SingleOrDefault(u => u.Email == email);
```

</td>
<td>

```java
public User findByEmail(String email) {
    return repository.stream()
        .filter(u -> u.email().equals(email))
        .findFirst()
        .orElse(null);
}
```

</td>
</tr>
</table>

❌ Not honest — the return type says `User`, but the body may return `null`. The signature lies; every caller is responsible for null-checking, and the compiler will not remind them.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
#nullable enable
public User? FindByEmail(string email) =>
    repository.SingleOrDefault(u => u.Email == email);
```

</td>
<td>

```java
public Optional<User> findByEmail(String email) {
    return repository.stream()
        .filter(u -> u.email().equals(email))
        .findFirst();
}
```

</td>
</tr>
</table>

✅ Honest — both signatures tell the caller the result may be absent. C# does it by typing the reference itself; Java does it with a wrapper. Either way the compiler flags any caller that tries to read the value without handling the empty case.

### Is this honest about absence? (2/5) — exception masquerading as absence

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public User GetByEmail(string email) =>
    repository.Single(u => u.Email == email);
// throws InvalidOperationException on miss
```

</td>
<td>

```java
public User getByEmail(String email) {
    return repository.stream()
        .filter(u -> u.email().equals(email))
        .findFirst()
        .orElseThrow();
    // throws NoSuchElementException on miss
}
```

</td>
</tr>
</table>

❌ Not honest — the signature says `User`, and the exception is what happens when there isn't one. Exceptions are for *exceptional* outcomes; "no user with this email" is not exceptional, it is the question the function was asked. Callers either have to wrap the call in try/catch (the same pattern as a null check, only slower and with worse readability) or trust that the email always exists. The honest version is the same shape as quiz 1/5 — and the rename carries the honesty in the *name* too: `get` suggests "give me this thing"; `find` suggests "look and see whether it's there."

### Is this honest about absence? (3/5) — tombstone / null object

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public User FindByEmail(string email) =>
    repository.SingleOrDefault(u => u.Email == email)
    ?? new User("", "");
```

</td>
<td>

```java
public User findByEmail(String email) {
    return repository.stream()
        .filter(u -> u.email().equals(email))
        .findFirst()
        .orElse(new User("", ""));
}
```

</td>
</tr>
</table>

❌ Not honest — the caller cannot tell a real `User("", "")` from "no user found." Worse, downstream code now operates on a value that *looks* present and quietly produces garbage. The tombstone strategy is the worst of both worlds: the cost of constructing a fake plus the silent corruption of a `null`. The honest version is the same shape as quiz 1/5 — absence becomes a *different value* from "a real user whose fields happen to be empty," and downstream code is forced to acknowledge which it has.

### Is this honest about absence? (4/5) — wrapped but never handled

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public string GetDisplayName(int userId) {
    User? user = FindById(userId);
    return user!.Name;
}
```

</td>
<td>

```java
public String getDisplayName(int userId) {
    return findById(userId).get().name();
}
```

</td>
</tr>
</table>

❌ Not honest — wrapping the source in `Optional<T>` or `T?` is only useful if callers actually handle the empty case. `Optional.get()` (without first calling `isPresent()` or `orElseThrow` with a meaningful message) and C#'s null-forgiving operator (`!`) re-introduce exactly the lie the type was meant to prevent. Treat them as code smells; their legitimate uses are vanishingly rare.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public string GetDisplayName(int userId) =>
    FindById(userId)?.Name ?? "(unknown)";
```

</td>
<td>

```java
public String getDisplayName(int userId) {
    return findById(userId)
        .map(User::name)
        .orElse("(unknown)");
}
```

</td>
</tr>
</table>

✅ Honest — the caller transformed the present case and supplied a value for the empty case. Both cases appear in the source.

### Is this honest about absence? (5/5) — Maybe in the wrong place

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed record User(
    string Email,
    string Name,
    string? MiddleName);
```

</td>
<td>

```java
public record User(
    String email,
    String name,
    Optional<String> middleName) {}
```

</td>
</tr>
</table>

❌ The Java version is dishonest *enough* — `Optional` is intended as a return type, not a field[2]. Putting it on a record introduces a wrapper that every serializer, ORM, and reflection-driven framework has to be taught how to handle, and the default mappings tend to leak. The C# version, using a nullable annotation on the field, is the honest equivalent: the field's type itself tells the truth, without dragging a wrapper through serialisation.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed record User(
    string Email,
    string Name,
    string? MiddleName);
```

</td>
<td>

```java
public record User(
    String email,
    String name,
    @Nullable String middleName) {}
```

</td>
</tr>
</table>

✅ Honest — the field's type carries the absence at the type-system level. Both serialisers and equality work the same way they do for any other field.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
List<string?> namesOrMissing = LoadNames();
```

</td>
<td>

```java
List<Optional<String>> namesOrMissing = loadNames();
```

</td>
</tr>
</table>

❌ A collection of Maybes is almost always wrong. A list already represents "zero or more elements"; adding a per-element absence on top is a distinction without a meaning. Prefer either a `List<T>` that may be empty, or a `Maybe<List<T>>` if you want to distinguish "we didn't load it" from "we loaded it and there's nothing."

### What an honest signature buys you

The five quizzes above show what *not* to do. Here is the positive payoff — what the toolchain refuses to let you write, once the return type is honest:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
#nullable enable
public User? FindById(int id) => ...;

string name = FindById(42).Name;
// warning CS8602: Dereference of a possibly null reference.
// Build still passes.
```

</td>
<td>

```java
public Optional<User> findById(int id) { ... }

String name = findById(42).name();
// error: cannot find symbol
//   symbol:   method name()
//   location: class java.util.Optional<User>
```

</td>
</tr>
</table>

Same gesture, two different verdicts. Java refuses the program: `Optional<User>` does not have a `name()` method, and the only way to reach the inner `User` is through methosds like `orElse`, `ifPresent`, or pattern matching — all of which surface the empty case. C# warns: `T?` and `T` are the same type at runtime, so the dereference is structurally allowed; only flow analysis flags it. A project that promotes the warning to a build failure (`TreatWarningsAsErrors` or scoped equivalents) recovers most of Java's guarantee; one that leaves it as a warning recovers very little.

### Handling both cases

Once the signature is honest, the next question is: how do you actually write the handler? Each language has a canonical shape that names both branches in the source.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
string name = FindById(42) switch
{
    User u => u.Name,
    null   => "(unknown)"
};
```

</td>
<td>

```java
String name = findById(42)
    .map(User::name)
    .orElse("(unknown)");
```

</td>
</tr>
</table>

C# names both cases directly with a switch expression matching on `User u` and `null` — the compiler refuses to compile the switch if either arm is missing for an exhaustive set. Java threads them through `map` (present case) and `orElse` (empty case): the two branches sit on separate lines and neither is optional — `map` alone returns `Optional<String>`, so the caller still has to resolve the empty case before reading a `String`.

For one-line transformations C# offers a compact alternative — `FindById(42)?.Name ?? "(unknown)"` — where `?.` short-circuits to `null` on the empty case and `??` supplies the default; Java's chain above is already its compact form. Reach for the verbose `switch` when each branch does meaningful work and naming the cases earns its syntax; reach for the compact form when the transformation would otherwise be lost in the scaffolding.

---

## Problem / forces

Writing ordinary line-of-business code, engineers keep asking questions that may not have an answer:

- "Find the user with this email."
- "Look up the config value for this key."
- "Find the first item that matches this predicate."
- "Read this optional header from the request."

The result is one of two facts: a value, or no value. Both are normal; the function is *asking* whether the value is there.

The default tool the industry reaches for — a return type `T` whose value may be `null` — quietly works against most of those forces:

- The signature lies. `User findByEmail(String email)` reads as "returns a User"; in practice it returns "User or null." Callers have to remember to null-check; the compiler does not help (until C# introduced nullable reference types, and even then only when enabled).
- `null` is overloaded. It means "no value", "not yet initialised", "doesn't apply in this case", "sentinel for unknown", and "exception fallback", all with the same name. The same bottom value carries every kind of absence.
- The cost of forgetting to handle null is a `NullPointerException` / `NullReferenceException` at runtime, often far from the function that returned the null. The stack trace points at the consumer, not the producer.
- Throwing on absence (the other common default) turns "no match found" into a control-flow event with stack traces and worse performance — and it conflates a normal answer with a system error.

The competing force pulling the other way is **brevity** and **ergonomics**. `user.getName()` is shorter than `user.map(User::getName).orElse("")`. C# `user.Name` is shorter than `user?.Name ?? ""`. The axiom does not deny this force; it pays the verbosity cost in exchange for moving the absence check from the runtime into the type system, where the compiler does it for you. As with Axiom 2, the win is that a class of bugs disappears at compile time instead of being something to find at code review.

---

## Why

**1. The type is the contract.**
A function signature is the cheapest documentation in software, and it is the only documentation the compiler reads. A signature that says `T` and sometimes returns `null` is a *false* contract; one that says `Optional<T>` or `T?` is a *true* one. The cost of telling the truth is a parametric wrapper (or a `?` modifier); the cost of lying is paid by every caller, every time, forever — and the compiler will never remind the careless one.

**2. Hoare's "billion-dollar mistake" was specifically this.**
Hoare himself, at QCon 2009, identified the introduction of `null` references in ALGOL W in 1965 as his single most expensive design choice: "I call it my billion-dollar mistake. … This has led to innumerable errors, vulnerabilities, and system crashes, which have probably caused a billion dollars of pain and damage in the last forty years."[3] The Maybe type is the standard mitigation — older than the diagnosis, dating back to Standard ML's `option` and Haskell's `Maybe`[4]. The C# language team's nullable-reference-types feature is a different implementation of the same mitigation, recognising the same problem 53 years later[5].

**3. Absence is a value; treat it like one.**
[Axiom 1](axiom-01-data-vs-behaviour.md) says data should be a *value*; absence is one of the facts you sometimes want to represent. Modelling it as `null` makes absence a property of the *reference* (a place where the value isn't); modelling it as `None` / `Optional.empty()` makes it a value alongside the others, with the same compositional properties. You can store it, return it, pass it, map over it, and test it the same way you test a present value. Hickey's argument that values are place-independent and the same everywhere applies cleanly here[6]: an empty `Optional` is the same value forever, the same way the integer `0` is.

**4. The compiler becomes your reviewer — to differing degrees.**
You stop having to remember to write the null check; the toolchain reminds you. *How loudly* it reminds you varies. Java's `Optional<T>` is **structural**: `findById(id).name()` is a compile *error*, because `name()` does not exist on `Optional<User>`. C# `T?` with NRT on is **advisory**: the compiler emits `CS8602: dereference of a possibly null reference`, but the build still passes unless you have opted into `TreatWarningsAsErrors`. F#'s `Option` and Haskell's `Maybe` go further still: pattern matches must be exhaustive, and the compiler errors on a missing branch under the warning flags typically used in production. Same axiom; three points on an enforcement gradient — and the cheapest point that still beats raw null is the one your project's tooling can hold the line on.

**5. Absence composes; exceptions don't.**
A function returning `Optional<User>` can be chained with another returning `Optional<Address>` (and another, and another) without any of the intermediate code knowing anything about absence — `flatMap` / `map` propagate it for you, and the same is true for `?.` chains on C# nullable references. A function throwing on absence forces every intermediate function to either catch it or document that it doesn't. The Maybe type is closed under composition; the throw is not.

---

## Trade-offs

**Verbosity on the happy path.** `value.orElse(default)` is longer than `value ?? default` is longer than `value`, and the same value passed through three transformations is `value.map(f).map(g).map(h).orElse(d)` rather than `h(g(f(value)))`. Brian Goetz acknowledged this explicitly when designing Java's `Optional`: it is "a limited mechanism for library method return types," not a general-purpose substitute for nullable everywhere[2]. On the C# side, `?.` and `??` keep the syntactic cost low, at the price of harder-to-spot misuse — `user?.Manager?.Email ?? ""` quietly swallows three different "missing" cases as one.

**Allocation on the happy path.** Every `Optional.of(x)` boxes the value. For hot inner loops returning primitives, that overhead is real — which is why Java ships `OptionalInt`, `OptionalLong`, `OptionalDouble`. In C# the nullable-reference-type approach has no allocation cost at all (`T?` for a reference type is purely a compile-time annotation), which is one of the reasons the C# team chose it over an `Option<T>` library type.

**Tooling friction.** Serializers, ORMs, and reflection-driven frameworks were designed around `null` fields and don't all know what to do with `Optional`. Jackson, Hibernate, EF Core, and friends each have their own dialect for "an optional field," and the mappings tend to be subtly leaky — `Optional<String>` may serialise as `null`, as the empty string, or as `{ "present": false }` depending on framework config.

**A second axis of choice.** When *do* you use `Optional<T>` versus `@Nullable T` versus `T?` versus splitting the type into "complete" and "partial" variants? Each language has at least two answers, and the answers don't compose cleanly across language boundaries. The pragmatic rule (and the one Goetz recommended for Java): `Optional<T>` for return types of queries that may not find anything; `@Nullable` for fields and parameters where you have no choice; never both for the same shape.

---

## When NOT to

**Fields in entities, DTOs, and persisted records.** Brian Goetz was explicit: `Optional` is for return types, not fields[2]. Putting `Optional` on a record introduces a wrapper that every serializer, ORM, and reflection-driven framework has to be taught how to handle, and the default mappings tend to leak. Either use the language's nullable annotation (Java's `@Nullable`, C#'s `T?`) or split the type into "complete" and "partial" variants and parse from one to the other.

**Inside collections.** `List<Optional<T>>` carries no useful information that `Optional<List<T>>` — or a `List<T>` that may be empty — does not carry better. Lists already represent "zero or more"; adding a second axis of absence inside each element is a distinction without a meaning in nearly every business context.

**When the absence is exceptional.** A configuration system that is documented to always supply a database URL but is found at runtime not to is in an exceptional state — that is an error, not an honest "no value." Throw and let the program fail fast at startup. Reserve `Maybe` for the case where "not there" is a normal outcome of an honest question.

**Performance-sensitive primitive code.** When you are returning a primitive in a hot loop, the boxing cost of `Optional<Integer>` is real. Use the specialised `OptionalInt` / `OptionalLong` / `OptionalDouble` in Java, or the Try-pattern (`bool TryParse(string s, out int result)`) in C# — both honest about absence, both allocation-free.

**At the boundary, briefly.** When parsing a wire format whose schema includes optional fields, you may read them as `T?` first and only lift into `Optional<T>` (or a richer value object) once you have validated the surrounding shape. The boundary code is allowed to traffic in nullable references; the domain code is not.

---

## Maybe in C# beyond `T?`

This axiom uses C# nullable reference types in its examples because they are the language's built-in answer. When you need a *structural* Maybe — one the compiler refuses to let you misuse, with guarantees closer to Java's `Optional<T>` — the .NET ecosystem offers several libraries, and the language itself is about to grow a native answer.

| Library | Wrapper | Status (May 2026) | Best for |
|---|---|---|---|
| **CSharpFunctionalExtensions** (Vladimir Khorikov) | `Maybe<T>` (struct) | Active (v3.7.0, Mar 2026) | The pragmatic choice — small surface, OO-friendly, bundles `Maybe`, value-object base, JSON / EF Core converters |
| **LanguageExt** (Paul Louth) | `Option<A>` (struct) | GitHub active; NuGet on v4 (Jun 2024) | Full FP — `Map`, `Bind`, LINQ syntax, traverse, applicative validation, monad transformers; steep learning curve |
| **OneOf** (Harry McIntyre) | `OneOf<T0, T1, …>` (struct) | Maintained | General discriminated unions; people use it for `Some`/`None` but the library is broader than Maybe |
| **Optional** (Nils Lück) | `Option<T>` (struct) | **Last NuGet release Feb 2018** | Just `Option<T>`. Pick something actively shipped for new code |

All four use a `struct` wrapper, which sidesteps the "the Optional itself can be null" hazard that Java's reference-typed `Optional<T>` has.

**Coming in C# 15 / .NET 11** (preview April 2026, GA November 2026): the language gains *union types*. The official `csharplang` proposal and the Microsoft DevBlogs post both use `Option<T>` as the prototypical example:

```csharp
public record class None();
public record class Some<T>(T value);
public union Option<T>(None, Some<T>);
```

The compiler enforces exhaustive matching on the union, with no boxing and no library dependency. Once C# 15 ships, the "what should I reach for in C#?" question may collapse into the language itself.

Picking one is an ADR-level call, not a principle-level one — it depends on the project's existing style, dependency tolerance, and how much functional infrastructure you want alongside Maybe. The axiom is the same either way: a function whose result might be absent says so in its return type.

---

## References

[1] **The Java Language Specification** §4.1 and **the C# Language Specification** §8.2.3 both define `null` as the single value of the bottom reference type, assignable to any reference type. This is the structural source of the problem this axiom addresses: every reference type secretly admits a value (`null`) that does not satisfy any of its declared invariants, and the type system makes no distinction between references that may carry it and references that do not — except where the language adds an explicit annotation (Java's `@Nullable` / `@NonNull`, C#'s nullable reference types).

[2] **Brian Goetz**, Java Language Architect, Stack Overflow answer on the intended use of `java.util.Optional` (23 October 2014):
> "Of course, people will do what they want. But we did have a clear intention when adding this feature, and it was not to be a general purpose Maybe or Some type, as much as many people would have liked us to do so. Our intention was to provide a limited mechanism for library method return types where there needed to be a clear way to represent 'no result', and using null for such was overwhelmingly likely to cause errors."

<https://stackoverflow.com/a/26328555>. The canonical project-team statement of the rules in *Definitions* and *When NOT to*; the JDK API note on `java.util.Optional` echoes it almost verbatim.

[3] **Tony Hoare**, *Null References: The Billion Dollar Mistake*, talk at QCon London, March 2009. Hoare attributes the introduction of null references to his 1965 design of ALGOL W and identifies it as his single most expensive design decision. Recording on InfoQ:
<https://www.infoq.com/presentations/Null-References-The-Billion-Dollar-Mistake-Tony-Hoare/>.

[4] **Standard ML** and **Haskell** — `option` and `Maybe` are the canonical precedents. ML's `option` type predates Hoare's public diagnosis of the null problem by decades; Haskell's `Maybe` (Haskell 1.0 Report, 1990) is by now the textbook example of a parametric algebraic data type. The "ML/Haskell answer to Hoare's mistake" historically predates Hoare's statement of the mistake.

[5] **Mads Torgersen et al.**, *Nullable reference types* in C# 8, design notes and language documentation (2018–2019):
<https://learn.microsoft.com/en-us/dotnet/csharp/nullable-references>. The C# language team adopted a different implementation of the same axiom: rather than introduce `Option<T>` to the standard library, the language extends the type system so that `T` and `T?` are distinct, with flow analysis enforcing null checks at compile time. Same axiom; different implementation; no allocation cost.

[6] **Rich Hickey**, *The Value of Values*, keynote at JaxConf 2012 (also delivered at GOTO Copenhagen 2012). Recording on InfoQ, 14 August 2012:
<https://www.infoq.com/presentations/Value-Values/>. Cited in [Axiom 1](axiom-01-data-vs-behaviour.md) as [4] and [Axiom 2](axiom-02-immutability.md) as [2]; cross-listed here because the argument that *values* are place-independent and identical-everywhere is what justifies treating absence as a value rather than as a property of a reference.

[7] **Yaron Minsky**, *Effective ML*, MLOC 2011 (notes refreshed in Jane Street's blog series). Source of the slogan "make illegal states unrepresentable," which is the broader design principle the Maybe type is one instance of: if a value cannot legally be absent, do not give it a type that admits absence; if it can, give it a type that admits exactly that and nothing else.
<https://blog.janestreet.com/effective-ml-revisited/>

[8] **The .NET Maybe ecosystem (May 2026 snapshot).**
- CSharpFunctionalExtensions: <https://www.nuget.org/packages/CSharpFunctionalExtensions> / <https://github.com/vkhorikov/CSharpFunctionalExtensions>
- LanguageExt: <https://www.nuget.org/packages/LanguageExt.Core> / <https://github.com/louthy/language-ext>
- OneOf: <https://www.nuget.org/packages/OneOf> / <https://github.com/mcintyre321/OneOf>
- Optional (nlkl): <https://www.nuget.org/packages/Optional> / <https://github.com/nlkl/Optional>

[9] **C# 15 union types.**
- Microsoft DevBlogs, *Explore union types in C# 15* (Bill Wagner, 2 April 2026): <https://devblogs.microsoft.com/dotnet/csharp-15-union-types/>
- Official proposal: <https://github.com/dotnet/csharplang/blob/main/proposals/unions.md> (mirrored at <https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/proposals/unions>)
- Andrew Lock companion writeup: <https://andrewlock.net/exploring-the-dotnet-11-preview-2-dotnet-gets-union-types/>
