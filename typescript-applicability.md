# Do the axioms apply to current TypeScript?

*An evaluation of Chapter 2's axioms (1–27; the later-added Axiom 0 — Ubiquitous Language — is not yet evaluated here) against current TypeScript (≈ 5.x, `strict` on). Analysis only — the playbook's named targets remain C# and Java per [CLAUDE.md](CLAUDE.md); nothing in `book/` is changed by this document.*

*Written 2026-06-01.*

---

## Headline verdict

**The principles transfer almost entirely; the *mechanisms* split into three groups, and one language trait — structural typing — is the thread that decides which.**

The playbook's central model — *pure functions over immutable types, returning values or action DUs; a single impure orchestrator is the only seam; stateful resources held in the shell and fed in as values* — is, if anything, **more native to TypeScript than to C#/Java**, because discriminated unions are TS's idiomatic core rather than a ceremony assembled out of `abstract record` / `sealed interface`.

But four of the playbook's load-bearing guarantees lean on **nominal typing** and **automatic exhaustiveness**, and TypeScript gives you neither for free. So the axioms are *right* for TS, yet several of the **C#/Java examples would actively mislead a TS reader** if transcribed literally: they would compile and silently fail to deliver the guarantee the prose claims.

---

## The four forces that decide each axiom's fate

1. **Discriminated unions are native and ergonomic.** `type T = A | B | C` with a literal discriminant, plus automatic control-flow narrowing — no class-per-variant boilerplate. → Axioms 11, 14, 16, 21, 22, 23, 24 land *cleaner* than in C#/Java.
2. **Typing is structural, not nominal.** Two types with the same shape are interchangeable. → Axioms 8 (Connascence of Type), 18 (value objects), 27 (construction control) lose their compiler-enforced edge unless you reach for **branded types** or **`#private`-field classes**.
3. **Exhaustiveness is opt-in.** No sealed-hierarchy exhaustiveness check; you need the `never` idiom, ESLint's `switch-exhaustiveness-check`, or `ts-pattern`'s `.exhaustive()`. → Every DU-consuming axiom inherits a weaker "the compiler hands you the to-do list" claim — placing TS *below* even C#'s CS8509 warning unless the team adopts the idiom.
4. **No native pattern matching, no value equality, shallow erased immutability.** → Axioms 11, 2, 18 need different machinery from what the examples show.

---

## Per-axiom verdict

