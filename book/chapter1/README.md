# Chapter 1 — SOLID Principles don't cut it anymore

> How many times has a code review ended with "this code breaks Liskov Substitution"?

> How many times have you stopped while coding and thought "I need Open/Closed here"?

> How many times have you wondered "should I apply Dependency Inversion here?"

> How many times was a code review really an argument about whether a class does too much?

For years, SOLID was my go-to vocabulary to justify a design. It looked like a method: learn five letters, apply them, get good code.

Then I noticed that I could recite SOLID, but it never changed a single decision I made at the keyboard. When I tried to use it to *create* a design, instead of judging one, it gave me nothing to act on:

- "Single responsibility" never told me where to draw the line.
- "Open/closed" never told me which part of the code would change.

What I had left was a set of words to name things **after** they had gone wrong. That is useful. But it is not a way to reason about code, and I had been using it as one.

This chapter explains why. I criticise SOLID on two levels:

- **In practice.** Almost nobody applies SOLID the way its authors intended. The industry settled on one way of working, and that is the only SOLID most people ever meet. When that version is criticised, the usual reply is "you're doing it wrong". Maybe. But it is not one critic doing it wrong, it is the whole industry, for decades. At that point the misreading *is* the principle as it exists, so that is what I judge.
- **In theory.** Even read charitably, SOLID wraps universal concerns (cohesion, coupling) in OOP-specific mechanisms. It helps you name a problem after the fact. It does not help you design.

## What others have said

I am not the first to feel this. Here is what others have argued, with sources, so you can follow each thread yourself.

### General

