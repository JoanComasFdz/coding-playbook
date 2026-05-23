# Axiom 1 — Immutability

**Data cannot be modified after it is created.**

- Model facts as values: once constructed, they never change.
- Carry the discipline all the way down — a single mutable field anywhere makes the whole object mutable.

[Axiom 0](axiom-00-data-vs-behaviour.md) already touches on immutability — its claim that data is a *value* depends on it. This axiom is the deep dive: what immutability is, how to recognise it, what it costs, and what it buys.

---

## Definitions

> Data is immutable.
Yehonathan Sharvit's Principle #3

It says one structural thing: **once a value exists, no one — including the code that produced it — may change it.**

A type is immutable when every one of the following is true:

- **Records or final classes** — the type cannot be extended into a mutable subtype.
- **No public fields** — fields cannot be reached and reassigned from outside.
- **No setters** — no method reassigns a field after construction.
- **Immutable fields, all the way down** — every field is itself a value (no `List`, no `Date`, no `Address`-with-a-setter masquerading as one).
- **No state-changing methods** — no method changes the object's internal state, even if it returns `void`.
- **Final / readonly fields** — declare every field `final` (Java) / `readonly` (C#) so the compiler refuses any reassignment after construction. Class-level discipline (no setter) keeps the public surface clean; field-level discipline keeps future maintainers honest.

This axiom rejects the mainstream default: a "data class" whose `final` keyword guards only the outermost wrapper while mutability leaks through public fields, setters, mutable collections, or a method called `increment()`.

The discipline is contract-level, not byte-level. Reflection, `Unsafe`, and JNI can break any of the rules above; that does not make the type mutable, only that the language permits trespass[1]. The contract holds for code that does not cheat.

---

## Recognizing immutability

The five short quizzes below apply the checklist. Each row pairs a small C# type with its Java counterpart; ask whether the pair is immutable before reading on.

### Is this immutable? (1/5) — extension and setters

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public class Person(string name)
{
    public string Name { get; } = name;
}
```

</td>
<td>

```java
public class Person {
    private String name;
    public Person(String name) {
        this.name = name;
    }
    public String getName() {
        return name;
    }
}
```

</td>
</tr>
</table>

❌ Not immutable — the class can be extended; a subclass can add a setter or override the getter to return mutable state.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed class Person(string name)
{
    public string Name { get; } = name;
}
```

</td>
<td>

```java
public final class Person {
    private String name;
    public Person(String name) {
        this.name = name;
    }
    public String getName() {
        return name;
    }
}
```

</td>
</tr>
</table>

✅ Immutable — `sealed` / `final` blocks extension, there is no setter, and `string` is itself a value.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed class Person(string name)
{
    public string Name { get; set; } = name;
}
```

</td>
<td>

```java
public final class Person {
    private String name;
    public Person(String name) {
        this.name = name;
    }
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }
}
```

</td>
</tr>
</table>

❌ Not immutable — the setter reassigns `name` after construction.

### Is this immutable? (2/5) — depth

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed class Person(string name)
{
    public string Name = name;
}
```

</td>
<td>

```java
public final class Person {
    public String name;
    public Person(String name) {
        this.name = name;
    }
}
```

</td>
</tr>
</table>

❌ Not immutable — the public field can be reassigned from outside the class.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed class Person(List<string> friends)
{
    public List<string> Friends { get; } = friends;
}
```

</td>
<td>

```java
public final class Person {
    private List<String> friends;
    public Person(List<String> friends) {
        this.friends = friends;
    }
    public List<String> getFriends() {
        return friends;
    }
}
```

</td>
</tr>
</table>

❌ Not immutable — `List` itself is mutable, so any caller can mutate the contents of the returned reference.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed class Person(Address address)
{
    public Address Address { get; } = address;
}

public sealed class Address(string street)
{
    public string Street { get; set; } = street;
}
```

</td>
<td>

```java
public final class Person {
    private Address address;
    public Person(Address address) {
        this.address = address;
    }
    public Address getAddress() {
        return this.address;
    }
}
public final class Address {
    private String street;
    public String getStreet() {
        return this.street;
    }
    public void setStreet(String street) {
        this.street = street;
    }
}
```

</td>
</tr>
</table>

❌ Not immutable — `Address` exposes a setter, so the contained value can change underneath `Person`.

### Is this immutable? (3/5) — state-changing methods and value types

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed class Counter(int initialCount)
{
    private int count = initialCount;
    public int Count => count;
    public void Increment() => count++;
}
```

</td>
<td>

```java
public final class Counter {
    private int count;
    public Counter(int initialCount) {
        this.count = initialCount;
    }
    public int getCount() {
        return count;
    }
    public void increment() {
        this.count++;
    }
}
```

</td>
</tr>
</table>

❌ Not immutable — `Increment` / `increment()` mutates the field after construction.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
var person = new Person("Alice");
var nameField = typeof(Person).GetField(
    "name",
    BindingFlags.NonPublic | BindingFlags.Instance);
nameField!.SetValue(person, "Bob");

public sealed class Person
{
    private readonly string name;
    public Person(string name) => this.name = name;
}
```