| Axiom | Applies? | TS mechanism vs. the C#/Java example |
|---|---|---|
| [1 Data vs Behaviour](book/chapter2/axiom-01-data-vs-behaviour.md) | ✅ unchanged | Language-agnostic; TS culture already leans this way (plain data + functions). |
| [2 Immutability](book/chapter2/axiom-02-immutability.md) | ⚠️ weaker | `readonly` / `as const` / `Readonly<T>` are **shallow + erased**; no value equality; `Object.freeze` is the only runtime teeth. The reflection quizzes and "records are values" don't map. |
| [3 Side effects](book/chapter2/axiom-03-side-effects.md) | ✅ unchanged | Same recognition discipline; the API catalogue needs a JS rewrite (`Date.now`, `Math.random`, `fetch`, `fs`, `console`, throwing, microtasks). |
| [4 Impure functions](book/chapter2/axiom-04-impure-functions.md) | ✅ unchanged | Same; minor bonus — `async` *is* surfaced in the type (`Promise<T>`), unlike most effects. |
| [5 Pure functions](book/chapter2/axiom-05-pure-functions.md) | ✅ unchanged | Identical; no purity enforcement, same as C#/Java. |
| [6 Honest/total signatures](book/chapter2/axiom-06-honest-total-signatures.md) | ✅ **stronger** | DUs make "widen the output" cheap; the `out`/`ref` dishonesty doesn't exist in TS. **But** `any`/`as` and structural typing undercut totality, and exhaustiveness isn't free. |
| [7 Cohesion](book/chapter2/axiom-07-cohesion.md) | ✅ unchanged | Pure judgement; transcribes directly. |
| [8 Connascence](book/chapter2/axiom-08-connascence.md) | ⚠️ **shifts** | **The CoT example breaks** (below). The "compiler-enforced vs convention" line moves because CoT is only as strong as branding makes it. |
| [9 First-class functions](book/chapter2/axiom-09-first-class-functions.md) | ✅ **stronger** | TS/JS has the cleanest story of the three — no `Func<>` / delegate ceremony, native closures. |
| [10 Higher-order functions](book/chapter2/axiom-10-higher-order-functions.md) | ✅ **stronger** | Native `map`/`filter`/`reduce`; less inference friction than the axiom warns about. |
| [11 Pattern matching](book/chapter2/axiom-11-pattern-matching.md) | ⚠️ **different** | No native pattern matching / no `switch` *expression*. Discriminant-`switch` + `never`, or `ts-pattern`. The `Match`-method form works. |
| [12 Impureheim](book/chapter2/axiom-12-impureheim.md) | ✅ unchanged | Same sandwich; gather is usually `await`ed. |
| [13 Maybe](book/chapter2/axiom-13-maybe.md) | ✅ **stronger** | `T \| undefined` under `strict` is structural + compile-enforced *and* allocation-free — it lands **above C# NRT** (advisory) and matches Java `Optional`'s enforcement. The "no Optional in fields/collections" caveats are largely Java-specific (`field?: T` is idiomatic in TS). |
| [14 Either](book/chapter2/axiom-14-either.md) | ✅ **stronger** | Trivial DU; the `out`-param critique is moot. |
| [15 Unit](book/chapter2/axiom-15-unit.md) | ➖ partly dissolves | TS `void` *is* a type and `undefined` is a one-value type — most of the "void isn't first-class" problem the axiom solves doesn't exist in TS. |
| [16 Result](book/chapter2/axiom-16-result.md) | ✅ **stronger motivation** | DU or `neverthrow`/`Effect`. Exceptions are *less* honest than C#/Java (no checked exceptions, `catch (e: unknown)`), so the case for Result is stronger. |
| [17 Result combinators](book/chapter2/axiom-17-result-combinators.md) | ✅ unchanged | `neverthrow`'s `map`/`mapErr`/`andThen`; `Promise.then` and `Array.flatMap` make the "same shape elsewhere" point vividly. |
| [18 Value objects](book/chapter2/axiom-18-value-objects.md) | ⚠️ **weaker / different** | Biggest divergence (below). Spirit is *extremely* idiomatic via **Zod**, but the nominal guarantees need branding / `#private`, and value-equality is absent. |
| [19 Railway](book/chapter2/axiom-19-railway.md) | ✅ unchanged | `neverthrow` chains are the railway verbatim. |
| [20 Validation (accumulate)](book/chapter2/axiom-20-validation.md) | ✅ **stronger** | Variadic-arity pain is smaller (variadic tuple types); and **Zod accumulates all field errors by default** — Axiom 20 out of the box. |
| [21 Discriminated unions](book/chapter2/axiom-21-discriminated-unions.md) | ✅ **best fit** | TS's crown jewel; the axiom already cites TS tagged unions. Only gap: exhaustiveness opt-in. |
| [22 Illegal states unrepresentable](book/chapter2/axiom-22-illegal-states.md) | ✅ **best fit** | Sum-of-records is pure idiom; the product/sum arithmetic ports directly. |
| [23 Pure fns returning actions](book/chapter2/axiom-23-pure-functions-returning-actions.md) | ✅ unchanged | Action DU + dispatch switch; clean. |
| [24 State machines](book/chapter2/axiom-24-state-machines.md) | ✅ unchanged | `Transition(state, command) → event` over DUs; XState exists, but the pure-function form is natural. |
| [25 Session Context](book/chapter2/axiom-25-session-context.md) | ✅ unchanged | Mutable object threaded explicitly; ambient anti-patterns map to `AsyncLocalStorage` / React context. |
| [26 Stateful Shell](book/chapter2/axiom-26-stateful-shell.md) | ✅ unchanged | Loop + async dispatch; cancellation → `AbortController` / `AbortSignal` instead of `CancellationToken`. |
| [27 Typestate](book/chapter2/axiom-27-typestate.md) | ⚠️ weaker construction / stronger DSL | Linear typestate needs `#private` for construction control; but the **stacking-generics** variant (Kysely, Drizzle, Zod builders) is arguably *more* natural in TS than C#/Java. |

