# Axiom 8 — Pattern matching

**Pattern matching is a single expression that selects a branch by inspecting the shape of a value, narrows the value's type inside the chosen branch, and binds the parts of the value the branch needs.**

- Each branch is a *pair*: a shape on the left, an expression on the right. The shape selects the branch; the binding makes the value's parts available without a separate cast.
- When the set of possible shapes is *closed* — a sealed type hierarchy, an enum, a finite set of literals — the compiler can verify at compile time that every shape has a branch.

[Axiom 0](axiom-00-data-vs-behaviour.md) drew the line: data is a passive description of what something is; behaviour is a separate operation defined over it. When the data can take one of several shapes, the natural way to define a behaviour over it is *case analysis* — one clause per shape, each clause naming the result for that shape. Pattern matching is the syntax for that clausal definition: the shape on the left, the result on the right, the value's parts bound in the same step.

---

## Definitions

A pattern match is an expression evaluated against a value. Each branch, called *arm* (or *case*) consists of a **pattern** — the shape the value must have for that arm to fire — and a **body** — the expression to evaluate when the pattern matches. The first arm whose pattern matches wins; its body is the result of the whole expression.

The patterns come in several kinds, all available in modern C# and Java:

- **Type patterns.** `case Circle c` — selects on the runtime type of the value and binds it to a name typed by that case. The cast is part of the match; the body operates on the narrowed type.
- **Record / deconstruction patterns.** `Point(var x, var y)` — selects on shape *and* pulls the components out by position or by name. Inside the body, `x` and `y` are local values of their declared types.
- **Constant / literal patterns.** `0`, `"OPEN"`, `EventType.Deleted` — selects on equality with a known value. The natural fit for tag dispatch.
- **Guarded patterns.** `case Square s when s.Side > 5` — refines a structural match with a runtime predicate. Shape *and* condition in one arm.

A match expression is *exhaustive* when its arms cover every value the input type can hold. For a sealed hierarchy or an enum, that is a property the compiler can check; a match missing a case is a compile error in modern Java and in C# `switch` expressions.

---

## Example

A function that takes an `Object` and dispatches by runtime type. The pre-pattern formulation lays out the cast as a separate step; the pattern version makes the cast part of the match.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public static string Describe(object obj) =>
    obj switch
    {
        string s => $"text({s.ToUpperInvariant()})",
        int i    => $"twice({i * 2})",
        double d => $"half({d / 2})",
        _        => $"unknown({obj})"
    };
```

</td>
<td>

```java
public static String describe(Object obj) {
    return switch (obj) {
        case String s  -> "text(" + s.toUpperCase(Locale.ROOT) + ")";
        case Integer i -> "twice(" + (i * 2) + ")";
        case Double d  -> "half(" + (d / 2) + ")";
        default        -> "unknown(" + obj + ")";
    };
}
```

</td>
</tr>
</table>

Each arm names the type and binds the narrowed value in the same place where its work happens. The arms read as a table — "if it's *this*, do *that*" — without a separate cast step or an intermediate variable to hold the narrowed value.

A second case: a *closed* hierarchy. The compiler sees the full set of shapes and refuses to compile a match that forgets one. Guards let one structural case split into several arms by predicate.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public abstract record Shape;
public sealed record Circle(double Radius)         : Shape;
public sealed record Rectangle(double L, double W) : Shape;
public sealed record Square(double Side)           : Shape;

public static string Classify(Shape shape) =>
    shape switch
    {
        Square s when s.Side > 5     => "too big",
        Square                        => "fits",
        Rectangle r when r.L > 3     => "too large",
        Rectangle                     => "fits",
        Circle                        => "not supported"
    };
```

</td>
<td>

```java
sealed interface Shape permits Circle, Rectangle, Square {}
record Circle(double radius) implements Shape {}
record Rectangle(double length, double width) implements Shape {}
record Square(double side) implements Shape {}

public static String classify(Shape shape) {
    return switch (shape) {
        case Square s when s.side() > 5      -> "too big";
        case Square s                         -> "fits";
        case Rectangle r when r.length() > 3 -> "too large";
        case Rectangle r                      -> "fits";
        case Circle c                         -> "not supported";
    };
}
```

</td>
</tr>
</table>

Both forms are *exhaustive*: there is no `default` arm, and the compiler verifies that `Circle`, `Rectangle`, and `Square` are the only shapes a `Shape` can be. Add a fourth — `Triangle` — and the compiler points at every match that does not yet handle it.

---

## Problem / forces

Case analysis on a value's shape is a fundamental operation: every program that decides what to do based on which kind of thing it holds is doing case analysis in some form. The question is only what syntax expresses the decision. Several options sit on the same trade-off curve, each appropriate in its own setting:

- **A virtual method on the type.** When the behaviour belongs *to* the data — `Area`, `Perimeter`, `ToString` — each shape owns its own definition and dispatch is implicit. The case analysis lives inside the type system. The right choice whenever the operation's meaning is part of what the type *is*.
- **The Visitor pattern.** A type-safe way to express case analysis in an OO language without native pattern matching: each new operation is a visitor with one method per shape, double-dispatched through `accept`. The cases *are* checked by the compiler. Where pattern matching is available, the same idea fits in one expression instead of a hierarchy of classes.
- **`instanceof` / `is` ladders with manual downcasts.** Lightweight and immediate, with no extra types involved. The type test and the cast are separate statements; nothing the compiler can verify about completeness. A reasonable fit for a throwaway decision; awkward as soon as a new shape is added.
- **`switch` on a tag string or enum, followed by a downcast inside each arm.** Common in event-stream code where the tag is the dispatch key. The narrowing has to be written by hand because the language can't carry it across the branch.
- **Pattern matching.** Selects on shape *and* narrows *and* binds parts, in one arm; the compiler verifies exhaustiveness over a closed set of cases.