</td>
<td>

```java
void main() throws Exception {
    var person = new Person("Alice");
    var nameField = Person.class.getDeclaredField("name");
    nameField.setAccessible(true);
    nameField.set(person, "Bob");
}

final class Person {
    private String name;
    Person(String name) {
        this.name = name;
    }
}
```

</td>
</tr>
</table>

✅ Immutable — the type's contract still holds; reflection is a language escape hatch, not a refutation.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed class Person(DateOnly birthdate)
{
    public DateOnly Birthdate { get; } = birthdate;
}
```

</td>
<td>

```java
public final class Person {
    private LocalDate birthdate;
    public Person(LocalDate birthdate) {
        this.birthdate = birthdate;
    }
    public LocalDate getBirthdate() {
        return birthdate;
    }
}
```

</td>
</tr>
</table>

✅ Immutable — `DateOnly` / `LocalDate` is itself a value, so the field cannot change underneath.

### Is this immutable? (4/5) — records

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
record Person(DateOnly Birthdate);
```

</td>
<td>

```java
record Person(LocalDate birthdate) {}
```

</td>
</tr>
</table>

✅ Immutable — `record` makes the wrapper a value, and `DateOnly` / `LocalDate` is itself a value.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
record Person(List<string> Friends);
```

</td>
<td>

```java
record Person(List<String> friends) {}
```

</td>
</tr>
</table>

❌ Not immutable — `record` only protects the wrapper; the `List` inside can still be mutated.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
var person = new Person("Alice");
var nameProperty = typeof(Person).GetProperty("Name");
nameProperty!.SetValue(person, "Bob");

record Person(string Name);
```

</td>
<td>

```java
void main() throws Exception {
    var person = new Person("Alice");
    var nameField = Person.class.getDeclaredField("name");
    nameField.setAccessible(true);
    nameField.set(person, "Bob");
}

record Person(String name) {}
```

</td>
</tr>
</table>

✅ Immutable — the record's contract still holds; reflection is the same language-level trespass as before, not a refutation.

### Is this immutable? (5/5) — defense in depth

The first four quizzes ask whether the public surface of a type allows mutation. This one asks the next question: with a clean public surface, what stops the *next* maintainer from reassigning a field from inside the class?

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed class Person(string name)
{
    private string name = name;
    public string Name => name;
    public void Rename(string newName) => name = newName;
}
```

</td>
<td>

```java
public final class Person {
    private String name;
    public Person(String name) {
        this.name = name;
    }
    public String getName() {
        return name;
    }
    public void rename(String newName) {
        this.name = newName;
    }
}
```

</td>
</tr>
</table>

❌ Not immutable — the class is `sealed` / `final` and has no setter, but `Rename` / `rename` reassigns the field from inside. Nothing at the class level forbids this.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public sealed class Person(string name)
{
    private readonly string name = name;
    public string Name => name;
}
```

</td>
<td>

```java
public final class Person {
    private final String name;
    public Person(String name) {
        this.name = name;
    }
    public String getName() {
        return name;
    }
}
```

</td>
</tr>
</table>

✅ Immutable — `readonly` / `final` on the field means the compiler refuses any reassignment after construction. A future maintainer who tries to add a `Rename` / `rename` method gets a compile error.

---

## Problem / forces

When writing ordinary line-of-business code, engineers keep doing the same things to their data: hand it to other functions, store and retrieve it, serialise and transmit it, inspect it long after the moment that produced it, and reuse the same shapes across modules.

The default tool the industry reaches for — a class with private mutable fields and getter/setter accessors — quietly works against most of those forces:

- Two parts of the program holding references to "the same object" silently drift, because any holder can mutate it without telling the others.
- Every accessor that returns an internal collection or sub-object has to clone, or callers can reach in and change it; every method that accepts one has to clone it on the way in.
- The value a field held two seconds ago exists only in the logs you remembered to write; equality and identity drift apart, and there is no clean way to ask "what was this at 14:03?"

The competing force is **ergonomics** — in-place update reads naturally ("the counter increments"), and most of the tooling (ORMs, serialisers, UI frameworks) was designed assuming setters. The axiom does not deny this force; it relocates it. Mutation is a property of the *shell* — Axiom 0's impure orchestrator — not of the data itself.

---

## Why

**1. A value is a fact; facts do not change.**
The deeper reason data should be immutable is that data represents facts about the world, and facts about the world do not change after they happen. The order *was* placed at 14:03. The customer's birthday *is* 1987-04-12. Overwriting a memory cell with new information does not change the old fact; it only loses your reference to it. This is Hickey's place-oriented critique[2] — and it is what Axiom 0 was already pointing at when it called data a *value*. Axiom 1 is just enforcing that claim.