**Tally:** ~19 apply unchanged or land better; 4 need real caveats (8, 18, 27, plus the swapped-argument protection that recurs across them); 3 need mechanism swaps (2, 11, 13); 1 partly dissolves (15).

---

## The examples that would mislead if transcribed literally

These are the spots where the C#/Java code carries a guarantee that **silently evaporates** in idiomatic TS.

### Axiom 8 — the Connascence-of-Type example is the clearest casualty

The axiom shows that giving `amount` and `fee` distinct types catches a swap at compile time:

```csharp
public readonly record struct Amount(decimal Value);
public readonly record struct Fee(decimal Value);
// Transfer(payer, payee, new Fee(2.50m), new Amount(100.00m));  // ❌ build breaks
```

In nominal C#/Java this is the whole point — CoT is "the benign, compiler-enforced end of the scale." In TypeScript:

```typescript
type Amount = { value: number };
type Fee    = { value: number };
// transfer(payer, payee, fee, amount);  // ✅ COMPILES — structurally identical
```

The swap **compiles fine**. CoT in TS is only compiler-enforced if you brand:

```typescript
type Amount = number & { readonly __brand: 'Amount' };
type Fee    = number & { readonly __brand: 'Fee' };
// now transfer(payer, payee, fee, amount) is a type error (brands forgeable only via `as`)
```

So the axiom's central organizing line — *"CoN and CoT are the only forms the compiler enforces"* — is **conditionally true** in TS: it depends on a nominal-typing discipline the language doesn't impose. The "weaken CoM → CoT" canonical move still helps, but you are weakening *toward a target that is itself soft* unless branded.

### Axiom 18 — value objects: right spirit, wrong default mechanism

The C#/Java example relies on three things TS doesn't give you for free:

1. **Distinctness.** `CustomerProfile(Username, EmailAddress)` rules out swapped arguments *because the types are nominal*. With `Username = {value:string}` and `EmailAddress = {value:string}`, the swap compiles. You need **branded types**, or — the genuinely nominal TS trick — a class with a **`#private` field** (a class carrying a private member is *not* structurally assignable from a plain object of the same shape).
2. **Equality by value.** The axiom's definition demands "two instances with equal data are equal." Records give this free in C#/Java. TS objects are reference-equal (`===`); you'd hand-write `equals` or pull a library. This property is simply *absent* by default.
3. **Construction control.** TS `private constructor` is compile-time only; `#private` is runtime-enforced.

The redeeming TS-specific fact: **Zod is the most idiomatic realization of "parse, don't validate" in any mainstream language.** `z.string().email().brand<'Email'>().safeParse(raw)` returns `{ success: true, data } | { success: false, error }` — literally a Result DU — and `.brand()` gives the nominal distinctness. So Axiom 18's *intent* is arguably better-served in the TS ecosystem than in C#/Java; the wrapper-record-with-private-constructor example is just not the TS idiom and doesn't carry equality.

### Axiom 2 — immutability is advisory to a greater degree than "contract-level, not byte-level"

The playbook already concedes immutability is source-level (reflection breaks it). TS pushes further: `readonly` is **erased and shallow** (`readonly foo: string[]` still lets you `.push()`; you need `readonly string[]`), there is **no value-typed record**, and the runtime escape is a casual `as any`. The reflection-still-immutable quizzes (3/5, 4/5) have no TS analogue; the "List vs immutable" quiz maps to `string[]` vs `readonly string[]`; and "records are values" — the foundation of quiz 4/5 — has no TS equivalent. The principle holds; the enforcement floor is lower, with `Object.freeze` as the only runtime guarantee.

