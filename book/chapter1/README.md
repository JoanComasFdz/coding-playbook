# Chapter 1 — SOLID Principles don't cut it anymore
> How many times have you done a code review where you or your partner said "This code is not applying Liskov Substitution"?

> How many times have you been coding and though: "Oh I need to follow the Open/Close principle here" ?

> How many times have you been coding and though: "Hm.. i am not sure I should apply Dependency Inversion here" ?

> How many times have you done a code review where the main discussion was if a class was doing too much or not?

For years SOLID was the vocabulary I reached for whenever I had to justify a design. It sounded like a method: five letters, learn them, apply them, get good code. But somewhere along the way I noticed I could *recite* SOLID without it ever changing a single decision I made at the keyboard. When I tried to use it forward — to *generate* a design rather than grade one — it gave me nothing actionable. "Single responsibility" never told me where to draw the line; "open/closed" never told me which axis would vary.

What I was left with was a set of words for *naming things that had already gone wrong*. SOLID stopped being something I could act on and became something I could point at — after the fact. That is a real and useful thing for a vocabulary to be. It is just not a way to reason about the code, and I had been treating it as one.

This chapter is me working out why, and focusing on SOLID as it's actually practiced in industry — cargo-culted, dogmatic, `IFoo`-per-class — not the principles charitably interpreted by their authors. 

Strip away the theory and what the industry actually settled on is a small, fixed architecture — a project skeleton you just follow:

- an interface for every class — `IFoo` beside every `Foo`;
- a DI container to wire them;
- those interfaces injected through the constructor.

It is really just **D** and **I** turned into plumbing; **O** and **L** survive only as the *excuse* for the interface seam (you *could* swap the implementation, any one *would* substitute), never as something you actually do. Principles meant to guide judgement became *boilerplate* you set up once and stop thinking about — which is the problem in miniature: **a template you apply by reflex is the opposite of reasoning about a design**.

## The online sentiment

The unease I felt has already been expressed; here is what others have argued, with sources, so you can follow each thread yourself.

### General

