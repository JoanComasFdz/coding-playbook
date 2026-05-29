# Axiom 9 — Pattern matching

**Pattern matching is a single expression that selects a branch by inspecting the shape of a value, narrows the value's type inside the chosen branch, and binds the parts of the value the branch needs.**

- Each branch is a *pair*: a shape on the left, an expression on the right. The shape selects the branch; the binding makes the value's parts available without a separate cast.
- When the set of possible shapes is *closed* — a sealed type hierarchy, an enum, a finite set of literals — the compiler can verify at compile time that every shape has a branch.
- Two surfaces for the same operation: a `switch` expression in the consumer, or a `Match` method on the type — same lesson, same totality, different owner.

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

Case analysis is *whose* job. The consumer's, when written as `switch` at the call site; the type's, when exposed as a `Match` method on the value itself. The arms, the totality property, and the exhaustiveness guarantee are unchanged across the two surfaces — only the *location* of the case list moves.

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

## The method form

The same case analysis takes a second surface: a method on the type itself, taking one handler per shape and returning whatever the handlers return. The lesson and the totality property are the same — the change is *who owns the dispatch*.

The method on `Shape`, declared once next to the type:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public abstract record Shape
{
    public R Match<R>(
        Func<Circle, R>    circle,
        Func<Rectangle, R> rectangle,
        Func<Square, R>    square) => this switch
    {
        Circle c    => circle(c),
        Rectangle r => rectangle(r),
        Square q    => square(q),
        _           => throw new InvalidOperationException()
    };
}
```

</td>
<td>

```java
sealed interface Shape permits Circle, Rectangle, Square {
    default <R> R match(
            Function<Circle, R>    circle,
            Function<Rectangle, R> rectangle,
            Function<Square, R>    square) {
        return switch (this) {
            case Circle c    -> circle.apply(c);
            case Rectangle r -> rectangle.apply(r);
            case Square q    -> square.apply(q);
        };
    }
}
```

</td>
</tr>
</table>

The body is the same `switch` from the previous section — `Match` does not introduce new machinery, it wraps the existing one as a method on the type. The Java form is exhaustive at compile time, so it needs no fallthrough. The C# form needs a `throw` in the unreachable position because the C# 14 compiler cannot yet *prove* the sealed hierarchy closed: CS8509 emits a warning, not a hard error.

The same `Area` function, written first as a `switch` expression and then as a `Match` call:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// switch — case analysis at the call site
public static double Area(Shape shape) => shape switch
{
    Circle c    => Math.PI * c.Radius * c.Radius,
    Rectangle r => r.L * r.W,
    Square s    => s.Side * s.Side
};

// Match — case analysis on the type
public static double Area(Shape shape) => shape.Match(
    circle:    c => Math.PI * c.Radius * c.Radius,
    rectangle: r => r.L * r.W,
    square:    s => s.Side * s.Side);
```

</td>
<td>

```java
// switch — case analysis at the call site
public static double area(Shape shape) {
    return switch (shape) {
        case Circle c    -> Math.PI * c.radius() * c.radius();
        case Rectangle r -> r.length() * r.width();
        case Square s    -> s.side() * s.side();
    };
}

// match — case analysis on the type
public static double area(Shape shape) {
    return shape.match(
        c -> Math.PI * c.radius() * c.radius(),
        r -> r.length() * r.width(),
        s -> s.side() * s.side());
}
```

</td>
</tr>
</table>

The two arms read at the same length. The difference is *where the case name lives*. In the `switch` form the case is named on the left of `=>` as a type pattern (`Circle c =>`); the consumer spells the type on every arm. In the `Match` form the case is named on the left of `=>` as a *parameter label* (`circle: c =>`); the consumer passes a lambda whose parameter type is *inferred* from the method's signature.

**Case analysis can live where the consumer is, or where the type is.** A `switch` expression carries the case list at the call site: every consumer of `Shape` writes its own arms with `Circle c => …`, `Rectangle r => …`, `Square s => …`. A `Match` method moves that list onto the type: the type declares the handler shape once, and every consumer fills in the bodies. The lesson — case analysis on shape, exhaustive over the closed set — is the same. The *location* of the case list is the choice.

The ergonomic consequence is real. **Each `switch` arm spells out the case type at the call site.** With `Shape`, that's `Circle c =>` — short and clear. With a type whose generic arguments are themselves compound — a sum type parameterised by a tuple of named types, a record-of-records, a sealed hierarchy with multiple type parameters — every arm at every call site repeats the full type. The consumer carries the transcription burden every time the type is consumed, and the burden scales with how often that is. The `Match` method removes the type from the call site entirely: the case is named by parameter, and the consumer passes a lambda whose parameter type is inferred.