- "Principles" is the wrong word. They are patterns or properties that depend on context, not universal rules ([Henney, *SOLID Deconstruction*](https://www.slideshare.net/Kevlin/solid-deconstruction); [North, *Why Every Element of SOLID Is Wrong*](https://speakerdeck.com/tastapod/why-every-element-of-solid-is-wrong)).
- Applied rigidly, SOLID produces over-abstracted code that is hard to navigate: lots of tiny classes and interfaces ([Khoo, *Challenging the Gospel*](https://medium.com/@jeremykhoois/solid-principles-sucks-b5935b1235d7); [Mortenson, *SOLID — 25 Years Later*](https://dev.to/chriswritesstuff/solid-30-years-later-g79)).
- The definitions are not precise, so they are open to almost any interpretation ([Marston, *Not-so-SOLID OO Principles*](https://www.tonymarston.net/php-mysql/not-so-solid-oo-principles.html)).
- There are no concrete demonstrations: show me the bug, the fix, and the side effects ([Marston](https://www.tonymarston.net/php-mysql/not-so-solid-oo-principles.html)).
- They are second-order principles at best. They point in a direction but do not define a goal ([Mortenson](https://dev.to/chriswritesstuff/solid-30-years-later-g79)).
- They come from late-90s OO assumptions, and it shows ([nocomplexity, *Rise and Fall of SOLID*](https://nocomplexity.com/solid-programming/); [Dunn, *Is SOLID Still Relevant?*](https://dunnhq.com/posts/2021/solid-relevance/)).

### Per principle

#### S — Single Responsibility

- No working definition. "One reason to change" drifted into "one actor", and neither comes with a test you can apply ([Marston](https://www.tonymarston.net/php-mysql/not-so-solid-oo-principles.html)). Chapter 2 gives the underlying idea, [Cohesion](../chapter2/axiom-07-cohesion.md), a sharper and testable shape.
- Applied rigidly, it produces overly small classes for the sake of purity ([Khoo](https://medium.com/@jeremykhoois/solid-principles-sucks-b5935b1235d7)).

#### O — Open/Closed

- It requires predicting the future: which part of the code will vary next ([Khoo](https://medium.com/@jeremykhoois/solid-principles-sucks-b5935b1235d7)).
- "Extend by inheritance" caused the 90s inheritance overdose we are still recovering from ([Dunn](https://dunnhq.com/posts/2021/solid-relevance/)).
- Arguably redundant, because LSP already implies it ([Henney summary](https://yahnd.com/theater/r/vimeo/157708450/); [Dunn](https://dunnhq.com/posts/2021/solid-relevance/)).

#### L — Liskov Substitution

- Often misread as a *structural* rule ("same interface, so it is substitutable"). It is really a *behavioural* contract ([Henney](https://www.slideshare.net/Kevlin/solid-deconstruction); [Oldwood, *KISSing SOLID Goodbye*](https://accu.org/journals/overload/22/122/oldwood_1957/)). [Honest, total signatures](../chapter2/axiom-06-honest-total-signatures.md) are what make that contract visible.

#### I — Interface Segregation

- Cargo-culted into "one interface per class, even with a single implementation" ([Khoo](https://medium.com/@jeremykhoois/solid-principles-sucks-b5935b1235d7)).
- Arguably just SRP again, not a separate idea ([North](https://speakerdeck.com/tastapod/why-every-element-of-solid-is-wrong)).

#### D — Dependency Inversion

- Constantly confused with DI and DI frameworks. The principle is not the mechanism ([NDepend, *In Defense of SOLID*, noting the confusion](https://blog.ndepend.com/defense-solid-principles/)).
- Henney argues it reduces to SRP + LSP, so it is not a separate principle ([Henney summary](https://yahnd.com/theater/r/vimeo/157708450/)).
- The name is dated. "Inversion" comes from the structured-programming era; today it is just the normal direction of dependencies ([Dunn](https://dunnhq.com/posts/2021/solid-relevance/)). Where dependency direction does matter, the [Impureheim sandwich](../chapter2/axiom-12-impureheim.md) turns it into a code shape, not a framework.

### Paradigm fit

- It does not transfer well to functional programming or data pipelines. It works mainly in its original context: large Java/.NET monoliths ([Mikulski, *CUPID in Data Engineering*](https://mikulskibartosz.name/cupid-principles-in-data-engineering)).
- It does not work across microservice boundaries. You cannot inject an implementation over HTTP or AMQP, so OCP loses its meaning and DIP becomes coupling to a contract ([Van Couvering, *Applying SOLID to Services*](https://david-vancouvering.medium.com/applying-solid-principles-to-services-e56ef2382a26)).

### Proposed alternatives

- **CUPID**: Composable, Unix philosophy, Predictable, Idiomatic, Domain-based. Properties on a spectrum, not rules ([cupid.dev](https://cupid.dev/); [North, *CUPID — for joyful coding*](https://dannorth.net/2022/02/10/cupid-for-joyful-coding/)).
- **Patterns over principles**: treat SOLID as patterns you apply when you see the symptoms, not rules you always follow ([Henney, *SOLID Deconstruction*](https://www.slideshare.net/Kevlin/solid-deconstruction)).

## My read, part 1 — SOLID in practice

This builds on the critique above instead of repeating it. The reasoning is my own; external sources are cited inline.

### What SOLID became

In most codebases, SOLID turned into a fixed project skeleton you just follow:

- an interface for every class: `IFoo` next to every `Foo`;
- a DI container to wire them;
- those interfaces injected through the constructor.

That is just **D** and **I** turned into plumbing. **O** and **L** survive only as the excuse for the interface: you *could* swap the implementation, any other one *would* substitute. In practice, nobody does.

Principles meant to guide judgement became boilerplate you set up once and stop thinking about. **A template you apply by reflex is the opposite of reasoning about a design.**

### Why it became that

Nobody arrived at this skeleton by reading SOLID. Two other forces built it:

- **Unit tests based on mocks.** To replace a dependency with a mock, you need an interface. So every class gets one, even when there is only one implementation.
- **Framework defaults.** ASP.NET Core ships with a DI container, and Spring is built around one. Templates and tutorials wire everything through constructors from day one.

SOLID became the vocabulary used to *justify* this setup after the fact. "Why does `Foo` have an `IFoo`?" "Dependency Inversion." The real answer is usually "so the test can mock it".

This matters for the rest of the book: a pure core, tested with plain values, does not need mocks. Without mocks, most of that interface layer loses its reason to exist.

### The letters survive only as symptoms, never by name

- Nobody says "Liskov violation". They say "this implementation behaves weird".
- Nobody says "SRP". They argue that the class does too much.
- The principle names are dead in practice. The symptom names won: blast radius, shotgun surgery, "why do I touch five files to add one thing?".

### SRP survives because it is undefined

Its vagueness is not a bug. It is the only place in SOLID where real judgement about [cohesion](../chapter2/axiom-07-cohesion.md) happens. The other letters became settled convention. SRP is still debated because it cannot be turned into a rule.

### A rule everyone misreads is not actionable

- If most of an industry has misapplied a set of principles for 25 years, that is no longer about the readers. It says something about the principles: they are not specific enough to be applied correctly.
- An actionable rule is hard to misread. Two reviewers applying it to the same code should reach the same verdict.
- By that test, **SOLID as practiced is not actionable.** It does not help you reason about code. It only names what already went wrong.

## My read, part 2 — SOLID in theory

Now read SOLID charitably, the way its authors meant it. It still does not give you a way to design.

### SOLID splits in two

- **D, I, and the strategy-pattern form of O are structural.** A convention, a DI container or a linter can enforce them.
- **S and L are semantic.** They are about [cohesion](../chapter2/axiom-07-cohesion.md) and honest behaviour. No tool can enforce them.

This split explains what happened in practice. The structural letters were easy to mechanise, so they became ceremony: an `IFoo` next to its only `Foo` is enforced, but it encodes no design decision. The semantic letters could not be mechanised at all, so they stayed vague. Neither half became something you can act on.

Enforcing rules in code is not the problem. The rest of this book wants exactly that. The problem is enforcing ceremony instead of decisions. A `Result` return type is enforced by the compiler *and* says something about the code. An `IFoo` says nothing.

### There are two OCPs, and the popular one is the bad one

- **Meyer's OCP** (extend by subclassing) leads straight into the fragile-base-class trap.
- **Uncle Bob's OCP** (add a new implementation, never edit existing ones) is fine. But it is just "composition over inheritance" plus "program to an interface" with a new name.
- OCP only makes sense **after the fact**, along an axis you have already seen change (the [rule of three](https://en.wikipedia.org/wiki/Rule_of_three_(computer_programming))). Applied in advance, it is speculative generality.

### OCP did not die, it moved up the stack

Its intent, "open for extension, closed for modification", lives on in Vertical Slice Architecture: you add a feature by adding a new slice, without touching the existing ones. The unit that stays closed moved from the *class* to the *slice*, where it is finally actionable.

### Refactoring to extract a shared concept is OCP working, not failing

- Extract once, when the second consumer appears. That one change makes the code closed for every future consumer.
- The health metric is not "zero edits ever". It is **extractions becoming rarer over time** as the domain model matures.
- If you still need big extractions years in, your domain model or design is wrong. That is not an OCP failure.
- Extract the *stable* domain concept (the aggregate). Tolerate duplication in the *volatile* workflow.

### LSP is a behavioural contract the types do not show

Read correctly, LSP is about behaviour: a subtype must keep the promises of its parent. But in a typical OO signature those promises are invisible. A method can throw, return `null` or have side effects without saying so. So LSP can only be checked by reading every implementation.

[Honest, total signatures](../chapter2/axiom-06-honest-total-signatures.md) move the promise into the type, where the compiler checks it.

### SOLID wraps universal concerns in OOP mechanisms

You rarely hear about SOLID in functional code. That is because most of the mechanisms SOLID corrects do not exist there:

- No inheritance to abuse, so subclass-based OCP and fragile base classes disappear.
- Functions are [first-class](../chapter2/axiom-09-first-class-functions.md), so a single-method interface is just a function. OCP's strategy pattern and ISP come for free.
- [Data and behaviour are separate](../chapter2/axiom-01-data-vs-behaviour.md), so there are no objects mixing mutable state with methods.
- Dependencies are passed as parameters, so DIP needs no container.

Even Mark Seemann, a careful defender of SOLID, argues that SOLID taken seriously leads to FP: push ISP to role interfaces and you end up with single-method interfaces, which *are* functions ([Seemann, *SOLID: the next step is Functional*](https://blog.ploeh.dk/2014/03/10/solid-the-next-step-is-functional/)).

But the concerns *underneath* do not disappear. A pure FP codebase can still have modules with poor cohesion and functions coupled in fragile ways. Those concerns are universal. They deserve tools that work in any paradigm and come with a scale you can argue with: [Cohesion](../chapter2/axiom-07-cohesion.md) and [Connascence](../chapter2/axiom-08-connascence.md).

So SOLID is useful to name OOP smells, but it is not the level where design happens.

## CUPID — names the destination, not the route

The alternative I keep coming back to is Dan North's **CUPID**: five *properties* (Composable, Unix philosophy, Predictable, Idiomatic, Domain-based) on a spectrum ([North, *CUPID — for joyful coding*](https://dannorth.net/2022/02/10/cupid-for-joyful-coding/)).

CUPID is about goals: "move toward this", not "comply or not". That is already a step up. **SOLID as practiced is useless for creating a design; CUPID is an ally.**

But it hits the same ceiling. A property is something you *recognise*, not something you *do*. CUPID describes the **destination**, never the **route**. When you read each property, you end up reaching for the building blocks of the next two chapters to actually get there. **CUPID describes what good code looks like; the axioms are how you get there.**

### This is North's own framing

I am not reading a flaw into CUPID. North chose properties over principles on purpose:

- Principles are "rules: you are either compliant or you are not."
- Properties "define a goal or centre to move towards" and act as "a lens or filter to assess your code" ([North](https://dannorth.net/2022/02/10/cupid-for-joyful-coding/)).

A lens helps you assess code. It does not write it for you. North says the same about each property. For example, the things that make code Composable are "neither necessary nor sufficient to make any guarantees … useful heuristics", because "more is not necessarily better; it is all trade-offs" ([cupid.dev](https://cupid.dev/properties/composable/)).

To be fair: North also says there is "always a clear *direction* of travel". So "names the destination, not the route" is my phrasing, not his. He sees the open route as a feature. I see it as the ceiling. That is the only point where we disagree.

### Others reach the same conclusion

Jeremy Miller is no CUPID sceptic. He dismissed it at first, then made himself take it seriously, and concluded: "I don't find it to be specific enough to be **actionable**, but as a philosophical starting point it's pretty solid" ([Miller, *Putting SOLID into Perspective*](https://jeremydmiller.com/2022/08/10/putting-solid-into-perspective/)).

*Actionable* is the right word. CUPID gives even a fair, experienced reader a starting point, but no route. The next two chapters set out to provide that route.

### Mapping each property to the book

Every property maps to something I already reason with, or will in a later chapter.

#### Composable — "plays well with others"

- **Small surface area** → the future *Deep modules, small interfaces* Play (Chapter 3): a module's value is its functionality divided by the cost of its interface. A narrow API *is* the small surface.
- **Intention-revealing** → [honest, total signatures](../chapter2/axiom-06-honest-total-signatures.md) and domain-named [value objects](../chapter2/axiom-18-value-objects.md). [Making illegal states unrepresentable](../chapter2/axiom-22-illegal-states.md) and [discriminated unions](../chapter2/axiom-21-discriminated-unions.md) name each case where a `bool` would hide it. The type, not a comment, reveals the intent.
- **Minimal dependencies** → North means *external packages* (his example is dropping a logging library). That is a packaging concern, above this book's level. At the level of a single function it is *similar to*, but not the same as:
  - [purity](../chapter2/axiom-05-pure-functions.md): the function depends only on its arguments;
  - [Impureheim](../chapter2/axiom-12-impureheim.md): dependencies are handed in from the shell, never fetched.
- **Composing itself** → [higher-order functions](../chapter2/axiom-10-higher-order-functions.md) and `Result` composition (map/bind/traverse). Composability is something you build, with combinators.

#### Unix philosophy — "does one thing well"

- **Does one thing** → [Cohesion](../chapter2/axiom-07-cohesion.md), judged from the outside in. That is the same move North makes away from SRP, which judges from the inside out. "One job" is the cohesion question, made testable.
- **Composes via pipes** → low [Connascence](../chapter2/axiom-08-connascence.md) between units, plus the combinators above. Pieces connect cleanly only when what couples them is weak and explicit.

#### Predictable — "does what you expect"

- **Behaves as expected** → [honest, total signatures](../chapter2/axiom-06-honest-total-signatures.md). The type tells you what can come back, so the behaviour is visible in the signature, not hidden in the body.
- **Deterministic** → [pure functions](../chapter2/axiom-05-pure-functions.md). The cleanest match in the whole set: deterministic means referentially transparent means pure.
- **Observable** → instrumentation, telemetry, monitoring. Operational, above this book's level.

#### Idiomatic — "feels natural"

- **Language and team idioms** → not an axiom but a *contextual choice*: dated, reversible, team-dependent. That belongs in ADRs (`AsNoTracking` and jOOQ are idiom choices, and North himself sends local idioms to ADRs). What feels natural depends on the reader, not on the code.
- **The honest tension**: my axioms sometimes go *against* the local idiom. For example, `Result<int, string>` instead of the idiomatic `bool TryParse(string, out int)`.
  - I trade idiom for honesty (simplicity first: honest before familiar).
  - I pay the idiom back in the mechanics: records, `switch` expressions, pattern matching, LINQ.
  - Idiomatic still matters. It just sits one level above the building blocks.

#### Domain-based — "models the problem domain in language and structure"

- **Domain-based language** → domain-named [value objects](../chapter2/axiom-18-value-objects.md) and the future FP-style *DDD tactical patterns* (Chapter 3). `Surname`, not `string`: close the gap between the code and the conversation.
- **Domain-based structure** → Vertical Slice Architecture: folders mirror the domain, not technical layers. That is also where I argued [OCP moved to](#ocp-did-not-die-it-moved-up-the-stack).
- **Domain-based boundaries** (module = deployment unit) → architecture, above this book's level.

### The critique of CUPID that does exist

There is less direct criticism of CUPID than you would expect. Most write-ups just restate North and agree. But CUPID's precursor got one sharp reply worth keeping:

- Before the properties, North proposed "fits in my head" as his replacement for Single Responsibility: "you can only reason about something if it fits in your head" ([North, *the back story*](https://dannorth.net/blog/cupid-the-back-story/)).
- The reply on Hacker News: "any developer who wants to defend their code will simply claim a given spaghetti incident easily fit in *their* head" ([HN](https://news.ycombinator.com/item?id=26531079)).

That is the whole point in one line. A heuristic you can *recognise* but not *enforce* settles no argument. The best-known critique of CUPID is not about a property. It is about the missing mechanism behind one.

### What CUPID leaves above this book

The book is stacked by level: Chapter 1 is the motivation, Chapter 2 the building blocks, Chapter 3 the plays. The parts of CUPID that do not map into Chapters 2 and 3 all point the same way: **up**.

- Observable
- Idiomatic
- Minimal dependencies, in the packaging sense

They are not unmapped because they do not matter. They are unmapped because they live above the level of code. Everything that *is* at the level of code is already a building block in the next chapter.

## So what do I reason with instead?

When reading and writing code, we need tools: a precise vocabulary to evaluate each line, each piece of data and each function, along several dimensions. Something to argue about trade-offs with, and to describe them properly.

SOLID does not give us that:

- In practice, it became ceremony that a whole industry applies by reflex, and the letters survive only as names for symptoms.
- In theory, it wraps universal concerns in OOP-specific mechanisms. Half of it is structure that can be enforced but says nothing; the other half is judgement that cannot be enforced at all.

CUPID comes closer. It is an ally that points toward a destination, but it stops at the same ceiling: it cannot give you the route.

Both let me *name* what I am looking at. Neither helps me *create* it.

So the question is not "how do I obey five principles, or chase five properties?". It is:

**What building blocks give me a precise vocabulary and metrics to reason about code?**

And once I have them:

**How can I enforce them in the code itself, so I do not depend on anyone's discipline at review time?**

---

Next: [Chapter 2](../chapter2/README.md) →