Where the operation belongs to the consumer (not to the data) and the set of cases is closed, pattern matching is the most direct of the five. The other four remain the right fit when their conditions hold — and the trade-offs section names where pattern matching itself gives way.

---

## Why

**1. Shape, binding, and action sit on the same arm.**
Each arm is a (pattern, expression) pair: the shape on the left, the work on the right, the value's parts bound in the same step. Inside an arm typed `Circle c`, the value already *is* a `Circle` with a `radius`; the body refers to the parts directly, without a cast or an intermediate local. The arm contains exactly the work for that case, and nothing else has to exist for it to happen.

**2. The `if`-ladder collapses into one cohesive expression.**
The pre-pattern formulation of the same decision is a sequence of `if (x instanceof T) { var t = (T) x; ... } else if (...) { ... } else { ... }` blocks — each block carrying its own braces, type test, cast, and narrowed local. The match form removes that scaffolding: one `switch`, one closing brace, and between them the cases themselves, one per line. The same decision occupies a fraction of the vertical space; the ratio of language syntax to decision content shifts from roughly half-and-half to mostly content. The cases also sit *together* as a group, where an `if`-ladder leaves them as separate top-level blocks the reader has to mentally re-assemble into "the set of cases this code handles."

**3. Exhaustiveness becomes a compile-time property.**
For a closed type — a sealed interface in Java, an abstract record hierarchy in C# — the compiler knows the full set of shapes. A match that omits a case is a compile error, not a runtime surprise. Adding a new shape to the hierarchy forces every match that consumes it to acknowledge the new case; missed call sites become a list of compile errors, not a list of bugs.

**4. The dispatch lives where the decision lives.**
The consumer that needs to branch on a shape contains the branching logic; the data type stays a passive description of *what it is*. A second consumer with a different question writes its own match; the data type is touched by neither. This is the practical payoff of [Axiom 0](axiom-00-data-vs-behaviour.md) — data is data, and the operations over it live with the consumers that need them.

---

## Trade-offs

The first cost is **scattering branches across consumers**. A virtual method keeps the per-case implementation next to the case definition. A pattern match concentrates the cases together, but at the cost of putting them in the consumer instead of next to the type. The right choice is the one that matches where the behaviour belongs. Operations whose meaning is intrinsic to the type — geometric `Area`, `Equals`, `ToString` — belong as methods; operations whose meaning belongs to a consumer (this report, this command, this validation) belong as a pattern match.

The second cost is **the temptation to grow the match indefinitely**. A match expression that runs forty arms is, usually, a signal that the data should be redesigned — perhaps the cases should be grouped, perhaps the consumer is trying to make too many decisions in one place. The match is doing its job by making the size of the decision visible.

The third cost is that **the compile-time guarantee depends on closure**. Sealed types and exhaustive matches require the set of cases to live in one place. A pattern match on a non-sealed type still compiles, but the compiler can no longer ensure every case is covered; a `default` arm becomes load-bearing. This is acceptable for `Object`-typed dispatch or for inherited hierarchies the codebase does not own, but it loses the strongest reason to use pattern matching in the first place. Where the cases are under the codebase's control, seal them.

---

## When NOT to

Two cases where another option on the trade-off curve fits better:

- **The behaviour is intrinsic to the type.** `Shape.Area()`, `Money.Plus(other)`, `Document.IsValid()` — operations whose meaning is part of what the type *is*. A virtual method (or in C# / modern Java, a method on each record / sealed implementor) keeps that operation next to its data. A pattern match in a consumer would force every caller to know how each shape computes its area; the abstraction is the point.
- **The set of cases is open by design.** Plugin hosts, extension points, codebases where the set of subtypes is expected to grow outside the module. Pattern matching's compile-time guarantee depends on the compiler seeing the full set of cases. For an open set, the polymorphic dispatch a virtual method provides is the right shape.

---

## References

[1] **Philip Wadler**, *Views: A Way for Pattern Matching to Cohabit with Data Abstraction*, POPL 1987. The foundational paper showing that pattern matching can coexist with information hiding — the matched value's internal representation can stay private while the match still reads its meaningful shape. Modern record and deconstruction patterns in C# and Java are direct descendants of this idea.

[2] **Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides**, *Design Patterns: Elements of Reusable Object-Oriented Software*, Addison-Wesley, 1994. Cross-listed from [Axiom 6](axiom-06-first-class-functions.md) and [Axiom 7](axiom-07-higher-order-functions.md); the *Visitor* chapter remains the canonical reference for case analysis over a closed type hierarchy in an OO language without native pattern matching.

[3] **OpenJDK**, *JEP 441: Pattern Matching for switch*, finalised in Java 21 (2023). The canonical reference for Java's pattern-matching syntax, exhaustiveness rules, and interaction with sealed types.
<https://openjdk.org/jeps/441>