**2. No action at a distance.**
The most expensive class of bugs in OO codebases comes from one piece of code mutating an object that another piece of code is still using. Immutability eliminates the class. If a function hands you a value, nothing the function later does can change what you hold; if you hand a value to a function, nothing it does can change what you still hold. Every reference is, in effect, a defensive copy you did not have to write.

**3. Concurrency without coordination.**
Locks exist because state is both *shared* and *mutable*. Remove the mutability and the lock disappears. A value can be read by any number of threads, in any order, with no synchronisation, and no thread will ever see an inconsistent view. This is the single cheapest concurrency win available, and it is the property that makes distributed systems tractable at all[2].

**4. Cheap to reason, cheap to test.**
A function over immutable inputs is the easiest thing in the universe to test: pin the inputs, pin the output, no setup, no teardown, no order-of-operations effects between cases. The same property that makes it testable — that the inputs uniquely determine the output — is also what lets you read the call site once and trust it. (And as a minor bonus, short-lived values are cheap for the garbage collector to reclaim.)

---

## Trade-offs

Sharvit names the costs honestly[3] and they apply here too. Immutable types cost you **ergonomics on update**: changing a field means producing a new value (`record.with(name = "x")`, builder patterns, lens libraries), which is verbose in Java and C# compared to `obj.name = "x"`. They cost you **tooling friction**: ORMs (Hibernate, EF) and some serialisers were designed for mutable entities and need adaptation. They cost you a small amount of **allocation pressure**, since you cannot mutate in place; modern GCs absorb most of this, but in tight loops it matters[4]. And they cost you **named entities** — a separate "builder" or "with-er" surface where mutation used to live inline.

These costs buy what Why lists above. The trade is almost always worth it for line-of-business code; it sometimes is not for inner loops (see below).

---

## When NOT to

Mutable state earns its keep in two main cases.

**Inner loops where allocation dominates.** When you are inside a tight hot path — a parser tokenising megabytes per second, a renderer building a frame, a physics step iterating millions of bodies — copy-on-write loses to in-place update on the only axis that matters. This is the Mike Acton territory Axiom 0 already flagged as out-of-scope for this playbook[5], and the same caveat applies here: a *performance* argument, not a *complexity* one.

**Boundary objects you do not own.** ORM entities, framework callbacks, and DTOs from generated code sometimes ship with setters you cannot remove. Wrap them: parse them into immutable value objects at the boundary, work in immutable types in the core, and project back out at the exit. The shell is allowed to be mutable; the core is not.

---

## References

[1] **JLS / `java.lang.reflect`** and **`sun.misc.Unsafe`** are the canonical Java escape hatches; **`System.Reflection`** with `BindingFlags.NonPublic | BindingFlags.Instance` (and `FieldInfo.SetValue`) is the equivalent in .NET. Their existence means no JVM- or CLR-level guarantee of immutability is possible; the contract is enforced at the source level only.

[2] **Rich Hickey**, *The Value of Values*, keynote at JaxConf 2012 (also delivered at GOTO Copenhagen 2012). Recording on InfoQ, published 14 August 2012:
<https://www.infoq.com/presentations/Value-Values/>. The argument that values — immutable, location-independent — are what make concurrency and distribution tractable. Already cited in [Axiom 0](axiom-00-data-vs-behaviour.md) as reference [4]; cross-listed here because the argument is load-bearing for Axiom 1 as well.

[3] **Yehonathan Sharvit**, *Data-Oriented Programming: Reduce software complexity*, Manning Publications, 2022 — Principle #3 ("Data is immutable") and the discussion of update ergonomics, allocation cost, and tooling friction in the corresponding chapter.
<https://www.manning.com/books/data-oriented-programming>

[4] **Chris Okasaki**, *Purely Functional Data Structures*, Cambridge University Press, 1998. The standard reference on how to build immutable data structures (lists, queues, heaps, finger trees) with asymptotic costs comparable to their mutable counterparts — the answer to "but isn't copy-on-write slow?" for everything outside the absolute hottest loops.

[5] **Mike Acton**, *Data-Oriented Design and C++*, keynote at CppCon 2014:
<https://www.youtube.com/watch?v=rX0ItVEVjHc>. Already cited in [Axiom 0](axiom-00-data-vs-behaviour.md) as reference [6]; relevant here as the dominant counter-argument inside performance-critical inner loops.

[6] **Joshua Bloch**, *Effective Java*, 3rd ed., Addison-Wesley, 2018 — Item 17, "Minimize mutability". The canonical Java-specific statement of the rules listed in this axiom's *Definitions* section, with the same five-point recipe (no mutators, ensure the class cannot be extended, make all fields final, make all fields private, ensure exclusive access to any mutable components).
