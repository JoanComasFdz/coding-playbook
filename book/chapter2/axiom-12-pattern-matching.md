# Axiom 12 — Pattern matching

**[Pattern matching](https://en.wikipedia.org/wiki/Pattern_matching) lets one `switch` check what kind of value it has, cast it for you, and take it apart, all in one step.**

- When the possible kinds are a *closed* set (a sealed hierarchy, an enum), the compiler can check that the `switch` handles every one of them.

[Axiom 2](axiom-02-data-is-not-behavior.md) separates data from behavior. When data comes in several shapes, a behavior over it needs one branch per shape, and pattern matching is how you write those branches.

Through [Axiom 9](axiom-09-connascence.md)'s lens, an exhaustive match turns "did every consumer remember every case?" into a [Connascence of Type](axiom-09-connascence.md#connascence-of-type-cot) that the build checks (see *Why*, point 3).

---

## Definitions

A pattern match is an expression evaluated against a value. Each branch has a **pattern**, the shape the value must have for that branch to run, and a **body**, the expression to evaluate when it does. The first branch whose pattern matches wins; its body is the result of the whole expression.

Modern C# and Java support several kinds of pattern:

- **Type patterns.** `case Circle c` picks on the runtime type and binds the value to a name of that type. The cast is part of the match.
- **Record (deconstruction) patterns.** `Point(var x, var y)` picks on shape *and* pulls the components out. Inside the body, `x` and `y` are local values of their declared types. (Letting a type choose which shape it shows to patterns, while hiding its internals, is an idea Wadler explored as *views* [1].)
- **Constant patterns.** `0`, `"OPEN"`, `EventType.Deleted` pick on equality with a known value.
- **Guarded patterns.** `case Square s when s.Side > 5` adds a runtime condition to a structural match: shape *and* condition in one branch.

A match is *exhaustive* when its branches cover every value the input type can hold. How much the compiler helps differs:

- **Java** checks exhaustiveness over sealed interfaces and enums. A `switch` that misses a case doesn't compile [3].
- **C#** warns (CS8509) when a `switch` expression isn't exhaustive, and you can turn that warning into an error. But C# can't yet prove that a class hierarchy is closed, so a `switch` over an abstract record base needs a discard branch (`_ => throw ...`), and a newly added subtype isn't flagged. It compiles, and throws at runtime. *The method form* below gives C# the check back.

---

## Example

A function that takes an `Object` and branches on its runtime type. Without patterns, the type test and the cast are separate steps; with them, the cast is part of the match.

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

Each branch names the type and binds the narrowed value right where its work happens. The branches read as a table, "if it's *this*, do *that*", with no separate cast or extra variable.

A second example: a *closed* hierarchy. Guards let one shape split into several branches by condition.

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
        Circle                        => "not supported",
        _ => throw new UnreachableException() // ❌ C# can't prove Shape is closed
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

The Java version has no `default` branch, and adding a `Triangle` later points you at every `switch` that must handle it. The C# version needs the discard branch (see *Definitions*): add a `Triangle` and it still compiles, then throws when one arrives.

---

## The method form

The same case analysis can live on the type instead: a `Match` method that takes one function per shape and returns whatever they return. The case analysis is the same; what changes is *who owns the dispatch*. Functional programmers call this shape a [*catamorphism*](https://en.wikipedia.org/wiki/Catamorphism), or fold: "create a function parameter to handle each case" [4].

The method, declared once next to the type:

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
        _           => throw new UnreachableException()
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

Its body is the same `switch` as before: `Match` wraps it as a method on the type. Java needs no fallback branch. C# still does, for the reason in *Definitions*, but now it is written once, inside the type, and no caller sees it. Add a `Triangle` and `Match` gets a fourth parameter, so every call site stops compiling until it handles the new case. In C#, that is how a closed type gets the check Java's `switch` gives for free.

The same `CalculateArea` function, first as a `switch` expression and then as a `Match` call:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// switch — case analysis at the call site (❌ in C#, see below)
public static double CalculateArea(Shape shape) => shape switch
{
    Circle c    => Math.PI * c.Radius * c.Radius,
    Rectangle r => r.L * r.W,
    Square s    => s.Side * s.Side,
    _           => throw new UnreachableException()
};

// Match — case analysis on the type
public static double CalculateArea(Shape shape) => shape.Match(
    circle:    c => Math.PI * c.Radius * c.Radius,
    rectangle: r => r.L * r.W,
    square:    s => s.Side * s.Side);
```

</td>
<td>

```java
// switch — case analysis at the call site
public static double calculateArea(Shape shape) {
    return switch (shape) {
        case Circle c    -> Math.PI * c.radius() * c.radius();
        case Rectangle r -> r.length() * r.width();
        case Square s    -> s.side() * s.side();
    };
}

// match — case analysis on the type
public static double calculateArea(Shape shape) {
    return shape.match(
        c -> Math.PI * c.radius() * c.radius(),
        r -> r.length() * r.width(),
        s -> s.side() * s.side());
}
```

</td>
</tr>
</table>

Both read at about the same length. The difference is *where the case name lives*: in the `switch`, the consumer spells the type on every branch (`Circle c =>`); in the `Match` call, the case is a parameter name (`circle: c =>`) and the lambda's parameter type is inferred.

### When the branches only act: `Handle`

`Match` returns a value, so every branch must produce one. Sometimes no branch has anything to produce: each one only *does* something, like drawing the shape on a canvas. For that, the type gets a second method that takes one action per case and returns nothing:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public abstract record Shape
{
    // Match as above, plus:
    public void Handle(
        Action<Circle>    circle,
        Action<Rectangle> rectangle,
        Action<Square>    square)
    {
        switch (this)
        {
            case Circle c:    circle(c);    break;
            case Rectangle r: rectangle(r); break;
            case Square q:    square(q);    break;
            default: throw new UnreachableException();
        }
    }
}

shape.Handle(
    circle:    c => canvas.DrawCircle(c),
    rectangle: r => canvas.DrawRectangle(r),
    square:    s => canvas.DrawSquare(s));
```

</td>
<td>

```java
sealed interface Shape permits Circle, Rectangle, Square {
    // match as above, plus:
    default void handle(
            Consumer<Circle>    circle,
            Consumer<Rectangle> rectangle,
            Consumer<Square>    square) {
        switch (this) {
            case Circle c    -> circle.accept(c);
            case Rectangle r -> rectangle.accept(r);
            case Square q    -> square.accept(q);
        }
    }
}

shape.handle(
    c -> canvas.drawCircle(c),
    r -> canvas.drawRectangle(r),
    s -> canvas.drawSquare(s));
```

</td>
</tr>
</table>

The rule: **`Match` when every branch produces a value, `Handle` when every branch only acts.** The C# statement noise (`break`, `default`) lives once, inside the method, instead of at every call site.

It is a separate name on purpose, not a `Match` overload: a lambda like `c => list.Add(c)` fits both a function and an action, so C# would pick the function version and Java would refuse to choose.

The pair is not new. C# libraries such as OneOf [5] and ErrorOr [6] offer `Match` for values and `Switch` for actions, and Java's `Optional` has `ifPresentOrElse` for the same job [7]. This book names the void form `Handle`, because `switch` is a reserved word in Java and one name should work in both languages.

### `switch` or `Match`?

- **`switch` puts the case list at the call site.** Every consumer writes its own branches and can use guards, nested patterns, or a default for cases it doesn't care about. The cost: every branch spells out the case type. That's short with `Circle`, but tiresome when the type is generic and every branch repeats a long compound type.
- **`Match` puts the case list on the type.** Every consumer gets one uniform call shape, and no branch spells out a type. The costs:
  - the method's signature grows with the number of variants (seven variants, seven function parameters);
  - each branch is a lambda allocation;
  - every consumer is coupled to the variant list, so adding, removing or renaming a variant changes a method signature every caller sees (in C#, that is the point: see below);
  - each branch is a lambda, so it can't `return` from the calling method or `break` out of its loop, and a guard becomes an `if` or a `?:` inside the branch.

The answer depends on the language:

- **Java: start with `switch`.** The compiler checks a sealed `switch` at every call site, guards and nested patterns included. Move to `match` once the variant list has settled and enough consumers exist that spelling out the case types becomes a visible tax.
- **C#: consume a closed type with `Match` or `Handle`, never with a discard that throws.** A `_ => throw` branch tells the reader nothing and hides a missing case until runtime; `Match` turns it into a build error. A `switch` stays only where it checks or decides something itself:
  - inside the type's own `Match` and `Handle`, the one place the discard lives;
  - over a C# 15 `union`, which the compiler knows is closed, so it needs no discard;
  - over a type that was never closed: `object` (as in `Describe` above), a nullable `T?` (where `null` and the value cover every case), an `enum` (which can hold any integer);
  - where the wildcard is a real branch ("any other event: no change"), not a `throw`.

For most line-of-business code the performance costs don't matter.

---

## Problem / forces

Every program that decides what to do based on which kind of thing it holds is doing case analysis. The only question is which syntax expresses the decision. Several options sit on the same trade-off curve, each right in its own setting:

- **A method on an interface.** Each case implements the interface and dispatch is implicit. Right when the set of cases is open (see *When NOT to*).
- **The [Visitor pattern](https://en.wikipedia.org/wiki/Visitor_pattern)** [2]. A type-safe way to do case analysis in an OO language without pattern matching: one visitor per operation, one method per shape, double dispatch through `accept`. The compiler checks the cases. Where pattern matching exists, the same idea fits in one expression instead of a class hierarchy.
- **`instanceof` / `is` chains with manual casts.** Light and immediate, with no extra types. But the type test and the cast are separate statements, and nothing checks completeness. Fine for a throwaway decision; awkward as soon as a shape is added.
- **A `switch` on a tag string or enum, with a cast inside each branch.** Common in event-handling code where the tag is the dispatch key. The narrowing has to be written by hand, because the language can't carry it into the branch.
- **Pattern matching.** Picks on shape, narrows and binds in one branch, and the compiler can check exhaustiveness over a closed set of cases.

When the operation belongs to the consumer (not the data) and the set of cases is closed, pattern matching is the most direct of the five. The others stay the right fit when their conditions hold.

---

## Why

**1. Shape, binding and action sit in the same branch.**
Inside a branch typed `Circle c`, the value already *is* a `Circle` with a radius. The body uses its parts directly, without a cast or an extra local. The branch contains exactly the work for that case and nothing else.

**2. The match is [concise](https://en.wikipedia.org/wiki/Conciseness): less [boilerplate](https://en.wikipedia.org/wiki/Boilerplate_code), the same decisions.**
An `if` chain (see *Problem / forces*) gives each case its own braces, type test, cast and local. The match removes that scaffolding: one `switch`, and between its braces the cases themselves, one per line. Apply the [decisions-vs-ceremony test](../chapter1/README.md#enforce-decisions-not-ceremony) from [Chapter 1](../chapter1/README.md): remove the type test, the cast and the local, and the reader loses nothing. Every line left is a decision. The cases also sit *together*, where an `if` chain leaves them as separate blocks the reader has to reassemble into "the set of cases this code handles".

**3. Missing cases become build errors, not production bugs.**
For a closed type, the compiler knows every shape (in Java through `switch`; in C# through `Match`, see *The method form*). A match that misses one is flagged at build time, and adding a shape points you at every match that has to handle it.

**4. The dispatch lives where the decision lives.**
The consumer that needs to branch on a shape holds the branching logic; the data type stays a passive description of *what it is*. A second consumer with a different question writes its own match, and neither touches the data type. This is the practical payoff of [Axiom 2](axiom-02-data-is-not-behavior.md): data is data, and the operations over it live with the consumers that need them. (When it reads better, the case list can move onto the type instead: see *The method form*.)

---

## Trade-offs

- **The temptation to grow the match forever.** A match with forty branches usually means the data should be redesigned: maybe the cases should be grouped, or the consumer is making too many decisions in one place. The match is doing its job by making the size of the decision visible.
- **Concise can turn cryptic.** Nested patterns and long guards pack a decision into one line the reader has to decode. The same test applies in reverse: if taking the line apart shows a decision the reader had to rebuild, pull it out into a named step.
- **The guarantee needs a closed type.** A match over a non-sealed type compiles, but nothing checks completeness and the `default` branch carries the weight. Acceptable for `Object`-typed dispatch or hierarchies you don't own; where the cases are under your control, seal them. (For sets that are open by design, see *When NOT to*.)
- **`Match` has costs.** A signature per type, a lambda per branch, and no `return` or `break` from inside a branch. In Java you weigh them; in C# this book pays them for the check (see *`switch` or `Match`?*).

---

## When NOT to

- **The set of cases is open by design.** Plugin hosts, extension points, codebases where new subtypes are expected to appear outside the module. Pattern matching's guarantee depends on the compiler seeing every case, so it can't help here. This is one side of the [expression problem](https://en.wikipedia.org/wiki/Expression_problem): a closed set of cases makes new operations easy and new cases hard; an open set, the other way round.

---

## Convention: match on a named value, never on an inline call

A pattern match (a `switch` expression, a `switch` statement, or a `Match` or `Handle` call) always reads from a *named variable*, never from a call expression. Wherever you're tempted to write `Compute(...).Handle(...)` or `switch (Compute(...)) { ... }`, split it into two statements:

<table>
<tr><th>Don't</th><th>Do</th></tr>
<tr>
<td>

```csharp
Decide(state, command).Handle(
    approved: a => Persist(a),
    denied:   d => Log(d));
```

</td>
<td>

```csharp
var decision = Decide(state, command);   // pure
decision.Handle(                          // impure dispatch
    approved: a => Persist(a),
    denied:   d => Log(d));
```

</td>
</tr>
</table>

The same goes for `Match` and for `switch`: `var result = x.Compute(...); result.Match(...)`, not `x.Compute(...).Match(...)`.

The reason is **visual separation between pure and impure code**. The pure call is on one line; the impure dispatch is on the next. A reviewer scanning down sees the two halves at once, *compute* then *act*, without parsing an expression. Inlining the call merges them into one expression and hides the boundary this book works hard to mark.

It also brings three smaller benefits:

1. **The intermediate value gets a name.** A reviewer knows what is being dispatched on by reading one identifier.
2. **A debugger can stop between the two statements** and show the result before the dispatch runs.
3. **Every example has the same rhythm.** `var x = Pure(...); x.Match(...)` becomes a shape the eye recognizes without parsing.

A property access (`x.Status`) is fine to inline; the rule is about real *calls*, not every member access.

---

## References

[1] **Philip Wadler**, *Views: A Way for Pattern Matching to Cohabit with Data Abstraction*, POPL 1987. Shows that pattern matching can coexist with information hiding: a value's internal representation can stay private while patterns still read a meaningful shape.

[2] **Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides**, *Design Patterns: Elements of Reusable Object-Oriented Software*, Addison-Wesley, 1994. Also cited in [Axiom 10](axiom-10-first-class-functions.md) and [Axiom 11](axiom-11-higher-order-functions.md). Its *Visitor* chapter is the classic reference for case analysis over a closed type hierarchy in an OO language without pattern matching.

[3] **OpenJDK**, *JEP 441: Pattern Matching for switch*, final in Java 21 (2023). The reference for Java's pattern-matching syntax, exhaustiveness rules and interaction with sealed types. <https://openjdk.org/jeps/441>

[4] **Scott Wlaschin**, *Introduction to recursive types*, fsharpforfunandprofit.com, 2015, the first post of his series on catamorphisms and folds. Its first rule for writing a catamorphism: "Create a function parameter to handle each case in the structure." <https://fsharpforfunandprofit.com/posts/recursive-types-and-folds/>

[5] **OneOf** (C#). "You use the `TOut Match(Func<T0, TOut> f0, ... Func<Tn,TOut> fn)` method to get a value out", and "There is also a .Switch method, for when you aren't returning a value."
<https://github.com/mcintyre321/OneOf>

[6] **ErrorOr** (C#), a Result-style library. "The `Match` method receives two functions, `onValue` and `onError`", and "The `Switch` method receives two actions, `onValue` and `onError`."
<https://github.com/amantinband/error-or>

[7] **`java.util.Optional`**, Java SE 21 documentation. `ifPresentOrElse` (since Java 9) "performs the given action with the value, otherwise performs the given empty-based action": the void form beside `map` and `orElse`.
<https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Optional.html>

---

← Previous: [Axiom 11 — Higher-order functions](axiom-11-higher-order-functions.md) · Next: [Axiom 13 — Impureim](axiom-13-impureim.md) →