### Axiom 11 — pattern matching: principle yes, mechanism no

TS has **no native pattern matching and no `switch` expression**. The C#/Java type-pattern switch (`obj switch { string s => … }`) becomes `typeof`/`instanceof` narrowing or — idiomatically — a `switch` on a literal discriminant field. Exhaustiveness over a closed set is the `never` idiom or `ts-pattern`'s `.exhaustive()`, not a compiler default. The "match on a named value, never an inline call" convention applies unchanged.

```typescript
function render(o: PaymentOutcome): string {
  switch (o.kind) {
    case 'approved':             return `Charged. Auth: ${o.authCode}`;
    case 'declined':             return `Declined: ${o.reason}`;
    case 'requiresVerification': return `Verify at ${o.challengeUrl}`;
    default: { const _exhaustive: never = o; throw new Error('unreachable'); }
  }
}
```

### Axiom 15 — Unit largely dissolves

The axiom's entire motivation is "`void` is not a type — you can't put it in a generic slot, can't return it from a lambda." In TS, `void` **is** a type, `() => void` and `Promise<void>` and `Array<() => void>` all work, and `undefined` is a genuine one-value type. The problem Axiom 15 exists to solve is ~80% already solved by the TS type system; a dedicated `Unit` is rarely needed.

### Axiom 27 — typestate: weaker linearity-of-construction, stronger DSLs

The headline linear-typestate example depends on `internal` / package-private constructors to stop fabrication of `AuthenticatedSession`. TS's answer is the `#private`-field-class trick (nominal identity) — the only clean way to make `new AuthenticatedSession(...)` un-forgeable. The "old reference doesn't vanish" trade-off is the same (TS has no linear/affine types, same as C#/Java). *But* the **stacking-generics** variant (SQL DSL, Given/When/Then, FluentValidation/Moq) is a TS *strength*: variadic tuples, conditional and template-literal types make builder-typestate richer than in C#/Java — Kysely and Drizzle are the TS jOOQ, and they go further than jOOQ's example.

---

## Making the axioms applicable in TS: three tiers, not "config before each example"

A natural first instinct is that each example needs a comment plus some environment config to hold in TS. The instinct is right that the examples carry an *implicit environment* that must be made explicit — but it conflates two layers, and one of them isn't config at all. There are **three tiers**.

### Tier 1 — one global config preamble (once for the whole book, not per example)

A `tsconfig` baseline plus one ESLint rule, stated *once* — the way the playbook states its scope once in the README.

```jsonc
// tsconfig.json — the baseline every example assumes
{
  "compilerOptions": {
    "strict": true,                    // → strictNullChecks, useUnknownInCatchVariables, noImplicitAny…
    "exactOptionalPropertyTypes": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true
  }
}
// + ESLint: "@typescript-eslint/switch-exhaustiveness-check": "error"
```

What this buys, and which axioms it rescues:

- `strictNullChecks` → **Axiom 13** (`T | undefined` becomes *enforced*, not advisory — this is where TS actually beats C#'s `T?`) and **Axiom 6** (null honesty).
- `useUnknownInCatchVariables` → **Axiom 16** (`catch (e: unknown)` reinforces errors-as-values).
- `noUncheckedIndexedAccess` → **Axiom 6** totality (indexing returns `T | undefined`).
- `exactOptionalPropertyTypes` → **Axiom 13** (tightens optional-property semantics).
- The ESLint exhaustiveness rule → **Axioms 11, 14, 21, 22, 23, 24** — the closest TS gets to Java's sealed exhaustiveness, and note it is a *lint rule, not a compiler feature*. The guarantee the playbook leans on is partly outsourced to ESLint.

So the "environment config" intuition is real — but it is one preamble, and it covers maybe a third of the axioms.

### Tier 2 — in-code technique (NOT config, NOT a comment)

The correction that matters: **no `tsconfig` flag makes TypeScript nominal.** There is no `"nominalTypes": true`. So the deepest divergences — **Axiom 8 (CoT), 18 (value objects), 27 (construction control)** — are *unreachable by configuration*. They need code that lives inside the example:

- **branded types** (`string & { readonly __brand: 'Email' }`), or
- the **`#private`-field class** trick (a class with a private member is nominally distinct — a plain object of the same shape won't assign to it), or
- the **`never` exhaustiveness idiom** where the lint rule isn't enough.

That is not a preamble bolted on — it is the example itself being written differently. Config is **necessary but not sufficient**; the hardest cases skip config entirely and live in the code.

### Tier 3 — a localized prose note (the "comment")

Yes — but only on the *diverging* examples, and the book already has exactly this pattern: the Axiom 13 box explaining that C# `T?` is "compile-time-only and advisory," and the recurring "C# 14 can't prove the hierarchy closed → CS8509" note in Axioms 11/14/21. That is the precedent. A TS edition would add the same kind of short, localized note — *"in TS, brand it or use a `#private` field, because structural typing won't catch the swap"* — folded in where it bites.

Putting a config-and-comment block before **all 27** examples would be noise on the ~19 that transfer cleanly. The book's own register is "say the minimum, where it's needed" — blanket boilerplate would fight that.

### What config covers vs. what only code can

| Guarantee | Reachable by config? | How |
|---|---|---|
| Absence honest & enforced (Axiom 13) | ✅ | `strict` / `strictNullChecks` |
| Null honesty in signatures (Axiom 6) | ✅ | `strict` |
| Errors-as-values reinforced (Axiom 16) | ✅ | `useUnknownInCatchVariables` (in `strict`) |
| Totality on indexing (Axiom 6) | ✅ | `noUncheckedIndexedAccess` |
| Exhaustiveness over DUs (11, 21, 23, 24) | ◑ partial | ESLint rule **or** `never` idiom **or** `ts-pattern` |
| Nominal distinctness / no-swap (8, 18, 27) | ❌ | branded types or `#private`-field classes (in-code) |
| Deep immutability (Axiom 2) | ❌ | `readonly` discipline + `Object.freeze` / `DeepReadonly` |
| Value equality (Axiom 18) | ❌ | library or hand-written `equals` |
| Pattern matching (Axiom 11) | ❌ | discriminant `switch` or `ts-pattern` |

---

## Concrete illustration

**A diverging axiom — Axiom 18, with the technique baked in and one localized note:**

```typescript
// (tsconfig strict assumed — Tier 1, stated once for the book)

class EmailAddress {
  private constructor(readonly value: string) {}   // Tier 2: private ctor + class identity
                                                    //         = nominal, un-forgeable
  static from(raw: string): Result<EmailAddress, string> {
    if (!raw.includes('@')) return err("email is missing '@'");
    return ok(new EmailAddress(raw));
  }
}
// Tier 3 note: a *plain object* { value: string } would be structurally
// interchangeable with Username — the class (or a brand) is what makes
// CustomerProfile(Username, EmailAddress) reject a swap. No tsconfig flag does this.
```

**A clean transfer — Axiom 22 needs none of this; just a TS union, no preamble, no note:**

```typescript
type Bill =
  | { kind: 'pending';    id: BillId; amount: Money }
  | { kind: 'processing'; id: BillId; amount: Money }
  | { kind: 'processed';  id: BillId; amount: Money; processedAt: Date }
  | { kind: 'sent';       id: BillId; amount: Money; sentAt: Date }
  | { kind: 'paid';       id: BillId; amount: Money; paymentRef: string }
  | { kind: 'failed';     id: BillId; amount: Money; reason: string };
```

**The branded fix for Axiom 8 — where the C#/Java example's guarantee is recovered:**

```typescript
type Amount = number & { readonly __brand: 'Amount' };
type Fee    = number & { readonly __brand: 'Fee' };

declare function transfer(from: Account, to: Account, amount: Amount, fee: Fee): Receipt;
// transfer(payer, payee, fee, amount);  // ❌ now a type error — brands make the swap visible
```

---

## Bottom line

- **~19 of 27 axioms apply unchanged or land better in TS** — every DU-centric axiom (11, 14, 16, 21, 22, 23, 24), the reading-discipline axioms (1, 3, 4, 5, 7), the function axioms (9, 10), and the composition axioms (12, 17, 19, 20, 25, 26). The playbook's spine is a *good fit* for TS.
- **Four need real caveats** because they assume nominal typing: **8 (CoT), 18 (value objects), 27 (construction control)**, plus the swapped-argument protection that recurs across them. Transcribed naively they compile and lie; they need **branded types** or **`#private`-field classes**.
- **Three need mechanism swaps**: **2** (shallow/erased immutability, no value equality), **11** (discriminant `switch` + `never` instead of pattern matching), **13** (`T | undefined` — actually a *better* home than C#'s `T?`).
- **One partly dissolves**: **15** (`void` / `undefined` are already type-like).
- **The ecosystem does several axioms *better than the prose assumes***: Zod for 18/20 (parse-don't-validate + accumulating validation built-in), the exception model making 14/16 more compelling, native DUs for the whole sum-type family.

If a TypeScript edition were ever wanted, the rewrite is mostly mechanical, plus **one cross-cutting addition the C#/Java text never has to make**: a recurring *"in TS, brand it or use a `#private` field, because structural typing won't catch the swap"* note — most naturally folded into Axioms 8 and 18, the way the existing C#-`T?`-is-advisory note is folded into Axiom 13. And it is **three tiers, not "config before each example"**: one global config preamble, in-code technique on the ~5 nominal-typing-dependent axioms, and a localized note only where the mechanism diverges. The trap is thinking config can carry the load; the deepest cases (8, 18, 27) need code, because the thing they depend on — nominal typing — is the one thing no flag turns on.

---

## Open question — frontend framing: vary the shell, not the core *(for future consideration)*

A natural worry about a TS edition: TypeScript's centre of gravity is frontend/UI, where C# and Java are backend/desktop — so should the TS examples be UI-flavoured? And if they were, would they still be *comparable* to the C#/Java examples that sit beside them? The comparability worry is the right one to have — the side-by-side, "same axiom, different syntax" table is the book's core pedagogical device. But the dilemma is smaller than it first appears.

### Two assumptions to loosen first

1. **TypeScript isn't only frontend.** Node / Deno / Bun backends are enormous — Express, Fastify, NestJS (explicitly modelled on Spring/Angular DI), tRPC, Hono — plus CLIs and build tooling. A backend-flavoured TS shell would be both authentic *and* maximally comparable to the C#/Java shells.
2. **The playbook is about the pure domain core, not the UI.** Per [CLAUDE.md](CLAUDE.md) it is the *anatomy of a module and its functions* — code-level, not system topology. UI rendering, reactivity, hook ordering, the DOM, JSX, re-render timing are **the impure shell of a frontend app** — the same role an HTTP controller plays on the backend. The axioms never claimed that territory in C#/Java either.

Together these dissolve most of the dilemma: the choice is **not** "comparable backend examples vs. relatable UI examples." The axioms live in the domain core, and **the domain core looks the same in a frontend and a backend app.**

### Why the dilemma dissolves

The frontend code the playbook *does* touch is domain logic, and it is **already comparable** to the backend versions:

- Form validation → Axioms [18](book/chapter2/axiom-18-value-objects.md)/[20](book/chapter2/axiom-20-validation.md) (value objects, accumulate-every-error) — frontend-native via Zod + react-hook-form, still "parse input into domain values."
- Decoding/validating an API response at the `fetch` boundary → [Axiom 18](book/chapter2/axiom-18-value-objects.md) / parse-don't-validate — arguably the single most compelling frontend use of the book, and the same axiom as the backend's input parse.
- Deriving view-state from domain state → pure function, [Axiom 5](book/chapter2/axiom-05-pure-functions.md) (memoised selectors).
- A multi-step wizard or cart as a state machine → Axioms [24](book/chapter2/axiom-24-state-machines.md)/[27](book/chapter2/axiom-27-typestate.md) (XState, `useReducer`).

The frontend code the playbook *doesn't* touch — DOM, reactivity, component lifecycle — is exactly what it scopes out regardless of language. The book already says this: **[Axiom 27](book/chapter2/axiom-27-typestate.md)'s "When NOT to"** lists React hooks (`useX must be used within a Provider`) and Web Component `connectedCallback` as cases typestate can't reach, because they are tree-structural / framework-owned. The line is already drawn and consistent.

### Three models, and the recommendation

- **A — Parallel/comparable (the current device).** Same example, side-by-side columns; keeps "same axiom, every language" visible. The thing that makes the book work as a multi-language text.
- **B — Native-idiom per language.** C# = backend service, TS = React component. Authentic, but loses comparability *and* drags framework noise into every example — the reader now learns React alongside the axiom, diluting it.
- **C — Hybrid (recommended).** Keep the **pure-core examples parallel and comparable** across all languages (cart, order, validation, FSM). Vary **only the shell**, and only in the synthesis examples where a shell appears (Axioms [12](book/chapter2/axiom-12-impureheim.md), [16](book/chapter2/axiom-16-result.md), [19](book/chapter2/axiom-19-railway.md), [23](book/chapter2/axiom-23-pure-functions-returning-actions.md), [24](book/chapter2/axiom-24-state-machines.md), [26](book/chapter2/axiom-26-stateful-shell.md)), toward the reader's native idiom — and even then, keep it framework-light.

Model C honours the book's own philosophy directly — **thin shell, fat core**: the shell is where idioms legitimately differ; the core is universal. Adapt the part that is *meant* to be environment-specific, leave the part that is *meant* to be portable alone.

Concrete shell substitutions, with the core unchanged:

| Backend shell (current) | Frontend-native TS shell | Framework-light? |
|---|---|---|
| ASP.NET / Spring HTTP endpoint | React Router `action` / form `onSubmit` handler | yes (~6 lines, no JSX) |
| `return new HttpResponse(...)` | dispatch an action / return next view-state / navigate | yes |
| DB read at the top of the shell | `fetch` + Zod decode at the top | yes |
| Message-queue subscriber loop (Axiom 26) | `useReducer` dispatch / XState service | yes |

### The gift: frontend already speaks this dialect

This is why UI-rendering examples are unnecessary to make the edition land:

- A Redux / `useReducer` reducer is `(state, action) => state` — **literally [Axiom 24](book/chapter2/axiom-24-state-machines.md)'s `Transition`**, with the store as the shell. No JSX required.
- `react-hook-form` + Zod is **Axioms [18](book/chapter2/axiom-18-value-objects.md) + [20](book/chapter2/axiom-20-validation.md)** out of the box.
- A TanStack Query `queryFn` that fetches-then-decodes is **[Axiom 12](book/chapter2/axiom-12-impureheim.md)'s gather + [Axiom 18](book/chapter2/axiom-18-value-objects.md)'s parse.**

A frontend reader recognises the examples *as their own work* without the book ever rendering a component.

### The risk to avoid

A real React component example is rarely minimal — it imports hooks rules, dependency arrays, re-render semantics, JSX. That ceremony **competes with the axiom for the reader's attention**, and the book keeps examples "educational, not production." If a frontend shell is shown, show the *handler / reducer / decoder* (a plain function), not the component tree.

### Bottom line

Don't turn the TS examples into UI examples — that would lose comparability *and* drift into out-of-scope framework plumbing. Instead: keep pure-core examples identical and comparable across C#/Java/TS; vary only the shell, only where one appears, toward a frontend-native-but-framework-light idiom; and lean on the fact that the frontend's own primitives (reducers, RHF+Zod, query functions) *are* these axioms, so relatability comes for free. Let genuinely UI-specific concerns (reactivity, lifecycle, DOM) stay out of scope — the book already draws that line in [Axiom 27](book/chapter2/axiom-27-typestate.md), so it is a consistent boundary, not a new exception.
