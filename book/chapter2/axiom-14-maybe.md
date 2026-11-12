# Axiom 14 — Maybe

**When a result might be absent, say so in the return type: `User?` in C#, `Optional<User>` in Java.**

- The caller can't read the value without handling the empty case.
- No `null` hidden behind `User`, no placeholder object, no exception for "not found".

[Axiom 7](axiom-07-honest-total-signatures.md) ruled out silent nulls and sentinels, and replaced them with a `Found | NotFound` type written by hand. A Maybe (also called an [option type](https://en.wikipedia.org/wiki/Option_type)) is that type, ready-made and generic: the standard answer to the most common two-outcome question, "is there a value or not?". It is [Axiom 1](axiom-01-explicit-over-implicit.md)'s explicitness applied to absence. Its examples use the `map` from [Axiom 11](axiom-11-higher-order-functions.md) and the `switch` from [Axiom 12](axiom-12-pattern-matching.md).

Through [Axiom 9](axiom-09-connascence.md)'s lens, a Maybe weakens a [Connascence of Meaning](axiom-09-connascence.md#connascence-of-meaning-com) (every caller agreeing, by convention, that `null` means *absent*) into a [Connascence of Type](axiom-09-connascence.md#connascence-of-type-cot).

---

## Definitions

A type is a *Maybe* when:

- **It has two cases.** One carries a value (`Optional.of(user)`), the other doesn't (`Optional.empty()`).
- **The empty case is a value too.** Not `null`, not a placeholder, not an exception. You can store it, pass it and compare it like any other value.
- **There is no silent unwrap.** You can't read the inner value without handling the empty case.

The two languages get there in different ways:

- **Java wraps.** `Optional<User>` is a different type from `User`, and it has no `name()` method. To reach the user you go through `map`, `orElse` or `ifPresent`, and each of them makes you handle the empty case. The check is **structural**: misuse doesn't compile.
- **C# annotates.** With [nullable reference types](https://learn.microsoft.com/en-us/dotnet/csharp/nullable-references) enabled, `User?` and `User` are different to the compiler but the same type at runtime: the feature is "entirely a compile-time feature" [3]. [Flow analysis](https://en.wikipedia.org/wiki/Data-flow_analysis) warns when you read a `User?` without checking it. The check is **advisory**: the build passes on a warning unless warnings are treated as errors. (For a structural Maybe in C#, see *Maybe in C# beyond `T?`*.)

The C# examples assume `<Nullable>enable</Nullable>`, which new .NET project templates set by default.

---

## Example

### Is this honest about absence?

Four short quizzes. For each, ask whether the caller is forced to handle the empty case before reading the value.

#### 1/4 — the hidden `null`

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public User FindByEmail(string email) =>
    users.FirstOrDefault(u => u.Email == email);
```

</td>
<td>

```java
public User findByEmail(String email) {
    return users.stream()
        .filter(u -> u.email().equals(email))
        .findFirst()
        .orElse(null);
}
```

</td>
</tr>
</table>

❌ Not honest. The return type says `User`, but the body can return `null`, and every caller has to remember to check. Java says nothing. C# with nullable reference types warns on this line (`FirstOrDefault` can return `null`); with them off, it says nothing either.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public User? FindByEmail(string email) =>
    users.FirstOrDefault(u => u.Email == email);
```

</td>
<td>

```java
public Optional<User> findByEmail(String email) {
    return users.stream()
        .filter(u -> u.email().equals(email))
        .findFirst();
}
```

</td>
</tr>
</table>

✅ Honest. Both signatures tell the caller the user may not be there.

#### 2/4 — an exception for "not found"

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public User GetByEmail(string email) =>
    users.First(u => u.Email == email);
// throws InvalidOperationException on a miss
```

</td>
<td>

```java
public User getByEmail(String email) {
    return users.stream()
        .filter(u -> u.email().equals(email))
        .findFirst()
        .orElseThrow();
    // throws NoSuchElementException on a miss
}
```

</td>
</tr>
</table>

❌ Not honest. "No user with this email" is not exceptional: it is a normal answer to the question the function was asked. Throwing sends that answer through a side channel ([Axiom 7](axiom-07-honest-total-signatures.md#definitions)). The fix is quiz 1's honest version, and the rename helps too: `get` says "give me this", `find` says "look and see whether it's there".

#### 3/4 — a placeholder object

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public User FindByEmail(string email) =>
    users.FirstOrDefault(u => u.Email == email)
    ?? new User("", "");
```

</td>
<td>

```java
public User findByEmail(String email) {
    return users.stream()
        .filter(u -> u.email().equals(email))
        .findFirst()
        .orElse(new User("", ""));
}
```

</td>
</tr>
</table>

❌ Not honest. This is a [sentinel value](https://en.wikipedia.org/wiki/Sentinel_value) shaped like an object. The caller can't tell a real `User("", "")` from "no user found", so downstream code works on a value that *looks* present and quietly produces garbage. The fix is again quiz 1's honest version: absence becomes a different value from "a real user whose fields happen to be empty".

#### 4/4 — wrapped, but never handled

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public string GetDisplayName(int userId) =>
    FindById(userId)!.Name;
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

❌ Not honest. The Maybe only helps if callers handle the empty case. C#'s null-forgiving operator `!` and Java's `Optional.get()` read the value without that check, and the lie is back. Treat both as a smell.

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

✅ Honest. The caller transforms the present case and supplies a value for the empty one. Both cases are in the source.

### What the compiler does with it

Once the return type is honest, here is what the toolchain says when a caller forgets the empty case:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public User? FindById(int id) => ...;

string name = FindById(42).Name;
// warning CS8602: Dereference of a
// possibly null reference.
// The build still passes.
```

</td>
<td>

```java
public Optional<User> findById(int id) { ... }

String name = findById(42).name();
// error: cannot find symbol
// (Optional<User> has no method name())
```

</td>
</tr>
</table>

Same mistake, two verdicts (see *Definitions*). Java refuses the program. C# warns, and a project that sets `TreatWarningsAsErrors` (or promotes the nullable warnings to errors) gets most of Java's guarantee back.

### Handling both cases

Each language has a natural way to write both branches:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
var found = FindById(42);
string name = found switch
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

- **C#** names both cases in a `switch` ([Axiom 12](axiom-12-pattern-matching.md)). Leave out the `null` branch and the compiler warns that a `null` input isn't handled. For a one-line transformation, `FindById(42)?.Name ?? "(unknown)"` says the same thing: `?.` passes the empty case through and `??` supplies the default. Use the `switch` when each branch does real work, and the short form when the scaffolding would bury a simple transformation.
- **Java** threads the two cases through `map` (present) and `orElse` (empty). Neither can be skipped: `map` alone still returns an `Optional<String>`, so the caller has to resolve the empty case before it gets a `String`.

---

## Problem / forces

Tony Hoare introduced the null reference in ALGOL W in 1965 "simply because it was so easy to implement", and later called it "my billion-dollar mistake" [1].

Line-of-business code keeps asking questions that may have no answer:

- "Find the user with this email."
- "Look up the config value for this key."
- "Find the first item that matches."
- "Read this optional request header."

Both answers are normal: a value, or no value. [Axiom 7](axiom-07-honest-total-signatures.md#definitions) showed what it costs to deliver the second one as `null`: the signature lies, and the bug lands on the caller. Absence adds one cost of its own. `null` means many things at once: "not found", "not set yet", "doesn't apply", "unknown". It is a homonym in the sense of [Axiom 0](axiom-00-ubiquitous-language.md), at the level of the type system. A Maybe means exactly one thing: this question had no answer.

The force pulling the other way is brevity (see *Trade-offs*).

---

## Why

**1. One standard type instead of one per function.**
[Axiom 7](axiom-07-honest-total-signatures.md)'s `FindResult` works, but writing a `Found | NotFound` pair for every lookup gets repetitive, and every copy is slightly different. A Maybe is the shared shape. Every lookup returns the same type, every caller handles it the same way, and the language and its standard library already know how to transform it.

**2. Absence is a value.**
[Axiom 2](axiom-02-data-is-not-behavior.md) says data is a value. `null` is the absence of an object; `Optional.empty()` is an object that means absence. You can store it, return it, compare it and test it, and it means the same thing everywhere [4].

**3. Absence travels without checks in between.**
A chain of steps that may each find nothing needs no `if` between them:

```java
Optional<String> email = findUser(id)
    .flatMap(this::findManagerOf)   // a lookup that may find nothing
    .map(Manager::email);
```

`map` transforms a present value; `flatMap` is the same for a function that itself returns an `Optional`. If any step comes back empty, the rest are skipped and the result is empty. C#'s `?.` does the same along nullable properties: `FindUser(id)?.Manager?.Email`. The empty case is handled once, at the end of the chain.

---

## Trade-offs

- **It costs some length.** `value.map(f).orElse(d)` is longer than `f(value)`, and `user?.Name ?? ""` is longer than `user.Name`. That is the same price honesty charges in [Axiom 7](axiom-07-honest-total-signatures.md#trade-offs): the author pays once, so that no caller pays later.
- **A short chain can hide different absences.** `user?.Manager?.Email ?? ""` turns three different "missing" cases (no user, no manager, no email) into the same empty string. When the caller needs to know which one happened, see *When NOT to*.
- **Java allocates.** Every `Optional` is an object, and `Optional<Integer>` also [boxes](https://en.wikipedia.org/wiki/Boxing_(computer_programming)) the `int`. `OptionalInt`, `OptionalLong` and `OptionalDouble` avoid the box. C# pays nothing at runtime: `T?` on a reference type is only an annotation, and `int?` is a struct (`Nullable<int>`).
- **Frameworks need help with `Optional` fields.** Serializers and ORMs were built around nullable fields. An `Optional` field needs extra configuration (Jackson, for example, needs an extra module), and the defaults vary between frameworks. This is one reason `Optional` stays out of fields (see *When NOT to*).

---

## When NOT to

- **Fields, and parameters of public APIs.** `Optional` is designed as a return type [2]. Callers shouldn't have to wrap values they already hold just to call you. On a field or a record component it drags a wrapper through every serializer and ORM (see *Trade-offs*). Use the nullable annotation instead: `string? MiddleName` in C#, and in Java `@Nullable String middleName` from [JSpecify](https://jspecify.dev/). In Java that annotation is checked by tools such as NullAway or the IDE, not by `javac`. Boundary types (DTOs, request bodies) can keep nullable fields; parse them into domain types once, at the edge.
- **Inside collections.** A list already means "zero or more", so `List<Optional<String>>` adds a second kind of absence with no meaning. Use a list that may be empty. Use `Optional<List<T>>` only when "not loaded" and "loaded, but empty" really are different facts.
- **When the caller needs to know why.** A Maybe only says "nothing". If there are several reasons for nothing (not found, expired, not allowed) and the caller reacts differently to each, a Maybe hides outcomes, which is [Axiom 7](axiom-07-honest-total-signatures.md)'s lie again. Name each reason in the return type, the way `FindResult` does.
- **When absence is a bug.** A database URL that the configuration always provides is not an honest "maybe": if it's missing, the program is broken. Fail loudly at startup ([Axiom 7](axiom-07-honest-total-signatures.md#when-not-to), last point).
- **A measured hot path in Java.** If profiling shows the `Optional` allocations matter, use `OptionalInt` and friends, or a sentinel that never leaves one private function.

---

## Maybe in C# beyond `T?`

The examples use C# nullable reference types because they are the language's built-in answer. When you want a *structural* Maybe in C#, one the compiler won't let you misuse, there are libraries, and the language is growing its own answer.

| Library | Type | Fits |
|---|---|---|
| **CSharpFunctionalExtensions** (Vladimir Khorikov) | `Maybe<T>` (struct) | A small, OO-friendly toolkit. Also ships JSON and EF Core converters. |
| **LanguageExt** (Paul Louth) | `Option<A>` (struct) | A full functional-programming library. Powerful, with a steep learning curve. |
| **OneOf** (Harry McIntyre) | `OneOf<T0, T1, …>` (struct) | General "one of several types" values. It can model Maybe, but it is broader. |
| **Optional** (Nils Lück) | `Option<T>` (struct) | Just `Option<T>`. Its last stable release is from February 2018, so prefer an actively maintained library for new code. |

All four use a `struct`, so the Maybe itself can't be `null`. (Java's `Optional` is a reference type, so a variable of type `Optional` can still hold `null`; its documentation says it never should [2].)

**C# 15 adds [union types](https://en.wikipedia.org/wiki/Union_type)** (available since the .NET 11 previews) [6]. A Maybe can be declared directly:

```csharp
public sealed record None;
public sealed record Some<T>(T Value);
public union Option<T>(Some<T>, None);
```

A `switch` that covers every case type needs no discard branch, and a missing case is a compiler warning. Two limits. The built-in union stores its contents as an `object?` reference, so value types are boxed. And the union is a `struct` whose `default` value holds no case at all: its `Value` is `null`. Where a union can be `default` (an uninitialized field, a new array) or a case type is nullable, the `switch` needs a `null` arm [6]. Unlike a discard, that arm is a real branch: it handles "no case yet". Once C# 15 is in use, the question "which library?" may go away.

Which option to pick is a contextual choice, not a principle. It depends on the project's style, how many dependencies it accepts, and how much functional tooling it wants alongside Maybe [5]. The axiom is the same either way: a function whose result might be absent says so in its return type.

---

## References

[1] **Tony Hoare**, *Null References: The Billion Dollar Mistake*, talk at QCon London, 2009. The InfoQ summary: he introduced null references in ALGOL W in 1965 "simply because it was so easy to implement", and calls that decision "my billion-dollar mistake".
<https://www.infoq.com/presentations/Null-References-The-Billion-Dollar-Mistake-Tony-Hoare/>

[2] **`java.util.Optional` API note**, Java SE 21 documentation: "`Optional` is primarily intended for use as a method return type where there is a clear need to represent "no result," and where using `null` is likely to cause errors. A variable whose type is `Optional` should never itself be `null`; it should always point to an `Optional` instance." Brian Goetz, Java's language architect, gave the same intent in a 2014 Stack Overflow answer: `Optional` was meant as a limited mechanism for library method return types, not as a general-purpose Maybe.
<https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Optional.html> · <https://stackoverflow.com/a/26328555>

[3] **Microsoft**, *Nullable reference types*, C# documentation. "The runtime behavior of your program is unchanged. Nullable reference types are entirely a compile-time feature." `string` and `string?` are both `System.String` at runtime.
<https://learn.microsoft.com/en-us/dotnet/csharp/nullable-references>

[4] **Rich Hickey**, *The Value of Values*, keynote at JaxConf 2012. Also cited in [Axiom 2](axiom-02-data-is-not-behavior.md) and [Axiom 3](axiom-03-immutability.md). Values are the same everywhere and don't depend on a place, which is why absence works better as a value than as a missing reference.
<https://www.infoq.com/presentations/Value-Values/>

[5] **The .NET Maybe libraries.**
- CSharpFunctionalExtensions: <https://www.nuget.org/packages/CSharpFunctionalExtensions> · <https://github.com/vkhorikov/CSharpFunctionalExtensions>
- LanguageExt: <https://www.nuget.org/packages/LanguageExt.Core> · <https://github.com/louthy/language-ext>
- OneOf: <https://www.nuget.org/packages/OneOf> · <https://github.com/mcintyre321/OneOf>
- Optional: <https://www.nuget.org/packages/Optional> · <https://github.com/nlkl/Optional>

[6] **Bill Wagner**, *Explore union types in C# 15*, .NET Blog, 2 April 2026. Union declarations, exhaustive `switch` without a discard, when a `null` arm is needed, and how a union stores (and boxes) its value.
<https://devblogs.microsoft.com/dotnet/csharp-15-union-types/>

---

← Previous: [Axiom 13 — Impureim](axiom-13-impureim.md) · Next: [Axiom 15 — Either](axiom-15-either.md) →
