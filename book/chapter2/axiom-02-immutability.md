# Axiom 2 — Immutability

**Data cannot be modified after it is created.**

- Model facts as values: once constructed, they never change.
- Carry the discipline all the way down: a single mutable field anywhere makes the whole object mutable.

[Axiom 1](axiom-01-data-is-not-behavior.md) already touches on immutability: its claim that data is a *value* depends on it. This axiom goes deeper: what immutability is, how to recognize it, what it costs and what it buys.

---

## Definitions

> "Data is immutable."
>
> — Yehonathan Sharvit, Principle #3 of Data-Oriented Programming [3]

It says one structural thing: **once a value exists, no one may change it, not even the code that created it.**

A type is immutable when all of the following are true. This is essentially Bloch's recipe from *Effective Java* [6]:

- **Records or final classes.** The type cannot be extended into a mutable subtype.
- **No public fields.** Fields cannot be reached and reassigned from outside.
- **No setters.** No method reassigns a field after construction.
- **Immutable fields, all the way down.** Every field is itself a value: no `List`, no Java `Date`, no `Address` with a setter pretending to be a value.
- **No state-changing methods.** No method changes the object's internal state, even one that returns `void`.
- **Final / readonly fields.** Declare every field `final` (Java) or `readonly` (C#), so the compiler refuses any reassignment after construction. No setters keeps the public surface clean; `final` fields keep future maintainers honest.

This axiom departs from a common default: a "data class" whose `final` keyword guards only the outer wrapper, while mutability leaks through public fields, setters, mutable collections or a method called `increment()`.

The discipline is about the type's contract, not its bytes. Reflection, `Unsafe` and JNI can break any of the rules above. That doesn't make the type mutable; it only means the language allows trespassing [1]. The contract holds for code that doesn't cheat.

A record built this way is a [*product type*](https://en.wikipedia.org/wiki/Product_type): its value is all of its fields at once.

---

## Recognizing immutability

The five short quizzes below apply the checklist. Each one shows a small C# type next to its Java counterpart. Decide whether the pair is immutable before reading the answer.

### Is this immutable? (1/5): extension and setters

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

❌ Not immutable. The class can be extended: a subclass can add a setter, or override the getter to return mutable state.

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

✅ Immutable. `sealed` / `final` blocks extension, there is no setter, the field is read-only, and `string` is itself a value.

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

❌ Not immutable. The setter reassigns `name` after construction.

### Is this immutable? (2/5): depth

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

❌ Not immutable. The public field can be reassigned from outside the class.

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

❌ Not immutable. `List` itself is mutable, so any caller can change the contents of the returned list.

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

❌ Not immutable. `Address` has a setter, so the value inside `Person` can change underneath it.

### Is this immutable? (3/5): methods, reflection and value types

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

❌ Not immutable. `Increment` / `increment()` changes the field after construction.

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
    private final String name;
    Person(String name) {
        this.name = name;
    }
}
```

</td>
</tr>
</table>

✅ Immutable. The type's contract still holds. Reflection is a language escape hatch, not a counterexample.

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
    private final LocalDate birthdate;
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

✅ Immutable. `DateOnly` / `LocalDate` is itself a value, so the field cannot change underneath.

### Is this immutable? (4/5): records

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
sealed record Person(DateOnly Birthdate);
```

</td>
<td>

```java
record Person(LocalDate birthdate) {}
```

</td>
</tr>
</table>

✅ Immutable. `record` makes the wrapper a value, and `DateOnly` / `LocalDate` is itself a value. Java records are always final. C# records can be inherited, so they need `sealed` to meet the first rule of the checklist.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
sealed record Person(List<string> Friends);
```

</td>
<td>

```java
record Person(List<String> friends) {}
```

</td>
</tr>
</table>

❌ Not immutable. `record` only protects the wrapper; the `List` inside can still be changed.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
var person = new Person("Alice");
var nameProperty = typeof(Person).GetProperty("Name");
nameProperty!.SetValue(person, "Bob");

sealed record Person(string Name);
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

✅ Immutable. The record's contract still holds; reflection is the same trespass as before. In Java the attempt actually fails: record fields cannot be changed through reflection, so `set` throws `IllegalAccessException`. In C# it succeeds.

### Is this immutable? (5/5): defense in depth

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

❌ Not immutable. The class is `sealed` / `final` and has no setter, but `Rename` / `rename` reassigns the field from inside. Nothing at the class level forbids it.

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

✅ Immutable. `readonly` / `final` on the field means the compiler refuses any reassignment after construction. A future maintainer who tries to add `Rename` / `rename` gets a compile error.

---

## Problem / forces

In ordinary line-of-business code, engineers keep doing the same things with their data: hand it to other functions, store and load it, serialize and send it, look at it long after the moment that produced it, and reuse the same shapes across modules.

The usual tool, a class with private mutable fields and getters and setters, works against most of those forces:

- Two parts of the program holding "the same object" drift apart silently, because any holder can change it without telling the others.
- Every getter that returns an internal collection or sub-object has to clone it, or callers can reach in and change it. Every method that accepts one has to clone it on the way in.
- The value a field held two seconds ago only exists in the logs you remembered to write. There is no clean way to ask "what was this at 14:03?"

One force pulls the other way: **ergonomics**. Updating in place reads naturally ("the counter increments"), and much of the tooling (ORMs, serializers, UI frameworks) was designed around setters. This axiom does not deny that force; it moves it. Mutation belongs at the edges of the program, where [Axiom 1](axiom-01-data-is-not-behavior.md) already left room for mutable resources, not in the data itself.

---

## Why

**1. A value is a fact, and facts do not change.**
Data represents facts about the world, and facts do not change after they happen. The order *was* placed at 14:03. The customer's birthday *is* 1987-04-12. Overwriting a memory cell with new information does not change the old fact; it only loses your reference to it. This is Hickey's critique of place-oriented programming [2], and it is what Axiom 1 was already pointing at when it called data a *value*. This axiom enforces that claim.

**2. No action at a distance.**
One of the most expensive kinds of bug in OO code is one piece of code changing an object that another piece is still using. Immutability removes that whole kind:

- If a function hands you a value, nothing it does later can change what you hold.
- If you hand a value to a function, nothing it does can change what you still hold.

Every reference is, in effect, a defensive copy you didn't have to write.

**3. Concurrency without coordination.**
Locks exist because state is both *shared* and *mutable*. Remove the mutability and the lock is no longer needed. Any number of threads can read a value, in any order, with no synchronization, and no thread ever sees an inconsistent view. It is one of the cheapest concurrency wins available, and a large part of what makes distributed systems manageable [2].

**4. Easier to reason about and to test.**
When the inputs cannot change, a test only has to set them up and check the result. There is no state to reset between cases and nothing can change the inputs halfway through. The same property lets you read a call site once and trust it. As a small bonus, short-lived values are cheap for the garbage collector to reclaim.

---

## Trade-offs

Immutable types cost you:

- **Ergonomics on update.** Changing a field means producing a new value. C# has `person with { Name = "x" }`. In Java you write `withName(...)` methods or a builder, extra code that sits where a setter used to be. Both are more verbose than `person.Name = "x"`.
- **Tooling friction.** ORMs (Hibernate, EF) and some serializers were designed for mutable entities and need adapting.
- **Some allocation pressure.** You cannot change things in place. Modern garbage collectors absorb most of this, but in tight loops it matters [5].

These costs buy what *Why* lists above. For line-of-business code the trade is almost always worth it. For inner loops it sometimes isn't (see *When NOT to*).

### "But isn't all this copying slow?"

This is the worry behind the allocation cost, and it deserves a straight answer. For a small record, a "copy" is a handful of field assignments: cheap, not worth a second thought. The worry only matters for *collections*: surely adding one item to a 10,000-element list can't mean copying all 10,000 every time?

It doesn't, if you use a **persistent collection**. These are immutable collections built as trees. An updated "copy" shares every unchanged node with the original and rebuilds only the path to the node that changed: O(log n) new nodes, not O(n). The old version stays valid and untouched, and the new one is cheap. This reuse of nodes is called **structural sharing**, and it is what makes immutability practical for large collections.

The rule: **don't build this yourself.** Use a well-tested library [7]:

- **C#:** `System.Collections.Immutable` (`ImmutableList`, `ImmutableDictionary`, …), part of .NET.
- **Java:** Vavr. Java's built-in `List.of` and `List.copyOf` are immutable too, but they copy everything on each change; they don't share structure.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
var a = ImmutableList.Create(1, 2, 3);
var b = a.Add(4);   // a is still [1, 2, 3]; b reuses a's nodes
```

</td>
<td>

```java
var a = Vector.of(1, 2, 3);
var b = a.append(4); // a is still [1, 2, 3]; b reuses a's nodes
```

</td>
</tr>
</table>

How these are built (finger trees, amortized versus worst-case bounds) is Okasaki's subject [4]. You *use* the library; you don't implement it. That reference is the deep answer; this section is the everyday one.

---

## When NOT to

Mutable state earns its place in two cases:

- **Inner loops where allocation dominates.** In a tight hot path (a parser tokenizing megabytes per second, a renderer building a frame, a physics step over millions of bodies), copying loses to in-place update on the only axis that matters. This is the Mike Acton territory that Axiom 1 already marked as out of scope for this book [5]: a *performance* argument, not a *complexity* one.
- **Boundary objects you don't own.** ORM entities, framework callbacks and generated DTOs sometimes come with setters you cannot remove. Convert them into immutable records at the boundary, work with immutable types in the core, and convert back on the way out. The edges may be mutable; the core is not.

---

## References

[1] **JLS / `java.lang.reflect`** and **`sun.misc.Unsafe`** are the canonical Java escape hatches; **`System.Reflection`** with `BindingFlags.NonPublic | BindingFlags.Instance` (and `FieldInfo.SetValue`) is the equivalent in .NET. Their existence means no JVM- or CLR-level guarantee of immutability is possible; the contract is enforced at the source level only.

[2] **Rich Hickey**, *The Value of Values*, keynote at JaxConf 2012 (also delivered at GOTO Copenhagen 2012). Recording on InfoQ, published 14 August 2012: <https://www.infoq.com/presentations/Value-Values/>. The argument that values (immutable, location-independent) are what make concurrency and distribution manageable. Already cited in [Axiom 1](axiom-01-data-is-not-behavior.md) as reference [4]; listed again here because the argument matters just as much for Axiom 2.

[3] **Yehonathan Sharvit**, *Data-Oriented Programming: Reduce software complexity*, Manning Publications, 2022. Principle #3 ("Data is immutable"). <https://www.manning.com/books/data-oriented-programming>

[4] **Chris Okasaki**, *Purely Functional Data Structures*, Cambridge University Press, 1998. The standard reference on how to build immutable data structures (lists, queues, heaps, finger trees) with asymptotic costs comparable to their mutable counterparts. The answer to "but isn't copy-on-write slow?" for everything outside the absolute hottest loops.

[5] **Mike Acton**, *Data-Oriented Design and C++*, keynote at CppCon 2014: <https://www.youtube.com/watch?v=rX0ItVEVjHc>. Already cited in [Axiom 1](axiom-01-data-is-not-behavior.md) as reference [6]; relevant here as the dominant counter-argument inside performance-critical inner loops.

[6] **Joshua Bloch**, *Effective Java*, 3rd ed., Addison-Wesley, 2018, Item 17, "Minimize mutability". The canonical Java-specific statement of the rules listed in this axiom's *Definitions* section, with the same five-point recipe (no mutators, ensure the class cannot be extended, make all fields final, make all fields private, ensure exclusive access to any mutable components).

[7] **`System.Collections.Immutable`** (.NET) and **Vavr** (Java) are the mainstream persistent-collection libraries: immutable lists, maps, sets, and vectors with structural sharing built in, so you never hand-roll the trees in reference [4]. .NET: <https://learn.microsoft.com/en-us/dotnet/api/system.collections.immutable>. Vavr: <https://vavr.io>.

---

← Previous: [Axiom 1 — Data is not Behavior](axiom-01-data-is-not-behavior.md) · Next: [Axiom 3 — Side effects](axiom-03-side-effects.md) →