Two costs return the other way. **The method's signature grows with the variant count**: a `Match` over a 7-arm hierarchy declares seven `Func` parameters in one place, and the call site reads as a labelled table while the *declaration* reads as a wall of generics. And **each arm is a lambda allocation** where the consumer would otherwise inline the arm body in `switch`. For most line-of-business code both costs are dust. For hot paths or large variant sets, consumer-owned `switch` is the right reach.

The choice between the two surfaces is local: pick the one that reads better at the call sites you have. Both are pattern matching.

---

## Convention: match on a named value, never on an inline call

Pattern matching — whether `switch` expression, `switch` statement, or `Match` method — always reads against a *named variable*, never against a call expression. Wherever the temptation is to write `switch (Compute(...)) { ... }`, split it into two statements:

<table>
<tr><th>Don't</th><th>Do</th></tr>
<tr>
<td>

```csharp
switch (Decide(state, command))
{
    case Approved a => Persist(a),
    case Denied   d => Log(d)
}
```

</td>
<td>

```csharp
var decision = Decide(state, command);   // pure
switch (decision)                         // impure dispatch
{
    case Approved a => Persist(a),
    case Denied   d => Log(d)
}
```

</td>
</tr>
</table>

Same for the `Match` method form: `var result = x.Compute(...); result.Match(...)`, not `x.Compute(...).Match(...)`.

The reason is **visual separation between pure and impure**. The pure call lives on one line; the impure dispatch lives on the next. A reviewer scanning vertically sees the two halves of the [Impureim sandwich](axiom-10-impureheim.md) at a glance — *compute*, then *act* — without parsing an expression. Inlining the call collapses the two halves into one expression and hides the boundary the playbook spends so much effort marking.

Three downstream benefits follow from that visual cue:

1. **The intermediate value gets a name.** A reviewer reading the dispatch knows what is being dispatched on by reading one identifier, not by mentally evaluating an expression.
2. **A debugger can break between the two statements** and inspect the result before the dispatch fires — a real ergonomic win when the pure call is non-trivial.
3. **The convention reads the same in every example.** `var x = Pure(...); switch (x) { ... }` becomes a shape the eye recognises without having to parse — same visual rhythm everywhere the playbook does case analysis.

This applies to `switch` expressions, `switch` statements, and `Match` calls equally. A property access (`x.Status`) is fine to inline — the rule is about non-trivial *calls*, not about all member access.

---

## Problem / forces

Case analysis on a value's shape is a fundamental operation: every program that decides what to do based on which kind of thing it holds is doing case analysis in some form. The question is only what syntax expresses the decision. Several options sit on the same trade-off curve, each appropriate in its own setting:

- **A virtual method on the type.** When the behaviour belongs *to* the data — `Area`, `Perimeter`, `ToString` — each shape owns its own definition and dispatch is implicit. The case analysis lives inside the type system. The right choice whenever the operation's meaning is part of what the type *is*.
- **The Visitor pattern.** A type-safe way to express case analysis in an OO language without native pattern matching: each new operation is a visitor with one method per shape, double-dispatched through `accept`. The cases *are* checked by the compiler. Where pattern matching is available, the same idea fits in one expression instead of a hierarchy of classes.
- **`instanceof` / `is` ladders with manual downcasts.** Lightweight and immediate, with no extra types involved. The type test and the cast are separate statements; nothing the compiler can verify about completeness. A reasonable fit for a throwaway decision; awkward as soon as a new shape is added.
- **`switch` on a tag string or enum, followed by a downcast inside each arm.** Common in event-stream code where the tag is the dispatch key. The narrowing has to be written by hand because the language can't carry it across the branch.
- **Pattern matching.** Selects on shape *and* narrows *and* binds parts, in one arm; the compiler verifies exhaustiveness over a closed set of cases.

Where the operation belongs to the consumer (not to the data) and the set of cases is closed, pattern matching is the most direct of the five. The other four remain the right fit when their conditions hold — and the trade-offs section names where pattern matching itself gives way.

Both surfaces of pattern matching shown earlier — `switch` and `Match` — share this position on the curve. The choice between them is a local readability decision (verbose case types at the call site versus a method signature growing with the variant count), not a new option among the five.

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