- "Principles" is the wrong word — they're contextual patterns or properties, not universal rules ([Henney, *SOLID Deconstruction*](https://www.slideshare.net/Kevlin/solid-deconstruction); [North, *Why Every Element of SOLID Is Wrong*](https://speakerdeck.com/tastapod/why-every-element-of-solid-is-wrong)).
- Applied rigidly, SOLID produces over-abstracted, hard-to-navigate codebases — proliferation of tiny classes and interfaces ([Khoo, *Challenging the Gospel*](https://medium.com/@jeremykhoois/solid-principles-sucks-b5935b1235d7); [Mortenson, *SOLID — 25 Years Later*](https://dev.to/chriswritesstuff/solid-30-years-later-g79)).
- Open to vast amounts of interpretation and misinterpretation; the original definitions aren't operationally precise ([Marston, *Not-so-SOLID OO Principles*](https://www.tonymarston.net/php-mysql/not-so-solid-oo-principles.html)).
- No concrete problem/solution demonstrations — show the bug, the fix, the side effects ([Marston](https://www.tonymarston.net/php-mysql/not-so-solid-oo-principles.html)).
- Second-order principles at best — they point in a direction, they don't define a goal ([Mortenson](https://dev.to/chriswritesstuff/solid-30-years-later-g79)).
- Rooted in late-90s OO assumptions; the framing feels dated ([nocomplexity, *Rise and Fall of SOLID*](https://nocomplexity.com/solid-programming/); [Dunn, *Is SOLID Still Relevant?*](https://dunnhq.com/posts/2021/solid-relevance/)).

### Per principle

#### S — Single Responsibility
- Undefined in practice; "one reason to change" drifted to "one actor" with no operational test ([Marston](https://www.tonymarston.net/php-mysql/not-so-solid-oo-principles.html)). (The idea this gropes toward — [Cohesion](../chapter2/axiom-07-cohesion.md) — is given a sharper, testable shape in Chapter 2.)
- Applied rigidly, produces overly granular classes for theoretical purity ([Khoo](https://medium.com/@jeremykhoois/solid-principles-sucks-b5935b1235d7)).

#### O — Open/Closed
- Requires predicting the future — which axis of variation will matter next ([Khoo](https://medium.com/@jeremykhoois/solid-principles-sucks-b5935b1235d7)).
- Inheritance-for-extension caused the 90s "inheritance overdose" we're still recovering from ([Dunn](https://dunnhq.com/posts/2021/solid-relevance/)).
- Arguably redundant — already implied by LSP ([Henney summary](https://yahnd.com/theater/r/vimeo/157708450/); [Dunn](https://dunnhq.com/posts/2021/solid-relevance/)).

#### L — Liskov Substitution
- Routinely misread as a *structural* rule (same interface ⇒ substitutable) when it's a *behavioral* contract ([Henney](https://www.slideshare.net/Kevlin/solid-deconstruction); [Oldwood, *KISSing SOLID Goodbye*](https://accu.org/journals/overload/22/122/oldwood_1957/)). (Behavioral contract is exactly what [honest, total signatures](../chapter2/axiom-06-honest-total-signatures.md) make visible.)

#### I — Interface Segregation
- Cargo-culted into "one interface per class, even with a single implementation" ([Khoo](https://medium.com/@jeremykhoois/solid-principles-sucks-b5935b1235d7)).
- Arguably collapses into SRP — not a separate idea ([North](https://speakerdeck.com/tastapod/why-every-element-of-solid-is-wrong)).

#### D — Dependency Inversion
- Routinely conflated with DI / DI frameworks; the principle ≠ the mechanism ([NDepend, *In Defense of SOLID*, noting the confusion](https://blog.ndepend.com/defense-solid-principles/)).
- Arguably reduces to SRP + LSP — Henney argues it isn't a separate principle ([Henney summary](https://yahnd.com/theater/r/vimeo/157708450/)).
- Terminology dated — "inversion" comes from the structured-programming era; today this *is* normal dependency direction ([Dunn](https://dunnhq.com/posts/2021/solid-relevance/)). (Where dependency direction *does* earn its keep, the [Impureheim sandwich](../chapter2/axiom-12-impureheim.md) makes it a shape, not a framework.)

### Paradigm fit

- Doesn't transfer cleanly to functional programming or data pipelines; works mainly in its original context (large Java/.NET monoliths) ([Mikulski, *CUPID in Data Engineering*](https://mikulskibartosz.name/cupid-principles-in-data-engineering)).
- Doesn't apply cleanly across microservice boundaries — no implementation injection over HTTP/AMQP, so OCP loses meaning and DIP becomes contract-coupling ([Van Couvering, *Applying SOLID to Services*](https://david-vancouvering.medium.com/applying-solid-principles-to-services-e56ef2382a26)).

### Proposed alternatives

- **CUPID** — Composable, Unix philosophy, Predictable, Idiomatic, Domain-based. Properties on a spectrum, not rules ([cupid.dev](https://cupid.dev/); [North, *CUPID — for joyful coding*](https://dannorth.net/2022/02/10/cupid-for-joyful-coding/)).
- **Patterns over principles** — treat SOLID as context-dependent patterns to apply when symptoms appear, not rules to follow always ([Henney, *SOLID Deconstruction*](https://www.slideshare.net/Kevlin/solid-deconstruction)).

## My read — half architecture, half not actionable

*This sharpens the community critique above rather than repeating it. The reasoning is my own; the one external attribution is cited inline.*

- **The structural/semantic split.** SOLID partitions cleanly. D, I, and the strategy-pattern form of O are *structural* — a convention, DI container, or linter enforces them, so they dissolve into invisible plumbing. S and L are *semantic* — about [cohesion](../chapter2/axiom-07-cohesion.md) and behavioral honesty — and nothing can mechanize them. The only live half of SOLID is S and L.
- **Only the un-mechanizable letters survive review — and only as symptoms, never by name.** Nobody says "Liskov violation," they say "this implementation behaves weird." Nobody says "SRP," they argue the class does too much. The principle vocabulary is dead in practice; the symptom vocabulary (blast radius, shotgun surgery, "why do I touch five files to add one thing") won.
- **SRP survives precisely because it's undefined.** Its vagueness isn't a bug — it's the only space in SOLID where real, contextual judgment ([cohesion](../chapter2/axiom-07-cohesion.md)) happens. The other letters became settled convention; SRP stays contested because it can't be reduced to a rule.
- **Two OCPs, and the bad one is the popular one.** Meyer's inheritance-based OCP (subclass to extend) is the fragile-base-class trap everyone actually hits. Bob's polymorphic OCP (add an implementation, never edit existing ones) is fine — but it's just "composition over inheritance" + "program to an interface" renamed. OCP is only sane *reactively*, along an axis you've already seen vary ([rule of three](https://en.wikipedia.org/wiki/Rule_of_three_(computer_programming))); applied speculatively it's just speculative generality.
- **OCP didn't die — it migrated up the stack.** Its surviving intent ("open for extension, closed for modification") is alive as Vertical Slice Architecture: add a feature by dropping in a vertical slice without touching existing slices. The unit of closure moved from the *class* to the *slice*, where it's finally actionable.
- **Refactoring to extract a shared concept is OCP working, not OCP breaking.** A one-time stabilizing extraction — done when the second consumer appears — buys closure for every future consumer. The health metric isn't "zero edits ever," it's *extraction frequency decaying over time* as the domain model matures. Persistent big extractions years in signal a wrong domain model and or design, not an OCP failure. Extract the *stable* domain concept (the aggregate); tolerate duplication on the *volatile* workflow.
- **SOLID is OOP-remediation, not universal design.** Its invisibility in FP is the tell: SRP, OCP, LSP, ISP, DIP are all structural givens in FP ([functional decomposition](../chapter2/axiom-01-data-vs-behaviour.md), [higher-order functions](../chapter2/axiom-09-first-class-functions.md), parametricity, small composable functions, dependencies-as-parameters), so the vocabulary is never needed. Even Mark Seemann — a rigorous SOLID defender — argues that, taken seriously, SOLID converges on FP ([Seemann, *SOLID: the next step is Functional*](https://blog.ploeh.dk/2014/03/10/solid-the-next-step-is-functional/)): push ISP to role interfaces and you reach single-method interfaces, which *are* functions. SOLID is a diagnostic vocabulary for *OOP-as-practiced* failure modes — useful for naming smells, but not the level at which design actually happens.
- **Judge SOLID by how it's practiced, not by what it was meant to be.** Almost no one applies the principles the way their authors intended, and the industry has long since settled into one particular way of working. That practiced version is the only SOLID most people ever meet — so debating what the principles *should* have meant is pointless; it only invites the reply *"you've misunderstood them."* The claim worth making is the concrete one: the version the industry actually practices isn't actionable — it doesn't help you reason about the code, only name what already went wrong. Everyone has felt that, so no one can dismiss it.

## CUPID — names the destination, not the route

The alternative I keep circling back to is Dan North's **CUPID** — five *properties* (Composable, Unix philosophy, Predictable, Idiomatic, Domain-based) on a spectrum ([North, *CUPID — for joyful coding*](https://dannorth.net/2022/02/10/cupid-for-joyful-coding/)). It is goal-oriented — *"move toward"*, not *"conform or don't"* — which is already a step up: **applied SOLID is useless for generating a design; CUPID is an ally.**

But it shares SOLID's ceiling. A property is something you *recognise*, not something you *do*: CUPID describes the **destination**, never the **route**. Read each property and you find yourself reaching for the building blocks of the next two chapters to actually *get there* — and that is the tell. **CUPID is the symptom of good mechanism; the axioms are the mechanism.** Every property below resolves into something I already reason with (or will, in a later chapter):

### Composable — "plays well with others"

- **Small surface area** → the future *Deep modules, small interfaces* Play (Chapter 3): module value = functionality ÷ interface cost. *Why:* a narrow API is the small surface.
- **Intention-revealing** → [honest, total signatures](../chapter2/axiom-06-honest-total-signatures.md) + domain-named [value objects](../chapter2/axiom-18-value-objects.md); [making illegal states unrepresentable](../chapter2/axiom-22-illegal-states.md) and [discriminated unions](../chapter2/axiom-21-discriminated-unions.md) name each case where a `bool` would hide it. *Why:* the type, not a comment, reveals the intent.
- **Minimal dependencies** → North means *external packages* (his example is dropping a logging library) — a packaging concern that sits *above* this book's altitude. Zoomed in to a single function it *rhymes* with [purity](../chapter2/axiom-05-pure-functions.md) (depends only on its arguments) and [Impureheim](../chapter2/axiom-12-impureheim.md) (dependencies handed in from the shell, never reached for). A rhyme, not the same claim — packages vs. hidden inputs.
- The act of *composing* itself → [higher-order functions](../chapter2/axiom-10-higher-order-functions.md) and `Result` composition (map/bind/traverse). *Why:* composability is something you build, with combinators.

### Unix philosophy — "does one thing well"

- **Does one thing** → [Cohesion](../chapter2/axiom-07-cohesion.md), judged outside-in — which is exactly North's own distinction from inside-out SRP. *Why:* "one job" is the cohesion question, made testable.
- **Composes via pipes** → low [Connascence](../chapter2/axiom-08-connascence.md) between units, plus the combinators above. *Why:* tools pipe cleanly only when what couples them is weak and explicit.

### Predictable — "does what you expect"

- **Behaves as expected** → [honest, total signatures](../chapter2/axiom-06-honest-total-signatures.md). *Why:* the type tells you what can come back, so the behaviour is on the surface, not in the body.
- **Deterministic** → [pure functions](../chapter2/axiom-05-pure-functions.md). The cleanest one-to-one in the whole set: determinism *is* referential transparency *is* purity.
- **Observable** → instrumentation, telemetry, monitoring. Operational, above this book's altitude.

### Idiomatic — "feels natural"

- **Language + team idioms** → not an axiom but a *contextual choice* (dated, reversible, team-dependent — the ADR tier; `AsNoTracking`, jOOQ are idiom picks, and North himself sends local idioms to ADRs). *Why:* what feels natural is a property of the reader, not of the code.
- The honest tension worth naming: my axioms sometimes go *against* the local idiom — `Result<int, string>` instead of the idiomatic `bool TryParse(string, out int)`. I trade paradigm-idiom for honesty (simplicity-first: honest before familiar) while paying the idiom back at the *mechanism* level — records, `switch` expressions, pattern matching, LINQ. Idiomatic still applies and still matters; it just sits a level above the building blocks.

### Domain-based — "models the problem domain in language and structure"

- **Domain-based language** → domain-named [value objects](../chapter2/axiom-18-value-objects.md) and the future FP-style *DDD tactical patterns* (Chapter 3). *Why:* `Surname`, not `string` — close the gap between the code and the conversation.
- **Domain-based structure** → Vertical Slice Architecture: directories mirror the domain, not technical layers — which is where I argued [OCP migrated](#my-read--half-architecture-half-not-actionable).
- **Domain-based boundaries** (module = deployment unit) → architectural, above this book's altitude.

Stack the chapters by altitude — Chapter 1 the inception, Chapter 2 the building blocks, Chapter 3 the plays, each a level up — and the parts of CUPID that *don't* land in Chapters 2–3 (Observable, Idiomatic, minimal-dependencies-as-packaging) all point the same way: up, at a layer this book doesn't reach yet. That is the honest reason they're unmapped — not that they don't matter, but that they live above the code altitude. Everything *at* code altitude is already a building block waiting in the next chapter.

## So what do I reason with instead?

When reading and writing code we must have the tools, the precise vocabulary to evaluate each line, each data point and each function, in several dimensions. To argue about trade-offs and to describe them properly.

SOLID does not give us that. The tell is right there: SOLID is invisible in functional code. It can only be applied where objects own mutable state and behaviour at once. And even when applied, half of it is pure architecture and the other is not actionable.

CUPID comes closer — it's an ally, pointing *toward* a destination,  nut it stops at the same ceiling: it can't hand you the route. Both leave me able to *name* what I'm looking at, never to *generate* it.

So the question I want answered isn't "how do I obey five principles, or chase five properties?" It's:

**What are the building blocks that give me the precise vocabulary and metrics to reason about the code?**

And once I have them:

**How can I enforced those in the code itself, so I do not rely on anyone's discipline at review time?**