**5. The dispatch can also live on the type, when that reads better.**
A `Match` method moves the case list from the call site onto the type's surface. The case analysis is the same and the totality requirement is the same — only the *location* of the case list moves. Consumer-owned dispatch (the `switch` form, the previous bullet) lets every call site shape its own match with guards, nested patterns, or partial matches falling through to a default. Type-owned dispatch (the `Match` form) gives every consumer a single uniform call shape and lifts the case-type transcription off every arm. Pattern matching keeps both options on the table; the chapter does not pick one for you.

---

## Trade-offs

The first cost is **scattering branches across consumers**. A virtual method keeps the per-case implementation next to the case definition. A pattern match concentrates the cases together, but at the cost of putting them in the consumer instead of next to the type. The right choice is the one that matches where the behaviour belongs. Operations whose meaning is intrinsic to the type — geometric `Area`, `Equals`, `ToString` — belong as methods; operations whose meaning belongs to a consumer (this report, this command, this validation) belong as a pattern match.

The second cost is **the temptation to grow the match indefinitely**. A match expression that runs forty arms is, usually, a signal that the data should be redesigned — perhaps the cases should be grouped, perhaps the consumer is trying to make too many decisions in one place. The match is doing its job by making the size of the decision visible.

The third cost is that **the compile-time guarantee depends on closure**. Sealed types and exhaustive matches require the set of cases to live in one place. A pattern match on a non-sealed type still compiles, but the compiler can no longer ensure every case is covered; a `default` arm becomes load-bearing. This is acceptable for `Object`-typed dispatch or for inherited hierarchies the codebase does not own, but it loses the strongest reason to use pattern matching in the first place. Where the cases are under the codebase's control, seal them.

The fourth cost is **a local choice the chapter does not make for you: `switch` versus `Match`**. The two surfaces carry different costs at different scales. A `switch` expression spells the case type on every arm — short and clear with names like `Circle`, onerous when the type is generic and every arm repeats the same compound. A `Match` method moves that cost off the consumer onto the declaration: a 7-arm `Match` has seven `Func` parameters in its signature, plus one lambda allocation per call. For most line-of-business code both costs are dust. Pick the surface that reads better at the call sites you have, and accept that the answer can be different for different types in the same codebase.

---

## When NOT to

Two cases where another option on the trade-off curve fits better:

- **The behaviour is intrinsic to the type.** `Shape.Area()`, `Money.Plus(other)`, `Document.IsValid()` — operations whose meaning is part of what the type *is*. A virtual method (or in C# / modern Java, a method on each record / sealed implementor) keeps that operation next to its data. A pattern match in a consumer would force every caller to know how each shape computes its area; the abstraction is the point.
- **The set of cases is open by design.** Plugin hosts, extension points, codebases where the set of subtypes is expected to grow outside the module. Pattern matching's compile-time guarantee depends on the compiler seeing the full set of cases. For an open set, the polymorphic dispatch a virtual method provides is the right shape.
- **The type's variant list is unstable, or its consumer count is small.** A `Match` method couples every consumer to the variant signature: a variant added, removed, or renamed is a method-signature change visible to every call site. While the variant list is in flux — or while only one or two consumers exist — `switch` at the call site is cheaper to live with. Promote to `Match` once the variant list has stabilised and consumer count makes the per-arm transcription tax visible.

---

## References

[1] **Philip Wadler**, *Views: A Way for Pattern Matching to Cohabit with Data Abstraction*, POPL 1987. The foundational paper showing that pattern matching can coexist with information hiding — the matched value's internal representation can stay private while the match still reads its meaningful shape. Modern record and deconstruction patterns in C# and Java are direct descendants of this idea.

[2] **Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides**, *Design Patterns: Elements of Reusable Object-Oriented Software*, Addison-Wesley, 1994. Cross-listed from [Axiom 7](axiom-07-first-class-functions.md) and [Axiom 8](axiom-08-higher-order-functions.md); the *Visitor* chapter remains the canonical reference for case analysis over a closed type hierarchy in an OO language without native pattern matching.

[3] **OpenJDK**, *JEP 441: Pattern Matching for switch*, finalised in Java 21 (2023). The canonical reference for Java's pattern-matching syntax, exhaustiveness rules, and interaction with sealed types.
<https://openjdk.org/jeps/441>

[4] **Scott Wlaschin**, *Designing with Types* series, fsharpforfunandprofit.com. F#'s `Option.fold`, `Result.fold`, and the per-DU `match` keyword are the canonical functional treatment of "case analysis owned by the type" — the lineage of the `Match` method form. The C# / Java shape used in this axiom is the direct translation of that idiom into languages where pattern matching is a built-in language construct rather than a per-type member.
<https://fsharpforfunandprofit.com/series/designing-with-types/>
